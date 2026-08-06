# Search Service API Documentation

**Base URL Freebox** : `http://91.171.4.184:28011/api/search/`
**Base URL Local** : `http://localhost:8011/api/search/`

## Endpoints

### GET `/products/`

**Description**: Recherche de produits avec filtres
**URL Freebox** : `http://91.171.4.184:28011/api/search/products/`  
**URL Local** : `http://localhost:8011/api/search/products/`

**Authentification** : Non requise

**Query Parameters**:
- `q`: Terme de recherche (nom, description)
- `category`: ID de catégorie
- `price_min`: Prix minimum
- `price_max`: Prix maximum
- `rating_min`: Note minimum
- `baker_id`: ID du pâtissier
- `sort`: Tri (relevance, price, rating)
- `page`: Numéro de page (défaut: 1)

**Response Success (200)**:
```json
{
  "count": 150,
  "results": [
    {
      "id": 1,
      "name": "Gâteau au chocolat",
      "description": "Délicieux gâteau au chocolat fait maison",
      "price": 25.50,
      "baker_id": 1,
      "average_rating": 4.5,
      "location": "Paris",
      "dimensions": "20x20cm",
      "preparation_time": 24,
      "is_refrigerated": true,
      "baker_name": "Pâtisserie Marie",
      "category_names": ["Gâteaux"],
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-15T10:30:00Z"
    }
  ],
  "page": 1,
  "page_size": 20,
  "total_pages": 8
}
```

**Tables Sources**: `product`, `baker`, `category`

---

### GET `/bakers/`

**Description**: Recherche de pâtissiers avec filtres
**URL Freebox** : `http://91.171.4.184:28011/api/search/bakers/`  
**URL Local** : `http://localhost:8011/api/search/bakers/`

**Authentification** : Non requise

**Query Parameters**:
- `q`: Terme de recherche (nom d'entreprise, description, spécialité)
- `specialty`: Filtre par spécialité
- `city`: Filtre par ville (depuis location)
- `rating_min`: Note minimum
- `sort`: Tri (relevance, rating)
- `page`: Numéro de page (défaut: 1)

**Response Success (200)**:
```json
{
  "count": 50,
  "results": [
    {
      "id": 1,
      "user": 2,
      "description": "Pâtissière passionnée depuis 10 ans",
      "experience": "10 ans d'expérience",
      "average_rating": 4.8,
      "location": "Paris, France",
      "business_name": "Pâtisserie Marie",
      "is_verified": true,
      "is_active": true,
      "accepts_orders": true,
      "user_email": "marie@patisserie.com",
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-15T10:30:00Z"
    }
  ],
  "page": 1,
  "page_size": 20,
  "total_pages": 3
}
```

**Tables Sources**: `baker`, `accounts_user`

---

### GET `/suggestions/`

**Description**: Récupération de suggestions de recherche
**URL Freebox** : `http://91.171.4.184:28011/api/search/suggestions/`  
**URL Local** : `http://localhost:8011/api/search/suggestions/`

**Authentification** : Non requise

**Query Parameters**:
- `q`: Terme de recherche (minimum 2 caractères)

**Response Success (200)**:
```json
{
  "suggestions": [
    "Gâteau au chocolat",
    "Gâteau d'anniversaire",
    "Gâteau aux fruits",
    "Pâtisserie Marie",
    "Pâtisserie Pierre",
    "Gâteaux",
    "Tartes",
    "Macarons"
  ]
}
```

**Tables Sources**: `product`, `baker`, `category`

---

### GET `/trending/`

**Description**: Récupération des recherches tendances
**URL Freebox** : `http://91.171.4.184:28011/api/search/trending/`  
**URL Local** : `http://localhost:8011/api/search/trending/`

**Authentification** : Non requise

**Response Success (200)**:
```json
{
  "products": [
    {
      "id": 1,
      "name": "Gâteau au chocolat",
      "description": "Délicieux gâteau au chocolat",
      "price": 25.50,
      "baker_id": 1,
      "average_rating": 4.5,
      "baker_name": "Pâtisserie Marie",
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "bakers": [
    {
      "id": 1,
      "business_name": "Pâtisserie Marie",
      "description": "Pâtissière passionnée",
      "average_rating": 4.8,
      "is_verified": true,
      "created_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

**Tables Sources**: `product`, `baker`

---

### GET `/filters/`

**Description**: Récupération des filtres disponibles pour une catégorie
**URL Freebox** : `http://91.171.4.184:28011/api/search/filters/`  
**URL Local** : `http://localhost:8011/api/search/filters/`

**Authentification** : Non requise

**Query Parameters**:
- `category`: ID de catégorie (optionnel)

**Response Success (200)**:
```json
{
  "price_ranges": [
    {"min": 0, "max": 10, "label": "Under €10"},
    {"min": 10, "max": 25, "label": "€10 - €25"},
    {"min": 25, "max": 50, "label": "€25 - €50"},
    {"min": 50, "max": null, "label": "Over €50"}
  ],
  "rating_options": [
    {"min": 4.5, "label": "4.5+ stars"},
    {"min": 4.0, "label": "4+ stars"},
    {"min": 3.5, "label": "3.5+ stars"},
    {"min": 3.0, "label": "3+ stars"}
  ],
  "sort_options": [
    {"value": "relevance", "label": "Relevance"},
    {"value": "price", "label": "Price: Low to High"},
    {"value": "-price", "label": "Price: High to Low"},
    {"value": "rating", "label": "Highest Rated"}
  ],
  "category": {
    "id": 1,
    "name": "Gâteaux"
  }
}
```

**Tables Sources**: `category`





