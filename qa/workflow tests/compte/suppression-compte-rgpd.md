# Suppression de compte (RGPD)

| | |
|---|---|
| **Statut** | 🔁 à revoir — fonctionnalité partielle, PAT-39 en cours |
| **Écrit avant le développement ?** | non — la Phase 1 (page d'information) est déjà en production, ce fichier est rédigé pendant que la Phase 2 (workflow automatisé) est encore *In Progress* |
| **Écrans concernés** | `account_deletion_screen.dart` (route `/suppression-compte`) |
| **Endpoints concernés** | Aucun endpoint de suppression/anonymisation RGPD n'existe à ce jour (voir §1 et §4) — `DELETE /api/users/{id}/` existe mais fait autre chose (voir §4) |
| **Tickets Linear liés** | **PAT-39** — *In Progress*, priorité **Urgent** |
| **Dernière relecture** | 2026-09-22 |

---

## 1. Périmètre

Ce fichier documente l'état **réel et actuel** du parcours de suppression de compte, pas l'état cible de PAT-39. Il doit être mis à jour (statut, endpoints, definition of done) à chaque livraison de la Phase 2, pas seulement relu — voir la note dans le code source de l'écran, citée en §3.

**Ce qui existe aujourd'hui :** une page d'information statique et publique expliquant la procédure, avec un point d'entrée **manuel par email**. **Ce qui n'existe pas encore :** tout parcours in-app (formulaire, vérification d'identité, suppression ou anonymisation effective des données en base). C'est la Phase 1 d'un projet en deux phases explicitement annoncé comme tel dans le code.

## 2. Préconditions

- Environnement cible : staging (`stg.patisry.fr`), mais **cette page doit aussi être vérifiée sans être connecté** — c'est une exigence de conception (voir §5), pas une option de test.
- Aucun compte de test particulier requis pour vérifier l'affichage de la page elle-même.

## 3. Scénario nominal (happy path) — état actuel (Phase 1)

1. **Accéder à `/suppression-compte` sans être connecté.** La route n'est **pas** enveloppée par `_AuthGate` dans `app.dart` — accessible publiquement, comme l'exige le questionnaire Data Safety de Google Play Console qui référence directement `https://patisry.fr/suppression-compte` (commentaire du code source, `account_deletion_screen.dart` lignes 7-14 : « Page publique RGPD décrivant la procédure de suppression de compte (PAT-39)... Doit rester accessible sans être connecté... Phase 1 (celle-ci) : page d'information + point d'entrée par e-mail. Le workflow automatisé (formulaire in-app, vérification, anonymisation/suppression backend) est traité séparément en phase 2. »).
2. **Lire le contenu affiché.** Quatre sections : comment demander la suppression (écrire à `privacy@patisry.fr` depuis l'adresse du compte), ce qui est supprimé ou conservé (compte jamais commandé → suppression totale ; compte ayant commandé → anonymisation des données identifiantes, commandes conservées anonymisées, contenu des messages conservé côté destinataire avec expéditeur anonymisé), délai de traitement (1 mois, prolongeable de 2 mois conformément à l'article 12 du RGPD), lien vers les mentions légales.
3. **Cliquer sur le lien « Mentions légales & confidentialité ».** Navigue vers `/mentions-legales` (`context.go`) — voir [`pages-legales-et-consentement.md`](pages-legales-et-consentement.md).
4. **Envoyer un email à `privacy@patisry.fr`** (hors app, processus manuel) — vérifier que cette adresse est surveillée et qu'une suite est réellement donnée, ce test ne peut être automatisé.

## 4. Cas de bord et erreurs attendues — et ce qui manque encore

- **Aucun formulaire in-app de demande de suppression n'existe.** Toute tentative de trouver un bouton « Supprimer mon compte » qui déclencherait ce parcours RGPD depuis cette page échouera — normal, ce n'est pas encore développé. **Ne pas confondre** avec le bouton « Supprimer mon compte » de `connected_account_screen.dart` (`/account`) : celui-là existe, mais ne fait **qu'une déconnexion** sans rien supprimer ni anonymiser — voir [`profil-client.md`](profil-client.md) §4, c'est un problème séparé et tout aussi urgent (l'utilisateur croit avoir déclenché une suppression, ce qui rend la confusion avec le vrai parcours PAT-39 d'autant plus dangereuse).
- **Aucun endpoint backend de suppression/anonymisation RGPD n'a été trouvé** (recherche `grep -rniE "anonymi[sz]|def delete_account|account_deletion|gdpr|rgpd"` sur tout `Backend/`, hors `.venv`) : les seules occurrences sont des commentaires **anticipant** PAT-39 dans `display-service/display/views.py` et `display/tests.py` (gestion défensive d'un pâtissier déjà anonymisé — code déjà prêt à recevoir la donnée anonymisée, mais rien ne la produit encore).
- **`DELETE /api/users/{id}/` existe dans `user-service`** (`accounts/views.py::UserViewSet.destroy`, protégé par `verify_user_access`, self-service uniquement) **mais ne fait qu'une désactivation** : `user.is_active = False; user.save()`. Aucun champ personnel (nom, email, téléphone, adresse) n'est modifié ou anonymisé, aucune commande ni aucun message n'est touché. **Ce n'est pas l'implémentation de PAT-39** — à ne pas confondre avec elle si on tombe dessus en explorant l'API, et à ne pas présenter comme « le RGPD est fait côté backend » dans un rapport de test.
- **Email non surveillé ou délai de traitement dépassé.** Hors du périmètre technique de ce fichier (processus humain), mais à signaler si observé — c'est actuellement le **seul** canal de traitement réel d'une demande.

## 5. Règles métier à vérifier

- **Accessibilité sans authentification** : condition non négociable pour la conformité Google Play Data Safety — toute évolution future de cette page doit explicitement re-tester qu'elle reste hors de `_AuthGate`.
- **Distinction jamais commandé / déjà commandé** annoncée dans le texte de la page (suppression totale vs anonymisation avec conservation des commandes) — le jour où un vrai parcours backend existe, vérifier qu'il implémente fidèlement cette distinction, pas une suppression uniforme qui casserait les obligations comptables, ni une anonymisation uniforme qui garderait des données inutilement sur les comptes n'ayant jamais commandé.
- **Anonymisation des messages : contenu conservé côté destinataire, identité de l'expéditeur supprimé anonymisée** — règle spécifique à vérifier une fois implémentée, car elle diffère d'une simple suppression en cascade.

## 6. Non-régressions connues

- Aucune à ce jour — fonctionnalité trop récente et partielle pour avoir déjà régressé. À initier dès la première livraison de la Phase 2.

## 7. Comment vérifier

- Aujourd'hui : uniquement `flutter analyze` (0 erreur) + vérification manuelle de l'affichage et de l'accessibilité sans connexion sur staging. Aucun test backend pertinent tant qu'aucun endpoint n'existe.
- **Dès qu'un endpoint de suppression/anonymisation est livré** : ce fichier doit être mis à jour avec les commandes `manage.py test` du service concerné, un scénario de vérification en base (comptes sans commande vs avec commande) et repasser le statut en tête de fichier à `🟡 en écriture` puis `✅ rédigé et à jour` une fois la Phase 2 vérifiée de bout en bout.

## 8. Definition of done

**État Phase 1 (actuel) :**
- [x] Page accessible sans connexion sur staging
- [x] Contenu conforme aux exigences Google Play Data Safety (adresse de contact, délais RGPD)
- [ ] Lien vers `/mentions-legales` vérifié fonctionnel

**État Phase 2 (PAT-39, reste à livrer avant de cocher) :**
- [ ] Un parcours in-app de demande de suppression existe et est accessible depuis un compte connecté
- [ ] Le compte sans commande est réellement supprimé (vérifié en base sur staging)
- [ ] Le compte avec commande(s) est réellement anonymisé, commandes conservées sous forme anonymisée
- [ ] Les messages : contenu conservé, expéditeur anonymisé — vérifié en base
- [ ] Le bouton « Supprimer mon compte » de `connected_account_screen.dart` (`/account`) est corrigé ou retiré — ne doit plus prétendre supprimer des données qu'il ne supprime pas (cf. [`profil-client.md`](profil-client.md))
- [ ] Tests d'intégration du service porteur de PAT-39 écrits et verts
- [ ] **Point bloquant pour la soumission Google Play/App Store tant que ces cases ne sont pas cochées** — cf. [`CLAUDE.md`](../../../../CLAUDE.md) et mémoire projet `patisry-store-build-env-staging-only` référencée dans `Documentations/qa/`.
