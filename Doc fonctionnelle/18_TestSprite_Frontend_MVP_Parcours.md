# Patisry — Parcours frontend à tester (TestSprite) — MVP sans Stripe

**Application** : Flutter **Patisry** (`Patisry/lib/`).  
**Public** : outil de test automatisé (ex. **TestSprite**), QA, ou agent IA générant des scénarios E2E.  
**Objectif produit** : couvrir le **MVP consommateur** de bout en bout : **authentification → découverte catalogue → fiche produit → panier → validation de commande**, **sans** exercer Stripe, PaymentIntent, webhooks ni saisie de carte réelle.

**Référence MVP** : aligné sur [`16_Vue_PO_Fonctionnalites_et_Phasage.md`](16_Vue_PO_Fonctionnalites_et_Phasage.md) (M1–M3 + validation commande ; **M4 Stripe exclu** de ce document).

---

## 1. Prérequis techniques

| Élément | Détail |
|---------|--------|
| Backend | Services **auth**, **user**, **display**, **product** (données), **order** disponibles et joignables depuis l’app (voir `AppConfig` : `Environment.local` ou `freebox`). |
| Build | Application compilée et installée (simulateur / device / web selon votre cible TestSprite). |
| Données | Au moins **un produit** actif visible sur l’accueil ou via navigation ; compte test ou capacité d’**inscription**. |
| Compte test (recommandé) | Utilisateur avec **profil / adresse** renseignés côté API user pour éviter uniquement les valeurs par défaut du checkout (l’app complète sinon avec champs minimaux). |

**Fichier de configuration des URLs** : `lib/core/config/app_config.dart` (`currentEnvironment`).

---

## 2. Hors périmètre explicite (ne pas exiger dans les tests)

- Paiement **Stripe** (clés publiques, `PaymentIntent`, `client_secret`, 3DS).
- **payment-service** : création de moyens de paiement, remboursements, webhooks.
- Saisie et validation d’un **numéro de carte** réel ou test Stripe.
- **Apple Pay** et **Google Pay** (sélection UI éventuelle sans aller jusqu’au wallet).
- **Notifications push** et centre de notifications (pas dans le MVP de ce document).

**Note importante (comportement actuel de l’app)** : sur l’écran **Paiement** (`PaymentScreen`), l’action **« Confirmer et payer »** déclenche un appel direct à **`POST /api/cart/checkout/`** (order-service) via `OrderApi.checkout` — **sans** passage par le SDK Stripe dans ce flux. Les tests MVP « sans Stripe » doivent donc **valider ce flux jusqu’à confirmation de commande** (SnackBar succès + navigation confirmation), sans simuler un PSP.

---

## 3. Routes nommées utiles (MaterialApp)

| Route | Écran / usage |
|-------|----------------|
| `/` | Accueil (`HomeScreen`) |
| `/login` | Connexion ; arguments possibles : `returnRoute`, `returnArgs` |
| `/register` | Inscription |
| `/product` | Fiche produit ; arguments : `productId` (int), optionnel `pendingAddToFavorite` |
| `/cart` | Panier |
| `/payment` | Paiement / **validation commande** (redirige vers `/login` si non connecté) |
| `/payment/confirmation` | Confirmation après commande |
| `/baker` | Profil pâtissier ; `bakerId` |
| `/favorites` | Favoris |
| `/reviews` | Avis produit ; `productId` |

Les tests doivent privilégier ces routes ou les **gestes utilisateur** équivalents depuis l’accueil.

---

## 4. Scénarios de test — ordre recommandé

Chaque bloc est autonome : **ID** stable pour référence TestSprite, **préconditions**, **étapes**, **résultats attendus**.

---

### TS-MVP-01 — Inscription compte

- **But** : Créer un nouvel utilisateur (M1).
- **Préconditions** : Backend auth joignable ; email non déjà utilisé.
- **Étapes** :
  1. Ouvrir l’app (route initiale `/`).
  2. Naviguer vers **Inscription** (`/register`).
  3. Remplir les champs requis (email, mot de passe, identité, etc. selon l’UI).
  4. Soumettre le formulaire.
- **Résultats attendus** :
  - Réponse succès (201 côté API) ou message UI de succès / redirection vers parcours connecté.
  - Aucun crash ; pas d’erreur réseau non gérée.

---

### TS-MVP-02 — Connexion compte valide

- **But** : Obtenir une session authentifiée (M1).
- **Préconditions** : Compte existant (TS-MVP-01 ou compte de test).
- **Étapes** :
  1. Aller sur `/login`.
  2. Saisir email + mot de passe valides.
  3. Valider.
- **Résultats attendus** :
  - L’utilisateur est reconnu comme connecté (écran compte / accueil connecté ou équivalent).
  - Tokens stockés de façon à autoriser les appels API suivants (panier serveur, checkout).

---

### TS-MVP-03 — Connexion refusée (identifiants invalides)

- **But** : Gestion d’erreur login (M1).
- **Préconditions** : Aucune.
- **Étapes** :
  1. `/login` avec mot de passe incorrect.
- **Résultats attendus** :
  - Message d’erreur utilisateur lisible ; pas de navigation « connecté ».

---

### TS-MVP-04 — Accueil : chargement catalogue (Display)

- **But** : Vérifier le chargement du payload d’accueil (M2).
- **Préconditions** : Display-service joignable ; optionnel : non connecté (catalogue public).
- **Étapes** :
  1. Ouvrir `/`.
  2. Attendre fin de chargement (plus de loader principal).
- **Résultats attendus** :
  - Liste ou grille de produits (ou état vide explicite si aucune donnée).
  - Pas d’erreur bloquante silencieuse.

---

### TS-MVP-05 — Fiche produit détail enrichi

- **But** : Affichage détail produit via display `.../full/` (M2).
- **Préconditions** : `productId` valide connu.
- **Étapes** :
  1. Depuis l’accueil, ouvrir un produit (navigation réelle) **ou** `Navigator` vers `/product` avec `arguments: {'productId': <id>}`.
  2. Attendre le rendu du détail (titre, prix, contenu principal).
- **Résultats attendus** :
  - Pas d’écran « Produit introuvable » pour un id valide.
  - Contenu cohérent avec les données API.

---

### TS-MVP-06 — Ajout au panier (ligne locale + sync serveur)

- **But** : Ajouter une ligne au panier depuis la fiche produit (M3).
- **Préconditions** : Utilisateur **connecté** si le flux l’exige ; sinon suivre le comportement réel de l’app.
- **Étapes** :
  1. Sur fiche produit, choisir options nécessaires (date / heure de livraison si l’UI l’impose pour commander).
  2. Action **Ajouter au panier** (libellé équivalent).
  3. Ouvrir `/cart`.
- **Résultats attendus** :
  - Le panier n’est pas vide ; article attendu visible.
  - Quantité / prix affichés de façon cohérente.

---

### TS-MVP-07 — Panier : garde connexion

- **But** : Rappel MVP — commande réservée aux connectés (M3).
- **Préconditions** : Session **non** connectée ; panier avec au moins un article (si possible sans login, sinon adapter).
- **Étapes** :
  1. Avec panier non vide, lancer le flux **Commander** depuis le panier.
- **Résultats attendus** :
  - Message du type « Veuillez vous connecter pour commander » **ou** redirection vers `/login` avec intention de retour vers paiement (ex. `returnRoute: '/payment'`).

---

### TS-MVP-08 — Panier → Paiement (écran récap / moyens)

- **But** : Atteindre l’écran de validation sans Stripe (M3).
- **Préconditions** : Utilisateur connecté ; panier non vide ; sync serveur OK (le panier appelle `syncToServer` avant navigation vers `/payment`).
- **Étapes** :
  1. Depuis `/cart`, action commander (bouton principal).
  2. Vérifier présence sur **PaymentScreen** : récap commande, choix de moyen (carte / GPay / Apple Pay en liste).
- **Résultats attendus** :
  - Route `/payment` affichée (pas de boucle login).
  - Bouton principal du type **« Confirmer et payer »** visible et activable si panier non vide.

---

### TS-MVP-09 — Validation commande (checkout API order-service uniquement)

- **But** : **Critère de fin MVP** sans Stripe — commande créée côté backend et feedback UI (M3).
- **Préconditions** : TS-MVP-08 ; utilisateur avec adresse complète **ou** acceptation des défauts minimalistes de l’app.
- **Étapes** :
  1. Sur `/payment`, **sans** remplir de formulaire carte ni appeler Stripe, appuyer sur **« Confirmer et payer »**.
  2. Attendre la fin du traitement (plus de « Traitement en cours... »).
- **Résultats attendus** :
  - SnackBar ou équivalent **succès** mentionnant une **commande confirmée**, un **numéro de commande**, un **statut**, un **montant**.
  - Navigation vers **`/payment/confirmation`** avec informations de commande (après court délai dans l’implémentation actuelle).
  - Panier vidé côté client après succès.
- **Échec** : SnackBar rouge / exception ; dans ce cas capturer le corps de réponse API (order-service) pour diagnostic.

---

### TS-MVP-10 — Liste et détail des commandes

- **But** : Vérifier la consultation post-achat (M3).
- **Préconditions** : Au moins une commande créée (TS-MVP-09).
- **Étapes** :
  1. Naviguer vers l’écran **Mes commandes** (menu / toolbar selon UI).
  2. Ouvrir le détail d’une commande récente.
- **Résultats attendus** :
  - La commande créée apparaît avec identifiant / statut cohérents.
  - Pas d’erreur réseau non gérée.

---

## 5. Suite optionnelle (MVP étendu — hors Stripe)

À exécuter **après** le socle TS-MVP-01 … 10 si le périmètre MVP produit l’inclut :

| ID | Thème | Description courte |
|----|--------|-------------------|
| TS-MVP-11 | Profil | Mise à jour profil / adresse (`user`) pour fiabiliser l’adresse de livraison au checkout. |
| TS-MVP-12 | Déconnexion | Login → logout → accès `/payment` impossible sans re-login. |
| TS-MVP-13 | Baker | Navigation `/baker` depuis un produit ; fiche pâtissier charge (M5). |
| TS-MVP-14 | Favoris | Ajout / retrait favori depuis fiche produit ou liste ; `/favorites`. |

---

## 6. Synthèse pour génération de tests (prompt court)

> En tant que TestSprite, génère des tests E2E pour l’app Flutter Patisry sur les IDs **TS-MVP-01 à TS-MVP-10**. Exclure Stripe, Apple Pay, Google Pay et payment-service. Le point de validation maximal est **TS-MVP-09** : bouton « Confirmer et payer » sur `/payment` doit créer une commande via l’order-service et afficher la confirmation. Utiliser les routes documentées dans la section 3.

---

## 7. Documents liés

- Vue PO / MVP : [`16_Vue_PO_Fonctionnalites_et_Phasage.md`](16_Vue_PO_Fonctionnalites_et_Phasage.md)  
- Brief dev : [`17_Agent_Dev_Etat_et_Objectifs.md`](17_Agent_Dev_Etat_et_Objectifs.md)  
- Contrat API commande / panier : [`07_Order_Service.md`](07_Order_Service.md)  
- Auth : [`01_Auth_Service.md`](01_Auth_Service.md)  
- Display : [`03_Display_Service.md`](03_Display_Service.md)

---

*Document 18 — Patisry / TestSprite — MVP frontend sans Stripe.*
