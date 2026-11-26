# Connexion et mot de passe oublié

| | |
|---|---|
| **Statut** | ✅ rédigé et à jour |
| **Écrit avant le développement ?** | non — fonctionnalité déjà en production, rédigé rétroactivement le 2026-09-22 |
| **Écrans concernés** | `login_screen.dart` (route `/login`), `forgot_password_screen.dart` (route `/forgot-password`) |
| **Endpoints concernés** | `POST /api/auth/login/`, `POST /api/auth/token/refresh/`, `POST /api/auth/password-reset/request/`, `/verify/`, `/reset/` (auth-service) |
| **Tickets Linear liés** | — |
| **Dernière relecture** | 2026-09-22 |

---

## 1. Périmètre

La connexion par email/mot de passe, le rafraîchissement automatique du token JWT en tâche de fond, et le parcours « mot de passe oublié » en 3 étapes. Ne couvre pas l'inscription ([`inscription.md`](inscription.md)) ni la modification du mot de passe depuis un compte déjà connecté (aucun écran dédié identifié à ce jour — `profile_screen.dart` affiche une entrée « Modifier le mot de passe » qui déclenche `_showComingSoon`, non fonctionnelle).

## 2. Préconditions

- Comptes de test : `patissier@exemple.com` (baker 5), `client@exemple.com`. Jamais la vraie boutique Berile (baker_id=1).
- Environnement cible : staging.
- **`/login/` est throttlé** (voir §5) — prévoir les tentatives de test en conséquence, ne pas enchaîner les essais d'identifiants erronés sans compter.

## 3. Scénario nominal (happy path) — connexion

1. **Saisir email + mot de passe valides, « Se souvenir de moi » coché par défaut.** `POST /api/auth/login/` via `CustomTokenObtainPairView`.
2. **Réponse `200`.** `access` (durée de vie 12h) + `refresh` (7 jours) — cf. [`../../../../CLAUDE.md`](../../../../CLAUDE.md). Tokens persistés par `AuthApi.login()` dans `SecureTokenStorage`.
3. **Redirection** vers `widget.returnRoute` si fourni (ex. venu de `/payment` ou d'une page protégée via le paramètre `returnRoute` de l'URL), sinon `/account`.
4. **Déjà connecté et on va sur `/login` ou `/register`.** Redirigé automatiquement (`_redirect` dans `app.dart`) vers `returnRoute` ou `/account` — impossible d'atterrir sur le formulaire de connexion en étant déjà authentifié.

## Scénario nominal — rafraîchissement automatique du token

5. **Un appel authentifié échoue en 401** (access token expiré, endpoint ni public ni d'authentification). `AuthInterceptor.onError` déclenche un refresh via `/token/refresh/`, avec **un seul refresh concurrent partagé** (`_refreshCompleter`) même si plusieurs requêtes 401 arrivent en même temps.
6. **Refresh réussi.** Nouveau `access` (et `refresh` s'il est roté — `ROTATE_REFRESH_TOKENS` côté serveur, cf. commentaire `_doRefresh` : « CRITIQUE : persister le refresh roté, sinon le prochain refresh utilisera un token périmé ») persistés, la requête initiale est **rejouée automatiquement** avec le nouveau token, l'appelant ne voit jamais l'échec initial.
7. **Refresh échoué** (refresh token absent, expiré ou invalide) → `tokenStorage.clearTokens()`, l'erreur d'origine est propagée — fin de session propre, une seule fois.

## Scénario nominal — mot de passe oublié

8. **Étape 1 : email.** `POST /password-reset/request/` → code à 6 chiffres envoyé par email, **valable 10 minutes** (texte de l'email : « Ce code est valable 10 minutes »). Cooldown client de 30s avant de pouvoir renvoyer.
9. **Étape 2 : code.** `POST /password-reset/verify/` → `reset_token` (UUID de la ligne `PasswordResetCode`) retourné, utilisé à l'étape suivante.
10. **Étape 3 : nouveau mot de passe.** `POST /password-reset/reset/` avec `email`, `new_password`, `reset_token` → `200`, redirection vers `/login`.

## 4. Cas de bord et erreurs attendues

- **Email/mot de passe incorrects.** `400`/`401` → message générique « Email ou mot de passe incorrect. » (le frontend ne distingue jamais email inexistant de mot de passe faux, comportement voulu contre l'énumération de comptes).
- **Compte pas encore vérifié (email non confirmé).** `CustomTokenObtainPairView` intercepte `EmailNotVerifiedError` → `403 {"error_code": "email_not_verified", "email": ...}`. Le frontend détecte précisément ce cas (`statusCode == 403 && responseData['error_code'] == 'email_not_verified'`) et redirige vers `/email-verification?email=...` **avec un nouveau code déjà envoyé côté serveur** (`ensure_verification_code(self.user)` dans `CustomTokenObtainPairSerializer.validate`) — vérifier qu'un code fonctionnel est bien reçu à cette étape, pas seulement la redirection UI.
- **Coupure réseau.** Message dédié « Pas de connexion internet. » (`DioExceptionType.connectionError`/`connectionTimeout`/`receiveTimeout`/`sendTimeout`), pas de message technique brut affiché à l'utilisateur.
- **Erreur serveur 5xx.** Message « Erreur serveur (code). » — vérifier qu'aucune trace technique (stack Django, SQL) ne fuite jusqu'à l'écran.
- **Refresh token expiré pendant l'usage normal de l'app** (après 7 jours, ou après un logout ailleurs si le blacklist est actif). Doit produire une **vraie** fin de session (retour à `/login`), pas une boucle infinie de tentatives — `_refreshAccessTokenShared` ne relève jamais d'exception, toujours `null` en cas d'échec, donc pas de blocage.
- **401 persistant même après un refresh réussi** (token frais toujours rejeté). `AuthInterceptor` ne vide les tokens que dans ce cas précis (`retryErr.response?.statusCode == 401`) — toute autre erreur sur la requête rejouée (réseau, 5xx) ne doit **pas** déconnecter l'utilisateur.
- **Reset de mot de passe : robustesse du nouveau mot de passe.** Écart réel entre les deux parcours : l'inscription impose 8 caractères + majuscule + minuscule + chiffre + caractère spécial (`UserSerializer.validate_password`), alors que **le reset de mot de passe n'exige qu'une longueur minimale de 8 caractères** côté serveur (`ResetPasswordSerializer.new_password = serializers.CharField(min_length=8, ...)`, sans règle de complexité) — le frontend (`forgot_password_screen.dart::_handleResetPassword`) ne vérifie lui aussi que la longueur (`password.length < 8`). **Un mot de passe du type `aaaaaaaa` est aujourd'hui accepté en réinitialisation alors qu'il serait refusé à l'inscription.** À confirmer si c'est voulu ou à corriger — ne pas le documenter comme un bug tant que ce n'est pas tranché, mais le signaler explicitement lors de chaque campagne tant que l'écart existe.
- **Jeton de réinitialisation réutilisé.** `ResetPasswordView` filtre `PasswordResetCode.objects.get(id=reset_token, user=user, is_used=True)` sans jamais invalider ce `reset_token` après usage — un `reset_token` capturé une fois reste valide indéfiniment pour rejouer une réinitialisation. Documenté comme faille HIGH dans `SECURITY_HARDENING_TICKET.md` §1.3 (« Reset token reuse ») — à re-tester après tout correctif de ce ticket, et à traiter comme faille de sécurité potentielle si un correctif est en cours (cf. règle projet : faille critique confirmée → déploiement immédiat sans attendre validation).

## 5. Règles métier à vérifier

- **JWT** : access 12h / refresh 7 jours — cf. [`../../../../CLAUDE.md`](../../../../CLAUDE.md).
- **Rate limiting sur `/login/`.** Vérifié dans le code (`auth-service/core/settings.py`) : `DEFAULT_THROTTLE_RATES['auth_sensitive'] = '5/min'`, appliqué à `CustomTokenObtainPairView` (`throttle_scope = 'auth_sensitive'`) — donc **5 requêtes/minute par IP**, pas 10/min. **Écart avec `Documentations/qa/state.md` (entrée du 2026-08-05)**, qui cite un throttle « 10/min » sur `/login/` en s'appuyant sur `SECURITY_HARDENING_TICKET.md` §4.1 : ce document est une liste de recommandations de durcissement (« Default rates: ... `/login/`: `5/min` per IP + `10/min` per email »), pas une description de l'état déployé — la valeur **par email** proposée (10/min) a visiblement été confondue avec la valeur **par IP** réellement en place (5/min). **Se fier au code ci-dessus, pas à la note de state.md**, et signaler l'écart au Tech Lead pour correction de cette note. Implication pour un test répété : 5 tentatives de connexion (bonnes ou mauvaises) suffisent à déclencher un `429` sur la même IP en moins d'une minute — prévoir des pauses entre les essais d'une campagne de test de connexion, et ne pas confondre un `429` avec un `401`.
- Le throttle `auth_sensitive` s'applique aussi à `/password-reset/request|verify|reset/` — un test enchaînant les 3 étapes du mot de passe oublié plusieurs fois de suite peut se faire bloquer avant la fin.

## 6. Non-régressions connues

- **[cf. `Documentations/qa/solution.md` §4] « Profil — ... Ne doit jamais déconnecter l'utilisateur : un bug transformait toute erreur métier en 401 et forçait la déconnexion. Un « Session expirée » sur une action banale est le symptôme à traquer. »** Cause racine retrouvée et corrigée côté `user-service` (`accounts/decorators.py::verify_user_access`) : avant correctif, la vue métier (`view_func(...)`) était appelée **à l'intérieur** du `try/except` qui décode le token JWT, donc toute exception métier (ex. `IntegrityError`, `Group.DoesNotExist` — voir aussi le commentaire dans `accounts/models.py` sur `group_id`) remontait comme « Token invalide » → 401 → déconnexion forcée côté `AuthInterceptor`, même avec une session parfaitement valide. Le décorateur ne fait désormais un 401 que sur un échec réel de décodage du JWT. **Symptôme à surveiller si ça réapparaît : un « Session expirée » sur une action qui n'a rien à voir avec l'authentification** (ex. modification de profil, patch d'informations) — retester après toute modification de `verify_user_access` ou de décorateurs équivalents sur les autres services.
- **Boucle de refresh infinie.** Le `Completer` de `_refreshAccessTokenShared` est toujours résolu (`catchError` + `whenComplete`), jamais laissé en attente — si un correctif futur touche cette fonction, vérifier explicitement qu'un refresh qui échoue termine bien tous les appels en attente au lieu de les bloquer indéfiniment.

## 7. Comment vérifier

- Backend : `auth-service`, `python manage.py test accounts` (`test_login_success`, `test_login_validation_error`, `test_request_password_reset_success`, `test_request_password_reset_user_not_found`). Voir [`role.md`](../../role.md) pour le tunnel DB.
- Frontend : `flutter analyze` (0 erreur). Pas de test Flutter dédié identifié pour ces deux écrans — à signaler au Tech Lead.
- Vérification manuelle du refresh : `read_network_requests` sur staging pour confirmer qu'un 401 déclenche bien un seul appel `/token/refresh/` (pas un par requête en attente) et que la requête initiale est rejouée avec succès.
- Vérification du throttle : `curl` direct répété sur `/api/auth/login/` (staging) pour confirmer le `429` et son message (`{"code":"too_many_requests", ...}` — format confirmé dans `Documentations/qa/state.md`).

## 8. Definition of done

- [ ] Connexion avec identifiants valides → tokens reçus et persistés, redirection correcte (`returnRoute` ou `/account`)
- [ ] Déjà connecté → jamais d'accès direct à `/login`/`/register`
- [ ] Compte non vérifié → `403 email_not_verified`, redirection vers le code, nouveau code réellement envoyé
- [ ] Refresh automatique transparent sur un 401, un seul appel réseau même avec plusieurs requêtes en attente
- [ ] Refresh échoué → déconnexion propre, pas de boucle
- [ ] Aucun « Session expirée » sur une action métier banale (non-régression du bug décrit en §6)
- [ ] Mot de passe oublié : 3 étapes complètes, code à 6 chiffres valable 10 min, écart de robustesse du nouveau mot de passe (§4) signalé et arbitré
- [ ] Throttle `/login/` confirmé à 5/min par IP (pas 10/min), `state.md` mis à jour en conséquence
- [ ] Tests `auth-service` verts + `flutter analyze` 0 erreur
