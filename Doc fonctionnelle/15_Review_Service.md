# Review Service API Documentation

**Base URL Freebox** : `http://91.171.4.184:28015/api/reviews/`
**Base URL Local** : `http://localhost:8015/api/reviews/`

## Endpoints

### GET `/product/{product_id}/`

**Description**: Liste des avis pour un produit
**URL Freebox** : `http://91.171.4.184:28015/api/reviews/product/{product_id}/`  
**URL Local** : `http://localhost:8015/api/reviews/product/{product_id}/`

**Authentification** : Non requise

**Query Parameters**:
- `min_rating`: Note minimum (défaut: 1)
- `verified_only`: Afficher uniquement les avis vérifiés (true/false)
- `has_images`: Afficher uniquement les avis avec images (true/false)
- `sort_by`: Tri (date, rating, helpful)

**Response Success (200)**:
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "product_id": "1",
    "user_id": "2",
    "order_id": "12345",
    "rating": 5,
    "title": "Excellent gâteau !",
    "review_text": "Gâteau délicieux, très bon rapport qualité-prix.",
    "is_verified": true,
    "helpful_count": 10,
    "images": [
      "https://example.com/review1.jpg"
    ],
    "metadata": {
      "delivery_rating": 5,
      "packaging_rating": 4
    },
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
]
```

**Tables Sources**: `product_reviews`

---

### GET `/product/{product_id}/{id}/`

**Description**: Détails d'un avis spécifique
**URL Freebox** : `http://91.171.4.184:28015/api/reviews/product/{product_id}/{id}/`  
**URL Local** : `http://localhost:8015/api/reviews/product/{product_id}/{id}/`

**Authentification** : Non requise

**Response Success (200)**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "product_id": "1",
  "user_id": "2",
  "order_id": "12345",
  "rating": 5,
  "title": "Excellent gâteau !",
  "review_text": "Gâteau délicieux, très bon rapport qualité-prix.",
  "is_verified": true,
  "helpful_count": 10,
  "images": [
    "https://example.com/review1.jpg"
  ],
  "metadata": {
    "delivery_rating": 5,
    "packaging_rating": 4
  },
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

**Tables Sources**: `product_reviews`

---

### POST `/product/{product_id}/`

**Description**: Création d'un avis pour un produit
**URL Freebox** : `http://91.171.4.184:28015/api/reviews/product/{product_id}/`  
**URL Local** : `http://localhost:8015/api/reviews/product/{product_id}/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "product_id": "1",
  "user_id": "2",
  "order_id": "12345",
  "rating": 5,
  "title": "Excellent gâteau !",
  "review_text": "Gâteau délicieux, très bon rapport qualité-prix.",
  "images": [
    "https://example.com/review1.jpg"
  ],
  "metadata": {
    "delivery_rating": 5,
    "packaging_rating": 4
  }
}
```

**Response Success (201)**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "product_id": "1",
  "user_id": "2",
  "order_id": "12345",
  "rating": 5,
  "title": "Excellent gâteau !",
  "review_text": "Gâteau délicieux, très bon rapport qualité-prix.",
  "is_verified": true,
  "helpful_count": 0,
  "images": [
    "https://example.com/review1.jpg"
  ],
  "metadata": {
    "delivery_rating": 5,
    "packaging_rating": 4
  },
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

**Response Error (400)**:
```json
{
  "detail": "User already reviewed this product"
}
```

**Tables Sources**: `product_reviews`, `product`

---

### PUT `/product/{product_id}/{id}/`

**Description**: Mise à jour d'un avis
**URL Freebox** : `http://91.171.4.184:28015/api/reviews/product/{product_id}/{id}/`  
**URL Local** : `http://localhost:8015/api/reviews/product/{product_id}/{id}/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "rating": 4,
  "title": "Très bon gâteau",
  "review_text": "Gâteau délicieux mais un peu cher.",
  "images": [
    "https://example.com/review1.jpg",
    "https://example.com/review2.jpg"
  ],
  "metadata": {
    "delivery_rating": 5,
    "packaging_rating": 4
  }
}
```

**Response Success (200)**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "product_id": "1",
  "user_id": "2",
  "rating": 4,
  "title": "Très bon gâteau",
  "review_text": "Gâteau délicieux mais un peu cher.",
  "is_verified": true,
  "helpful_count": 10,
  "images": [
    "https://example.com/review1.jpg",
    "https://example.com/review2.jpg"
  ],
  "metadata": {
    "delivery_rating": 5,
    "packaging_rating": 4
  },
  "updated_at": "2024-01-15T10:35:00Z"
}
```

**Tables Sources**: `product_reviews`, `product`

---

### DELETE `/product/{product_id}/{id}/`

**Description**: Suppression d'un avis
**URL Freebox** : `http://91.171.4.184:28015/api/reviews/product/{product_id}/{id}/`  
**URL Local** : `http://localhost:8015/api/reviews/product/{product_id}/{id}/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (204)**:
```
No Content
```

**Tables Sources**: `product_reviews`, `product`

---

### POST `/product/{product_id}/{id}/helpful/`

**Description**: Marquer un avis comme utile
**URL Freebox** : `http://91.171.4.184:28015/api/reviews/product/{product_id}/{id}/helpful/`  
**URL Local** : `http://localhost:8015/api/reviews/product/{product_id}/{id}/helpful/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "user_id": "3"
}
```

**Response Success (200)**:
```json
{
  "detail": "Marked helpful"
}
```

**Tables Sources**: `product_reviews`, `review_helpful_votes`

---

### POST `/product/{product_id}/{id}/helpful/remove/`

**Description**: Retirer le vote "utile" d'un avis
**URL Freebox** : `http://91.171.4.184:28015/api/reviews/product/{product_id}/{id}/helpful/remove/`  
**URL Local** : `http://localhost:8015/api/reviews/product/{product_id}/{id}/helpful/remove/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "user_id": "3"
}
```

**Response Success (200)**:
```json
{
  "detail": "Removed helpful"
}
```

**Tables Sources**: `product_reviews`, `review_helpful_votes`

---

### GET `/summary/{product_id}/`

**Description**: Résumé des avis pour un produit
**URL Freebox** : `http://91.171.4.184:28015/api/reviews/summary/{product_id}/`  
**URL Local** : `http://localhost:8015/api/reviews/summary/{product_id}/`

**Authentification** : Non requise

**Response Success (200)**:
```json
{
  "product_id": "1",
  "average_rating": 4.5,
  "total_reviews": 25,
  "rating_distribution": {
    "1": 1,
    "2": 2,
    "3": 3,
    "4": 8,
    "5": 11
  },
  "verified_count": 20
}
```

**Tables Sources**: `product_reviews`

---

### GET `/summary/baker/{baker_id}/summary/`

**Description**: Résumé des avis pour tous les produits d'un pâtissier
**URL Freebox** : `http://91.171.4.184:28015/api/reviews/summary/baker/{baker_id}/summary/`  
**URL Local** : `http://localhost:8015/api/reviews/summary/baker/{baker_id}/summary/`

**Authentification** : Non requise

**Response Success (200)**:
```json
{
  "baker_id": "1",
  "average_rating": 4.8
}
```

**Tables Sources**: `product_reviews`, `product`





