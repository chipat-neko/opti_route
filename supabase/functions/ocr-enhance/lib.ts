// Unités pures de la function `ocr-enhance`, extraites d'index.ts pour
// être testables sans démarrer le serveur (audit 2026-06-11, tests dans
// supabase/functions/_tests/ocr_enhance_test.ts). Aucune dépendance
// réseau : l'appel Gemini reste dans index.ts.

export interface OcrEnhanceRequest {
  // Texte OCR brut : lignes detectees par ML Kit, joined par \n.
  ocr_text: string;
  // Format detecte par le parser local : 'enlevement' | 'livraison'.
  // Sert d'indice au prompt (Gemini sait quoi chercher en priorite).
  format_hint?: 'enlevement' | 'livraison';
  // Parser local utilise : 'mesexp' | 'colissimo' | 'chronopost'.
  parser_used?: string;
}

export interface OcrEnhanceResponse {
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

// CORS restreint (#183). ocr-enhance est verify_jwt=true -> le JWT est le
// vrai garde-fou, mais on limite quand meme l'origine NAVIGATEUR a l'app
// web prod + le dev local. Le mobile n'envoie pas d'en-tete Origin et
// n'est pas soumis a CORS, donc non impacte. Origine inconnue -> on
// renvoie l'origine prod (le navigateur tiers sera bloque cote client).
export const ALLOWED_ORIGINS = [
  'https://chipat-neko.github.io', // site + app web (GitHub Pages)
  'http://localhost', // dev web local (avec port quelconque)
];

export function corsHeaders(req: Request): Record<string, string> {
  const origin = req.headers.get('origin') ?? '';
  const allowed = ALLOWED_ORIGINS.some(
    (o) => origin === o || origin.startsWith(`${o}:`),
  );
  return {
    'Access-Control-Allow-Origin': allowed ? origin : ALLOWED_ORIGINS[0],
    'Access-Control-Allow-Headers':
      'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Vary': 'Origin',
  };
}

/// Taille max du body accepte avant parsing (#184). Un bordereau OCR fait
/// quelques Ko ; on refuse tout ce qui depasse pour eviter de lire un
/// payload enorme en memoire (DoS leger).
export const kMaxBodyBytes = 16 * 1024;

export function buildPrompt(req: OcrEnhanceRequest): string {
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

export function parseGeminiJson(raw: string): OcrEnhanceResponse {
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
