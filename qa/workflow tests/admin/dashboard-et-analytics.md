# Dashboard et analytics admin

| | |
|---|---|
| **Statut** | ✅ rédigé et à jour |
| **Écrit avant le développement ?** | non — fonctionnalité déjà en production, rédigé rétroactivement le 2026-09-22 |
| **Écrans concernés** | `admin_dashboard_screen.dart` (`/admin`), `admin_analytics_screen.dart` (`/admin/analytics`) |
| **Endpoints concernés** | `GET /api/admin/kpis/` (admin-service) ; `GET /api/analytics/kpis/global/`, `GET /api/analytics/kpis/trends/{period}/`, `GET /api/analytics/kpis/cities/`, `GET /api/analytics/products/top/`, `GET /api/analytics/users/top/` (analytics-service) |
| **Tickets Linear liés** | — |
| **Dernière relecture** | 2026-09-22 |

---

## 1. Périmètre

Les deux écrans d'accueil du panel admin : le tableau de bord (`/admin`, 5 compteurs simples) et la page analytics (`/admin/analytics`, KPIs détaillés + courbe de revenu + tableaux top produits/utilisateurs/villes). Ne couvre pas la navigation entre sections admin ni le contrôle d'accès général au panel (→ [`README.md`](../README.md) et section 5 ci-dessous pour le rappel du point d'entrée unique `IsAdminRole`, détaillé une seule fois ici et réutilisé par lien dans les 6 autres fichiers `admin/`).

## 2. Préconditions

- Un compte admin de test existant (`group_id = 1`) — mot de passe documenté dans la mémoire projet, ne jamais l'écrire en clair ici.
- Au moins quelques commandes, produits et utilisateurs en base sur staging pour que les compteurs ne soient pas tous à zéro (les comptes standard `patissier@exemple.com` / `client@exemple.com` suffisent pour un premier passage, pas besoin de volumétrie réaliste pour valider l'affichage).
- Environnement cible : staging (`stg.patisry.fr`) — CLAUDE.md, la Freebox est abandonnée.

## 3. Scénario nominal (happy path)

1. **Connexion avec le compte admin puis navigation vers `/admin`.** Un utilisateur non-admin qui tente d'accéder est redirigé vers `/account` côté client (voir §5) ; l'admin voit le tableau de bord.
2. **Tableau de bord (`/admin`).** Cinq cartes s'affichent : Utilisateurs, Pâtissiers, Produits, Commandes, Revenu total — valeurs issues de `GET /api/admin/kpis/`, un seul appel réseau.
3. **Navigation vers `/admin/analytics`.** Cinq appels réseau parallèles (`Future.wait`) : KPIs globaux, tendance mensuelle, produits/utilisateurs top 10, répartition par ville. Chargement affiché avec un seul spinner pour l'ensemble — pas de chargement partiel section par section.
4. **Lecture des KPIs globaux.** 8 cartes : utilisateurs (+ nouveaux 30j), pâtissiers actifs (+ vérifiés), produits actifs, commandes (+ 30j), revenu total (+ 30j), panier moyen, messages, favoris.
5. **Courbe de revenu.** Douze derniers mois (`getTrends('monthly')`), affichée du plus ancien au plus récent (la réponse est inversée côté client — `.reversed`).
6. **Tableaux « Produits les plus performants » et « Utilisateurs les plus actifs ».** Dix lignes maximum chacun, triés par le backend (l'écran ne trie pas côté client, il se contente de tronquer à `take(10)`).
7. **Tableau « Répartition géographique ».** N'apparaît que si `_cities` n'est pas vide — absence de section plutôt que section vide si aucune ville n'a de données.
8. **Rafraîchir.** Le bouton de rafraîchissement de `/admin/analytics` relance les 5 appels.

## 4. Cas de bord et erreurs attendues

- **Échec d'un seul des 5 appels analytics.** `Future.wait` échoue globalement dès qu'un des 5 appels échoue : toute la page bascule sur le message d'erreur générique « Impossible de charger les analytics. », même si 4 des 5 endpoints ont répondu correctement. Pas de dégradation partielle — à vérifier explicitement en coupant un service (ex : arrêter analytics-service et confirmer qu'aucun chiffre ne s'affiche, plutôt que de deviner).
- **`/admin/kpis/` et les KPIs globaux d'analytics ne comptent pas la même chose.** `kpis()` (dashboard) fait un `COUNT` brut sur `AccountsUser`/`Baker`/`Product`/`Orders` sans filtre `is_active` ni filtre de statut — un utilisateur banni, un pâtissier suspendu ou un produit désactivé sont comptés comme n'importe quel autre. Les KPIs analytics (`active_bakers`, `active_products`) filtrent, eux, sur l'état actif. **Ne pas s'étonner d'un écart entre les deux écrans** : c'est un calcul différent, pas un bug, mais à vérifier en base si un écart semble anormal plutôt que de le supposer.
- **Non-admin qui appelle directement les endpoints.** `IsAdminRole` doit renvoyer 403, pas 500 ni une liste vide (voir §5).
- **Ville avec des valeurs à zéro.** Un utilisateur/pâtissier/commande/revenu à zéro pour une ville doit s'afficher comme `0`, pas être filtré silencieusement de la liste.

## 5. Règles métier à vérifier

- **Point d'entrée unique « qui est admin »** : `IsAdminRole` (`Backend/admin-service/admin_app/permissions.py`) — basé uniquement sur `group_id == 1` relu en base à chaque requête via le JWT, jamais sur `is_staff`/`is_superuser`. C'est la même logique dans tous les endpoints `/api/admin/...` de tous les services (product-service utilise l'équivalent `IsAdminOnly`). **Cette règle est décrite une seule fois ici** ; les 6 autres fichiers `admin/` y renvoient par lien plutôt que de la répéter.
- **Le gating client (`_adminOnlyPathPrefixes` dans `app.dart`) n'est qu'un confort UX**, pas une sécurité : le commentaire du code le dit explicitement (« Le vrai rempart est le contrôle serveur »). Un non-admin qui accède à `/admin` côté Flutter est redirigé vers `/account`, mais ce n'est pas ce qui protège les données — vérifier que les endpoints eux-mêmes rejettent un JWT non-admin (403), pas seulement que l'écran ne s'affiche pas.

## 6. Non-régressions connues

_Aucune connue à ce jour — première rédaction de cette fiche. Ajouter ici tout bug réel rencontré lors d'une future campagne._

## 7. Comment vérifier

- Backend : `admin-service` (`manage.py test`, classe `AdminEndpointsTests.test_kpis` pour le calcul des compteurs, `test_permission_denied_without_auth` pour le rejet sans JWT — voir `Backend/admin-service/admin_app/tests/test_endpoints.py`).
- Vérification manuelle directe : comparer un compteur affiché (ex. « Commandes ») à `SELECT COUNT(*) FROM orders` en base staging.
- Frontend : `flutter analyze` (zéro erreur) + test manuel staging avec le compte admin et, pour le cas de bord 403, un compte client standard tentant d'appeler `GET /api/admin/kpis/` directement (ex. via un client HTTP, pas via l'UI qui bloque déjà la route).

## 8. Definition of done

- [ ] Tableau de bord et analytics affichent des valeurs cohérentes avec un contrôle direct en base
- [ ] Échec d'un seul endpoint analytics fait bien basculer toute la page en erreur (comportement vérifié, pas supposé)
- [ ] Écart éventuel dashboard vs analytics expliqué par la différence de filtre actif/inactif, pas traité comme un bug par défaut
- [ ] Accès direct aux endpoints par un compte non-admin renvoie 403
- [ ] Tests `admin-service` verts
- [ ] `flutter analyze` sans erreur
