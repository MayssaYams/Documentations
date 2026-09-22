# Messagerie client ↔ pâtissier

| | |
|---|---|
| **Statut** | ✅ rédigé et à jour |
| **Écrit avant le développement ?** | non — fonctionnalité déjà en production, rédigé rétroactivement le 2026-09-22 |
| **Écrans concernés** | `messages_screen.dart` (`/account/messages`), `conversation_screen.dart` (`/account/messages/conversation`) |
| **Endpoints concernés** | message-service (`conversations`, `conversation_participants`, `messages`), `POST /api/conversations/find-or-create/` |
| **Tickets Linear liés** | epic PAT-43 (message d'adresse), PAT-71 (message_type/metadata forgeables) |
| **Dernière relecture** | 2026-09-22 |

---

## 1. Périmètre

La messagerie 1-to-1 client ↔ pâtissier : conversations directes créées manuellement ou automatiquement, tous les `message_type`. Ne couvre pas la logique métier qui déclenche un message automatique côté order-service/baker-service (→ [`panier-et-validation-commande.md`](panier-et-validation-commande.md) pour `order_request`, [`cycle-de-vie-commande.md`](cycle-de-vie-commande.md) pour le message d'adresse à `ready`) — ici on vérifie que ces messages, une fois créés, s'affichent et se comportent correctement dans l'UI de conversation.

## 2. Préconditions

- `client@exemple.com` et `patissier@exemple.com` (baker 5).
- Pour les scénarios automatiques : une commande de test avec `special_instructions`, ou une commande amenée à `ready`.

## 3. Scénario nominal (happy path)

1. **Ouvrir une conversation existante depuis la liste.** `push()` vers `/account/messages/conversation` — retour système revient à la liste, pas de sortie d'app.
2. **`ConversationScreen._loadConversationData()`.** Si la liste de messages est vide au chargement, l'écran ne doit pas planter sur un appel synchrone dans `initState` — gérer le cas `_contact == null` proprement (point d'attention déjà identifié dans CLAUDE.md).
3. **Envoyer un message texte.** Apparaît immédiatement côté expéditeur, `delivery_status='sent'` en base.
4. **Message `order_request` (créé au checkout avec instructions spéciales).** S'affiche avec son métadonnées (`order_id`, `order_number`, `product_id`, `product_name`) correctement formatées, pas en JSON brut.
5. **Message d'adresse (créé au passage à `ready`).** S'affiche avec l'adresse complète, correctement formaté.
6. **Retour à la liste.** `messages_screen` se recharge (comportement `push()` post-PAT-42 : l'écran source reste vivant et se rafraîchit au retour).

## 4. Cas de bord et erreurs attendues

- **Conversation sans aucun message (liste vide).** Ne doit pas crasher — vérifier explicitement `_contact` null.
- **`getMessagesByOrder` — piège d'escape connu.** Vérifier que l'URL utilise `$orderId` sans backslash dans `message_api.dart` (bug déjà réintroduit une fois par un agent). `grep -n '\\\\\$orderId' lib/features/messages/data/datasources/message_api.dart` doit être vide.
- **`message_type`/`metadata` forgés côté client.** À date, PAT-71 (Backlog) documente que ces champs et les participants d'une conversation ne sont pas suffisamment validés côté serveur — tant que ce ticket n'est pas livré, **ne pas** considérer cette fonctionnalité comme sûre contre un client malveillant ; le scénario nominal ci-dessus suffit pour la validation fonctionnelle, pas pour la sécurité.
- **Conversation créée automatiquement deux fois pour le même couple client/pâtissier.** `find-or-create` doit réutiliser la conversation existante, jamais en dupliquer une.

## 5. Règles métier à vérifier

- `delivery_status` toujours `'sent'` par défaut sur tout INSERT dans `messages` (CLAUDE.md, règle non négociable).
- Conversation `direct` = 1-to-1 uniquement.
- L'adresse complète du pâtissier ne doit apparaître dans un message **que** si son déclencheur légitime a eu lieu (commande à `ready`) — jamais avant, jamais dans une conversation sans commande associée.

## 6. Non-régressions connues

- **`\$orderId` échappé par erreur** dans `getMessagesByOrder` (CLAUDE.md, « Bugs connus ») — réapparu au moins une fois par un agent, à vérifier explicitement à chaque modification de `message_api.dart`.
- **`ConversationScreen._loadConversationData()`** — appel synchrone sur liste vide en `initState`, cas déjà identifié comme fragile.
- **Message `order_request` avalé silencieusement** (contrainte DB qui refusait autrefois ce type de message) — voir [`panier-et-validation-commande.md`](panier-et-validation-commande.md) §6.

## 7. Comment vérifier

- Backend : `message-service` (`manage.py test`).
- `grep -n '\\\\\$orderId' Patisry/lib/features/messages/data/datasources/message_api.dart` doit rester vide — à ajouter à toute checklist de relecture de ce fichier.
- Frontend : `flutter analyze` + test manuel staging.

## 8. Definition of done

- [ ] Conversation sans message ne crashe pas
- [ ] Message texte, `order_request` et message d'adresse s'affichent correctement formatés
- [ ] `$orderId` non échappé dans `message_api.dart`
- [ ] `delivery_status='sent'` vérifié en base sur au moins un message de chaque type
- [ ] Retour système et rechargement au retour sur la liste fonctionnent
- [ ] Tests `message-service` verts
