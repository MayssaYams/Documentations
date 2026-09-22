# Fiche pâtissier publique

| | |
|---|---|
| **Statut** | 🔁 à revoir — écran connecté au mauvais endpoint backend, voir constat §1 |
| **Écrit avant le développement ?** | non — écrit en constatant l'état réel du code le 2026-09-22 |
| **Écrans concernés** | `baker_profile_screen.dart` (route `/bakers/:id`) |
| **Endpoints concernés** | `GET /api/bakers/{id}/` (baker-service, **utilisé par l'app**, authentifié) — endpoint correct qui existe mais **n'est pas appelé** par l'app : `GET /api/bakers/{id}/public/` (baker-service, `AllowAny`, `PublicFullBakerSerializer`) |
| **Tickets Linear liés** | PAT-57 (garde-fou champs publics), PAT-74 (ville publique) |
| **Dernière relecture** | 2026-09-22 |

---

## 1. Périmètre — constat de lecture de code à vérifier en priorité

Ce document couvre l'écran « Votre pâtissier » (`/bakers/:id`) : identité, description, spécialités, localisation, informations vérifiées, produits du pâtissier. Ne couvre pas la saisie d'adresse côté pâtissier lui-même (→ [`../patissier/adresse-et-position.md`](../patissier/adresse-et-position.md)).

**Constat important, à revérifier avant toute campagne** (le code peut avoir changé) : `baker_api.dart::getBakerFromBakerID` appelle `GET /api/bakers/{id}/` — c'est-à-dire l'action `retrieve` de `BakerViewSet`, dont `permission_classes = [IsAuthenticated]` **globalement**, et qui sert `BakerSerializer` (le serializer « complet », pas le serializer public). Il existe pourtant, côté baker-service, un endpoint conçu spécifiquement pour cet usage : `GET /api/bakers/{id}/public/` (action `public_profile`, `permission_classes=[AllowAny]`, serializer `PublicFullBakerSerializer`, qui expose `pickup_city` via `ville_publique()` et jamais `location`/lat/lon). **L'app Flutter n'appelle cet endpoint public nulle part** (`grep -rn "bakers/.*public" lib/` ne retourne rien côté client au moment de la rédaction). Deux conséquences directes, décrites en détail au §4 :

1. Un visiteur **non connecté** ne peut pas ouvrir la fiche pâtissier (401).
2. Un visiteur **connecté non-propriétaire** ne voit ni ville ni distance sur cette fiche (le champ `location` est explicitement vidé côté serveur, sans être remplacé par une ville) — alors que le modèle produit (CLAUDE.md) exige que la ville et la distance soient publiquement visibles.

## 2. Préconditions

- `client@exemple.com` connecté, ET un test en navigation anonyme (déconnecté) — les deux donnent un résultat différent, voir §4.
- `patissier@exemple.com` (baker 5) avec un profil complet (description, spécialités, point de collecte renseigné via [`../patissier/adresse-et-position.md`](../patissier/adresse-et-position.md)).
- Staging (`stg.patisry.fr`).

## 3. Scénario nominal (happy path) — tel qu'observé aujourd'hui, connecté non-propriétaire

1. **Ouvrir `/bakers/:id` depuis un lien produit ou la fiche produit, connecté avec un compte autre que le propriétaire.** `GET /api/bakers/{id}/` répond `200` (utilisateur authentifié). Affiche nom commercial, note (si `ratingVisible`), ancienneté, description, spécialités, informations vérifiées (identité/e-mail/téléphone — coche booléenne, jamais la valeur elle-même), produits du pâtissier.
2. **Section localisation.** `_buildLocationSection()` ne s'affiche **que si** `_bakerData.location` est non nul et non vide. Pour un non-propriétaire, ce champ est explicitement mis à `null` côté serveur (voir §4/§5) — la section n'apparaît donc **jamais** pour un visiteur classique dans l'état actuel du code. Ce n'est pas une fuite (bonne nouvelle, voir §5), mais ce n'est pas non plus la ville/distance publique attendue par le produit (mauvaise nouvelle, voir §4).
3. **Clic sur un produit du pâtissier.** Navigue vers `/products/:id` via `ValueKey`, mêmes garanties que documentées dans [`fiche-produit.md`](fiche-produit.md).

## 4. Cas de bord et erreurs attendues

- **Visiteur non connecté ouvrant `/bakers/:id`.** `GET /api/bakers/{id}/` exige `IsAuthenticated` (aucune dérogation sur `retrieve` dans `baker_app/views.py::BakerViewSet`) → `401`. `BakerProfileScreen._loadBakerData()` avale l'exception (`try { ... } catch (_) { _bakerData = null; }`) et affiche simplement **« Pâtissier introuvable »** — message trompeur : le pâtissier existe, c'est l'accès qui est refusé. **À vérifier en priorité, sans compte connecté** : c'est incohérent avec le reste du catalogue (accueil et fiche produit sont consultables sans compte, `display-service` étant `AllowAny` — voir [`accueil.md`](accueil.md) §5 et [`fiche-produit.md`](fiche-produit.md) §5). Un client qui découvre un pâtissier via un lien partagé sans être connecté ne peut pas voir sa fiche.
- **Visiteur connecté non-propriétaire — pas de ville ni de distance affichée.** Le hotfix sécurité du 2026-09-16 (`BakerSerializer.to_representation`, `baker_app/serializers.py`) met `data['location'] = None` pour tout non-propriétaire (`_demandeur_est_proprietaire` renvoie `False`), en plus de retirer `bank_details` et de masquer `email`/`phone_number` par `'•••'`. Résultat : la section localisation ne s'affiche jamais pour un tiers, mais la ville publique (`pickup_city`, calculée par `ville_publique()` à partir de `baker_location`) n'est **pas** renvoyée par cet endpoint — elle n'existe que sur `PublicBakerSerializer`/`PublicFullBakerSerializer`, non utilisés ici. **Écart fonctionnel avec le modèle produit** : CLAUDE.md exige que « la vitrine n'affiche que la ville et la distance » ; sur cette fiche, elle n'affiche ni l'une ni l'autre.
- **Propriétaire consultant sa propre fiche publique** (cas rare mais possible, ex. en cliquant sur son propre lien). `_demandeur_est_proprietaire` renvoie `True` → reçoit la réponse complète (`location`, `bank_details`, `email`/`phone_number` en clair). Comportement voulu (« c'est son propre profil »), à ne pas confondre avec une fuite.
- **`bakerId` invalide ou pâtissier supprimé.** `_bakerData == null` après échec → « Pâtissier introuvable », bouton retour disponible.

## 5. Règles métier à vérifier

- **L'adresse exacte n'est jamais publique** (règle CLAUDE.md non négociable). Sur l'endpoint actuellement utilisé (`GET /bakers/{id}/`), c'est **respecté aujourd'hui** grâce au hotfix sécurité du 2026-09-16 dans `BakerSerializer.to_representation` (`baker_app/serializers.py:112-144`) : un non-propriétaire reçoit `location: None`, jamais le texte libre de l'adresse. **Ce respect dépend entièrement de ce hotfix** et de la bonne classification par `_demandeur_est_proprietaire` — si cette fonction est un jour modifiée (ex. mal gérer un `request` absent du contexte du serializer), le champ redeviendrait visible. À valider explicitement à chaque modification de `baker_app/serializers.py` : vérifier en réseau (`read_network_requests`) qu'un appel `GET /bakers/{id}/` authentifié en tant que non-propriétaire ne contient jamais de `location` non nulle, ni `bank_details`, ni un `email`/`phone_number` en clair (seule la valeur masquée `'•••'` est acceptable si le champ était renseigné).
- **Seules ville et distance doivent être publiques.** Le fichier `baker_app/public_fields.py` liste explicitement les champs interdits en public (`location`, `latitude`, `longitude`, `address`, `address_label`, `email`, `phone_number`, etc. — `city` en est volontairement absent, « seule granularité géographique publiquement autorisée »), et `baker_app/tests_public_privacy.py` échoue si l'un de ces noms réapparaît dans un serializer public. **Cette liste, et le test qui la fait respecter, ne protègent que les serializers explicitement publics (`PublicBakerSerializer`, `PublicFullBakerSerializer`) — pas `BakerSerializer`.** L'écran actuel n'utilise ni l'un ni l'autre des serializers publics (voir §1) : il est donc hors du filet de sécurité automatisé de `tests_public_privacy.py`, protégé uniquement par le hotfix manuel de `to_representation`. À signaler comme risque structurel, pas seulement comme un bug ponctuel.
- **`GET /api/bakers/{id}/public/` (déjà écrit, non utilisé) est le candidat naturel pour corriger l'écart du §4** — il expose `pickup_city` (ville) sans jamais exposer l'adresse, et fonctionne en anonyme. Le rapprocher de l'écran réglerait à la fois le 401 pour les visiteurs non connectés et l'absence de ville/distance publique. Décision de le brancher : hors périmètre de ce document (décision Tech Lead/PO), mais à signaler.

## 6. Non-régressions connues

- **PAT-57 (2026-09-09, hotfix confirmé sur staging)** : `GET /api/bakers/{id}/public/` renvoyait autrefois `email`, `phone_number` et `location` sans authentification — l'email réel d'un pâtissier sortait en clair. Corrigé sur le serializer public. **Sans objet direct sur l'écran actuel** puisqu'il n'appelle pas cet endpoint, mais tout branchement futur de `/bakers/:id` sur `/public/` devra revalider ce point précis avant mise en prod.
- **Hotfix sécurité du 2026-09-16** (`BakerSerializer`) : avant correctif, `GET /api/bakers/` et `GET /api/bakers/{id}/` renvoyaient à **tout compte authentifié** les coordonnées bancaires, l'email, le téléphone et l'adresse de **tous** les pâtissiers — pas seulement celles du demandeur. Corrigé par `to_representation` + verrouillage en lecture seule de `user`/`is_verified`/`commission_rate`. **Non-régression à revalider à chaque modification de ce serializer** : reproduire l'appel avec un compte non-propriétaire et vérifier l'absence de `bank_details`, `location` nul, `email`/`phone_number` masqués.

## 7. Comment vérifier

- Backend : `baker-service` — `manage.py test`, en particulier `baker_app/tests_public_privacy.py` (garde-fou champs publics) et tout test couvrant `BakerSerializer.to_representation`.
- `read_network_requests` sur `GET /api/bakers/{id}/` avec un compte non-propriétaire connecté : confirmer `location: null`, absence de `bank_details`, `email`/`phone_number` = `'•••'` si renseignés.
- Vérification manuelle staging **en navigation anonyme (déconnecté)** : ouvrir `/bakers/:id`, confirmer si le 401/« Pâtissier introuvable » du §4 est toujours reproductible — c'est le point le plus prioritaire de ce document.
- `flutter analyze` 0 erreur.

## 8. Definition of done

- [ ] Confirmé si l'accès anonyme à `/bakers/:id` fonctionne ou renvoie toujours « Pâtissier introuvable » (401 masqué) — décision Tech Lead à obtenir si non corrigé
- [ ] Aucune adresse complète, coordonnée bancaire, email/téléphone en clair visible par un non-propriétaire (vérifié réseau)
- [ ] Ville et/ou distance publique affichée, ou écart formellement documenté comme dette si non corrigé
- [ ] Propriétaire voit bien sa propre fiche complète sans régression
- [ ] Tests `baker-service` verts, en particulier `tests_public_privacy.py`
- [ ] `flutter analyze` 0 erreur
