# Favorite Service API Documentation

**Base URL Freebox** : `http://91.171.4.184:28009/api/favorites/`
**Base URL Local** : `http://localhost:8009/api/favorites/`

## Endpoints

### GET `/`

**Description**: Liste des favoris de l'utilisateur connecté
**URL Freebox** : `http://91.171.4.184:28009/api/favorites/`  
**URL Local** : `http://localhost:8009/api/favorites/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
[
  {
    "user": 1,
    "user_id": 1,
    "user_email": "user@example.com",
    "product": {
      "id": 1,
      "name": "Gâteau au chocolat",
      "description": "Délicieux gâteau au chocolat",
      "price": 25.50,
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-15T10:30:00Z"
    },
    "product_id": 1,
    "added_at": "2024-01-15T10:30:00Z",
    "notes": "À essayer pour l'anniversaire",
    "is_public": false,
    "sort_order": 1
  }
]
```

**Tables Sources**: `user_favoris`, `product`

---

### POST `/`

**Description**: Ajout d'un produit aux favoris
**URL Freebox** : `http://91.171.4.184:28009/api/favorites/`  
**URL Local** : `http://localhost:8009/api/favorites/`

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
  "notes": "À essayer pour l'anniversaire",
  "is_public": false,
  "sort_order": 1
}
```

**Response Success (201)**:
```json
{
  "user": 1,
  "user_id": 1,
  "product": {
    "id": 1,
    "name": "Gâteau au chocolat",
    "price": 25.50
  },
  "product_id": 1,
  "added_at": "2024-01-15T10:30:00Z",
  "notes": "À essayer pour l'anniversaire",
  "is_public": false,
  "sort_order": 1
}
```

**Response Error (409)**:
```json
{
  "error": "Product is already in favorites"
}
```

**Tables Sources**: `user_favoris`, `product`

---

### GET `/{id}/`

**Description**: Détails d'un favori spécifique
**URL Freebox** : `http://91.171.4.184:28009/api/favorites/{id}/`  
**URL Local** : `http://localhost:8009/api/favorites/{id}/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
{
  "user": 1,
  "user_id": 1,
  "product": {
    "id": 1,
    "name": "Gâteau au chocolat",
    "price": 25.50
  },
  "product_id": 1,
  "added_at": "2024-01-15T10:30:00Z",
  "notes": "À essayer pour l'anniversaire",
  "is_public": false,
  "sort_order": 1
}
```

**Tables Sources**: `user_favoris`, `product`

---

### DELETE `/{id}/`

**Description**: Suppression d'un favori
**URL Freebox** : `http://91.171.4.184:28009/api/favorites/{id}/`  
**URL Local** : `http://localhost:8009/api/favorites/{id}/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (204)**:
```
No Content
```

**Tables Sources**: `user_favoris`

---

### GET `/groups/`

**Description**: Liste des groupes de favoris de l'utilisateur
**URL Freebox** : `http://91.171.4.184:28009/api/favorites/groups/`  
**URL Local** : `http://localhost:8009/api/favorites/groups/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
[
  {
    "id": 1,
    "user": 1,
    "user_id": 1,
    "user_email": "user@example.com",
    "name": "Gâteaux d'anniversaire",
    "description": "Pour les anniversaires",
    "color": "#FF5733",
    "icon": "cake",
    "is_public": false,
    "is_default": false,
    "sort_order": 1,
    "items_count": 5,
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z",
    "items": []
  }
]
```

**Tables Sources**: `favorite_groups`

---

### POST `/groups/`

**Description**: Création d'un groupe de favoris
**URL Freebox** : `http://91.171.4.184:28009/api/favorites/groups/`  
**URL Local** : `http://localhost:8009/api/favorites/groups/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "name": "Gâteaux d'anniversaire",
  "description": "Pour les anniversaires",
  "color": "#FF5733",
  "icon": "cake",
  "is_public": false,
  "is_default": false,
  "sort_order": 1
}
```

**Response Success (201)**:
```json
{
  "id": 1,
  "user": 1,
  "user_id": 1,
  "name": "Gâteaux d'anniversaire",
  "description": "Pour les anniversaires",
  "color": "#FF5733",
  "icon": "cake",
  "is_public": false,
  "is_default": false,
  "sort_order": 1,
  "items_count": 0,
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

**Tables Sources**: `favorite_groups`

---

### POST `/groups/{id}/items/`

**Description**: Ajout d'un produit à un groupe de favoris
**URL Freebox** : `http://91.171.4.184:28009/api/favorites/groups/{id}/items/`  
**URL Local** : `http://localhost:8009/api/favorites/groups/{id}/items/`

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
  "notes": "Pour l'anniversaire de Marie",
  "sort_order": 1
}
```

**Response Success (201)**:
```json
{
  "id": 1,
  "group": 1,
  "product": {
    "id": 1,
    "name": "Gâteau au chocolat",
    "price": 25.50
  },
  "product_id": 1,
  "added_at": "2024-01-15T10:30:00Z",
  "notes": "Pour l'anniversaire de Marie",
  "sort_order": 1
}
```

**Tables Sources**: `favorite_group_items`, `favorite_groups`, `product`

---

### DELETE `/groups/{id}/items/{item_id}/`

**Description** : Retirer un produit d’un groupe de favoris.

**URL Freebox** : `http://91.171.4.184:28009/api/favorites/groups/{id}/items/{item_id}/`  
**URL Local** : `http://localhost:8009/api/favorites/groups/{id}/items/{item_id}/`

**Authentification** : Requise

**Response Success (204)** : Pas de contenu.

**Tables Sources** : `favorite_group_items`, `favorite_groups`

---

### DELETE `/by-product/{product_id}/`

**Description** : Supprimer le favori « plat » (hors groupe) associé à un `product_id` pour l’utilisateur connecté.

**URL Freebox** : `http://91.171.4.184:28009/api/favorites/by-product/{product_id}/`  
**URL Local** : `http://localhost:8009/api/favorites/by-product/{product_id}/`

**Authentification** : Requise

**Response Success (204)** : Pas de contenu.

**Tables Sources** : `user_favoris`





