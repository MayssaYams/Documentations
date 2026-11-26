# Cycle de vie d'une commande

| | |
|---|---|
| **Statut** | ✅ rédigé et à jour |
| **Écrit avant le développement ?** | non — fonctionnalité déjà en production, rédigé rétroactivement le 2026-09-22 |
| **Écrans concernés** | `orders_screen.dart` (`/account/orders`), `order_detail_screen.dart` (`/account/orders/detail`), `ready_dialogs.dart` |
| **Endpoints concernés** | order-service — transitions de statut, contrainte `chk_order_status_valid` en base |
| **Tickets Linear liés** | epic PAT-43, PAT-42 (navigation retour depuis le détail) |
| **Dernière relecture** | 2026-09-22 |

---

## 1. Périmètre

Le cycle de vie d'une commande **une fois créée** (la création elle-même → [`panier-et-validation-commande.md`](panier-et-validation-commande.md)) : transitions de statut, permissions par rôle, écrans liste/détail. Les avis et le message d'adresse de retrait sont traités dans leurs propres fichiers ([`avis.md`](avis.md), [`messages.md`](messages.md)) mais leur déclenchement depuis ce cycle est vérifié ici.

## 2. Préconditions

- Une commande de test entre `patissier@exemple.com` (baker 5) et `client@exemple.com`, dans chaque statut à tester (créer plusieurs commandes si besoin plutôt que de réutiliser la même).
- Pour le cas « compte double rôle » : un compte qui a à la fois un profil pâtissier actif et une commande passée en tant que client chez un **autre** pâtissier de test.

## 3. Scénario nominal (happy path)

Chaîne de statuts (contrainte DB `chk_order_status_valid`) :
```
pending_confirmation → in_preparation → ready → awaiting_pickup → completed
```

1. **Pâtissier fait avancer la commande.** `pending_confirmation` → `in_preparation` → `ready` → `awaiting_pickup`, chaque transition déclenchée depuis `order_detail_screen`.
2. **Passage à `ready`.** Déclenche l'envoi automatique du message contenant l'**adresse complète de retrait** au client (règle CLAUDE.md : adresse transmise uniquement à ce moment, jamais avant). Vérifier le message en base, pas seulement l'UI.
3. **Client clôture.** Depuis `awaiting_pickup`, seul le client peut poser `completed` (bouton « J'ai récupéré ma commande »).
4. **Annulation.** Depuis `pending_confirmation` ou `in_preparation`, par le pâtissier **ou** le client.
5. **Retour depuis le détail de commande.** `push()` depuis la liste : le retour système revient à `orders_screen`, qui se recharge (cf. [`../transverse/navigation-retour-systeme.md`](../transverse/navigation-retour-systeme.md)).

## 4. Cas de bord et erreurs attendues

- **Pâtissier qui pose `completed`.** Refusé — seul le client clôt une commande.
- **Client qui pose autre chose que `completed`.** Refusé.
- **Client qui pose `completed` depuis un statut autre que `awaiting_pickup`.** Refusé.
- **Tout saut d'étape** (`pending_confirmation` → `ready` directement) **et tout retour en arrière.** Refusés par la contrainte DB — vérifier que l'erreur remonte proprement côté UI (pas de crash).
- **Annulation depuis `ready` ou après.** Refusée.
- **Compte double rôle.** Un compte pâtissier qui a commandé chez un autre pâtissier doit voir la **vue client** sur cette commande précise, avec le bouton « J'ai récupéré ma commande » — bug réel déjà rencontré : le code testait le type de compte global au lieu du rôle sur cette commande. **À retester à chaque évolution de cet écran.**
- **Panier multi-pâtissiers.** Vérifier que chaque commande du groupe (même `checkout_reference`) a son propre cycle de statut indépendant — faire avancer une commande du groupe ne doit pas toucher les autres.

## 5. Règles métier à vérifier

- Click & collect uniquement : aucune référence à une livraison ne doit apparaître sur ces écrans.
- Adresse de retrait effective = point de collecte alternatif si renseigné, sinon adresse principale — c'est CETTE adresse qui part dans le message à `ready`, pas l'adresse saisie initialement si un point de collecte alternatif existe (cf. [`../patissier/adresse-et-position.md`](../patissier/adresse-et-position.md)).
- `delivery_status='sent'` sur le message d'adresse comme sur tout autre message généré automatiquement.

## 6. Non-régressions connues

- **Bascule de rôle sur une commande précise** (voir §4) — bug réel, cause connue (test du type de compte global au lieu du rôle contextuel).
- **PAT-42 (2026-09-21)** : avant correctif, le retour système depuis le détail de commande **fermait l'application**. Corrigé, mais retester sur device réel après merge de PAT-42 (pas encore fait au moment de la rédaction de cette fiche).

## 7. Comment vérifier

- Backend : `order-service` (`manage.py test`, tunnel DB — voir [`role.md`](../role.md)). Prêter attention aux tests de transitions interdites, pas seulement autorisées.
- Vérification directe en base après une transition : `SELECT status FROM orders WHERE id = ...` et `SELECT * FROM messages WHERE order-related metadata... ORDER BY created_at DESC LIMIT 1` pour confirmer l'envoi du message d'adresse à `ready`.
- Frontend : `flutter analyze` + test manuel sur staging avec les deux comptes de test.

## 8. Definition of done

- [ ] Toutes les transitions autorisées passent, dans l'ordre, pour le pâtissier et pour le client
- [ ] Toutes les transitions interdites de la section 4 sont refusées proprement (pas de 500, message clair)
- [ ] Le message d'adresse de retrait est bien envoyé à `ready`, avec la bonne adresse effective, vérifié en base
- [ ] Compte double rôle : vue client correcte sur une commande où l'utilisateur n'est pas le pâtissier
- [ ] Retour système depuis le détail de commande revient à la liste (pas de sortie d'app)
- [ ] Tests `order-service` verts
