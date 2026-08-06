# Mapping Frontend Screens → APIs → Tables

## Vue d'ensemble

Ce document établit la correspondance entre les écrans du frontend Flutter, les APIs du backend et les tables de la base de données PostgreSQL. Chaque écran est analysé pour identifier les données affichées et leur origine.

---

## 1. Écrans d'Authentification

### 1.1 Écran de Connexion (`LoginScreen`)

**Frontend**: `lib/features/auth/presentation/login_screen.dart`

**Données affichées**:
- Formulaire de connexion (email, mot de passe)
- Bouton de connexion
- Lien vers l'inscription
- Lien "Mot de passe oublié"

**APIs utilisées**:
- `POST /api/auth/login/` - Connexion utilisateur
- `POST /api/auth/password-reset/request/` - Demande de réinitialisation

**Tables sources**:
- `accounts_user` - Vérification des identifiants
- `password_reset_codes` - Génération du code de réinitialisation

**Flux de données**:
```
LoginScreen → POST /api/auth/login/ → accounts_user → AuthTokens
```

### 1.2 Écran d'Inscription (`RegisterScreen`)

**Frontend**: `lib/features/auth/presentation/register_screen.dart`

**Données affichées**:
- Formulaire d'inscription (email, mot de passe, prénom, nom, téléphone)
- Validation des champs
- Bouton d'inscription

**APIs utilisées**:
- `POST /api/auth/register/` - Création d'un compte

**Tables sources**:
- `accounts_user` - Création du nouvel utilisateur

**Flux de données**:
```
RegisterScreen → POST /api/auth/register/ → accounts_user → UserInfoModel
```

### 1.3 Écran de Réinitialisation de Mot de Passe

**Frontend**: `lib/features/auth/presentation/forgot_password_screen.dart`

**Données affichées**:
- Formulaire de demande de réinitialisation
- Champ de vérification du code
- Formulaire de nouveau mot de passe

**APIs utilisées**:
- `POST /api/auth/password-reset/request/` - Demande de code
- `POST /api/auth/password-reset/verify/` - Vérification du code
- `POST /api/auth/password-reset/reset/` - Réinitialisation

**Tables sources**:
- `accounts_user` - Vérification de l'utilisateur
- `password_reset_codes` - Stockage et validation du code

---

## 2. Écrans Principaux

### 2.1 Écran d'Accueil (`HomeScreen`)

**Frontend**: `lib/features/home/presentation/home_screen.dart`

**Données affichées**:
- Liste des produits populaires
- Catégories de produits
- Pâtissiers recommandés
- Barre de recherche
- Notifications

**APIs utilisées**:
- `GET /api/display/products/home/payload/` - Payload écran accueil (produits, favoris, filtres, distance optionnelle)
- `GET /api/display/products/home/payload/?lat=&lon=` - Idem avec calcul de distance baker
- `GET /api/users/me/` - Profil utilisateur

**Tables sources**:
- `product` - Produits affichés
- `product_image` - Images des produits
- `baker` - Informations des pâtissiers
- `baker_location` - Coordonnées GPS des pâtissiers (distance, carte)
- `accounts_user` - Localisation de l'utilisateur
- `user_favoris` - Favoris de l'utilisateur

**Flux de données**:
```
HomeScreen → GET /api/display/products/home/payload/?lat=&lon= → product + baker + baker_location → ProductModel (avec distance_km)
HomeScreen → PastryCard avec distance_km réel depuis baker_location
```

### 2.2 Écran de Recherche (`SearchScreen`)

**Frontend**: `lib/features/search/presentation/search_screen.dart`

**Données affichées**:
- Barre de recherche
- Filtres (prix, distance, catégorie, allergènes)
- Résultats de recherche
- Historique des recherches

**APIs utilisées**:
- `GET /api/products/` - Recherche de produits
- `POST /api/display/products/nearby/connected/` - Produits par proximité

**Tables sources**:
- `product` - Produits correspondants
- `product_image` - Images des produits
- `baker` - Informations des pâtissiers
- `product_allergen` - Filtrage par allergènes
- `product_category` - Filtrage par catégories
- `user_search_history` - Historique des recherches

**Flux de données**:
```
SearchScreen → GET /api/products/?search=query → product + product_image + baker → MockProduct
SearchScreen → user_search_history (local) → POST /api/analytics/search/ → user_search_history
```

### 2.3 Écran de Détails Produit (`ProductDetailScreen`)

**Frontend**: `lib/features/products/presentation/product_detail_screen.dart`

**Données affichées**:
- Images du produit
- Nom et description
- Prix et variantes
- Informations du pâtissier
- Avis et notes
- Boutons d'action (favoris, panier, message)

**APIs utilisées**:
- `GET /api/products/{id}/full_product/` - Détails complets du produit
- `GET /api/reviews/product/{id}/` - Avis du produit
- `POST /api/analytics/product-view/` - Tracking de la vue

**Tables sources**:
- `product` - Détails du produit
- `product_image` - Images du produit
- `product_variant` - Variantes disponibles
- `product_allergen` - Allergènes
- `baker` - Informations du pâtissier
- `product_reviews` - Avis des utilisateurs
- `product_views` - Tracking des vues

**Flux de données**:
```
ProductDetailScreen → GET /api/products/{id}/full_product/ → product + product_variant + product_image + baker → ProductModel
ProductDetailScreen → POST /api/analytics/product-view/ → product_views
```

---

## 3. Écrans de Profil

### 3.1 Écran de Profil Utilisateur (`ProfileScreen`)

**Frontend**: `lib/features/profile/presentation/profile_screen.dart`

**Données affichées**:
- Informations personnelles
- Historique des commandes
- Favoris
- Paramètres de notification
- Statistiques d'utilisation

**APIs utilisées**:
- `GET /api/users/me/` - Profil utilisateur
- `GET /api/orders/user/` - Commandes de l'utilisateur
- `GET /api/favorites/user/` - Favoris de l'utilisateur
- `GET /api/analytics/user/` - Statistiques utilisateur

**Tables sources**:
- `accounts_user` - Informations personnelles
- `user_preferences` - Préférences utilisateur
- `orders` - Historique des commandes
- `user_favoris` - Produits favoris
- `favorite_groups` - Groupes de favoris
- `user_analytics_daily` - Statistiques quotidiennes

**Flux de données**:
```
ProfileScreen → GET /api/users/me/ → accounts_user + user_preferences → UserInfoModel
ProfileScreen → GET /api/orders/user/ → orders + order_detail → Order
ProfileScreen → GET /api/favorites/user/ → user_favoris + favorite_groups → FavoriteItem
```

### 3.2 Écran de Profil Pâtissier (`BakerProfileScreen`)

**Frontend**: `lib/features/baker/presentation/baker_profile_screen.dart`

**Données affichées**:
- Informations du pâtissier
- Spécialités et certifications
- Horaires de travail
- Produits proposés
- Avis et notes
- Statistiques de vente

**APIs utilisées**:
- `GET /api/bakers/{id}/` - Profil pâtissier
- `GET /api/products/baker/{id}/` - Produits du pâtissier
- `GET /api/reviews/baker/{id}/` - Avis du pâtissier
- `GET /api/analytics/baker/{id}/` - Statistiques pâtissier

**Tables sources**:
- `baker` - Informations du pâtissier
- `baker_specialties` - Spécialités
- `baker_certifications` - Certifications
- `baker_working_hours` - Horaires
- `baker_languages` - Langues parlées
- `product` - Produits proposés
- `baker_review` - Avis des clients
- `baker_analytics_daily` - Statistiques quotidiennes

**Flux de données**:
```
BakerProfileScreen → GET /api/bakers/{id}/ → baker + baker_specialties + baker_certifications → BakerModel
BakerProfileScreen → GET /api/products/baker/{id}/ → product + product_image → MockProduct
```

---

## 4. Écrans de Commande

### 4.1 Écran du Panier (`CartScreen`)

**Frontend**: `lib/features/cart/presentation/cart_screen.dart`

**Données affichées**:
- Articles du panier
- Quantités et prix
- Options de personnalisation
- Dates de livraison
- Adresses de livraison
- Total et frais

**APIs utilisées**:
- `GET /api/cart/` - Contenu du panier
- `PUT /api/cart/items/{id}/` - Modification d'un article
- `DELETE /api/cart/items/{id}/` - Suppression d'un article
- `GET /api/shipping-addresses/` - Adresses de livraison

**Tables sources**:
- `cart` - Panier de l'utilisateur
- `cart_items` - Articles du panier
- `product` - Détails des produits
- `product_variant` - Variantes sélectionnées
- `shipping_address` - Adresses de livraison

**Flux de données**:
```
CartScreen → GET /api/cart/ → cart + cart_items + product → CartItem
CartScreen → PUT /api/cart/items/{id}/ → cart_items
```

### 4.2 Écran de Commande (`OrderScreen`)

**Frontend**: `lib/features/orders/presentation/order_screen.dart`

**Données affichées**:
- Récapitulatif de la commande
- Informations de livraison
- Méthodes de paiement
- Codes promotionnels
- Confirmation de commande

**APIs utilisées**:
- `POST /api/orders/` - Création de commande
- `GET /api/payment-methods/` - Méthodes de paiement
- `POST /api/promotions/validate/` - Validation de promotion
- `POST /api/payments/` - Traitement du paiement

**Tables sources**:
- `orders` - Nouvelle commande
- `order_detail` - Détails de la commande
- `payment_method` - Méthodes de paiement
- `promotion` - Codes promotionnels
- `payments` - Transaction de paiement
- `shipping_address` - Adresse de livraison

**Flux de données**:
```
OrderScreen → POST /api/orders/ → orders + order_detail → Order
OrderScreen → POST /api/payments/ → payments + payment_transactions
```

### 4.3 Écran de Suivi de Commande (`OrderTrackingScreen`)

**Frontend**: `lib/features/orders/presentation/order_tracking_screen.dart`

**Données affichées**:
- Statut de la commande
- Historique des statuts
- Informations de livraison
- Contact du pâtissier
- Estimation de livraison

**APIs utilisées**:
- `GET /api/orders/{id}/` - Détails de la commande
- `GET /api/orders/{id}/tracking/` - Suivi de livraison
- `GET /api/orders/{id}/status-history/` - Historique des statuts

**Tables sources**:
- `orders` - Détails de la commande
- `order_status_history` - Historique des statuts
- `order_tracking` - Suivi de livraison
- `baker` - Contact du pâtissier

---

## 5. Écrans de Messages

### 5.1 Écran de Conversations (`ConversationsScreen`)

**Frontend**: `lib/features/messages/presentation/conversations_screen.dart`

**Données affichées**:
- Liste des conversations
- Derniers messages
- Nombre de messages non lus
- Statut en ligne des contacts

**APIs utilisées**:
- `GET /api/conversations/` - Liste des conversations
- `GET /api/messages/unread-count/` - Nombre de messages non lus

**Tables sources**:
- `conversations` - Conversations de l'utilisateur
- `conversation_participants` - Participants aux conversations
- `messages` - Derniers messages
- `accounts_user` - Informations des contacts

**Flux de données**:
```
ConversationsScreen → GET /api/conversations/ → conversations + conversation_participants + messages → Conversation
```

### 5.2 Écran de Chat (`ChatScreen`)

**Frontend**: `lib/features/messages/presentation/chat_screen.dart`

**Données affichées**:
- Messages de la conversation
- Informations du contact
- Champ de saisie
- Statuts de livraison
- Pièces jointes

**APIs utilisées**:
- `GET /api/conversations/{id}/messages/` - Messages de la conversation
- `POST /api/messages/` - Envoi d'un message
- `PUT /api/messages/{id}/read/` - Marquer comme lu
- `POST /api/messages/{id}/reactions/` - Réactions aux messages

**Tables sources**:
- `messages` - Messages de la conversation
- `message_attachments` - Pièces jointes
- `message_reactions` - Réactions
- `conversation_participants` - Statut de lecture

**Flux de données**:
```
ChatScreen → GET /api/conversations/{id}/messages/ → messages + message_attachments → Message
ChatScreen → POST /api/messages/ → messages
```

---

## 6. Écrans de Favoris

### 6.1 Écran des Favoris (`FavoritesScreen`)

**Frontend**: `lib/features/favorites/presentation/favorites_screen.dart`

**Données affichées**:
- Liste des produits favoris
- Groupes de favoris
- Options de tri et filtrage
- Actions sur les favoris

**APIs utilisées**:
- `GET /api/favorites/` - Liste des favoris
- `GET /api/favorites/groups/` - Groupes de favoris
- `POST /api/favorites/` - Ajout d'un favori
- `DELETE /api/favorites/{id}/` - Suppression d'un favori

**Tables sources**:
- `user_favoris` - Produits favoris
- `favorite_groups` - Groupes de favoris
- `favorite_group_items` - Articles dans les groupes
- `product` - Détails des produits

**Flux de données**:
```
FavoritesScreen → GET /api/favorites/ → user_favoris + product → FavoriteItem
FavoritesScreen → GET /api/favorites/groups/ → favorite_groups + favorite_group_items → FavoriteGroup
```

---

## 7. Écrans d'Analytics (Pâtissiers)

### 7.1 Dashboard Pâtissier (`BakerDashboardScreen`)

**Frontend**: `lib/features/baker/presentation/baker_dashboard_screen.dart`

**Données affichées**:
- Statistiques de vente
- Graphiques de revenus
- Nombre de commandes
- Avis et notes
- Produits populaires

**APIs utilisées**:
- `GET /api/analytics/baker/dashboard/` - Données du dashboard
- `GET /api/analytics/baker/revenue/` - Statistiques de revenus
- `GET /api/analytics/baker/orders/` - Statistiques de commandes

**Tables sources**:
- `baker_analytics_daily` - Analytics quotidiennes
- `orders` - Commandes du pâtissier
- `product_analytics_daily` - Analytics des produits
- `baker_review` - Avis des clients

**Flux de données**:
```
BakerDashboardScreen → GET /api/analytics/baker/dashboard/ → baker_analytics_daily + orders → DashboardSeries
```

---

## 8. Écrans d'Administration

### 8.1 Dashboard Admin (`AdminDashboardScreen`)

**Frontend**: `lib/features/admin/presentation/admin_dashboard_screen.dart`

**Données affichées**:
- KPIs globaux
- Statistiques des utilisateurs
- Statistiques des pâtissiers
- Statistiques des commandes
- Graphiques de tendances

**APIs utilisées**:
- `GET /api/admin/kpis/` - KPIs globaux
- `GET /api/admin/users/stats/` - Statistiques utilisateurs
- `GET /api/admin/bakers/stats/` - Statistiques pâtissiers
- `GET /api/admin/orders/stats/` - Statistiques commandes

**Tables sources**:
- `global_kpis` - Vue des KPIs globaux
- `user_analytics_daily` - Analytics utilisateurs
- `baker_analytics_daily` - Analytics pâtissiers
- `order_analytics_daily` - Analytics commandes

---

## 9. Tracking et Analytics

### 9.1 Données de Tracking Collectées

**Écrans concernés**: Tous les écrans

**Données collectées**:
- Pages visitées
- Temps passé sur chaque page
- Actions utilisateur (clics, scrolls)
- Recherches effectuées
- Produits consultés
- Conversions (ajouts au panier, commandes)

**APIs utilisées**:
- `POST /api/analytics/page-view/` - Tracking des pages
- `POST /api/analytics/user-action/` - Tracking des actions
- `POST /api/analytics/search/` - Tracking des recherches

**Tables sources**:
- `user_page_views` - Vues de pages
- `user_actions` - Actions utilisateur
- `user_search_history` - Historique des recherches
- `user_analytics_daily` - Analytics quotidiennes

---

## 10. Résumé des Correspondances

### 10.1 Frontend → Backend
- **Auth**: `auth-service` (Port 8000)
- **Users**: `user-service` (Port 8001)
- **Products**: `product-service` (Port 8002)
- **Display**: `display-service` (Port 8003)
- **Messages**: `message-service` (Port 8004) - À développer
- **Notifications**: `notification-service` (Port 8005) - À développer
- **Reviews**: `review-service` (Port 8006)
- **Orders**: `order-service` (Port 8007) - À développer

### 10.2 Backend → Database
- **Auth Service**: `accounts_user`, `password_reset_codes`
- **User Service**: `accounts_user`, `user_preferences`, `user_analytics_daily`
- **Product Service**: `product`, `product_variant`, `product_image`, `product_allergen`
- **Display Service**: `product`, `baker`, `baker_location`, `accounts_user`, `user_favoris`, `product_image`, `product_categories`
- **Review Service**: `baker_review`, `product_reviews`
- **Message Service**: `conversations`, `messages`, `conversation_participants`
- **Order Service**: `orders`, `order_detail`, `cart`, `cart_items`
- **Analytics**: `user_page_views`, `user_actions`, `user_search_history`

### 10.3 Modèles Frontend → Tables Database
- `UserInfoModel` → `accounts_user`
- `ProductModel` → `product` + `product_variant` + `product_image`
- `BakerModel` → `baker` + `baker_location` + `baker_specialties` + `baker_certifications`
- `Order` → `orders` + `order_detail`
- `Message` → `messages` + `conversation_participants`
- `FavoriteItem` → `user_favoris` + `favorite_groups`
- `CartItem` → `cart_items` + `cart`

---

## 11. Prochaines Étapes

1. **Développement des services manquants** (Message, Notification, Order)
2. **Implémentation du tracking utilisateur** sur tous les écrans
3. **Migration des données mock** vers les vraies APIs
4. **Ajout des endpoints d'analytics** pour les KPIs
5. **Tests d'intégration** frontend-backend-database
