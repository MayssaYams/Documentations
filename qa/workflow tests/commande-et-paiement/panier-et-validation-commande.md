# Panier et validation de commande (checkout)

| | |
|---|---|
| **Statut** | ✅ rédigé et à jour |
| **Écrit avant le développement ?** | non — fonctionnalité déjà en production, rédigé rétroactivement le 2026-09-22 |
| **Écrans concernés** | `cart_screen.dart` (`/cart`), `payment_screen.dart` (`/payment`), `payment_confirmation_screen.dart` (`/payment/confirmation`) |
| **Endpoints concernés** | `POST /api/cart/checkout/` (order-service) |
| **Tickets Linear liés** | epic PAT-43 (multi-baker au panier), PAT-69 (500 sans adresse) |
| **Dernière relecture** | 2026-09-22 |

---

## 1. Périmètre

Du panier rempli jusqu'à la commande confirmée créée en base. Ne couvre pas la gestion des moyens de paiement enregistrés (→ [`moyens-de-paiement.md`](moyens-de-paiement.md)) ni ce qui se passe après (→ [`cycle-de-vie-commande.md`](cycle-de-vie-commande.md)).

**Important (comportement actuel, à ne pas « corriger » sans décision produit)** : l'action « Confirmer et payer » appelle directement `POST /api/cart/checkout/` — **il n'y a pas de passage par le SDK Stripe** dans ce flux (`payment-service` gère les moyens de paiement enregistrés mais pas encore le paiement réel, cf. PAT-55 « Stripe Connect » toujours en Backlog). Ne pas exiger de test 3DS/PaymentIntent tant que PAT-55 n'est pas livré.

## 2. Préconditions

- `client@exemple.com` avec un profil et une adresse renseignés côté user-service (sinon voir cas de bord PAT-69).
- Au moins un produit actif d'un pâtissier de test (baker 5, `patissier@exemple.com`) dans le panier.
- Pour le cas multi-pâtissiers : produits d'au moins 2 pâtissiers de test différents.

## 3. Scénario nominal (happy path)

1. **Ajouter un produit au panier depuis la fiche produit.** Le panier reflète l'ajout (badge/compteur), `push()` vers `/cart` ou retour à la fiche produit selon le point d'entrée — le retour système doit revenir à la fiche produit, pas quitter l'app (cf. [`../transverse/navigation-retour-systeme.md`](../transverse/navigation-retour-systeme.md)).
2. **Panier avec un seul pâtissier → paiement.** `/cart` liste les articles, quantités modifiables, sous-total correct. Bouton vers `/payment` (`push()`).
3. **Écran paiement, non connecté.** Redirection vers `/login` avec retour prévu vers `/payment` après connexion (cf. limite connue en section 6).
4. **Confirmer et payer.** Appel `POST /api/cart/checkout/` → `201`. Le panier est vidé. Navigation vers `/payment/confirmation` (`go()`, volontaire — fin de parcours).
5. **Commande créée en base.** Une ligne `orders` par pâtissier, statut initial `pending_confirmation`. Un `checkout_reference` (UUID) commun si plusieurs pâtissiers (voir étape 6).
6. **Panier multi-pâtissiers (2+ pâtissiers de test).** Au panier, le client est prévenu explicitement qu'il y aura **N retraits à N adresses différentes** (règle CLAUDE.md, click & collect). Au checkout : **N commandes distinctes créées**, partageant le même `checkout_reference`. Vérifier en base : `SELECT COUNT(*), checkout_reference FROM orders WHERE ... GROUP BY checkout_reference`.

## 4. Cas de bord et erreurs attendues

- **Client sans adresse renseignée.** Doit produire une erreur métier claire (400) gérée par l'UI, **jamais un 500** — c'était le bug PAT-69 (tout client sans adresse ne pouvait pas commander du tout). Reproduire en vidant l'adresse du compte de test avant de checkout.
- **Article avec `special_instructions`.** Doit créer **automatiquement** une conversation client↔pâtissier + un message `order_request` (`delivery_status='sent'`). Vérifier que le message arrive vraiment en base (`SELECT * FROM messages WHERE message_type='order_request' ...`), pas seulement que la commande est créée — un bug l'a longtemps fait échouer silencieusement (contrainte DB qui refusait le type, erreur avalée).
- **Plusieurs produits avec `special_instructions` d'un même pâtissier.** Doit créer **plusieurs** messages `order_request`, pas un seul fusionné.
- **Panier vidé entre l'ajout et le checkout** (ex : produit désactivé entretemps par le pâtissier). Message clair, pas de commande fantôme créée.
- **Retour navigateur (web) depuis `/payment/confirmation`.** Ne doit jamais permettre de rejouer `/payment` sur un panier déjà vidé (bug connu, non corrigé — voir PAT-81).

## 5. Règles métier à vérifier

- Click & collect uniquement — aucune logique de livraison à observer, même si `orders.delivery_address`/`delivery_fee` existent en base (colonnes volontairement dormantes, CLAUDE.md).
- N commandes = N retraits à N adresses différentes, le client doit en être averti **au panier**, avant de payer.
- `delivery_status` toujours `'sent'` sur les INSERT `messages` créés par le checkout.

## 6. Non-régressions connues

- **PAT-69 (2026-09-16)** : checkout en 500 pour tout client sans adresse — plus aucun client ne pouvait commander. Corrigé, à revérifier à chaque changement du endpoint checkout ou du modèle adresse client.
- **Messages `order_request` avalés silencieusement** (avant correctif) : la commande se créait mais le message jamais — toujours vérifier le message en base, pas seulement le code retour HTTP.
- **PAT-82 (non corrigé, connu)** : après connexion depuis `/payment`, le retour ramène à l'accueil et non au panier/produit d'origine — comportement actuel à ne pas signaler comme un nouveau bug tant que PAT-82 n'est pas traité.

## 7. Comment vérifier

- Backend : `order-service` (`manage.py test`, cf. [`role.md`](../role.md) pour le tunnel DB) + vérif manuelle des tables `orders` et `messages` après un checkout de test.
- Frontend : `flutter analyze` + `flutter build web --no-tree-shake-icons` propres ; test manuel sur `stg.patisry.fr` avec `client@exemple.com`.
- Ne jamais utiliser de vraie carte ni de compte Stripe réel — hors périmètre MVP actuel (voir §1).

## 8. Definition of done

- [ ] Checkout mono-pâtissier réussit de bout en bout, commande visible dans `orders`
- [ ] Checkout multi-pâtissiers crée N commandes avec un `checkout_reference` commun, avertissement affiché au panier
- [ ] `special_instructions` crée bien le(s) message(s) `order_request` en base, vérifié directement en SQL
- [ ] Client sans adresse : erreur métier propre, jamais un 500 (PAT-69)
- [ ] `flutter analyze` (0 erreur) et tests `order-service` verts
