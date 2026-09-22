# Adresse et point de collecte du pâtissier

| | |
|---|---|
| **Statut** | ✅ rédigé et à jour |
| **Écrit avant le développement ?** | non — fonctionnalité déjà en production, rédigé rétroactivement le 2026-09-22 |
| **Écrans concernés** | `baker_address_screen.dart` (`/account/baker/address`) |
| **Endpoints concernés** | `PUT /bakers/{id}/location/` (baker-service), API Adresse (BAN, `api-adresse.data.gouv.fr`) |
| **Tickets Linear liés** | PAT-44, PAT-45, PAT-74, PAT-75, PAT-76 (tous livrés sur staging) |
| **Dernière relecture** | 2026-09-22 |

---

## 1. Périmètre

Saisie et modification de l'adresse principale et du point de collecte alternatif d'un pâtissier, géocodage via la BAN, désambiguïsation d'adresse. Ne couvre pas l'affichage public (ville + distance uniquement) → [`../catalogue/fiche-patissier-publique.md`](../catalogue/fiche-patissier-publique.md).

## 2. Préconditions

- `patissier@exemple.com` (baker 5) connecté. **Jamais** utiliser la vraie boutique Berile (baker_id=1) pour ces tests.
- Adresse de test qui produit une ambiguïté BAN connue (voir §4) si on veut retester PAT-76 spécifiquement.

## 3. Scénario nominal (happy path)

1. **Saisir une adresse principale non ambiguë.** Autocomplétion BAN, sélection d'un candidat, sauvegarde → `201`/`200` selon création ou mise à jour.
2. **Ajouter un point de collecte alternatif.** Adresse distincte de l'adresse principale, sauvegardée séparément.
3. **Adresse de retrait effective calculée côté serveur.** = point de collecte alternatif s'il est renseigné, sinon adresse principale — matérialisée une seule fois en base (`baker_location`), utilisée à la fois pour la distance publique et le message client.
4. **Modifier une adresse déjà confirmée sans changer le texte.** Le `address_ban_id` précédemment confirmé est réutilisé — pas de nouvelle désambiguïsation.
5. **Modifier le texte après une confirmation.** La confirmation précédente est perdue, un nouveau géocodage est déclenché sur le nouveau texte (comportement voulu — ne pas réutiliser un `ban_id` qui ne correspond plus au texte affiché).

## 4. Cas de bord et erreurs attendues

- **Adresse ambiguë (réponse 409 `ambiguous_address`).** L'écran doit présenter les candidats (chacun avec son `id` BAN dans la réponse) et laisser choisir. **Ne jamais** boucler indéfiniment sur la resoumission du même texte — c'était le bug PAT-76 : les scores BAN ne sont pas parfaitement stables d'un appel à l'autre, et certaines adresses ont deux entrées BAN quasi identiques (écart de score sous le seuil d'ambiguïté), rendant la désambiguïsation par texte structurellement impossible. **Confirmer un candidat doit envoyer son `address_ban_id`**, pas resoumettre le texte — vérifier dans les requêtes réseau (`read_network_requests`) que le second appel contient bien `address_ban_id`, pas seulement `address_label`.
- **Création d'un point de collecte (`baker_location`) pour la première fois.** Ne doit **jamais** produire un 500 — c'était le bug PAT-75 : `BakerLocation.objects.create()` incluait la colonne PostgreSQL `GENERATED ALWAYS` (`effective_pickup_city`) dans l'INSERT, ce que Postgres refuse. Ce bug n'était **pas** reproductible en test SQLite (le test runner ne simule pas la sémantique des colonnes générées) — toute régression sur ce point ne sera visible qu'en testant contre le vrai Postgres de staging, jamais suffisant de faire confiance à `manage.py test` seul ici.
- **Adresse introuvable / hors de France.** Message d'erreur clair, pas de crash, pas d'enregistrement partiel.
- **BAN injoignable au moment de la sauvegarde.** Message clair, l'utilisateur ne perd pas sa saisie.

## 5. Règles métier à vérifier

- L'adresse exacte n'est **jamais publique** — vérifier qu'aucun endpoint public (fiche pâtissier, recherche, home) ne renvoie l'adresse complète, seulement ville + distance.
- Adresse de retrait effective = règle déterministe unique, matérialisée une seule fois (pas recalculée différemment entre la distance publique et le message client — les deux doivent lire la même valeur en base).
- Géocodage exclusivement via l'API Adresse (BAN) — jamais Google Places.

## 6. Non-régressions connues

- **PAT-75 (2026-09-16)** : `PUT /bakers/{id}/location/` en 500 à la création à cause de la colonne générée `effective_pickup_city`. Corrigé par un INSERT SQL brut listant explicitement les colonnes inscriptibles. **Toujours vérifier contre le vrai Postgres**, pas seulement SQLite.
- **PAT-76 (2026-09-16)** : désambiguïsation d'adresse (409) pouvant boucler indéfiniment à cause de l'instabilité des scores BAN. Corrigé par résolution déterministe via `ban_id` (`geocode_confirmed`). Retester avec une adresse réellement ambiguë, pas une adresse qui ne l'est plus après correctif d'une entrée BAN entretemps (les données BAN peuvent changer).
- **PAT-74** : la ville publique doit venir de `baker_location`, pas d'un fallback texte sur `baker.location` — à vérifier si `baker_location` n'existe pas encore pour un pâtissier fraîchement créé.

## 7. Comment vérifier

- Backend : `baker-service` (`manage.py test` + vérification manuelle **contre Postgres réel sur staging**, en particulier pour PAT-75 — ne pas se fier à un test SQLite vert).
- `read_network_requests` pour confirmer la présence de `address_ban_id` dans l'appel de confirmation d'un candidat ambigu.
- Frontend : `flutter analyze` + `flutter test` (voir `baker_address_screen_confirmation_test.dart` pour le pattern de test existant — `AddressAutocompleteField` construit son propre `BanGeocodingApi()` non injectable, utiliser `tester.pump()` borné plutôt que `pumpAndSettle()`).

## 8. Definition of done

- [ ] Adresse non ambiguë sauvegardée sans erreur
- [ ] Adresse ambiguë : confirmation d'un candidat envoie `address_ban_id`, jamais de boucle
- [ ] Création d'un point de collecte pour la première fois : pas de 500 (vérifié contre Postgres réel)
- [ ] Adresse de retrait effective identique entre distance publique et message client, vérifiée en base
- [ ] Aucune adresse complète exposée sur un endpoint public
- [ ] Tests `baker-service` verts + `flutter analyze`/`flutter test` verts
