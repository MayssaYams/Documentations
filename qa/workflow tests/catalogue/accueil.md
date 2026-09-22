# Accueil

| | |
|---|---|
| **Statut** | ✅ rédigé et à jour |
| **Écrit avant le développement ?** | non — écran déjà en production, rédigé rétroactivement le 2026-09-22 |
| **Écrans concernés** | `home_screen.dart` (route `/`) |
| **Endpoints concernés** | `GET /api/display/products/home/payload/` (display-service) |
| **Tickets Linear liés** | PAT-49, PAT-50 (distance/rayon), PAT-57 (adresse jamais publique) |
| **Dernière relecture** | 2026-09-22 |

---

## 1. Périmètre

Liste paginée des produits sur l'écran d'accueil : chargement, tri, pagination/scroll infini, filtres, état vide. **Ne couvre pas** le pre-prompt de localisation (GPS / ville saisie / refus) ni la mémorisation du mode choisi — voir [`../transverse/localisation-memorisation.md`](../transverse/localisation-memorisation.md). Ce document part du principe qu'une position (ou son absence) est déjà connue et se concentre sur ce que l'écran en fait.

## 2. Préconditions

- `client@exemple.com` ou navigation anonyme (l'endpoint est public — voir §5).
- Au moins un produit actif chez `patissier@exemple.com` (baker 5) pour un scénario non vide ; aucun produit dans le rayon appliqué pour tester l'état vide.
- Staging (`stg.patisry.fr`).

## 3. Scénario nominal (happy path)

1. **Ouverture de l'accueil sans position connue.** `_userLat`/`_userLon` sont `null` (aucune position mémorisée dans `LocationService` — cf. `transverse/localisation-memorisation.md`). `getHomePayload()` part sans `lat`/`lon`/`radius_km`. Les cartes produit n'affichent aucune distance.
2. **Ouverture avec une position déjà en cache de session.** `HomeScreen.initState()` sème `_userLat`/`_userLon` depuis `LocationService` **avant** le premier appel réseau (`lib/features/home/presentation/home_screen.dart:117-118`) : la toute première page reçue porte déjà les distances, pas de flash « sans distance » suivi d'un rechargement.
3. **Tri par distance.** Avec position + `baker_location` renseigné, le serveur trie **tout le catalogue** par distance avant pagination (SQL `distance_km ASC NULLS LAST, ...`, display-service `display/views.py`). Un pâtissier sans adresse enregistrée (`distance_km` NULL) apparaît en fin de liste, jamais en tête.
4. **Scroll infini.** Approcher le bas de la liste (`shouldLoadMore`, seuil 700px ou 70 % de la hauteur scrollable) déclenche la page suivante ; `_hasMore=false` affiche « Plus de produits disponibles pour le moment. » au lieu de retenter indéfiniment.
5. **Pull-to-refresh.** Réinitialise `_currentPage=1`, vide le cache `DisplayApi` (`_displayApi.clearCache()`) et les distances en cache.
6. **Changement de position en cours de session** (via la puce `LocationChip` ou le SnackBar). `LocationService` notifie `HomeScreen._onLocationChanged` ; le cache de distances est vidé (`_distanceCache.clear()`) avant le rechargement pour ne jamais afficher un kilométrage calculé depuis l'ancienne position.

## 4. Cas de bord et erreurs attendues

- **Aucun produit dans le rayon appliqué.** État vide dédié (`_buildEmptyState`, clé `home_empty_state`) avec un bouton « Voir toute la France » (`home_empty_all_france`, bascule `_radius` sur `DistanceRadius.allFrance()`) et un bouton « Changer de lieu »/« Choisir un lieu » (`home_empty_change_place`). Ne jamais laisser un écran vide sans porte de sortie.
- **Recherche texte sans résultat.** Message dédié (« Aucune pâtisserie ne correspond à « … » »), pas de bouton « Toute la France » (non pertinent pour une recherche texte).
- **Le `search` tapé dans la barre de l'accueil ne recharge JAMAIS depuis le serveur.** `_onSearchChanged`/`_onSearch` (`home_screen.dart:390-406`) ne font qu'un filtrage **local** (`TextUtils.containsIgnoreAccents`) sur `_allProducts`, c'est-à-dire sur les produits **déjà paginés** dans la session. Un produit qui matche le texte mais qui n'a pas encore été chargé (page 3+, non atteinte par le scroll) **n'apparaîtra pas**, même s'il existe. Seul le point d'entrée `initialSearchQuery` (recherche lancée depuis le tiroir/drawer, `context.go('/', extra: {'searchQuery': ...})`) déclenche un rechargement serveur avec `search` en paramètre — mais voir la limite ci-dessous.
- **Le paramètre `search` envoyé au serveur est silencieusement ignoré.** `DisplayApi.getHomePayload` envoie bien `search` en query param vers `GET /api/display/products/home/payload/`, mais `display/views.py::home_screen_payload` ne lit **que** `page`, `page_size`, `lat`, `lon`, `radius_km` — aucune lecture de `request.query_params.get('search', ...)` dans tout le fichier. Même la recherche « serveur » déclenchée par le drawer revient donc, en pratique, à charger la première page normale (non filtrée) puis à la filtrer localement via `_applyFilters()`. À vérifier explicitement : une recherche déclenchée depuis le drawer sur un produit qui n'est PAS sur la première page ne le trouve pas non plus.
- **`ordering` (tri prix/note) est également ignoré côté serveur** — même constat (absent de `home_screen_payload`). Le tri « Prix croissant » / « Prix décroissant » / « Note » (`_buildMainContent`, `sortedProducts.sort(...)`) ne réordonne donc que **les produits déjà chargés en mémoire**, pas tout le catalogue. Sur un catalogue de plusieurs pages, trier par prix après avoir chargé 2 pages ne fait pas remonter un produit moins cher resté en page 3. Seul le tri par distance est réellement fait côté serveur, avant pagination (voir §3). **À tester explicitement avec plus d'une page de résultats.**
- **`page`/`page_size` invalides.** `page < 1` ou non entier → `400 bad_request` côté display-service (`home_screen_payload`) ; vérifier que le client ne peut pas produire ce cas en usage normal (pagination pilotée uniquement par `_currentPage`, jamais par une saisie utilisateur).
- **Erreur réseau au chargement.** `_loadProducts` catch générique → `_isLoading=false`, liste vide affichée sans message d'erreur dédié (contrairement à `favorites_screen.dart` ou `notifications_screen.dart`, qui ont un état d'erreur explicite). À signaler si observé : l'écran d'accueil ne distingue pas visuellement « zéro produit » de « échec réseau ».

## 5. Règles métier à vérifier

- **Aucune coordonnée ni adresse de pâtissier n'est jamais renvoyée par cet endpoint** — `display/views.py::home_screen_payload` : le JSON `baker` embarqué ne contient plus `latitude`/`longitude`/`address_label` depuis PAT-57 (commentaire explicite en tête de la méthode). Seule une `distance_km` calculée côté serveur est exposée. Vérifier via `read_network_requests` sur la réponse réelle.
- **L'endpoint est public (`AllowAny`)** — la navigation catalogue doit fonctionner sans compte (`display/views.py`, `ProductViewSet.permission_classes = [AllowAny]`). Un utilisateur non connecté doit voir exactement la même liste (sans les `is_favorite` personnalisés, qui restent `false`).
- **Position jamais persistée** — cf. règle CLAUDE.md non négociable, déjà couverte par [`../transverse/localisation-memorisation.md`](../transverse/localisation-memorisation.md) ; ce document ne fait que consommer `LocationService`, il n'écrit jamais de coordonnées.

## 6. Non-régressions connues

- **display-service, 2 échecs pré-existants confirmés et non liés à une régression récente** : `test_authenticated_no_coords` et `test_authenticated_with_coords_returns_distance` (classe `HomePayloadTests`, `display/tests.py`) renvoient `500` au lieu de `200`. Confirmés indépendants des livraisons en cours (vérifiés par `git stash`, cf. `Documentations/qa/role.md` et `Documentations/qa/state.md`, campagnes du 2026-08-04/05 : 36/38 puis 33/35 selon les campagnes, toujours exactement ces 2 échecs). **Ne pas re-diagnostiquer à chaque campagne : juste confirmer qu'aucun autre test de cette classe n'a rejoint la liste.**
- **PAT-49/PAT-50** : avant correctif, le tri par distance se faisait après pagination (« les plus proches parmi N produits arbitraires » au lieu de « les N produits les plus proches du catalogue entier »). Le commentaire dans `home_screen.dart` (`_buildMainContent`, case `default`) rappelle explicitement de ne jamais retrier localement par distance — seul le serveur en a le droit, avant pagination. Si un futur retri local par distance apparaît, c'est une régression directe de PAT-49/50.
- **Web : boucle de chargement au retour sur l'accueil.** `shouldLoadMore` retourne `false` si `metrics.maxScrollExtent <= 0` (sinon `extentAfter < threshold` reste vrai indéfiniment sur un contenu qui ne déborde pas) — commentaire explicite dans le code signalant que c'était la cause principale des gels web au retour sur l'accueil. À retester si le comportement de scroll infini est modifié.

## 7. Comment vérifier

- Backend : `display-service` — `python manage.py test --keepdb`, cible attendue : tous verts sauf les 2 échecs connus de la classe `HomePayloadTests` (§6). `manage.py check` sans erreur.
- `read_network_requests` sur `GET /api/display/products/home/payload/` pour confirmer l'absence de `latitude`/`longitude`/`address_label` dans le JSON `baker`, et pour observer concrètement que `search`/`ordering` envoyés par le client ne changent pas le jeu de résultats renvoyé par le serveur (comparer deux appels avec/sans ces paramètres, même page/position).
- Frontend : `flutter analyze` (0 erreur) ; `computeTargetItemCountForTest`/`estimateItemsPerRowForTest`/`shouldLoadMore` sont exposés pour test unitaire (`home_screen.dart`, fin de fichier) — vérifier qu'ils sont bien couverts si l'écran est retouché.
- Vérification manuelle staging : charger plus de 2 pages (scroller), puis taper une recherche correspondant à un produit resté hors des pages déjà chargées — confirmer qu'il n'apparaît pas (comportement actuel, pas un bug à corriger dans ce document, mais un point à ne pas confondre avec un vrai bug de recherche).

## 8. Definition of done

- [ ] Accueil sans position : liste chargée, aucune distance affichée, pas de crash
- [ ] Accueil avec position : tri par distance correct sur tout le catalogue (pas seulement la page reçue)
- [ ] Scroll infini charge bien les pages suivantes puis affiche le message de fin de liste
- [ ] Pull-to-refresh vide bien les caches (produits, distances, favoris) avant de recharger
- [ ] État vide avec les deux boutons de sortie (Toute la France / Changer de lieu) quand un rayon est appliqué
- [ ] Aucune coordonnée/adresse de pâtissier dans la réponse `home/payload` (vérifié réseau)
- [ ] Tests `display-service` verts hors les 2 échecs connus de `HomePayloadTests`
- [ ] `flutter analyze` 0 erreur
