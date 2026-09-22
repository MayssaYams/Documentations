# Fiche produit

| | |
|---|---|
| **Statut** | ✅ rédigé et à jour |
| **Écrit avant le développement ?** | non — écran déjà en production, rédigé rétroactivement le 2026-09-22 |
| **Écrans concernés** | `product_screen.dart` (route `/products/:id`) |
| **Endpoints concernés** | `GET /api/display/products/{id}/full/` (display-service, public), `POST /api/orders/cart/items/` (order-service), favoris (voir [`favoris.md`](favoris.md)), avis (`GET` via `review-service`, voir [`../commande-et-paiement/avis.md`](../commande-et-paiement/avis.md)) |
| **Tickets Linear liés** | PAT-26 (calendrier grisé), PAT-57 (adresse jamais publique) |
| **Dernière relecture** | 2026-09-22 |

---

## 1. Périmètre

Fiche produit complète : chargement, calendrier de disponibilité, sélection taille/variante/quantité, ajout au panier, ajout aux favoris, section pâtissier, avis, produits suggérés. Ne couvre pas le détail du panier/paiement (→ [`../commande-et-paiement/panier-et-validation-commande.md`](../commande-et-paiement/panier-et-validation-commande.md)), ni le contenu de la fiche pâtissier publique elle-même (→ [`fiche-patissier-publique.md`](fiche-patissier-publique.md)), ni les avis en détail (→ [`../commande-et-paiement/avis.md`](../commande-et-paiement/avis.md)).

## 2. Préconditions

- `client@exemple.com` connecté pour ajout panier/favoris ; navigation anonyme possible pour la simple consultation (endpoint `AllowAny`, voir §5).
- Un produit actif chez `patissier@exemple.com` (baker 5), avec au moins une taille et un délai de préparation renseigné (`preparation_time` ou `delivery_info.preparation_time_hours`).
- Staging (`stg.patisry.fr`).

## 3. Scénario nominal (happy path)

1. **Ouvrir un produit depuis l'accueil ou un lien direct `/products/:id`.** Chargement via `GET .../products/{id}/full/`, timeout 5 s. Affichage image(s), infos, tailles/variantes, ingrédients, allergènes, calendrier, avis, section pâtissier, produits suggérés.
2. **Sélectionner une date dans le calendrier.** Ouvre automatiquement (après 100 ms) le sélecteur de créneau horaire.
3. **Sélectionner un créneau disponible.** Déclenche directement l'ajout au panier guidé (`_guardedAddToCart`), sans repasser par le bouton « Commander ».
4. **Ajuster la quantité** (respecte `minOrderQuantity`/`maxOrderQuantity`, arrondi au multiple de `lotSize` si le produit est vendu par lot).
5. **Appuyer sur « Commander ».** Si date/heure déjà choisies → ajout direct au panier local (`CartService`) + appel `order-service` (`POST /cart/items/`) ; sinon, scroll automatique vers le calendrier avec un SnackBar explicite (« Veuillez choisir une date de réception »).
6. **Ajouter/retirer des favoris** (cœur). Nécessite d'être connecté — sinon SnackBar « Connectez-vous pour ajouter aux favoris », pas de redirection forcée vers le login.
7. **Section pâtissier.** Affiche nom commercial, note (si `ratingVisible`), ancienneté sur la plateforme, description tronquée (3 lignes) avec lien « Lire la suite » vers `/bakers/:id`. **Jamais d'adresse ni de ville ici** — voir §5.

## 4. Cas de bord et erreurs attendues

- **Calendrier — date dont tous les créneaux sont indisponibles (bug PAT-26).** Le calcul de la première date sélectionnable (`_computeFirstSelectableDate`) et le calcul des créneaux horaires disponibles (`_openTimePickerForSelectedDate`) doivent utiliser **la même source de vérité** — sinon une date apparaît cliquable dans le calendrier mais s'ouvre sur un sélecteur d'heure entièrement grisé. Le code documente explicitement ce piège (commentaires en tête de `_ProductScreenState` et sur `_dayHasAnyEnabledSlot`) : les deux calculs partagent désormais `_computeFirstSelectableDate()` et les mêmes constantes `_defaultDayStart`/`_defaultDayEnd`. `_dayHasAnyEnabledSlot` grise dans le calendrier lui-même le tout premier jour sélectionnable si son dernier créneau (`_defaultDayEnd`, 18h00) tombe avant `now + 30 min` — **à retester explicitement en fin de journée (après ~17h30)**, c'est le seul moment où ce cas peut se produire naturellement. Vérifier qu'aucune date n'est cliquable dans le calendrier si elle n'a effectivement aucun créneau ouvrable une fois le sélecteur d'heure ouvert.
- **Web : cliquer un produit suggéré doit changer l'URL ET le contenu.** Bug historique documenté dans `Documentations/qa/solution.md` §4 (« URL modifiée, page figée ») : sans clé Flutter, deux routes `/products/:id` avec un `id` différent sont vues comme le même widget (même type, même position dans l'arbre) — le `State` est réutilisé, `initState()` ne se relance pas, l'URL change mais le produit affiché reste l'ancien. **Corrigé** dans `lib/app.dart` (route `/products/:id`) par `key: ValueKey('product-$productId')`, avec un commentaire explicite décrivant exactement ce bug. **Non-régression à vérifier à chaque changement de cette route** : si la clé disparaît un jour (refactor de la route, changement du builder), le bug réapparaît silencieusement — pas d'erreur, juste un contenu figé. Test : depuis une fiche produit, cliquer un produit dans « D'autres douceurs à découvrir », vérifier que l'URL **et** le titre/image affichés changent.
- **Produit désactivé consulté par son propriétaire.** Un pâtissier qui ouvre la fiche de son propre produit désactivé (404 sur l'endpoint public) reçoit un fallback : `_loadInactiveProductForOwner` retente via `product-service` directement (pas display-service) et vérifie que le produit appartient bien au baker connecté (`getProductsByBakerList`) avant de l'afficher. Un produit désactivé d'un **autre** pâtissier reste en 404 (« Ce produit n'existe pas »).
- **Produit introuvable / retiré.** État dédié « Ce produit n'existe pas / Il a peut-être été retiré par le pâtissier », pas de bouton réessayer (contrairement aux erreurs réseau).
- **Pas de connexion internet / serveur ne répond pas.** États dédiés distincts (`noInternet` vs `loadError`), tous deux avec bouton « Réessayer ». Distinction faite sur le type de `DioException` (timeout/connexion vs autre).
- **Ajout au panier sans être connecté.** Redirige vers `/login` avec la commande en attente sérialisée dans `extra` (`returnRoute: '/cart'`, `returnArgs: {'pendingOrder': ...}`) plutôt que de simplement bloquer — à vérifier que la commande se retrouve bien reconstituée après connexion.
- **Retour sur l'écran après plus de 30 s en arrière-plan** (`AppNavigation.staleResumeThreshold`). Recharge automatiquement le produit (`_maybeReloadAfterStaleResume`) — utile si le pâtissier a changé la disponibilité/le prix entre-temps. Vérifier qu'un retour rapide (< 30 s) ne recharge pas inutilement.
- **Choix de taille manquant à la commande.** Si le produit a des tailles mais qu'aucune n'est sélectionnée, SnackBar « Veuillez choisir une taille avant de commander », pas de crash ni d'ajout silencieux au prix de base.

## 5. Règles métier à vérifier

- **L'adresse exacte du pâtissier n'apparaît jamais sur la fiche produit.** La section « Où récupérer ma commande » est volontairement absente du code actuel — commentaire explicite dans `_buildProductInfo`/corps de `build()` : « L'adresse exacte du pâtissier n'est jamais publique [...] elle est transmise au client par message automatique quand sa commande passe en « prête » ». Vérifier qu'aucun champ latitude/longitude/adresse ne transite, même indirectement, dans le payload `baker` de `_bakerFromDisplay` (le mapping ne lit que `business_name`, `description`, `average_rating`, `profile_image_url`, `phone_number`, `email`, `location` — ce dernier n'est **jamais rendu à l'écran** sur cette fiche, contrairement à la fiche pâtissier, voir [`fiche-patissier-publique.md`](fiche-patissier-publique.md)).
- Le prix affiché au client (taille sélectionnée **remplace** le prix de base ; la variante s'y **additionne**) — vérifier que `_calculateTotalPrice()` respecte bien cette distinction, un bug de calcul ici a un impact direct sur le paiement.

## 6. Non-régressions connues

- **PAT-26** : date affichée sélectionnable mais tous ses créneaux grisés une fois le sélecteur d'heure ouvert — voir détail au §4. Corrigé par le partage d'une source de vérité unique (`_computeFirstSelectableDate`) entre calendrier et sélecteur d'heure.
- **Bug URL/contenu figé sur le web** (solution.md §4) — corrigé par `ValueKey('product-$productId')` sur la route `/products/:id`. Voir détail §4 ; à retester à chaque modification de `lib/app.dart` autour de cette route.

## 7. Comment vérifier

- Backend : `display-service` (endpoint `products/{id}/full/`), `order-service` (ajout panier) — `manage.py test` sur les deux.
- Frontend : `flutter analyze` (0 erreur). Le calendrier n'a pas de test automatisé dédié identifié dans le dépôt au moment de la rédaction — vérification manuelle obligatoire, de préférence en fin de journée pour couvrir le cas PAT-26 (§4).
- Vérification manuelle staging : cliquer un produit suggéré depuis une fiche produit sur le **build web**, confirmer changement d'URL + de contenu (bug PAT-57/solution.md §4).

## 8. Definition of done

- [ ] Chargement produit + calendrier + tailles/variantes + panier fonctionnels de bout en bout
- [ ] Aucune date cliquable sans créneau réellement disponible (testé en fin de journée)
- [ ] Web : clic sur un produit suggéré change URL **et** contenu
- [ ] Ajout favoris/panier sans connexion redirige proprement, sans perte de la sélection en cours
- [ ] Aucune adresse ni coordonnée de pâtissier visible sur la fiche produit
- [ ] Produit désactivé : 404 pour un tiers, visible en fallback pour son propriétaire
- [ ] `flutter analyze` 0 erreur, tests `display-service`/`order-service` verts
