import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

/// ════════════════════════════════════════════════════════════════
/// Transforme une exception cloud brute en message FR user-friendly.
/// ════════════════════════════════════════════════════════════════
///
/// Avant : `CloudSyncException('Echec push : ClientException(SocketException
/// : Failed host lookup ...))'` -> Noah voit du jargon technique.
///
/// Apres : `CloudSyncException('Echec push : Pas de connexion internet
/// (verifie wifi/4G)')` -> Noah comprend tout de suite.
///
/// Heuristiques :
/// - `SocketException` / "Failed host lookup" / "Network is unreachable"
///   -> "Pas de connexion internet"
/// - `TimeoutException` / "timeout" / "deadline exceeded"
///   -> "Delai depasse, ressaie dans qq secondes"
/// - `PostgrestException` 401/403 / "JWT expired" / "invalid_grant"
///   -> "Session expiree, reconnecte-toi"
/// - `PostgrestException` autres : message texte direct sans "Postgrest..."
/// - Fallback : message de l'exception en toString() court
String humanizeCloudError(Object e) {
  // Network failures (host lookup, no route, refused)
  if (e is SocketException) {
    return 'Pas de connexion internet (verifie wifi/4G).';
  }
  if (e is TimeoutException) {
    return 'Delai depasse, ressaie dans quelques secondes.';
  }

  // Postgrest : check le code HTTP + message
  if (e is PostgrestException) {
    // Tokens auth expirés
    if (e.code == '401' || e.code == 'PGRST301' ||
        e.message.toLowerCase().contains('jwt expired') ||
        e.message.toLowerCase().contains('invalid token')) {
      return 'Session expiree, reconnecte-toi (Parametres > Compte cloud).';
    }
    if (e.code == '403') {
      return 'Acces refuse cote serveur (RLS). Verifie le compte.';
    }
    // Code 42P17 = infinite recursion (le bug qu'on a deja fix)
    if (e.code == '42P17') {
      return 'Erreur RLS recursive (SQL Supabase a re-jouer ?).';
    }
    // Default : juste le message texte sans le wrapper (scrub par
    // prudence : un message serveur ne devrait pas contenir de token,
    // mais on ne prend pas le risque).
    return scrubSecrets(e.message);
  }

  // String-based matching pour les ClientException de http qui wrap
  // souvent une SocketException sans en exposer le type directement.
  final s = e.toString().toLowerCase();
  if (s.contains('failed host lookup') ||
      s.contains('network is unreachable') ||
      s.contains('no address associated')) {
    return 'Pas de connexion internet (verifie wifi/4G).';
  }
  if (s.contains('timeout') || s.contains('deadline exceeded')) {
    return 'Delai depasse, ressaie dans quelques secondes.';
  }
  if (s.contains('connection refused') || s.contains('connection reset')) {
    return 'Serveur Supabase injoignable, ressaie plus tard.';
  }

  // Fallback : message brut NETTOYE (on retire tout secret eventuel)
  // puis tronque si trop long (max 120 chars pour tenir dans un SnackBar
  // lisible). Le scrub evite qu'un JWT de session / token Bearer fuite
  // dans un SnackBar ou via l'ecran Diagnostic (copie/capture d'ecran).
  final raw = scrubSecrets(e.toString());
  if (raw.length <= 120) return raw;
  return '${raw.substring(0, 117)}...';
}

/// Masque les secrets susceptibles d'apparaitre dans une exception brute
/// (message d'une ClientException http, log Supabase...) avant affichage
/// utilisateur :
/// - JWT (`eyJ...` en 3 segments base64url) -> token de session, le plus
///   dangereux (vol de session via capture d'ecran).
/// - en-tete `Bearer <token>` / `apikey=<...>` / `access_token=<...>`.
///
/// Defensif : si rien ne matche, la chaine est renvoyee inchangee. Cf
/// audit securite nuit 2026-06-01 (information disclosure).
String scrubSecrets(String input) {
  var out = input;
  // JWT : 3 segments base64url separes par des points. On masque tout.
  out = out.replaceAll(
    RegExp(r'eyJ[A-Za-z0-9_=-]+\.[A-Za-z0-9_=-]+\.[A-Za-z0-9_=.-]*'),
    '***',
  );
  // Bearer <token>
  out = out.replaceAll(
    RegExp(r'[Bb]earer\s+[A-Za-z0-9._~+/=-]+'),
    'Bearer ***',
  );
  // apikey=... / access_token=... / refresh_token=... dans une URL/query
  out = out.replaceAll(
    RegExp(
      r'(apikey|access_token|refresh_token|token)=[A-Za-z0-9._~+/=-]+',
      caseSensitive: false,
    ),
    r'$1=***',
  );
  return out;
}

/// Variante etendue de [humanizeCloudError] qui gere AUSSI les
/// exceptions locales courantes (Drift SQLite + I/O fichier). Sert aux
/// screens UI qui melangent operations cloud et locales (ex: delete
/// d'une tournee qui fait delete cloud + local + Storage).
///
/// Si on est sur de ne traiter que des erreurs cloud, prefer
/// [humanizeCloudError] qui evite les checks fichier inutiles.
String humanizeAnyError(Object e) {
  // FileSystemException (write disque plein, permission denied, etc.)
  if (e is FileSystemException) {
    final msg = e.osError?.message ?? '';
    if (msg.toLowerCase().contains('no space')) {
      return 'Disque plein. Libere de l\'espace et ressaie.';
    }
    if (msg.toLowerCase().contains('permission denied')) {
      return 'Permission refusee sur le fichier.';
    }
    return 'Erreur fichier : ${e.message}';
  }

  // String-based : Drift / SQLite exceptions (SqliteException n'est pas
  // exporte directement, on detecte par toString)
  final s = e.toString().toLowerCase();
  if (s.contains('sqliteexception') || s.contains('drift')) {
    if (s.contains('constraint')) {
      return 'Conflit dans la base locale (donnee deja existante ?).';
    }
    if (s.contains('disk i/o') || s.contains('database is locked')) {
      return 'Base de donnees occupee, ressaie dans qq secondes.';
    }
    return 'Erreur base de donnees locale.';
  }

  // Sinon : delegue a humanizeCloudError (qui gere lui-meme le fallback
  // toString tronque).
  return humanizeCloudError(e);
}
