import 'database.dart';

/// Gravite d'une anomalie de tournee (carte #122).
enum AnomalieSeverite { info, attention, critique }

/// Une anomalie detectee sur la tournee en cours.
class Anomalie {
  const Anomalie(this.severite, this.message);

  final AnomalieSeverite severite;
  final String message;

  @override
  bool operator ==(Object other) =>
      other is Anomalie &&
      other.severite == severite &&
      other.message == message;

  @override
  int get hashCode => Object.hash(severite, message);

  @override
  String toString() => 'Anomalie($severite, $message)';
}

/// Detecte des anomalies sur une tournee EN COURS pour alerter le
/// livreur (carte #122). Fonction PURE : prend la tournee + ses stops +
/// l'heure courante (injectee pour etre deterministe et testable),
/// retourne la liste des anomalies (vide si rien d'anormal).
///
/// Heuristiques deterministes implementees :
/// - **Taux d'echec eleve** (> 20% sur >= 5 tentatives) -> critique.
/// - **Inactivite** : tournee demarree, des arrets restent a livrer,
///   mais aucune validation depuis >= 2h -> attention ("tu es bloque ?").
/// - **A cloturer** : tous les arrets traites mais statut encore
///   en_cours -> info.
///
/// (Les anomalies "stop a >50km" et "meme client 3 echecs" du brief
/// necessitent l'ordre/historique et sont laissees pour une iteration
/// ulterieure.)
class AnomalyDetectionService {
  AnomalyDetectionService._();

  static const double kSeuilTauxEchec = 0.20;
  static const int kMinTentatives = 5;
  static const Duration kInactiviteSeuil = Duration(hours: 2);

  static List<Anomalie> detect({
    required Tournee tournee,
    required List<Stop> stops,
    required DateTime now,
  }) {
    if (stops.isEmpty) return const [];

    // Cas particulier #274 : tournee marquee terminee mais reste des
    // arrets a_livrer (statut force depuis tournees_list_screen, ou
    // bug de bascule). On alerte au cas ou des colis traineraient
    // encore dans le camion.
    if (tournee.statut == 'terminee') {
      final aLivrer = stops.where((s) => s.statutLivraison == 'a_livrer');
      if (aLivrer.isNotEmpty) {
        final colisOublies = aLivrer.fold<int>(0, (sum, s) => sum + s.nbColis);
        return [
          Anomalie(
            AnomalieSeverite.critique,
            'Tournee terminee mais ${aLivrer.length} arret(s) jamais '
            'valide(s) ($colisOublies colis). Verifie le camion !',
          ),
        ];
      }
      return const [];
    }

    // Au-dela : on ne surveille que les tournees en cours.
    if (tournee.statut != 'en_cours') return const [];

    final livres = stops.where((s) => s.statutLivraison == 'livre').length;
    final echecs = stops.where((s) => s.statutLivraison == 'echec').length;
    final total = stops.length;
    final restants = total - livres - echecs;
    final tentatives = livres + echecs;

    final out = <Anomalie>[];

    // 1. Taux d'echec eleve.
    if (tentatives >= kMinTentatives) {
      final taux = echecs / tentatives;
      if (taux > kSeuilTauxEchec) {
        final pct = (taux * 100).round();
        out.add(Anomalie(
          AnomalieSeverite.critique,
          'Taux d\'echec eleve : $pct% ($echecs sur $tentatives). '
          'Verifie les adresses / pre-appelle les clients.',
        ));
      }
    }

    // 2. Inactivite : aucune validation depuis >= 2h alors qu'il reste
    //    des arrets. lastActivity = derniere validation (livreLe), ou
    //    le demarrage si aucune validation encore.
    if (restants > 0 && tournee.demareeLe != null) {
      DateTime lastActivity = tournee.demareeLe!;
      for (final s in stops) {
        final t = s.livreLe;
        if (t != null && t.isAfter(lastActivity)) lastActivity = t;
      }
      final inactif = now.difference(lastActivity);
      if (inactif >= kInactiviteSeuil) {
        final h = inactif.inHours;
        out.add(Anomalie(
          AnomalieSeverite.attention,
          'Aucune livraison validee depuis ${h}h. Tout va bien ?',
        ));
      }
    }

    // 3. Tout traite mais tournee encore en cours.
    if (restants == 0 && total > 0) {
      out.add(const Anomalie(
        AnomalieSeverite.info,
        'Tous les arrets sont traites — pense a cloturer la tournee.',
      ));
    }

    out.sort((a, b) => b.severite.index.compareTo(a.severite.index));
    return out;
  }
}
