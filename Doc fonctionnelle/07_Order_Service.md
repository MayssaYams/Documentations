# Order Service API Documentation

**Base URL Freebox** : `http://91.171.4.184:28007/api/`
**Base URL Local** : `http://localhost:8007/api/`

## Endpoints

### GET `/cart/`

**Description**: Récupération du panier actif de l'utilisateur connecté
**URL Freebox** : `http://91.171.4.184:28007/api/cart/`  
**URL Local** : `http://localhost:8007/api/cart/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": 1,
  "session_id": null,
  "is_active": true,
  "expires_at": null,
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z",
  "items": [
    {
      "id": "660e8400-e29b-41d4-a716-446655440001",
      "product_id": 1,
      "product_variant_id": null,
      "quantity": 2,
      "unit_price": "25.50",
      "total_price": "51.00",
      "customization_options": null,
      "special_instructions": "Sans noix",
      "delivery_date": "2024-01-20",
      "delivery_time_slot": "14:00-16:00"
    }
  ]
}
```

**Response Error (404)**:
```json
{
  "message": "No active cart found"
}
```

**Tables Sources**: `cart`, `cart_items`

---

### POST `/cart/items/`

**Description**: Ajout d'un article au panier
**URL Freebox** : `http://91.171.4.184:28007/api/cart/items/`  
**URL Local** : `http://localhost:8007/api/cart/items/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "product_id": 1,
  "product_variant_id": null,
  "quantity": 2,
  "customization_options": {
    "message": "Joyeux anniversaire",
    "decoration": "fruits"
  },
  "special_instructions": "Sans noix",
  "delivery_date": "2024-01-20",
  "delivery_time_slot": "14:00-16:00"
}
```

**Response Success (201)**:
```json
{
  "id": "660e8400-e29b-41d4-a716-446655440001",
  "cart_id": "550e8400-e29b-41d4-a716-446655440000",
  "product_id": 1,
  "quantity": 2,
  "unit_price": "25.50",
  "total_price": "51.00"
}
```

**Tables Sources**: `cart`, `cart_items`, `product`

---

### DELETE `/cart/items/{id}/`

**Description**: Suppression d'un article du panier
**URL Freebox** : `http://91.171.4.184:28007/api/cart/items/{id}/`  
**URL Local** : `http://localhost:8007/api/cart/items/{id}/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (204)**:
```
No Content
```

**Tables Sources**: `cart_items`

---

### POST `/cart/checkout/`

**Description**: Finalisation du panier et création d'une commande
**URL Freebox** : `http://91.171.4.184:28007/api/cart/checkout/`  
**URL Local** : `http://localhost:8007/api/cart/checkout/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "delivery_fee": "5.00",
  "service_fee": "2.00",
  "discount_amount": "0.00",
  "delivery_address": {
    "street": "Rue de la Paix",
    "street_number": "123",
    "city": "Paris",
    "postal_code": "75001",
    "country": "France"
  },
  "delivery_date": "2024-01-20",
  "delivery_time_slot": "14:00-16:00",
  "delivery_instructions": "Sonner 2 fois",
  "customer_notes": "Gâteau pour anniversaire"
}
```

**Response Success (201)**:
```json
{
  "order_id": 12345,
  "order_number": "ORD-2024-001234",
  "total_price": "58.00",
  "status": "pending"
}
```

**Tables Sources**: `cart`, `cart_items`, `orders`, `order_detail`

---

### GET `/orders/`

**Description**: Liste des commandes de l'utilisateur connecté
**URL Freebox** : `http://91.171.4.184:28007/api/orders/`  
**URL Local** : `http://localhost:8007/api/orders/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
[
  {
    "id": 12345,
    "order_number": "ORD-2024-001234",
    "total_price": "58.00",
    "status": "pending",
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
]
```

**Tables Sources**: `orders`

---

### GET `/orders/{id}/`

**Description**: Détails d'une commande spécifique
**URL Freebox** : `http://91.171.4.184:28007/api/orders/{id}/`  
**URL Local** : `http://localhost:8007/api/orders/{id}/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
{
  "id": 12345,
  "order_number": "ORD-2024-001234",
  "total_price": "58.00",
  "subtotal": "51.00",
  "delivery_fee": "5.00",
  "service_fee": "2.00",
  "discount_amount": "0.00",
  "status": "pending",
  "delivery_address": {
    "street": "Rue de la Paix",
    "street_number": "123",
    "city": "Paris",
    "postal_code": "75001",
    "country": "France"
  },
  "delivery_date": "2024-01-20",
  "delivery_time_slot": "14:00-16:00",
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z",
  "items": [
    {
      "id": 1,
      "product_id": 1,
      "variant_id": null,
      "quantity": 2,
      "unit_price": "25.50",
      "total_price": "51.00",
      "customization_options": {
        "message": "Joyeux anniversaire"
      },
      "special_instructions": "Sans noix"
    }
  ]
}
```

**Tables Sources**: `orders`, `order_detail`

---

### PUT `/orders/{id}/status/`

**Description**: Mise à jour du statut d'une commande
**URL Freebox** : `http://91.171.4.184:28007/api/orders/{id}/status/`  
**URL Local** : `http://localhost:8007/api/orders/{id}/status/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "status": "confirmed"
}
```

**Response Success (200)**:
```json
{
  "message": "Order status updated",
  "new_status": "confirmed"
}
```

**Tables Sources**: `orders`, `order_status_history`





