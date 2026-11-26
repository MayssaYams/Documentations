# Profil client (compte connecté)

| | |
|---|---|
| **Statut** | ✅ rédigé et à jour |
| **Écrit avant le développement ?** | non — fonctionnalité déjà en production, rédigé rétroactivement le 2026-09-22 |
| **Écrans concernés** | `connected_account_screen.dart` (route `/account`), `edit_personal_info_screen.dart` (route `/account/profile/edit`), `profile_screen.dart` (route `/account/profile`) |
| **Endpoints concernés** | `PATCH /api/users/{id}/personal_info/` (user-service) |
| **Tickets Linear liés** | — |
| **Dernière relecture** | 2026-09-22 |

---

## 1. Périmètre

Le hub « Mon compte » (`connected_account_screen.dart`), l'écran profil à onglets (`profile_screen.dart`) et la modification des informations personnelles (`edit_personal_info_screen.dart`). Couvre aussi le bouton « Supprimer mon compte » visible sur `connected_account_screen.dart` (comportement actuel décrit en §4 — **ne pas confondre avec** le vrai parcours RGPD, voir [`suppression-compte-rgpd.md`](suppression-compte-rgpd.md)). La bascule pâtissier → client accessible depuis `profile_screen.dart` (« Supprimer mon compte pâtissier ») est traitée en détail dans [`../patissier/bascule-baker-client.md`](../patissier/bascule-baker-client.md) ; on vérifie ici seulement que le point d'entrée est correct.

## 2. Préconditions

- `client@exemple.com` connecté pour le parcours client pur ; `patissier@exemple.com` (baker 5) pour vérifier l'onglet pâtissier de `profile_screen.dart` et la « danger zone ».
- Toutes les routes de ce fichier sont protégées (`_AuthGate`) — un utilisateur déconnecté est redirigé vers `/login?returnRoute=...`.

## 3. Scénario nominal (happy path)

1. **Ouvrir `/account`.** Liste d'options adaptée au rôle (`_authService.canAccessBakerFeatures`, `_authService.isAdmin`) : un admin voit les mêmes entrées pâtissier qu'un baker (gating de navigation volontaire, pas de propriété d'une ressource précise).
2. **Ouvrir `/account/profile`.** Onglet « Paramètres » toujours présent ; onglets « À propos » et « Évaluation » uniquement si `canAccessBakerFeatures`. Nom, email, badge de rôle (Pâtissier/Client) affichés depuis `AuthService.currentUser`.
3. **Ouvrir `/account/profile/edit`.** Champs prénom (requis), nom (facultatif), email (requis, regex basique), téléphone (facultatif) pré-remplis depuis `AuthService.userInfo`.
4. **Modifier et enregistrer.** `PATCH /api/users/{id}/personal_info/` avec les 4 champs. Succès → `auth.refreshUserInfo()`, retour à l'écran précédent (`goBackOrHome`), snackbar « Profil mis à jour ».
5. **(Pâtissier uniquement) Modifier la bio et la photo depuis l'onglet « À propos ».** `PATCH` sur `baker-service` (`BakerApi().patchBaker`, `updateBakerProfileImage`) — indépendant de `personal_info`, cache pâtissier invalidé après succès (`BakerApi.clearCache()`).

## 4. Cas de bord et erreurs attendues

- **Téléphone vide.** Doit s'enregistrer sans erreur. Vérifié dans le code : `edit_personal_info_screen.dart::_onSave` envoie `phone.isEmpty ? null : phone` (jamais une chaîne vide), et le backend (`user-service/accounts/views.py::personal_info`) applique en plus `_normalize_blank_strings_to_none` sur les champs autorisés — double filet. Cf. [`solution.md`](../../solution.md) §4 : « Profil — enregistrer avec un téléphone vide doit fonctionner (le champ part en `null`, pas en `''`). »
- **Erreur métier sur `PATCH personal_info` (ex. email invalide selon le serializer, contrainte violée).** Doit revenir en **400**, avec le détail formaté (`_formatApiError`) affiché en snackbar — **ne doit jamais** être confondue avec une expiration de session. Voir §6, non-régression majeure de cet écran.
- **401 réel (token/refresh invalides) pendant l'enregistrement.** Snackbar « Session expirée. Merci de vous reconnecter. » **avant** le logout (ordre volontaire, commentaire du code : « Show snackbar before logout to avoid rebuild race on iOS »), puis déconnexion et redirection vers `/login` **sans** `returnRoute` pointant vers l'écran d'édition lui-même (évite une boucle de redirection si le refresh token est aussi expiré).
- **Bouton « Supprimer mon compte » sur `/account`.** La boîte de dialogue de confirmation affiche : « Cette action est irréversible. Toutes vos données seront supprimées définitivement. » **Le code exécuté ne supprime rien** : `AuthService.deleteAccount()` (`lib/core/services/auth_service.dart`) se contente d'appeler `logout()`, avec le commentaire explicite dans le code source : `// In a real app, this would make an API call to delete the account`. **Le compte reste entièrement intact en base après ce bouton** (email, mot de passe, commandes, tout est conservé) — seul l'utilisateur est déconnecté. C'est trompeur pour l'utilisateur final, qui croit son compte supprimé. **À signaler comme point bloquant avant toute publication grand public** tant que ce bouton n'est pas soit désactivé, soit branché sur un vrai parcours de suppression (cf. [`suppression-compte-rgpd.md`](suppression-compte-rgpd.md), PAT-39, en cours). Ne pas cocher la definition of done de ce fichier tant que ce point n'a pas été remonté au PO/Tech Lead.
- **« Devenir pâtissier » sans être connecté.** Snackbar bloquante, pas d'appel réseau (double vérification `user == null || !isLoggedIn` avant l'appel).
- **Bascule pâtissier → client depuis `profile_screen.dart`.** Point d'entrée uniquement ici (`_confirmDowngradeToClient` → `AuthService.downgradeToClient()`) — dérouler le scénario complet dans [`../patissier/bascule-baker-client.md`](../patissier/bascule-baker-client.md).

## 5. Règles métier à vérifier

- Gating de navigation par rôle : un admin voit toujours les mêmes menus qu'un pâtissier (`canAccessBakerFeatures`), jamais de menu manquant pour lui — comportement voulu, pas une fuite de droits (le vrai contrôle est côté serveur).
- Téléphone vide → `null` en base, jamais `''` — voir §4.
- Aucune donnée sensible (mot de passe en clair, token) ne doit apparaître dans les snackbars d'erreur formatées par `_formatApiError`.

## 6. Non-régressions connues

- **[cf. `Documentations/qa/solution.md` §4] « Ne doit jamais déconnecter l'utilisateur : un bug transformait toute erreur métier en 401 et forçait la déconnexion. Un « Session expirée » sur une action banale est le symptôme à traquer. »** Le correctif exact (dans `user-service/accounts/decorators.py::verify_user_access`) et le comportement attendu sont détaillés dans [`connexion-et-mot-de-passe-oublie.md`](connexion-et-mot-de-passe-oublie.md) §6 — à retester ici spécifiquement sur `PATCH /api/users/{id}/personal_info/`, l'endpoint le plus exposé à ce risque sur cet écran.
- **Bouton « Supprimer mon compte » qui ne supprime rien** (voir §4) — pas un bug de régression au sens classique (comportement d'origine, jamais implémenté), mais un écart UI/réalité à traiter avec la même urgence tant qu'il reste en l'état sur un écran accessible à tout utilisateur connecté.

## 7. Comment vérifier

- Backend : `user-service`, `python manage.py test accounts` (couvre `personal_info`, `verify_user_access`). Voir [`role.md`](../../role.md).
- Vérification directe en base après un enregistrement téléphone vide : `SELECT phone_number FROM accounts_user WHERE id = ...` → doit être `NULL`, pas `''`.
- Frontend : `flutter analyze` (0 erreur). Pas de test Flutter dédié identifié pour ces 3 écrans.
- Vérification manuelle staging : confirmer qu'après clic sur « Supprimer mon compte » puis reconnexion avec les mêmes identifiants, la connexion réussit toujours (preuve que rien n'a été supprimé).

## 8. Definition of done

- [ ] Modification du profil (tous champs, y compris téléphone vide) → succès, `null` en base pour un téléphone vide
- [ ] Erreur métier sur l'enregistrement → 400 affiché proprement, **aucune déconnexion**
- [ ] 401 réel → déconnexion propre, message avant logout, pas de boucle de redirection
- [ ] Gating de navigation par rôle correct (admin voit le menu pâtissier, un client simple ne le voit pas)
- [ ] Constat du bouton « Supprimer mon compte » trompeur remonté explicitement au PO/Tech Lead (pas seulement documenté ici)
- [ ] Tests `user-service` verts + `flutter analyze` 0 erreur
