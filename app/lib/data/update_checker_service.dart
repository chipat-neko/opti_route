import 'package:http/http.dart' as http;

/// Check si une nouvelle version d'opti_route est dispo sur GitHub.
///
/// Strategie : fetch le `pubspec.yaml` de la branche main via l'API
/// raw.githubusercontent (pas besoin de token) et compare la ligne
/// `version: X.Y.Z+N` avec la version locale fournie par le caller.
///
/// Best-effort : si pas de réseau / GitHub down / parse impossible →
/// `UpdateStatus.error(message)`. Pas d'erreur jetée, l'UI gère.
class UpdateCheckerService {
  UpdateCheckerService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const String _pubspecUrl =
      'https://raw.githubusercontent.com/chipat-neko/opti_route/main/app/pubspec.yaml';

  static final RegExp _versionLine = RegExp(r'^version:\s*([^\s]+)', multiLine: true);

  /// Compare la version locale [currentVersion] (ex "2.9.0+4050") avec
  /// celle sur main. Retourne l'état.
  Future<UpdateStatus> check({required String currentVersion}) async {
    try {
      final resp = await _client
          .get(Uri.parse(_pubspecUrl))
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) {
        return UpdateStatus.error('HTTP ${resp.statusCode}');
      }
      final match = _versionLine.firstMatch(resp.body);
      if (match == null) {
        return UpdateStatus.error('Version introuvable dans pubspec distant');
      }
      final remote = match.group(1)!.trim();
      if (remote == currentVersion) {
        return UpdateStatus.upToDate(currentVersion);
      }
      return UpdateStatus.updateAvailable(
        currentVersion: currentVersion,
        remoteVersion: remote,
      );
    } catch (e) {
      return UpdateStatus.error('Réseau indisponible');
    }
  }

  void close() => _client.close();
}

/// Etat retourné par [UpdateCheckerService.check].
sealed class UpdateStatus {
  const UpdateStatus();

  factory UpdateStatus.upToDate(String version) = _UpToDate;
  factory UpdateStatus.updateAvailable({
    required String currentVersion,
    required String remoteVersion,
  }) = _UpdateAvailable;
  factory UpdateStatus.error(String message) = _Error;
}

class _UpToDate extends UpdateStatus {
  const _UpToDate(this.version);
  final String version;
}

class _UpdateAvailable extends UpdateStatus {
  const _UpdateAvailable({
    required this.currentVersion,
    required this.remoteVersion,
  });
  final String currentVersion;
  final String remoteVersion;
}

class _Error extends UpdateStatus {
  const _Error(this.message);
  final String message;
}

// Accesseurs : sealed class + factories privées = pattern matching
// `switch (status) { ... }` côté UI sans exposer les classes internes.
extension UpdateStatusAccess on UpdateStatus {
  bool get isUpToDate => this is _UpToDate;
  bool get hasUpdate => this is _UpdateAvailable;
  bool get hasError => this is _Error;

  String? get currentVersion {
    final s = this;
    if (s is _UpToDate) return s.version;
    if (s is _UpdateAvailable) return s.currentVersion;
    return null;
  }

  String? get remoteVersion {
    final s = this;
    if (s is _UpdateAvailable) return s.remoteVersion;
    if (s is _UpToDate) return s.version;
    return null;
  }

  String? get errorMessage {
    final s = this;
    if (s is _Error) return s.message;
    return null;
  }
}
