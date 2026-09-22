# Index — workflow tests

Un fichier par ligne. Statuts : 🔲 à rédiger, 🟡 en écriture, ✅ rédigé et à jour, 🔁 à revoir. Mis à jour par qui rédige ou relit un fichier — ne pas laisser une ligne périmée.

À chaque nouvel écran/fonctionnalité ajouté au produit, ajouter une ligne ici **avant** le développement (voir [`README.md`](README.md)).

## compte/

| Fichier | Écrans couverts | Statut |
|---|---|---|
| `compte/inscription.md` | `register_screen`, `email_verification_screen` | 🔲 |
| `compte/connexion-et-mot-de-passe-oublie.md` | `login_screen`, `forgot_password_screen` | 🔲 |
| `compte/profil-client.md` | `connected_account_screen`, `edit_personal_info_screen`, `profile_screen` | 🔲 |
| `compte/suppression-compte-rgpd.md` | `account_deletion_screen` | 🔲 |
| `compte/pages-legales-et-consentement.md` | `legal_notice_screen`, `analytics_consent_dialog` | 🔲 |

## catalogue/

| Fichier | Écrans couverts | Statut |
|---|---|---|
| `catalogue/accueil.md` | `home_screen` (hors localisation, voir `transverse/localisation-memorisation.md`) | 🔲 |
| `catalogue/recherche.md` | feature `search` | 🔲 |
| `catalogue/fiche-produit.md` | `product_screen` | 🔲 |
| `catalogue/fiche-patissier-publique.md` | `baker_profile_screen` | 🔲 |
| `catalogue/favoris.md` | `favorites_screen`, `favorite_group_detail_screen` (+ note code mort `favorite_screen.dart`, cf. PAT-80) | 🔲 |
| `catalogue/mes-patisseries.md` | `my_pastries_screen`, `edit_pastry_screen` | 🔲 |
| `catalogue/notifications.md` | `notifications_screen` + notifications push (tap → deep link, cf. PAT-42 non testé sur device) | 🔲 |

## commande-et-paiement/

| Fichier | Écrans couverts | Statut |
|---|---|---|
| `commande-et-paiement/panier-et-validation-commande.md` | `cart_screen`, `payment_screen`, `payment_confirmation_screen` | ✅ |
| `commande-et-paiement/moyens-de-paiement.md` | `payment_methods_screen`, `add_card_screen`, `edit_card_screen`, `apple_pay_screen`, `google_pay_screen`, `paypal_screen` | ✅ |
| `commande-et-paiement/cycle-de-vie-commande.md` | `orders_screen`, `order_detail_screen`, `ready_dialogs` | ✅ |
| `commande-et-paiement/messages.md` | `messages_screen`, `conversation_screen` | ✅ |
| `commande-et-paiement/avis.md` | `reviews_screen`, `write_review_screen` | ✅ |

## patissier/

| Fichier | Écrans couverts | Statut |
|---|---|---|
| `patissier/adresse-et-position.md` | `baker_address_screen` (PAT-74/75/76) | ✅ |
| `patissier/bascule-baker-client.md` | `edit_baker_info_screen`, downgrade/upgrade (CLAUDE.md §Règles métier) | ✅ |

## transverse/

| Fichier | Portée | Statut |
|---|---|---|
| `transverse/navigation-retour-systeme.md` | Tout l'app — bouton retour, `go`/`push` (PAT-42) | 🔁 (PR non mergée, non testée device) |
| `transverse/localisation-memorisation.md` | Tout l'app — mode GPS/ville mémorisé (PAT-77), `location_chip`, `location_flow`, `manual_location_sheet` | 🔁 (raffinement en cours) |

## admin/

| Fichier | Écrans couverts | Statut |
|---|---|---|
| `admin/dashboard-et-analytics.md` | `admin_dashboard_screen`, `admin_analytics_screen` | 🔲 |
| `admin/baker-et-produits.md` | `admin_bakers_screen`, `admin_products_screen` | 🔲 |
| `admin/utilisateurs-et-audit.md` | `admin_users_screen`, `admin_audit_log_screen` | 🔲 |
| `admin/moderation-avis.md` | `admin_review_reports_screen` | 🔲 |
| `admin/referentiels.md` | `admin_allergens_screen`, `admin_categories_screen`, `admin_size_options_screen` | 🔲 |
| `admin/communication.md` | `admin_newsletter_screen`, `admin_push_screen` | 🔲 |
| `admin/parametres.md` | `admin_settings_screen` | 🔲 |

## Hors périmètre pour l'instant (pas d'écran ou dormant)

- `subscription_screen.dart` — fonctionnalité abonnement **dormante** (tables en base, pas de logique active), cf. mémoire `patisry-deferred-feature-opportunities`. Pas de workflow test tant que la fonctionnalité n'est pas activée.
- `dashboard_screen.dart` (hors admin) — à vérifier s'il est routé/utilisé avant de lui écrire un fichier.
- Code mort identifié par PAT-80 (`login_screen_clean.dart`, `connexion_screen.dart`, `connected_screen.dart`, `favorite/favorite_screen.dart`, `toolbar.dart`) — pas de workflow test tant qu'il n'est pas confirmé vivant ou supprimé.
