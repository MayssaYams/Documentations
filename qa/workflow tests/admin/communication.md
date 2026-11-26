# Communication (newsletter et notifications push)

| | |
|---|---|
| **Statut** | ✅ rédigé et à jour |
| **Écrit avant le développement ?** | non — fonctionnalité déjà en production, rédigé rétroactivement le 2026-09-22 |
| **Écrans concernés** | `admin_newsletter_screen.dart` (`/admin/newsletter`), `admin_push_screen.dart` (`/admin/push`) |
| **Endpoints concernés** | admin-service : `GET /api/admin/newsletter/`, `PUT /api/admin/newsletter/{id}/unsubscribe/` ; notification-service : `POST /api/admin/push/send/` |
| **Tickets Linear liés** | — |
| **Dernière relecture** | 2026-09-22 |

---

## 1. Périmètre

Les deux seuls canaux de communication sortante gérés depuis le panel admin. **Point à ne pas supposer avant d'avoir lu le code** : les deux écrans ne se comportent pas symétriquement — l'un envoie réellement un message, l'autre non (voir ci-dessous).

## 2. Préconditions

- Le compte admin de test.
- **Notifications push : au moins un appareil de test avec un token FCM actif enregistré**, idéalement sur une plateforme que rien d'autre n'utilise en parallèle sur staging (ex. un appareil de test dédié), car l'envoi cible **tous** les appareils actifs de la plateforme choisie — jamais un sous-ensemble (voir §5).
- Newsletter : au moins un abonné de test en base (`newsletter_subscriptions`).

## 3. Scénario nominal (happy path) — newsletter

1. **Ouvrir `/admin/newsletter`.** Liste des abonnés (`GET /newsletter/`), avec le nombre d'abonnés actifs affiché en en-tête.
2. **Désinscrire un abonné.** `PUT /newsletter/{id}/unsubscribe/` → `is_active = FALSE`, sans confirmation supplémentaire côté UI, action irréversible depuis cet écran (pas de « réinscrire »).
3. **Il n'existe pas d'action d'envoi de campagne depuis cet écran.** Confirmé par le commentaire explicite du backend (`NewsletterAdminViewSet`, `Backend/admin-service/admin_app/views.py`) : « Gestion des abonnés newsletter : liste + désabonnement manuel (**pas de compositeur/envoi de campagne — hors périmètre**) ». **Ne pas chercher un bouton « Envoyer » sur cet écran ni un endpoint de composition** : à ce jour, `/admin/newsletter` est uniquement un outil de gestion de la liste d'abonnés, pas un outil d'envoi. Si un besoin d'envoi de newsletter existe côté produit, c'est une fonctionnalité à construire, pas un bug de cet écran.

## Scénario nominal — notifications push

4. **Ouvrir `/admin/push`.** Choix d'une plateforme cible parmi quatre puces : Android, iOS, Web, **Toutes**.
5. **Saisir titre et message, cliquer « Envoyer la notification ».** Un dialogue de confirmation s'affiche d'abord (« Envoyer cette notification push à tous les appareils actifs sur "{plateforme}" ? Cette action est immédiate et irréversible. »), à valider explicitement.
6. **Envoi.** `POST /api/admin/push/send/` avec `{platform, title, body}` → diffusion réelle vers **tous les appareils actifs** de la plateforme choisie (`UserDeviceTokens` filtrés par plateforme et `is_active = TRUE`, `Backend/notification-service/notification_app/views.py`).
7. **Résultat affiché.** `{total, sent, failed}` — nombre d'appareils ciblés, envois réussis, échecs. `total = 0` affiche explicitement « Aucun appareil actif sur cette plateforme. » plutôt qu'un résultat vide ambigu.

## 4. Cas de bord et erreurs attendues

- **Titre ou message vide.** Refusé côté client avant tout appel réseau (« Le titre et le message sont obligatoires. »).
- **Échec réseau à l'envoi.** Message générique (« Échec de l'envoi. Réessaie plus tard. ») — **ne permet pas de savoir si l'envoi a partiellement eu lieu** avant l'échec réseau (ex. certains appareils notifiés, la coupure survenant après). À vérifier explicitement en cas de doute : consulter les logs notification-service plutôt que de supposer un statut à partir du seul message UI.
- **Aucun appareil actif sur la plateforme choisie.** Ne doit jamais être traité comme une erreur — `total = 0` est un résultat valide, pas un échec.
- **Désinscrire un abonné déjà désinscrit.** Le bouton « Désinscrire » n'apparaît que pour les abonnés `isActive` côté UI — vérifier qu'un appel direct à l'endpoint sur un abonné déjà inactif ne casse rien (idempotence de l'`UPDATE`).

## 5. Règles métier à vérifier

- Point d'entrée admin unique — `IsAdminRole` côté admin-service pour la newsletter, `IsAdminRole` importé également côté notification-service pour le push (même logique `group_id == 1`, service différent) — voir [`dashboard-et-analytics.md`](dashboard-et-analytics.md) §5.
- **Ciblage push : aucun segment ni ciblage par utilisateur, seulement par plateforme technique (Android/iOS/Web/Toutes).** Il n'existe **aucun mécanisme d'envoi de test restreint à un seul appareil ou à un compte précis** — le choix « Toutes » diffuse littéralement à tous les appareils actifs, toutes plateformes confondues, dès la confirmation validée. **Conséquence directe pour la QA en environnement de test** : ne jamais choisir « Toutes » (ni même une plateforme précise) sur staging sans avoir vérifié au préalable quels appareils réels y sont enregistrés — un test mal préparé peut notifier de vrais utilisateurs si des comptes non-test ont un token actif sur staging. Le seul filet est le dialogue de confirmation, qui prévient de l'irréversibilité mais ne réduit jamais la portée de l'envoi.
- La newsletter n'a pas de canal d'envoi actif à ce jour (voir §3) — ne pas confondre « fonctionnalité pas encore testée » avec « fonctionnalité manquante » dans un futur rapport de campagne : c'est un choix de périmètre documenté dans le code, pas un trou de couverture QA.

## 6. Non-régressions connues

_Aucune connue à ce jour — première rédaction de cette fiche. Ajouter ici tout bug réel rencontré lors d'une future campagne._

## 7. Comment vérifier

- Backend : notification-service (`manage.py test`, classe `AdminPushViewSetTests` — `Backend/notification-service/notification_app/tests.py` — couvre déjà l'envoi par plateforme et les permissions) ; admin-service (`manage.py test`, classe `NewsletterAdminEndpointsTests` — `Backend/admin-service/admin_app/tests/test_endpoints.py`).
- Vérification directe : `SELECT is_active FROM newsletter_subscriptions WHERE id = ...` après désinscription ; pour le push, confirmer le nombre réel d'appareils actifs par plateforme (`SELECT platform, COUNT(*) FROM user_device_tokens WHERE is_active = TRUE GROUP BY platform`) **avant** tout envoi de test, pour dimensionner l'impact réel.
- Frontend : `flutter analyze` + test manuel staging, en réservant l'envoi push réel à un appareil de test dédié et clairement identifié au préalable.

## 8. Definition of done

- [ ] Désinscription d'un abonné newsletter fonctionnelle, `is_active` cohérent en base
- [ ] Absence de canal d'envoi de campagne newsletter confirmée et non traitée comme un bug
- [ ] Envoi push fonctionnel sur au moins une plateforme, avec confirmation préalable obligatoire
- [ ] Résultat `{total, sent, failed}` cohérent avec le nombre réel de tokens actifs vérifié en base
- [ ] Aucun envoi push de test effectué vers un appareil ou compte non identifié comme appareil de test
- [ ] Tests `notification-service` (`AdminPushViewSetTests`) et `admin-service` (`NewsletterAdminEndpointsTests`) verts
- [ ] `flutter analyze` sans erreur
