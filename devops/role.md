# DevOps — rôle et repères

Voir d'abord [`Documentations/_conventions.md`](../_conventions.md) pour les règles communes. Orchestré par le **Tech Lead** ([`Documentations/tech-lead/role.md`](../tech-lead/role.md)) : reçoit des tâches déjà découpées, met à jour ce dossier après chaque tâche, pas d'échange en cours de tâche.

## Mission

Infra, CI/CD, déploiement, Terraform, monitoring.

## Environnements

| Env | Hébergement | Domaine réel | Statut |
|---|---|---|---|
| dev | Freebox (`91.171.4.184`) | — | déploiement manuel via `deploy_freebox.sh` par service |
| staging | Scaleway DEV1-M (`51.15.236.77`) | `stg.patisry.fr` | CI/CD automatique au push sur `staging` |
| production | pas encore déployée | — | `patisry.fr` **pointait sur un parking Hostinger le 2026-07-27, mais plus depuis au moins le 2026-08-05** : son DNS résout maintenant vers la VM staging (`51.15.236.77`), nginx y sert le même build Flutter que `stg.patisry.fr`. Personne n'a documenté ce changement — cause et intention à clarifier avec le CTO. En attendant, le traiter comme un alias non-officiel de staging (mêmes limites), pas comme une vraie prod. |

## Déploiement dev (Freebox) — manuel

```bash
cd Backend/<service> && ./deploy_freebox.sh
```
Build l'image Docker en local, l'exporte, la transfère par SSH, la charge et redémarre le service sur la Freebox. Lancer en tâche de fond (peut prendre plusieurs minutes), suivre via les logs affichés en fin de script.

## Déploiement staging — automatique via CI, ne jamais déployer à la main

Chaque service backend a son repo Git séparé (`github.com/MayssaYams/<Service-Name>`) avec un workflow `.github/workflows/deploy-staging.yml` déclenché sur push vers la branche `staging` :
1. Build l'image Docker, la push sur `rg.fr-par.scw.cloud/patisry-staging/<service>` (tags `:latest` et `:<sha>`).
2. SSH vers la VM staging (`deploy@51.15.236.77`), `docker compose -f docker-compose.staging.yml pull && up -d --no-deps <service>`.

Le repo `Patisry` (Flutter web) a son propre `deploy-staging.yml` : build web en mode release avec `--dart-define=ENVIRONMENT=staging --dart-define=API_BASE_URL=https://stg.patisry.fr`, puis SCP vers `/opt/patisry/web` sur la VM + reload nginx (`docker exec patisry-nginx nginx -s reload`).

**La VM staging ne supporte pas trop de déploiements simultanés** (ressources limitées) — pousser sur `staging` service par service, 2 repos à la fois maximum, en attendant que le run CI du pair précédent soit terminé (`gh run watch <run-id> --exit-status`) avant d'en lancer un autre.

## Accès SSH

- Freebox : `ssh -p 31456 alvin@91.171.4.184`
- VM staging : `ssh -i ~/.ssh/patisry-staging-deploy ubuntu@51.15.236.77` (ou `deploy@` — les deux fonctionnent), conteneurs sous `/opt/patisry`, `docker compose -f docker-compose.staging.yml ...`. **`.env` de tous les services staging = un seul fichier partagé `/opt/patisry/.env`** (pas un `.env` par service comme sur Freebox).
- **Piège SSH staging** : l'agent 1Password (clé "Scaleway") échoue systématiquement en session non-interactive (`sign_and_send_pubkey: signing failed for ED25519 "Scaleway" from agent: communication with agent failed`), mais SSH retombe ensuite sur la clé fichier explicite (`-i ~/.ssh/patisry-staging-deploy`) et réussit — **prévoir un timeout ~90s** pour laisser ce fallback se faire, ne pas conclure à un blocage après un timeout court.

## Conteneurs staging (noms réels)

`sudo docker ps` sur la VM staging → `patisry-<service>` (ex: `patisry-baker`, `patisry-product`, `patisry-db`), pas `<service>_<service>_1` comme sur Freebox. Utiliser `sudo docker exec patisry-<service> ...` pour exécuter du code avec les credentials déjà chargés en environnement (évite d'extraire des secrets vers une autre machine).
- DB staging (via VM) : `psql -h 127.0.0.1 -U local -d mytestpatisry` une fois SSH sur la VM (identifiants dans `.env` du service côté VM, ne pas les recopier en clair dans la doc — ce dossier est destiné à devenir un repo Git).

## Postgres sur la Freebox : natif, pas conteneurisé

Contrairement à la VM staging, **Postgres tourne en systemd directement sur l'hôte Freebox**, pas dans un conteneur `patisry-db` (ce nom n'existe que côté staging/prod). Accès : `sudo -u postgres psql -d <db>` en SSH sur la Freebox (`sudo -n` fonctionne sans mot de passe pour l'utilisateur `alvin`). Deux bases pertinentes : `mytestpatisry` (applicative) et `test_mytestpatisry` (dédiée aux tests `manage.py test`, cf. `full-stack/role.md`) — **toute évolution de schéma doit être appliquée sur les deux**, sinon les tests cassent sur des colonnes manquantes indépendamment du code.

## Piège `docker-compose --force-recreate` sur la Freebox

`docker-compose up -d --force-recreate` casse avec `KeyError: 'ContainerConfig'` sur la combinaison Docker Engine / docker-compose v1.29.2 installée sur la Freebox — le conteneur existant est renommé et arrêté, aucun nouveau conteneur n'est créé (service down jusqu'à intervention manuelle). Rencontré et confirmé le 2026-08-04 sur `product-service`/`baker-service`/`display-service`. **Ne jamais utiliser `--force-recreate` sur la Freebox** : toujours `docker-compose down` puis `docker-compose up -d` (2 commandes séparées) pour appliquer un changement d'environnement sans rebuild.

## Piège `.env.freebox` versionné vs réalité déployée

`deploy_freebox.sh` écrase sans avertissement le `.env`/`.env.freebox` qui tourne sur la Freebox avec la version présente dans le repo local au moment du déploiement — si cette version locale a un trou (variable manquante), le déploiement casse silencieusement un service qui fonctionnait. Rencontré le 2026-08-04 : `JWT_SECRET_KEY` absent des `.env.freebox` de `product-service`/`baker-service`/`display-service` (seul `auth-service` l'avait), 3 services en crash-loop après déploiement. **Avant tout déploiement Freebox, vérifier que le `.env.freebox` local contient bien toutes les variables que `settings.py` exige sans valeur par défaut** (`os.environ['X']`, pas `os.getenv('X', default)`) plutôt que de supposer qu'il est à jour.

## Process de release (établi le 2026-07-27)

1. Commit tous les changements réels sur `develop` (repo par repo, exclure `.env.freebox` — bruit de re-chiffrement à chaque déploiement — et les `__pycache__`/`media/` non trackés).
2. Bump de version (`Patisry/pubspec.yaml`), build/tests verts sur tous les repos concernés.
3. Push `develop` sur tous les repos concernés.
4. Fast-forward `staging` depuis `develop`, push 2 repos à la fois, attendre la fin du CI de chaque paire avant la suivante.
5. Vérifier le déploiement réel (grep du code déployé dans les conteneurs, ou vérification visuelle sur `stg.patisry.fr`) avant de taguer.
6. Tag `<version>` sur `staging` pour chaque repo concerné, push le tag.

## Terraform

`terraform/patisry-infra/Scaleway/` — instance DEV1-M, DB managée PostgreSQL-15, Object Storage (media + frontend web), Container Registry. `terraform validate` doit renvoyer "Success", `terraform plan` ne doit jamais montrer la destruction de l'instance, l'IP ou la DB.

## Repères doc existante

- `Documentations/DEPLOYMENT_FREEBOX.md`, `Documentations/SSH_TUNNEL_README.md`.
