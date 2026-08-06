# Auth Service API Documentation

**Base URL Freebox** : `http://91.171.4.184:28000/api/auth/`
**Base URL Local** : `http://localhost:8000/api/auth/`

## Endpoints

### POST `/register/`

**Description**: Inscription d'un nouvel utilisateur
**URL Freebox** : `http://91.171.4.184:28000/api/auth/register/`  
**URL Local** : `http://localhost:8000/api/auth/register/`

**Authentification** : Non requise

**Headers**:
```
Content-Type: application/json
```

**Body**:
```json
{
  "email": "user@example.com",
  "password": "password123",
  "first_name": "John",
  "last_name": "Doe",
  "phone_number": "+33123456789",
  "date_of_birth": "1990-01-01",
  "address_complement": "Apt 123",
  "city": "Paris",
  "country": "France",
  "postal_code": "75001",
  "region": "Île-de-France",
  "street": "Rue de la Paix",
  "street_number": "123"
}
```

**Response Success (201)**:
```json
{
  "message": "Utilisateur créé avec succès.",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "phone_number": "+33123456789",
    "date_joined": "2024-01-15T10:30:00Z"
  }
}
```

**Response Error (400)**:
```json
{
  "error": "Email déjà utilisé",
  "details": {
    "email": ["Un utilisateur avec cet email existe déjà."]
  }
}
```

**Tables Sources**: `accounts_user`

---

### POST `/login/`

**Description**: Connexion d'un utilisateur
**URL Freebox** : `http://91.171.4.184:28000/api/auth/login/`  
**URL Local** : `http://localhost:8000/api/auth/login/`

**Authentification** : Non requise

**Headers**:
```
Content-Type: application/json
```

**Body**:
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response Success (200)**:
```json
{
  "user": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "last_login": "2024-01-15T10:30:00Z"
  },
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

**Response Error (401)**:
```json
{
  "error": "Identifiants invalides"
}
```

**Tables Sources**: `accounts_user`

---

### POST `/token/refresh/`

**Description**: Rafraîchissement du token d'accès
**URL Freebox** : `http://91.171.4.184:28000/api/auth/token/refresh/`  
**URL Local** : `http://localhost:8000/api/auth/token/refresh/`

**Authentification** : Non requise

**Headers**:
```
Content-Type: application/json
```

**Body**:
```json
{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

**Response Success (200)**:
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

**Response Error (401)**:
```json
{
  "error": "Token de rafraîchissement invalide"
}
```

**Tables Sources**: `accounts_user`

---

### POST `/password-reset/request/`

**Description**: Demande de réinitialisation de mot de passe
**URL Freebox** : `http://91.171.4.184:28000/api/auth/password-reset/request/`  
**URL Local** : `http://localhost:8000/api/auth/password-reset/request/`

**Authentification** : Non requise

**Headers**:
```
Content-Type: application/json
```

**Body**:
```json
{
  "email": "user@example.com",
  "reset_type": "email"
}
```

**Response Success (200)**:
```json
{
  "message": "Un code de réinitialisation a été envoyé par email."
}
```

**Tables Sources**: `accounts_user`, `password_reset_codes`

---

### POST `/password-reset/verify/`

**Description**: Vérification du code de réinitialisation
**URL Freebox** : `http://91.171.4.184:28000/api/auth/password-reset/verify/`  
**URL Local** : `http://localhost:8000/api/auth/password-reset/verify/`

**Authentification** : Non requise

**Headers**:
```
Content-Type: application/json
```

**Body**:
```json
{
  "email": "user@example.com",
  "code": "123456"
}
```

**Response Success (200)**:
```json
{
  "message": "Code vérifié avec succès.",
  "reset_token": "uuid-reset-token"
}
```

**Tables Sources**: `password_reset_codes`

---

### POST `/password-reset/reset/`

**Description**: Réinitialisation du mot de passe
**URL Freebox** : `http://91.171.4.184:28000/api/auth/password-reset/reset/`  
**URL Local** : `http://localhost:8000/api/auth/password-reset/reset/`

**Authentification** : Non requise

**Headers**:
```
Content-Type: application/json
```

**Body**:
```json
{
  "email": "user@example.com",
  "new_password": "newpassword123",
  "reset_token": "uuid-reset-token"
}
```

**Response Success (200)**:
```json
{
  "message": "Mot de passe changé avec succès."
}
```

**Tables Sources**: `accounts_user`, `password_reset_codes`





