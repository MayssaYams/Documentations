# APIs Futures à Développer - Patisry Backend

## Vue d'ensemble

Ce document liste toutes les APIs qui doivent être développées pour compléter l'écosystème Patisry. Ces APIs sont nécessaires pour remplacer les données mock du frontend et implémenter toutes les fonctionnalités identifiées.

---

## 1. Message Service (Port 8004)

**Base URL**: `http://localhost:8004/api/messages/`

### 1.1 Gestion des Conversations

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/conversations/` | Liste des conversations de l'utilisateur | `conversations`, `conversation_participants` |
| POST | `/conversations/` | Créer une nouvelle conversation | `conversations`, `conversation_participants` |
| GET | `/conversations/{id}/` | Détails d'une conversation | `conversations`, `conversation_participants` |
| PUT | `/conversations/{id}/` | Mettre à jour une conversation | `conversations` |
| DELETE | `/conversations/{id}/` | Supprimer une conversation | `conversations` |
| POST | `/conversations/{id}/participants/` | Ajouter un participant | `conversation_participants` |
| DELETE | `/conversations/{id}/participants/{user_id}/` | Retirer un participant | `conversation_participants` |

### 1.2 Gestion des Messages

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/conversations/{id}/messages/` | Messages d'une conversation | `messages`, `message_attachments` |
| POST | `/messages/` | Envoyer un message | `messages`, `message_attachments` |
| PUT | `/messages/{id}/` | Modifier un message | `messages` |
| DELETE | `/messages/{id}/` | Supprimer un message | `messages` |
| POST | `/messages/{id}/reactions/` | Ajouter une réaction | `message_reactions` |
| DELETE | `/messages/{id}/reactions/{reaction_id}/` | Supprimer une réaction | `message_reactions` |
| PUT | `/messages/{id}/read/` | Marquer comme lu | `messages`, `conversation_participants` |

### 1.3 Templates et Notifications

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/templates/` | Liste des templates de messages | `conversation_templates` |
| POST | `/templates/` | Créer un template | `conversation_templates` |
| GET | `/notifications/unread-count/` | Nombre de messages non lus | `conversation_participants` |
| POST | `/notifications/mark-all-read/` | Marquer tous comme lus | `conversation_participants` |

---

## 2. Notification Service (Port 8005)

**Base URL**: `http://localhost:8005/api/notifications/`

### 2.1 Gestion des Notifications

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/` | Liste des notifications de l'utilisateur | `user_notifications` |
| GET | `/unread/` | Notifications non lues | `user_notifications` |
| PUT | `/{id}/read/` | Marquer comme lue | `user_notifications` |
| PUT | `/mark-all-read/` | Marquer toutes comme lues | `user_notifications` |
| DELETE | `/{id}/` | Supprimer une notification | `user_notifications` |
| POST | `/send/` | Envoyer une notification | `user_notifications` |

### 2.2 Préférences de Notification

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/preferences/` | Préférences de notification | `user_preferences` |
| PUT | `/preferences/` | Mettre à jour les préférences | `user_preferences` |
| POST | `/preferences/test/` | Tester les notifications | `user_notifications` |

### 2.3 Templates de Notification

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/templates/` | Templates de notification | `notification_templates` |
| POST | `/templates/` | Créer un template | `notification_templates` |
| PUT | `/templates/{id}/` | Modifier un template | `notification_templates` |
| DELETE | `/templates/{id}/` | Supprimer un template | `notification_templates` |

---

## 3. Order Service (Port 8007)

**Base URL**: `http://localhost:8007/api/orders/`

### 3.1 Gestion des Commandes

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/` | Liste des commandes de l'utilisateur | `orders`, `order_detail` |
| GET | `/baker/` | Commandes du pâtissier | `orders`, `order_detail` |
| GET | `/{id}/` | Détails d'une commande | `orders`, `order_detail` |
| POST | `/` | Créer une commande | `orders`, `order_detail` |
| PUT | `/{id}/` | Mettre à jour une commande | `orders` |
| PUT | `/{id}/status/` | Changer le statut | `orders`, `order_status_history` |
| DELETE | `/{id}/` | Annuler une commande | `orders` |

### 3.2 Gestion du Panier

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/cart/` | Contenu du panier | `cart`, `cart_items` |
| POST | `/cart/items/` | Ajouter un article | `cart_items` |
| PUT | `/cart/items/{id}/` | Modifier un article | `cart_items` |
| DELETE | `/cart/items/{id}/` | Supprimer un article | `cart_items` |
| DELETE | `/cart/clear/` | Vider le panier | `cart_items` |
| POST | `/cart/checkout/` | Passer commande | `orders`, `order_detail` |

### 3.3 Suivi et Livraison

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/{id}/tracking/` | Suivi de livraison | `order_tracking` |
| POST | `/{id}/tracking/` | Mettre à jour le suivi | `order_tracking` |
| GET | `/{id}/status-history/` | Historique des statuts | `order_status_history` |
| GET | `/delivery-zones/` | Zones de livraison | `delivery_zones` |
| GET | `/delivery-time-slots/` | Créneaux de livraison | `delivery_time_slots` |

---

## 4. Analytics Service (Port 8008)

**Base URL**: `http://localhost:8008/api/analytics/`

### 4.1 Analytics Utilisateur

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| POST | `/page-view/` | Enregistrer une vue de page | `user_page_views` |
| POST | `/user-action/` | Enregistrer une action utilisateur | `user_actions` |
| POST | `/search/` | Enregistrer une recherche | `user_search_history` |
| GET | `/user/stats/` | Statistiques utilisateur | `user_analytics_daily` |
| GET | `/user/dashboard/` | Dashboard utilisateur | `user_analytics_daily` |

### 4.2 Analytics Pâtissier

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/baker/{id}/stats/` | Statistiques pâtissier | `baker_analytics_daily` |
| GET | `/baker/{id}/dashboard/` | Dashboard pâtissier | `baker_analytics_daily` |
| GET | `/baker/{id}/revenue/` | Statistiques de revenus | `orders`, `payments` |
| GET | `/baker/{id}/orders/` | Statistiques de commandes | `orders` |
| GET | `/baker/{id}/products/` | Statistiques des produits | `product_analytics_daily` |

### 4.3 Analytics Produit

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| POST | `/product-view/` | Enregistrer une vue de produit | `product_views` |
| GET | `/product/{id}/stats/` | Statistiques produit | `product_analytics_daily` |
| GET | `/product/{id}/views/` | Vues du produit | `product_views` |
| GET | `/product/{id}/favorites/` | Favoris du produit | `user_favoris` |

### 4.4 Analytics Globales

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/global/kpis/` | KPIs globaux | `global_kpis` |
| GET | `/global/daily/` | KPIs quotidiens | `daily_kpis` |
| GET | `/global/monthly/` | Tendances mensuelles | `monthly_trends` |
| GET | `/global/weekly/` | Tendances hebdomadaires | `weekly_trends` |

---

## 5. Favorite Service (Port 8009)

**Base URL**: `http://localhost:8009/api/favorites/`

### 5.1 Gestion des Favoris

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/` | Liste des favoris de l'utilisateur | `user_favoris` |
| POST | `/` | Ajouter un favori | `user_favoris` |
| DELETE | `/{id}/` | Supprimer un favori | `user_favoris` |
| GET | `/groups/` | Groupes de favoris | `favorite_groups` |
| POST | `/groups/` | Créer un groupe | `favorite_groups` |
| PUT | `/groups/{id}/` | Modifier un groupe | `favorite_groups` |
| DELETE | `/groups/{id}/` | Supprimer un groupe | `favorite_groups` |

### 5.2 Gestion des Groupes

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/groups/{id}/items/` | Articles d'un groupe | `favorite_group_items` |
| POST | `/groups/{id}/items/` | Ajouter un article au groupe | `favorite_group_items` |
| DELETE | `/groups/{id}/items/{item_id}/` | Retirer un article | `favorite_group_items` |
| POST | `/groups/{id}/share/` | Partager un groupe | `favorite_shares` |
| GET | `/groups/shared/` | Groupes partagés | `favorite_shares` |

### 5.3 Recommandations

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/recommendations/` | Recommandations basées sur les favoris | `favorite_recommendations` |
| GET | `/recommendations/similar/` | Produits similaires aux favoris | `product_recommendations` |
| GET | `/recommendations/trending/` | Produits tendance dans les groupes | `product_recommendations` |

---

## 6. Baker Service (Port 8010)

**Base URL**: `http://localhost:8010/api/bakers/`

### 6.1 Gestion des Pâtissiers

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/` | Liste des pâtissiers | `baker`, `baker_specialties` |
| GET | `/{id}/` | Détails d'un pâtissier | `baker`, `baker_specialties`, `baker_certifications` |
| PUT | `/{id}/` | Mettre à jour le profil | `baker` |
| GET | `/{id}/products/` | Produits du pâtissier | `product`, `product_image` |
| GET | `/{id}/reviews/` | Avis du pâtissier | `baker_review` |

### 6.2 Spécialités et Certifications

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/{id}/specialties/` | Spécialités du pâtissier | `baker_specialties` |
| POST | `/{id}/specialties/` | Ajouter une spécialité | `baker_specialties` |
| DELETE | `/{id}/specialties/{specialty_id}/` | Supprimer une spécialité | `baker_specialties` |
| GET | `/{id}/certifications/` | Certifications | `baker_certifications` |
| POST | `/{id}/certifications/` | Ajouter une certification | `baker_certifications` |

### 6.3 Horaires et Disponibilité

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/{id}/working-hours/` | Horaires de travail | `baker_working_hours` |
| PUT | `/{id}/working-hours/` | Mettre à jour les horaires | `baker_working_hours` |
| GET | `/{id}/availability/` | Disponibilité | `baker_availability` |
| PUT | `/{id}/availability/` | Mettre à jour la disponibilité | `baker_availability` |
| GET | `/{id}/followers/` | Followers | `baker_followers` |
| POST | `/{id}/follow/` | Suivre un pâtissier | `baker_followers` |
| DELETE | `/{id}/follow/` | Ne plus suivre | `baker_followers` |

---

## 7. Search Service (Port 8011)

**Base URL**: `http://localhost:8011/api/search/`

### 7.1 Recherche Avancée

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| POST | `/products/` | Recherche de produits | `product`, `product_tags`, `product_categories` |
| POST | `/bakers/` | Recherche de pâtissiers | `baker`, `baker_specialties` |
| POST | `/nearby/` | Recherche par proximité | `product`, `baker`, `accounts_user` |
| GET | `/suggestions/` | Suggestions de recherche | `user_search_history` |
| GET | `/trending/` | Recherches tendance | `user_search_history` |

### 7.2 Filtres et Tri

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/filters/categories/` | Catégories disponibles | `product_categories` |
| GET | `/filters/tags/` | Tags disponibles | `product_tags` |
| GET | `/filters/allergens/` | Allergènes disponibles | `allergen` |
| GET | `/filters/price-ranges/` | Gammes de prix | `product` |
| GET | `/filters/locations/` | Localisations disponibles | `accounts_user` |

---

## 8. Payment Service (Port 8012)

**Base URL**: `http://localhost:8012/api/payments/`

### 8.1 Gestion des Paiements

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| POST | `/` | Traiter un paiement | `payments`, `payment_transactions` |
| GET | `/{id}/` | Détails d'un paiement | `payments`, `payment_transactions` |
| POST | `/{id}/refund/` | Rembourser un paiement | `payments`, `payment_transactions` |
| GET | `/methods/` | Méthodes de paiement | `payment_method` |
| POST | `/methods/` | Ajouter une méthode | `payment_method` |
| DELETE | `/methods/{id}/` | Supprimer une méthode | `payment_method` |

### 8.2 Promotions et Remises

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/promotions/` | Promotions actives | `promotion` |
| POST | `/promotions/validate/` | Valider un code | `promotion`, `promotion_usage` |
| GET | `/promotions/{id}/usage/` | Utilisation d'une promotion | `promotion_usage` |

---

## 9. Subscription Service (Port 8013)

**Base URL**: `http://localhost:8013/api/subscriptions/`

### 9.1 Gestion des Abonnements

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/plans/` | Plans d'abonnement | `subscription_plans` |
| GET | `/plans/{id}/` | Détails d'un plan | `subscription_plans`, `subscription_features` |
| GET | `/user/` | Abonnement de l'utilisateur | `user_subscriptions` |
| POST | `/subscribe/` | Souscrire à un plan | `user_subscriptions` |
| PUT | `/cancel/` | Annuler l'abonnement | `user_subscriptions` |
| POST | `/upgrade/` | Changer de plan | `user_subscriptions` |

### 9.2 Facturation

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/billing/` | Historique de facturation | `subscription_billing` |
| GET | `/billing/{id}/invoice/` | Télécharger une facture | `subscription_billing` |
| GET | `/usage/` | Utilisation des quotas | `subscription_usage` |
| GET | `/discounts/` | Remises disponibles | `subscription_discounts` |
| POST | `/discounts/apply/` | Appliquer une remise | `subscription_discount_usage` |

---

## 10. Admin Service (Port 8014)

**Base URL**: `http://localhost:8014/api/admin/`

### 10.1 Gestion des Utilisateurs

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/users/` | Liste des utilisateurs | `accounts_user` |
| GET | `/users/{id}/` | Détails d'un utilisateur | `accounts_user`, `user_analytics_daily` |
| PUT | `/users/{id}/status/` | Changer le statut | `accounts_user` |
| GET | `/users/stats/` | Statistiques utilisateurs | `user_analytics_daily` |

### 10.2 Gestion des Pâtissiers

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/bakers/` | Liste des pâtissiers | `baker` |
| GET | `/bakers/{id}/` | Détails d'un pâtissier | `baker`, `baker_analytics_daily` |
| PUT | `/bakers/{id}/verify/` | Vérifier un pâtissier | `baker` |
| GET | `/bakers/stats/` | Statistiques pâtissiers | `baker_analytics_daily` |

### 10.3 Gestion des Produits

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/products/` | Liste des produits | `product` |
| GET | `/products/{id}/` | Détails d'un produit | `product`, `product_analytics_daily` |
| PUT | `/products/{id}/feature/` | Mettre en avant | `product` |
| GET | `/products/stats/` | Statistiques produits | `product_analytics_daily` |

### 10.4 KPIs et Rapports

| Méthode | Endpoint | Description | Tables Sources |
|---------|----------|-------------|----------------|
| GET | `/kpis/` | KPIs globaux | `global_kpis` |
| GET | `/reports/daily/` | Rapport quotidien | `daily_kpis` |
| GET | `/reports/monthly/` | Rapport mensuel | `monthly_trends` |
| GET | `/reports/export/` | Exporter les données | Toutes les tables |

---

## 11. Priorités de Développement

### Phase 1 (Critique)
1. **Order Service** - Nécessaire pour les commandes
2. **Message Service** - Communication pâtissier-client
3. **Analytics Service** - Tracking utilisateur

### Phase 2 (Important)
4. **Notification Service** - Notifications temps réel
5. **Favorite Service** - Gestion des favoris
6. **Payment Service** - Traitement des paiements

### Phase 3 (Amélioration)
7. **Baker Service** - Gestion avancée des pâtissiers
8. **Search Service** - Recherche avancée
9. **Subscription Service** - Abonnements premium
10. **Admin Service** - Administration

---

## 12. Considérations Techniques

### 12.1 Authentification
- Tous les services doivent valider les tokens JWT
- Utilisation du service auth-service pour la validation
- Gestion des rôles et permissions

### 12.2 Base de Données
- Chaque service peut avoir sa propre base de données
- Utilisation des tables définies dans les scripts SQL
- Synchronisation des données entre services

### 12.3 Communication Inter-Services
- Utilisation de HTTP/REST pour la communication
- Gestion des erreurs et timeouts
- Logging centralisé

### 12.4 Monitoring et Observabilité
- Métriques de performance pour chaque service
- Logs structurés
- Alertes en cas de problème

---

## 13. Estimation des Efforts

| Service | Complexité | Temps Estimé | Développeurs |
|---------|------------|--------------|--------------|
| Order Service | Haute | 3-4 semaines | 2 |
| Message Service | Haute | 2-3 semaines | 2 |
| Analytics Service | Moyenne | 2 semaines | 1 |
| Notification Service | Moyenne | 2 semaines | 1 |
| Favorite Service | Faible | 1 semaine | 1 |
| Payment Service | Haute | 3-4 semaines | 2 |
| Baker Service | Moyenne | 2 semaines | 1 |
| Search Service | Moyenne | 2 semaines | 1 |
| Subscription Service | Haute | 3 semaines | 2 |
| Admin Service | Moyenne | 2 semaines | 1 |

**Total estimé**: 20-25 semaines avec 2-3 développeurs
