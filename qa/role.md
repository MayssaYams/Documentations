# QA — rôle et repères

Voir d'abord [`Documentations/_conventions.md`](../_conventions.md) pour les règles communes. Orchestré par le **Tech Lead** ([`Documentations/tech-lead/role.md`](../tech-lead/role.md)) : reçoit des tâches déjà découpées, met à jour ce dossier après chaque tâche, pas d'échange en cours de tâche.

## Mission

Tests, non-régression, validation avant release. Règle CLAUDE.md non négociable : les tests d'intégration doivent passer à 100 % sans réduire la couverture existante ; toute nouvelle fonctionnalité doit avoir de nouveaux tests qui la couvrent.

## Comment lancer les tests backend

```bash
ssh -p 31456 -L 5433:127.0.0.1:5432 alvin@91.171.4.184 -N -f   # tunnel DB Freebox
cd Backend/<service> && source venv/bin/activate
JWT_SECRET_KEY='<valeur dev partagée>' DB_HOST=127.0.0.1 DB_PORT=5433 python manage.py test --keepdb
```
**Exception `user-service`** : force SQLite dès que `'test' in sys.argv`, indépendamment de `DB_HOST`/`DB_PORT` — pas besoin du tunnel pour lui.

Certains services ont aussi un `integration_tests.py` autonome (script, pas `manage.py test`) qui tape en HTTP réel sur le service + la DB — voir en tête du fichier pour les variables d'env attendues (`AUTH_SERVICE_URL`, `DISPLAY_SERVICE_URL`, etc., pointent par défaut sur la Freebox).

## Frontend

```bash
cd Patisry && flutter analyze && flutter build web --no-tree-shake-icons
```
Les deux doivent être propres avant de valider une tâche frontend.

## Échecs pré-existants connus — ne pas re-diagnostiquer, juste confirmer qu'ils n'ont pas empiré

- `display-service` : `test_authenticated_no_coords` et `test_authenticated_with_coords_returns_distance` renvoient 500 au lieu de 200. Confirmé pré-existant et indépendant des changements du 2026-07-27 (même échec avec et sans les changements, vérifié via `git stash`). Root cause pas encore investiguée.

## Repères doc existante

- [`Documentations/Doc fonctionnelle/18_TestSprite_Frontend_MVP_Parcours.md`](../Doc%20fonctionnelle/18_TestSprite_Frontend_MVP_Parcours.md) — scénarios E2E frontend déjà définis (TS-MVP-01…10).
- [`Documentations/Service-fonctionnel.md`](../Service-fonctionnel.md) — statut des tests d'intégration par service (à tenir à jour après chaque campagne de tests).
