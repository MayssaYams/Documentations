-- =====================================================
-- add_product_sizes_order_service.sql
-- Propage la taille choisie (product_sizes, voir add_product_sizes.sql) au
-- panier et à la commande — même pattern que product_variant_id/variantid
-- déjà en place (04_orders.sql). Prix figé dans unit_price/total_price au
-- moment de l'ajout, comme pour le produit/variante.
--
-- À exécuter manuellement, après add_product_sizes.sql, sur la même base
-- (order-service partage le schéma Postgres avec product-service).
-- =====================================================

BEGIN;

ALTER TABLE cart_items ADD COLUMN IF NOT EXISTS product_size_id INTEGER
    REFERENCES product_sizes(id) ON DELETE SET NULL;

ALTER TABLE order_detail ADD COLUMN IF NOT EXISTS size_id INTEGER
    REFERENCES product_sizes(id) ON DELETE SET NULL;

COMMENT ON COLUMN cart_items.product_size_id IS 'Taille choisie (product_sizes) — NULL si le produit n''a pas de tailles';
COMMENT ON COLUMN order_detail.size_id IS 'Taille commandée (product_sizes) — NULL si le produit n''a pas de tailles';

CREATE INDEX IF NOT EXISTS idx_cart_items_size_id ON cart_items(product_size_id);
CREATE INDEX IF NOT EXISTS idx_order_detail_size_id ON order_detail(size_id);

-- La contrainte UNIQUE d'origine sur cart_items ne connaît pas la taille :
-- deux tailles différentes du même produit (même variante, même créneau)
-- seraient donc traitées comme la même ligne de panier. On la remplace par
-- une contrainte équivalente incluant product_size_id, en retrouvant son nom
-- auto-généré dynamiquement plutôt que de le supposer.
DO $$
DECLARE
    old_constraint_name TEXT;
BEGIN
    SELECT con.conname INTO old_constraint_name
    FROM pg_constraint con
    JOIN pg_class rel ON rel.oid = con.conrelid
    WHERE rel.relname = 'cart_items'
      AND con.contype = 'u'
      AND con.conname <> 'cart_items_unique_with_size'
      AND (
          SELECT array_agg(attname::text ORDER BY attname)
          FROM unnest(con.conkey) AS k(attnum)
          JOIN pg_attribute a ON a.attrelid = con.conrelid AND a.attnum = k.attnum
      ) = ARRAY['cart_id', 'delivery_date', 'delivery_time_slot', 'product_id', 'product_variant_id']::text[];

    IF old_constraint_name IS NOT NULL THEN
        EXECUTE format('ALTER TABLE cart_items DROP CONSTRAINT %I', old_constraint_name);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'cart_items_unique_with_size'
    ) THEN
        ALTER TABLE cart_items ADD CONSTRAINT cart_items_unique_with_size
            UNIQUE (cart_id, product_id, product_variant_id, product_size_id, delivery_date, delivery_time_slot);
    END IF;
END $$;

COMMIT;
