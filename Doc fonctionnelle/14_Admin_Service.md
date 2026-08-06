# Admin Service API Documentation

**Base URL Freebox** : `http://91.171.4.184:28014/api/admin/`
**Base URL Local** : `http://localhost:8014/api/admin/`

## Endpoints

### GET `/users/`

**Description**: Liste des utilisateurs (Admin seulement)
**URL Freebox** : `http://91.171.4.184:28014/api/admin/users/`  
**URL Local** : `http://localhost:8014/api/admin/users/`

**Authentification** : Requise (Admin)

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
[
  {
    "id": 1,
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "is_active": true,
    "is_staff": false,
    "is_superuser": false,
    "phone_number": "+33123456789",
    "city": "Paris",
    "country": "France",
    "postal_code": "75001",
    "region": "Île-de-France",
    "street": "Rue de la Paix",
    "street_number": "123",
    "address_complement": "Apt 123",
    "date_of_birth": "1990-01-01"
  }
]
```

**Tables Sources**: `accounts_user`

---

### GET `/users/{id}/`

**Description**: Détails d'un utilisateur spécifique
**URL Freebox** : `http://91.171.4.184:28014/api/admin/users/{id}/`  
**URL Local** : `http://localhost:8014/api/admin/users/{id}/`

**Authentification** : Requise (Admin)

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
  "is_active": true,
  "is_staff": false,
  "is_superuser": false,
  "phone_number": "+33123456789",
  "city": "Paris",
  "country": "France",
  "postal_code": "75001",
  "region": "Île-de-France",
  "street": "Rue de la Paix",
  "street_number": "123",
  "address_complement": "Apt 123",
  "date_of_birth": "1990-01-01"
}
```

**Tables Sources**: `accounts_user`

---

### PUT `/users/{id}/`

**Description**: Mise à jour d'un utilisateur
**URL Freebox** : `http://91.171.4.184:28014/api/admin/users/{id}/`  
**URL Local** : `http://localhost:8014/api/admin/users/{id}/`

**Authentification** : Requise (Admin)

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "first_name": "John",
  "last_name": "Doe Updated",
  "is_active": true,
  "city": "Lyon"
}
```

**Response Success (200)**:
```json
{
  "id": 1,
  "email": "user@example.com",
  "first_name": "John",
  "last_name": "Doe Updated",
  "is_active": true,
  "city": "Lyon"
}
```

**Tables Sources**: `accounts_user`

---

### PUT `/users/{id}/ban/`

**Description**: Bannir un utilisateur
**URL Freebox** : `http://91.171.4.184:28014/api/admin/users/{id}/ban/`  
**URL Local** : `http://localhost:8014/api/admin/users/{id}/ban/`

**Authentification** : Requise (Admin)

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
{
  "message": "User banned."
}
```

**Tables Sources**: `accounts_user`

---

### PUT `/users/{id}/unban/`

**Description**: Débannir un utilisateur
**URL Freebox** : `http://91.171.4.184:28014/api/admin/users/{id}/unban/`  
**URL Local** : `http://localhost:8014/api/admin/users/{id}/unban/`

**Authentification** : Requise (Admin)

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
{
  "message": "User unbanned."
}
```

**Tables Sources**: `accounts_user`

---

### DELETE `/users/{id}/`

**Description**: Suppression d'un utilisateur
**URL Freebox** : `http://91.171.4.184:28014/api/admin/users/{id}/`  
**URL Local** : `http://localhost:8014/api/admin/users/{id}/`

**Authentification** : Requise (Admin)

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (204)**:
```
No Content
```

**Tables Sources**: `accounts_user`

---

### GET `/bakers/`

**Description**: Liste des pâtissiers (Admin seulement)
**URL Freebox** : `http://91.171.4.184:28014/api/admin/bakers/`  
**URL Local** : `http://localhost:8014/api/admin/bakers/`

**Authentification** : Requise (Admin)

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
[
  {
    "id": 1,
    "user_id": 2,
    "description": "Pâtissière passionnée depuis 10 ans",
    "experience": "10 ans d'expérience",
    "average_rating": 4.8,
    "location": "Paris, France",
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
]
```

**Tables Sources**: `baker`

---

### GET `/bakers/pending/`

**Description**: Liste des pâtissiers en attente de vérification
**URL Freebox** : `http://91.171.4.184:28014/api/admin/bakers/pending/`  
**URL Local** : `http://localhost:8014/api/admin/bakers/pending/`

**Authentification** : Requise (Admin)

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
[
  {
    "id": 2,
    "user_id": 3,
    "description": null,
    "experience": null,
    "average_rating": null,
    "location": null,
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
]
```

**Tables Sources**: `baker`

---

### PUT `/bakers/{id}/verify/`

**Description**: Vérifier un pâtissier
**URL Freebox** : `http://91.171.4.184:28014/api/admin/bakers/{id}/verify/`  
**URL Local** : `http://localhost:8014/api/admin/bakers/{id}/verify/`

**Authentification** : Requise (Admin)

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
{
  "message": "Baker verified."
}
```

**Tables Sources**: `baker`

---

### PUT `/bakers/{id}/suspend/`

**Description**: Suspendre un pâtissier
**URL Freebox** : `http://91.171.4.184:28014/api/admin/bakers/{id}/suspend/`  
**URL Local** : `http://localhost:8014/api/admin/bakers/{id}/suspend/`

**Authentification** : Requise (Admin)

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
{
  "message": "Baker suspended."
}
```

**Tables Sources**: `baker`

---

### GET `/products/`

**Description**: Liste des produits (Admin seulement)
**URL Freebox** : `http://91.171.4.184:28014/api/admin/products/`  
**URL Local** : `http://localhost:8014/api/admin/products/`

**Authentification** : Requise (Admin)

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
[
  {
    "id": 1,
    "name": "Gâteau au chocolat",
    "description": "Délicieux gâteau au chocolat",
    "dimensions": "20x20cm",
    "price": 25.50,
    "preparation_time": 24,
    "is_refrigerated": true,
    "expiration_date": "2024-01-20",
    "available_from": "2024-01-15T00:00:00Z",
    "available_to": "2024-01-20T23:59:59Z",
    "average_rating": 4.5,
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
]
```

**Tables Sources**: `product`

---

### GET `/products/reported/`

**Description**: Liste des produits signalés
**URL Freebox** : `http://91.171.4.184:28014/api/admin/products/reported/`  
**URL Local** : `http://localhost:8014/api/admin/products/reported/`

**Authentification** : Requise (Admin)

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
[
  {
    "id": 5,
    "name": "Produit signalé",
    "description": "Description",
    "price": 10.00,
    "average_rating": 0.5,
    "created_at": "2024-01-15T10:30:00Z"
  }
]
```

**Tables Sources**: `product`

---

### PUT `/products/{id}/feature/`

**Description**: Mettre en avant un produit
**URL Freebox** : `http://91.171.4.184:28014/api/admin/products/{id}/feature/`  
**URL Local** : `http://localhost:8014/api/admin/products/{id}/feature/`

**Authentification** : Requise (Admin)

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
{
  "message": "Product featured."
}
```

**Tables Sources**: `product`

---

### DELETE `/products/{id}/`

**Description**: Suppression d'un produit
**URL Freebox** : `http://91.171.4.184:28014/api/admin/products/{id}/`  
**URL Local** : `http://localhost:8014/api/admin/products/{id}/`

**Authentification** : Requise (Admin)

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (204)**:
```
No Content
```

**Tables Sources**: `product`

---

### GET `/orders/`

**Description**: Liste des commandes (Admin seulement)
**URL Freebox** : `http://91.171.4.184:28014/api/admin/orders/`  
**URL Local** : `http://localhost:8014/api/admin/orders/`

**Authentification** : Requise (Admin)

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
[
  {
    "id": 12345,
    "user_id": 1,
    "total_price": 58.00,
    "tax_included": true,
    "status": "pending",
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
]
```

**Tables Sources**: `orders`

---

### GET `/kpis/`

**Description**: Récupération des indicateurs clés de performance
**URL Freebox** : `http://91.171.4.184:28014/api/admin/kpis/`  
**URL Local** : `http://localhost:8014/api/admin/kpis/`

**Authentification** : Requise (Admin)

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
{
  "total_users": 1000,
  "total_bakers": 50,
  "total_products": 500,
  "orders": 2500,
  "revenue_total": 125000.00
}
```

**Tables Sources**: `accounts_user`, `baker`, `product`, `orders`

---

### GET `/reports/revenue/`

**Description**: Rapport de revenus
**URL Freebox** : `http://91.171.4.184:28014/api/admin/reports/revenue/`  
**URL Local** : `http://localhost:8014/api/admin/reports/revenue/`

**Authentification** : Requise (Admin)

**Headers**:
```
Authorization: Bearer <access_token>
```

**Query Parameters**:
- `start_date`: Date de début (format: YYYY-MM-DD)
- `end_date`: Date de fin (format: YYYY-MM-DD)
- `baker_id`: ID du pâtissier (optionnel)
- `product_id`: ID du produit (optionnel)

**Response Success (200)**:
```json
{
  "revenue_total": 125000.00
}
```

**Tables Sources**: `orders`

---

### GET `/reports/users/`

**Description**: Rapport sur les utilisateurs
**URL Freebox** : `http://91.171.4.184:28014/api/admin/reports/users/`  
**URL Local** : `http://localhost:8014/api/admin/reports/users/`

**Authentification** : Requise (Admin)

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
{
  "total_users": 1000,
  "staff_users": 10
}
```

**Tables Sources**: `accounts_user`

---

### GET `/reports/products/`

**Description**: Rapport sur les produits
**URL Freebox** : `http://91.171.4.184:28014/api/admin/reports/products/`  
**URL Local** : `http://localhost:8014/api/admin/reports/products/`

**Authentification** : Requise (Admin)

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
{
  "total_products": 500,
  "avg_rating": 4.2
}
```

**Tables Sources**: `product`





