# Message Service API Documentation

**Base URL Freebox** : `http://91.171.4.184:28004/api/`
**Base URL Local** : `http://localhost:8004/api/`

## Endpoints

### GET `/conversations/`

**Description**: Liste des conversations de l'utilisateur connecté
**URL Freebox** : `http://91.171.4.184:28004/api/conversations/`  
**URL Local** : `http://localhost:8004/api/conversations/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "conversation_type": "direct",
    "title": "Conversation avec Marie",
    "description": null,
    "is_active": true,
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
]
```

**Tables Sources**: `conversations`, `conversation_participants`

---

### POST `/conversations/`

**Description**: Création d'une nouvelle conversation
**URL Freebox** : `http://91.171.4.184:28004/api/conversations/`  
**URL Local** : `http://localhost:8004/api/conversations/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "conversation_type": "direct",
  "title": "Nouvelle conversation",
  "participant_ids": [2, 3]
}
```

**Response Success (201)**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Tables Sources**: `conversations`, `conversation_participants`

---

### GET `/conversations/{id}/messages/`

**Description**: Récupération des messages d'une conversation
**URL Freebox** : `http://91.171.4.184:28004/api/conversations/{id}/messages/`  
**URL Local** : `http://localhost:8004/api/conversations/{id}/messages/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
[
  {
    "id": "660e8400-e29b-41d4-a716-446655440001",
    "sender_id": 2,
    "message_type": "text",
    "content": "Bonjour !",
    "delivery_status": "read",
    "created_at": "2024-01-15T10:35:00Z"
  }
]
```

**Response Error (403)**:
```json
{
  "error": "Not a participant"
}
```

**Tables Sources**: `messages`, `conversation_participants`

---

### POST `/messages/`

**Description**: Envoi d'un message dans une conversation
**URL Freebox** : `http://91.171.4.184:28004/api/messages/`  
**URL Local** : `http://localhost:8004/api/messages/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**:
```json
{
  "conversation_id": "550e8400-e29b-41d4-a716-446655440000",
  "message_type": "text",
  "content": "Bonjour, comment allez-vous ?",
  "content_metadata": null,
  "reply_to_id": null
}
```

**Response Success (201)**:
```json
{
  "id": "660e8400-e29b-41d4-a716-446655440002"
}
```

**Tables Sources**: `messages`, `conversations`, `conversation_participants`

---

### PUT `/messages/{id}/read/`

**Description**: Marquer un message comme lu
**URL Freebox** : `http://91.171.4.184:28004/api/messages/{id}/read/`  
**URL Local** : `http://localhost:8004/api/messages/{id}/read/`

**Authentification** : Requise

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response Success (200)**:
```json
{
  "message": "Message marked as read"
}
```

**Tables Sources**: `messages`





