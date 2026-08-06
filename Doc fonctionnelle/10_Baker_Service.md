# Baker Service API Documentation

**Base URL Freebox** : `http://91.171.4.184:28010/api/`
**Base URL Local** : `http://localhost:8010/api/`

## Endpoints

### GET `/bakers/`

**Description**: Liste des pâtissiers avec filtres optionnels
**URL Freebox** : `http://91.171.4.184:28010/api/bakers/`  
**URL Local** : `http://localhost:8010/api/bakers/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
```

**Query Parameters**:
- `is_verified`: Filtrer par statut vérifié (true/false)
- `is_active`: Filtrer par statut actif (true/false)
- `accepts_orders`: Filtrer par acceptation de commandes (true/false)
- `location`: Filtrer par localisation (recherche partielle)

**Response Success (200)**:
```json
[
  {
    "id": 1,
    "user": 2,
    "business_name": "Pâtisserie Marie",
    "description": "Pâtissière passionnée depuis 10 ans",
    "experience": "10 ans d'expérience en pâtisserie",
    "location": "Paris, France",
    "profile_image_url": "https://example.com/baker.jpg",
    "is_verified": true,
    "is_active": true,
    "accepts_orders": true,
    "phone_number": "+33123456789",
    "email": "marie@patisserie.com",
    "years_experience": 10,
    "delivery_radius": 15,
    "min_order_amount": 20.00,
    "delivery_fee": 5.00,
    "preparation_time_hours": 24,
    "commission_rate": 10.00,
    "average_rating": 4.8,
    "specialties": [],
    "languages": [],
    "certifications": [],
    "working_hours": [],
    "reviews_count": 25,
    "is_available": true,
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
]
```

**Tables Sources**: `baker`, `baker_specialty`, `baker_language`, `baker_certification`, `baker_working_hours`

---

### GET `/bakers/{id}/`

**Description**: Détails d'un pâtissier spécifique
**URL Freebox** : `http://91.171.4.184:28010/api/bakers/{id}/`  
**URL Local** : `http://localhost:8010/api/bakers/{id}/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
{
  "id": 1,
  "user": 2,
  "business_name": "Pâtisserie Marie",
  "description": "Pâtissière passionnée depuis 10 ans",
  "experience": "10 ans d'expérience en pâtisserie",
  "location": "Paris, France",
  "profile_image_url": "https://example.com/baker.jpg",
  "is_verified": true,
  "is_active": true,
  "accepts_orders": true,
  "phone_number": "+33123456789",
  "email": "marie@patisserie.com",
  "years_experience": 10,
  "delivery_radius": 15,
  "min_order_amount": 20.00,
  "delivery_fee": 5.00,
  "preparation_time_hours": 24,
  "commission_rate": 10.00,
  "average_rating": 4.8,
  "specialties": [
    {
      "id": 1,
      "baker": 1,
      "specialty_name": "Gâteaux d'anniversaire",
      "specialty_description": "Spécialiste des gâteaux d'anniversaire",
      "is_primary": true,
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "languages": [
    {
      "id": 1,
      "baker": 1,
      "language_code": "fr",
      "language_name": "Français",
      "proficiency_level": "native",
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "certifications": [],
  "working_hours": [],
  "reviews_count": 25,
  "is_available": true,
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

**Tables Sources**: `baker`, `baker_specialty`, `baker_language`, `baker_certification`, `baker_working_hours`

---

### GET `/bakers/userid/{user_id}/`

**Description**: Recherche d'un pâtissier par **user_id** (identifiant utilisateur Auth / compte), tel que défini dans le routeur (`url_path=userid/(?P<user_id>\\d+)`).
**URL Freebox** : `http://91.171.4.184:28010/api/bakers/userid/{user_id}/`
**URL Local** : `http://localhost:8010/api/bakers/userid/{user_id}/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
{
  "id": 1,
  "user": 2,
  "business_name": "Pâtisserie Marie",
  "description": "Pâtissière passionnée depuis 10 ans",
  "experience": "10 ans d'expérience en pâtisserie",
  "location": "Paris, France",
  "profile_image_url": "https://example.com/baker.jpg",
  "is_verified": true,
  "is_active": true,
  "accepts_orders": true,
  "phone_number": "+33123456789",
  "email": "marie@patisserie.com",
  "years_experience": 10,
  "delivery_radius": 15,
  "min_order_amount": 20.00,
  "delivery_fee": 5.00,
  "preparation_time_hours": 24,
  "commission_rate": 10.00,
  "average_rating": 4.8,
  "specialties": [],
  "languages": [],
  "certifications": [],
  "working_hours": [],
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

**Response Error (404)**:
```json
{
  "error": "No baker profile found for this user"
}
```

**Tables Sources**: `baker`

---

### POST `/bakers/`

**Description**: Création d'un profil de pâtissier
**URL Freebox** : `http://91.171.4.184:28010/api/bakers/`  
**URL Local** : `http://localhost:8010/api/bakers/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "user": 2,
  "business_name": "Pâtisserie Marie",
  "description": "Pâtissière passionnée depuis 10 ans",
  "experience": "10 ans d'expérience",
  "location": "Paris, France",
  "profile_image_url": "https://example.com/baker.jpg",
  "phone_number": "+33123456789",
  "email": "marie@patisserie.com",
  "years_experience": 10,
  "delivery_radius": 15,
  "min_order_amount": 20.00,
  "delivery_fee": 5.00,
  "preparation_time_hours": 24,
  "commission_rate": 10.00
}
```

**Response Success (201)**:
```json
{
  "id": 1,
  "user": 2,
  "business_name": "Pâtisserie Marie",
  "description": "Pâtissière passionnée depuis 10 ans",
  "is_verified": false,
  "is_active": true,
  "accepts_orders": true,
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

**Tables Sources**: `baker`

---

### PUT `/bakers/{id}/`

**Description**: Mise à jour complète d'un profil de pâtissier
**URL Freebox** : `http://91.171.4.184:28010/api/bakers/{id}/`  
**URL Local** : `http://localhost:8010/api/bakers/{id}/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "business_name": "Pâtisserie Marie Premium",
  "description": "Pâtissière passionnée depuis 10 ans - Spécialiste des gâteaux premium",
  "delivery_radius": 20,
  "min_order_amount": 25.00
}
```

**Response Success (200)**:
```json
{
  "id": 1,
  "business_name": "Pâtisserie Marie Premium",
  "description": "Pâtissière passionnée depuis 10 ans - Spécialiste des gâteaux premium",
  "delivery_radius": 20,
  "min_order_amount": 25.00,
  "updated_at": "2024-01-15T10:35:00Z"
}
```

**Tables Sources**: `baker`

---

### PATCH `/bakers/{id}/`

**Description**: Mise à jour partielle d'un profil de pâtissier
**URL Freebox** : `http://91.171.4.184:28010/api/bakers/{id}/`  
**URL Local** : `http://localhost:8010/api/bakers/{id}/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "delivery_radius": 20
}
```

**Response Success (200)**:
```json
{
  "id": 1,
  "delivery_radius": 20,
  "updated_at": "2024-01-15T10:35:00Z"
}
```

**Tables Sources**: `baker`

---

### DELETE `/bakers/{id}/`

**Description**: Suppression d'un profil de pâtissier
**URL Freebox** : `http://91.171.4.184:28010/api/bakers/{id}/`  
**URL Local** : `http://localhost:8010/api/bakers/{id}/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (204)**:
```
No Content
```

**Tables Sources**: `baker`

---

### GET `/bakers/{id}/specialties/`

**Description**: Liste des spécialités d'un pâtissier
**URL Freebox** : `http://91.171.4.184:28010/api/bakers/{id}/specialties/`  
**URL Local** : `http://localhost:8010/api/bakers/{id}/specialties/`

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
    "baker": 1,
    "specialty_name": "Gâteaux d'anniversaire",
    "specialty_description": "Spécialiste des gâteaux d'anniversaire",
    "is_primary": true,
    "created_at": "2024-01-01T00:00:00Z"
  }
]
```

**Tables Sources**: `baker_specialty`

---

### POST `/bakers/{id}/specialties/`

**Description**: Ajout d'une spécialité à un pâtissier
**URL Freebox** : `http://91.171.4.184:28010/api/bakers/{id}/specialties/`  
**URL Local** : `http://localhost:8010/api/bakers/{id}/specialties/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "specialty_name": "Tartes aux fruits",
  "specialty_description": "Spécialiste des tartes aux fruits de saison",
  "is_primary": false
}
```

**Response Success (201)**:
```json
{
  "id": 2,
  "baker": 1,
  "specialty_name": "Tartes aux fruits",
  "specialty_description": "Spécialiste des tartes aux fruits de saison",
  "is_primary": false,
  "created_at": "2024-01-15T10:30:00Z"
}
```

**Tables Sources**: `baker_specialty`





