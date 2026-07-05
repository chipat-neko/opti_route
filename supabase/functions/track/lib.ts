// Unités pures de la function `track`, extraites d'index.ts pour être
// testables sans démarrer le serveur (audit 2026-06-11, tests dans
// supabase/functions/_tests/track_test.ts). Aucune dépendance réseau.

// Longueur EXACTE attendue (kTrackingCodeLength = 4 cote app, calibre
// sur la contrainte client "URL <= 20 chars" : https://optr.ro/abcd).
// On rejette les codes plus courts (ex 3 chars = espace de recherche
// reduit) -- audit #176.
export const kTrackingCodeRegex = /^[a-z0-9]{4}$/;

export function statusLabel(s: string): string {
  switch (s) {
    case 'livre':
      return 'Livré';
    case 'echec':
      return 'Livraison non aboutie';
    default:
      return 'En cours de livraison';
  }
}

// Minimisation RGPD (audit #176) : le code 4 chars est court (contrainte
// URL <= 20 chars client) et l'endpoint est public sans rate-limit ->
// un code devine ne doit PAS reveler une identite complete ni un
// domicile exact. On renvoie donc le prenom + initiale du nom, et des
// coordonnees arrondies (~110 m).
export function pseudonymizeName(name: string | null): string | null {
  if (name == null) return null;
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return null;
  if (parts.length === 1) return parts[0];
  // Premier mot complet + initiale du dernier mot ("Jean Dupont" -> "Jean D.").
  return `${parts[0]} ${parts[parts.length - 1][0].toUpperCase()}.`;
}

// Arrondit a 3 decimales (~110 m) : assez precis pour situer le quartier
// sur la carte de suivi, sans pointer le batiment exact (cf #176/#251).
export function coarsenCoord(v: number | null): number | null {
  if (v == null) return null;
  return Math.round(v * 1000) / 1000;
}
