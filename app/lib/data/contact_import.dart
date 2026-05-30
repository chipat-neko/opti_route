import 'package:drift/drift.dart' show Value;

import 'database.dart';

/// Modele intermediaire d'un contact telephone, decouple du plugin
/// natif Android (contacts_service / flutter_contacts). Permet de
/// tester l'import sans depender d'une permission systeme. Carte #300.
class PhoneContact {
  const PhoneContact({
    required this.displayName,
    this.phone,
    this.address,
  });
  final String displayName;
  final String? phone;
  final String? address;
}

/// Genere les SavedDestinationsCompanion a inserer depuis une liste
/// de [PhoneContact]. Skip les contacts sans adresse (le carnet
/// opti_route a besoin d'une adresse minimum).
class ContactImport {
  ContactImport._();

  static List<SavedDestinationsCompanion> mapToCompanions(
    List<PhoneContact> contacts, {
    double? defaultLat,
    double? defaultLng,
  }) {
    final out = <SavedDestinationsCompanion>[];
    for (final c in contacts) {
      final addr = (c.address ?? '').trim();
      if (addr.isEmpty) continue;
      out.add(SavedDestinationsCompanion.insert(
        nomClient: Value(c.displayName.isEmpty ? null : c.displayName),
        adresseDisplay: addr,
        lat: defaultLat ?? 0,
        lng: defaultLng ?? 0,
        telephone: Value(c.phone),
      ));
    }
    return out;
  }
}
