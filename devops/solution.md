# La solution Patisry — infrastructure (DevOps)

Ce document explique **comment la plateforme tourne, se déploie et où sont ses fragilités opérationnelles**. Les repères d'accès rapides sont dans [`role.md`](role.md) ; l'architecture applicative dans [`tech-lead/solution.md`](../tech-lead/solution.md).

Vérifier avant de s'appuyer sur un détail (voir [`_conventions.md`](../_conventions.md)).

---

## 1. Ce qu'il faut faire tourner

**16 conteneurs** : 15 microservices Django + PostgreSQL/PostGIS, plus nginx en frontal sur staging. Le frontend Flutter Web est du **statique servi par nginx**, pas un conteneur.

Point structurant : **une seule base pour les 15 services**. Il n'y a pas de base par service. Toute opération sur la base impacte potentiellement tout le système.

---

## 2. Les trois environnements

| | dev | staging | production |
|---|---|---|---|
| Hébergement | Freebox (domicile) | Scaleway DEV1-M | **n'existe pas** |
| Accès | `91.171.4.184`, SSH port `31456`, user `alvin` | `51.15.236.77`, clé `~/.ssh/patisry-staging-deploy`, users `ubuntu` / `deploy` | — |
| Exposition | port interne **+ 20000** (auth 8000 → 28000) | nginx → `stg.patisry.fr` (HTTPS) | — |
| Base | `mytestpatisry` / user `local` | `patisry_db` / user `patisry_backend`, conteneur `patisry-db` | — |
| Déploiement | manuel | CI au push sur `staging` | — |
| Orchestration | `docker-compose` par service, `/home/alvin/services/<service>/` | un seul `docker-compose.staging.yml` dans `/opt/patisry` | — |

**`patisry.fr` — statut changé depuis le 2026-07-27, ce n'est TOUJOURS PAS une vraie production, mais ce n'est plus un simple parking.** Vérifié le 2026-08-05 : le DNS pointe maintenant vers la VM staging (`51.15.236.77`), nginx y sert le même build Flutter que `stg.patisry.fr`. Un bug CORS déjà repéré (le bucket Object Storage n'autorise que l'origine `stg.patisry.fr`, pas `patisry.fr` — les images cassent). Cause/intention du changement DNS non documentée, à clarifier avec le CTO avant de considérer ce domaine comme fiable pour autre chose que du test. Le choix Azure vs AWS pour une vraie prod est toujours ouvert.

---

## 3. Déploiement dev (Freebox) — manuel

```bash
cd Backend/<service> && ./deploy_freebox.sh
```

Le script : build l'image en local → l'exporte en `.tar.gz` → la transfère en SSH → `docker load` → redémarre le service. Compter **2 à 5 minutes**, à lancer en tâche de fond.

Il déchiffre puis rechiffre `.env.freebox` (git-crypt) à chaque exécution — d'où un `.env.freebox` qui apparaît systématiquement modifié dans `git status`. **Ce bruit ne doit jamais être commité.**

Chaque service a un `entrypoint.sh` qui attend PostgreSQL (`nc -z` sur `DB_HOST:DB_PORT`) avant de démarrer. Ne pas contourner ce mécanisme.

---

## 4. Déploiement staging — CI uniquement, jamais à la main

**Chaque service backend a son propre dépôt GitHub** (`github.com/MayssaYams/<Service-Name>`), avec `.github/workflows/deploy-staging.yml` déclenché **au push sur `staging`** :

1. Build de l'image, push sur `rg.fr-par.scw.cloud/patisry-staging/<service>` (tags `:latest` **et** `:<sha>`), plateforme `linux/amd64`, cache GitHub Actions.
2. SSH vers la VM en tant que `deploy` → `docker compose -f docker-compose.staging.yml pull <service>` puis `up -d --no-deps <service>` → `docker image prune -f`.

Le dépôt `Patisry` (Flutter) a son propre workflow : build web release avec `--dart-define=ENVIRONMENT=staging --dart-define=API_BASE_URL=https://stg.patisry.fr` → SCP vers `/opt/patisry/web` → `docker exec patisry-nginx nginx -s reload`. Compter **~3 minutes**, contre ~1 minute pour un service backend.

### La contrainte de charge

**La VM ne supporte pas plusieurs déploiements simultanés.** Pousser **2 dépôts maximum à la fois**, et attendre la fin des runs de la paire avant la suivante :

```bash
gh run watch <run-id> --exit-status
```

### Routage nginx (`/opt/patisry/nginx/patisry.conf`)

Le préfixe d'URL détermine le service : `/api/auth/`, `/api/users/`, `/api/display/`, `/api/products/`, `/api/conversations/` + `/api/messages/`, `/api/notifications/` + `/api/device-tokens/`, `/api/cart/` + `/api/orders/`, `/api/favorites/`, `/api/bakers/`, `/api/search/`, `/api/payments/` + `/api/promotions/` + `/api/webhooks/`, `/api/subscription-plans/` + `/api/user-subscriptions/` + `/api/newsletter/`, `/api/admin/`, `/api/reviews/`, `/api/analytics/`.

**Exception piégeuse** : `/api/admin/push/` part vers **notification-service**, pas admin-service. Ce bloc doit rester plus spécifique que `/api/admin/` — nginx choisit le préfixe le plus long.

`location /` sert le Flutter Web statique. Certificats via certbot (`/.well-known/acme-challenge/`).

---

## 5. Le processus de release

Établi et éprouvé le 2026-07-27 :

1. Commiter sur `develop`, dépôt par dépôt. **Exclure** `.env.freebox`, `__pycache__/`, `media/`.
2. Bumper la version dans `Patisry/pubspec.yaml` (`<version>+<buildNumber>`), tests et build verts partout.
3. Pousser `develop`.
4. `staging` en fast-forward depuis `develop`, pousser **2 dépôts à la fois**, attendre chaque paire.
5. **Vérifier le déploiement réel** avant de taguer : `grep` du correctif dans le conteneur (`docker exec <conteneur> grep ... /app/...`) et/ou vérification visuelle sur `stg.patisry.fr`. Un run CI vert prouve que le déploiement a eu lieu, pas que le bon code tourne.
6. Taguer `<version>` sur `staging` dans chaque dépôt concerné et pousser le tag.

### Builds mobiles

```bash
cd Patisry
flutter build appbundle --release --dart-define=ENVIRONMENT=staging --dart-define=API_BASE_URL=https://stg.patisry.fr
flutter build apk       --release --dart-define=ENVIRONMENT=staging --dart-define=API_BASE_URL=https://stg.patisry.fr
```
Sorties recopiées dans `build/app/outputs/bundle/release/` sous le nom `patisry-STG.V<version>.aab|apk`.

**Deux pièges vécus :**
- Le message final de la CLI Flutter affiche parfois un **ancien nom de fichier** — le vrai résultat est `app-release.aab`. Vérifier la date du fichier, pas le message.
- Le compilateur AOT se fait **tuer par manque de mémoire** (`exit code -9`, « Dart snapshot generator failed ») si la machine est chargée. Libérer de la RAM (`./gradlew --stop` dans `android/`, fermer les IDE) et relancer. Ce n'est pas une erreur de code.

Vérifier l'URL réellement embarquée avant distribution :
```bash
unzip -p <fichier>.aab "base/lib/*/libapp.so" | strings | grep -o "stg\.patisry\.fr\|patisry\.fr" | sort -u
```
Et le `versionCode` dans `build/app/intermediates/packaged_manifests/release/.../AndroidManifest.xml` — Google Play refuse un `versionCode` déjà utilisé.

---

## 6. La base de données — le point noir

**Le schéma est appliqué à la main, environnement par environnement, sans aucun registre de ce qui a été joué où.** Pas de table de migrations. Django ne gère rien (modèles `managed = False`, dossiers `migrations/` vides). Les scripts sont dans `Documentations/database/*.sql`, majoritairement idempotents.

### Ce que ça a déjà coûté

Le 2026-07-27, staging avait plusieurs migrations de retard : **le checkout était totalement cassé**. Les écarts se sont révélés **un par un**, chaque correctif dévoilant le suivant : colonne `orders.checkout_reference` absente → contrainte `chk_order_status_valid` périmée → `chk_message_type_valid` périmée → tables `review_reports` / `platform_settings` et colonnes `product_reviews.baker_reply*` absentes (soit exactement les fonctionnalités déployées le jour même) → table `billing_history` que **aucun script ne créait**.

Résolution : audit complet de schéma, puis rejeu des scripts. Détail dans [`state.md`](state.md).

### La méthode d'audit (à rejouer avant toute mise en production)

Extraire des deux bases puis comparer localement — colonnes, contraintes `CHECK`, index :

```sql
SELECT table_name, column_name, data_type, is_nullable FROM information_schema.columns WHERE table_schema='public' ORDER BY 1,2;
SELECT c.relname, con.conname, pg_get_constraintdef(con.oid) FROM pg_constraint con JOIN pg_class c ON c.oid=con.conrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND con.contype='c' ORDER BY 1,2;
SELECT tablename, indexname FROM pg_indexes WHERE schemaname='public' ORDER BY 1;
```

Accès : dev → `PGPASSWORD=... psql -h 127.0.0.1 -U local -d mytestpatisry` depuis la Freebox. Staging → `docker exec patisry-db psql -U patisry_backend -d patisry_db`. Les identifiants sont dans l'environnement des conteneurs, **à ne jamais recopier en clair dans cette documentation** (destinée à devenir un dépôt Git).

**Toujours vérifier le volume des tables concernées avant une opération destructive** (`DROP CONSTRAINT`, changement de nullabilité) : lors de l'incident, toutes les tables touchées étaient vides, donc sans risque — ce ne sera pas toujours le cas.

Note : `auth_permission`, `django_admin_log`, `django_content_type`, `django_session` sont absentes de staging **et c'est sans conséquence** : les services n'utilisent pas l'admin Django.

### Ce qu'il faut retenir

**Le même scénario se reproduira en production.** Les scripts SQL ne suffisent pas s'il n'existe aucune trace de ce qui a été appliqué. Une table `schema_migrations` minimale rendrait ces écarts visibles avant qu'ils ne cassent quelque chose, au lieu de les découvrir en testant.

---

## 7. Terraform

`terraform/patisry-infra/Scaleway/` : instance DEV1-M (3 vCPU / 4 Go, `fr-par-1`), PostgreSQL managé (`DB-DEV-S`), Object Storage (`patisry-staging-media`, `patisry-staging-frontend`), Container Registry, groupe de sécurité limité à 22/80/443/ICMP.

Garde-fous : `terraform validate` doit renvoyer *Success* ; `terraform plan` ne doit **jamais** montrer la destruction de l'instance, de l'IP ou de la base. L'ACL de la base managée n'autorise que l'IP de la VM — y ajouter son IP locale pour un accès direct.

Le DNS **n'est pas géré par Terraform** (à faire chez le registrar).

Outil Object Storage : **Scaleway CLI (`scw`)** — pas AWS CLI, pas rclone.
