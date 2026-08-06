# Full-stack — rôle et repères

Voir d'abord [`Documentations/_conventions.md`](../_conventions.md) pour les règles communes. Orchestré par le **Tech Lead** ([`Documentations/tech-lead/role.md`](../tech-lead/role.md)) : reçoit des tâches déjà découpées, met à jour ce dossier après chaque tâche, pas d'échange en cours de tâche.

## Mission

Implémenter les tâches découpées par le Tech Lead, côté Flutter (`Patisry/`) et/ou Django (`Backend/<service>/`).

## Repères Flutter

- `Patisry/lib/core/config/app_config.dart` — toutes les URLs par environnement (local/freebox/staging), sélectionné via `--dart-define=ENVIRONMENT=...`.
- `Patisry/lib/core/network/dio_client.dart` + `core/network/interceptors/auth_interceptor.dart` — client HTTP singleton, refresh JWT automatique.
- `Patisry/lib/core/services/auth_service.dart` — état de session (`ChangeNotifier`), type de compte (client/baker).
- `Patisry/lib/shared/widgets/back_bar/back_bar.dart` — `goBackOrHome()`, le point d'entrée unique pour un bouton retour cohérent (essaie `Navigator.pop`, puis l'historique navigateur réel sur web, puis repli sur `/`). Ne pas utiliser `Navigator.pop`/`context.go('/')` en dur ailleurs.
- Navigation : `context.go()` partout, pas `context.push()` — `push()` ne met pas à jour l'URL du navigateur sur web avec la version de go_router utilisée ici. Les routes avec paramètre (`/products/:id`, etc.) ont besoin d'un `key: ValueKey(...)` explicite sur le builder dans `app.dart`, sinon go_router réutilise le même widget/state entre deux navigations vers la même route.

## Repères Backend

- Chaque service = sa propre responsabilité DB — ne pas modifier la table d'un autre service directement, sauf le pattern déjà établi (order-service qui écrit dans les tables message-service au checkout via `connection.cursor()` + SQL brut).
- **Ne jamais** faire `manage.py migrate`/`makemigrations` ni `CREATE TABLE`/`ALTER TABLE` depuis le code applicatif — schéma géré à la main, scripts dans `Documentations/database/` (et `scripts/db/` selon service).
- Pièges connus : `baker.userid` vs `user_id` (nom de colonne variable selon service), `product.baker_id` peut être NULL (fallback `product_user` uniquement si NULL, jamais prioritaire) — détail dans [`Documentations/tech-lead/role.md`](../tech-lead/role.md).
- `message_api.dart` → `getMessagesByOrder` : vérifier que l'URL utilise `$orderId` sans backslash (bug d'échappement déjà réapparu une fois).

## Comment lancer les tests

```bash
ssh -p 31456 -L 5433:127.0.0.1:5432 alvin@91.171.4.184 -N -f   # tunnel DB Freebox
cd Backend/<service> && source venv/bin/activate
JWT_SECRET_KEY='<valeur dev partagée>' DB_HOST=127.0.0.1 DB_PORT=5433 python manage.py test --keepdb
```
`user-service` fait exception : il force SQLite dès que `'test' in sys.argv`, pas besoin du tunnel pour lui.

Flutter :
```bash
cd Patisry && flutter analyze && flutter build web --no-tree-shake-icons
```
Les deux doivent être propres (`flutter analyze` sans erreur) avant de considérer une tâche frontend terminée — CLAUDE.md l'exige.

## Repères doc existante

- `Documentations/Doc fonctionnelle/0X_<Service>.md` — doc API complète par service (endpoints, payloads, exemples).
- `Documentations/DATABASE_SCHEMA.md` — schéma DB complet.
