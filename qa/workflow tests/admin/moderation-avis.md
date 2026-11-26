# Modération des avis signalés

| | |
|---|---|
| **Statut** | ✅ rédigé et à jour |
| **Écrit avant le développement ?** | non — fonctionnalité déjà en production, rédigé rétroactivement le 2026-09-22 |
| **Écrans concernés** | `admin_review_reports_screen.dart` (`/admin/review-reports`) |
| **Endpoints concernés** | admin-service : `GET /api/admin/review-reports/`, `PUT /api/admin/review-reports/{id}/dismiss/`, `PUT /api/admin/review-reports/{id}/resolve-delete/` |
| **Tickets Linear liés** | — |
| **Dernière relecture** | 2026-09-22 |

---

## 1. Périmètre

File de modération des signalements d'avis produit créés côté client, et les deux actions possibles dessus (ignorer / supprimer l'avis). Le déclenchement du signalement lui-même, côté client, est couvert par [`../commande-et-paiement/avis.md`](../commande-et-paiement/avis.md) — ne pas dupliquer ici.

**Hors périmètre volontaire — signalements produits et messages.** Le backend admin-service expose aussi `product-reports` et `message-reports` (mêmes verbes `dismiss`/`resolve`, mêmes modèles `ProductReport`/`MessageReport`, `Backend/admin-service/admin_app/views.py`), avec leurs propres tests (`ProductReportAdminEndpointsTests`, `MessageReportAdminEndpointsTests`). **Aucun de ces deux endpoints n'a d'écran Flutter dans le panel admin** — `AdminApi` (`Patisry/lib/features/admin/data/datasources/admin_api.dart`) n'appelle que `review-reports`. Un signalement de produit ou de message abusif remonte donc bien côté serveur mais n'est visible ni traitable depuis aucune interface admin à ce jour. Ce n'est pas un oubli de cette fiche : c'est un écran qui reste à construire. À ne pas tester ici tant qu'il n'existe pas — le signaler comme dette plutôt que d'inventer un scénario pour un écran absent.

## 2. Préconditions

- Le compte admin de test.
- Un avis de test signalé (créé via le flux client décrit dans [`../commande-et-paiement/avis.md`](../commande-et-paiement/avis.md)) — la file ne liste que les signalements `status = 'pending'` (`ReviewReportAdminViewSet.get_queryset`), un signalement déjà résolu ou ignoré n'apparaît plus.
- Idéalement deux avis signalés distincts, pour tester séparément « ignorer » et « supprimer ».

## 3. Scénario nominal (happy path)

1. **Ouvrir `/admin/review-reports`.** Liste des signalements en attente : produit ciblé, note de l'avis, texte de l'avis, motif du signalement.
2. **Ignorer un signalement.** Confirmation (« L'avis restera visible sur le produit. ») → `PUT /review-reports/{id}/dismiss/` → `status = 'dismissed'`, `resolved_at`/`resolved_by` renseignés. **L'avis original n'est pas touché** — il reste visible sur la fiche produit, seul le signalement change de statut.
3. **Supprimer l'avis signalé.** Confirmation (« Cette action est irréversible et résout tous les signalements liés à cet avis. ») → `PUT /review-reports/{id}/resolve-delete/` → suppression réelle de la ligne `product_reviews` correspondante.
4. **Effet de cascade de la suppression.** La table `review_reports` a une FK `ON DELETE CASCADE` vers `product_reviews` (commentaire explicite dans `ReviewReportAdminViewSet` : « ON DELETE CASCADE nettoie automatiquement tous les signalements liés à cet avis ») — si le même avis avait été signalé par plusieurs utilisateurs, **tous** ses signalements disparaissent en une seule action, pas seulement celui traité depuis l'écran.
5. **Note agrégée du pâtissier recalculée.** Après suppression d'un avis, la note affichée sur la fiche pâtissier doit refléter l'avis en moins (→ [`../catalogue/fiche-patissier-publique.md`](../catalogue/fiche-patissier-publique.md) pour le détail du calcul, non dupliqué ici).

## 4. Cas de bord et erreurs attendues

- **`resolve-delete` sur un `id` de signalement déjà traité ou inexistant.** Renvoie 404 (« Signalement introuvable. »), pas de 500, pas de suppression silencieuse d'un autre avis.
- **Un avis signalé par deux utilisateurs différents.** Vérifier explicitement que la liste ne montre pas de doublon trompeur et que résoudre l'un des deux signalements fait bien disparaître l'autre de la liste au rechargement (cascade FK, voir §3.4) — pas un oubli à corriger, un comportement voulu à confirmer.
- **Ignorer un signalement ne doit avoir strictement aucun effet visible côté client** — ni sur l'avis, ni sur la note du pâtissier, ni sur le produit. Si un effet est observé, c'est une régression.
- **Suppression de l'avis d'une commande qui a aussi généré un message ou une réponse du pâtissier.** Vérifier que la réponse du pâtissier à cet avis (si `../commande-et-paiement/avis.md` §3 en a créé une) ne reste pas affichée seule, orpheline, après la suppression.

## 5. Règles métier à vérifier

- Point d'entrée admin unique `IsAdminRole` → voir [`dashboard-et-analytics.md`](dashboard-et-analytics.md) §5.
- Chaque action de modération est auditée (`admin.review_report.dismissed`, `admin.review_report.resolved_delete`) — mêmes réserves sur la fiabilité d'écriture qu'ailleurs, voir [`utilisateurs-et-audit.md`](utilisateurs-et-audit.md) §4.
- L'adresse exacte du pâtissier ne doit jamais apparaître dans le texte d'un avis affiché à l'admin — même règle générale que côté client (CLAUDE.md), à vérifier ici aussi puisque le texte de l'avis est du contenu utilisateur libre.

## 6. Non-régressions connues

_Aucune connue à ce jour — première rédaction de cette fiche. Ajouter ici tout bug réel rencontré lors d'une future campagne._

## 7. Comment vérifier

- Backend : `admin-service` (`manage.py test`, classe `ReviewReportAdminEndpointsTests` — `Backend/admin-service/admin_app/tests/test_endpoints.py` — couvre déjà dismiss, resolve-delete, resolve-delete sur `id` inconnu, et le rejet pour un non-admin).
- Vérification directe en base : `SELECT status, resolved_at FROM review_reports WHERE id = ...` après `dismiss` ; `SELECT * FROM product_reviews WHERE id = ...` (doit être vide) et `SELECT * FROM review_reports WHERE review_id = ...` (doit être vide, cascade) après `resolve-delete`.
- Frontend : `flutter analyze` + test manuel staging avec le compte admin.

## 8. Definition of done

- [ ] Ignorer un signalement laisse l'avis intact et visible côté client
- [ ] Supprimer un avis signalé le retire réellement de `product_reviews`, avec cascade sur tous ses signalements
- [ ] `resolve-delete` sur un signalement déjà traité renvoie 404, pas 500
- [ ] Note agrégée du pâtissier recalculée après suppression d'un avis
- [ ] Actions retrouvées dans `audit_log`
- [ ] Absence d'écran pour `product-reports`/`message-reports` documentée comme dette, pas testée comme si elle existait
- [ ] Tests `admin-service` verts (classe `ReviewReportAdminEndpointsTests`)
- [ ] `flutter analyze` sans erreur
