# Brief agent développement — État du système et objectifs prioritaires

**Public** : agent ou développeur **backend** (microservices Django) ou **frontend** (Flutter / Patisry).  
**Objectif** : situer le projet techniquement, savoir quoi lire en premier, et quelles sont les **prochaines cibles** alignées avec le phasage PO ([`16_Vue_PO_Fonctionnalites_et_Phasage.md`](16_Vue_PO_Fonctionnalites_et_Phasage.md)).

**Position actuelle (synthèse)** : fin de **MVP** / entrée en **bêta fermée** — le cœur parcours (auth, catalogue display, panier, commandes, baker, favoris, recherche, messages, avis) est en grande partie présent côté API et app. Le parcours commande E2E client + visibilité pâtissier + machine d'états est désormais implémenté (**G0** ✅). Il reste à fermer le MVP (paiement test E2E) puis à durcir la bêta fermée.

---

## 1. Cartographie rapide

| Zone | Emplacement indicatif | Rappel |
|------|------------------------|--------|
| App Flutter | `Patisry/lib/` — `features/*`, `core/config/app_config.dart`, `core/network/` | URLs des services : `Environment.local` / `freebox` |
| Microservices | Un repo par service sous `Backend/*-service` | Vérité terrain des routes : `core/urls.py`, `*/urls.py`, ViewSets |
| Doc API fonctionnelle | Ce dossier : `00_` … `15_*.md` | Contrat attendu ; en cas de doute, le **code** prime |
| Vue PO / jalons | [`16_Vue_PO_Fonctionnalites_et_Phasage.md`](16_Vue_PO_Fonctionnalites_et_Phasage.md) | Tableau domaine × API × app, MVP / bêtas / V1 |

**Ports** : [`00_Guide_Commun.md`](00_Guide_Commun.md) et [`README.md`](README.md) (local + Freebox).

---

## 2. Où on en est — par rôle

### 2.1 Backend

- **Exposé et documenté** : 15 services avec schémas REST (fichiers `01_`–`15_`). Une passe de réconciliation a mis à jour notamment Display (`home/payload`, `full`), User (PATCH profil / adresse / statut + note sur `GET /users/`), Favoris (DELETE by-product, retrait item groupe), Baker (`userid/{user_id}`), Subscription (`unsubscribe`), Product (exemple pagination), Guide commun (cible vs implémentation).
- **Commandes (G0 ✅)** : `order-service` mis à jour — checkout enregistre `baker_id`, machine d'états complète (`pending_confirmation` → `in_preparation` → `ready` → `out_for_delivery` → `delivered` → `completed`), endpoint `GET /orders/?scope=received` pour le pâtissier, contrôle de rôle (baker ne peut pas passer à `completed`).
- **Dette / risque connu** : **`user-service`** — `GET /api/users/` accessible à tout utilisateur authentifié sans garde admin/staff (à corriger si exigence sécurité bêta fermée **B5**).
- **Cohérence erreurs / rate limit** : non harmonisée partout ; ne pas supposer le JSON du `00_Guide_Commun` partout sans tester le service concerné.

### 2.2 Frontend (Flutter)

- **Clients API** : `lib/features/*/data/datasources/*_api.dart` (auth, user, display, product, order, payment, favorite, baker, search, message, review, subscription, analytics).
- **Commandes (G0 ✅)** : `OrderStatus` étendu aux 7 statuts, `OrdersService.getReceivedOrders` utilise désormais le filtre serveur (`?scope=received`), `order_display_service` traduit tous les statuts en français. Fiche produit : popup post-ajout, chargement avec spinner + timeout 5 s + états `loadError` / `notFound`.
- **Manque notable** : **pas de `notification_api.dart`** (ou équivalent) — le service notification existe côté backend mais l'app ne consomme pas l'API dans l'inventaire actuel → objectif **O1** bêta ouverte.
  > **TODO push** : connecter push notification / WebSocket pour actualiser automatiquement l'onglet commandes pâtissier. En attendant, un pull-to-refresh suffit.
- **Paiement** : plusieurs écrans (cartes, Apple/Google/PayPal, etc.) — valider **un** flux Stripe test **de bout en bout** avec l'order-service / payment-service (**M4**).
- **Parcours baker** : `pastry`, `baker`, `dashboard` — finaliser édition produit / TODOs métier si présents dans le repo.

---

## 3. Objectifs prioritaires (ordre suggéré)

Numérotation partagée : un agent peut prendre **un numéro** comme ticket / epic. Les tags **BE** / **FE** indiquent le pilote principal ; certains items sont mixtes.

| # | Objectif | BE | FE | Rationale (lien phasage 16) |
|---|----------|----|----|------------------------------|
| **G0** ✅ | **Commande E2E — visibilité pâtissier + machine d'états** | `order-service` : `baker_id` au checkout, validation mono-pâtissier, `pending_confirmation` initial, list/retrieve/status avec machine d'états et contrôle de rôle | Flutter : `OrderStatus` étendu, `getReceivedOrders` via `?scope=received`, popup post-ajout panier, chargement produit avec états `loading / loadError / notFound` | Fermer **M3** + débloquer baker bêta |
| **G1** | **Paiement test E2E** : commande → intent / confirmation → statut commande cohérent | Ajuster webhooks, idempotence, erreurs payment si besoin | Enchaîner écrans + `payment_api` / `order_api`, gérer états UI | Fermer **M4** |
| **G2** | **Sécuriser `GET /api/users/`** (admin/staff ou suppression de la liste publique) | `user-service` : permissions + tests | Vérifier qu'aucun écran ne dépend d'une liste globale abusive | **B5** |
| **G3** | **Stabiliser messagerie** : création conversation, envoi, lecture, marquer lu | Vérifier contrats UUID, 403, pagination si ajoutée | `message_api` + `messages_screen` / `conversation_screen` | **B2** |
| **G4** | **Recherche "bêta fermée"** : suggestions / trending / filtres réellement utilisés dans l'UI | Déjà exposé (`api/search/...`) | Brancher ou compléter les écrans de recherche | **B4** |
| **G5** | **Notifications in-app (minimum viable)** | Inchangé si API OK | Nouveau datasource + écran ou section + refresh token | **O1** |
| **G6** | **Analytics parcours** : events sur écrans clés (home, produit, panier, checkout) | Optionnel : valider charge | Appeler `analytics_api` / sessions depuis les routes concernées | **O2** |
| **G7** | **Baker / produit** : parcours édition "basique" sans TODO bloquant | Valider droits baker sur product-service | `edit_pastry` / product flows | **M5** |
| **G8** | **Avis** : affichage + création selon règle métier (ex. après commande livrée) | Endpoints review + order si règle serveur | UX création avis + garde-fous | **B3** |
| **G9** | **Abonnements** : parcours souscription / annulation clair | Déjà documenté (`subscribe`, `cancel`, `unsubscribe`, etc.) | `subscription_screen` + états vides / erreurs | **O3** |
| **G10** | **Doc <> code** : après chaque gros changement de routes, mettre à jour le `0X_*` correspondant | Oui | N/A (si changement uniquement app, noter dans 16 si pertinent) | Hygiène continue |

**Prochain objectif global recommandé** : **G0 ✅ terminé** → enchaîner **G1** puis **G2** (paiement test bout-en-bout + sécurité minimum avant d'élargir les testeurs).

### Checklist de validation — G0 (commande E2E)

- [ ] Client crée une commande depuis l'app → `orders.baker_id` est renseigné en base.
- [ ] Toutes les lignes du panier appartiennent au même pâtissier (retour `400` sinon).
- [ ] La commande apparaît chez le pâtissier via `GET /api/orders/?scope=received` (rechargement manuel ou pull-to-refresh).
- [ ] Machine d'états : transitions illégales refusées avec `400` (ex. `ready → completed` par le baker, `pending_confirmation → completed` par le client).
- [ ] Le client ne peut passer à `completed` que depuis `delivered`.
- [ ] La fiche produit n'ajoute pas au panier à la sélection de l'heure — uniquement sur le bouton.
- [ ] Popup post-ajout panier : "Aller au panier" / "Continuer mes achats" s'affiche.
- [ ] Chargement produit : spinner → timeout 5 s → message d'erreur + bouton réessayer (le message "produit inexistant" n'apparaît que sur réponse 404 du backend).

---

## 4. Checklist à l'onboarding d'un agent

1. Lire [`16_Vue_PO_Fonctionnalites_et_Phasage.md`](16_Vue_PO_Fonctionnalites_et_Phasage.md) (sections 1, 3, 5).
2. Ouvrir le fichier service concerné dans `01_`–`15_` + le `urls.py` / ViewSet du repo `Backend/<service>-service`.
3. Côté app : `AppConfig` + le `*_api.dart` du domaine + l'écran dans `lib/features/<domaine>/`.
4. Lancer les tests du service (`pytest`, `integration_tests.py`, etc. selon le repo) après toute modification d'API.
5. Ne pas modifier ce document pour du détail de ticket : utiliser l'outil de suivi interne ; mettre à jour **16** ou **17** seulement si le **périmètre produit** ou les **jalons** changent.

---

## 5. Références croisées

| Besoin | Fichier |
|--------|---------|
| Contrat HTTP par service | `01_` … `15_` |
| Conventions transverses (JWT, pagination cible, ports) | [`00_Guide_Commun.md`](00_Guide_Commun.md) |
| Vision PO et tableau maturité | [`16_Vue_PO_Fonctionnalites_et_Phasage.md`](16_Vue_PO_Fonctionnalites_et_Phasage.md) |
| Index des docs | [`README.md`](README.md) |

---

*Document 17 — à maintenir lors des changements de priorités ou après chaque release majeure.*
