import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ════════════════════════════════════════════════════════════════
/// Wrapper Supabase (Phase 2 backend cloud) -- jalon 1 : Auth seule.
/// ════════════════════════════════════════════════════════════════
///
/// **Choix techniques de la Phase 2** :
/// - Free tier Supabase (500 MB DB, 50k MAU, region UE = Frankfurt
///   ou Paris). Largement assez pour Noah + 1-5 coequipiers.
/// - Auth par **email + OTP** (code 6 chiffres envoye par mail) plutot
///   que magic link : pas besoin de configurer les deep links / Universal
///   Links Android+iOS dans ce jalon 1. Magic link viendra en jalon 2.
/// - Donnees locales (Drift) sont l'autorite courante. Le sync vers le
///   cloud est ajoute progressivement par jalon (cf docs/plan-phase-2.md
///   a venir).
///
/// **Config** :
/// L'URL et l'anon key Supabase sont injectees au build via
/// `--dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=
/// SUPABASE_ANON_KEY=eyJxxx`. En dev sans config, [isConfigured] est
/// false et l'auth UI affiche un message d'erreur explicite.
///
/// **Important** : ce service n'est PAS un repository Drift. Il est
/// initialise une seule fois au boot par [init] et expose ensuite des
/// methodes statiques sur l'instance globale `Supabase.instance.client`.
class SupabaseService {
  SupabaseService._();
  static final instance = SupabaseService._();

  /// URL et anon key configurees au build via --dart-define. Vides en
  /// dev local sans config -> [isConfigured] = false, l'UI bascule en
  /// mode "non configure" plutot que de crasher.
  static const String _url =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String _anonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  bool _initialized = false;

  /// Vrai si les variables d'environnement Supabase ont ete fournies
  /// au build. Permet a l'UI de proposer une bascule "Activer le cloud"
  /// uniquement si les credentials sont en place.
  bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  /// Initialise le client Supabase. Appelle [Supabase.initialize] une
  /// seule fois (idempotent). Pas d'init si [isConfigured] est false
  /// (mode dev local sans backend) -- les methodes d'auth retourneront
  /// alors une erreur explicite.
  Future<void> init() async {
    if (_initialized) return;
    if (!isConfigured) {
      debugPrint(
        '[SupabaseService] Pas de config (SUPABASE_URL / SUPABASE_ANON_KEY '
        'absents) -- mode local-only.',
      );
      return;
    }
    try {
      await Supabase.initialize(
        url: _url,
        anonKey: _anonKey,
        // Auth detection desactivee par defaut : pas de deep link
        // dans le jalon 1, OTP par code email suffit.
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.implicit,
        ),
      );
      _initialized = true;
    } catch (e) {
      debugPrint('[SupabaseService] init failed: $e');
    }
  }

  /// Utilisateur courant ou null si pas connecte / pas initialise.
  User? get currentUser =>
      _initialized ? Supabase.instance.client.auth.currentUser : null;

  /// Stream des changements d'auth (login / logout). Sert au
  /// `authGate` qui montre AuthScreen vs HomeScreen selon l'etat.
  Stream<AuthState> get authStateChanges {
    if (!_initialized) return const Stream.empty();
    return Supabase.instance.client.auth.onAuthStateChange;
  }

  /// Envoie un code OTP a 6 chiffres a [email] (valable 1 heure cote
  /// Supabase). Le client doit ensuite appeler [verifyOtp] avec le code
  /// recu pour finaliser le login.
  ///
  /// Throw [AuthException] si :
  /// - email mal forme (Supabase rejette)
  /// - rate limit (Supabase plafonne a ~5 envois / heure / email)
  /// - service non configure ([isConfigured] = false)
  Future<void> sendOtpToEmail(String email) async {
    if (!_initialized) {
      throw const AuthException(
        'Service cloud non configure sur cette build de l\'app.',
      );
    }
    final clean = email.trim();
    if (clean.isEmpty || !clean.contains('@')) {
      throw const AuthException('Adresse email invalide.');
    }
    await Supabase.instance.client.auth.signInWithOtp(
      email: clean,
      // shouldCreateUser: true -> creation auto si nouveau compte.
      shouldCreateUser: true,
    );
  }

  /// Verifie le code OTP recu par email et finalise la connexion.
  /// Retourne le User en cas de succes, throw [AuthException] sinon
  /// (code invalide / expire).
  Future<User?> verifyOtp({
    required String email,
    required String code,
  }) async {
    if (!_initialized) {
      throw const AuthException(
        'Service cloud non configure sur cette build de l\'app.',
      );
    }
    final response = await Supabase.instance.client.auth.verifyOTP(
      email: email.trim(),
      token: code.trim(),
      type: OtpType.email,
    );
    return response.user;
  }

  /// Deconnexion. Efface la session locale (Supabase Flutter SDK la
  /// stocke en SharedPreferences via FlutterSecureStorage).
  Future<void> signOut() async {
    if (!_initialized) return;
    await Supabase.instance.client.auth.signOut();
  }
}
