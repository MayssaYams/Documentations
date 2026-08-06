# Payment Service API Documentation

**Base URL Freebox** : `http://91.171.4.184:28012/api/`
**Base URL Local** : `http://localhost:8012/api/`

## Endpoints

### GET `/payment-methods/`

**Description**: Liste des méthodes de paiement de l'utilisateur connecté
**URL Freebox** : `http://91.171.4.184:28012/api/payment-methods/`  
**URL Local** : `http://localhost:8012/api/payment-methods/`

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
    "payment_type": "card",
    "is_default": true,
    "is_active": true,
    "is_verified": true,
    "card_last_four": "4242",
    "card_brand": "visa",
    "expiry_date": "2025-12-31",
    "verification_date": "2024-01-15T10:30:00Z",
    "billing_address": {
      "street": "Rue de la Paix",
      "city": "Paris",
      "postal_code": "75001",
      "country": "France",
      "stripe_customer_id": "cus_xxxxx"
    },
    "stripe_payment_method_id": "pm_xxxxx"
  }
]
```

**Tables Sources**: `payment_method`

---

### POST `/payment-methods/`

**Description**: Ajout d'une méthode de paiement
**URL Freebox** : `http://91.171.4.184:28012/api/payment-methods/`  
**URL Local** : `http://localhost:8012/api/payment-methods/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "payment_method_token": "pm_xxxxx",
  "payment_type": "card",
  "is_default": true,
  "billing_address": {
    "street": "Rue de la Paix",
    "street_number": "123",
    "city": "Paris",
    "postal_code": "75001",
    "country": "France"
  }
}
```

**Response Success (201)**:
```json
{
  "id": 1,
  "user": 1,
  "payment_type": "card",
  "is_default": true,
  "is_active": true,
  "is_verified": true,
  "card_last_four": "4242",
  "card_brand": "visa",
  "expiry_date": "2025-12-31",
  "billing_address": {
    "street": "Rue de la Paix",
    "city": "Paris",
    "postal_code": "75001",
    "country": "France",
    "stripe_customer_id": "cus_xxxxx"
  },
  "stripe_payment_method_id": "pm_xxxxx"
}
```

**Tables Sources**: `payment_method`

---

### POST `/payment-methods/simple/`

**Description**: Ajout d'une méthode de paiement sans adresse de facturation
**URL Freebox** : `http://91.171.4.184:28012/api/payment-methods/simple/`  
**URL Local** : `http://localhost:8012/api/payment-methods/simple/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "payment_method_token": "pm_xxxxx",
  "payment_type": "card",
  "is_default": false
}
```

**Response Success (201)**:
```json
{
  "id": 1,
  "user": 1,
  "payment_type": "card",
  "is_default": false,
  "is_active": true,
  "is_verified": true,
  "card_last_four": "4242",
  "card_brand": "visa",
  "expiry_date": "2025-12-31",
  "verification_date": "2024-01-15T10:30:00Z",
  "billing_address": null,
  "stripe_payment_method_id": "pm_xxxxx"
}
```

**Note**: Cet endpoint permet d'ajouter un moyen de paiement sans fournir d'adresse de facturation. Le champ `billing_address` sera `null` en base de données. Tous les autres champs (card_last_four, card_brand, expiry_date) sont retournés normalement.

**Tables Sources**: `payment_method`

---

### DELETE `/payment-methods/{id}/`

**Description**: Suppression d'une méthode de paiement
**URL Freebox** : `http://91.171.4.184:28012/api/payment-methods/{id}/`  
**URL Local** : `http://localhost:8012/api/payment-methods/{id}/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (204)**:
```
No Content
```

**Tables Sources**: `payment_method`

---

### POST `/payment-methods/{id}/set-default/`

**Description**: Définir une méthode de paiement comme défaut
**URL Freebox** : `http://91.171.4.184:28012/api/payment-methods/{id}/set-default/`  
**URL Local** : `http://localhost:8012/api/payment-methods/{id}/set-default/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
{
  "id": 1,
  "is_default": true
}
```

**Tables Sources**: `payment_method`

---

### POST `/payments/`

**Description**: Création d'un paiement
**URL Freebox** : `http://91.171.4.184:28012/api/payments/`  
**URL Local** : `http://localhost:8012/api/payments/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "order_id": 12345,
  "payment_method_id": 1,
  "amount": "58.00",
  "currency": "eur"
}
```

**Response Success (201)**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "completed",
  "external_payment_id": "pi_xxxxx",
  "amount": "58.00",
  "currency": "eur"
}
```

**Tables Sources**: `payments`, `payment_method`, `orders`

---

### POST `/payments/create-intent/`

**Description**: Création d'un PaymentIntent Stripe
**URL Freebox** : `http://91.171.4.184:28012/api/payments/create-intent/`  
**URL Local** : `http://localhost:8012/api/payments/create-intent/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "order_id": 12345,
  "amount": "58.00",
  "currency": "eur",
  "payment_method_id": 1
}
```

**Response Success (200)**:
```json
{
  "client_secret": "pi_xxxxx_secret_xxxxx",
  "payment_intent_id": "pi_xxxxx",
  "status": "requires_payment_method"
}
```

**Tables Sources**: `payments`, `payment_method`

---

### GET `/payments/public-key/`

**Description**: Récupération de la clé publique Stripe
**URL Freebox** : `http://91.171.4.184:28012/api/payments/public-key/`  
**URL Local** : `http://localhost:8012/api/payments/public-key/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
{
  "public_key": "pk_test_xxxxx"
}
```

---

### POST `/payments/{id}/refund/`

**Description**: Remboursement d'un paiement
**URL Freebox** : `http://91.171.4.184:28012/api/payments/{id}/refund/`  
**URL Local** : `http://localhost:8012/api/payments/{id}/refund/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
{
  "status": "refunded"
}
```

**Tables Sources**: `payments`

---

### GET `/promotions/`

**Description**: Liste des promotions actives
**URL Freebox** : `http://91.171.4.184:28012/api/promotions/`  
**URL Local** : `http://localhost:8012/api/promotions/`

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
    "code": "WELCOME10",
    "description": "10% de réduction sur votre première commande",
    "discount_value": 10.00,
    "discount_type": "percentage",
    "discount_percentage": 10.00,
    "start_date": "2024-01-01T00:00:00Z",
    "end_date": "2024-12-31T23:59:59Z",
    "is_active": true
  }
]
```

**Tables Sources**: `promotion`

---

### POST `/promotions/validate/`

**Description**: Validation d'un code promotionnel
**URL Freebox** : `http://91.171.4.184:28012/api/promotions/validate/`  
**URL Local** : `http://localhost:8012/api/promotions/validate/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "code": "WELCOME10",
  "amount": "58.00"
}
```

**Response Success (200)**:
```json
{
  "code": "WELCOME10",
  "discount_percentage": "10.00",
  "discount_value": "10.00",
  "discount_type": "percentage",
  "discount_amount": "5.80",
  "final_amount": "52.20"
}
```

**Tables Sources**: `promotion`

---

### POST `/webhooks/stripe/`

**Description**: Webhook Stripe pour les événements de paiement
**URL Freebox** : `http://91.171.4.184:28012/api/webhooks/stripe/`  
**URL Local** : `http://localhost:8012/api/webhooks/stripe/`

**Authentification** : Non requise (signature Stripe)

**Headers**:
```
Stripe-Signature: t=timestamp,v1=signature
Content-Type: application/json
```

**Body** (exemple d'événement Stripe):
```json
{
  "type": "payment_intent.succeeded",
  "data": {
    "object": {
      "id": "pi_xxxxx",
      "status": "succeeded",
      "amount": 5800,
      "currency": "eur"
    }
  }
}
```

**Response Success (200)**:
```
OK
```

**Tables Sources**: `payments`





