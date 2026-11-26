# Bascule pâtissier ↔ client

| | |
|---|---|
| **Statut** | ✅ rédigé et à jour |
| **Écrit avant le développement ?** | non — fonctionnalité déjà en production, rédigé rétroactivement le 2026-09-22 |
| **Écrans concernés** | `edit_baker_info_screen.dart` (`/account/baker/edit`), `profile_screen.dart` |
| **Endpoints concernés** | baker-service (désactivation/réactivation), `UPDATE accounts_user SET group_id` |
| **Tickets Linear liés** | — |
| **Dernière relecture** | 2026-09-22 |

---

## 1. Périmètre

Désactivation d'un compte pâtissier vers un compte client, et réactivation. Ne couvre pas l'inscription initiale en tant que pâtissier (hors périmètre actuel, pas d'écran dédié identifié).

## 2. Préconditions

- Un compte de test pâtissier **dédié à cette bascule**, distinct de `patissier@exemple.com` (baker 5) qui doit rester intact pour les autres campagnes — créer un compte pâtissier jetable si besoin.
- Au moins une pâtisserie liée par `baker_id` et, si possible, une liée uniquement par `product_user` (pour couvrir le cas §4).
- Un **autre** pâtissier de test actif, avec ses propres produits, pour vérifier qu'il n'est pas affecté.

## 3. Scénario nominal (happy path) — désactivation

1. **Depuis le profil, désactiver le compte pâtissier.** baker-service : `is_active = False`, `accepts_orders = False`. `UPDATE accounts_user SET group_id = 2`.
2. **Navigation.** Redirige vers `/account` — **jamais** vers `/home` (route inexistante, piège documenté CLAUDE.md).
3. **`UserType` recalculé.** Le compte est désormais reconnu comme `UserType.client` (`baker.isActive` faux).

## Scénario nominal — réactivation

4. **Réactiver depuis le même compte.** Récupère **l'ancien profil pâtissier, même `baker_id`** — pas un profil recréé de zéro.
5. `is_active = True`, `accepts_orders = True`, `UPDATE accounts_user SET group_id = 3`.
6. **Les pâtisseries ne sont PAS réactivées automatiquement.** Comportement voulu (manuel, une par une) — ne pas signaler comme un bug.

## 4. Cas de bord et erreurs attendues

- **Désactivation doit désactiver TOUTES les pâtisseries du pâtissier**, y compris celles liées uniquement via `product_user` (pas de `baker_id` direct). Vérifier les deux cas de liaison.
- **La désactivation ne doit toucher AUCUN produit d'un autre pâtissier.** Bug réel déjà rencontré : un correctif trop large avait désactivé le produit d'un pâtissier actif tiers. **Vérifier explicitement, à chaque évolution de cet écran**, qu'un pâtissier de test tiers garde ses produits actifs après la désactivation du premier.
- **`baker_id` NULL sur un produit.** Le lien réel passe alors uniquement par `product_user` — `baker_id` reste **toujours prioritaire** quand il est renseigné (piège documenté : `product-ownership-dual-link-gotcha`).
- **Navigation vers `/home` après désactivation.** Route inexistante — si observée, c'est une régression du correctif déjà en place, à corriger immédiatement.

## 5. Règles métier à vérifier

- `group_id = 2` → client, `group_id = 3` → pâtissier — toujours cohérent avec `is_active`/`accepts_orders`.
- `UserType` Flutter : baker si `baker.isActive && baker.id > 0`, client sinon.

## 6. Non-régressions connues

- **Désactivation qui a touché le produit d'un pâtissier tiers** (bug réel, cause : requête de désactivation trop large, probablement sans filtre `baker_id` strict). **Le cas de bord le plus important de cette fiche.**
- **Navigation vers `/home` inexistante** au lieu de `/account` (CLAUDE.md, « Baker downgrade → client »).

## 7. Comment vérifier

- Backend : `baker-service` + `user-service` (`manage.py test`).
- Vérification directe en base : `SELECT is_active, accepts_orders FROM baker WHERE ...` et `SELECT group_id FROM accounts_user WHERE ...` avant/après chaque bascule, sur le compte testé **et** sur le pâtissier tiers témoin.
- Frontend : `flutter analyze` + test manuel staging.

## 8. Definition of done

- [ ] Désactivation : `is_active`/`accepts_orders` à `False`, `group_id = 2`, navigation vers `/account`
- [ ] Toutes les pâtisseries du compte désactivées, y compris liaison via `product_user`
- [ ] Pâtissier tiers témoin : produits intacts après désactivation d'un autre pâtissier
- [ ] Réactivation : même `baker_id`, pâtisseries restent désactivées (manuel)
- [ ] Tests `baker-service`/`user-service` verts
