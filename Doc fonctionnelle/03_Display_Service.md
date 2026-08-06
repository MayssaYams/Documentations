# Display Service API Documentation

**Base URL Freebox** : `http://91.171.4.184:28003/api/display/`
**Base URL Local** : `http://localhost:8003/api/display/`

**Préfixe réel des routes produit** : `api/display/products/` (router Django REST). Les actions `nearby/*` et `home/payload` sont exposées sous ce préfixe.

## Endpoints

### GET `/products/home/payload/`

**Description** : Payload paginé pour l’écran d’accueil (liste de produits actifs avec baker, images, catégories ; si l’utilisateur est authentifié, indicateur `is_favorite`).

**URL Freebox** : `http://91.171.4.184:28003/api/display/products/home/payload/`  
**URL Local** : `http://localhost:8003/api/display/products/home/payload/`

**Authentification** : Optionnelle (JWT si fourni : favoris par utilisateur ; coordonnées optionnelles pour distance).

**Query parameters** : `page` (défaut 1), `page_size` (défaut 12, max 50), `lat`, `lon` (optionnels, pour `distance_km` et localisation baker).

**Note** : La route est également déclarée explicitement dans `core/urls.py` ; le comportement est celui de l’action `home_screen_payload` du `ProductViewSet`.

---

### GET `/products/{id}/full/`

**Description** : Détail enrichi d’un produit pour affichage (lecture seule, SQL agrégé).

**URL Freebox** : `http://91.171.4.184:28003/api/display/products/{id}/full/`  
**URL Local** : `http://localhost:8003/api/display/products/{id}/full/`

**Authentification** : Non requise (JWT optionnel selon configuration du ViewSet).

---

### POST `/products/nearby/nolat/`

**Description**: Récupère les produits triés par distance par rapport à un point donné
**URL Freebox** : `http://91.171.4.184:28003/api/display/products/nearby/nolat/`  
**URL Local** : `http://localhost:8003/api/display/products/nearby/nolat/`

**Authentification** : Non requise

**Headers**:
```
Content-Type: application/json
```

**Body**:
```json
{
  "lat": 48.8566,
  "lon": 2.3522,
  "distance": 10,
  "limit": 20,
  "offset": 0,
  "filters": {
    "min_price": 10,
    "max_price": 50,
    "categories": [1, 2],
    "allergens": [1],
    "is_featured": true
  },
  "ordering": "distance"
}
```

**Response Success (200)**:
```json
[
  {
    "product_id": 1,
    "product_name": "Gâteau au chocolat",
    "product_description": "Délicieux gâteau au chocolat fait maison",
    "product_price": 25.50,
    "product_image_url": "https://example.com/product1.jpg",
    "product_rating": 4.5,
    "product_reviews_count": 8,
    "product_is_featured": true,
    "product_is_available": true,
    "product_stock_quantity": 10,
    "baker_id": 1,
    "baker_name": "Marie Dupont",
    "baker_business_name": "Pâtisserie Marie",
    "baker_description": "Pâtissière passionnée depuis 10 ans",
    "baker_is_verified": true,
    "baker_average_rating": 4.8,
    "baker_profile_image_url": "https://example.com/baker.jpg",
    "baker_phone_number": "+33123456789",
    "baker_email": "marie@patisserie.com",
    "baker_years_experience": 10,
    "baker_delivery_radius": 15,
    "baker_min_order_amount": 20.00,
    "baker_delivery_fee": 5.00,
    "baker_preparation_time_hours": 24,
    "distance_km": 2.5,
    "estimated_delivery_time": "2-3 heures",
    "delivery_fee": 5.00,
    "min_order_amount": 20.00
  },
  {
    "product_id": 2,
    "product_name": "Tarte aux fraises",
    "product_description": "Tarte aux fraises fraîches de saison",
    "product_price": 18.00,
    "product_image_url": "https://example.com/product2.jpg",
    "product_rating": 4.2,
    "product_reviews_count": 12,
    "product_is_featured": false,
    "product_is_available": true,
    "product_stock_quantity": 5,
    "baker_id": 2,
    "baker_name": "Pierre Martin",
    "baker_business_name": "Pâtisserie Pierre",
    "baker_description": "Spécialiste des tartes aux fruits",
    "baker_is_verified": true,
    "baker_average_rating": 4.6,
    "baker_profile_image_url": "https://example.com/baker2.jpg",
    "baker_phone_number": "+33987654321",
    "baker_email": "pierre@patisserie.com",
    "baker_years_experience": 8,
    "baker_delivery_radius": 10,
    "baker_min_order_amount": 15.00,
    "baker_delivery_fee": 3.00,
    "baker_preparation_time_hours": 20,
    "distance_km": 3.8,
    "estimated_delivery_time": "1-2 heures",
    "delivery_fee": 3.00,
    "min_order_amount": 15.00
  }
]
```

**Tables Sources**: `product`, `product_image`, `baker`, `accounts_user`

---

### POST `/products/nearby/connected/`

**Description**: Utilise la localisation de l'utilisateur connecté pour récupérer les produits
**URL Freebox** : `http://91.171.4.184:28003/api/display/products/nearby/connected/`  
**URL Local** : `http://localhost:8003/api/display/products/nearby/connected/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "distance": 10,
  "limit": 20,
  "offset": 0,
  "filters": {
    "min_price": 10,
    "max_price": 50,
    "categories": [1, 2],
    "allergens": [1],
    "is_featured": true
  },
  "ordering": "distance"
}
```

**Response Success (200)**:
```json
[
  {
    "product_id": 1,
    "product_name": "Gâteau au chocolat",
    "product_description": "Délicieux gâteau au chocolat fait maison",
    "product_price": 25.50,
    "product_image_url": "https://example.com/product1.jpg",
    "product_rating": 4.5,
    "product_reviews_count": 8,
    "product_is_featured": true,
    "product_is_available": true,
    "product_stock_quantity": 10,
    "baker_id": 1,
    "baker_name": "Marie Dupont",
    "baker_business_name": "Pâtisserie Marie",
    "baker_description": "Pâtissière passionnée depuis 10 ans",
    "baker_is_verified": true,
    "baker_average_rating": 4.8,
    "baker_profile_image_url": "https://example.com/baker.jpg",
    "baker_phone_number": "+33123456789",
    "baker_email": "marie@patisserie.com",
    "baker_years_experience": 10,
    "baker_delivery_radius": 15,
    "baker_min_order_amount": 20.00,
    "baker_delivery_fee": 5.00,
    "baker_preparation_time_hours": 24,
    "distance_km": 2.5,
    "estimated_delivery_time": "2-3 heures",
    "delivery_fee": 5.00,
    "min_order_amount": 20.00
  }
]
```

**Tables Sources**: `product`, `product_image`, `baker`, `accounts_user`

---

### GET `/products/home/payload/`

**Description**: Renvoie un payload unique pour la page d’accueil (produits paginés + métadonnées, agilités, favoris et filtres) conformément à [home_screen_data_requirements.md](./Doc agent service/home_screen_data_requirements.md).
**URL Freebox** : `http://91.171.4.184:28003/api/display/products/home/payload/`  
**URL Local** : `http://localhost:8003/api/display/products/home/payload/`

**Authentification** : Optionnelle (les favoris ne sont présents que pour les utilisateurs connectés)

**Headers**:
```
Authorization: Bearer <access_token> (si disponible)
```

**Query Parameters**:

| Paramètre | Description | Défaut |
|-----------|-------------|--------|
| `page` | Numéro de page à récupérer | `1` |
| `page_size` | Taille du lot (max 50) | `12` |

**Réponse Success (200)**:
```json
{
  "success": true,
  "data": {
    "page": 1,
    "page_size": 12,
    "has_more": true,
    "next_page": 2,
    "total_count": 120,
    "products": [
      {
        "id": 1,
        "name": "Gâteau royal",
        "subtitle": "Douceur du jour",
        "description": "Gâteau chocolat noisette",
        "price": 24.5,
        "is_active": true,
        "is_available": true,
        "is_featured": false,
        "average_rating": 4.9,
        "reviews_count": 8,
        "isFavorite": true,
        "baker": {
          "id": 10,
          "userid": 5,
          "business_name": "Les Délices",
          "description": "Pâtissier depuis 15 ans",
          "average_rating": 4.8,
          "profile_image_url": "https://cdn.example/img/baker.jpg"
        },
        "images": [
          {
            "id": 100,
            "imageurl": "https://cdn.example/img/product1.jpg",
            "is_primary": true,
            "viewfrom": "front",
            "alt_text": "Gâteau royal",
            "width_pixels": 640,
            "height_pixels": 480,
            "format": "jpg",
            "sort_order": 1
          }
        ],
        "categories": [
          {
            "id": "cat-1",
            "name": "Gâteaux",
            "slug": "gateaux",
            "is_active": true,
            "image_url": "https://cdn.example/img/category/gateaux.png"
          }
        ]
      }
    ],
    "favorites": [
      {
        "id": 7,
        "name": "Biscuit vanille",
        "subtitle": "Un classique",
        "price": 12.5,
        "primary_image_url": "https://cdn.example/img/product7.jpg"
      }
    ],
    "filters": {
      "categories": [
        {
          "id": "cat-1",
          "name": "Gâteaux",
          "slug": "gateaux",
          "is_active": true,
          "image_url": "https://cdn.example/img/category/gateaux.png"
        }
      ]
    }
  }
}
```

**Mentions techniques**:
- `products` contient toutes les métadonnées utiles (`baker`, `images`, `categories`, `isFavorite`, `average_rating`, `reviews_count`…), ce qui évite au front de faire des appels supplémentaires.
- `images` fournit les méta-données des assets (`is_primary`, `viewfrom`, `width_pixels`, `height_pixels`, `alt_text`) pour permettre au front de prioriser les versions resized/CDN.
- `favorites` n’est présent que pour les utilisateurs authentifiés : si aucun token n’est fourni, la liste reste vide.
- `filters.categories` agrège toutes les catégories vues dans ce lot pour que le front puisse bâtir des chips ou un filtre rapide.

**Tables Sources**: `product`, `product_image`, `baker`, `product_category_relations`, `product_categories`, `user_favoris`

---

### GET `/products/{id}/full/`

**Description**: Retourne le `ProductScreen` complet (produit, pâtissier, avis, favori) avec toutes les sections requises dans [Doc agent service/product_screen.md](../Doc\ agent\ service/product_screen.md). L’endpoint fonctionne sans token et expose `isFavorite=false` & `favorite_id=null` quand aucun utilisateur n’est connecté.
**URL Freebox** : `http://91.171.4.184:28003/api/display/products/{id}/full/`  
**URL Local** : `http://localhost:8003/api/display/products/{id}/full/`

**Authentification** : Optionnelle

**Headers**:
```
Authorization: Bearer <access_token> (si disponible)
```

**Réponse Success (200)**:
```json
{
  "success": true,
  "data": {
    "product": {
      "id": 252,
      "name": "Layer cake",
      "description": "Gâteau feuilleté",
      "subtitle": "Édition limitée",
      "price": 80.00,
      "base_price": 80.00,
      "is_active": true,
      "is_available": true,
      "stock_quantity": 10,
      "min_order_quantity": 1,
      "max_order_quantity": 5,
      "images": [ ... ],
      "variants": [ ... ],
      "categories": [ ... ],
      "allergens": [ ... ],
      "tags": [ ... ],
      "customization_options": { ... },
      "delivery_info": { ... },
      "nutritional_info": { ... },
      "average_rating": 4.5,
      "reviews_count": 12,
      "orders_count": 3,
      "favorites_count": 0
    },
    "baker": {
      "id": 65,
      "userid": 309,
      "business_name": "Test Bakery",
      "description": "Pâtissier test",
      "average_rating": 4.5,
      "profile_image_url": null,
      "years_experience": 5,
      "delivery_radius": 20,
      "min_order_amount": 0.00,
      "delivery_fee": 0.00,
      "preparation_time_hours": 2,
      "phone_number": "0600000000",
      "email": "a@gmail.com"
    },
    "review": {
      "reviews_count": 12,
      "average_rating": 4.5,
      "reviews_preview": [
        {
          "author": "a@gmail.com",
          "rating": 5,
          "text": "Excellent"
        }
      ]
    },
    "favorite": {
      "isFavorite": false,
      "favorite_id": null,
      "favorite_group_id": null
    }
  }
}
```

**Frontend contract**: `ProductScreen` now consumes `/products/{id}/full/` as the sole source for product, baker, review and favorite metadata. Keep this payload complete so the client does not need extra backend calls.

**Tables Sources**: `product`, `product_image`, `product_variant`, `product_category_relations`, `product_categories`, `product_allergen`, `allergen`, `product_tags`, `product_tag_relations`, `baker`, `product_user`, `user_favoris`, `product_reviews`, `accounts_user`





