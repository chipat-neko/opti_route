# Index de la documentation `docs/`

Point d'entrée de la documentation projet. Les fichiers sont regroupés
par thème ; les rapports datés (audits, sessions, checklists) sont des
**archives** conservées pour l'historique — ils ne reflètent pas
forcément l'état courant du code.

> Pour l'architecture et les conventions, voir plutôt
> [`../ARCHITECTURE.md`](../ARCHITECTURE.md) ; pour l'historique des
> versions, [`../CHANGELOG.md`](../CHANGELOG.md).

## Produit & plans

- [plan_free.md](plan_free.md) — plan de la version gratuite (Phase 1)
- [plan_cb.md](plan_cb.md) — plan de la version payante (Google Maps Platform)
- [plan-gps-integre.md](plan-gps-integre.md) — navigation GPS turn-by-turn intégrée
- [plans-381a-implementation.md](plans-381a-implementation.md) — implémentation des « plans » #381-A
- [role-classification.md](role-classification.md) — rôles et classification

## Guide & usage

- [user-guide.md](user-guide.md) — guide utilisateur exhaustif
- [ocr-france-alliance.md](ocr-france-alliance.md) — parser OCR France Alliance
- [play_store/listing.md](play_store/listing.md) — fiche Play Store

## Cloud (Supabase)

- [supabase-setup.md](supabase-setup.md) — mise en place du backend
- [supabase-rls.md](supabase-rls.md) — politiques Row Level Security
- Schémas SQL (l'état réel = empilement des trois) :
  - [supabase-schema.sql](supabase-schema.sql)
  - [supabase-schema-multi-tenant.sql](supabase-schema-multi-tenant.sql)
  - [supabase-schema-plans-381a.sql](supabase-schema-plans-381a.sql)

## Build & release

- [keystore-release.md](keystore-release.md) — génération de la keystore + signature
- [windows-update.md](windows-update.md) — procédure de mise à jour Windows (MSIX)
- [_build_pdf.py](_build_pdf.py) — génération PDF des docs Markdown

## Légal

- [legal/privacy-policy.md](legal/privacy-policy.md) — politique de confidentialité
- [legal/cgu.md](legal/cgu.md) — conditions générales d'utilisation

## Design

- [design/handoff/](design/handoff/) — handoff Claude Design (écrans cibles + tokens)

## Archives datées (historique, non maintenu)

Conservées pour la traçabilité. **Ne pas s'y fier pour l'état courant.**

- [journal-de-bord.md](journal-de-bord.md) — journal de bord
- [session-2026-05-11-autonome.md](session-2026-05-11-autonome.md) — récap session
- [session-2026-05-12-terrain.md](session-2026-05-12-terrain.md) — récap session
- [audit-2026-05-10.md](audit-2026-05-10.md)
- [audit-site_doc-2026-05-14.md](audit-site_doc-2026-05-14.md)
- [deps-audit-2026-05-14.md](deps-audit-2026-05-14.md)
- [checklist-tests-2026-05-14.md](checklist-tests-2026-05-14.md)
- [checklist-tests-interactif.html](checklist-tests-interactif.html)
- [smoke-tests-device-2026-05-14.md](smoke-tests-device-2026-05-14.md)
- [nuit-securite-0602.md](nuit-securite-0602.md)

---

*Suite possible (non faite ici pour ne pas casser de liens entrants) :
déplacer physiquement la section « Archives » dans `docs/archive/`.*
