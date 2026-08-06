# Analytics Service API Documentation

**Base URL Freebox** : `http://91.171.4.184:28008/api/`
**Base URL Local** : `http://localhost:8008/api/`

## Endpoints

### POST `/sessions/`

**Description**: Création d'une nouvelle session utilisateur
**URL Freebox** : `http://91.171.4.184:28008/api/sessions/`  
**URL Local** : `http://localhost:8008/api/sessions/`

**Authentification** : Non requise

**Headers**:
```
Content-Type: application/json
```

**Body**:
```json
{
  "user_id": 1,
  "device_info": {
    "device_type": "mobile",
    "os": "iOS",
    "os_version": "17.0",
    "app_version": "1.0.0"
  },
  "ip_address": "192.168.1.1",
  "user_agent": "Mozilla/5.0...",
  "location": {
    "lat": 48.8566,
    "lon": 2.3522,
    "city": "Paris",
    "country": "France"
  },
  "expires_at": "2024-01-16T10:30:00Z"
}
```

**Response Success (201)**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "session_token": "660e8400-e29b-41d4-a716-446655440001",
  "refresh_token": "770e8400-e29b-41d4-a716-446655440002"
}
```

**Tables Sources**: `user_sessions`

---

### GET `/sessions/{id}/`

**Description**: Récupération des détails d'une session
**URL Freebox** : `http://91.171.4.184:28008/api/sessions/{id}/`  
**URL Local** : `http://localhost:8008/api/sessions/{id}/`

**Authentification** : Non requise

**Headers**:
```
Content-Type: application/json
```

**Response Success (200)**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": 1,
  "is_active": true,
  "expires_at": "2024-01-16T10:30:00Z",
  "last_activity": "2024-01-15T10:30:00Z"
}
```

**Response Error (404)**:
```json
{
  "error": "Session non trouvée",
  "code": "NOT_FOUND"
}
```

**Tables Sources**: `user_sessions`

---

### PUT `/sessions/{id}/activity/`

**Description**: Mise à jour de l'activité d'une session
**URL Freebox** : `http://91.171.4.184:28008/api/sessions/{id}/activity/`  
**URL Local** : `http://localhost:8008/api/sessions/{id}/activity/`

**Authentification** : Non requise

**Headers**:
```
Content-Type: application/json
```

**Response Success (200)**:
```json
{
  "message": "Activité mise à jour"
}
```

**Tables Sources**: `user_sessions`

---

### DELETE `/sessions/{id}/`

**Description**: Désactivation d'une session
**URL Freebox** : `http://91.171.4.184:28008/api/sessions/{id}/`  
**URL Local** : `http://localhost:8008/api/sessions/{id}/`

**Authentification** : Non requise

**Headers**:
```
Content-Type: application/json
```

**Response Success (204)**:
```
No Content
```

**Tables Sources**: `user_sessions`

---

### POST `/analytics/page-view/`

**Description**: Enregistrement d'une vue de page
**URL Freebox** : `http://91.171.4.184:28008/api/analytics/page-view/`  
**URL Local** : `http://localhost:8008/api/analytics/page-view/`

**Authentification** : Non requise

**Headers**:
```
Content-Type: application/json
```

**Body**:
```json
{
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": 1,
  "page_name": "product_detail",
  "page_url": "/products/1",
  "page_title": "Gâteau au chocolat",
  "referrer_url": "/products",
  "duration_seconds": 45,
  "scroll_depth_percentage": 75,
  "metadata": {
    "product_id": 1,
    "category": "gâteaux"
  }
}
```

**Response Success (201)**:
```json
{
  "id": "660e8400-e29b-41d4-a716-446655440003"
}
```

**Tables Sources**: `user_page_views`

---

### POST `/analytics/user-action/`

**Description**: Enregistrement d'une action utilisateur
**URL Freebox** : `http://91.171.4.184:28008/api/analytics/user-action/`  
**URL Local** : `http://localhost:8008/api/analytics/user-action/`

**Authentification** : Non requise

**Headers**:
```
Content-Type: application/json
```

**Body**:
```json
{
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": 1,
  "page_view_id": "660e8400-e29b-41d4-a716-446655440003",
  "action_type": "click",
  "target_element": "add_to_cart_button",
  "target_id": "product_1",
  "target_text": "Ajouter au panier",
  "coordinates": {
    "x": 150,
    "y": 200
  },
  "context": {
    "product_id": 1,
    "price": 25.50
  }
}
```

**Response Success (201)**:
```json
{
  "id": "770e8400-e29b-41d4-a716-446655440004"
}
```

**Tables Sources**: `user_actions`

---

### POST `/analytics/search/`

**Description**: Enregistrement d'une recherche
**URL Freebox** : `http://91.171.4.184:28008/api/analytics/search/`  
**URL Local** : `http://localhost:8008/api/analytics/search/`

**Authentification** : Non requise

**Headers**:
```
Content-Type: application/json
```

**Body**:
```json
{
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": 1,
  "search_query": "gâteau au chocolat",
  "search_type": "products",
  "filters": {
    "category": 1,
    "price_min": 10,
    "price_max": 50
  },
  "results_count": 15,
  "clicked_results": [
    {
      "product_id": 1,
      "position": 1
    }
  ]
}
```

**Response Success (201)**:
```json
{
  "id": "880e8400-e29b-41d4-a716-446655440005"
}
```

**Tables Sources**: `user_search_history`

---

### GET `/analytics/{user_id}/daily/`

**Description**: Récupération des statistiques quotidiennes d'un utilisateur
**URL Freebox** : `http://91.171.4.184:28008/api/analytics/{user_id}/daily/`  
**URL Local** : `http://localhost:8008/api/analytics/{user_id}/daily/`

**Authentification** : Non requise

**Headers**:
```
Content-Type: application/json
```

**Query Parameters**:
- `start_date`: Date de début (format: YYYY-MM-DD)
- `end_date`: Date de fin (format: YYYY-MM-DD)

**Response Success (200)**:
```json
[
  {
    "date": "2024-01-15",
    "page_views_count": 25,
    "unique_pages_count": 10,
    "total_session_duration": 1800,
    "actions_count": 45,
    "searches_count": 5,
    "products_viewed_count": 8,
    "bakers_viewed_count": 3,
    "cart_additions_count": 2,
    "favorites_additions_count": 1,
    "orders_count": 1,
    "total_spent": 58.00,
    "conversion_rate": 0.04,
    "bounce_rate": 0.20
  }
]
```

**Tables Sources**: `user_analytics_daily`





