# QA — état courant

Voir [`role.md`](role.md). À mettre à jour à la fin de chaque tâche confiée par le Tech Lead — il relit ce fichier avant de relancer ou valider.

## Fait

- 2026-07-27 — Suite complète passée avant la release 1.5.0 sur admin-service (34/34), baker-service (70/70), display-service (35/37, 2 échecs pré-existants confirmés indépendants — voir `role.md`), order-service (34/34), review-service (21/21), user-service (38/38). `flutter analyze` (0 erreur) + `flutter build web` verts sur Patisry.
- 2026-08-04 — Campagne de tests PAT-24 (optimisation images, Phase 1 backend) sur `product-service`, `baker-service`, `display-service`. Tunnel SSH DB Freebox (`ssh -p 31456 -L 5433:127.0.0.1:5432 alvin@91.171.4.184 -N -f`) + `JWT_SECRET_KEY` lu depuis `Backend/auth-service/.env.freebox`. `manage.py test --keepdb` lancé pour chaque service (label explicite `products.unit_tests` nécessaire sur product-service — la découverte par défaut sans label trouve 0 test, le dossier `products/unit_tests/` n'a pas de `__init__.py`).

  **product-service : 68 tests, 56 OK, 9 failures + 3 errors (12 échecs).** `manage.py check` : OK.
  - (b) Liés à PAT-24 (Pillow valide désormais le contenu du fichier uploadé, les mocks de test envoient des octets factices non-image) :
    - `test_create_images_success` (`products/unit_tests/test_views.py:798`) — `AssertionError: 400 != 201`
    - `test_create_images_success` (`products/unit_tests/test_views_more.py:32`) — `AssertionError: 400 != 201`
  - (c) Autres échecs, confirmés préexistants par `git diff products/views.py` (zones non touchées par le diff PAT-24) :
    - `test_get_images_product_not_found` — `AttributeError: 'TestProductViewSet' object has no attribute 'product_model'`
    - `test_get_images_success` — même `AttributeError: ... no attribute 'product_model'`
    - `test_retrieve_image_not_found` — `ModuleNotFoundError: No module named 'FileNotFoundError'` (import bugué dans le test lui-même)
    - `test_create_images_missing_imageurl` — attend le message `'imageurl is required'`, reçoit `'At least one file is required'`
    - `test_create_product_admin_with_any_baker_id_success` — `AssertionError: 400 != 201` (`Baker 5 not found in database`)
    - `test_create_product_baker_with_other_baker_id_fails` — `AssertionError: 400 != 403` (`Baker 999 not found in database`)
    - `test_create_product_baker_with_own_baker_id_success` — `AssertionError: 400 != 201` (`Baker 5 not found in database`)
    - `test_create_product_with_baker_id_success` — `AssertionError: 400 != 201` (`Baker 1 not found in database`)
    - `test_create_product_with_baker_no_userid_fails` — attend `'does not have an associated user'`, reçoit `'Baker with id 1 does not exist'`
    - `test_list_by_baker_valid_id` — `AssertionError: 0 != 2`
    - Note confirmée à part : `test_create_images_success` de `test_views.py` (ligne ~757 mentionnée par le dev, en réalité ligne 798) échouait déjà avant PAT-24 pour une raison indépendante (mock sans `files` en multipart) — mais avec PAT-24 il échoue désormais aussi (et en premier) sur la validation Pillow ; les deux causes se cumulent sur ce test.

  **baker-service : 70 tests, 56 OK, 3 failures + 11 errors (14 échecs) — TOUS liés au changement de contrat `upload_baker_image`.** `manage.py check` : OK.
  - (b) 9x `TypeError: upload_baker_image() takes 1 positional argument but 2 were given` : `test_upload_local_creates_directory`, `test_upload_local_unknown_extension_defaults_to_jpg`, `test_upload_local_writes_file_bytes`, `test_upload_uses_local_when_s3_disabled`, `test_upload_calls_upload_fileobj`, `test_upload_raises_when_boto3_missing`, `test_upload_returns_public_url`, `test_upload_sets_public_read_acl`, `test_upload_wraps_botocore_error`
  - (b) 2x `TypeError: string indices must be integers, not 'str'` (le code du test traite encore le retour comme un `str`, alors que c'est maintenant un `dict`) : `test_upload_image_calls_storage_and_saves_url`, `test_upload_image_deletes_old_image_before_upload`
  - (b) `test_delete_calls_delete_object_with_correct_key` — `AssertionError: Expected 'delete_object' to be called once. Called 2 times` (3 variantes désormais supprimées au lieu d'1)
  - (b) `test_upload_image_rejects_invalid_extension` — `AssertionError: 400 != 200` (contenu factice non-image rejeté par Pillow)
  - (b) `test_upload_image_saves_file_and_returns_updated_baker` — `AssertionError: 400 != 200` (idem)

  **display-service : 35 tests, 33 OK, 2 failures — exactement les 2 échecs connus, pas de nouveau/pas d'aggravation.** `manage.py check` : OK.
  - (a) `test_authenticated_no_coords` — `AssertionError: 500 != 200`
  - (a) `test_authenticated_with_coords_returns_distance` — `AssertionError: 500 != 200`
  - Écart chiffré à signaler sans re-diagnostic : le total observé est 35 tests (33 OK + 2 KO) alors que le rapport du 2026-07-27 mentionnait 37 tests (35 OK + 2 KO). `display/tests.py` n'apparaît pas modifié par PAT-24 (`git status` ne le liste pas parmi les fichiers modifiés dans `display-service`, seul `display/views.py` l'est) — la cause de cet écart de comptage (2 tests) n'a pas été investiguée plus loin, à signaler au Tech Lead.

  **`Documentations/Service-fonctionnel.md` non modifié** : ce fichier suit un format "tests d'intégration" (`integration_tests.py` via HTTP réel) avec des totaux différents (ex. Product 56/56, Baker 43/43, Display 13/13) qui ne correspondent pas au périmètre de cette tâche (`manage.py test`, tests unitaires). L'écraser avec les chiffres unitaires ci-dessus aurait faussé son contenu — à clarifier avec le Tech Lead si une mise à jour y est aussi attendue, et si oui avec quelle source (`integration_tests.py` à relancer séparément).

## En cours

_Rien pour l'instant._

## Bloqué / n'a pas pu être fait correctement

- Root cause des 2 échecs pré-existants sur `display-service` pas encore investiguée (juste confirmé non-régression, exactement les mêmes 2 tests).
- Écart de comptage display-service (35 tests observés le 2026-08-04 vs 37 documentés le 2026-07-27) non investigué — `tests.py` non modifié par PAT-24 d'après `git status`. **Mise à jour 2026-08-05 : ne se reproduit plus, voir ci-dessous (38 tests observés). Cause de l'écart 35→38 non investiguée non plus, mais plus bloquant.**
- `Documentations/Service-fonctionnel.md` pas mis à jour (voir ci-dessus, incompatibilité de périmètre avec les résultats de cette tâche).
- **`product-service/integration_tests.py` non exécutable en bout en bout (2026-08-05)** : voir détail ci-dessous — throttling `/api/auth/login/` sur auth-service Freebox (`10/min` par IP, cf. `SECURITY_HARDENING_TICKET.md` §4.1) bloque l'obtention d'un token.

## Questions ouvertes pour le Tech Lead

- Faut-il prioriser l'investigation des 2 tests `display-service` en échec, ou rester en veille tant qu'ils ne bloquent pas de release ?
- Les 10 échecs `product-service` restants (classés (c), préexistants, cf. campagne du 2026-08-04) sont-ils à corriger avant release, ou une release partielle est-elle acceptable ?
- `Documentations/Service-fonctionnel.md` : qui le tient à jour et avec quelle source de vérité (intégration HTTP vs unitaires `manage.py test`) ?
- `integration_tests.py` de `product-service` retente le login ~6x par email candidat sur plusieurs emails candidats (jusqu'à 5) dès le premier échec — avec un throttle auth-service à `10/min` par IP, ce script grille son propre quota en une seule exécution. Faut-il l'ajuster (moins de tentatives, backoff) pour qu'il reste utilisable sur un auth-service durci, ou fournir un `--token` pré-obtenu à chaque lancement ?

## Fait (suite)

- 2026-08-05 — Suite de vérification post-PAT-24 (suite continuation) sur `product-service` et `display-service`, ciblée par le Tech Lead sur les chiffres exacts 63/73 et 36/38.

  **Tunnel DB** : `ssh -p 31456 -L 5433:127.0.0.1:5432 alvin@91.171.4.184 -N -f` ouvert avec succès. `JWT_SECRET_KEY` lu depuis `.env.freebox` de chaque service.

  **product-service : `python manage.py test products.unit_tests --keepdb` → 73 tests, 63 OK, 7 failures + 3 errors = exactement 10 échecs.** Les noms correspondent exactement à la liste (c) déjà documentée le 2026-08-04 (préexistants, indépendants des images) :
  `test_get_images_product_not_found` (error), `test_get_images_success` (error), `test_retrieve_image_not_found` (error, import bugué), `test_create_images_missing_imageurl`, `test_create_product_admin_with_any_baker_id_success`, `test_create_product_baker_with_other_baker_id_fails`, `test_create_product_baker_with_own_baker_id_success`, `test_create_product_with_baker_id_success`, `test_create_product_with_baker_no_userid_fails`, `test_list_by_baker_valid_id`.
  Les 2 échecs (b) liés à Pillow (`test_create_images_success` x2) du 2026-08-04 **ne réapparaissent plus** — corrigés depuis. Cible **63/73 confirmée exactement**, aucun échec supplémentaire ni différent. `manage.py check` : `System check identified no issues (0 silenced)`.

  **display-service : `python manage.py test --keepdb` → 38 tests, 36 OK, 2 failures.** Exactement les 2 échecs déjà documentés, aucun nouveau :
  `test_authenticated_no_coords` (`AssertionError: 500 != 200`), `test_authenticated_with_coords_returns_distance` (`AssertionError: 500 != 200`), tous deux dans `display.tests.HomePayloadTests`. Cible **36/38 confirmée exactement**. `manage.py check` : `System check identified no issues (0 silenced)`.
  Note : l'écart de comptage 35 (2026-08-04) vs 37 (2026-07-27) mentionné plus haut ne se reproduit pas — 38 tests observés aujourd'hui. Cause non investiguée (hors périmètre de cette tâche), mais le total actuel (38) et les 2 échecs correspondent exactement à la cible donnée par le Tech Lead.

  **`product-service/integration_tests.py` — tenté, bloqué sur un prérequis non trivial.** Lancé avec les valeurs par défaut du script (`AUTH_SERVICE_URL`/`PRODUCT_SERVICE_URL`/`BAKER_SERVICE_URL` → Freebox, `DB_PORT=5433` via tunnel, `POSTGRES_DB=mytestpatisry`/`POSTGRES_USER=local`/`POSTGRES_PASSWORD=admin` conformes à `.env.freebox`). Connexion DB OK, les 3 services répondent (200), l'enregistrement d'un nouvel utilisateur via `/api/auth/register/` réussit. **Le login (`/api/auth/login/`) échoue systématiquement avec "No response from server"** (résultat de `requests` ne renvoyant rien d'exploitable côté script) sur l'utilisateur fraîchement créé, puis sur ~5 emails candidats de secours. Diagnostic : `curl` direct sur `/api/auth/login/` renvoie `429 {"code":"too_many_requests","message":"Request was throttled. Expected available in N seconds."}` — confirmé par `SECURITY_HARDENING_TICKET.md` §4.1, qui documente un throttle `10/min` par IP sur `/login/`, manifestement déjà en place sur auth-service Freebox. La logique interne du script (jusqu'à 6 tentatives de login par email candidat, sur jusqu'à 5 emails) épuise ce quota dès sa propre première phase, avant même d'atteindre la partie qui vérifie le format `imageurl`. Résultat du script : `Total tests: 8, PASSED: 6, FAILED: 2` (échec = "Login failed" + "Could not obtain authentication token"), aucun test d'image exécuté. **Pas retenté après coup** pour ne pas prolonger le lockout partagé sur l'IP Freebox (le tunnel/les services sont partagés). Nécessiterait soit un `--token` pré-obtenu hors du script, soit un ajustement du script pour respecter le throttle (moins de tentatives / backoff) — décision Tech Lead, voir question ouverte ci-dessus.

## Dernière mise à jour

2026-08-05 — vérification ciblée product-service (63/73) + display-service (36/38) après suite PAT-24, tentative `integration_tests.py` documentée (bloquée par throttle login auth-service).
