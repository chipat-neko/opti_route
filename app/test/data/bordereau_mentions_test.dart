import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/bordereau_mentions.dart';

void main() {
  group('BordereauMentions.detect (#329)', () {
    test('texte vide', () {
      expect(BordereauMentions.detect(''), isEmpty);
    });
    test('SIGN/RECOMMAND -> signatureRequired', () {
      expect(
        BordereauMentions.detect('Pli RECOMMANDE avec SIGN'),
        contains(BordereauMention.signatureRequired),
      );
    });
    test('FRAGILE + VERRE -> fragile (dedup)', () {
      final r = BordereauMentions.detect('VERRE FRAGILE');
      expect(r, hasLength(1));
      expect(r.first, BordereauMention.fragile);
    });
    test('+18 / MAJEUR -> adultRequired', () {
      expect(
        BordereauMentions.detect('Livraison +18 obligatoire'),
        contains(BordereauMention.adultRequired),
      );
      expect(
        BordereauMentions.detect('MAJEUR signature'),
        containsAll([
          BordereauMention.adultRequired,
          BordereauMention.signatureRequired,
        ]),
      );
    });
    test('ordonnance -> medication', () {
      expect(
        BordereauMentions.detect('Ordonnance MEDICALE prioritaire'),
        contains(BordereauMention.medication),
      );
    });
  });

  group('BordereauMentions.requiresProofPhoto (#329)', () {
    test('sign + +18 -> photo obligatoire', () {
      expect(
        BordereauMentions.requiresProofPhoto(BordereauMention.signatureRequired),
        isTrue,
      );
      expect(
        BordereauMentions.requiresProofPhoto(BordereauMention.adultRequired),
        isTrue,
      );
    });
    test('fragile/rdv/frais -> non bloquant', () {
      expect(
        BordereauMentions.requiresProofPhoto(BordereauMention.fragile),
        isFalse,
      );
      expect(
        BordereauMentions.requiresProofPhoto(BordereauMention.rendezVous),
        isFalse,
      );
    });
  });
}
