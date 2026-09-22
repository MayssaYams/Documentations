# Notifications

| | |
|---|---|
| **Statut** | 🔁 à revoir — tap sur notification push jamais testé sur device (PAT-42), voir §4 |
| **Écrit avant le développement ?** | non — écran déjà en production, rédigé rétroactivement le 2026-09-22 |
| **Écrans concernés** | `notifications_screen.dart` (route `/notifications`) + notifications push (Firebase Messaging, `firebase_messaging` dans `pubspec.yaml`) |
| **Endpoints concernés** | `GET /notifications/`, `GET /notifications/unread/`, `PUT .../read/`, `PUT .../mark_all_read/`, `POST/DELETE .../device-tokens/` (notification-service) |
| **Tickets Linear liés** | PAT-42 (navigation, tap notification non testé) |
| **Dernière relecture** | 2026-09-22 |

---

## 1. Périmètre

Liste des notifications in-app (`/notifications`), et le pipeline push complet : demande de permission, enregistrement du token FCM, réception au premier plan/arrière-plan/app fermée, navigation au tap. Le comportement général du bouton retour et des règles `go()`/`push()` de l'app est traité une seule fois dans [`../transverse/navigation-retour-systeme.md`](../transverse/navigation-retour-systeme.md) — ne pas le dupliquer ici, seulement vérifier que cet écran et le tap sur notification le respectent.

## 2. Préconditions

- `client@exemple.com` ou `patissier@exemple.com` (baker 5) connecté — `/notifications` est dans `_protectedPathPrefixes` de `app.dart`.
- Permission notifications accordée sur l'appareil de test (sinon `PushRegistrationService.registerCurrentDevice()` s'arrête silencieusement dès `AuthorizationStatus.denied`, best-effort par conception — voir §5).
- **Un appareil réel** (Android ou iOS) pour le scénario de tap sur notification push app fermée/arrière-plan — non reproductible fidèlement en simulateur pour ce cas précis (comportement système de lancement à froid).
- Au moins une commande en cours entre les deux comptes de test pour générer une notification `orderUpdate` réelle.

## 3. Scénario nominal (happy path)

1. **Ouvrir `/notifications`.** Toujours un rechargement réseau en arrière-plan à l'ouverture, même si un cache existe (commentaire explicite dans `initState` : « le cache ne sert qu'à l'affichage instantané pendant la requête »).
2. **Liste avec notifications non lues.** Fond distinct (`0xFFFCEEF2`) pour les non lues, texte en gras ; bouton « Tout lire » visible uniquement si `unreadCount > 0`.
3. **Tap sur une notification (in-app, app déjà ouverte).** Marque comme lue (`markAsRead`) puis navigue : vers la conversation si `conversationId` renseigné, sinon vers le détail de commande si `orderId` renseigné, sinon reste sur l'écran (`_onTapNotification`, aucune action si ni l'un ni l'autre).
4. **Notification push reçue app au premier plan.** `FirebaseMessaging.onMessage` recharge la liste (`NotificationsService().loadNotifications()`), affiche une notification locale silencieuse (`sound: false` sur iOS, choix produit assumé — commentaire explicite : « la bannière suffit »), et si un `conversation_id` est présent, synchronise immédiatement la conversation concernée (`pollConversation`) plutôt que d'attendre le prochain tick de polling (jusqu'à 3 s de décalage sinon).
5. **Tap sur une notification push, app en arrière-plan.** `FirebaseMessaging.onMessageOpenedApp` → `_navigateForData` : même logique de routage que le tap in-app (conversation > commande > `/notifications` par défaut si aucun identifiant).
6. **Tap sur une notification push, app totalement fermée (cold start).** `FirebaseMessaging.instance.getInitialMessage()` au démarrage → même routage.

## 4. Cas de bord et erreurs attendues

- **Tap sur notification push — jamais testé sur device réel (PAT-42).** La PR de refonte de la navigation (PAT-42, voir [`../transverse/navigation-retour-systeme.md`](../transverse/navigation-retour-systeme.md) §3 point 6 et §7) note explicitement ne pas avoir couvert ce cas : le code de `NotificationTapHandler` (`context.go(...)` vers conversation/commande/`/notifications`) a été écrit et relu, mais jamais vérifié en conditions réelles (tap sur une notification système avec l'app fermée ou en arrière-plan, sur un vrai appareil). **À vérifier en priorité avant de considérer ce document à jour** — sans dupliquer le contexte complet de PAT-42, déjà détaillé dans le document transverse. Cas précis à couvrir : (a) app fermée, tap → ouvre directement le bon écran sans passer par l'accueil ; (b) app en arrière-plan, tap → même résultat ; (c) le routage utilise `context.go()`, qui remplace la pile — vérifier que le retour depuis l'écran ouvert par la notification ne boucle pas et ne ferme pas l'app immédiatement (règle générale du document transverse, à revérifier spécifiquement sur ce point d'entrée qui n'est pas une navigation utilisateur normale).
- **Notification sans `conversation_id` ni `order_id` (type `promotion`/`system`).** `_navigateForData` retombe sur `context.go('/notifications')` — vérifier que ce cas ne produit pas une navigation en boucle si l'utilisateur est déjà sur cet écran.
- **`appNavigatorKey.currentContext == null` au moment du tap** (ex. app pas encore complètement initialisée). `_navigateForData` retourne silencieusement sans naviguer (`if (context == null) return;`) — la notification reste alors sans effet visible, best-effort assumé par le code (commentaire : « ne lève jamais, comme le reste du pipeline push de ce projet »). Un tap sur une notification pendant le tout premier démarrage de l'app pourrait donc ne rien faire — à vérifier si reproductible.
- **Permission notification refusée.** `PushRegistrationService.registerCurrentDevice()` s'arrête dès `AuthorizationStatus.denied`, aucun token enregistré. `verifyPermissionAndReregister()` est censé être rappelé à chaque retour au premier plan pour rattraper un changement de réglage système — vérifier que réactiver la permission dans les réglages système, puis revenir dans l'app, ré-enregistre bien le token sans nécessiter une reconnexion.
- **Rotation du token FCM en cours de session** (restauration depuis sauvegarde, rotation de sécurité). `listenForTokenRefresh()` doit ré-enregistrer automatiquement le nouveau token — best-effort, erreur avalée (`catchError`) si l'appel réseau échoue.
- **Échec de chargement de la liste in-app.** État d'erreur dédié (icône wifi barré, message + détail de l'erreur), distinct de l'état vide (« Aucune notification », uniquement si `hasLoaded && notifications.isEmpty`) — ne pas confondre les deux dans un test.
- **`markAllAsRead` avec 0 notification non lue.** Le bouton « Tout lire » n'est même pas rendu dans ce cas (`unreadCount == 0` → `SizedBox` vide) — vérifier qu'il ne peut pas être déclenché par erreur (ex. double-tap pendant la transition d'état).

## 5. Règles métier à vérifier

- **Best-effort strict sur tout le pipeline push** — aucune étape (permission, `getToken`, enregistrement, réception, tap) ne doit jamais lever d'exception non rattrapée ni bloquer le flux login/logout. Chaque méthode de `PushRegistrationService` et `NotificationTapHandler` a son propre `try/catch` avec `debugPrint`. Vérifier qu'un token FCM `null` (Play Services absents sur émulateur, clé VAPID web absente) ou une permission refusée ne provoque aucun crash ni blocage de connexion.
- Aucune donnée de géolocalisation en jeu sur cet écran.

## 6. Non-régressions connues

- **PAT-42 — tap sur notification push jamais testé sur device réel.** Voir §4. Pas encore un bug confirmé : un point de couverture manquant, explicitement signalé comme tel par la PR d'origine. À faire remonter au statut « non-régression connue avec bug confirmé » ou « validé » dès qu'un test sur device réel aura eu lieu, dans un sens ou dans l'autre.

## 7. Comment vérifier

- Backend : `notification-service` — `manage.py test`.
- **Test manuel obligatoire sur appareil réel** pour le tap sur notification push (§4) — ni le simulateur iOS ni l'émulateur Android ne reproduisent fidèlement un cold start déclenché par une notification système. Voir [`../transverse/navigation-retour-systeme.md`](../transverse/navigation-retour-systeme.md) §7 pour la même exigence côté navigation générale.
- `flutter analyze` 0 erreur.
- Déclencher une vraie notification via le flux commande (ex. changement de statut d'une commande de test entre `patissier@exemple.com` et `client@exemple.com`) plutôt qu'un envoi de test générique, pour valider `conversation_id`/`order_id` réels dans le payload.

## 8. Definition of done

- [ ] Liste in-app : lu/non lu, tout marquer comme lu, état vide, état d'erreur, tous corrects
- [ ] Tap in-app sur une notification navigue vers le bon écran (conversation ou commande)
- [ ] **Tap sur notification push testé sur device réel, app fermée ET arrière-plan** (PAT-42, priorité — voir §4)
- [ ] Permission refusée puis réaccordée : le token se ré-enregistre bien sans reconnexion
- [ ] Aucun crash ni blocage de connexion en cas d'échec du pipeline push (token null, permission refusée)
- [ ] Tests `notification-service` verts, `flutter analyze` 0 erreur
