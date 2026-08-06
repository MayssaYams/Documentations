## Home screen payload format

The home screen (`lib/features/home/presentation/home_screen.dart`) fetches paginated products, enriches them with favorites and review metadata, and renders them via `PastryCard`/`FilterChipList`. To avoid multiple round-trips the backend can return a single paginated payload structured per section (products, bakers, favorites, filters, etc.) that already contains every property the UI reads.

### Pagination envelope
- `page`: current page index (int)
- `page_size`: number of items supplied on this call
- `has_more`: bool
- `next_page`: optional URL/token for subsequent page
- `total_count`: total number of matching products

### Product list (per item)
Each product object is rendered in `PastryCard` and also used to generate filter chips, favorites, and metadata.

Required fields from the table product:
- `id` (int/string): used as navigation argument .
- `name` (string): displayed as title.
- `subtitle` (string, optional): new short marketing text shown below the title inside `PastryCard`.
- `description` (string, optional): available for edit screen and detail view.
- `price` (numbers): displayed as price and for calculation.
- `is_active`, `is_available` (bool): backend can include for badges.
- `images`: list of objects with at least `imageurl` (URL string) + `is_primary`.
- `baker`: nested object (see below).
- `average_rating`, `reviews_count`: displayed via `Rating` widget.
- `categories`: list of objects `{id, name}` used to build chips (`_getCategoriesFromProducts`).
- `is_featured` may be useful for future filtering.
- `tags`, `allergens`, `variants` if you plan to reuse same payload in detail view.

Additional metadata currently populated on the client:
- `isFavorite` (bool): if user.id and the product.id are match in the table user_favoris
- `reviewCount`: should be count by product_id from the table product_reviews; include `reviews_count` or `review_count` per product to avoid the secondary call.

### Baker object
- `baker.id` and `baker.userid`
- `baker.business_name`: shown as pastryType.
- `baker.description`, `baker.average_rating`, `baker.profile_image_url`

### Favorites section (optional)
To render favorite groups without hitting `/favorites` twice, include a `favorites` array of product IDs (or the full product objects) that belong to the default group; each entry can reuse the product schema above and the UI will show the same cards.

