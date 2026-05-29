import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/bordereau_text_filters.dart';

// Filtres OCR purs (aucun changement de prod) : on verrouille le
// comportement de rejet des faux noms de destinataire.
void main() {
  group('isObviousLabel', () {
    test('libelles techniques -> true', () {
      for (final l in [
        'DESTINATAIRE',
        'MESEXP',
        'Lieu de livraison',
        'ZA de la Chenardiere',
        'Alliance PR',
        'France Alliance',
      ]) {
        expect(BordereauTextFilters.isObviousLabel(l), isTrue, reason: l);
      }
    });
    test('vrai nom client -> false', () {
      expect(BordereauTextFilters.isObviousLabel('NOVA'), isFalse);
      expect(BordereauTextFilters.isObviousLabel('CS-AUTO'), isFalse);
    });
  });

  group('looksLikeStreet', () {
    test('mots de voirie -> true', () {
      expect(BordereauTextFilters.looksLikeStreet('AVENUE LOUIS PASTEUR'),
          isTrue);
      expect(BordereauTextFilters.looksLikeStreet('12 RUE DES LILAS'), isTrue);
      expect(BordereauTextFilters.looksLikeStreet('IMPASSE DE LA CERISAIE'),
          isTrue);
    });
    test('nom sans mot de voirie -> false', () {
      expect(BordereauTextFilters.looksLikeStreet('NOVA'), isFalse);
      expect(BordereauTextFilters.looksLikeStreet('GARAGE CENTRAL'), isFalse);
    });
  });

  group('lineIsStreet', () {
    test('rue numerotee -> true', () {
      expect(
          BordereauTextFilters.lineIsStreet('24 AVENUE LOUIS PASTEUR'), isTrue);
    });
    test('ligne non-rue -> false', () {
      expect(BordereauTextFilters.lineIsStreet('NOVA'), isFalse);
    });
  });

  group('looksLikeCity', () {
    final cities = {'CHARTRES', 'COURVILLE SUR EURE', 'NOGENT', 'ROTROU'};
    test('exact match -> true', () {
      expect(BordereauTextFilters.looksLikeCity('CHARTRES', cities), isTrue);
    });
    test('prefixe avec espace -> true', () {
      expect(
          BordereauTextFilters.looksLikeCity('COURVILLE SUR', cities), isTrue);
    });
    test('tous les mots >=4 dans cityWords -> true', () {
      expect(BordereauTextFilters.looksLikeCity('NOGENT LE ROTROU', cities),
          isTrue);
    });
    test('un mot hors cityWords -> false', () {
      expect(BordereauTextFilters.looksLikeCity('THEODORE CHARTRES', cities),
          isFalse);
    });
    test('cityWords vide -> false', () {
      expect(BordereauTextFilters.looksLikeCity('CHARTRES', {}), isFalse);
    });
  });

  group('isTableHeaderLine', () {
    test('2+ mots-cles -> true', () {
      expect(
          BordereauTextFilters.isTableHeaderLine('Vol/lg Poids U.M. Client Date'),
          isTrue);
      expect(BordereauTextFilters.isTableHeaderLine('Poids Client'), isTrue);
    });
    test('0-1 mot-cle -> false', () {
      expect(BordereauTextFilters.isTableHeaderLine('NOVA'), isFalse);
    });
  });

  group('looksLikeTransporter', () {
    test('mots transporteur -> true', () {
      expect(
          BordereauTextFilters.looksLikeTransporter('EURE ET LOIR ACHEMINEMENT'),
          isTrue);
      expect(BordereauTextFilters.looksLikeTransporter('FA45 TRANSPORTS'),
          isTrue);
    });
    test('vrai client -> false', () {
      expect(BordereauTextFilters.looksLikeTransporter('NOVA'), isFalse);
    });
  });

  group('looksUnreliable', () {
    test('null / vide / trop court -> true', () {
      expect(BordereauTextFilters.looksUnreliable(null), isTrue);
      expect(BordereauTextFilters.looksUnreliable(''), isTrue);
      expect(BordereauTextFilters.looksUnreliable('AB'), isTrue);
    });
    test('numero de reference (>=4 chiffres sans espace) -> true', () {
      expect(BordereauTextFilters.looksUnreliable('FA280000440358'), isTrue);
      expect(BordereauTextFilters.looksUnreliable('72070741'), isTrue);
    });
    test('mot technique -> true', () {
      expect(BordereauTextFilters.looksUnreliable('FACTURE'), isTrue);
      expect(BordereauTextFilters.looksUnreliable('ENLEVEMENT'), isTrue);
    });
    test('vrai nom court legitime -> false', () {
      expect(BordereauTextFilters.looksUnreliable('NOVA'), isFalse);
      expect(BordereauTextFilters.looksUnreliable('GARAGE CABARET'), isFalse);
    });
  });
}
