# Pages légales et consentement analytics

| | |
|---|---|
| **Statut** | ✅ rédigé et à jour |
| **Écrit avant le développement ?** | non — fonctionnalité déjà en production, rédigé rétroactivement le 2026-09-22 |
| **Écrans concernés** | `legal_notice_screen.dart` (route `/mentions-legales`), `analytics_consent_dialog.dart` (popup, pas une route) |
| **Endpoints concernés** | Aucun — contenu statique + préférence stockée localement (`ConsentService`) |
| **Tickets Linear liés** | PAT-40 (mentions légales) |
| **Dernière relecture** | 2026-09-22 |

---

## 1. Périmètre

La page de mentions légales / politique de confidentialité, et la popup de consentement à la mesure d'audience (Google Analytics) qui s'appuie dessus. Ne couvre pas la suppression de compte, traitée séparément dans [`suppression-compte-rgpd.md`](suppression-compte-rgpd.md) bien qu'un lien y renvoie depuis cette page.

## 2. Préconditions

- Aucun compte requis pour `/mentions-legales` — page publique.
- Pour tester la popup de consentement : un état « jamais répondu » (`ConsentService.hasAnswered()` doit renvoyer `false`) — sur mobile/web réinstaller l'app ou vider le stockage local si le consentement a déjà été donné lors d'une session précédente.

## 3. Scénario nominal (happy path)

1. **Ouvrir `/mentions-legales` sans être connecté.** Route non protégée (`_AuthGate` absent dans `app.dart`) — accessible publiquement, comme `/suppression-compte`.
2. **Lire le contenu.** Mentions légales + politique de confidentialité (PAT-40), dernière mise à jour affichée en dur (« 16 septembre 2026 »). Le code documente explicitement un point non tranché : Patisry est déployée **en nom propre** (Alvin Nzembani, personne physique) en attendant la création de la société ; l'adresse postale du responsable de traitement est **volontairement absente** de la page ; le texte devra être révisé une fois la structure juridique (société + SIRET) en place, notamment à l'intégration de Stripe.
3. **Premier lancement de l'app (ou consentement jamais donné).** `AnalyticsConsentDialog.showIfNeeded()` affiche la popup, non-dismissible par le fond (`barrierDismissible: false`).
4. **Accepter ou refuser.** Les deux boutons ont **le même style visuel** (choix voulu, commenté dans le code : « refuser doit être aussi simple qu'accepter — exigence RGPD/CNIL, pas de dark pattern »). `_respond()` appelle `ConsentService.setConsent(granted)` puis `AnalyticsService.applyConsent(granted)`, puis **ferme explicitement la popup** (`Navigator.of(context).pop()`).
5. **Revenir sur son choix depuis le profil.** `profile_screen.dart` → section Préférences → « Mesure d'audience » (libellé « Activée »/« Désactivée » selon `ConsentService.isGranted()`) → réouvre la même popup (`_openAnalyticsConsent`), aussi simple à changer qu'à donner initialement.

## 4. Cas de bord et erreurs attendues

- **Lien « Politique de confidentialité » dans la popup de consentement.** Point signalé comme un doute à vérifier — **vérifié dans le code, pas supposé** :
  - Les deux boutons « Accepter »/« Refuser » ferment explicitement la popup avant de rendre la main (`_respond` appelle `Navigator.of(context).pop()`).
  - Le lien « Politique de confidentialité » (`_policyTapRecognizer`, `TapGestureRecognizer().onTap = () => context.go('/mentions-legales')`) **n'appelle jamais `Navigator.pop()`** — il se contente de `context.go('/mentions-legales')`. C'est une différence de code vérifiable et non contestable entre ce lien et les deux boutons de réponse.
  - La popup est ouverte via `showDialog(barrierDismissible: false, ...)`, ce qui la pousse comme une route sur le `Navigator` local à l'écran appelant, **par-dessus** la pile gérée par `go_router`. Un `context.go()` déclenché depuis l'intérieur de cette route ne referme pas nécessairement cette route elle-même — dont le pop n'est jamais demandé explicitement sur ce chemin.
  - **Ce qui n'est pas vérifiable par la seule lecture du code** : si `go_router` reconstruit sa pile de Navigator au point de démonter automatiquement la route de dialogue au passage sur `/mentions-legales`, ou si la popup reste effectivement visible/bloquante par-dessus la page légale nouvellement affichée en dessous. **À vérifier manuellement sur staging (mobile et web)** : cliquer le lien depuis la popup de premier lancement et constater si la page des mentions légales devient réellement consultable, ou si l'utilisateur reste bloqué derrière une popup non-dismissible qui ne se ferme pas. Ne pas cocher la definition of done de ce point tant que ce test manuel n'a pas été fait — c'est actuellement une incertitude de code confirmée, pas un bug confirmé ni un non-problème confirmé.
- **Refus du consentement.** Doit désactiver la mesure d'audience de façon vérifiable (`AnalyticsService.applyConsent(false)`) — s'assurer qu'aucun événement Analytics n'est envoyé après un refus (cf. `read_network_requests` en filtrant les appels vers les domaines Google Analytics/Firebase).
- **Popup qui réapparaît alors qu'une réponse a déjà été donnée.** Ne doit pas se reproduire — `hasAnswered()` doit refléter fidèlement un choix déjà fait, y compris après redémarrage de l'app.

## 5. Règles métier à vérifier

- Consentement analytics : CNIL — refuser doit être aussi accessible qu'accepter (voir §3, styles identiques).
- Modification du consentement accessible à tout moment depuis le profil, pas seulement au premier lancement.
- Mentions légales : statut juridique (nom propre) et absence d'adresse du responsable de traitement sont des points **provisoires et connus**, pas des oublis à signaler comme bug — mais à re-vérifier à chaque changement de statut juridique de la société (à suivre avec la Juriste, cf. `Documentations/juriste/`).

## 6. Non-régressions connues

- Aucune connue à ce jour sur ces deux écrans. Le point du lien non-dismissible (§4) n'est pas encore confirmé comme un bug — dès qu'il l'est (ou est écarté) par un test manuel, cette section doit être mise à jour avec la conclusion et, si confirmé, la date.

## 7. Comment vérifier

- Frontend uniquement : `flutter analyze` (0 erreur) — pas de logique backend sur ces deux écrans.
- Test manuel obligatoire sur staging pour le point §4 (lien depuis la popup non-dismissible) : mobile **et** web, les deux plateformes pouvant se comporter différemment sur la gestion de la pile de Navigator par `go_router`.
- `read_network_requests` pour confirmer l'absence d'appels Analytics après un refus de consentement.

## 8. Definition of done

- [ ] `/mentions-legales` accessible sans connexion, contenu à jour
- [ ] Popup de consentement affichée uniquement tant qu'aucune réponse n'a été donnée
- [ ] Accepter/Refuser : mêmes styles, ferme la popup, applique bien le consentement (vérifié réseau)
- [ ] Modification du consentement depuis le profil fonctionne dans les deux sens
- [ ] **Comportement du lien « Politique de confidentialité » dans la popup vérifié manuellement (mobile + web)** — page légale réellement consultable ou non, conclusion actée dans ce fichier
- [ ] `flutter analyze` 0 erreur
