# Subscription Service API Documentation

**Base URL Freebox** : `http://91.171.4.184:28013/api/`
**Base URL Local** : `http://localhost:8013/api/`

## Endpoints

### GET `/subscription-plans/`

**Description**: Liste des plans d'abonnement actifs
**URL Freebox** : `http://91.171.4.184:28013/api/subscription-plans/`  
**URL Local** : `http://localhost:8013/api/subscription-plans/`

**Authentification** : Non requise

**Response Success (200)**:
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Plan Premium",
    "description": "Accès à tous les produits premium",
    "price": 9.99,
    "billing_cycle": "monthly",
    "features": ["Accès premium", "Livraison gratuite", "Réductions exclusives"],
    "is_active": true,
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
]
```

**Tables Sources**: `subscription_plans`

---

### POST `/subscriptions/subscribe/`

**Description**: Souscription à un plan d'abonnement
**URL Freebox** : `http://91.171.4.184:28013/api/subscriptions/subscribe/`  
**URL Local** : `http://localhost:8013/api/subscriptions/subscribe/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "user": 1,
  "plan_id": "550e8400-e29b-41d4-a716-446655440000",
  "start_date": "2024-01-15T00:00:00Z",
  "auto_renew": true
}
```

**Response Success (201)**:
```json
{
  "id": "660e8400-e29b-41d4-a716-446655440001",
  "user": 1,
  "plan": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Plan Premium",
    "price": 9.99,
    "billing_cycle": "monthly"
  },
  "plan_id": "550e8400-e29b-41d4-a716-446655440000",
  "start_date": "2024-01-15T00:00:00Z",
  "end_date": "2024-02-15T00:00:00Z",
  "status": "active",
  "billing_cycle": "monthly",
  "price": 9.99,
  "auto_renew": true,
  "cancelled_at": null,
  "cancellation_reason": null,
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

**Tables Sources**: `user_subscriptions`, `subscription_plans`

---

### PUT `/subscriptions/{id}/cancel/`

**Description**: Annulation d'un abonnement
**URL Freebox** : `http://91.171.4.184:28013/api/subscriptions/{id}/cancel/`  
**URL Local** : `http://localhost:8013/api/subscriptions/{id}/cancel/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "cancellation_reason": "Trop cher"
}
```

**Response Success (200)**:
```json
{
  "id": "660e8400-e29b-41d4-a716-446655440001",
  "status": "cancelled",
  "cancelled_at": "2024-01-15T10:35:00Z",
  "auto_renew": false
}
```

**Tables Sources**: `user_subscriptions`

---

### PUT `/subscriptions/{id}/unsubscribe/`

**Description** : Désinscription / résiliation côté `UserSubscriptionsViewSet` (complément ou variante métier par rapport à `cancel/` — se référer au code `subscription_app/views.py` pour le corps attendu et le statut renvoyé).

**URL Freebox** : `http://91.171.4.184:28013/api/subscriptions/{id}/unsubscribe/`  
**URL Local** : `http://localhost:8013/api/subscriptions/{id}/unsubscribe/`

**Authentification** : Requise

**Tables Sources** : `user_subscriptions`

---

### GET `/subscriptions/current/`

**Description**: Récupération de l'abonnement actif d'un utilisateur
**URL Freebox** : `http://91.171.4.184:28013/api/subscriptions/current/?user=1`  
**URL Local** : `http://localhost:8013/api/subscriptions/current/?user=1`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
```

**Query Parameters**:
- `user`: ID de l'utilisateur (requis)

**Response Success (200)**:
```json
{
  "id": "660e8400-e29b-41d4-a716-446655440001",
  "user": 1,
  "plan": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Plan Premium",
    "price": 9.99
  },
  "status": "active",
  "start_date": "2024-01-15T00:00:00Z",
  "end_date": "2024-02-15T00:00:00Z",
  "auto_renew": true
}
```

**Response Success (204)**:
```
No Content
```

**Tables Sources**: `user_subscriptions`

---

### GET `/subscriptions/billing-history/`

**Description**: Historique de facturation
**URL Freebox** : `http://91.171.4.184:28013/api/subscriptions/billing-history/?user=1`  
**URL Local** : `http://localhost:8013/api/subscriptions/billing-history/?user=1`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
```

**Query Parameters**:
- `user`: ID de l'utilisateur (optionnel)

**Response Success (200)**:
```json
[
  {
    "id": 1,
    "user_subscription": "660e8400-e29b-41d4-a716-446655440001",
    "invoice_number": "INV-2024-001",
    "invoice_date": "2024-01-15T00:00:00Z",
    "amount": 9.99,
    "currency": "eur",
    "status": "paid",
    "payment_method": "card",
    "created_at": "2024-01-15T10:30:00Z"
  }
]
```

**Tables Sources**: `billing_history`, `user_subscriptions`

---

### POST `/newsletter/`

**Description**: Abonnement à la newsletter
**URL Freebox** : `http://91.171.4.184:28013/api/newsletter/`  
**URL Local** : `http://localhost:8013/api/newsletter/`

**Authentification** : Non requise

**Headers**:
```
Content-Type: application/json
```

**Body**:
```json
{
  "email": "user@example.com",
  "user": 1,
  "preferences": {
    "promotions": true,
    "new_products": true,
    "news": false
  }
}
```

**Response Success (201)**:
```json
{
  "id": 1,
  "email": "user@example.com",
  "user": 1,
  "is_active": true,
  "preferences": {
    "promotions": true,
    "new_products": true,
    "news": false
  },
  "created_at": "2024-01-15T10:30:00Z"
}
```

**Tables Sources**: `newsletter_subscription`

---

### PUT `/newsletter/{id}/unsubscribe/`

**Description**: Désabonnement de la newsletter
**URL Freebox** : `http://91.171.4.184:28013/api/newsletter/{id}/unsubscribe/`  
**URL Local** : `http://localhost:8013/api/newsletter/{id}/unsubscribe/`

**Authentification** : Non requise

**Headers**:
```
Content-Type: application/json
```

**Response Success (200)**:
```json
{
  "id": 1,
  "is_active": false
}
```

**Tables Sources**: `newsletter_subscription`

---

### POST `/billing/prorate/`

**Description**: Calcul du montant proratisé
**URL Freebox** : `http://91.171.4.184:28013/api/billing/prorate/`  
**URL Local** : `http://localhost:8013/api/billing/prorate/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "price": 9.99,
  "days_used": 15,
  "cycle_days": 30
}
```

**Response Success (200)**:
```json
{
  "amount": "4.99"
}
```

**Response Error (400)**:
```json
{
  "detail": "Invalid input"
}
```





