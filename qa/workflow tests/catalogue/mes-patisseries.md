# Mes pâtisseries

| | |
|---|---|
| **Statut** | 🔁 à revoir — écart identifié §4 sur le filtre `baker_id`, à faire trancher par le Tech Lead |
| **Écrit avant le développement ?** | non — écran déjà en production, rédigé rétroactivement le 2026-09-22 |
| **Écrans concernés** | `my_pastries_screen.dart` (route `/account/my-pastries`), `edit_pastry_screen.dart` (route `/account/my-pastries/edit`) |
| **Endpoints concernés** | `GET /api/products/?baker_id={id}` (product-service), `POST /api/products/` (création), `PATCH` statut actif/inactif, `DELETE` |
| **Tickets Linear liés** | PAT-80 (référence croisée code mort général) |
| **Dernière relecture** | 2026-09-22 |

---

## 1. Périmètre

Gestion des produits d'un pâtissier connecté : liste, création, édition, pause/reprise, suppression, sélection multiple. Ne couvre pas la consultation publique d'un produit (→ [`fiche-produit.md`](fiche-produit.md)) ni la fiche pâtissier publique (→ [`fiche-patissier-publique.md`](fiche-patissier-publique.md)).

## 2. Préconditions

- `patissier@exemple.com` (baker 5) connecté avec un profil baker actif — route protégée à la fois par `_protectedPathPrefixes` (`/account`) et `_bakerOnlyPathPrefixes` (`/account/my-pastries`) dans `app.dart` : un client sans profil baker actif ne doit pas pouvoir y accéder.
- **Jamais** utiliser la vraie boutique Berile (baker_id=1) pour ces tests.
- Idéalement, un produit de test dont le lien vers le pâtissier passe par `product_user` (cas normal de création via l'app) — voir §4 pour le cas `product.baker_id` direct, plus dur à provoquer depuis l'app elle-même.
- Staging (`stg.patisry.fr`).

## 3. Scénario nominal (happy path)

1. **Ouvrir « Mes pâtisseries ».** `MyPastriesService.listForCurrentBaker(auth)` appelle `GET /api/products/?baker_id={auth.currentUser.bakerId}` (product-service). Liste affichée avec statut (actif/en pause), prix, favoris comptés côté client (un appel `getFavorites()` **par produit**, voir §4).
2. **Créer une pâtisserie** (bouton `+`). Navigue vers `/account/my-pastries/edit` avec `extra: {'id': null}`. `EditPastryScreen` propose deux prix : « prix net du pâtissier » et « prix public TTC » calculé automatiquement à ×1,25 (marge plateforme) — vérifier que la modification de l'un recalcule l'autre sans boucle infinie de `setState`.
3. **Soumettre la création.** `createProduct` (product-service) exige `baker_id` dans le body ; le backend vérifie que le `baker_id` fourni correspond bien au baker du compte connecté pour un rôle pâtissier (sinon `403`). Le produit créé doit apparaître immédiatement dans la liste (`addPastry`, mise à jour locale sans rechargement complet).
4. **Modifier une pâtisserie existante.** Navigue vers `/account/my-pastries/edit` avec `extra: {'id': <id>}`, formulaire pré-rempli.
5. **Mettre en pause / réactiver** (icône play/pause, individuel ou par sélection multiple). Appelle `updateProductActiveStatus`. Le statut affiché change immédiatement en local, sans attendre un rechargement.
6. **Supprimer** (individuel ou par sélection multiple), avec confirmation modale. Retiré de la liste locale après succès ; message d'erreur dédié si l'appel échoue (le produit reste affiché).

## 4. Cas de bord et erreurs attendues

- **Lien `baker_id` / `product_user` — écart identifié à la lecture du code product-service, à faire trancher.** CLAUDE.md et `Documentations/tech-lead/role.md` documentent la règle : `product.baker_id` (colonne directe) peut être NULL, avec repli sur `product_user` uniquement dans ce cas — `baker_id` toujours prioritaire quand renseigné. Or le filtre réellement utilisé par « Mes pâtisseries » (`ProductViewSet.get_queryset`, `products/views.py:192-224`, appelé par `GET /api/products/?baker_id=X`) ne fait **que** `ProductUser.objects.filter(user__baker__id=baker_id)` — il n'interroge **jamais** la colonne `product.baker_id` (qui n'est d'ailleurs même pas un champ du modèle Django `Product`, `products/models.py`, lequel est `managed=False` et omet ce champ de sa liste de colonnes). Conséquence concrète : un produit dont le lien vers son pâtissier ne passe que par la colonne `product.baker_id` (sans ligne `ProductUser` correspondante — cas de données historiques/migrées) **n'apparaîtra jamais** dans « Mes pâtisseries » pour ce pâtissier, même s'il en est bien propriétaire. Le produit resterait néanmoins visible côté vitrine publique (display-service, qui a sa propre logique de résolution du baker — voir `_product_baker_column_safe`/`_baker_user_fk_column_safe` côté display-service). **À signaler au Tech Lead** : soit ce filtre doit être complété pour couvrir aussi `product.baker_id`, soit la donnée historique concernée doit être migrée pour toujours passer par `ProductUser`. Ne pas cocher la case correspondante en definition of done sans cette clarification.
- **Autre fonction du même service, ordre inverse** : `determine_baker_id_for_product` (`products/views.py:25-49`, utilisée uniquement pour construire la clé de stockage des images à l'upload) vérifie `ProductUser` **en premier**, puis retombe sur `product.baker_id` en second — ordre opposé à la règle documentée. Portée limitée (upload d'image seulement), mais à signaler comme incohérence si ce module est retouché.
- **Statistique « favoris » coûteuse et approximative.** `MyPastriesService.listForCurrentBaker` fait un appel `GET .../favorites/` **complet par produit affiché** (boucle `for (final p in products)`), puis filtre côté client (`favorites.where((f) => f.productId == p.id).length`). Sur un catalogue de N produits, cela déclenche N appels réseau identiques à `favorite-service` pour un seul écran. Pas un bug fonctionnel en soi (le compte reste correct) mais un point de performance à surveiller si un pâtissier a un catalogue large — vérifier le temps de chargement avec 10+ produits.
- **Recherche/tri locaux uniquement.** La barre de recherche (`SearchBarWithSuggestions`) et le tri (prix, note = nombre de favoris, date) de cet écran filtrent/trient exclusivement la liste déjà chargée en mémoire (`service.pastries`), comme sur l'accueil — pas de rappel serveur. Sans pagination sur cet endpoint (`getProductsByBakerList` charge toute la liste du baker en un appel), ce n'est pas un problème fonctionnel identifié aujourd'hui, mais à revérifier si une pagination est introduite un jour côté serveur.
- **Suppression/pause en échec réseau.** Message d'erreur dédié (`_showDeletionError`/`_showStatusUpdateError`), la sélection/l'état local n'est modifié qu'après succès confirmé — vérifier qu'un échec ne laisse jamais la liste dans un état incohérent avec le serveur.
- **`TODO_EDIT_PASTRY.md` présent dans le dossier de l'écran** (`lib/features/pastry/presentation/TODO_EDIT_PASTRY.md`) liste des champs qu'il documente comme non implémentés (`dimensions`, `preparation_time`, `is_refrigerated`, `expiration_date`, `available_from/to`, `location`, `isActive`). À la lecture de `edit_pastry_screen.dart`, des contrôleurs/champs existent déjà pour la plupart de ces valeurs (dates de disponibilité, réfrigération, statut actif, temps de préparation) — ce fichier TODO semble périmé. À confirmer à l'écran plutôt qu'à supposer réglé ou non réglé.

## 5. Règles métier à vérifier

- **Un pâtissier ne peut créer/modifier des produits que pour son propre `baker_id`.** Vérifié côté serveur (`products/views.py::create`, comparaison `user_baker_id != int(baker_id)` → `403`) — à retester explicitement avec un compte pâtissier tentant de fournir un `baker_id` autre que le sien (via un appel API direct, pas atteignable depuis l'UI normale).
- **Priorité `baker_id` > `product_user`** (CLAUDE.md, `Documentations/tech-lead/role.md`) — **non respectée par le filtre de listing utilisé par cet écran**, voir §4. C'est la règle métier la plus directement mise en cause par ce document.

## 6. Non-régressions connues

- **Aucune régression fraîchement introduite identifiée** — le point du §4 sur le filtre `baker_id`/`product_user` est un écart structurel présent dans le code actuel, pas une régression récente. À traiter comme une dette à trancher plutôt que comme un bug de dernière minute.

## 7. Comment vérifier

- Backend : `product-service` — `manage.py test`. Noter que la campagne du 2026-08-05 documentée dans `Documentations/qa/state.md` donnait 63/73 sur ce service, avec 10 échecs préexistants déjà classés indépendants de PAT-24 — vérifier qu'aucun nouvel échec ne s'ajoute à cette liste connue avant de conclure à une régression.
- Vérification directe en base (si accès) pour le cas du §4 : chercher un produit dont `product.baker_id` est renseigné mais qui n'a **aucune** ligne correspondante dans `product_user` — un tel produit est le cas de test exact pour reproduire l'écart documenté.
- `flutter analyze` 0 erreur ; test manuel de création/édition/pause/suppression avec `patissier@exemple.com` (baker 5).

## 8. Definition of done

- [ ] Création, édition, pause/reprise, suppression fonctionnels de bout en bout sur staging
- [ ] Écart `baker_id`/`product_user` du §4 tranché par le Tech Lead (corrigé, ou accepté comme dette documentée) — ne pas cocher cette case tant que la décision n'est pas prise
- [ ] Un pâtissier ne peut pas créer/modifier un produit pour un `baker_id` qui n'est pas le sien (testé)
- [ ] Prix net / prix public TTC cohérents (×1,25) sans boucle de recalcul
- [ ] Aucune incohérence entre l'état local (liste) et le serveur après un échec réseau sur pause/suppression
- [ ] Tests `product-service` verts hors échecs préexistants connus (`Documentations/qa/state.md`)
- [ ] `flutter analyze` 0 erreur
