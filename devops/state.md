# DevOps — état courant

Voir [`role.md`](role.md). À mettre à jour à la fin de chaque tâche confiée par le Tech Lead — il relit ce fichier avant de relancer ou valider.

## Fait

- 2026-07-27 — Release 1.5.0 déployée sur staging pour 7 repos (admin-service, baker-service, display-service, order-service, review-service, user-service, Patisry). CI vérifiée verte sur chaque paire, code déployé confirmé par grep dans les conteneurs + vérification visuelle sur `stg.patisry.fr`. Tag `1.5.0` posé sur `staging` pour les 7 repos.
- 2026-07-27 — Bundle Android `patisry-PROD.V1.5.0.aab` généré pointant vers `patisry.fr` à la demande explicite du CTO, **mais ce bundle est non-fonctionnel** : `patisry.fr` est un domaine parké Hostinger, aucune requête API n'aboutira. À ne pas distribuer tel quel.

- 2026-07-27 — **Resynchronisation du schéma DB staging.** Staging avait plusieurs migrations de retard (schéma appliqué à la main, staging oublié), ce qui cassait le checkout. Écarts trouvés par audit complet Freebox ↔ staging et corrigés :
  - `orders.checkout_reference` (colonne + index) manquante
  - `chk_order_status_valid` périmée (refusait `pending_confirmation`)
  - `chk_message_type_valid` périmée (refusait `order_request`/`order_reply` → cassait le checkout avec instructions spéciales) — via `15_fix_message_type_constraint.sql`
  - `review_reports`, `platform_settings`, `product_reviews.baker_reply`/`baker_reply_at`, contraintes d'unicité + `order_id NOT NULL` — via `add_review_ownership_and_reports.sql`
  - `newsletter_subscriptions` — via `add_newsletter_subscriptions_table.sql`
  - `billing_history` — **aucun script ne la créait**, dérive non documentée côté Freebox ; script `add_billing_history_table.sql` créé à cette occasion dans `Documentations/database/`
  - Toutes les tables concernées étaient vides au moment de l'opération (risque nul). Audit final : plus aucune colonne, contrainte ou index manquant. Seules restent absentes les 4 tables internes Django (`auth_permission`, `django_admin_log`, `django_content_type`, `django_session`) — sans impact, les services n'utilisent pas l'admin Django.

## En cours

_Rien pour l'instant._

## Bloqué / n'a pas pu être fait correctement

- La vraie production (Azure/AWS, cf. `CLAUDE.md`) n'existe pas encore — impossible de builder un bundle prod réellement fonctionnel tant que l'infra n'est pas déployée et qu'un vrai domaine ne pointe pas dessus.
- **Risque structurel** : le schéma DB est appliqué manuellement, environnement par environnement, sans registre de ce qui a été joué où. La dérive staging du 2026-07-27 en est la conséquence directe et se reproduira. Un mécanisme de suivi des migrations (même minimal : une table `schema_migrations` listant les scripts appliqués) éviterait de re-découvrir ces écarts un par un en production.

### 2026-08-04 — PAT-24 : déploiement fait, mais incident JWT_SECRET_KEY en cours de route (résolu)

- SQL `Documentations/database/add_image_variants.sql` appliqué avec succès sur **les deux bases Postgres natives de la Freebox** (Postgres tourne en systemd, pas en conteneur — `sudo -u postgres psql -d <db>`, pas de conteneur `patisry-db`) : `mytestpatisry` (base applicative) et `test_mytestpatisry` (base de test, cf. mémoire projet du 2026-07-23). Les 3 colonnes (`product_image.thumbnail_url`/`medium_url`, `baker.profile_thumbnail_url`) confirmées présentes sur les deux.
- `product-service`, `baker-service`, `display-service` déployés via `./deploy_freebox.sh` (build ARM64 local, `Pillow==10.2.0` build sans problème avec un wheel `manylinux_..._aarch64` — l'inquiétude de Full-stack sur la version Pillow était un faux problème lié à son venv local Python 3.14, sans rapport avec le Dockerfile `python:3.11-slim` réellement utilisé).
- **Incident découvert juste après déploiement** : les 3 services sont partis en crash-loop (`KeyError: 'JWT_SECRET_KEY'` au chargement de `settings.py`). Cause : les fichiers `.env.freebox` versionnés dans les 3 dépôts ne contiennent **pas** la ligne `JWT_SECRET_KEY=` (trou pré-existant, sans lien avec le code de PAT-24) ; `deploy_freebox.sh` écrase sans avertissement le `.env`/`.env.freebox` qui tournait correctement sur la Freebox avec cette version incomplète du repo local. `auth-service` est le seul des 15 services dont le `.env.freebox` local contient déjà la ligne.
- Corrigé (avec accord explicite du CTO avant d'agir, le fix touchant un secret partagé) : ligne `JWT_SECRET_KEY=<même valeur que SECRET_KEY, déjà identique à celle d'auth-service>` ajoutée dans les `.env.freebox` de `product-service`, `baker-service`, `display-service` (repo local ET sur la Freebox), puis conteneurs recréés.
- **Piège rencontré au passage** : `docker-compose up -d --force-recreate` casse avec `KeyError: 'ContainerConfig'` sur cette combinaison Docker Engine / docker-compose v1.29.2 de la Freebox — laisse le conteneur renommé et arrêté, aucun nouveau conteneur créé. Le fix fiable est `docker-compose down` puis `docker-compose up -d` (jamais `--force-recreate` sur cette Freebox).
- État final vérifié : les 3 conteneurs stables (`Up`, pas de restart), `JWT_SECRET_KEY` confirmé présent dans l'environnement runtime, code neuf confirmé présent (`image_processing.py`, occurrences `thumbnail_url` dans `display/views.py`). Les 12 autres services n'ont pas été touchés, tous stables.

## Questions ouvertes pour le Tech Lead

- Faut-il prioriser la mise en place de l'infra production (choix Azure vs AWS toujours TBD dans CLAUDE.md) ?
- **Nouveau** : les `.env.freebox` versionnés dans les dépôts sont la source de vérité utilisée par `deploy_freebox.sh`, mais peuvent diverger silencieusement de ce qui tourne réellement sur la Freebox (exactement ce qui vient de casser 3 services). Faut-il un audit systématique des `.env.freebox` de tous les services (comparaison avec l'env runtime réel) pour trouver d'autres trous similaires avant qu'ils ne cassent un déploiement futur ?
- **Nouveau** : bannir `docker-compose up -d --force-recreate` sur la Freebox (bug `ContainerConfig`) — à documenter quelque part de plus visible que ce fichier si d'autres agents DevOps risquent de le retenter (`role.md` ?).

## Dernière mise à jour

2026-08-04 — PAT-24 : SQL appliqué (2 bases), 3 services déployés, incident JWT_SECRET_KEY découvert et résolu (voir détail ci-dessus). Agent DevOps automatique initialement lancé pour cette tâche s'est bloqué (timeout 600s, probablement sur le mauvais nom de conteneur DB supposé) — reprise et finalisation en direct par le Tech Lead.
