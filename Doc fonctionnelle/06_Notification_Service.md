# Notification Service API Documentation

**Base URL Freebox** : `http://91.171.4.184:28005/api/`
**Base URL Local** : `http://localhost:8005/api/`

## Endpoints

### GET `/notifications/`

**Description**: Liste des notifications de l'utilisateur connecté
**URL Freebox** : `http://91.171.4.184:28005/api/notifications/`  
**URL Local** : `http://localhost:8005/api/notifications/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
```

**Query Parameters**:
- `type`: Filtrer par type de notification
- `is_read`: Filtrer par statut de lecture (true/false)
- `page`: Numéro de page
- `page_size`: Taille de page

**Response Success (200)**:
```json
{
  "success": true,
  "count": 10,
  "notifications": [
    {
      "id": 1,
      "notification_type": "order_update",
      "title": "Commande confirmée",
      "message": "Votre commande #12345 a été confirmée",
      "data": {
        "order_id": 12345
      },
      "is_read": false,
      "is_sent": true,
      "sent_at": "2024-01-15T10:30:00Z",
      "read_at": null,
      "expires_at": null,
      "created_at": "2024-01-15T10:30:00Z"
    }
  ]
}
```

**Tables Sources**: `user_notifications`

---

### GET `/notifications/{id}/`

**Description**: Détails d'une notification spécifique
**URL Freebox** : `http://91.171.4.184:28005/api/notifications/{id}/`  
**URL Local** : `http://localhost:8005/api/notifications/{id}/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
{
  "success": true,
  "notification": {
    "id": 1,
    "notification_type": "order_update",
    "title": "Commande confirmée",
    "message": "Votre commande #12345 a été confirmée",
    "data": {
      "order_id": 12345
    },
    "is_read": false,
    "is_sent": true,
    "sent_at": "2024-01-15T10:30:00Z",
    "read_at": null,
    "expires_at": null,
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

**Tables Sources**: `user_notifications`

---

### GET `/notifications/unread/`

**Description**: Récupération des notifications non lues
**URL Freebox** : `http://91.171.4.184:28005/api/notifications/unread/`  
**URL Local** : `http://localhost:8005/api/notifications/unread/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
{
  "success": true,
  "count": 5,
  "notifications": [
    {
      "id": 1,
      "notification_type": "order_update",
      "title": "Commande confirmée",
      "message": "Votre commande #12345 a été confirmée",
      "data": {},
      "is_read": false,
      "is_sent": true,
      "sent_at": "2024-01-15T10:30:00Z",
      "read_at": null,
      "expires_at": null,
      "created_at": "2024-01-15T10:30:00Z"
    }
  ]
}
```

**Tables Sources**: `user_notifications`

---

### PUT `/notifications/{id}/read/`

**Description**: Marquer une notification comme lue
**URL Freebox** : `http://91.171.4.184:28005/api/notifications/{id}/read/`  
**URL Local** : `http://localhost:8005/api/notifications/{id}/read/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "id": 1,
    "notification_type": "order_update",
    "title": "Commande confirmée",
    "message": "Votre commande #12345 a été confirmée",
    "is_read": true,
    "read_at": "2024-01-15T10:35:00Z"
  },
  "message": "Notification marked as read"
}
```

**Tables Sources**: `user_notifications`

---

### PUT `/notifications/mark-all-read/`

**Description**: Marquer toutes les notifications comme lues
**URL Freebox** : `http://91.171.4.184:28005/api/notifications/mark-all-read/`  
**URL Local** : `http://localhost:8005/api/notifications/mark-all-read/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
{
  "success": true,
  "message": "5 notifications marked as read",
  "count": 5
}
```

**Tables Sources**: `user_notifications`

---

### POST `/notifications/send/`

**Description**: Envoyer une notification (Admin seulement)
**URL Freebox** : `http://91.171.4.184:28005/api/notifications/send/`  
**URL Local** : `http://localhost:8005/api/notifications/send/`

**Authentification** : Requise (Admin)

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "user_id": 1,
  "notification_type": "promotion",
  "title": "Nouvelle promotion",
  "message": "Découvrez nos nouvelles offres !",
  "data": {
    "promotion_id": 123
  },
  "expires_at": "2024-01-20T23:59:59Z"
}
```

**Response Success (201)**:
```json
{
  "success": true,
  "message": "Notification sent successfully",
  "data": {
    "id": 1,
    "notification_type": "promotion",
    "title": "Nouvelle promotion",
    "message": "Découvrez nos nouvelles offres !",
    "data": {
      "promotion_id": 123
    },
    "is_read": false,
    "is_sent": true,
    "sent_at": "2024-01-15T10:30:00Z",
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

**Tables Sources**: `user_notifications`

---

### DELETE `/notifications/{id}/`

**Description**: Supprimer une notification
**URL Freebox** : `http://91.171.4.184:28005/api/notifications/{id}/`  
**URL Local** : `http://localhost:8005/api/notifications/{id}/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (204)**:
```
No Content
```

**Tables Sources**: `user_notifications`





