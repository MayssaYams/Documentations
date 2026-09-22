# Référentiels catalogue (catégories, allergènes, tailles)

| | |
|---|---|
| **Statut** | ✅ rédigé et à jour |
| **Écrit avant le développement ?** | non — fonctionnalité déjà en production, rédigé rétroactivement le 2026-09-22 |
| **Écrans concernés** | `admin_categories_screen.dart` (`/admin/categories`), `admin_allergens_screen.dart` (`/admin/allergens`) — tous deux basés sur le composant partagé `admin_referential_screen.dart` — et `admin_size_options_screen.dart` (`/admin/sizes`) |
| **Endpoints concernés** | **product-service**, pas admin-service : `GET/POST/PUT/DELETE /api/products/admin/categories/`, `/api/products/admin/allergens/`, `/api/products/admin/size-options/` |
| **Tickets Linear liés** | — |
| **Dernière relecture** | 2026-09-22 |

---

## 1. Périmètre

CRUD des trois référentiels partagés par tout le catalogue : catégories de pâtisserie, allergènes, tailles proposées par catégorie. Ne couvre pas leur usage côté pâtissier (étape « Tailles » de `edit_pastry_screen`) ni côté client (filtres catalogue) — uniquement la gestion admin et, spécifiquement demandé, ce qui se passe quand on supprime une valeur déjà utilisée par un produit existant.

**Particularité à retenir avant de tester** : ces trois endpoints vivent dans **product-service**, pas admin-service comme le reste du panel admin — la permission appliquée est `IsAdminOnly` (product-service), pas `IsAdminRole` (admin-service). Deux classes différentes, mais même logique (`group_id == 1`) — à vérifier séparément si l'une évolue sans l'autre.

## 2. Préconditions

- Le compte admin de test.
- Un produit de test avec une catégorie assignée, au moins un allergène coché, et une taille issue du référentiel (pas un libellé libre `custom_label`) — nécessaire pour observer l'effet réel d'une suppression de référentiel utilisé.
- Une catégorie/un allergène/une taille **de test**, non utilisés par un produit réel, pour vérifier le cas nominal de suppression propre sans toucher aux données existantes.

## 3. Scénario nominal (happy path)

1. **Catégories (`/admin/categories`) et allergènes (`/admin/allergens`).** Même écran générique (`AdminReferentialScreen`) : liste `{id, name}`, ajout (`+`), renommage (icône crayon), suppression (icône corbeille avec confirmation).
2. **Créer une entrée.** Nom unique en base (`UNIQUE (name)` sur `category` et `allergen`) — une création avec un nom déjà pris échoue proprement (voir §4).
3. **Renommer.** `PUT .../{id}/` — le nom change partout où il est référencé par FK (pas de duplication de libellé stocké ailleurs).
4. **Tailles (`/admin/sizes`).** Sélection d'une catégorie dans un menu déroulant, puis liste des tailles configurées pour cette catégorie uniquement (`?category_id=`). Une catégorie sans taille configurée affiche l'avertissement explicite : « Les pâtissiers de cette catégorie n'auront pas l'étape "Tailles" ».
5. **Ajouter/modifier une taille.** Libellé obligatoire, dimensions (`20` ou `15 x 15`) et nombre de parts (`8` ou `10-12`) facultatifs, validés par regex côté client (`_diameterRe`/`_partsRe`) — mêmes règles que `product-service/products/serializers.py::_validate_diameter_cm`.
6. **Désactiver une taille (icône œil).** `PATCH .../{id}/` avec `is_active: false` — **différent d'une suppression** : la taille reste en base, disparaît des nouveaux choix proposés, mais un produit qui l'utilise déjà la garde (voir §5).

## 4. Cas de bord et erreurs attendues — le comportement réel à la suppression, vérifié en base

Le code UI affiche un message de confirmation différent pour chaque référentiel — **vérifié contre le schéma réel** (`Documentations/database/03_products.sql`, `add_product_sizes.sql`) plutôt que supposé identique partout :

- **Supprimer un allergène utilisé par un produit.** `product_allergen.allergenid` a la contrainte `REFERENCES allergen(id) ON DELETE CASCADE`. La suppression réussit **et** retire silencieusement l'association du produit à cet allergène (`DELETE FROM product_allergen WHERE allergenid = ...` implicite). Le message affiché (« Les produits qui l'utilisent perdront cette association. ») **correspond exactement** au comportement réel — cas correctement documenté côté UI.
- **Supprimer une catégorie utilisée par un produit — deux effets, dont un non annoncé par l'UI.**
  1. `product_category.categoryid` (table historique « fallback ») est une **colonne entière sans contrainte de clé étrangère du tout** (commentaire du schéma : « Référence vers category (table définie ailleurs) »). Supprimer la catégorie ne touche donc pas ces lignes : **elles restent en base avec un `categoryid` qui ne pointe plus vers rien — produit orphelin silencieux**, sans erreur, sans avertissement. C'est la réponse concrète à la question « suppression bloquée ou produit orphelin ? » pour ce chemin : **orphelin silencieux**.
  2. `product_size_options.category_id` a `REFERENCES category(id) ON DELETE CASCADE` : supprimer une catégorie supprime en cascade **toutes les tailles configurées pour cette catégorie**, même si elles sont utilisées par des produits existants (voir effet en cascade ci-dessous). **Ce deuxième effet n'est mentionné nulle part dans le dialogue de confirmation** (« Les produits qui l'utilisent perdront cette association » ne parle que du produit, pas des tailles) — à vérifier explicitement sur staging avant de supprimer une catégorie de test qui a des tailles configurées, et à traiter comme une découverte à confirmer plutôt qu'un fait acquis tant que non observé en usage réel.
- **Supprimer une taille (`product_size_options`) utilisée par un produit — suppression potentiellement bloquée, contrairement au message affiché.** `product_sizes.size_option_id` a `REFERENCES product_size_options(id) ON DELETE SET NULL`, mais la table porte aussi la contrainte `CHECK (size_option_id IS NOT NULL OR custom_label IS NOT NULL)`. Un produit qui a choisi une taille du référentiel a très probablement `custom_label IS NULL` (le pâtissier n'a pas saisi de libellé libre, il a coché une taille existante). Dans ce cas, la mise à `NULL` de `size_option_id` lors de la suppression **viole la contrainte CHECK** : la suppression échouerait côté PostgreSQL (erreur d'intégrité), **contrairement au message affiché à l'admin** (« Les produits qui utilisent cette taille la garderont, mais elle ne sera plus proposable. », qui laisse penser que la suppression réussit toujours proprement). **À vérifier en priorité sur staging** : supprimer une taille effectivement utilisée par un produit de test et constater si l'action échoue (message d'échec générique « Échec de la suppression. », pas d'explication du pourquoi côté UI) ou si un mécanisme non repéré à la lecture du code l'empêche autrement. Si la suppression échoue silencieusement sans que l'admin comprenne pourquoi, c'est un gap UX à signaler — le bouton « désactiver » (`is_active = FALSE`) reste dans tous les cas le chemin sûr pour retirer une taille du choix sans toucher aux produits existants.
- **Créer une entrée avec un nom déjà utilisé.** Contrainte `UNIQUE` en base → échec, message générique côté UI (« Échec de la création (nom déjà utilisé ?). ») qui devine la cause plutôt que de la lire dans la réponse serveur — suffisant pour l'usage admin, mais ne pas s'attendre à un message serveur détaillé.
- **Créer une taille en double pour la même catégorie.** `UNIQUE (category_id, label)` → même comportement générique.

## 5. Règles métier à vérifier

- Point d'entrée admin, ici `IsAdminOnly` (product-service) — logique équivalente à `IsAdminRole` (admin-service) décrite dans [`dashboard-et-analytics.md`](dashboard-et-analytics.md) §5, mais **classe de permission distincte à vérifier séparément** puisque ce référentiel ne vit pas dans admin-service.
- **Désactiver une taille (`is_active = FALSE`) est le mécanisme voulu pour retirer une taille du choix sans casser les produits existants** — la suppression pure (`DELETE`) n'est pas garantie de réussir sur une taille en usage (voir §4). Documenter tout écart observé sur staging ici plutôt que de le redécouvrir à chaque fois.
- Chaque création/modification/suppression est auditée (`admin.category.created/updated/deleted`, `admin.allergen.*`, `admin.size_option.*`) — écrit par le `log_action` propre à product-service (même logique défensive que celui d'admin-service, voir [`utilisateurs-et-audit.md`](utilisateurs-et-audit.md) §4).

## 6. Non-régressions connues

- **Suppression de catégorie → cascade silencieuse sur `product_size_options`, non annoncée à l'admin** (voir §4) — gap identifié par lecture de schéma le 2026-09-22, à confirmer sur staging avant de le traiter comme un bug avéré.
- **Suppression de taille en usage potentiellement bloquée par la contrainte CHECK `product_sizes_label_required`, contrairement au message UI qui promet une suppression toujours propre** (voir §4) — même statut, à confirmer.

## 7. Comment vérifier

- Backend : `product-service` (`manage.py test`, `Backend/product-service/products/unit_tests/test_product_sizes.py` pour les tailles ; pas de fichier de tests dédié repéré pour `CategoryAdminViewSet`/`AllergenAdminViewSet` au 2026-09-22 — à confirmer et, si absent, c'est un trou de couverture à combler avant de considérer cette fiche entièrement fiable côté automatisé).
- Vérification directe en base, avant/après chaque suppression : `SELECT * FROM product_category WHERE categoryid = <id supprimé>` (doit montrer les lignes orphelines si le cas §4.2 est confirmé), `SELECT * FROM product_size_options WHERE category_id = <id supprimé>` (doit être vide si la cascade a eu lieu), `SELECT * FROM product_sizes WHERE size_option_id = <id>` avant de tenter la suppression d'une taille en usage.
- Frontend : `flutter analyze` + test manuel staging avec le compte admin, sur des entrées de test dédiées (jamais sur les catégories/allergènes/tailles réellement utilisées par le catalogue de `patissier@exemple.com`).

## 8. Definition of done

- [ ] Création/renommage/suppression fonctionnels sur les trois référentiels, avec conflit de nom géré proprement
- [ ] Effet réel de la suppression d'un allergène utilisé confirmé conforme au message UI
- [ ] Effet réel de la suppression d'une catégorie utilisée confirmé et documenté (orphelin `product_category` + cascade `product_size_options`)
- [ ] Effet réel de la suppression d'une taille utilisée confirmé et documenté (bloquée ou non par la contrainte CHECK)
- [ ] Désactivation d'une taille (chemin sûr) vérifiée comme n'affectant pas les produits existants
- [ ] Actions retrouvées dans `audit_log` (service product-service)
- [ ] Tests `product-service` verts, y compris `test_product_sizes.py`
- [ ] `flutter analyze` sans erreur
