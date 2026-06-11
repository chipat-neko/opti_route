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
import {
  buildPrompt,
  corsHeaders,
  kMaxBodyBytes,
  type OcrEnhanceRequest,
  parseGeminiJson,
} from './lib.ts';

const GEMINI_MODEL = 'gemini-2.5-flash';
const GEMINI_ENDPOINT =
  `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

// Types + CORS + buildPrompt + parseGeminiJson : cf ./lib.ts (extraits
// pour les tests Deno, audit 2026-06-11).

async function callGemini(
  apiKey: string,
  prompt: string,
): Promise<string> {
  // Clé via en-tête `x-goog-api-key` plutôt qu'en query string `?key=`
  // (durcissement nuit 2026-06-01) : une clé dans l'URL peut fuiter dans
  // les logs de proxy / d'accès. L'en-tête évite ça.
  const resp = await fetch(GEMINI_ENDPOINT, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'x-goog-api-key': apiKey,
    },
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

serve(async (req: Request): Promise<Response> => {
  const cors = corsHeaders(req);
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: cors });
  }
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...cors, 'content-type': 'application/json' },
    });
  }

  try {
    const apiKey = Deno.env.get('GEMINI_API_KEY');
    if (!apiKey) {
      return new Response(
        JSON.stringify({ error: 'GEMINI_API_KEY not configured' }),
        {
          status: 500,
          headers: { ...cors, 'content-type': 'application/json' },
        },
      );
    }
    // Garde-fou taille (#184) : refuse un body trop gros AVANT de le lire
    // en memoire. Content-Length absent (chunked) -> on laisse passer, la
    // troncature a 4000 chars plus bas limite l'impact.
    const contentLength = Number(req.headers.get('content-length') ?? '0');
    if (contentLength > kMaxBodyBytes) {
      return new Response(
        JSON.stringify({ error: 'Payload trop volumineux.' }),
        {
          status: 413,
          headers: { ...cors, 'content-type': 'application/json' },
        },
      );
    }
    const body = (await req.json()) as OcrEnhanceRequest;
    if (!body.ocr_text || typeof body.ocr_text !== 'string') {
      return new Response(
        JSON.stringify({ error: 'ocr_text required (string)' }),
        {
          status: 400,
          headers: { ...cors, 'content-type': 'application/json' },
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
      headers: { ...cors, 'content-type': 'application/json' },
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    return new Response(JSON.stringify({ error: msg }), {
      status: 500,
      headers: { ...cors, 'content-type': 'application/json' },
    });
  }
});
