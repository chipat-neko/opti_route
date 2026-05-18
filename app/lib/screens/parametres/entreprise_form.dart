import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/parametres_repository.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Formulaire "Profil entreprise" — section Parametres.
/// ════════════════════════════════════════════════════════════════
///
/// Trois champs optionnels pour personnaliser les exports PDF /
/// texte du chef d'equipe :
///   - nom raison sociale (ex: "CALOTE Transports")
///   - SIRET (14 chiffres)
///   - slogan / mention (ex: "Livraison express 7j/7")
///
/// Persistance : sur `onEditingComplete` (perte de focus / submit
/// clavier) et au dispose du widget. Pas de bouton "Sauvegarder"
/// explicite, l'enregistrement est automatique. Pas de validation
/// stricte (les formats varient entre entreprises).
///
/// Si un champ est vide, l'entree correspondante est supprimee
/// dans le ParametresRepository plutot que stockee comme chaine vide.
class EntrepriseForm extends ConsumerStatefulWidget {
  const EntrepriseForm({super.key});

  @override
  ConsumerState<EntrepriseForm> createState() => _EntrepriseFormState();
}

class _EntrepriseFormState extends ConsumerState<EntrepriseForm> {
  final _nomCtrl = TextEditingController();
  final _siretCtrl = TextEditingController();
  final _sloganCtrl = TextEditingController();
  // Indique si la lecture initiale en base a abouti. Sert a eviter de
  // persister des chaines vides au dispose si l'utilisateur n'a meme
  // pas vu le formulaire (build avant _load).
  bool _loaded = false;

  /// Reference capturee au build pour reutiliser dans dispose() sans
  /// repasser par `ref.read` (interdit apres unmount avec Riverpod >=2).
  /// Cf bug fix 2026-05-18 : crash "Using ref when widget is about to
  /// or has been unmounted" qui crashait la rebuild loop.
  ParametresRepository? _capturedRepo;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Charge les 3 valeurs depuis Drift en parallele et remplit les
  /// controllers. Marque `_loaded` pour permettre la sauvegarde au
  /// dispose.
  Future<void> _load() async {
    final repo = ref.read(parametresRepositoryProvider);
    _capturedRepo = repo;
    final nom = await repo.getEntrepriseNom();
    final siret = await repo.getEntrepriseSiret();
    final slogan = await repo.getEntrepriseSlogan();
    if (!mounted) return;
    setState(() {
      _nomCtrl.text = nom ?? '';
      _siretCtrl.text = siret ?? '';
      _sloganCtrl.text = slogan ?? '';
      _loaded = true;
    });
  }

  @override
  void dispose() {
    // Sauvegarde finale si modifs en attente (l'utilisateur sort de
    // l'ecran Parametres avant d'avoir tape Done). Pas de `ref.read`
    // ici -- Riverpod >=2 interdit l'acces a `ref` apres unmount, on
    // utilise la reference capturee pendant `_load()`.
    if (_loaded && _capturedRepo != null) {
      _persistAll();
    }
    _nomCtrl.dispose();
    _siretCtrl.dispose();
    _sloganCtrl.dispose();
    super.dispose();
  }

  /// Persiste les 3 valeurs en base. Si un champ est vide (trim),
  /// on supprime l'entree au lieu de stocker la chaine vide -> les
  /// templates PDF / texte ne tenteront pas d'afficher une ligne
  /// vide.
  ///
  /// Utilise [_capturedRepo] (capture au build dans `_load`) pour
  /// fonctionner aussi quand on est appele depuis `dispose()` --
  /// Riverpod >=2 interdit `ref.read` apres unmount. No-op si le
  /// repo n'a jamais ete capture (cas anormal : appel avant _load).
  Future<void> _persistAll() async {
    final repo = _capturedRepo;
    if (repo == null) return;
    final nom = _nomCtrl.text.trim();
    final siret = _siretCtrl.text.trim();
    final slogan = _sloganCtrl.text.trim();
    if (nom.isEmpty) {
      await repo.clearEntrepriseNom();
    } else {
      await repo.setEntrepriseNom(nom);
    }
    if (siret.isEmpty) {
      await repo.clearEntrepriseSiret();
    } else {
      await repo.setEntrepriseSiret(siret);
    }
    if (slogan.isEmpty) {
      await repo.clearEntrepriseSlogan();
    } else {
      await repo.setEntrepriseSlogan(slogan);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _nomCtrl,
          decoration: const InputDecoration(
            labelText: 'Nom / raison sociale (optionnel)',
            hintText: 'Ex: CALOTE Transports',
            prefixIcon: Icon(Icons.business_outlined),
          ),
          onEditingComplete: _persistAll,
        ),
        const SizedBox(height: AppSpacing.x10),
        TextField(
          controller: _siretCtrl,
          decoration: const InputDecoration(
            labelText: 'SIRET (optionnel)',
            hintText: '14 chiffres',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          keyboardType: TextInputType.number,
          maxLength: 14,
          onEditingComplete: _persistAll,
        ),
        const SizedBox(height: AppSpacing.x10),
        TextField(
          controller: _sloganCtrl,
          decoration: const InputDecoration(
            labelText: 'Slogan / mention (optionnel)',
            hintText: 'Ex: Livraison express 7j/7',
            prefixIcon: Icon(Icons.format_quote_outlined),
          ),
          onEditingComplete: _persistAll,
        ),
      ],
    );
  }
}
