// Tests des unités pures de la function `ocr-enhance` (audit 2026-06-11).
import {
  assert,
  assertEquals,
  assertStringIncludes,
  assertThrows,
} from 'https://deno.land/std@0.208.0/assert/mod.ts';
import {
  ALLOWED_ORIGINS,
  buildPrompt,
  corsHeaders,
  kMaxBodyBytes,
  parseGeminiJson,
} from '../ocr-enhance/lib.ts';

function reqWithOrigin(origin?: string): Request {
  const headers = origin ? { origin } : undefined;
  return new Request('https://x.test/ocr-enhance', { headers });
}

Deno.test('corsHeaders : origine prod autorisée renvoyée telle quelle', () => {
  const h = corsHeaders(reqWithOrigin('https://chipat-neko.github.io'));
  assertEquals(h['Access-Control-Allow-Origin'], 'https://chipat-neko.github.io');
  assertEquals(h['Vary'], 'Origin');
});

Deno.test('corsHeaders : localhost avec port autorisé (dev web)', () => {
  const h = corsHeaders(reqWithOrigin('http://localhost:8080'));
  assertEquals(h['Access-Control-Allow-Origin'], 'http://localhost:8080');
});

Deno.test('corsHeaders : origine inconnue -> rabattue sur la prod (#183)', () => {
  const h = corsHeaders(reqWithOrigin('https://evil.example.com'));
  assertEquals(h['Access-Control-Allow-Origin'], ALLOWED_ORIGINS[0]);
});

Deno.test('corsHeaders : un préfixe ne suffit pas (https://chipat-neko.github.io.evil.com)', () => {
  const h = corsHeaders(reqWithOrigin('https://chipat-neko.github.io.evil.com'));
  assertEquals(h['Access-Control-Allow-Origin'], ALLOWED_ORIGINS[0]);
});

Deno.test('corsHeaders : pas d\'en-tête Origin (mobile) -> prod', () => {
  const h = corsHeaders(reqWithOrigin());
  assertEquals(h['Access-Control-Allow-Origin'], ALLOWED_ORIGINS[0]);
});

Deno.test('kMaxBodyBytes : garde-fou DoS à 16 Ko (#184)', () => {
  assertEquals(kMaxBodyBytes, 16 * 1024);
});

Deno.test('buildPrompt : hint enlevement -> consigne "à enlever chez"', () => {
  const p = buildPrompt({ ocr_text: 'GARAGE X', format_hint: 'enlevement' });
  assertStringIncludes(p, 'ENLEVEMENT');
  assertStringIncludes(p, 'à enlever chez');
  assertStringIncludes(p, 'GARAGE X');
});

Deno.test('buildPrompt : hint livraison -> destinataire final', () => {
  const p = buildPrompt({ ocr_text: 'X', format_hint: 'livraison' });
  assertStringIncludes(p, 'bordereau LIVRAISON');
});

Deno.test('buildPrompt : sans hint -> détection automatique', () => {
  const p = buildPrompt({ ocr_text: 'X' });
  assertStringIncludes(p, 'Detecter automatiquement');
});

Deno.test('parseGeminiJson : JSON propre', () => {
  const r = parseGeminiJson(JSON.stringify({
    nom_destinataire: 'GARAGE DUPONT',
    rue: '12 rue X',
    code_postal: '28000',
    ville: 'CHARTRES',
    nb_colis: 3,
    telephone: '0237267502',
    format: 'enlevement',
    confidence: 'high',
  }));
  assertEquals(r.nom_destinataire, 'GARAGE DUPONT');
  assertEquals(r.nb_colis, 3);
  assertEquals(r.confidence, 'high');
  assertEquals(r.source, 'gemini');
});

Deno.test('parseGeminiJson : markdown ```json toléré', () => {
  const r = parseGeminiJson(
    '```json\n{"nom_destinataire":"X","format":"livraison","confidence":"low"}\n```',
  );
  assertEquals(r.nom_destinataire, 'X');
  assertEquals(r.format, 'livraison');
});

Deno.test('parseGeminiJson : valeurs invalides normalisées', () => {
  const r = parseGeminiJson(JSON.stringify({
    nb_colis: 'trois', // pas un nombre -> null
    format: 'pickup', // inconnu -> enlevement (défaut)
    confidence: 'tres-haute', // inconnue -> low
  }));
  assertEquals(r.nb_colis, null);
  assertEquals(r.format, 'enlevement');
  assertEquals(r.confidence, 'low');
  assertEquals(r.nom_destinataire, null);
});

Deno.test('parseGeminiJson : réponse non-JSON -> throw (gérée en 500 par le handler)', () => {
  assertThrows(() => parseGeminiJson('Désolé, je ne peux pas.'));
});

Deno.test('parseGeminiJson : nb_colis flottant accepté tel quel (number)', () => {
  const r = parseGeminiJson('{"nb_colis": 2}');
  assert(typeof r.nb_colis === 'number');
});
