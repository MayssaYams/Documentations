# Favoris

| | |
|---|---|
| **Statut** | 🔁 à revoir — bug connu (§4) non retrouvé de protection côté code, à reconfirmer |
| **Écrit avant le développement ?** | non — écran déjà en production, rédigé rétroactivement le 2026-09-22 |
| **Écrans concernés** | `favorites_screen.dart` (route `/favorites`), `favorite_group_detail_screen.dart` (route `/favorites/group`) |
| **Endpoints concernés** | `favorite-service` (`GET/POST/DELETE .../favorites/`, `.../favorites/groups/...`) |
| **Tickets Linear liés** | PAT-80 (audit code mort) |
| **Dernière relecture** | 2026-09-22 |

---

## 1. Périmètre

Liste des favoris (groupes + « Tous »), détail d'un groupe, ajout/retrait. Ne couvre pas le cœur d'ajout depuis la fiche produit elle-même (→ [`fiche-produit.md`](fiche-produit.md) §3). Ne couvre pas `favorite/favorite_screen.dart` (dossier singulier) — voir constat §1bis, ce fichier est traité comme du code mort tant qu'il n'est pas prouvé vivant.

**Constat code mort — vérifié, pas supposé** : `lib/features/favorite/presentation/favorite_screen.dart` (dossier **singulier** `favorite/`, distinct de `favorites/` qui contient les écrans réellement utilisés) n'est référencé nulle part. `grep -n "favorite_screen" lib/app.dart` ne retourne rien ; `grep -rln "features/favorite/presentation/favorite_screen\|FavoriteScreen(" lib/` (en excluant le fichier lui-même) ne retourne rien non plus. Seuls `favorites_screen.dart` et `favorite_group_detail_screen.dart` (dossier pluriel) sont importés dans `app.dart`. **`favorite_screen.dart` (singulier) est confirmé mort** — cohérent avec l'audit PAT-80 qui le liste déjà. Ne pas écrire de scénario de test dessus ; signaler sa suppression comme dette si PAT-80 n'est pas encore clos.

## 2. Préconditions

- `client@exemple.com` connecté (favoris nécessite une session — `FavoritesService.loadAll()` vérifie `_authService.isLoggedIn` en interne avant tout appel réseau).
- Au moins 2 produits favoris chez `patissier@exemple.com` (baker 5), dans au moins un groupe personnalisé en plus du groupe « Tous ».
- Un produit favori que l'on désactivera en cours de test (voir §4).
- Staging (`stg.patisry.fr`).

## 3. Scénario nominal (happy path)

1. **Ouvrir `/favorites` connecté avec des favoris existants.** Grille de groupes : « Tous » toujours présent en premier si au moins un favori existe (`showCount: false`), puis les groupes personnalisés (`showCount: true`), chacun avec sa vignette (premier item du groupe) et son décompte.
2. **Ouvrir un groupe.** Navigue vers `/favorites/group` avec `extra: {'groupId': ...}` → `FavoriteGroupDetailScreen` charge via `FavoritesService.getGroupFavorites(groupId)`.
3. **Retirer un favori.** Disparaît de la liste et du décompte du groupe immédiatement (écoute `FavoritesService` via `addListener`/`notifyListeners`).
4. **Pull-to-refresh.** `FavoritesService.loadAll(force: true)`.
5. **Connexion en cours de session sur l'écran favoris** (ex. redirection post-login). `_onAuthChanged` détecte le passage `logged=false → true` et force un rechargement (`loadAll(force: true)`).

## 4. Cas de bord et erreurs attendues

- **Produit désactivé toujours visible en favoris — bug réel déjà rencontré (`Documentations/qa/solution.md` §4 : « ne doit plus apparaître : ni sur l'accueil, ni dans la section favoris de l'accueil (oubli réel), ni en recherche »).** Lecture de code effectuée pour ce document : `grep -n "isActive\|is_active\|active" lib/core/services/favorites_service.dart` ne retourne **aucun résultat** — le service Flutter ne filtre jamais par statut actif. Côté backend, `grep -rln "is_active\|active" Backend/favorite-service --include="*.py"` (hors venv/migrations) ne retourne rien non plus : **aucun filtrage par `is_active` n'existe ni côté client ni côté serveur pour la liste des favoris.** Sur la seule base de cette lecture, le bug documenté dans `solution.md` paraît **toujours reproductible** — à confirmer en priorité par un test manuel (désactiver un produit favori depuis « Mes pâtisseries » avec le compte pâtissier, puis recharger `/favorites` avec le compte client qui l'avait mis en favori). Ne pas supposer corrigé sans l'avoir revu à l'écran.
- **Groupe vide après retrait du dernier favori.** Vérifier que le groupe « Tous » disparaît proprement de la grille (condition `if (allFavorites.isNotEmpty)`) plutôt que de laisser une carte vide ou un crash sur `allFavorites.first`.
- **Aucun favori du tout.** État vide dédié (icône cœur, « Aucun favori pour le moment », bouton « Découvrir nos pâtisseries » → `/`).
- **Échec de chargement (réseau).** État d'erreur dédié avec bouton « Réessayer » (`_favoritesService.clearLoadError()` puis rechargement) — distinct de l'état vide, ne pas confondre les deux dans un test.
- **`/favorites` visité sans être connecté.** La route `/favorites` **n'est pas** listée dans `_protectedPathPrefixes` de `app.dart` (contrairement à `/account`, `/notifications`, `/payment`, `/write-review`) — il n'y a donc **pas** de redirection automatique vers le login au niveau du routeur. La protection ne vient que de `FavoritesService.loadAll()` qui vérifie `isLoggedIn` en interne et ne déclenche aucun appel réseau sinon. **À vérifier explicitement** : un visiteur non connecté qui accède directement à `/favorites` (lien direct, bouton mal gardé) doit obtenir un état cohérent (vide ou invitation à se connecter), jamais une erreur réseau brute ou un crash.

## 5. Règles métier à vérifier

- **Produit désactivé invisible partout, y compris en favoris** (`Documentations/qa/solution.md` §4) — voir constat détaillé au §4 : semble non appliqué sur ce chemin précis à la lecture du code actuel, à confirmer par un test réel avant de considérer ce point comme un vrai/faux bug pour ce cycle de validation.
- Aucune donnée de géolocalisation en jeu sur cet écran.

## 6. Non-régressions connues

- **Produit désactivé visible en favoris** (`solution.md` §4, « oubli réel constaté une fois ») — voir §4. Statut à ce jour : **potentiellement toujours actif**, aucune protection trouvée en lecture de code côté `favorites_service.dart` ni côté `favorite-service`. Ne pas cocher cette case en definition of done sans un test manuel positif (désactivation réelle suivie d'un rechargement de l'écran).
- **`favorite/favorite_screen.dart` (singulier), code mort confirmé** — voir §1. À signaler dans un ticket de suppression si PAT-80 ne le couvre pas déjà explicitement.

## 7. Comment vérifier

- Backend : `favorite-service` — `manage.py test`.
- Vérification manuelle staging **obligatoire** pour le bug du §4 : mettre un produit en favori avec `client@exemple.com`, désactiver ce même produit depuis « Mes pâtisseries » avec `patissier@exemple.com` (voir [`mes-patisseries.md`](mes-patisseries.md)), recharger `/favorites` côté client et vérifier s'il a disparu.
- `grep -n "favorite_screen" lib/app.dart` avant toute campagne, pour confirmer que le code mort du §1 n'a pas été relié entre-temps.
- `flutter analyze` 0 erreur.

## 8. Definition of done

- [ ] Ajout/retrait de favori reflété immédiatement sur `/favorites` et `/favorites/group`
- [ ] **Produit désactivé retiré de l'affichage des favoris** — testé réellement, pas supposé (voir §4/§6)
- [ ] État vide et état d'erreur réseau distincts et corrects
- [ ] Comportement de `/favorites` sans connexion vérifié explicitement (pas de crash, pas d'erreur réseau brute)
- [ ] `favorite_screen.dart` (singulier) confirmé mort ou lien vers son ticket de suppression (PAT-80)
- [ ] Tests `favorite-service` verts, `flutter analyze` 0 erreur
