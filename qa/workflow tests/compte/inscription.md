# Inscription et vérification email

| | |
|---|---|
| **Statut** | ✅ rédigé et à jour |
| **Écrit avant le développement ?** | non — fonctionnalité déjà en production, rédigé rétroactivement le 2026-09-22 |
| **Écrans concernés** | `register_screen.dart` (route `/register`), `email_verification_screen.dart` (route `/email-verification`) |
| **Endpoints concernés** | `POST /api/auth/register/`, `POST /api/auth/email-verification/send/`, `POST /api/auth/email-verification/verify/` (auth-service) |
| **Tickets Linear liés** | PAT-65 (verrou `group_id`) |
| **Dernière relecture** | 2026-09-22 |

---

## 1. Périmètre

La création d'un compte client depuis `register_screen.dart`, jusqu'à l'activation du compte par le code de vérification email. Ne couvre pas la connexion elle-même ([`connexion-et-mot-de-passe-oublie.md`](connexion-et-mot-de-passe-oublie.md)) ni la création d'un profil pâtissier (pas d'écran d'inscription pâtissier dédié — devenir pâtissier passe par « Devenir pâtissier » sur `connected_account_screen.dart`, hors périmètre de ce fichier).

## 2. Préconditions

- Un email de test jetable, **jamais** `client@exemple.com`/`patissier@exemple.com` (ces comptes doivent rester utilisables pour toutes les autres campagnes).
- Environnement cible : staging (`stg.patisry.fr`).
- **Le endpoint est throttlé** (`throttle_scope = 'auth_sensitive'`, `5/min` par IP — voir §5). Espacer les tentatives d'inscription/de renvoi de code pendant une campagne de test pour ne pas se bloquer soi-même.

## 3. Scénario nominal (happy path)

1. **Remplir le formulaire.** Email, confirmation email, mot de passe, confirmation mot de passe, case CGU cochée. Le bouton reste actif même sans cocher « Je m'inscris en tant que pâtissier » (voir §4 — ce champ n'a aucun effet).
2. **Valider.** `POST /api/auth/register/` avec `email`, `password`, `first_name` (dérivé automatiquement de la partie avant `@` de l'email — **le formulaire ne demande ni prénom ni nom**, cf. `_handleRegister()`), `last_name` (chaîne vide). Réponse `201` : `{"message": "Utilisateur créé avec succès."}`.
3. **Redirection automatique** vers `/email-verification?email=<email>` (email dans l'URL, pas seulement en `extra`, pour survivre à un rafraîchissement navigateur).
4. **Code reçu par email.** 6 chiffres, valable **24h** (`EmailVerificationCode.is_valid()`). Sur staging avec SMTP configuré, vérifier la réception réelle ; en environnement sans SMTP l'envoi bascule sur le backend console sans bloquer l'inscription (`RegisterView.create` : un échec d'envoi est loggé mais ne fait jamais échouer le `201`).
5. **Saisir le code.** `POST /api/auth/email-verification/verify/` → `200`, snackbar de succès, puis redirection vers `/` (l'inscription **n'authentifie pas** l'utilisateur — pas de token émis à cette étape, c'est un comportement voulu, retester le login séparément après).
6. **Renvoyer un code si besoin.** Bouton « Renvoyer le code », cooldown client de 30s (`Timer.periodic`), invalide les anciens codes non utilisés côté serveur (`EmailVerificationCode.objects.filter(user=user, is_used=False).update(is_used=True)`) avant d'en créer un nouveau.

## 4. Cas de bord et erreurs attendues

- **Email déjà utilisé.** `UserSerializer.create()` lève `ValidationError({"email": "Cet email est déjà utilisé."})` → 400. Le frontend affiche `Email: Cet email est déjà utilisé.` (`_handleRegister`, branche `data.containsKey('email')`).
- **Mot de passe trop faible.** Backend (`validate_password`) exige : 8 caractères min, 1 majuscule, 1 minuscule, 1 chiffre, 1 caractère spécial (`!@#$%^&*()_+-=[]{}|;:,.<>?`). Le formulaire vérifie exactement les 4 mêmes règles côté client (checklist visuelle sous le champ) — vérifier qu'un mot de passe qui passe la checklist client passe bien aussi côté serveur, et inversement qu'aucun des deux n'est plus permissif que l'autre.
- **Emails ne correspondant pas** (email / confirmation email) → erreur client uniquement, pas d'appel réseau.
- **Case CGU non cochée** → bouton bloqué côté client (`_isCGUError`), aucun appel réseau. **Le backend ne vérifie pas l'acceptation des CGU** — l'API accepte une inscription sans aucune notion de CGU dans son payload ; c'est uniquement une contrainte d'UI.
- **Case « Je m'inscris en tant que pâtissier » cochée.** **Ne fait rien.** `_isPatissier` n'est ni envoyé dans le payload de `_authApi.register(...)`, ni lu ailleurs dans l'écran — dead code côté UI. Même en la cochant, le compte créé est un compte `client` standard (`group_id = 2`, PAT-65 : le `group_id` ne vient jamais du client, une inscription publique crée toujours un `User`). **Ne pas prendre cette case pour un point d'entrée pâtissier lors des tests** — c'est trompeur mais pas un bug de sécurité (aucun moyen de devenir pâtissier par ce biais).
- **`group_id` envoyé manuellement dans le payload** (ex. via un appel API direct pour tester la sécurité). Ignoré silencieusement par le serializer — pas d'erreur renvoyée, `PAT-65` retire `group_id` de `validated_data` avant `create_user(**validated_data)`. Vérifier explicitement qu'un `"group_id": 1` ne crée jamais un administrateur.
- **Code de vérification invalide.** `400 {"error": "Code invalide."}`.
- **Code de vérification expiré (>24h).** `400 {"error": "Code expiré."}`.
- **Email déjà vérifié, renvoi ou vérification retentés.** `200 {"message": "Email déjà vérifié."}` — pas d'erreur, idempotent.
- **Connexion avant vérification email.** Hors périmètre de ce fichier mais lié : voir [`connexion-et-mot-de-passe-oublie.md`](connexion-et-mot-de-passe-oublie.md) §4 (le login renvoie `403 email_not_verified` et redirige vers cet écran).
- **Throttle atteint pendant une campagne de test** (5 requêtes/min sur `register/`, `email-verification/send/` et `email-verification/verify/` partagent la même IP côté staging). Le backend doit répondre `429` proprement, jamais planter — voir §5.

## 5. Règles métier à vérifier

- **Politique d'âge 18+** (mémoire projet `patisry-age-policy-18-plus` : navigation libre, mais compte/commande doivent être réservés aux 18+ sans autorisation parentale, modèle Uber Eats). **Aucune vérification d'âge n'existe dans ce parcours** : ni sur `register_screen.dart` (pas de champ date de naissance dans le formulaire, alors que `AuthApi.register()` accepte un paramètre optionnel `dateOfBirth` jamais renseigné par cet écran), ni dans `UserSerializer` côté auth-service (`date_of_birth` est un champ optionnel, `required: False`, sans aucune contrainte de majorité). **Un compte peut aujourd'hui être créé sans jamais déclarer son âge.** Ce n'est pas un comportement à valider comme correct — c'est un écart à signaler tel quel : à vérifier auprès du PO/Juriste si une case de déclaration d'âge est prévue avant la prochaine mise à jour de ce document, ne pas supposer qu'un contrôle existe ailleurs dans le flux tant qu'il n'a pas été trouvé.
- PAT-65 : `group_id` ne vient jamais du client, quel que soit ce qui est envoyé dans le payload — voir §4.
- Mot de passe : les règles de robustesse sont dupliquées client + serveur, doivent rester strictement identiques (voir §4) — toute évolution d'une des deux sans l'autre est une régression silencieuse.

## 6. Non-régressions connues

- **Regex email trop stricte.** `register_screen.dart` et `login_screen.dart` utilisent la même regex `^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$`, commentée « alignée sur la contrainte DB `chk_email_format` — TLD de longueur libre (le `{2,4}` précédent rejetait à tort des domaines valides comme `.local`) ». Si un domaine de test valide est rejeté côté client, vérifier que cette regex n'a pas régressé vers l'ancienne borne `{2,4}`.
- **Inscription qui ne bloque jamais sur un échec d'envoi d'email.** Voulu (`RegisterView.create`, `try/except` autour de l'envoi) — un `500` sur `/register/` à cause d'un SMTP en panne serait une régression de ce choix explicite, pas un comportement acceptable.

## 7. Comment vérifier

- Backend : `auth-service`, `python manage.py test accounts` (voir `accounts/tests.py::test_register_success`, `RegisterEmailVerificationTests::test_register_creates_code_and_sends_email`, `test_register_smtp_failure_still_succeeds`) — voir [`role.md`](../../role.md) pour le tunnel DB. `manage.py check` avant de conclure.
- Frontend : `flutter analyze` (0 erreur) — pas de test Flutter dédié identifié pour cet écran à ce jour, à signaler au Tech Lead si une couverture est attendue.
- Vérification manuelle sur staging : `SELECT email_verified FROM accounts_user WHERE email = '...'` avant/après la saisie du code, `SELECT * FROM email_verification_codes WHERE user_id = ... ORDER BY created_at DESC` pour confirmer l'invalidation des anciens codes au renvoi.

## 8. Definition of done

- [ ] Inscription avec email neuf + mot de passe valide → `201`, redirection vers `/email-verification`
- [ ] Email déjà utilisé → erreur claire, pas de compte créé en double
- [ ] Mot de passe hors règles → refusé identiquement côté client et côté serveur
- [ ] Case « pâtissier » cochée ou non : le compte créé est toujours `group_id = 2` (client)
- [ ] `group_id` forcé dans le payload → toujours ignoré, jamais de compte admin/baker créé par ce biais
- [ ] Code à 6 chiffres : validation, expiration à 24h, renvoi avec invalidation des anciens codes — tous vérifiés
- [ ] Politique d'âge 18+ : état réel du contrôle confirmé (absent à ce jour, cf. §5) et remonté au PO si non arbitré
- [ ] Tests `auth-service` verts + `flutter analyze` 0 erreur
