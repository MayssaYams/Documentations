# Product Service API Documentation

**Base URL Freebox** : `http://91.171.4.184:28006/api/products/`
**Base URL Local** : `http://localhost:8006/api/products/`

## Endpoints

### GET `/`

**Description**: Liste des produits avec pagination et filtres
**URL Freebox** : `http://91.171.4.184:28006/api/products/`  
**URL Local** : `http://localhost:8006/api/products/`

**Authentification** : Non requise (accès public)

**Note** : Cet endpoint est accessible sans authentification. Tous les utilisateurs (authentifiés ou non) peuvent consulter la liste des produits.

**Champ supplémentaire** : `subtitle` (texte libre) est renvoyé sur chaque produit pour afficher un court sous-titre marketing.


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
  "next": "http://localhost:8006/api/products/?page=2",
  "previous": null,
  "results": [
    {
      "id": 1,
      "name": "Gâteau au chocolat",
      "description": "Délicieux gâteau au chocolat fait maison",
      "subtitle": "Version signature au cœur coulant",
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

**Description**: Détails d\'un produit spécifique
**URL Freebox** : `http://91.171.4.184:28006/api/products/{id}/`
**URL Local** : `http://localhost:8006/api/products/{id}/`

**Authentification** : Non requise (accès public)

**Note** : Cet endpoint est accessible sans authentification. Tous les utilisateurs (authentifiés ou non) peuvent consulter les détails d'un produit.

**Champ supplémentaire** : `subtitle` (texte libre) permet d'afficher un petit descriptif marketing complémentaire au `description`.

**Response Success (200)**:
```json
{
  "id": 1,
  "name": "Gâteau au chocolat",
  "description": "Délicieux gâteau au chocolat fait maison",
  "subtitle": "Version signature au cœur coulant",
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

### GET `/baker/<baker_id>/`

**Description**: Liste des produits associés à un pâtissier spécifique
**URL Freebox** : `http://91.171.4.184:28006/api/products/baker/<baker_id>/`
**URL Local** : `http://localhost:8006/api/products/baker/<baker_id>/`

**Authentification** : Non requise (accès public)

**Note** : Cet endpoint est accessible sans authentification. Tous les utilisateurs (authentifiés ou non) peuvent consulter la liste des produits d'un pâtissier spécifique.

**Path Parameters**:
- `baker_id` (requis) : ID du pâtissier (entier)

**Response Success (200)**:
```json
[
  {
    "id": 1,
    "name": "Gâteau au chocolat",
    "description": "Délicieux gâteau au chocolat fait maison",
    "price": 25.50,
    "dimensions": "20x20cm",
    "preparation_time": 2,
    "is_refrigerated": true,
    "expiration_date": "2024-01-20",
    "available_from": "2024-01-15",
    "available_to": "2024-01-25",
    "average_rating": 4.5,
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-15T10:30:00Z",
    "location": null,
    "views_count": 150,
    "favorites_count": 25,
    "orders_count": 12,
    "reviews_count": 8
  }
]
```

**Response Success (200)** - Aucun produit trouvé :
```json
[]
```

**Response Error (400)** - Format de `baker_id` invalide :
```json
{
  "error": "Invalid baker_id format. Must be an integer."
}
```

**Notes**:
- Retourne une liste vide si le baker n'existe pas ou n'a aucun produit
- Les produits sont triés par date de création décroissante (`created_at DESC`)
- L'endpoint utilise une requête SQL directe pour filtrer par `baker_id` car ce champ n'est pas exposé dans le modèle Django

**Tables Sources**: `product`


---

### POST `/`

**Description**: Création d\'un nouveau produit
**URL Freebox** : `http://91.171.4.184:28006/api/products/`
**URL Local** : `http://localhost:8006/api/products/`

**Authentification** : Requise (Admin ou Baker uniquement)

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Permissions** :
- **Admin (group_id = 1)** : Peut créer un produit pour n'importe quel baker existant
- **Baker (group_id = 3 ou 4)** : Peut créer un produit uniquement pour son propre compte baker
- **Autres utilisateurs** : Accès refusé (403 Forbidden)

**Règles importantes** :
- Le champ `baker_id` est **obligatoire** pour tous (admin et baker)
- Un admin doit spécifier un `baker_id` valide d'un baker existant
- Un baker doit spécifier son propre `baker_id` (vérification automatique)
- La relation `ProductUser` est créée automatiquement avec le `user_id` du baker
- Un admin ne peut jamais être associé à un produit (pas de `ProductUser` pour les admins)

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

**Response Error (400)** - `baker_id` manquant :
```json
{
  "error": "baker_id is required"
}
```

**Response Error (400)** - `baker_id` invalide :
```json
{
  "error": "Baker with id {id} does not exist"
}
```

**Response Error (400)** - Baker sans `userid` :
```json
{
  "error": "Baker {id} does not have an associated user"
}
```

**Response Error (403)** - Baker tentant de créer pour un autre baker :
```json
{
  "error": "You can only create products for your own baker account"
}
```

**Response Error (403)** - Utilisateur non autorisé :
```json
{
  "error": "You do not have permission to create products"
}
```

**Response Error (500)** - Erreur lors de la création de la relation `ProductUser` :
```json
{
  "error": "Error creating product-user relation: {error_message}"
}
```

**Tables Sources**: `product`, `product_variant`, `product_image`, `product_allergen`, `product_category`, `product_user`

---

### PUT `/{id}/`

**Description**: Mise à jour d'un produit
**URL Freebox** : `http://91.171.4.184:28006/api/products/{id}/`  
**URL Local** : `http://localhost:8006/api/products/{id}/`

**Authentification** : Requise (Admin ou Baker uniquement)

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Permissions** :
- **Admin (group_id = 1)** : Peut modifier tous les champs d'un produit **SAUF** `baker_id` (même si présent dans la requête, retourne 400)
- **Baker (group_id = 3 ou 4)** : Peut modifier uniquement ses propres produits (vérification via `ProductUser`)
- **Autres utilisateurs** : Accès refusé (403 Forbidden)

**Règles importantes** :
- Un admin **NE PEUT PAS** modifier le `baker_id` d'un produit (même un admin)
- Un baker ne peut modifier que les produits qui lui appartiennent (vérification via la relation `ProductUser`)
- Si un baker tente de modifier un produit qui ne lui appartient pas : 403 Forbidden

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

**Response Error (400)** - Tentative de modification de `baker_id` par un admin :
```json
{
  "error": "baker_id cannot be modified, even by administrators"
}
```

**Response Error (403)** - Baker tentant de modifier un produit qui ne lui appartient pas :
```json
{
  "error": "You can only modify your own products"
}
```

**Response Error (403)** - Produit sans propriétaire :
```json
{
  "error": "This product has no owner"
}
```

**Tables Sources**: `product`

---

### DELETE `/{id}/`

**Description**: Suppression d'un produit
**URL Freebox** : `http://91.171.4.184:28006/api/products/{id}/`  
**URL Local** : `http://localhost:8006/api/products/{id}/`

**Authentification** : Requise (Admin ou Baker uniquement)

**Headers**:
```
Authorization: Bearer <access_token>
```

**Permissions** :
- **Admin (group_id = 1)** : Peut supprimer n'importe quel produit
- **Baker (group_id = 3 ou 4)** : Peut supprimer uniquement ses propres produits (vérification via `ProductUser`)
- **Autres utilisateurs** : Accès refusé (403 Forbidden)

**Règles importantes** :
- Un baker ne peut supprimer que les produits qui lui appartiennent (vérification via la relation `ProductUser`)
- Si un baker tente de supprimer un produit qui ne lui appartient pas : 403 Forbidden
- La suppression d'un produit supprime automatiquement toutes les relations associées (CASCADE) :
  - `product_user`
  - `product_variant`
  - `product_image`
  - `product_category`
  - `product_allergen`
  - `product_quantity_rule`
  - Et toutes les autres tables avec FK vers `product`

**Response Success (204)**:
```
No Content
```

**Response Error (403)** - Baker tentant de supprimer un produit qui ne lui appartient pas :
```json
{
  "error": "You can only delete your own products"
}
```

**Response Error (403)** - Produit sans propriétaire :
```json
{
  "error": "This product has no owner"
}
```

**Tables Sources**: `product` (et toutes les tables avec FK CASCADE)

---

### POST `/variants/`

**Description**: Création de variantes de produit
**URL Freebox** : `http://91.171.4.184:28006/api/products/variants/`  
**URL Local** : `http://localhost:8006/api/products/variants/`

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
**URL Freebox** : `http://91.171.4.184:28006/api/products/categories/`  
**URL Local** : `http://localhost:8006/api/products/categories/`

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

**Description**: Création d'images de produit (enregistrement et proxy)
**URL Freebox** : `http://91.171.4.184:28006/api/products/images/`  
**URL Local** : `http://localhost:8006/api/products/images/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body (contrat simplifié)**:
```json
{
  "product_id": 1,
  "imageurl": "temp/gateau-side.jpg",
  "format": "jpg"
}
```

**Comportement** :

- Le front-end envoie uniquement le path relatif de l'image dans `imageurl`.
- Le service :
  - extrait automatiquement le `filename` depuis `imageurl` (dernière partie après `/`),
  - détermine le `baker_id` propriétaire du produit,
  - construit une clé de stockage : `bakerId/productId/filename` (ex: `5/10/gateau-side.jpg`),
  - copie physiquement l'image depuis `PRODUCT_IMAGES_ROOT + imageurl` vers l'emplacement de stockage :
    - **Freebox** : dans le dossier monté côté conteneur (`PRODUCT_IMAGES_ROOT/bakerId/productId/filename`),
    - **Production** : dans un bucket S3 privé (`s3://PRODUCT_IMAGES_S3_BUCKET/bakerId/productId/filename`),
  - crée une entrée `product_image` avec `imageurl = "bakerId/productId/filename"`.

**Response Success (201)** (exemple simplifié) :
```json
{
  "id": 2,
  "productid": 1,
  "imageurl": "5/10/gateau-side.jpg",
  "format": "jpg",
  "created_at": "2024-01-15T10:30:00Z",
  "public_url": "/api/products/images/5/10/gateau-side.jpg"
}
```

**Notes** :

- Le champ `imageurl` stocke la **clé de stockage** (et non plus une URL complète).
- Le champ `public_url` fournit l'URL HTTP du proxy d'image (même forme en Freebox et en production).

**Tables Sources**: `product_image`

---

### PUT `/{product_id}/images/`

**Description**: Mise à jour d'une image de produit
**URL Freebox** : `http://91.171.4.184:28006/api/products/{product_id}/images/`  
**URL Local** : `http://localhost:8006/api/products/{product_id}/images/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "imageurl": "temp/updated-image.jpg",
  "format": "jpg"
}
```

**Comportement** :
- Même logique que POST, mais pour remplacer l'image existante d'un produit.
- Le service détermine automatiquement le baker propriétaire et génère la nouvelle clé de stockage.
- L'ancienne image (si elle existe) peut être conservée ou supprimée selon la logique métier.

**Response Success (200)**:
```json
{
  "id": 2,
  "productid": 1,
  "imageurl": "5/10/updated-image.jpg",
  "format": "jpg",
  "created_at": "2024-01-15T10:30:00Z",
  "public_url": "/api/products/images/5/10/updated-image.jpg"
}
```

**Tables Sources**: `product_image`

---

### GET `/{product_id}/images/`

**Description**: Récupération de la liste des images d'un produit
**URL Freebox** : `http://91.171.4.184:28006/api/products/{product_id}/images/`  
**URL Local** : `http://localhost:8006/api/products/{product_id}/images/`

**Authentification** : Non requise (accès public)

**Response Success (200)**:
```json
[
  {
    "id": 1,
    "productid": 123,
    "imageurl": "5/123/image1.jpg",
    "format": "jpg",
    "created_at": "2024-01-15T10:30:00Z",
    "public_url": "/api/products/images/5/123/image1.jpg"
  },
  {
    "id": 2,
    "productid": 123,
    "imageurl": "5/123/image2.png",
    "format": "png",
    "created_at": "2024-01-15T11:00:00Z",
    "public_url": "/api/products/images/5/123/image2.png"
  }
]
```

**Response Error (404)** - Produit non trouvé:
```json
{
  "detail": "Product not found"
}
```

**Notes**:
- Retourne une liste vide si le produit n'a pas d'images.
- Les images sont triées par date de création décroissante (plus récentes en premier).
- Chaque image inclut un `public_url` pour accéder directement au fichier via le proxy.

**Tables Sources**: `product_image`

---

### GET `/images/<bakerId>/<productId>/<filename>`

**Description**: Récupération publique d'une image via proxy HTTP
**URL Freebox** : `http://91.171.4.184:28006/api/products/images/<bakerId>/<productId>/<filename>`  
**URL Local** : `http://localhost:8006/api/products/images/<bakerId>/<productId>/<filename>`

**Authentification** : Non requise (accès public)

**Notes** :

- **Freebox** :
  - lit le fichier depuis le système de fichiers local du conteneur (`PRODUCT_IMAGES_ROOT`), lui-même monté depuis la Freebox (ex: `/mnt/freebox_images` → `/app/product_images`),
  - renvoie le contenu binaire avec un `Content-Type` basé sur l'extension (via `mimetypes`).
- **Production** :
  - lit le fichier depuis un bucket S3 privé (accessible uniquement depuis le VPC),
  - le service API agit comme **proxy** et streame les octets au client,
  - aucune URL publique S3 n'est exposée.

**Response Success (200)** :
- Contenu binaire de l'image (`image/jpeg`, `image/png`, etc.).

**Response Error (404)** :
```json
{
  "detail": "Not found."
}
```

**Tables Sources**: `product_image` + stockage fichier (FS local ou S3)

---

### POST `/allergens/`

**Description**: Création d'allergènes
**URL Freebox** : `http://91.171.4.184:28006/api/products/allergens/`  
**URL Local** : `http://localhost:8006/api/products/allergens/`

**Authentification** : Requise

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
**URL Freebox** : `http://91.171.4.184:28006/api/products/quantity-rules/`  
**URL Local** : `http://localhost:8006/api/products/quantity-rules/`

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
**URL Freebox** : `http://91.171.4.184:28006/api/products/{id}/history/`  
**URL Local** : `http://localhost:8006/api/products/{id}/history/`

**Authentification** : Non requise (accès public)

**Note** : Cet endpoint est accessible sans authentification. Tous les utilisateurs (authentifiés ou non) peuvent consulter l'historique d'un produit.

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
**URL Freebox** : `http://91.171.4.184:28006/api/products/full_product/`  
**URL Local** : `http://localhost:8006/api/products/full_product/`

**Authentification** : Requise

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

**Description**: Récupération d\'un produit complet avec toutes ses relations
**URL Freebox** : `http://91.171.4.184:28006/api/products/{id}/full_product/`
**URL Local** : `http://localhost:8006/api/products/{id}/full_product/`

**Authentification** : Non requise (accès public)

**Note** : Cet endpoint est accessible sans authentification. Tous les utilisateurs (authentifiés ou non) peuvent consulter un produit complet avec toutes ses relations.

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

## Architecture des Permissions

### Vue d'ensemble

Le service Product utilise un système de permissions à deux niveaux :

1. **Permission au niveau de la vue** (`ProductPermission`) : Vérifie l'authentification et le groupe utilisateur
2. **Permission au niveau de l'objet** (`ProductObjectPermission`) : Vérifie la propriété du produit

### Règles de permissions

#### Accès en lecture (GET, HEAD, OPTIONS)
- **Public** : Aucune authentification requise
- **Endpoints concernés** :
  - `GET /api/products/` : Liste des produits
  - `GET /api/products/{id}/` : Détail d'un produit
  - `GET /api/products/{id}/full_product/` : Produit complet
  - `GET /api/products/baker/<baker_id>/` : Liste des produits d'un pâtissier
  - `GET /api/products/{id}/history/` : Historique

#### Accès en écriture (POST, PUT, PATCH, DELETE)
- **Authentification requise** : Oui
- **Groupes autorisés** : Admin (group_id = 1), Baker (group_id = 3 ou 4)
- **Autres utilisateurs** : 403 Forbidden

### Règles spécifiques par opération

#### Création (POST)
- **`baker_id` obligatoire** : Doit être fourni dans le body
- **Admin** : Peut créer un produit pour n'importe quel baker existant
- **Baker** : Peut créer un produit uniquement pour son propre compte (vérification automatique)
- **Relation `ProductUser`** : Créée automatiquement avec le `user_id` du baker (jamais avec l'admin)

#### Modification (PUT/PATCH)
- **Admin** :
  - Peut modifier tous les champs d'un produit
  - **NE PEUT PAS** modifier le `baker_id` (retourne 400 si tenté)
- **Baker** :
  - Peut modifier uniquement ses propres produits
  - Vérification via la relation `ProductUser`
  - Si le produit ne lui appartient pas : 403 Forbidden

#### Suppression (DELETE)
- **Admin** : Peut supprimer n'importe quel produit
- **Baker** : Peut supprimer uniquement ses propres produits (vérification via `ProductUser`)
- **CASCADE** : La suppression supprime automatiquement toutes les relations FK

### Modèle de données - Relations

#### Table `product_user`
- **Relation** : OneToOne entre `Product` et `AccountsUser`
- **Clé primaire** : `product_id`
- **Champ** : `user_id` (référence à `AccountsUser`)
- **Rôle** : Détermine le propriétaire du produit
- **Règle** : Un admin ne peut jamais être associé à un produit (pas de `ProductUser` pour group_id = 1)

#### Table `baker`
- **Champ** : `userid` (référence à `AccountsUser`)
- **Rôle** : Lien entre un utilisateur et son compte baker
- **Utilisation** : Pour valider que `baker_id` correspond à un baker existant

### Codes d'erreur

| Code | Signification | Cas d'usage |
|------|---------------|-------------|
| 200 | OK | Modification réussie, récupération réussie |
| 201 | Created | Création réussie |
| 204 | No Content | Suppression réussie |
| 400 | Bad Request | `baker_id` manquant, `baker_id` invalide, tentative de modification de `baker_id` par admin |
| 401 | Unauthorized | Utilisateur non authentifié pour opération nécessitant authentification |
| 403 | Forbidden | Baker tentant de modifier/supprimer un produit qui ne lui appartient pas, utilisateur non autorisé |
| 404 | Not Found | Produit, baker ou ressource non trouvé |
| 500 | Internal Server Error | Erreur serveur lors de la création de la relation `ProductUser` |

---