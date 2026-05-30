import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/voice_command_parser.dart';

void main() {
  group('VoiceCommandParser.parse', () {
    test('chaine vide -> unknown', () {
      expect(VoiceCommandParser.parse(''), VoiceCommand.unknown);
    });

    test('"livré" simple -> livre', () {
      expect(VoiceCommandParser.parse('livré'), VoiceCommand.livre);
    });

    test('variantes "livré" (accents, casse, mots autour) -> livre', () {
      expect(VoiceCommandParser.parse('Livré'), VoiceCommand.livre);
      expect(VoiceCommandParser.parse('ok livré'), VoiceCommand.livre);
      expect(VoiceCommandParser.parse('c\'est livré'), VoiceCommand.livre);
      expect(VoiceCommandParser.parse('J\'AI LIVRE !'), VoiceCommand.livre);
      expect(VoiceCommandParser.parse('déposé'), VoiceCommand.livre);
    });

    test('"echec" et variantes -> echec', () {
      expect(VoiceCommandParser.parse('échec'), VoiceCommand.echec);
      expect(VoiceCommandParser.parse('absent'), VoiceCommand.echec);
      expect(VoiceCommandParser.parse('refusé'), VoiceCommand.echec);
      expect(VoiceCommandParser.parse('client absent'), VoiceCommand.echec);
    });

    test('"passer" et variantes -> passer', () {
      expect(VoiceCommandParser.parse('passer'), VoiceCommand.passer);
      expect(VoiceCommandParser.parse('skip'), VoiceCommand.passer);
      expect(VoiceCommandParser.parse('suivant'), VoiceCommand.passer);
      expect(VoiceCommandParser.parse('on saute'), VoiceCommand.passer);
    });

    test('"stop" et variantes -> stop', () {
      expect(VoiceCommandParser.parse('stop'), VoiceCommand.stop);
      expect(VoiceCommandParser.parse('annuler'), VoiceCommand.stop);
      expect(VoiceCommandParser.parse('arrête'), VoiceCommand.stop);
      expect(VoiceCommandParser.parse('cancel'), VoiceCommand.stop);
    });

    test('texte sans mot-cle -> unknown', () {
      expect(VoiceCommandParser.parse('bonjour'), VoiceCommand.unknown);
      expect(VoiceCommandParser.parse('rue de la paix'), VoiceCommand.unknown);
      expect(VoiceCommandParser.parse('Il fait beau'), VoiceCommand.unknown);
    });

    test('matching mot entier : "depasser" NE matche PAS passer', () {
      // "depasser" contient "passer" en suffixe mais a "de" devant
      // -> pas un mot entier -> on ne doit pas matcher.
      expect(VoiceCommandParser.parse('je vais le depasser'),
          VoiceCommand.unknown);
      expect(VoiceCommandParser.parse('depasser'), VoiceCommand.unknown);
      // En revanche "passer" entoure d'espaces -> match.
      expect(VoiceCommandParser.parse('on va passer'), VoiceCommand.passer);
    });

    test('priorite stop > echec > livre > passer', () {
      // Si on dit "ok livré stop", c'est stop (annulation prioritaire).
      expect(VoiceCommandParser.parse('ok livré stop'), VoiceCommand.stop);
      // "echec livré" -> echec (la negation l'emporte sur la validation).
      expect(VoiceCommandParser.parse('echec livré'), VoiceCommand.echec);
    });

    test('ponctuation et espaces ignores', () {
      expect(VoiceCommandParser.parse('  livré.'), VoiceCommand.livre);
      expect(VoiceCommandParser.parse('livré!'), VoiceCommand.livre);
      expect(VoiceCommandParser.parse('  '), VoiceCommand.unknown);
    });
  });
}
