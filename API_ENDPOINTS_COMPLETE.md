# Documentation Complète des Endpoints API - Patisry Backend

## Vue d'ensemble

Ce document fournit une documentation exhaustive de tous les endpoints API du système Patisry, incluant les APIs existantes et futures. Chaque endpoint est documenté avec ses paramètres, réponses, codes d'erreur et tables sources.

---

## Table des Matières

1. [Auth Service](#1-auth-service-port-8000)
2. [User Service](#2-user-service-port-8001)
3. [Product Service](#3-product-service-port-8002)
4. [Display Service](#4-display-service-port-8003)
5. [Message Service](#5-message-service-port-8004-futur)
6. [Notification Service](#6-notification-service-port-8005-futur)
7. [Order Service](#7-order-service-port-8007-futur)
8. [Analytics Service](#8-analytics-service-port-8008-futur)
9. [Favorite Service](#9-favorite-service-port-8009-futur)
10. [Baker Service](#10-baker-service-port-8010-futur)
11. [Search Service](#11-search-service-port-8011-futur)
12. [Payment Service](#12-payment-service-port-8012-futur)
13. [Subscription Service](#13-subscription-service-port-8013-futur)
14. [Admin Service](#14-admin-service-port-8014-futur)

---

## 1. Auth Service (Port 8000)

**Base URL**: `http://localhost:8000/api/auth/`

### POST `/register/`

**Description**: Inscription d'un nouvel utilisateur

**Headers**:
```
Content-Type: application/json
```

**Body**:
```json
{
  "email": "user@example.com",
  "password": "password123",
  "first_name": "John",
  "last_name": "Doe",
  "phone_number": "+33123456789",
  "date_of_birth": "1990-01-01",
  "address_complement": "Apt 123",
  "city": "Paris",
  "country": "France",
  "postal_code": "75001",
  "region": "Île-de-France",
  "street": "Rue de la Paix",
  "street_number": "123"
}
```

**Response Success (201)**:
```json
{
  "message": "Utilisateur créé avec succès.",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "phone_number": "+33123456789",
    "date_joined": "2024-01-15T10:30:00Z"
  }
}
```

**Response Error (400)**:
```json
{
  "error": "Email déjà utilisé",
  "details": {
    "email": ["Un utilisateur avec cet email existe déjà."]
  }
}
```

**Tables Sources**: `accounts_user`

---

### POST `/login/`

**Description**: Connexion d'un utilisateur

**Headers**:
```
Content-Type: application/json
```

**Body**:
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response Success (200)**:
```json
{
  "user": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "last_login": "2024-01-15T10:30:00Z"
  },
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

**Response Error (401)**:
```json
{
  "error": "Identifiants invalides"
}
```

**Tables Sources**: `accounts_user`

---

### POST `/token/refresh/`

**Description**: Rafraîchissement du token d'accès

**Headers**:
```
Content-Type: application/json
```

**Body**:
```json
{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

**Response Success (200)**:
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

**Response Error (401)**:
```json
{
  "error": "Token de rafraîchissement invalide"
}
```

**Tables Sources**: `accounts_user`

---

### POST `/password-reset/request/`

**Description**: Demande de réinitialisation de mot de passe

**Headers**:
```
Content-Type: application/json
```

**Body**:
```json
{
  "email": "user@example.com",
  "reset_type": "email"
}
```

**Response Success (200)**:
```json
{
  "message": "Un code de réinitialisation a été envoyé par email."
}
```

**Tables Sources**: `accounts_user`, `password_reset_codes`

---

### POST `/password-reset/verify/`

**Description**: Vérification du code de réinitialisation

**Headers**:
```
Content-Type: application/json
```

**Body**:
```json
{
  "email": "user@example.com",
  "code": "123456"
}
```

**Response Success (200)**:
```json
{
  "message": "Code vérifié avec succès.",
  "reset_token": "uuid-reset-token"
}
```

**Tables Sources**: `password_reset_codes`

---

### POST `/password-reset/reset/`

**Description**: Réinitialisation du mot de passe

**Headers**:
```
Content-Type: application/json
```

**Body**:
```json
{
  "email": "user@example.com",
  "new_password": "newpassword123",
  "reset_token": "uuid-reset-token"
}
```

**Response Success (200)**:
```json
{
  "message": "Mot de passe changé avec succès."
}
```

**Tables Sources**: `accounts_user`, `password_reset_codes`

---

## 2. User Service (Port 8001)

**Base URL**: `http://localhost:8001/api/users/`

### GET `/me/`

**Description**: Récupération du profil de l'utilisateur connecté

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
{
  "id": 1,
  "email": "user@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "phone_number": "+33123456789",
  "address_complement": "Apt 123",
  "city": "Paris",
  "country": "France",
  "postal_code": "75001",
  "region": "Île-de-France",
  "street": "Rue de la Paix",
  "street_number": "123",
  "date_joined": "2024-01-01T00:00:00Z",
  "last_login": "2024-01-15T10:30:00Z",
  "is_active": true,
  "is_verified": false,
  "profile_image_url": "https://example.com/profile.jpg",
  "preferred_language": "fr",
  "timezone": "Europe/Paris"
}
```

**Tables Sources**: `accounts_user`, `user_preferences`

---

### GET `/`

**Description**: Liste des utilisateurs (Admin seulement)

**Headers**:
```
Authorization: Bearer <access_token>
```

**Query Parameters**:
- `page`: Numéro de page (défaut: 1)
- `page_size`: Taille de page (défaut: 20)
- `search`: Recherche textuelle
- `is_active`: Filtrer par statut actif
- `is_verified`: Filtrer par statut vérifié

**Response Success (200)**:
```json
{
  "count": 100,
  "next": "http://localhost:8001/api/users/?page=2",
  "previous": null,
  "results": [
    {
      "id": 1,
      "email": "user@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "date_joined": "2024-01-01T00:00:00Z",
      "last_login": "2024-01-15T10:30:00Z",
      "is_active": true,
      "is_verified": false
    }
  ]
}
```

**Tables Sources**: `accounts_user`

---

### GET `/{id}/`

**Description**: Détails d'un utilisateur spécifique

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
{
  "id": 1,
  "email": "user@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "phone_number": "+33123456789",
  "date_joined": "2024-01-01T00:00:00Z",
  "last_login": "2024-01-15T10:30:00Z",
  "is_active": true,
  "is_verified": false,
  "profile_image_url": "https://example.com/profile.jpg"
}
```

**Tables Sources**: `accounts_user`

---

### PUT `/{id}/`

**Description**: Mise à jour d'un utilisateur

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "first_name": "John",
  "last_name": "Doe",
  "phone_number": "+33123456789",
  "city": "Paris",
  "preferred_language": "fr",
  "timezone": "Europe/Paris"
}
```

**Response Success (200)**:
```json
{
  "id": 1,
  "email": "user@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "phone_number": "+33123456789",
  "city": "Paris",
  "preferred_language": "fr",
  "timezone": "Europe/Paris",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

**Tables Sources**: `accounts_user`, `user_preferences`

---

## 3. Product Service (Port 8002)

**Base URL**: `http://localhost:8002/api/products/`

### GET `/`

**Description**: Liste des produits avec pagination et filtres

**Query Parameters**:
- `page`: Numéro de page (défaut: 1)
- `page_size`: Taille de page (défaut: 20)
- `search`: Recherche textuelle
- `category`: ID de catégorie
- `baker_id`: ID du pâtissier
- `min_price`: Prix minimum
- `max_price`: Prix maximum
- `is_featured`: Produits mis en avant
- `is_active`: Produits actifs
- `ordering`: Tri (price, -price, name, -name, created_at, -created_at)

**Response Success (200)**:
```json
{
  "count": 150,
  "next": "http://localhost:8002/api/products/?page=2",
  "previous": null,
  "results": [
    {
      "id": 1,
      "name": "Gâteau au chocolat",
      "description": "Délicieux gâteau au chocolat fait maison",
      "price": 25.50,
      "base_price": 25.50,
      "sku": "GAT-CHOC-001",
      "slug": "gateau-au-chocolat",
      "is_featured": true,
      "is_active": true,
      "is_available": true,
      "stock_quantity": 10,
      "min_order_quantity": 1,
      "max_order_quantity": 5,
      "weight_grams": 800,
      "serving_size": "8 personnes",
      "ingredients": "Chocolat noir, farine, œufs, beurre, sucre",
      "nutritional_info": {
        "calories": 350,
        "protein": 6,
        "carbs": 45,
        "fat": 18
      },
      "tags": ["chocolat", "dessert", "anniversaire"],
      "customization_options": {
        "message": true,
        "decoration": ["fruits", "chocolat", "crème"]
      },
      "delivery_info": {
        "preparation_time_hours": 24,
        "is_refrigerated": true,
        "expiration_date": "2024-01-20"
      },
      "views_count": 150,
      "favorites_count": 25,
      "orders_count": 12,
      "reviews_count": 8,
      "average_rating": 4.5,
      "baker": {
        "id": 1,
        "userid": 2,
        "business_name": "Pâtisserie Marie",
        "description": "Pâtissière passionnée depuis 10 ans",
        "is_verified": true,
        "average_rating": 4.8,
        "profile_image_url": "https://example.com/baker.jpg"
      },
      "images": [
        {
          "id": 1,
          "imageurl": "https://example.com/product1.jpg",
          "format": "jpg",
          "viewfrom": "front",
          "alt_text": "Gâteau au chocolat vue de face",
          "is_primary": true,
          "sort_order": 1,
          "file_size_bytes": 1024000,
          "width_pixels": 1920,
          "height_pixels": 1080
        }
      ],
      "variants": [
        {
          "id": 1,
          "name": "Petit",
          "ingredients": "Chocolat noir, farine, œufs",
          "price": 20.00,
          "sku": "GAT-CHOC-001-S",
          "stock_quantity": 5,
          "is_active": true,
          "sort_order": 1,
          "weight_grams": 600,
          "preparation_time_hours": 20
        }
      ],
      "allergens": [
        {
          "id": 1,
          "name": "Gluten",
          "description": "Contient du gluten"
        },
        {
          "id": 2,
          "name": "Œufs",
          "description": "Contient des œufs"
        }
      ],
      "categories": [
        {
          "id": 1,
          "name": "Gâteaux",
          "slug": "gateaux",
          "description": "Gâteaux et pâtisseries",
          "is_primary": true
        }
      ],
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-15T10:30:00Z"
    }
  ]
}
```

**Tables Sources**: `product`, `product_image`, `product_variant`, `product_allergen`, `product_category`, `baker`, `accounts_user`, `allergen`, `category`

---

### GET `/{id}/`

**Description**: Détails d'un produit spécifique

**Response Success (200)**:
```json
{
  "id": 1,
  "name": "Gâteau au chocolat",
  "description": "Délicieux gâteau au chocolat fait maison",
  "price": 25.50,
  "base_price": 25.50,
  "sku": "GAT-CHOC-001",
  "slug": "gateau-au-chocolat",
  "is_featured": true,
  "is_active": true,
  "is_available": true,
  "stock_quantity": 10,
  "min_order_quantity": 1,
  "max_order_quantity": 5,
  "weight_grams": 800,
  "serving_size": "8 personnes",
  "ingredients": "Chocolat noir, farine, œufs, beurre, sucre",
  "nutritional_info": {
    "calories": 350,
    "protein": 6,
    "carbs": 45,
    "fat": 18
  },
  "tags": ["chocolat", "dessert", "anniversaire"],
  "customization_options": {
    "message": true,
    "decoration": ["fruits", "chocolat", "crème"]
  },
  "delivery_info": {
    "preparation_time_hours": 24,
    "is_refrigerated": true,
    "expiration_date": "2024-01-20"
  },
  "views_count": 150,
  "favorites_count": 25,
  "orders_count": 12,
  "reviews_count": 8,
  "average_rating": 4.5,
  "baker": {
    "id": 1,
    "userid": 2,
    "business_name": "Pâtisserie Marie",
    "description": "Pâtissière passionnée depuis 10 ans",
    "is_verified": true,
    "average_rating": 4.8,
    "profile_image_url": "https://example.com/baker.jpg"
  },
  "images": [
    {
      "id": 1,
      "imageurl": "https://example.com/product1.jpg",
      "format": "jpg",
      "viewfrom": "front",
      "alt_text": "Gâteau au chocolat vue de face",
      "is_primary": true,
      "sort_order": 1,
      "file_size_bytes": 1024000,
      "width_pixels": 1920,
      "height_pixels": 1080
    }
  ],
  "variants": [
    {
      "id": 1,
      "name": "Petit",
      "ingredients": "Chocolat noir, farine, œufs",
      "price": 20.00,
      "sku": "GAT-CHOC-001-S",
      "stock_quantity": 5,
      "is_active": true,
      "sort_order": 1,
      "weight_grams": 600,
      "preparation_time_hours": 20
    }
  ],
  "allergens": [
    {
      "id": 1,
      "name": "Gluten",
      "description": "Contient du gluten"
    }
  ],
  "categories": [
    {
      "id": 1,
      "name": "Gâteaux",
      "slug": "gateaux",
      "description": "Gâteaux et pâtisseries",
      "is_primary": true
    }
  ],
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

**Tables Sources**: `product`, `product_image`, `product_variant`, `product_allergen`, `product_category`, `baker`, `accounts_user`, `allergen`, `category`

---

### POST `/`

**Description**: Création d'un nouveau produit

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "name": "Gâteau au chocolat",
  "description": "Délicieux gâteau au chocolat fait maison",
  "price": 25.50,
  "base_price": 25.50,
  "sku": "GAT-CHOC-001",
  "slug": "gateau-au-chocolat",
  "is_featured": false,
  "is_active": true,
  "is_available": true,
  "stock_quantity": 10,
  "min_order_quantity": 1,
  "max_order_quantity": 5,
  "weight_grams": 800,
  "serving_size": "8 personnes",
  "ingredients": "Chocolat noir, farine, œufs, beurre, sucre",
  "nutritional_info": {
    "calories": 350,
    "protein": 6,
    "carbs": 45,
    "fat": 18
  },
  "tags": ["chocolat", "dessert", "anniversaire"],
  "customization_options": {
    "message": true,
    "decoration": ["fruits", "chocolat", "crème"]
  },
  "delivery_info": {
    "preparation_time_hours": 24,
    "is_refrigerated": true,
    "expiration_date": "2024-01-20"
  },
  "baker_id": 1,
  "variants": [
    {
      "name": "Petit",
      "ingredients": "Chocolat noir, farine, œufs",
      "price": 20.00,
      "sku": "GAT-CHOC-001-S",
      "stock_quantity": 5,
      "weight_grams": 600,
      "preparation_time_hours": 20
    }
  ],
  "images": [
    {
      "imageurl": "https://example.com/product1.jpg",
      "format": "jpg",
      "viewfrom": "front",
      "alt_text": "Gâteau au chocolat vue de face",
      "is_primary": true,
      "sort_order": 1
    }
  ],
  "allergen_ids": [1, 2],
  "category_ids": [1]
}
```

**Response Success (201)**:
```json
{
  "id": 1,
  "name": "Gâteau au chocolat",
  "description": "Délicieux gâteau au chocolat fait maison",
  "price": 25.50,
  "base_price": 25.50,
  "sku": "GAT-CHOC-001",
  "slug": "gateau-au-chocolat",
  "is_featured": false,
  "is_active": true,
  "is_available": true,
  "stock_quantity": 10,
  "min_order_quantity": 1,
  "max_order_quantity": 5,
  "weight_grams": 800,
  "serving_size": "8 personnes",
  "ingredients": "Chocolat noir, farine, œufs, beurre, sucre",
  "nutritional_info": {
    "calories": 350,
    "protein": 6,
    "carbs": 45,
    "fat": 18
  },
  "tags": ["chocolat", "dessert", "anniversaire"],
  "customization_options": {
    "message": true,
    "decoration": ["fruits", "chocolat", "crème"]
  },
  "delivery_info": {
    "preparation_time_hours": 24,
    "is_refrigerated": true,
    "expiration_date": "2024-01-20"
  },
  "views_count": 0,
  "favorites_count": 0,
  "orders_count": 0,
  "reviews_count": 0,
  "average_rating": 0,
  "baker_id": 1,
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

**Tables Sources**: `product`, `product_variant`, `product_image`, `product_allergen`, `product_category`

---

### PUT `/{id}/`

**Description**: Mise à jour d'un produit

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "name": "Gâteau au chocolat premium",
  "description": "Délicieux gâteau au chocolat fait maison avec chocolat premium",
  "price": 28.50,
  "stock_quantity": 15,
  "is_featured": true,
  "tags": ["chocolat", "dessert", "anniversaire", "premium"]
}
```

**Response Success (200)**:
```json
{
  "id": 1,
  "name": "Gâteau au chocolat premium",
  "description": "Délicieux gâteau au chocolat fait maison avec chocolat premium",
  "price": 28.50,
  "stock_quantity": 15,
  "is_featured": true,
  "tags": ["chocolat", "dessert", "anniversaire", "premium"],
  "updated_at": "2024-01-15T10:30:00Z"
}
```

**Tables Sources**: `product`

---

### DELETE `/{id}/`

**Description**: Suppression d'un produit

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (204)**:
```
No Content
```

**Response Error (403)**:
```json
{
  "error": "Vous n'avez pas la permission de supprimer ce produit"
}
```

**Tables Sources**: `product`

---

### POST `/variants/`

**Description**: Création de variantes de produit

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "product_id": 1,
  "variants": [
    {
      "name": "Grand",
      "ingredients": "Chocolat noir premium, farine, œufs",
      "price": 35.00,
      "sku": "GAT-CHOC-001-L",
      "stock_quantity": 8,
      "weight_grams": 1200,
      "preparation_time_hours": 28
    }
  ]
}
```

**Response Success (201)**:
```json
{
  "message": "Variantes créées avec succès",
  "variants": [
    {
      "id": 2,
      "productid": 1,
      "name": "Grand",
      "ingredients": "Chocolat noir premium, farine, œufs",
      "price": 35.00,
      "sku": "GAT-CHOC-001-L",
      "stock_quantity": 8,
      "is_active": true,
      "sort_order": 2,
      "weight_grams": 1200,
      "preparation_time_hours": 28,
      "created_at": "2024-01-15T10:30:00Z"
    }
  ]
}
```

**Tables Sources**: `product_variant`

---

### POST `/categories/`

**Description**: Création de catégories

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "name": "Gâteaux d'anniversaire",
  "slug": "gateaux-anniversaire",
  "description": "Gâteaux spécialement conçus pour les anniversaires",
  "parent_id": null,
  "image_url": "https://example.com/category.jpg",
  "icon": "cake",
  "is_active": true,
  "sort_order": 1
}
```

**Response Success (201)**:
```json
{
  "id": 2,
  "name": "Gâteaux d'anniversaire",
  "slug": "gateaux-anniversaire",
  "description": "Gâteaux spécialement conçus pour les anniversaires",
  "parent_id": null,
  "image_url": "https://example.com/category.jpg",
  "icon": "cake",
  "is_active": true,
  "sort_order": 1,
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

**Tables Sources**: `product_categories`

---

### POST `/images/`

**Description**: Création d'images de produit

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "product_id": 1,
  "images": [
    {
      "imageurl": "https://example.com/product-side.jpg",
      "format": "jpg",
      "viewfrom": "side",
      "alt_text": "Gâteau au chocolat vue de côté",
      "is_primary": false,
      "sort_order": 2,
      "file_size_bytes": 1024000,
      "width_pixels": 1920,
      "height_pixels": 1080
    }
  ]
}
```

**Response Success (201)**:
```json
{
  "message": "Images créées avec succès",
  "images": [
    {
      "id": 2,
      "productid": 1,
      "imageurl": "https://example.com/product-side.jpg",
      "format": "jpg",
      "viewfrom": "side",
      "alt_text": "Gâteau au chocolat vue de côté",
      "is_primary": false,
      "sort_order": 2,
      "file_size_bytes": 1024000,
      "width_pixels": 1920,
      "height_pixels": 1080,
      "created_at": "2024-01-15T10:30:00Z"
    }
  ]
}
```

**Tables Sources**: `product_image`

---

### POST `/allergens/`

**Description**: Création d'allergènes

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "name": "Lactose",
  "description": "Contient du lactose"
}
```

**Response Success (201)**:
```json
{
  "id": 3,
  "name": "Lactose",
  "description": "Contient du lactose",
  "created_at": "2024-01-15T10:30:00Z"
}
```

**Tables Sources**: `allergen`

---

### POST `/quantity-rules/`

**Description**: Création de règles de quantité

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "product_id": 1,
  "rules": [
    {
      "min_quantity": 1,
      "max_quantity": 5,
      "price_per_unit": 25.50,
      "is_active": true
    }
  ]
}
```

**Response Success (201)**:
```json
{
  "message": "Règles de quantité créées avec succès",
  "rules": [
    {
      "id": 1,
      "productid": 1,
      "min_quantity": 1,
      "max_quantity": 5,
      "price_per_unit": 25.50,
      "is_active": true,
      "created_at": "2024-01-15T10:30:00Z"
    }
  ]
}
```

**Tables Sources**: `product_quantity_rule`

---

### GET `/{id}/history/`

**Description**: Historique d'un produit

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
{
  "product_id": 1,
  "history": [
    {
      "id": 1,
      "action": "created",
      "old_values": null,
      "new_values": {
        "name": "Gâteau au chocolat",
        "price": 25.50
      },
      "changed_by": 2,
      "changed_at": "2024-01-01T00:00:00Z"
    },
    {
      "id": 2,
      "action": "updated",
      "old_values": {
        "price": 25.50
      },
      "new_values": {
        "price": 28.50
      },
      "changed_by": 2,
      "changed_at": "2024-01-15T10:30:00Z"
    }
  ]
}
```

**Tables Sources**: `product_history`

---

### POST `/full_product/`

**Description**: Création d'un produit complet avec toutes ses relations

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "name": "Gâteau au chocolat",
  "description": "Délicieux gâteau au chocolat fait maison",
  "price": 25.50,
  "base_price": 25.50,
  "sku": "GAT-CHOC-001",
  "slug": "gateau-au-chocolat",
  "is_featured": false,
  "is_active": true,
  "is_available": true,
  "stock_quantity": 10,
  "min_order_quantity": 1,
  "max_order_quantity": 5,
  "weight_grams": 800,
  "serving_size": "8 personnes",
  "ingredients": "Chocolat noir, farine, œufs, beurre, sucre",
  "nutritional_info": {
    "calories": 350,
    "protein": 6,
    "carbs": 45,
    "fat": 18
  },
  "tags": ["chocolat", "dessert", "anniversaire"],
  "customization_options": {
    "message": true,
    "decoration": ["fruits", "chocolat", "crème"]
  },
  "delivery_info": {
    "preparation_time_hours": 24,
    "is_refrigerated": true,
    "expiration_date": "2024-01-20"
  },
  "baker_id": 1,
  "variants": [
    {
      "name": "Petit",
      "ingredients": "Chocolat noir, farine, œufs",
      "price": 20.00,
      "sku": "GAT-CHOC-001-S",
      "stock_quantity": 5,
      "weight_grams": 600,
      "preparation_time_hours": 20
    },
    {
      "name": "Grand",
      "ingredients": "Chocolat noir premium, farine, œufs",
      "price": 35.00,
      "sku": "GAT-CHOC-001-L",
      "stock_quantity": 8,
      "weight_grams": 1200,
      "preparation_time_hours": 28
    }
  ],
  "images": [
    {
      "imageurl": "https://example.com/product1.jpg",
      "format": "jpg",
      "viewfrom": "front",
      "alt_text": "Gâteau au chocolat vue de face",
      "is_primary": true,
      "sort_order": 1
    },
    {
      "imageurl": "https://example.com/product-side.jpg",
      "format": "jpg",
      "viewfrom": "side",
      "alt_text": "Gâteau au chocolat vue de côté",
      "is_primary": false,
      "sort_order": 2
    }
  ],
  "allergen_ids": [1, 2],
  "category_ids": [1],
  "quantity_rules": [
    {
      "min_quantity": 1,
      "max_quantity": 5,
      "price_per_unit": 25.50,
      "is_active": true
    }
  ]
}
```

**Response Success (201)**:
```json
{
  "message": "Produit complet créé avec succès",
  "product": {
    "id": 1,
    "name": "Gâteau au chocolat",
    "description": "Délicieux gâteau au chocolat fait maison",
    "price": 25.50,
    "base_price": 25.50,
    "sku": "GAT-CHOC-001",
    "slug": "gateau-au-chocolat",
    "is_featured": false,
    "is_active": true,
    "is_available": true,
    "stock_quantity": 10,
    "min_order_quantity": 1,
    "max_order_quantity": 5,
    "weight_grams": 800,
    "serving_size": "8 personnes",
    "ingredients": "Chocolat noir, farine, œufs, beurre, sucre",
    "nutritional_info": {
      "calories": 350,
      "protein": 6,
      "carbs": 45,
      "fat": 18
    },
    "tags": ["chocolat", "dessert", "anniversaire"],
    "customization_options": {
      "message": true,
      "decoration": ["fruits", "chocolat", "crème"]
    },
    "delivery_info": {
      "preparation_time_hours": 24,
      "is_refrigerated": true,
      "expiration_date": "2024-01-20"
    },
    "views_count": 0,
    "favorites_count": 0,
    "orders_count": 0,
    "reviews_count": 0,
    "average_rating": 0,
    "baker_id": 1,
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  },
  "variants": [
    {
      "id": 1,
      "productid": 1,
      "name": "Petit",
      "ingredients": "Chocolat noir, farine, œufs",
      "price": 20.00,
      "sku": "GAT-CHOC-001-S",
      "stock_quantity": 5,
      "is_active": true,
      "sort_order": 1,
      "weight_grams": 600,
      "preparation_time_hours": 20
    },
    {
      "id": 2,
      "productid": 1,
      "name": "Grand",
      "ingredients": "Chocolat noir premium, farine, œufs",
      "price": 35.00,
      "sku": "GAT-CHOC-001-L",
      "stock_quantity": 8,
      "is_active": true,
      "sort_order": 2,
      "weight_grams": 1200,
      "preparation_time_hours": 28
    }
  ],
  "images": [
    {
      "id": 1,
      "productid": 1,
      "imageurl": "https://example.com/product1.jpg",
      "format": "jpg",
      "viewfrom": "front",
      "alt_text": "Gâteau au chocolat vue de face",
      "is_primary": true,
      "sort_order": 1,
      "file_size_bytes": 1024000,
      "width_pixels": 1920,
      "height_pixels": 1080
    },
    {
      "id": 2,
      "productid": 1,
      "imageurl": "https://example.com/product-side.jpg",
      "format": "jpg",
      "viewfrom": "side",
      "alt_text": "Gâteau au chocolat vue de côté",
      "is_primary": false,
      "sort_order": 2,
      "file_size_bytes": 1024000,
      "width_pixels": 1920,
      "height_pixels": 1080
    }
  ],
  "allergens": [
    {
      "id": 1,
      "name": "Gluten",
      "description": "Contient du gluten"
    },
    {
      "id": 2,
      "name": "Œufs",
      "description": "Contient des œufs"
    }
  ],
  "categories": [
    {
      "id": 1,
      "name": "Gâteaux",
      "slug": "gateaux",
      "description": "Gâteaux et pâtisseries",
      "is_primary": true
    }
  ],
  "quantity_rules": [
    {
      "id": 1,
      "productid": 1,
      "min_quantity": 1,
      "max_quantity": 5,
      "price_per_unit": 25.50,
      "is_active": true
    }
  ]
}
```

**Tables Sources**: `product`, `product_variant`, `product_image`, `product_allergen`, `product_category`, `product_quantity_rule`

---

### GET `/{id}/full_product/`

**Description**: Récupération d'un produit complet avec toutes ses relations

**Response Success (200)**:
```json
{
  "product": {
    "id": 1,
    "name": "Gâteau au chocolat",
    "description": "Délicieux gâteau au chocolat fait maison",
    "price": 25.50,
    "base_price": 25.50,
    "sku": "GAT-CHOC-001",
    "slug": "gateau-au-chocolat",
    "is_featured": true,
    "is_active": true,
    "is_available": true,
    "stock_quantity": 10,
    "min_order_quantity": 1,
    "max_order_quantity": 5,
    "weight_grams": 800,
    "serving_size": "8 personnes",
    "ingredients": "Chocolat noir, farine, œufs, beurre, sucre",
    "nutritional_info": {
      "calories": 350,
      "protein": 6,
      "carbs": 45,
      "fat": 18
    },
    "tags": ["chocolat", "dessert", "anniversaire"],
    "customization_options": {
      "message": true,
      "decoration": ["fruits", "chocolat", "crème"]
    },
    "delivery_info": {
      "preparation_time_hours": 24,
      "is_refrigerated": true,
      "expiration_date": "2024-01-20"
    },
    "views_count": 150,
    "favorites_count": 25,
    "orders_count": 12,
    "reviews_count": 8,
    "average_rating": 4.5,
    "baker_id": 1,
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  },
  "variants": [
    {
      "id": 1,
      "productid": 1,
      "name": "Petit",
      "ingredients": "Chocolat noir, farine, œufs",
      "price": 20.00,
      "sku": "GAT-CHOC-001-S",
      "stock_quantity": 5,
      "is_active": true,
      "sort_order": 1,
      "weight_grams": 600,
      "preparation_time_hours": 20
    },
    {
      "id": 2,
      "productid": 1,
      "name": "Grand",
      "ingredients": "Chocolat noir premium, farine, œufs",
      "price": 35.00,
      "sku": "GAT-CHOC-001-L",
      "stock_quantity": 8,
      "is_active": true,
      "sort_order": 2,
      "weight_grams": 1200,
      "preparation_time_hours": 28
    }
  ],
  "images": [
    {
      "id": 1,
      "productid": 1,
      "imageurl": "https://example.com/product1.jpg",
      "format": "jpg",
      "viewfrom": "front",
      "alt_text": "Gâteau au chocolat vue de face",
      "is_primary": true,
      "sort_order": 1,
      "file_size_bytes": 1024000,
      "width_pixels": 1920,
      "height_pixels": 1080
    },
    {
      "id": 2,
      "productid": 1,
      "imageurl": "https://example.com/product-side.jpg",
      "format": "jpg",
      "viewfrom": "side",
      "alt_text": "Gâteau au chocolat vue de côté",
      "is_primary": false,
      "sort_order": 2,
      "file_size_bytes": 1024000,
      "width_pixels": 1920,
      "height_pixels": 1080
    }
  ],
  "allergens": [
    {
      "id": 1,
      "name": "Gluten",
      "description": "Contient du gluten"
    },
    {
      "id": 2,
      "name": "Œufs",
      "description": "Contient des œufs"
    }
  ],
  "categories": [
    {
      "id": 1,
      "name": "Gâteaux",
      "slug": "gateaux",
      "description": "Gâteaux et pâtisseries",
      "is_primary": true
    }
  ],
  "quantity_rules": [
    {
      "id": 1,
      "productid": 1,
      "min_quantity": 1,
      "max_quantity": 5,
      "price_per_unit": 25.50,
      "is_active": true
    }
  ],
  "baker": {
    "id": 1,
    "userid": 2,
    "business_name": "Pâtisserie Marie",
    "description": "Pâtissière passionnée depuis 10 ans",
    "is_verified": true,
    "average_rating": 4.8,
    "profile_image_url": "https://example.com/baker.jpg",
    "phone_number": "+33123456789",
    "email": "marie@patisserie.com",
    "years_experience": 10,
    "is_active": true,
    "accepts_orders": true,
    "delivery_radius": 15,
    "min_order_amount": 20.00,
    "delivery_fee": 5.00,
    "preparation_time_hours": 24,
    "social_links": {
      "instagram": "@patisserie_marie",
      "facebook": "PatisserieMarie"
    },
    "commission_rate": 10.00
  }
}
```

**Tables Sources**: `product`, `product_variant`, `product_image`, `product_allergen`, `product_category`, `product_quantity_rule`, `baker`, `accounts_user`

---

## 4. Display Service (Port 8003)

**Base URL**: `http://localhost:8003/api/display/`

> **Note architecturale**: Les calculs de distance utilisent la table `baker_location` (coordonnées GPS des pâtissiers). Les produits dont le pâtissier n'a pas de ligne dans `baker_location` sont exclus des résultats de proximité. `baker.location` reste le champ texte d'adresse.

---

### GET `/products/home/payload/`

**Description**: Payload complet de l'écran d'accueil : produits, favoris, filtres. Calcule optionnellement la distance baker→utilisateur si `lat`/`lon` sont fournis.

**Headers**:
```
Content-Type: application/json
Authorization: Bearer <access_token>   (optionnel – pour favoris)
```

**Query Parameters**:

| Paramètre | Type | Requis | Description |
|-----------|------|--------|-------------|
| `page` | int | Non (défaut 1) | Numéro de page |
| `page_size` | int | Non (défaut 12, max 50) | Nombre d'éléments par page |
| `lat` | float | Non | Latitude utilisateur (pour distance) |
| `lon` | float | Non | Longitude utilisateur (pour distance) |

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "page": 1,
    "page_size": 12,
    "has_more": false,
    "next_page": null,
    "total_count": 1,
    "products": [
      {
        "id": 1,
        "name": "Gâteau royal",
        "subtitle": "Subtile",
        "description": "Délice du jour",
        "price": 12.5,
        "average_rating": 4.8,
        "reviews_count": 5,
        "distance_km": 2.3,
        "baker": {
          "id": 10,
          "userid": 100,
          "business_name": "Les Délices",
          "description": "Patissier",
          "average_rating": 4.8,
          "profile_image_url": "cdn/...",
          "latitude": 48.8566,
          "longitude": 2.3522,
          "address_label": "Paris 1er, France"
        },
        "images": [
          { "id": 100, "imageurl": "...", "is_primary": true, "format": "jpg" }
        ],
        "categories": [
          { "id": "cat-1", "name": "Tartes", "slug": "tartes" }
        ],
        "isFavorite": false
      }
    ],
    "favorites": [
      { "id": 1, "name": "Gâteau royal", "price": 12.5, "primary_image_url": "..." }
    ],
    "filters": {
      "categories": [{ "id": "cat-1", "name": "Tartes", "slug": "tartes" }]
    }
  }
}
```

**Notes**:
- `distance_km` est `null` si `lat`/`lon` absents ou si le baker n'a pas de `baker_location`.
- `baker.latitude`, `baker.longitude`, `baker.address_label` sont `null` si le baker n'a pas de `baker_location`.
- `favorites` est toujours `[]` pour les utilisateurs anonymes.

**Response Error (400)** – paramètres invalides:
```json
{ "success": false, "error": { "code": "bad_request", "message": "..." } }
```

**Tables Sources**: `product`, `baker`, `baker_location`, `product_image`, `product_categories`, `product_category_relations`, `user_favoris`

---

### GET `/products/{id}/full/`

**Description**: Détail complet d'un produit avec baker, variantes, allergènes, avis et coordonnées géographiques.

**Path Parameters**: `id` (int) – identifiant du produit

**Headers**:
```
Authorization: Bearer <access_token>   (optionnel – pour isFavorite)
```

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "product": {
      "id": 252, "name": "Layer cake", "price": 80.0,
      "images": [...], "variants": [...], "categories": [...],
      "allergens": [...], "tags": [...],
      "average_rating": 4.5, "reviews_count": 12
    },
    "baker": {
      "id": 65, "userid": 309, "business_name": "Test Bakery",
      "years_experience": 5, "delivery_radius": 20,
      "phone_number": "0600000000", "email": "a@gmail.com",
      "latitude": 48.8566,
      "longitude": 2.3522,
      "address_label": "Paris 1er, France"
    },
    "review": {
      "reviews_count": 12, "average_rating": 4.5,
      "reviews_preview": [{ "author": "a@gmail.com", "rating": 5, "text": "Excellent" }]
    },
    "favorite": { "isFavorite": false, "favorite_id": null, "favorite_group_id": null }
  }
}
```

**Notes**: `baker.latitude`, `baker.longitude`, `baker.address_label` sont `null` si le baker n'a pas de `baker_location`.

**Response Error (404)**: produit introuvable ou inactif.

**Tables Sources**: `product`, `baker`, `baker_location`, `product_image`, `product_variant`, `product_category_relations`, `product_categories`, `product_allergen`, `allergen`, `product_tag_relations`, `product_tags`, `user_favoris`, `product_reviews`, `accounts_user`

---

### POST `/products/nearby/nolat/`

**Description**: Produits à proximité d'un point fourni. Distance calculée via `baker_location`. Les produits dont le pâtissier n'a pas de ligne dans `baker_location` sont exclus.

**Headers**:
```
Content-Type: application/json
```

**Body**:
```json
{
  "lat": 48.8566,
  "lon": 2.3522,
  "distance": 10
}
```

| Champ | Type | Requis | Description |
|-------|------|--------|-------------|
| `lat` | float | Oui | Latitude du point de référence |
| `lon` | float | Oui | Longitude du point de référence |
| `distance` | float | Oui | Rayon maximum en km |

**Response Success (200)**:
```json
{
  "success": true,
  "count": 2,
  "data": [
    {
      "product_id": 1,
      "product_name": "Gâteau royal",
      "baker_name": "Les Délices",
      "baker_latitude": 48.8566,
      "baker_longitude": 2.3522,
      "baker_address_label": "Paris 1er, France",
      "distance_km": 2.3
    }
  ]
}
```

**Response Error (400)**:
```json
{ "success": false, "error": { "code": "bad_request", "message": "Distance is required." } }
```

**Tables Sources**: `product`, `baker`, `baker_location`

---

### POST `/products/nearby/connected/`

**Description**: Produits à proximité de l'utilisateur connecté. Distance calculée depuis `accounts_user.location` (PostGIS) vers `baker_location`. Les produits dont le pâtissier n'a pas de `baker_location` sont exclus.

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{ "distance": 10 }
```

**Response Success (200)**: même structure que `nearby/nolat`.

**Response Error (400)**: distance manquante ou utilisateur sans localisation.

**Response Error (401)**: token manquant ou invalide.

**Tables Sources**: `product`, `baker`, `baker_location`, `accounts_user`

---

## Codes de Statut HTTP

| Code | Description | Utilisation |
|------|-------------|-------------|
| 200 | OK | Requête réussie |
| 201 | Created | Ressource créée |
| 204 | No Content | Suppression réussie |
| 400 | Bad Request | Données invalides |
| 401 | Unauthorized | Token manquant ou invalide |
| 403 | Forbidden | Permissions insuffisantes |
| 404 | Not Found | Ressource non trouvée |
| 409 | Conflict | Conflit de données |
| 422 | Unprocessable Entity | Erreur de validation |
| 500 | Internal Server Error | Erreur serveur |

---

## Gestion des Erreurs

### Format Standard des Erreurs

```json
{
  "error": "Message d'erreur principal",
  "details": {
    "field_name": ["Message d'erreur spécifique"]
  },
  "code": "ERROR_CODE",
  "timestamp": "2024-01-15T10:30:00Z",
  "path": "/api/products/",
  "method": "POST"
}
```

### Codes d'Erreur Spécifiques

| Code | Description |
|------|-------------|
| `VALIDATION_ERROR` | Erreur de validation des données |
| `AUTHENTICATION_ERROR` | Erreur d'authentification |
| `AUTHORIZATION_ERROR` | Erreur d'autorisation |
| `NOT_FOUND` | Ressource non trouvée |
| `DUPLICATE_ERROR` | Ressource déjà existante |
| `BUSINESS_LOGIC_ERROR` | Erreur de logique métier |
| `EXTERNAL_SERVICE_ERROR` | Erreur de service externe |
| `RATE_LIMIT_ERROR` | Limite de taux dépassée |

---

## Limites et Contraintes

### Rate Limiting
- **Utilisateurs authentifiés**: 1000 requêtes/heure
- **Utilisateurs non authentifiés**: 100 requêtes/heure
- **Endpoints sensibles**: 10 requêtes/minute

### Pagination
- **Taille de page par défaut**: 20 éléments
- **Taille de page maximale**: 100 éléments
- **Taille de page minimale**: 1 élément

### Validation
- **Taille maximale des fichiers**: 10MB
- **Types de fichiers autorisés**: jpg, png, gif, webp
- **Longueur maximale des textes**: 5000 caractères

### Sécurité
- **Tokens JWT**: Durée de vie de 12 heures
- **Refresh tokens**: Durée de vie de 7 jours
- **Mots de passe**: Minimum 8 caractères avec complexité
- **CORS**: Configuration pour le frontend Flutter

---

## Monitoring et Logs

### Métriques Collectées
- Nombre de requêtes par endpoint
- Temps de réponse moyen
- Taux d'erreur par endpoint
- Utilisation des ressources

### Logs Structurés
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "level": "INFO",
  "service": "product-service",
  "endpoint": "/api/products/",
  "method": "GET",
  "user_id": 1,
  "response_time_ms": 150,
  "status_code": 200,
  "request_id": "req-123456"
}
```

---

## Prochaines Étapes

1. **Développement des services manquants** selon les priorités définies
2. **Implémentation du tracking utilisateur** sur tous les endpoints
3. **Tests d'intégration** frontend-backend
4. **Documentation OpenAPI/Swagger** complète
5. **Monitoring et alertes** en production
