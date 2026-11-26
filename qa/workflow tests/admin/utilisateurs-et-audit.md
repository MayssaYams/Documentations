# Utilisateurs et journal d'audit

| | |
|---|---|
| **Statut** | ✅ rédigé et à jour |
| **Écrit avant le développement ?** | non — fonctionnalité déjà en production, rédigé rétroactivement le 2026-09-22 |
| **Écrans concernés** | `admin_users_screen.dart` (`/admin/users`), `admin_audit_log_screen.dart` (`/admin/audit-log`) |
| **Endpoints concernés** | admin-service : `GET/PUT/DELETE /api/admin/users/`, `/{id}/ban|unban|promote_to_admin|demote_from_admin/`, `GET /api/admin/audit-log/` |
| **Tickets Linear liés** | — |
| **Dernière relecture** | 2026-09-22 |

---

## 1. Périmètre

Bannissement/débannissement d'un compte, promotion/rétrogradation admin, et lecture du journal d'audit qui doit tracer ces actions. Ne couvre pas la suppression de compte RGPD déclenchée par l'utilisateur lui-même (→ `compte/suppression-compte-rgpd.md`, non encore rédigé) ni la bascule pâtissier ↔ client (→ [`../patissier/bascule-baker-client.md`](../patissier/bascule-baker-client.md)).

## 2. Préconditions

- Le compte admin de test, **et un second compte admin de test** (l'action « rétrograder » refuse de retirer le dernier admin de la plateforme — il en faut donc au moins deux pour tester ce chemin sans se bloquer soi-même).
- Un compte client de test jetable (pas `client@exemple.com`) pour tester ban/promotion sans perturber les autres campagnes.

## 3. Scénario nominal (happy path) — utilisateurs

1. **Liste des utilisateurs (`/admin/users`).** `GET /api/admin/users/`, page 1 uniquement (pas de pagination dans l'UI — voir §4).
2. **Bannir un compte.** Confirmation requise → `PUT /users/{id}/ban/` → `is_active = FALSE`. Le compte ne peut plus se connecter (à vérifier côté auth-service, pas seulement le flag en base).
3. **Débannir.** `PUT /users/{id}/unban/` → `is_active = TRUE`, sans confirmation supplémentaire côté UI.
4. **Promouvoir un compte client en admin.** Confirmation requise → `PUT /users/{id}/promote_to_admin/` → `group_id = 1`.
5. **Rétrograder un admin.** Confirmation requise → `PUT /users/{id}/demote_from_admin/` → `group_id = 2`, uniquement s'il reste au moins un autre admin après (voir §4).

## Scénario nominal — journal d'audit

6. **Chaque action ci-dessus écrit une ligne dans `audit_log`** (`admin.user.banned`, `admin.user.unbanned`, `admin.user.promoted`, `admin.user.demoted`, etc.), avec `actor_user_id`/`actor_email`/`actor_role` = le compte admin qui a agi, `resource_type = 'user'`, `resource_id` = l'utilisateur ciblé.
7. **Ouvrir `/admin/audit-log`.** La ligne créée à l'étape précédente apparaît, triée par `occurred_at` décroissant (`ordering = ['-occurred_at']` sur le modèle).
8. **Filtrer par action.** Le champ texte filtre côté serveur avec `action__icontains` (ex. taper `admin.baker` remonte toutes les actions de modération pâtissier, pas seulement une action exacte).
9. **Filtrer par statut.** Dropdown Tous/Succès/Échec → `status = 'success'` ou `'failure'`.

## 4. Cas de bord et erreurs attendues

- **Un admin qui tente de modifier son propre statut admin (promote ou demote sur lui-même).** Refusé explicitement (« Vous ne pouvez pas modifier votre propre statut admin. »), avant même de vérifier autre chose.
- **Rétrograder le dernier admin restant.** Refusé (« Impossible : il ne resterait plus aucun administrateur. ») — nécessite bien deux comptes admin de test pour vérifier ce chemin, pas un seul.
- **Rétrograder un compte qui n'est déjà pas admin**, ou **promouvoir un compte déjà admin.** Réponses informatives (« Cet utilisateur n'est pas admin. » / « Cet utilisateur est déjà admin. »), pas d'erreur bloquante ni de double écriture d'audit incohérente.
- **Écriture d'audit qui échoue (contrainte de clé étrangère).** `log_action()` (`Backend/admin-service/admin_app/audit_log.py`) est explicitement conçu pour **ne jamais lever d'exception** : un échec d'`INSERT` (ex. FK invalide sur `actor_user_id` ou `resource_id`) est attrapé et seulement loggé côté serveur (`logger.error("[audit_log] Échec écriture audit...")`), l'action métier réussit quand même. C'est le comportement déjà repéré comme bruit connu dans `Documentations/qa/solution.md` §6 — **toujours d'actualité au 2026-09-22** (code inchangé, try/except générique). Conséquence directe pour ce fichier : une action admin peut réussir sans laisser de trace dans `/admin/audit-log`, **sans qu'aucune erreur ne remonte à l'écran**. Ne pas se fier à l'absence d'erreur UI pour conclure que l'audit a été écrit — toujours vérifier la ligne correspondante en base après l'action, pas seulement dans l'onglet audit (qui peut aussi être un problème de pagination/tri, pas d'écriture).
- **Aucune pagination visible sur `/admin/users`.** L'écran charge uniquement la page 1 (`listUsers()` sans paramètre) alors que l'API est paginée (`PaginatedResult`) — sur une base avec beaucoup d'utilisateurs, des comptes peuvent être invisibles depuis cet écran sans qu'aucun indice ne le signale (pas de « page suivante », pas de compteur total affiché). À vérifier si le volume d'utilisateurs de test dépasse la taille de page par défaut de DRF.
- **`deleteUser` existe côté client API (`AdminApi.deleteUser`) mais n'a aucun bouton dans l'écran.** Ne pas chercher ce bouton dans l'UI en pensant à une régression — la suppression dure d'un compte n'est pas exposée depuis ce panel, seul le bannissement l'est.

## 5. Règles métier à vérifier

- Point d'entrée admin unique `IsAdminRole` → voir [`dashboard-et-analytics.md`](dashboard-et-analytics.md) §5.
- **`is_staff`/`is_superuser` ne pilotent plus aucune décision d'autorisation applicative** (commentaire explicite de `permissions.py`) — seul `group_id` compte. Un test qui manipulerait `is_staff` pour simuler un admin ne prouve rien côté admin-service.
- **`UserAdminSerializer` expose l'adresse complète de l'utilisateur** (`street`, `city`, `postal_code`, `region`, etc.) — c'est un comportement voulu pour un endpoint strictement réservé à l'admin (contrairement aux endpoints publics où l'adresse ne doit jamais fuiter, cf. `patisry-public-endpoints-privacy-guard`), mais **à vérifier explicitement que cet endpoint reste bien inaccessible à un compte non-admin** (403), puisque c'est justement le genre de données que l'admin voit et que personne d'autre ne doit voir.
- `is_staff`/`is_superuser`/`group_id` sont `read_only` sur le serializer générique d'update (`UserAdminViewSet.update`) — un `PUT`/`PATCH` générique sur `/users/{id}/` ne peut jamais changer le statut admin, seules les actions dédiées `promote_to_admin`/`demote_from_admin` le peuvent. Vérifier qu'un payload qui tenterait de glisser `group_id` dans une modification générique (nom, téléphone...) est bien ignoré silencieusement, pas accepté.

## 6. Non-régressions connues

- **Bruit `[audit_log] Échec écriture audit ... violates foreign key constraint`** — cf. `Documentations/qa/solution.md` §6, confirmé toujours présent dans le code au 2026-09-22 (voir §4). Ne pas rediagnostiquer à chaque campagne : le comportement est volontairement défensif (l'action métier ne doit jamais échouer à cause d'un audit raté), mais vérifier qu'il ne masque pas une vraie absence de traçabilité sur les actions qui comptent (ban, promotion/rétrogradation admin).

## 7. Comment vérifier

- Backend : `admin-service` (`manage.py test`, classe `AdminEndpointsTests.test_user_ban_unban` — `Backend/admin-service/admin_app/tests/test_endpoints.py` — pour ban/unban ; pas de classe dédiée promote/demote repérée dans ce fichier de tests au 2026-09-22, à vérifier si elle a été ajoutée depuis).
- Vérification directe en base : `SELECT is_active, group_id FROM accounts_user WHERE id = ...` avant/après chaque action, et `SELECT * FROM audit_log WHERE resource_type='user' AND resource_id='...' ORDER BY occurred_at DESC LIMIT 5` pour confirmer l'écriture réelle (pas seulement l'affichage dans `/admin/audit-log`).
- Frontend : `flutter analyze` + test manuel staging avec les deux comptes admin de test et un compte client jetable.

## 8. Definition of done

- [ ] Ban/débannissement fonctionnels, `is_active` cohérent en base
- [ ] Promotion/rétrogradation admin fonctionnelles, `group_id` cohérent en base
- [ ] Auto-modification de son propre statut admin refusée
- [ ] Rétrogradation du dernier admin refusée (testé avec deux comptes admin, pas un seul)
- [ ] Chaque action sensible retrouvée dans `audit_log` en base, pas seulement supposée écrite faute d'erreur UI
- [ ] Accès à `/api/admin/users/` refusé (403) pour un compte non-admin
- [ ] Tests `admin-service` verts
- [ ] `flutter analyze` sans erreur
