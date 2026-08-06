# User Service API Documentation

**Base URL Freebox** : `http://91.171.4.184:28002/api/users/`
**Base URL Local** : `http://localhost:8002/api/users/`

## Endpoints

### GET `/me/`

**Description**: Récupération du profil de l'utilisateur connecté
**URL Freebox** : `http://91.171.4.184:28002/api/users/me/`  
**URL Local** : `http://localhost:8002/api/users/me/`

**Authentification** : Requise

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

**Description**: Liste paginée des utilisateurs (`ModelViewSet.list`).
**URL Freebox** : `http://91.171.4.184:28002/api/users/`  
**URL Local** : `http://localhost:8002/api/users/`

**Authentification** : Requise (`IsAuthenticated`).

**Note (implémentation)** : Les permissions DRF ne restreignent pas cette liste au rôle *staff/admin* dans le code actuel — tout utilisateur authentifié peut appeler `GET /api/users/`. À durcir côté métier si la doc « admin seulement » doit s’appliquer.

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
  "next": "http://localhost:8002/api/users/?page=2",
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

### PATCH `/{id}/personal_info/`

**Description** : Mise à jour partielle des champs personnels (`first_name`, `last_name`, `phone_number`, `date_of_birth`). L’`id` dans l’URL doit correspondre au `user_id` du JWT.

**URL Freebox** : `http://91.171.4.184:28002/api/users/{id}/personal_info/`  
**URL Local** : `http://localhost:8002/api/users/{id}/personal_info/`

**Authentification** : Requise

---

### PATCH `/{id}/address/`

**Description** : Mise à jour partielle de l’adresse (`street_number`, `street`, `address_complement`, `postal_code`, `city`, `region`, `country`, `location`).

**URL Freebox** : `http://91.171.4.184:28002/api/users/{id}/address/`  
**URL Local** : `http://localhost:8002/api/users/{id}/address/`

**Authentification** : Requise

---

### PATCH `/{id}/status_update/`

**Description** : Mise à jour des drapeaux `is_active`, `is_staff`, `is_superuser` (usage typiquement réservé aux comptes autorisés — à valider côté gouvernance).

**URL Freebox** : `http://91.171.4.184:28002/api/users/{id}/status_update/`  
**URL Local** : `http://localhost:8002/api/users/{id}/status_update/`

**Authentification** : Requise

---

### GET `/{id}/`

**Description**: Détails d'un utilisateur spécifique
**URL Freebox** : `http://91.171.4.184:28002/api/users/{id}/`  
**URL Local** : `http://localhost:8002/api/users/{id}/`

**Authentification** : Requise

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
**URL Freebox** : `http://91.171.4.184:28002/api/users/{id}/`  
**URL Local** : `http://localhost:8002/api/users/{id}/`

**Authentification** : Requise

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





