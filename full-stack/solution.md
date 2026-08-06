# La solution Patisry — implémentation (Full-stack)

Ce document explique **comment le code est réellement organisé et où intervenir**. Pour le « pourquoi » architectural, voir [`tech-lead/solution.md`](../tech-lead/solution.md).

Vérifier un pointeur avant d'agir dessus — le code bouge (voir [`_conventions.md`](../_conventions.md)).

---

## 1. Le trajet d'une requête, de bout en bout

```
Écran Flutter
  └→ <feature>/data/datasources/<x>_api.dart      (couche API de la feature)
       └→ DioClient().instance                     (singleton Dio)
            └→ AuthInterceptor                     (ajoute le Bearer, refresh auto)
                 └→ AppConfig.api<X>Service        (URL selon l'environnement)
                      └→ [dev] IP:port direct  |  [staging] nginx → conteneur
                           └→ Django REST → SQL brut ou ORM → PostgreSQL partagé
```

**Fichiers pivots :**
- `Patisry/lib/core/config/app_config.dart` — toutes les URLs par environnement. Sélection via `--dart-define=ENVIRONMENT=local|freebox|staging` (défaut : `freebox`).
- `Patisry/lib/core/network/dio_client.dart` — instance Dio unique.
- `Patisry/lib/core/network/interceptors/auth_interceptor.dart` — Bearer + refresh JWT (access 12 h, refresh 7 j).
- `Patisry/lib/core/services/auth_service.dart` — `ChangeNotifier`, session courante, type de compte.
- `Patisry/lib/core/storage/secure_storage.dart` — stockage des tokens.

**Routage staging** (nginx, utile pour comprendre un 404 en staging qui n'existe pas en dev) : le préfixe du chemin détermine le service. `/api/auth/` → auth, `/api/users/` → user, `/api/display/` → display, `/api/products/` → product, `/api/conversations/` et `/api/messages/` → message, `/api/notifications/` et `/api/device-tokens/` → notification, `/api/cart/` et `/api/orders/` → order, `/api/favorites/` → favorite, `/api/bakers/` → baker, `/api/search/` → search, `/api/payments/` `/api/promotions/` `/api/webhooks/` → payment, `/api/subscription-plans/` `/api/user-subscriptions/` `/api/newsletter/` → subscription, `/api/admin/` → admin (**sauf** `/api/admin/push/` → notification), `/api/reviews/` → review, `/api/analytics/` → analytics.

En dev (Freebox) il n'y a pas de nginx : chaque service est joignable sur `91.171.4.184:<port interne + 20000>`.

---

## 2. Règles Flutter à ne pas enfreindre

### Navigation

- **`context.go()` partout, jamais `context.push()`.** Avec la version de go_router utilisée, `push()` ne met pas à jour l'URL du navigateur sur le web. Un écran ouvert en `push()` se retrouve avec l'URL de l'écran précédent, et le bouton retour boucle.
- **Toute route paramétrée a besoin d'un `key: ValueKey(...)` explicite** dans `app.dart`. go_router dérive sa `pageKey` du **motif** de route (`/products/:id`), pas du chemin résolu — sans clé distincte, Flutter réutilise le même `State` d'un produit à l'autre : l'URL change, le contenu non.
- **Bouton retour** : toujours passer par `goBackOrHome(context)` (`shared/widgets/back_bar/back_bar.dart`). Il essaie `Navigator.pop()`, puis l'historique **réel** du navigateur, et ne retombe sur `/` qu'en dernier recours. Ne jamais écrire `Navigator.pop()` ou `context.go('/')` en dur pour un retour.
- Code web-only : passer par une **importation conditionnelle** (`browser_history.dart` / `_stub.dart` / `_web.dart`), jamais `dart:html` directement.

### Rôle par entité, pas par compte

Un compte pâtissier **reste client** sur les commandes qu'il a passées ailleurs. Ne jamais conditionner un affichage sur `AuthService.userType` seul quand il s'agit d'une entité précise — comparer les identifiants :

```dart
final isBaker = detail.bakerUserId != null
    ? (currentUserId != null && currentUserId == detail.bakerUserId)
    : currentUser?.type == UserType.baker;
```

### Champs optionnels vides

Envoyer `null`, **pas `''`**. Plusieurs colonnes ont une contrainte `CHECK` du type « respecte le format **OU** est NULL » (`chk_phone_format`, `chk_postal_code_format`) : une chaîne vide ne satisfait ni l'un ni l'autre et fait échouer la sauvegarde.

### Ne pas proposer un choix qui mène à une impasse

Cas concret déjà corrigé sur la fiche produit : si tous les créneaux d'une date sont grisés, la **date** doit l'être aussi.

---

## 3. Règles Django à ne pas enfreindre

### Le schéma ne se gère jamais depuis le code

**Interdit** : `makemigrations`, `migrate`, `CREATE TABLE`, `ALTER TABLE` depuis le code applicatif. Les modèles sont `managed = False`, les dossiers `migrations/` restent vides. Le SQL vit dans `Documentations/database/*.sql` et s'applique à la main.

Si une table manque : lever une erreur explicite, **jamais** la créer.

### Communication inter-services = SQL brut

Pas d'appels REST entre backends. On écrit directement via `connection.cursor()` sur la base partagée. Cas assumé : order-service écrit dans les tables de message-service au checkout.

Sur un `INSERT` dans `messages` : **toujours** inclure `delivery_status` avec `'sent'`.

### Ne jamais avaler une exception dans un décorateur d'authentification

Piège réel : `verify_user_access` (user-service) enveloppait **tout l'appel de la vue** dans un `try/except Exception`. Résultat : une erreur métier sans rapport (violation de contrainte `CHECK`) devenait un **401**, et l'app déconnectait l'utilisateur de force sur un bug qui n'avait rien à voir avec l'auth. Le `try/except` ne doit couvrir que le décodage du token.

### Colonnes dont le nom varie selon l'environnement

- `baker.userid` **ou** `baker.user_id` → `baker_user_fk_column()`
- `product.baker_id` **ou** `product.bakerid` → `_product_baker_column_name()`

Ne jamais écrire ces noms en dur.

### Double lien produit ↔ pâtissier

`product.baker_id` (souvent NULL) **ou** `product_user(product_id, user_id)`. **`baker_id` prioritaire**, `product_user` seulement en repli si NULL — `product_user` peut contenir des lignes périmées pointant vers un autre compte.

```sql
WHERE baker_id = %s
   OR (baker_id IS NULL AND id IN (
        SELECT pu.product_id FROM product_user pu WHERE pu.user_id = %s))
```

---

## 4. Le checkout, dans le code

`order-service/orders/views.py` :

1. Le panier est éclaté **par pâtissier** → N commandes, partageant un `checkout_reference` (UUID).
2. Statut initial : `pending_confirmation`.
3. Pour chaque article portant des `special_instructions` : `find-or-create` d'une conversation directe client↔pâtissier (`POST /api/conversations/find-or-create/`), puis insertion d'un message `message_type = 'order_request'` avec `delivery_status = 'sent'` et un `metadata` JSON contenant `order_id`, `order_number`, `product_id`, `product_name`.

Machine à états (constantes en tête de `views.py`) :
```
pending_confirmation → in_preparation → ready → awaiting_pickup → completed
```
Pâtissier : jusqu'à `awaiting_pickup` uniquement. Client : `completed` uniquement, et seulement depuis `awaiting_pickup`. Annulation depuis `pending_confirmation` ou `in_preparation` seulement. Pas de saut, pas de retour.

**Ces statuts sont doublés par une contrainte `CHECK` en base.** Ajouter un statut côté Python sans mettre à jour `chk_order_status_valid` produit une erreur 500 à l'insertion.

---

## 5. Lancer et vérifier

**Backend** (tunnel SSH obligatoire vers la base dev) :
```bash
ssh -p 31456 -L 5433:127.0.0.1:5432 alvin@91.171.4.184 -N -f
cd Backend/<service> && source venv/bin/activate
JWT_SECRET_KEY='<valeur dev>' DB_HOST=127.0.0.1 DB_PORT=5433 python manage.py test --keepdb
```
**Exception `user-service`** : force SQLite dès que `'test' in sys.argv` (`core/settings.py`), le tunnel est inutile pour lui.

Le venv est tantôt `venv/`, tantôt `.venv/` selon le service.

**Frontend** — les deux doivent être propres avant de considérer une tâche terminée :
```bash
cd Patisry && flutter analyze && flutter build web --no-tree-shake-icons
```
`flutter analyze` remonte ~300 avertissements *info* pré-existants (`withOpacity` déprécié, `prefer_const`…). Ce qui compte est **zéro `error`** : `flutter analyze | grep -c "^   error"`.

**Après un rebuild web, forcer un rechargement dur du navigateur** avant de retester : du JS en cache a déjà produit un faux négatif (un correctif jugé cassé alors qu'il fonctionnait).

---

## 6. Réflexe de diagnostic

Une erreur qui ressemble à un bug de code peut être une **dérive de schéma** : le même code marche en dev et échoue en staging parce que la base n'a pas reçu les mêmes scripts SQL. Avant de chercher longtemps dans le code, **comparer la structure de la table concernée entre les deux environnements**. Trois pannes consécutives du checkout venaient de là, pas du code.
