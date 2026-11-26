# Gestion admin des pâtissiers et produits

| | |
|---|---|
| **Statut** | ✅ rédigé et à jour |
| **Écrit avant le développement ?** | non — fonctionnalité déjà en production, rédigé rétroactivement le 2026-09-22 |
| **Écrans concernés** | `admin_bakers_screen.dart` (`/admin/bakers`), `admin_products_screen.dart` (`/admin/products`) |
| **Endpoints concernés** | admin-service : `GET/PUT /api/admin/bakers/`, `/pending/`, `/{id}/verify|reject|suspend|unsuspend|unverify/` ; `GET/PUT/DELETE /api/admin/products/`, `/reported/`, `/{id}/feature|unfeature|flag|unflag/` |
| **Tickets Linear liés** | PAT-61 (avertissement adresse manquante à la validation) |
| **Dernière relecture** | 2026-09-22 |

---

## 1. Périmètre

Validation/rejet/suspension d'un compte pâtissier par l'admin, et mise en avant/signalement/suppression d'un produit par l'admin. Ne couvre pas la bascule pâtissier ↔ client que le pâtissier déclenche lui-même depuis son propre compte (→ [`../patissier/bascule-baker-client.md`](../patissier/bascule-baker-client.md)) — cette fiche vérifie uniquement que les actions **admin** sur un pâtissier ou un produit restent strictement scopées à leur cible, sous le même angle que le bug déjà documenté là-bas (une désactivation trop large avait touché le produit d'un pâtissier tiers).

## 2. Préconditions

- Le compte admin de test.
- Au moins deux comptes pâtissiers de test **distincts** de `patissier@exemple.com` (baker 5, à préserver pour les autres campagnes) : un en attente de validation (`is_verified = FALSE`) et un déjà actif, chacun avec au moins un produit.
- Un pâtissier tiers témoin actif, avec ses propres produits, pour vérifier qu'aucune action admin sur le premier ne le touche.
- Idéalement : un pâtissier de test avec une adresse de retrait renseignée et un autre sans (pour le cas de bord §4 sur `hasLocation`).

## 3. Scénario nominal (happy path) — pâtissiers

1. **Liste des pâtissiers (`/admin/bakers`).** Le switch « En attente uniquement » bascule entre `GET /bakers/` (tous) et `GET /bakers/pending/` (`is_verified = FALSE` uniquement).
2. **Valider un compte en attente.** `PUT /bakers/{id}/verify/` → `is_verified = TRUE`, `is_active = TRUE`, `accepts_orders = TRUE`, et **bascule `accounts_user.group_id` à 3** (le compte devient réellement pâtissier à ce moment précis, pas à l'inscription initiale — voir §5).
3. **Rejeter une demande en attente.** `PUT /bakers/{id}/reject/` → supprime la ligne `baker` (uniquement si elle est encore `is_active = FALSE AND is_verified = FALSE` ; refusé sinon, voir §4). Le compte reste client.
4. **Suspendre un pâtissier déjà actif.** `PUT /bakers/{id}/suspend/` avec motif → `is_active = FALSE`, `accepts_orders = FALSE`, `suspended_at`/`suspension_reason`/`suspended_by` renseignés.
5. **Lever une suspension.** `PUT /bakers/{id}/unsuspend/` → réactive et vide les champs de suspension.
6. **Retirer le badge vérifié sans suspendre.** `PUT /bakers/{id}/unverify/` → `is_verified = FALSE` uniquement, `is_active`/`accepts_orders` inchangés — action distincte de la suspension (voir §5).

## Scénario nominal — produits

7. **Liste des produits (`/admin/products`).** Le switch « Signalés uniquement » bascule vers `GET /products/reported/` (`is_flagged = TRUE`).
8. **Mettre en avant / retirer.** `PUT /products/{id}/feature/` ou `unfeature/`.
9. **Signaler / lever le signalement.** `PUT /products/{id}/flag/` avec motif obligatoire (saisi via `promptReason`), ou `unflag/`.
10. **Supprimer un produit.** `DELETE /products/{id}/` — irréversible, confirmation demandée côté UI.

## 4. Cas de bord et erreurs attendues

- **Action admin sur un pâtissier ne doit toucher AUCUN autre pâtissier.** Chaque action (`verify`/`reject`/`suspend`/`unsuspend`/`unverify`) exécute un `UPDATE ... WHERE id = %s` scopé sur un seul `id` — vérifier explicitement, à chaque évolution de cet écran, que le pâtissier tiers témoin garde son statut et ses produits intacts après chaque action sur le premier (même piège que [`../patissier/bascule-baker-client.md`](../patissier/bascule-baker-client.md) §4, vu ici côté admin).
- **Rejeter une demande déjà traitée (déjà vérifiée ou déjà rejetée).** `reject` ne supprime que si `is_active = FALSE AND is_verified = FALSE` — sur un compte déjà actif, renvoie 404 « Demande introuvable ou déjà traitée », ne supprime jamais un profil actif par erreur.
- **`unverify` sur un compte pas encore vérifié**, ou **`suspend`/`unsuspend` sur un `id` inexistant.** Doivent renvoyer une erreur propre (404), jamais un 500.
- **Pâtissier sans adresse de retrait validé quand même (PAT-61).** Un dialogue de confirmation prévient avant l'action (« Ce pâtissier n'a pas d'adresse ») ; la validation reste possible. **Point à vérifier en priorité sur cet écran** : `AdminBaker.hasLocation`/`pickupCity` (`Patisry/lib/features/admin/data/datasources/admin_api.dart`) attendent les champs JSON `has_location`/`pickup_city`, mais `BakerAdminSerializer` côté admin-service (`Backend/admin-service/admin_app/serializers.py`) **ne renvoie ni l'un ni l'autre** — contrairement à display-service/search-service/order-service qui, eux, exposent bien ces champs. Conséquence probable : `hasLocation` vaut toujours `false` par défaut côté Flutter, donc l'avertissement « Ce pâtissier n'a pas d'adresse » et le badge « Sans adresse » s'affichent **pour tous les pâtissiers**, même ceux qui ont une adresse renseignée, et la sous-ligne retombe systématiquement sur l'ancien champ libre `location`. À confirmer sur staging avec un pâtissier ayant une adresse de retrait complète : si le badge apparaît quand même, c'est ce gap qui en est la cause, pas une régression du composant UI.
- **Avertissement serveur après validation (`warning` dans la réponse de `verify`).** Le code Flutter (`AdminApi.verifyBaker`) sait lire un champ `warning.message` dans la réponse pour l'afficher dans un second dialogue. La vue `verify()` côté admin-service ne renvoie actuellement que `{'message': 'Baker verified.'}`, sans clé `warning` — ce second filet ne se déclenche donc jamais en l'état. Ne pas chercher à le déclencher en pensant à un bug de l'écran : c'est le backend qui ne l'implémente pas (encore).
- **Suppression d'un produit utilisé dans une commande en cours.** Vérifier qu'un produit lié à une commande non terminée ne casse pas l'affichage de cette commande après suppression (pas de crash sur `order_detail_screen` côté client) — à tester explicitement, pas supposé sûr.

## 5. Règles métier à vérifier

- Point d'entrée admin unique `IsAdminRole` → voir [`dashboard-et-analytics.md`](dashboard-et-analytics.md) §5, ne pas dupliquer ici.
- **Devenir pâtissier nécessite une validation admin explicite** : la demande initiale (`baker-service.BakerViewSet.create`) ne bascule plus elle-même `group_id` à 3 ni `is_active` à `TRUE` — c'est uniquement `BakerAdminViewSet.verify` qui le fait. Un compte qui vient de faire une demande pâtissier doit donc rester `UserType.client` côté Flutter tant que l'admin n'a pas validé.
- `reject` ≠ `unverify` ≠ `suspend` : trois actions distinctes qui ne doivent jamais se chevaucher dans l'UI (les boutons « Valider »/« Rejeter » n'apparaissent que pour une demande non vérifiée, « Suspendre »/« Lever la suspension »/« Supprimer la vérification » uniquement pour un compte déjà vérifié — vérifier qu'aucun des deux groupes ne s'affiche en même temps sur une même ligne).
- L'adresse exacte d'un pâtissier n'est jamais publique (CLAUDE.md) — `BakerAdminSerializer` n'expose que `location` (texte libre historique), jamais un champ d'adresse structurée complète ; cohérent avec la règle même si le champ `location` reste un vestige à ne pas confondre avec l'adresse de retrait réelle gérée par `patissier/adresse-et-position.md`.

## 6. Non-régressions connues

- **`has_location`/`pickup_city` jamais renvoyés par `/admin/bakers/`** (voir §4) — pas encore rencontré en usage réel documenté, mais confirmé par lecture du code le 2026-09-22 ; à retester à chaque évolution de `BakerAdminSerializer` ou de l'écran, et à corriger côté backend si confirmé sur staging.
- **Absence de `warning` dans la réponse de `verify`** (voir §4) — même statut : gap identifié par lecture de code, pas encore un bug signalé, à garder en tête avant de conclure trop vite à un dysfonctionnement de l'UI.

## 7. Comment vérifier

- Backend : `admin-service` (`manage.py test`, classes `BakerVerificationEndpointsTests` pour verify/reject/unverify — `Backend/admin-service/admin_app/tests/test_endpoints.py` — et les tests `products`/`reported` de `AdminEndpointsTests`).
- Vérification directe en base : `SELECT is_verified, is_active, accepts_orders, suspended_at FROM baker WHERE id IN (...)` sur le pâtissier testé **et** le témoin, avant/après chaque action ; `SELECT group_id FROM accounts_user WHERE id = ...` après `verify`.
- Pour le cas `has_location`/`pickup_city` : comparer la réponse brute de `GET /api/admin/bakers/` (ex. via les DevTools réseau du navigateur sur `stg.patisry.fr/admin/bakers`) au contenu réel de la table `baker`/adresse de retrait pour ce pâtissier.
- Frontend : `flutter analyze` + test manuel staging avec le compte admin.

## 8. Definition of done

- [ ] Toutes les actions pâtissier (verify/reject/suspend/unsuspend/unverify) produisent l'effet attendu en base, scopées au seul `id` ciblé
- [ ] Pâtissier tiers témoin intact après chaque action sur un autre pâtissier
- [ ] Toutes les actions produit (feature/unfeature/flag/unflag/delete) fonctionnelles et scopées au seul produit ciblé
- [ ] Statut réel de `has_location`/`pickup_city` sur `/admin/bakers/` vérifié sur staging (confirmé absent ou corrigé) et documenté ici en conséquence
- [ ] Statut réel du champ `warning` sur `verify` vérifié sur staging et documenté ici en conséquence
- [ ] Tests `admin-service` verts
- [ ] `flutter analyze` sans erreur
