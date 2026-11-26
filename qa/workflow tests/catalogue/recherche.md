# Recherche

| | |
|---|---|
| **Statut** | 🔁 à revoir — voir constat §1, la fonctionnalité telle que conçue (search-service) n'est pas branchée |
| **Écrit avant le développement ?** | non — écrit en constatant l'état réel du code le 2026-09-22 |
| **Écrans concernés** | Barre de recherche de l'accueil (`SearchBarWidget`, `home_screen.dart`) et barre de recherche du tiroir (`SearchBarWithSuggestions`, `toolbar_with_drawer.dart`) — il n'existe **pas** d'écran dédié `/search` |
| **Endpoints concernés** | `GET /api/display/products/home/payload/` (display-service, réellement utilisé) ; `GET /api/search/products/`, `GET /api/search/bakers/` (search-service, code client écrit mais **jamais appelé**) |
| **Tickets Linear liés** | — |
| **Dernière relecture** | 2026-09-22 |

---

## 1. Périmètre — et un constat à lire avant de tester quoi que ce soit

Ce document couvre tout ce que l'app appelle « recherche » : la saisie dans la barre de l'accueil, et la saisie dans la barre du tiroir. **Constat de lecture de code, à ne pas supposer résolu sans revérifier au moment du test** : `lib/features/search/data/datasources/search_api.dart` définit un client complet pour `search-service` (`searchProducts`, `searchBakers` — filtres prix, note, catégorie, spécialité, ville, tri, pagination) mais `grep -rn "SearchApi(" lib/` ne retourne **aucun** appel en dehors de ce fichier lui-même. Aucune route, aucun écran, aucun bouton de l'app n'instancie `SearchApi`. `search-service` existe côté backend mais n'est **jamais interrogé par le frontend** en l'état actuel du code.

Ce que l'app appelle réellement « recherche » aujourd'hui :
- **Sur l'accueil** : un filtrage **local** du nom de produit sur les produits déjà chargés (voir [`accueil.md`](accueil.md) §4 pour le détail — ne pas dupliquer ici).
- **Depuis le tiroir** (`SearchBarWithSuggestions`, bouton loupe du drawer) : navigue vers `/` avec `extra: {'searchQuery': query}`, ce qui alimente `initialSearchQuery` sur `HomeScreen` et déclenche un `_loadProducts(reset: true)` — donc, in fine, le **même** mécanisme que l'accueil, avec en plus un paramètre `search` envoyé au serveur mais silencieusement ignoré par `display-service` (voir `accueil.md` §4).

Ne pas dupliquer ici le détail du filtrage/tri de l'accueil : ce document se concentre sur ce qui est spécifique à la saisie de recherche (historique, ce qui est réellement cherchable, comportement 0 résultat).

## 2. Préconditions

- `client@exemple.com` ou navigation anonyme (le chargement sous-jacent est le même endpoint public que l'accueil).
- Au moins un produit dont le nom contient une chaîne de test distinctive chez `patissier@exemple.com` (baker 5).
- Staging (`stg.patisry.fr`).

## 3. Scénario nominal (happy path)

1. **Taper dans la barre du tiroir et valider.** `SearchBarWithSuggestions._performSearch` enregistre le terme dans l'historique local (`SearchHistoryService.addToHistory`, `SharedPreferences`, clé `search_history`, 10 entrées max) puis appelle `onSearch` → `context.go('/', extra: {'searchQuery': query})`. Résultat attendu : navigation vers l'accueil, filtrage sur le nom des produits **déjà chargés lors du premier appel `initialSearchQuery`** (une seule page, cf. §4).
2. **Taper directement dans la barre de l'accueil.** Filtrage strictement local et instantané (`TextUtils.containsIgnoreAccents`, insensible aux accents/casse) sur `_allProducts` — pas d'appel réseau supplémentaire à chaque frappe.
3. **Recherche par nom de produit correspondant à un produit chargé.** Le produit apparaît dans la liste filtrée.
4. **Recherche par nom de pâtissier ou par ville.** **Ne fonctionne pas** — le filtre local (`_applyFilters`, `home_screen.dart`) ne teste que `product.name`, jamais `product.baker.name` ni la ville. Un client qui tape le nom d'un pâtissier plutôt que celui d'un gâteau n'obtient aucun résultat, même si ce pâtissier a des produits actuellement chargés. À vérifier explicitement : c'est un vrai écart avec ce qu'un utilisateur attend d'une « recherche ».

## 4. Cas de bord et erreurs attendues

- **Terme ne correspondant à aucun produit chargé.** État vide dédié sur l'accueil (« Aucun résultat » / « Aucune pâtisserie ne correspond à « … » », cf. `accueil.md` §4) — jamais un écran blanc ni un crash.
- **Terme correspondant à un produit existant mais non encore chargé (page 3+ du catalogue).** Aucun résultat affiché, alors que le produit existe réellement côté serveur — conséquence directe du constat du §1 (pas d'appel serveur filtré). Un testeur qui ne connaît pas ce détail conclura à tort à un bug de recherche « bête » ; c'est en réalité l'absence de recherche serveur. **Documenter, pas corriger dans ce fichier.**
- **Recherche vide / espaces uniquement.** `_performSearch` dans `SearchBarWithSuggestions` n'ajoute rien à l'historique et n'appelle pas `onSearch` si `query.trim().isEmpty`.
- **Historique de recherche.** `SearchHistoryService` (SharedPreferences, donc **sur l'appareil uniquement**, jamais en base) stocke jusqu'à 10 termes, déduplique en remontant le terme réutilisé en tête. **Fonctionnalité non branchée à l'UI** : le code d'affichage des suggestions dans `SearchBarWithSuggestions` (liste, tap, `_hideSuggestions`, `SearchSuggestions` widget) est intégralement commenté (`// Commenté temporairement`, `// TODO: Corriger le z-index pour que la modal passe au-dessus des autres éléments`). L'historique est donc écrit à chaque recherche mais **jamais lu ni affiché** à l'utilisateur actuellement — à vérifier que ce n'est pas régressé plus loin (ex. écriture qui échoue silencieusement) si ce code est un jour réactivé.

## 5. Règles métier à vérifier

- Aucune donnée de géolocalisation n'est en jeu ici : la recherche ne lit ni n'écrit de position (contrairement à l'accueil). Pas de règle RGPD spécifique à ce document.
- `search-service` (`public_fields.py` de ce service) applique déjà une règle stricte sur le filtre `location`/ville en `iexact` plutôt que `icontains` par cohérence avec le correctif PAT-57 de baker-service (voir [`fiche-patissier-publique.md`](fiche-patissier-publique.md) §... pour le détail de ce correctif) — **sans objet tant que le frontend n'appelle pas `search-service`**, à revérifier si le branchement est fait un jour.

## 6. Non-régressions connues

_Aucune connue à ce jour sur le mécanisme réellement utilisé (filtrage local) — le point à surveiller n'est pas une régression mais l'écart de conception documenté au §1. Si `search-service` est un jour branché au frontend, ce document devra être entièrement réécrit (nouveaux endpoints, nouveaux cas de bord : filtres prix/note/catégorie de `SearchApi`, pagination serveur réelle)._

## 7. Comment vérifier

- Confirmer l'absence d'appel à `search-service` avant toute campagne : `grep -rn "SearchApi(" lib/` ne doit renvoyer que `lib/features/search/data/datasources/search_api.dart` lui-même. Si ce grep renvoie un autre fichier, ce document est périmé — passer le statut en `🔁 à revoir` et le réécrire à partir de l'écran qui l'appelle réellement.
- Le reste de la vérification (chargement, filtre local, état vide) est celui de [`accueil.md`](accueil.md) §7 — ne pas dupliquer.
- `flutter analyze` 0 erreur.

## 8. Definition of done

- [ ] Recherche depuis le tiroir navigue bien vers l'accueil et filtre correctement les produits déjà chargés
- [ ] Recherche directe sur l'accueil filtre en local, insensible aux accents/casse
- [ ] État vide correct quand aucun produit chargé ne correspond
- [ ] Confirmé (grep) qu'aucun appel à `search-service` n'a été ajouté sans mise à jour de ce document
- [ ] `flutter analyze` 0 erreur
