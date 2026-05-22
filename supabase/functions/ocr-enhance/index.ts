// Edge Function Supabase : booste l'extraction OCR bordereau via
// Gemini Flash. Receit le texte OCR brut + format detecte par le
// parser local, demande a Gemini d'identifier le nom du destinataire
// de RAMASSE (a enlever chez) + adresse, et retourne du JSON propre.
//
// Workflow cote app : OCR + parser local en premier (instantane,
// offline-first), puis appel parallele a cette function. Quand la
// reponse Gemini arrive (~1s plus tard), si le resultat est meilleur,
// l'app bascule.
//
// Gemini Flash free tier : 1500 req/jour, largement assez pour Noah
// (~50-100 bordereaux/jour). Si quota depasse -> erreur 429 ->
// l'app garde le resultat local (fallback transparent).
//
// Deploiement : `npx supabase functions deploy ocr-enhance`
// Secret : `npx supabase secrets set GEMINI_API_KEY=AIza...`
// La cle se cree gratuitement sur https://aistudio.google.com/app/apikey

import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';

const GEMINI_MODEL = 'gemini-2.5-flash';
const GEMINI_ENDPOINT =
  `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

interface OcrEnhanceRequest {
  // Texte OCR brut : lignes detectees par ML Kit, joined par \n.
  ocr_text: string;
  // Format detecte par le parser local : 'enlevement' | 'livraison'.
  // Sert d'indice au prompt (Gemini sait quoi chercher en priorite).
  format_hint?: 'enlevement' | 'livraison';
  // Parser local utilise : 'mesexp' | 'colissimo' | 'chronopost'.
  parser_used?: string;
}

interface OcrEnhanceResponse {
  nom_destinataire: string | null;
  rue: string | null;
  code_postal: string | null;
  ville: string | null;
  nb_colis: number | null;
  telephone: string | null;
  format: 'enlevement' | 'livraison';
  confidence: 'high' | 'low' | 'none';
  // Provenance pour debug + badge UI ("Validé par IA").
  source: 'gemini';
}

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function buildPrompt(req: OcrEnhanceRequest): string {
  const formatLine = req.format_hint === 'enlevement'
    ? 'C\'est un bordereau ENLEVEMENT (ramasse). Le nom + adresse a extraire est celui du label "à enlever chez" -- c\'est le lieu OU le chauffeur va RAMASSER le colis, PAS la destination finale ulterieure.'
    : req.format_hint === 'livraison'
      ? 'C\'est un bordereau LIVRAISON. Extraire le nom + adresse du destinataire final.'
      : 'Detecter automatiquement si c\'est ENLEVEMENT (ramasse) ou LIVRAISON, puis extraire le nom + adresse pertinents.';

  return `Tu es un parser de bordereaux de transport francais (MESEXP, Colissimo, Chronopost, Eure et Loir Acheminement, etc).

${formatLine}

Texte OCR brut (lignes detectees par ML Kit, ordre potentiellement chaotique car blocs multi-colonnes) :
"""
${req.ocr_text}
"""

Extrait UNIQUEMENT du gros bloc destinataire (ignore en-tete transporteur, conditions generales en bas, numeros de reference techniques).

Reponds en JSON strict (rien d'autre, pas de markdown, pas de commentaire) :
{
  "nom_destinataire": "NOM EN MAJUSCULES ou null",
  "rue": "numero + nom de rue ou null",
  "code_postal": "5 chiffres ou null",
  "ville": "ville en majuscules ou null",
  "nb_colis": nombre entier ou null,
  "telephone": "10 chiffres sans espace ou null",
  "format": "enlevement" | "livraison",
  "confidence": "high" | "low" | "none"
}

Regles :
- "high" si nom + (rue OU cp+ville) trouves avec certitude
- "low" si donnees partielles ou ambigues
- "none" si rien d'utilisable
- Si tu hesites entre 2 adresses (ex sur ENLEVEMENT : "a enlever chez" vs "destination" finale), prends TOUJOURS celle du label demande, jamais la destination finale.`;
}

async function callGemini(
  apiKey: string,
  prompt: string,
): Promise<string> {
  const resp = await fetch(`${GEMINI_ENDPOINT}?key=${apiKey}`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0,
        maxOutputTokens: 512,
        responseMimeType: 'application/json',
      },
    }),
  });
  if (!resp.ok) {
    const errText = await resp.text();
    throw new Error(`Gemini ${resp.status} : ${errText.substring(0, 200)}`);
  }
  const data = await resp.json();
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text || typeof text !== 'string') {
    throw new Error('Gemini renvoie une reponse vide');
  }
  return text;
}

function parseGeminiJson(raw: string): OcrEnhanceResponse {
  // Gemini peut parfois ajouter du markdown ```json ... ``` malgre
  // responseMimeType. On nettoie a la main si besoin.
  let cleaned = raw.trim();
  if (cleaned.startsWith('```')) {
    cleaned = cleaned.replace(/^```(?:json)?\s*/i, '').replace(/```\s*$/i, '');
  }
  const obj = JSON.parse(cleaned);
  return {
    nom_destinataire: obj.nom_destinataire ?? null,
    rue: obj.rue ?? null,
    code_postal: obj.code_postal ?? null,
    ville: obj.ville ?? null,
    nb_colis: typeof obj.nb_colis === 'number' ? obj.nb_colis : null,
    telephone: obj.telephone ?? null,
    format: obj.format === 'livraison' ? 'livraison' : 'enlevement',
    confidence: ['high', 'low', 'none'].includes(obj.confidence)
      ? obj.confidence
      : 'low',
    source: 'gemini',
  };
}

serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS });
  }
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
    });
  }

  try {
    const apiKey = Deno.env.get('GEMINI_API_KEY');
    if (!apiKey) {
      return new Response(
        JSON.stringify({ error: 'GEMINI_API_KEY not configured' }),
        {
          status: 500,
          headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
        },
      );
    }
    const body = (await req.json()) as OcrEnhanceRequest;
    if (!body.ocr_text || typeof body.ocr_text !== 'string') {
      return new Response(
        JSON.stringify({ error: 'ocr_text required (string)' }),
        {
          status: 400,
          headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
        },
      );
    }
    // Garde-fou : on tronque le texte OCR a 4000 chars pour eviter
    // les bordereaux pathologiques qui explosent le quota tokens.
    const truncated = body.ocr_text.substring(0, 4000);
    const prompt = buildPrompt({ ...body, ocr_text: truncated });
    const geminiRaw = await callGemini(apiKey, prompt);
    const parsed = parseGeminiJson(geminiRaw);
    return new Response(JSON.stringify(parsed), {
      status: 200,
      headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    return new Response(JSON.stringify({ error: msg }), {
      status: 500,
      headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
    });
  }
});
