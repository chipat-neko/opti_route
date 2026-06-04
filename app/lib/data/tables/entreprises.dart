import 'package:drift/drift.dart';

/// Mirroir local de la table cloud `entreprises` (Supabase).
///
/// Une entreprise = un compte parent qui regroupe N entrepôts et N
/// employés. Créée par un user qui devient `admin_entreprise` dans
/// `entreprise_users`.
///
/// Carte Trello #361/#362 (épopée multi-tenant 2026-05-31).
///
/// Côté local : on stocke un miroir minimal pour l'UI offline et
/// pour faire les FK locales depuis `saved_destinations.entrepriseId`.
/// La source de vérité reste Supabase ; le sync se fait via
/// `CloudSyncService` (PR ultérieure).
class Entreprises extends Table {
  /// `cloud_id` UUID v4 (TEXT) = clé primaire locale ET cloud.
  /// Pas d'auto-increment : l'ID est généré côté Supabase puis miroir
  /// local. Simplifie la sync (1 ID partout, pas de mapping).
  TextColumn get cloudId => text()();

  TextColumn get nom => text()();

  /// SIRET (14 chiffres) optionnel. Stocké en TEXT pour préserver
  /// les zéros de tête (ex: "01234567890123").
  TextColumn get siret => text().nullable()();

  /// User qui a créé l'entreprise (= admin_entreprise initial).
  /// Stocke l'UUID Supabase de auth.users.
  TextColumn get createdBy => text()();

  DateTimeColumn get creeLe => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Code du plan/abonnement de l'entreprise (#381-A, carte #388).
  /// Défaut `illimite` = grandfathering : les entreprises existantes ne
  /// sont jamais bridées. AUCUNE limite n'est appliquée à ce stade
  /// (le bridage = #381-C) — cette colonne sert seulement à exposer un
  /// badge informatif. Valeurs : free | tier1 | tier2 | tier3 | illimite.
  TextColumn get plan =>
      text().withDefault(const Constant('illimite'))();

  @override
  Set<Column> get primaryKey => {cloudId};
}
