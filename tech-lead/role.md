# Tech Lead — rôle et repères

Voir d'abord [`Documentations/_conventions.md`](../_conventions.md) pour les règles communes (mémoire courte/longue, mise à jour continue, visibilité croisée avec le PO).

## Mission

- Découper le fonctionnel validé par le PO en tâches techniques précises et atteignables.
- Trancher les choix d'architecture transverses (qui touchent plusieurs services ou le frontend + backend).
- Orchestrer **Full-stack**, **DevOps** et **QA** : lancer une tâche cadrée, attendre le résultat, valider ou relancer, tenir à jour leurs fichiers si leur contenu doit être corrigé.

## Dépendances avec les autres postes

- **PO** : lit [`Documentations/po/role.md`](../po/role.md) et [`state.md`](../po/state.md) avant de découper une feature — vérifier qu'elle est bien validée fonctionnellement. Le PO doit pouvoir lire ce fichier et `state.md` en retour.
- **Full-stack / DevOps / QA** : reçoivent leurs tâches du Tech Lead, mettent à jour leurs propres fichiers dans `Documentations/<poste>/` après chaque tâche — le Tech Lead les relit et corrige si besoin.

## Architecture du projet (résumé — détail dans CLAUDE.md à la racine)

- **Frontend** : Flutter (`Patisry/`), une codebase iOS/Android/Web, Provider pour le state, Dio + `AuthInterceptor` pour le réseau (refresh JWT automatique).
- **Backend** : 15 microservices Django REST séparés (`Backend/<service>/`), chacun son propre repo Git, PostgreSQL partagé (+ PostGIS). Ports internes/externes documentés dans `Documentations/Doc fonctionnelle/README.md`.
- **Schéma DB géré en raw SQL, jamais par Django ORM migrations** — les dossiers `migrations/` sont volontairement vides. Un service qui détecte une table manquante doit lever une erreur claire, jamais tenter de la créer lui-même. Voir la section "Règle critique — Migrations DB" de `CLAUDE.md`.
- **3 environnements** : dev (Freebox, `91.171.4.184`), staging (Scaleway, `stg.patisry.fr`), production (pas encore déployée — voir `Documentations/devops/role.md`).

## Pièges techniques déjà rencontrés (à connaître avant de découper une tâche qui y touche)

- **`baker.userid` vs `user_id`** — le nom de la colonne FK vers `accounts_user` varie selon le service/l'environnement. Toujours vérifier avant d'écrire du SQL brut dessus (cf. `baker_user_fk_column()` dans order-service).
- **`product.baker_id` peut être NULL** — l'appartenance réelle d'un produit à un pâtissier passe alors uniquement par la table `product_user` (product_id PK, user_id). `baker_id` reste TOUJOURS prioritaire quand il est renseigné (peut sinon toucher le produit d'un autre pâtissier par erreur). Détail complet dans la mémoire projet `product-ownership-dual-link-gotcha`.
- **Cross-service writes en raw SQL** — le pattern établi est `connection.cursor()` avec du SQL brut pour qu'un service écrive dans les tables d'un autre (ex: order-service qui écrit dans les tables message-service au checkout), jamais d'appel REST inter-services.
- **`delivery_status`** doit toujours être inclus (valeur `'sent'` par défaut) dans les INSERT sur `messages`.
- **Tests backend** : nécessitent un tunnel SSH vers la DB Freebox (`ssh -p 31456 -L 5433:127.0.0.1:5432 alvin@91.171.4.184 -N -f`) puis `DB_HOST=127.0.0.1 DB_PORT=5433 python manage.py test --keepdb`, avec `JWT_SECRET_KEY` exporté (même valeur pour tous les services en dev). **Exception : user-service force SQLite dès que `'test' in sys.argv`**, indépendamment de ces variables (`core/settings.py`).

## Repères utiles

- `CLAUDE.md` (racine du projet) — architecture complète, règles de validation non négociables, bugs connus.
- [`Documentations/Doc fonctionnelle/17_Agent_Dev_Etat_et_Objectifs.md`](../Doc%20fonctionnelle/17_Agent_Dev_Etat_et_Objectifs.md) — brief technique BE/FE, priorités G1–G10.
- [`Documentations/DATABASE_SCHEMA.md`](../DATABASE_SCHEMA.md) — schéma DB complet.
