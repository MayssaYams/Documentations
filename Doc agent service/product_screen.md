# Product Screen Data Contract

L’écran produit (`ProductScreen`) doit recevoir toutes les informations suivantes dans la même réponse pour afficher correctement le produit, le pâtissier, les avis et l’état favori. Le backend peut libérer cet objet depuis `/products/{id}/full/` ou depuis le payload Display si on le simplifie.

## 1. product
- `id` (int) : identifiant utilisé partout (navigation, panier, favoris, etc.).
- `name`, `description`, `subtitle`.
- `price`, `base_price`, `is_active`, `is_available`, `stock_quantity`, `min_order_quantity`, `max_order_quantity`.
- `images` : liste complète des `{ id, imageurl (full URL), format, viewfrom, is_primary, sort_order }`.
- `variants`, `categories`, `allergens`, `tags`.
- `customization_options`, `delivery_info`, `nutritional_info` (si disponibles).
- `average_rating`, `reviews_count`, `orders_count`, `favorites_count`.

## 2. baker
- `id`, `userid`.
- `business_name`, `description`.
- `average_rating`.
- `profile_image_url`.
- `years_experience`, `delivery_radius`, `min_order_amount`, `delivery_fee`, `preparation_time_hours`.
- `phone_number`, `email` (pour la fiche du pâtissier).

## 3. review
- `reviews_count` (int) — déjà dans `product` mais peut être dupliqué ici pour la logique d’UI.
- `average_rating` (double).
- (optionnel) `reviews_preview`: tableau de `{ author, rating, text }` si vous souhaitez afficher un extrait sur la home.

## 4. favorite
- `isFavorite` (bool) — pour afficher l’icône de favoris actif dès l'ouverture du produit.
- `favorite_id` ou `favorite_group_id` (optionnel, utile si l’utilisateur appartient à plusieurs collections).

## Pagination / métadonnées optionnelles
- `filters` : catégories, allergies, ou autres listes utilisées par `HomeScreen`.
- `pagination` : `page`, `page_size`, `has_more`, `total_count` pour la home et éventuellement pour l’UI de recherche.

## Remarques
- L’API Display ou la route produit doit renvoyer ces champs même sans authentification. Les favoris (`isFavorite`) seront `false` pour les utilisateurs non connectés.
- Si un champ n’existe pas (ex : `baker_id`), renvoyer `null` plutôt qu’une valeur par défaut erronée (id=0).
