// Tests de la normalisation de texte partagee (F26 volet 2).
//
// Avant la factorisation, huit modules embarquaient leur propre copie
// de `_normalize`. Ces tests figent le contrat des deux fonctions
// publiques ET verifient, site d'appel par site d'appel, que la
// substitution n'a rien change au comportement observable.

import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/client_memory_service.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/voice_command_parser.dart';
import 'package:opti_route/utils/text_normalize.dart';

void main() {
  group('normalizeText', () {
    test('chaine vide et espaces seuls -> chaine vide', () {
      expect(normalizeText(''), '');
      expect(normalizeText('   '), '');
      expect(normalizeText('\n\t '), '');
    });

    test('casse ramenee en minuscules', () {
      expect(normalizeText('CHARTRES'), 'chartres');
      expect(normalizeText('ChArTrEs'), 'chartres');
    });

    test('accents replies sur leur equivalent ASCII', () {
      expect(normalizeText('Lucé'), 'luce');
      expect(normalizeText('à â ä á ã'), 'a a a a a');
      expect(normalizeText('è é ê ë'), 'e e e e');
      expect(normalizeText('î ï í ì'), 'i i i i');
      expect(normalizeText('ô ö ó õ'), 'o o o o');
      expect(normalizeText('ù û ü ú'), 'u u u u');
      expect(normalizeText('ÿ ý'), 'y y');
      expect(normalizeText('ç'), 'c');
      expect(normalizeText('ñ'), 'n');
    });

    test('ligature oe depliee en 2 lettres (fix #515)', () {
      expect(normalizeText('cœur'), 'coeur');
      expect(normalizeText('CŒUR'), 'coeur');
      expect(normalizeText('Sœur Emmanuelle'), 'soeur emmanuelle');
      // La ligature rend DEUX caracteres : la longueur de sortie peut
      // depasser celle de l'entree.
      expect(normalizeText('œ').length, 2);
    });

    test('ligature ae depliee en 2 lettres', () {
      expect(normalizeText('nævus'), 'naevus');
      expect(normalizeText('CURRICULUM VITÆ'), 'curriculum vitae');
    });

    test('trim des bords mais espaces internes preserves', () {
      expect(normalizeText('  Nogent '), 'nogent');
      expect(normalizeText('rue   de   la   paix'), 'rue   de   la   paix');
    });

    test('ponctuation et chiffres laisses intacts', () {
      expect(normalizeText("12 Bd d'Orléans, 28000"), "12 bd d'orleans, 28000");
    });

    test('idempotente', () {
      const brut = '  GARAGE LANCTIN, Lucé (28) - cœur de ville ';
      expect(normalizeText(normalizeText(brut)), normalizeText(brut));
    });
  });

  group('normalizeKey', () {
    test('chaine vide et espaces seuls -> chaine vide', () {
      expect(normalizeKey(''), '');
      expect(normalizeKey('   '), '');
    });

    test('minuscules + trim + espaces multiples aplatis', () {
      expect(
        normalizeKey('  12 RUE   Aristide  Briand  '),
        '12 rue aristide briand',
      );
      expect(normalizeKey('a\t\nb'), 'a b');
    });

    test('accents CONSERVES (la cle est persistee en base)', () {
      expect(normalizeKey('Rue de Lucé'), 'rue de lucé');
      expect(normalizeKey('CŒUR'), 'cœur');
    });

    test('idempotente', () {
      const brut = '  12  Rue   de Lucé ';
      expect(normalizeKey(normalizeKey(brut)), normalizeKey(brut));
    });

    test('les deux fonctions ne sont PAS interchangeables', () {
      // normalizeText replie les accents, normalizeKey non.
      expect(normalizeText('Lucé'), isNot(normalizeKey('Lucé')));
      // normalizeKey aplatit les espaces, normalizeText non.
      expect(normalizeKey('a  b'), isNot(normalizeText('a  b')));
    });
  });

  group('non-regression par site d\'appel migre', () {
    test(
        'recherche du carnet (saved_destinations_repository + '
        'carnet_adresses_screen) : "luce" matche "Lucé"', () {
      // Meme construction du foin que dans le repository : champs
      // normalises un par un puis joints.
      final hay = [
        normalizeText('Boulangerie Crème'),
        normalizeText('12 Avenue de la Gare'),
        normalizeText('Lucé'),
      ].join(' ');
      expect(hay.contains(normalizeText('luce')), isTrue);
      expect(hay.contains(normalizeText('CRÈME')), isTrue);
      expect(hay.contains(normalizeText('creme')), isTrue);
      expect(hay.contains(normalizeText('nogent')), isFalse);
    });

    test('filtre des arrets (stops_section) : le trim ajoute sur le foin '
        'ne change pas le resultat du contains', () {
      // Ancien code : la requete etait trimee AVANT l'appel, le foin ne
      // l'etait pas. normalizeText trim les deux ; comme la requete
      // normalisee ne peut ni commencer ni finir par un espace, aucune
      // occurrence ne peut chevaucher les espaces de bordure retires.
      final hay = normalizeText(
        ['', '  12 rue des Lilas  ', '', 'porte à côté'].join(' '),
      );
      expect(hay.contains(normalizeText('  lilas ')), isTrue);
      expect(hay.contains(normalizeText('porte a cote')), isTrue);
      expect(hay.contains(normalizeText('inconnu')), isFalse);
    });

    test('cle du cache de geocodage (geocode_cache_repository) inchangee', () {
      expect(
        normalizeKey('  12 Rue   de la Paix, PARIS '),
        '12 rue de la paix, paris',
      );
      // Si on repliait les accents ici, toutes les lignes deja ecrites
      // dans `geocode_cache` deviendraient orphelines.
      expect(normalizeKey('Lucé'), 'lucé');
    });

    test('groupage des arrets (stop_grouping) : meme adresse a la casse '
        'et aux espaces pres', () {
      expect(
        normalizeKey('12 Rue Aristide Briand'),
        normalizeKey('  12 RUE   Aristide  Briand  '),
      );
      // ... mais 2 adresses qui ne different que par un accent restent
      // distinctes, comme avant la factorisation.
      expect(normalizeKey('rue de Lucé'), isNot(normalizeKey('rue de Luce')));
    });

    test('fuzzy match client (client_memory_service) : casse et accents '
        'ignores', () {
      final carnet = [_dest(1, 'GARAGE LANCTIN', 'Courville')];
      expect(
        ClientMemoryService.matchInList('garage lanctin', carnet)?.nomClient,
        'GARAGE LANCTIN',
      );
      expect(
        ClientMemoryService.matchInList('Garage Lànctin', carnet)?.nomClient,
        'GARAGE LANCTIN',
      );
      expect(
        ClientMemoryService.matchInList('BOULANGERIE DUPONT', carnet),
        isNull,
      );
    });

    test('commandes vocales (voice_command_parser) : cas historiques '
        'preserves', () {
      expect(VoiceCommandParser.parse("c'est livré"), VoiceCommand.livre);
      expect(VoiceCommandParser.parse('  livré.'), VoiceCommand.livre);
      expect(VoiceCommandParser.parse('depasser'), VoiceCommand.unknown);
      expect(VoiceCommandParser.parse('ok livré stop'), VoiceCommand.stop);
      expect(VoiceCommandParser.parse('  '), VoiceCommand.unknown);
      // Le parser replie desormais aussi la ligature oe (il ne la
      // connaissait pas avant). Aucun mot-cle ne contient "oe" ni "ae",
      // donc aucun faux positif n'est introduit.
      expect(
        VoiceCommandParser.parse('le cœur de ville'),
        VoiceCommand.unknown,
      );
      expect(
        VoiceCommandParser.parse('livré au cœur de ville'),
        VoiceCommand.livre,
      );
    });
  });
}

/// Entree de carnet minimale pour tester [ClientMemoryService.matchInList]
/// sans ouvrir de base (la methode est pure).
SavedDestination _dest(int id, String nom, String ville) {
  final now = DateTime(2026, 6, 1);
  return SavedDestination(
    id: id,
    nomClient: nom,
    adresseDisplay: '1 rue X, $ville',
    lat: 48.0,
    lng: 1.0,
    ville: ville,
    useCount: 1,
    lastUsedAt: now,
    creeLe: now,
    isFavori: false,
    updatedAt: now,
    isProblematique: false,
    photoObligatoire: false,
  );
}
