# Scripts de Base de Données PostgreSQL

Ce dossier contient tous les scripts SQL pour créer et maintenir la base de données PostgreSQL de l'application Patisry.

## Ordre d'exécution des scripts

Les scripts doivent être exécutés dans l'ordre suivant :

1. `01_users_and_auth.sql` - Tables utilisateurs et authentification
2. `02_bakers.sql` - Tables pâtissiers et relations
3. `03_products.sql` - Tables produits et variantes
4. `04_orders.sql` - Tables commandes et panier
5. `05_favorites.sql` - Tables favoris et groupes
6. `06_messages.sql` - Tables messages et conversations
7. `07_payments.sql` - Tables paiements et promotions
8. `08_subscriptions.sql` - Tables abonnements
9. `09_analytics_views.sql` - Vues pour analytics et KPIs
10. `10_indexes_and_constraints.sql` - Index et contraintes de performance
11. `11_grant_permissions.sql` - Attribution des droits à l'utilisateur local pour les tests

## Conventions

- Tous les noms de tables sont en minuscules avec underscores
- Les clés primaires sont généralement des UUID ou des séquences auto-incrémentées
- Les timestamps utilisent le type `TIMESTAMP WITH TIME ZONE`
- Les champs JSON utilisent le type `JSONB` pour de meilleures performances
- Tous les scripts incluent des commentaires explicatifs

## Tracking Utilisateur

Le système inclut un tracking complet des actions utilisateur :
- Sessions utilisateur avec cookies et device info
- Page views avec durée et métadonnées
- Actions utilisateur (clics, interactions) avec contexte JSON
- Analytics quotidiennes agrégées par utilisateur et pâtissier


## Connexion forward port to 5433

ssh -p 31456 -L 5433:127.0.0.1:5432 alvin@91.171.4.184 -N