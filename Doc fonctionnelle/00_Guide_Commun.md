# Guide Commun - Documentation API Backend Patisry

Ce document contient les informations communes à tous les services de l'API Backend Patisry.

## Codes de Statut HTTP

| Code | Description | Utilisation |
|------|-------------|-------------|
| 200 | OK | Requête réussie |
| 201 | Created | Ressource créée |
| 204 | No Content | Suppression réussie |
| 400 | Bad Request | Données invalides |
| 401 | Unauthorized | Token manquant ou invalide |
| 403 | Forbidden | Permissions insuffisantes |
| 404 | Not Found | Ressource non trouvée |
| 409 | Conflict | Conflit de données |
| 422 | Unprocessable Entity | Erreur de validation |
| 500 | Internal Server Error | Erreur serveur |

---

## Gestion des Erreurs

### Format Standard des Erreurs

```json
{
  "error": "Message d'erreur principal",
  "details": {
    "field_name": ["Message d'erreur spécifique"]
  },
  "code": "ERROR_CODE",
  "timestamp": "2024-01-15T10:30:00Z",
  "path": "/api/products/",
  "method": "POST"
}
```

### Codes d'Erreur Spécifiques

| Code | Description |
|------|-------------|
| `VALIDATION_ERROR` | Erreur de validation des données |
| `AUTHENTICATION_ERROR` | Erreur d'authentification |
| `AUTHORIZATION_ERROR` | Erreur d'autorisation |
| `NOT_FOUND` | Ressource non trouvée |
| `DUPLICATE_ERROR` | Ressource déjà existante |
| `BUSINESS_LOGIC_ERROR` | Erreur de logique métier |
| `EXTERNAL_SERVICE_ERROR` | Erreur de service externe |
| `RATE_LIMIT_ERROR` | Limite de taux dépassée |

---

## Limites et Contraintes

> **Note (alignement code / doc)** : Les valeurs ci-dessous décrivent une **cible produit ou une convention** documentaire. Elles ne sont pas forcément appliquées de façon identique dans chaque microservice (rate limiting, format d’erreur JSON, durées JWT, etc.). Pour la vérité terrain par domaine, se référer au fichier `0X_*_Service.md` correspondant et au code du service.

### Rate Limiting
- **Utilisateurs authentifiés**: 1000 requêtes/heure
- **Utilisateurs non authentifiés**: 100 requêtes/heure
- **Endpoints sensibles**: 10 requêtes/minute

### Pagination
- **Taille de page par défaut**: 20 éléments
- **Taille de page maximale**: 100 éléments
- **Taille de page minimale**: 1 élément

### Validation
- **Taille maximale des fichiers**: 10MB
- **Types de fichiers autorisés**: jpg, png, gif, webp
- **Longueur maximale des textes**: 5000 caractères

### Sécurité
- **Tokens JWT**: Durée de vie de 12 heures
- **Refresh tokens**: Durée de vie de 7 jours
- **Mots de passe**: Minimum 8 caractères avec complexité
- **CORS**: Configuration pour le frontend Flutter

---

## Monitoring et Logs

### Métriques Collectées
- Nombre de requêtes par endpoint
- Temps de réponse moyen
- Taux d'erreur par endpoint
- Utilisation des ressources

### Logs Structurés
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "level": "INFO",
  "service": "product-service",
  "endpoint": "/api/products/",
  "method": "GET",
  "user_id": 1,
  "response_time_ms": 150,
  "status_code": 200,
  "request_id": "req-123456"
}
```

---

## Guide d'utilisation Frontend

### Authentification

Tous les endpoints nécessitant une authentification utilisent le format JWT Bearer Token :

```javascript
headers: {
  'Authorization': 'Bearer <access_token>',
  'Content-Type': 'application/json'
}
```

### Exemple d'intégration

```javascript
// Exemple avec fetch API
const response = await fetch('http://localhost:8000/api/auth/login/', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    email: 'user@example.com',
    password: 'Password123!'
  })
});

const data = await response.json();
// Stocker le token
localStorage.setItem('access_token', data.access);
localStorage.setItem('refresh_token', data.refresh);
```

### Gestion des tokens

```javascript
// Rafraîchir le token
const refreshToken = async () => {
  const refresh = localStorage.getItem('refresh_token');
  const response = await fetch('http://localhost:8000/api/auth/token/refresh/', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ refresh })
  });
  const data = await response.json();
  localStorage.setItem('access_token', data.access);
  return data.access;
};
```

---

## Mapping des Ports Freebox

**IP Freebox** : `91.171.4.184`  
**Format des ports** : Port externe = Port interne + 20000

| Service | Port Interne | Port Externe Freebox | Base URL Freebox |
|---------|-------------|---------------------|------------------|
| Auth Service | 8000 | 28000 | `http://91.171.4.184:28000/api/auth/` |
| User Service | 8002 | 28002 | `http://91.171.4.184:28002/api/users/` |
| Display Service | 8003 | 28003 | `http://91.171.4.184:28003/api/display/` |
| Message Service | 8004 | 28004 | `http://91.171.4.184:28004/api/messages/` |
| Notification Service | 8005 | 28005 | `http://91.171.4.184:28005/api/notifications/` |
| Product Service | 8006 | 28006 | `http://91.171.4.184:28006/api/products/` |
| Order Service | 8007 | 28007 | `http://91.171.4.184:28007/api/orders/` |
| Analytics Service | 8008 | 28008 | `http://91.171.4.184:28008/api/analytics/` |
| Favorite Service | 8009 | 28009 | `http://91.171.4.184:28009/api/favorites/` |
| Baker Service | 8010 | 28010 | `http://91.171.4.184:28010/api/bakers/` |
| Search Service | 8011 | 28011 | `http://91.171.4.184:28011/api/search/` |
| Payment Service | 8012 | 28012 | `http://91.171.4.184:28012/api/payments/` |
| Subscription Service | 8013 | 28013 | `http://91.171.4.184:28013/api/subscriptions/` |
| Admin Service | 8014 | 28014 | `http://91.171.4.184:28014/api/admin/` |
| Review Service | 8015 | 28015 | `http://91.171.4.184:28015/api/reviews/` |

---

## Prochaines Étapes

1. **Développement des services manquants** selon les priorités définies
2. **Implémentation du tracking utilisateur** sur tous les endpoints
3. **Tests d'intégration** frontend-backend
4. **Documentation OpenAPI/Swagger** complète
5. **Monitoring et alertes** en production





