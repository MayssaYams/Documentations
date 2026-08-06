# Inventaire des APIs Existantes - Patisry Backend

## Vue d'ensemble

Ce document présente l'inventaire complet des APIs existantes dans le backend Patisry, organisées par service microservice. Chaque service expose des endpoints REST pour différentes fonctionnalités.

## Architecture des Services

Le backend utilise une architecture microservices avec les services suivants :

- **auth-service** (Port 8000) - Authentification et autorisation
- **user-service** (Port 8001) - Gestion des utilisateurs
- **product-service** (Port 8002) - Gestion des produits
- **display-service** (Port 8003) - Affichage et recherche de produits
- **review-service** (Port 8006) - Gestion des avis
- **message-service** (Port 8004) - Messages et conversations
- **notification-service** (Port 8005) - Notifications
- **order-service** (Port 8007) - Gestion des commandes

---

## 1. Auth Service (Port 8000)

**Base URL**: `http://localhost:8000/api/auth/`

### Endpoints d'Authentification

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| POST | `/register/` | Inscription d'un utilisateur | `accounts_user` |
| POST | `/login/` | Connexion d'un utilisateur | `accounts_user` |
| POST | `/token/refresh/` | Rafraîchissement du token JWT | `accounts_user` |
| POST | `/password-reset/request/` | Demande de réinitialisation de mot de passe | `accounts_user`, `password_reset_codes` |
| POST | `/password-reset/verify/` | Vérification du code de réinitialisation | `password_reset_codes` |
| POST | `/password-reset/reset/` | Réinitialisation du mot de passe | `accounts_user`, `password_reset_codes` |

### Détails des Endpoints

#### POST `/register/`
- **Description**: Création d'un nouveau compte utilisateur
- **Body**: 
  ```json
  {
    "email": "user@example.com",
    "password": "password123",
    "first_name": "John",
    "last_name": "Doe",
    "phone_number": "+33123456789"
  }
  ```
- **Response**: `{"message": "Utilisateur créé avec succès."}`
- **Tables**: `accounts_user`

#### POST `/login/`
- **Description**: Authentification d'un utilisateur
- **Body**: 
  ```json
  {
    "email": "user@example.com",
    "password": "password123"
  }
  ```
- **Response**: 
  ```json
  {
    "user": {...},
    "refresh": "refresh_token",
    "access": "access_token"
  }
  ```
- **Tables**: `accounts_user`

---

## 2. User Service (Port 8001)

**Base URL**: `http://localhost:8001/api/users/`

### Endpoints de Gestion des Utilisateurs

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/me/` | Profil de l'utilisateur connecté | `accounts_user` |
| GET | `/` | Liste des utilisateurs | `accounts_user` |
| GET | `/{id}/` | Détails d'un utilisateur | `accounts_user` |
| POST | `/` | Création d'un utilisateur | `accounts_user` |
| PUT | `/{id}/` | Mise à jour d'un utilisateur | `accounts_user` |
| DELETE | `/{id}/` | Suppression d'un utilisateur | `accounts_user` |

### Détails des Endpoints

#### GET `/me/`
- **Description**: Récupération du profil de l'utilisateur connecté
- **Headers**: `Authorization: Bearer <access_token>`
- **Response**: 
  ```json
  {
    "id": 1,
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "phone_number": "+33123456789",
    "date_joined": "2024-01-01T00:00:00Z",
    "last_login": "2024-01-15T10:30:00Z"
  }
  ```
- **Tables**: `accounts_user`

---

## 3. Product Service (Port 8002)

**Base URL**: `http://localhost:8002/api/products/`

### Endpoints de Gestion des Produits

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/` | Liste des produits | `product`, `product_image`, `baker` |
| GET | `/{id}/` | Détails d'un produit | `product`, `product_image`, `product_variant`, `product_allergen` |
| POST | `/` | Création d'un produit | `product` |
| PUT | `/{id}/` | Mise à jour d'un produit | `product` |
| DELETE | `/{id}/` | Suppression d'un produit | `product` |
| POST | `/variants/` | Création de variantes | `product_variant` |
| PUT | `/{id}/variants/` | Mise à jour des variantes | `product_variant` |
| POST | `/categories/` | Création de catégories | `category` |
| PUT | `/{id}/categories/` | Mise à jour des catégories | `product_category` |
| POST | `/images/` | Création d'images | `product_image` |
| PUT | `/{id}/images/` | Mise à jour des images | `product_image` |
| POST | `/allergens/` | Création d'allergènes | `allergen` |
| PUT | `/{id}/allergens/` | Mise à jour des allergènes | `product_allergen` |
| POST | `/quantity-rules/` | Création de règles de quantité | `product_quantity_rule` |
| PUT | `/{id}/quantity-rules/` | Mise à jour des règles de quantité | `product_quantity_rule` |
| GET | `/{id}/history/` | Historique d'un produit | `product_history` |
| POST | `/full_product/` | Création d'un produit complet | `product`, `product_variant`, `product_image`, `product_allergen` |
| GET | `/{id}/full_product/` | Récupération d'un produit complet | `product`, `product_variant`, `product_image`, `product_allergen` |

### Détails des Endpoints

#### GET `/`
- **Description**: Liste tous les produits avec pagination
- **Query Parameters**: 
  - `page`: Numéro de page
  - `page_size`: Taille de page
  - `search`: Recherche textuelle
  - `category`: Filtre par catégorie
  - `baker_id`: Filtre par pâtissier
- **Response**: 
  ```json
  {
    "count": 100,
    "next": "http://localhost:8002/api/products/?page=2",
    "previous": null,
    "results": [
      {
        "id": 1,
        "name": "Gâteau au chocolat",
        "price": 25.50,
        "description": "Délicieux gâteau au chocolat",
        "baker": {
          "id": 1,
          "name": "Marie Dupont"
        },
        "images": [
          {
            "id": 1,
            "imageurl": "https://example.com/image1.jpg",
            "format": "jpg"
          }
        ]
      }
    ]
  }
  ```
- **Tables**: `product`, `product_image`, `baker`, `accounts_user`

#### POST `/full_product/`
- **Description**: Création d'un produit avec toutes ses relations
- **Body**: 
  ```json
  {
    "name": "Gâteau au chocolat",
    "price": 25.50,
    "description": "Délicieux gâteau au chocolat",
    "baker_id": 1,
    "variants": [
      {
        "name": "Petit",
        "price": 20.00,
        "ingredients": "Chocolat, farine, œufs"
      }
    ],
    "images": [
      {
        "imageurl": "https://example.com/image1.jpg",
        "format": "jpg"
      }
    ],
    "allergens": [1, 2],
    "categories": [1, 3]
  }
  ```
- **Tables**: `product`, `product_variant`, `product_image`, `product_allergen`, `product_category`

---

## 4. Display Service (Port 8003)

**Base URL**: `http://localhost:8003/api/display/`

### Endpoints d'Affichage et Recherche

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/products/home/payload/` | Payload accueil (produits, favoris, filtres, distance optionnelle) | `product`, `baker`, `baker_location`, `product_image`, `product_categories`, `user_favoris` |
| GET | `/products/{id}/full/` | Détail complet d'un produit avec baker et coordonnées | `product`, `baker`, `baker_location`, `product_image`, `product_variant`, … |
| POST | `/products/nearby/nolat/` | Produits par proximité (coordonnées fournies) | `product`, `baker`, `baker_location` |
| POST | `/products/nearby/connected/` | Produits par proximité (utilisateur connecté) | `product`, `baker`, `baker_location`, `accounts_user` |

### Détails des Endpoints

#### GET `/products/home/payload/`
- **Description**: Payload complet de l'écran d'accueil. Optionnellement calcule la distance baker→utilisateur.
- **Query params**:
  - `page` (int, défaut 1)
  - `page_size` (int, défaut 12, max 50)
  - `lat` (float, optionnel) — latitude utilisateur
  - `lon` (float, optionnel) — longitude utilisateur
- **Response** (200):
  ```json
  {
    "success": true,
    "data": {
      "page": 1, "page_size": 12, "has_more": false, "next_page": null, "total_count": 1,
      "products": [
        {
          "id": 1, "name": "Gâteau royal", "price": 12.5,
          "distance_km": 2.3,
          "baker": {
            "id": 10, "business_name": "Les Délices",
            "latitude": 48.8566, "longitude": 2.3522, "address_label": "Paris 1er, France"
          },
          "images": [...], "categories": [...], "isFavorite": false
        }
      ],
      "favorites": [...],
      "filters": { "categories": [...] }
    }
  }
  ```
- **Notes**: `distance_km` est `null` si `lat`/`lon` absents ou si le baker n'a pas de `baker_location`.
- **Tables**: `product`, `baker`, `baker_location`, `product_image`, `product_categories`, `product_category_relations`, `user_favoris`

#### GET `/products/{id}/full/`
- **Description**: Détail complet d'un produit incluant coordonnées du pâtissier.
- **Response** (200): objet avec `product`, `baker` (avec `latitude`, `longitude`, `address_label`), `review`, `favorite`.
- **Tables**: `product`, `baker`, `baker_location`, `product_image`, `product_variant`, `product_category_relations`, `product_categories`, `product_allergen`, `allergen`, `product_tag_relations`, `product_tags`, `user_favoris`, `product_reviews`, `accounts_user`

#### POST `/products/nearby/nolat/`
- **Description**: Produits triés par distance depuis un point donné. Distance calculée via `baker_location`. Les produits dont le baker n'a pas de `baker_location` sont exclus.
- **Body**: 
  ```json
  { "lat": 48.8566, "lon": 2.3522, "distance": 10 }
  ```
- **Response** (200):
  ```json
  {
    "success": true, "count": 1,
    "data": [
      {
        "product_id": 1, "product_name": "Gâteau royal", "baker_name": "Les Délices",
        "baker_latitude": 48.8566, "baker_longitude": 2.3522,
        "baker_address_label": "Paris 1er, France", "distance_km": 2.3
      }
    ]
  }
  ```
- **Tables**: `product`, `baker`, `baker_location`

#### POST `/products/nearby/connected/`
- **Description**: Utilise la localisation PostGIS de l'utilisateur connecté ; distance calculée via `baker_location`. Exclut les produits dont le baker n'a pas de `baker_location`.
- **Headers**: `Authorization: Bearer <access_token>`
- **Body**: `{ "distance": 10 }`
- **Response** (200): même structure que `nearby/nolat`
- **Tables**: `product`, `baker`, `baker_location`, `accounts_user`

---

## 5. Review Service (Port 8006)

**Base URL**: `http://localhost:8006/api/reviews/`

### Endpoints de Gestion des Avis

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/` | Liste des avis | `baker_review`, `product_reviews` |
| GET | `/{id}/` | Détails d'un avis | `baker_review`, `product_reviews` |
| POST | `/` | Création d'un avis | `baker_review`, `product_reviews` |
| PUT | `/{id}/` | Mise à jour d'un avis | `baker_review`, `product_reviews` |
| DELETE | `/{id}/` | Suppression d'un avis | `baker_review`, `product_reviews` |
| GET | `/baker/{baker_id}/` | Avis d'un pâtissier | `baker_review` |
| GET | `/product/{product_id}/` | Avis d'un produit | `product_reviews` |

### Détails des Endpoints

#### GET `/baker/{baker_id}/`
- **Description**: Récupère tous les avis d'un pâtissier
- **Response**: 
  ```json
  {
    "baker_id": 1,
    "average_rating": 4.3,
    "total_reviews": 25,
    "reviews": [
      {
        "id": 1,
        "rating": 5,
        "comment": "Excellent gâteau !",
        "user": {
          "first_name": "John",
          "last_name": "Doe"
        },
        "created_at": "2024-01-15T10:30:00Z"
      }
    ]
  }
  ```
- **Tables**: `baker_review`, `accounts_user`

---

## Services Manquants (À Développer)

### 6. Message Service (Port 8004)
- **Fonctionnalités**: Conversations, messages, notifications en temps réel
- **Tables**: `conversations`, `messages`, `conversation_participants`, `message_attachments`

### 7. Notification Service (Port 8005)
- **Fonctionnalités**: Notifications push, email, SMS
- **Tables**: `user_notifications`, `notification_templates`, `notification_preferences`

### 8. Order Service (Port 8007)
- **Fonctionnalités**: Gestion des commandes, panier, livraison
- **Tables**: `orders`, `order_detail`, `cart`, `cart_items`, `shipping_address`

---

## Authentification et Autorisation

### JWT Tokens
- **Access Token**: Durée de vie de 12 heures
- **Refresh Token**: Durée de vie de 1 jour
- **Format**: `Authorization: Bearer <access_token>`

### Rôles et Permissions
- **User**: Utilisateur standard
- **Baker**: Pâtissier
- **Admin**: Administrateur
- **Staff**: Personnel

---

## Codes de Statut HTTP

| Code | Description | Utilisation |
|------|-------------|-------------|
| 200 | OK | Requête réussie |
| 201 | Created | Ressource créée |
| 400 | Bad Request | Données invalides |
| 401 | Unauthorized | Token manquant ou invalide |
| 403 | Forbidden | Permissions insuffisantes |
| 404 | Not Found | Ressource non trouvée |
| 500 | Internal Server Error | Erreur serveur |

---

## Limitations et Notes

1. **Pagination**: Tous les endpoints de liste utilisent une pagination par défaut (20 éléments par page)
2. **Rate Limiting**: Limitation à 1000 requêtes par heure par utilisateur
3. **Validation**: Toutes les données sont validées côté serveur
4. **Logs**: Tous les appels API sont loggés pour le monitoring
5. **CORS**: Configuration CORS pour le frontend Flutter

---

## Prochaines Étapes

1. **Développement des services manquants** (Message, Notification, Order)
2. **Implémentation du tracking utilisateur** avec les nouvelles tables
3. **Ajout des endpoints d'analytics** pour les KPIs
4. **Intégration des webhooks** pour les notifications temps réel
5. **Documentation OpenAPI/Swagger** complète
