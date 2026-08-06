# Documentation Fonctionnelle - Backend Patisry

## Vue d'ensemble

Cette documentation fournit une référence complète de tous les endpoints API du système Patisry, organisée par service. Chaque service est documenté dans un fichier dédié avec les URLs complètes pour la Freebox et le développement local.

**IP Freebox** : `91.171.4.184`  
**Format des ports** : Port externe = Port interne + 20000

## Structure de la documentation

- **00_Guide_Commun.md** : Informations communes à tous les services (Codes HTTP, Gestion des erreurs, Guide Frontend, etc.)
- **01_Auth_Service.md** : Service d'authentification (Port 8000 → 28000)
- **02_User_Service.md** : Service de gestion des utilisateurs (Port 8002 → 28002)
- **03_Display_Service.md** : Service d'affichage des produits (Port 8003 → 28003)
- **04_Product_Service.md** : Service de gestion des produits (Port 8006 → 28006)
- **05_Message_Service.md** : Service de messagerie (Port 8004 → 28004)
- **06_Notification_Service.md** : Service de notifications (Port 8005 → 28005)
- **07_Order_Service.md** : Service de gestion des commandes (Port 8007 → 28007)
- **08_Analytics_Service.md** : Service d'analytics (Port 8008 → 28008)
- **09_Favorite_Service.md** : Service de favoris (Port 8009 → 28009)
- **10_Baker_Service.md** : Service de gestion des pâtissiers (Port 8010 → 28010)
- **11_Search_Service.md** : Service de recherche (Port 8011 → 28011)
- **12_Payment_Service.md** : Service de paiement (Port 8012 → 28012)
- **13_Subscription_Service.md** : Service d'abonnements (Port 8013 → 28013)
- **14_Admin_Service.md** : Service d'administration (Port 8014 → 28014)
- **15_Review_Service.md** : Service d'avis (Port 8015 → 28015)
- **16_Vue_PO_Fonctionnalites_et_Phasage.md** : Vue Product Owner — inventaire fonctionnel (API + app), maturité et phasage MVP → V1
- **17_Agent_Dev_Etat_et_Objectifs.md** : Brief développeur / agent (BE & Flutter) — état technique, objectifs G1–G10, onboarding
- **18_TestSprite_Frontend_MVP_Parcours.md** : Parcours E2E frontend (TestSprite) — MVP consommateur sans Stripe jusqu’à validation commande

## Table des matières

### Guide commun
- [00_Guide_Commun.md](00_Guide_Commun.md)
  - Codes de statut HTTP
  - Gestion des erreurs
  - Limites et contraintes
  - Monitoring et logs
  - Guide d'utilisation Frontend
  - Mapping des ports Freebox

### Services

1. [Auth Service](01_Auth_Service.md) - Authentification et gestion des tokens
2. [User Service](02_User_Service.md) - Gestion des profils utilisateurs
3. [Display Service](03_Display_Service.md) - Affichage des produits avec géolocalisation
4. [Product Service](04_Product_Service.md) - Gestion complète des produits
5. [Message Service](05_Message_Service.md) - Conversations et messages
6. [Notification Service](06_Notification_Service.md) - Notifications utilisateurs
7. [Order Service](07_Order_Service.md) - Panier et commandes
8. [Analytics Service](08_Analytics_Service.md) - Suivi et analytics
9. [Favorite Service](09_Favorite_Service.md) - Favoris et groupes de favoris
10. [Baker Service](10_Baker_Service.md) - Gestion des profils pâtissiers
11. [Search Service](11_Search_Service.md) - Recherche de produits et pâtissiers
12. [Payment Service](12_Payment_Service.md) - Méthodes de paiement et transactions
13. [Subscription Service](13_Subscription_Service.md) - Abonnements et newsletter
14. [Admin Service](14_Admin_Service.md) - Administration et rapports
15. [Review Service](15_Review_Service.md) - Avis et évaluations
16. [Vue PO — Fonctionnalités et phasage](16_Vue_PO_Fonctionnalites_et_Phasage.md) - Synthèse produit, statut API/app, MVP et versions
17. [Agent Dev — État et objectifs](17_Agent_Dev_Etat_et_Objectifs.md) - Brief technique BE/FE, priorités G1–G10, checklist onboarding
18. [TestSprite — MVP frontend sans Stripe](18_TestSprite_Frontend_MVP_Parcours.md) - Scénarios TS-MVP-01…10, routes, hors périmètre

## Mapping des ports

| Service | Port Interne | Port Externe Freebox | Base URL Freebox |
|---------|-------------|---------------------|------------------|
| Auth Service | 8000 | 28000 | `http://91.171.4.184:28000/api/auth/` |
| User Service | 8002 | 28002 | `http://91.171.4.184:28002/api/users/` |
| Display Service | 8003 | 28003 | `http://91.171.4.184:28003/api/display/` |
| Message Service | 8004 | 28004 | `http://91.171.4.184:28004/api/` |
| Notification Service | 8005 | 28005 | `http://91.171.4.184:28005/api/` |
| Product Service | 8006 | 28006 | `http://91.171.4.184:28006/api/products/` |
| Order Service | 8007 | 28007 | `http://91.171.4.184:28007/api/` |
| Analytics Service | 8008 | 28008 | `http://91.171.4.184:28008/api/` |
| Favorite Service | 8009 | 28009 | `http://91.171.4.184:28009/api/favorites/` |
| Baker Service | 8010 | 28010 | `http://91.171.4.184:28010/api/` |
| Search Service | 8011 | 28011 | `http://91.171.4.184:28011/api/search/` |
| Payment Service | 8012 | 28012 | `http://91.171.4.184:28012/api/` |
| Subscription Service | 8013 | 28013 | `http://91.171.4.184:28013/api/` |
| Admin Service | 8014 | 28014 | `http://91.171.4.184:28014/api/admin/` |
| Review Service | 8015 | 28015 | `http://91.171.4.184:28015/api/reviews/` |

## Utilisation

### Pour le développement local

Utilisez les URLs locales avec les ports internes :
- Auth Service : `http://localhost:8000/api/auth/`
- User Service : `http://localhost:8002/api/users/`
- etc.

### Pour la production (Freebox)

Utilisez les URLs Freebox avec les ports externes :
- Auth Service : `http://91.171.4.184:28000/api/auth/`
- User Service : `http://91.171.4.184:28002/api/users/`
- etc.

## Authentification

La plupart des endpoints nécessitent une authentification JWT. Consultez le [Guide Commun](00_Guide_Commun.md) pour plus de détails sur l'authentification et la gestion des tokens.

## Format de documentation

Chaque fichier de service contient :
- Base URLs (Freebox et Local)
- Liste complète des endpoints avec :
  - Méthode HTTP et chemin
  - Description
  - URLs complètes (Freebox et Local)
  - Headers requis
  - Body/Query parameters avec exemples JSON
  - Réponses de succès avec exemples
  - Réponses d'erreur avec exemples
  - Tables sources (si applicable)
  - Authentification requise (oui/non)

## Support

Pour toute question ou problème, consultez d'abord le [Guide Commun](00_Guide_Commun.md) qui contient les informations générales sur les codes d'erreur, les limites, et les bonnes pratiques.





