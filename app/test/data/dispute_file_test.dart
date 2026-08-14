import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/dispute_file.dart';

void main() {
  late AppDatabase db;
  late int tId;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tId = await db.into(db.tournees).insert(TourneesCompanion.insert(
        nom: 'T',
        date: DateTime(2026, 5, 30),
        pointDepartLat: 48.0,
        pointDepartLng: 1.0,
        pointDepartLabel: 'D'));
  });
  tearDown(() async => db.close());

  Future<Stop> seed({
    String statut = 'livre',
    String? raison,
    DateTime? livreLe,
    double? livreLat,
    double? livreLng,
    String? photo,
    bool sansContact = false,
    String? tracking,
    String? nom,
  }) async {
    final id = await db.into(db.stops).insert(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: '1 rue X',
        nomClient: Value(nom),
        statutLivraison: Value(statut),
        raisonEchec: Value(raison),
        livreLe: Value(livreLe),
        livreLat: Value(livreLat),
        livreLng: Value(livreLng),
        preuvePhotoPath: Value(photo),
        deposeSansContact: Value(sansContact),
        trackingNumbers: Value(tracking)));
    return (db.select(db.stops)..where((s) => s.id.equals(id))).getSingle();
  }

  group('DisputeFile.compose (#311)', () {
    test('contenu minimal + hash stable', () async {
      final s = await seed(
        statut: 'livre',
        livreLe: DateTime(2026, 5, 30, 14, 7),
        livreLat: 48.123,
        livreLng: 1.456,
      );
      final t = DateTime(2026, 5, 30, 18);
      final d1 = DisputeFile.compose(stop: s, now: t);
      final d2 = DisputeFile.compose(stop: s, now: t);
      expect(d1.body, contains('DOSSIER LITIGE'));
      expect(d1.body, contains('30/05/2026 14:07'));
      expect(d1.body, contains('48.12300,1.45600'));
      expect(d1.hash.length, 64);
      expect(d1.isOpposable, isTrue);
      expect(d1.hash, d2.hash, reason: 'hash deterministe');
    });

    test('echec + raison + photo + sans contact', () async {
      final s = await seed(
        statut: 'echec',
        raison: 'absent',
        livreLe: DateTime(2026, 5, 1, 9),
        photo: '/app_documents/preuves/1_xxx.jpg',
        sansContact: true,
        tracking: '["FA1","FA2"]',
        nom: 'M. Dupont',
      );
      final d = DisputeFile.compose(
          stop: s, now: DateTime(2026, 5, 1, 10));
      expect(d.body, contains('Statut     : echec'));
      expect(d.body, contains('Raison     : absent'));
      expect(d.body, contains('M. Dupont'));
      expect(d.body, contains('FA1'));
      expect(d.body, contains('DEPOSE SANS CONTACT'));
      expect(d.body, contains('preuves/1_xxx.jpg'));
    });

    test('pas de livreLe -> mention non livre', () async {
      final s = await seed(statut: 'a_livrer');
      final d = DisputeFile.compose(
          stop: s, now: DateTime(2026, 5, 30));
      expect(d.body, contains('(non livre)'));
      expect(d.body, contains('GPS indisponible'));
    });

    test('sans photo : le dossier dit qu\'il n\'y en a jamais eu',
        () async {
      final s = await seed(statut: 'livre');
      final d = DisputeFile.compose(stop: s, now: DateTime(2026, 5, 30));
      expect(d.photoState, DisputePhotoState.aucune);
      expect(d.photoHash, isNull);
      expect(d.coversPhoto, isFalse);
      expect(d.body, contains('AUCUNE photo preuve'));
      expect(d.body, contains('Aucune image n\'est couverte'));
      // "jamais prise" et "pas pu etre lue" ne racontent pas la meme
      // histoire face a un client : le dossier doit dire laquelle.
      expect(d.body, contains('aucune photo preuve n\'a jamais ete prise'));
      expect(d.body, isNot(contains('n\'a pas pu etre lu')));
    });

    test('hash change si stop change', () async {
      final s1 = await seed(
        statut: 'livre',
        livreLe: DateTime(2026, 5, 30, 14),
        livreLat: 48,
        livreLng: 1,
      );
      final s2 = await seed(
        statut: 'livre',
        livreLe: DateTime(2026, 5, 30, 14),
        livreLat: 49,
        livreLng: 1,
      );
      final t = DateTime(2026, 5, 30, 18);
      final d1 = DisputeFile.compose(stop: s1, now: t);
      final d2 = DisputeFile.compose(stop: s2, now: t);
      expect(d1.hash, isNot(d2.hash));
    });
  });

  /// Le hash doit couvrir le TEXTE **et** l'image : sinon on peut
  /// remplacer la photo preuve par une autre sans que la signature
  /// bouge, et le mot "opposable" ne veut plus rien dire.
  group('DisputeFile.compose - portee du hash sur la photo', () {
    const octetsA = <int>[1, 2, 3, 4, 5];
    const octetsB = <int>[1, 2, 3, 4, 6];
    final t = DateTime(2026, 5, 30, 18);

    Future<Stop> seedAvecPhoto() => seed(
          statut: 'livre',
          livreLe: DateTime(2026, 5, 30, 14, 7),
          livreLat: 48.123,
          livreLng: 1.456,
          photo: '/app_documents/preuves/1_xxx.jpg',
        );

    test('avec octets : empreinte photo dans le corps + hash etendu',
        () async {
      final s = await seedAvecPhoto();
      final avec = DisputeFile.compose(stop: s, now: t, photoBytes: octetsA);
      final sans = DisputeFile.compose(stop: s, now: t);

      expect(avec.photoState, DisputePhotoState.jointe);
      expect(avec.coversPhoto, isTrue);
      expect(avec.photoHash, isNotNull);
      expect(avec.photoHash!.length, 64);
      expect(avec.body, contains(avec.photoHash!));
      // Le corps annonce ce que la signature couvre.
      expect(avec.body, contains('empreinte de la photo comprise'));
      expect(avec.isOpposable, isTrue);
      // Meme stop, meme instant : seule la presence de l'image change.
      expect(avec.hash, isNot(sans.hash));
    });

    test('memes octets, meme entree : hash stable', () async {
      final s = await seedAvecPhoto();
      final d1 = DisputeFile.compose(stop: s, now: t, photoBytes: octetsA);
      final d2 = DisputeFile.compose(
          stop: s, now: t, photoBytes: List<int>.from(octetsA));
      expect(d1.hash, d2.hash, reason: 'hash deterministe');
      expect(d1.photoHash, d2.photoHash);
    });

    test('photo substituee : le hash casse', () async {
      final s = await seedAvecPhoto();
      final d1 = DisputeFile.compose(stop: s, now: t, photoBytes: octetsA);
      final d2 = DisputeFile.compose(stop: s, now: t, photoBytes: octetsB);
      expect(d1.photoHash, isNot(d2.photoHash));
      expect(d1.hash, isNot(d2.hash),
          reason: 'remplacer l\'image doit casser la signature');
    });

    test('fichier disparu du stockage : le dossier le dit', () async {
      // Cas frequent : photo prise puis cache nettoye. Le stop porte
      // toujours un chemin, mais le caller n'a pas pu lire d'octets.
      final s = await seedAvecPhoto();
      final d = DisputeFile.compose(stop: s, now: t);

      expect(d.photoState, DisputePhotoState.introuvable);
      expect(d.photoHash, isNull);
      expect(d.coversPhoto, isFalse);
      expect(d.body, contains('ABSENTE DU STOCKAGE'));
      expect(d.body, contains('Aucune image n\'est couverte'));
      // Le motif exact : le fichier existait, il n'a pas pu etre lu.
      expect(d.body, contains('n\'a pas pu etre lu'));
      expect(d.body, isNot(contains('jamais ete prise')));
      // Le dossier reste exploitable malgre la photo manquante.
      expect(d.isOpposable, isTrue);
      expect(d.body, contains('preuves/1_xxx.jpg'));
    });

    test('fichier de 0 octet : pas de fausse couverture', () async {
      // Un JPG tronque a 0 octet est une photo illisible. Sans garde,
      // le dossier signait l'empreinte du vide (e3b0c442...) et se
      // declarait "photo jointe et signee" : une garantie mensongere.
      final s = await seedAvecPhoto();
      final d = DisputeFile.compose(stop: s, now: t, photoBytes: const []);

      expect(d.photoState, DisputePhotoState.introuvable);
      expect(d.photoHash, isNull);
      expect(d.coversPhoto, isFalse);
      expect(d.body, isNot(contains('Photo SHA')));
      expect(d.body, contains('Aucune image n\'est couverte'));
    });
  });
}
