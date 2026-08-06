### Product Service API Mapping

- Products
  - GET `/products/`
  - POST `/products/`
  - GET `/products/{id}/`
  - PUT `/products/{id}/`
  - PATCH `/products/{id}/`
  - DELETE `/products/{id}/`
  - GET `/products/baker/<baker_id>/` - List products by baker (PUBLIC)
- Product Variants
  - POST `/products/variants/`
  - PUT `/products/{product_id}/variants/`
- Product Categories
  - POST `/products/categories/`
  - PUT `/products/{product_id}/categories/`
- Product Images
  - POST `/products/images/`
  - PUT `/products/{product_id}/images/`
  - GET `/products/images/<path:image_key>/` - Public image proxy (local FS on Freebox, S3 in production)
- Product Allergens
  - POST `/products/allergens/`
  - PUT `/products/{product_id}/allergens/`
- Product Quantity Rules
  - POST `/products/quantity-rules/`
  - PUT `/products/{product_id}/quantity-rules/`
- Product History
  - GET `/products/{product_id}/history/`
- Full Product
  - POST `/products/full_product/`
  - GET `/products/{product_id}/full_product/`



