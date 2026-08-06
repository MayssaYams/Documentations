-- =====================================================
-- alter_size_dimensions_to_text.sql
-- diameter_cm/parts_count passent de INTEGER à VARCHAR pour supporter :
--   - diameter_cm : diamètre rond ("20") OU dimensions rectangle ("15x15")
--   - parts_count : nombre fixe ("8") OU plage ("10-12")
-- Validation du format faite côté application (product-service/serializers.py),
-- pas en base.
--
-- À exécuter manuellement, après add_size_diameter_parts.sql, sur la même base.
-- =====================================================

BEGIN;

ALTER TABLE product_size_options ALTER COLUMN diameter_cm TYPE VARCHAR(20) USING diameter_cm::text;
ALTER TABLE product_size_options ALTER COLUMN parts_count TYPE VARCHAR(20) USING parts_count::text;

ALTER TABLE product_sizes ALTER COLUMN diameter_cm TYPE VARCHAR(20) USING diameter_cm::text;
ALTER TABLE product_sizes ALTER COLUMN parts_count TYPE VARCHAR(20) USING parts_count::text;

COMMENT ON COLUMN product_size_options.diameter_cm IS 'Diamètre rond ("20") ou dimensions rectangle ("15x15") — facultatif';
COMMENT ON COLUMN product_size_options.parts_count IS 'Nombre de parts fixe ("8") ou plage ("10-12") — facultatif';
COMMENT ON COLUMN product_sizes.diameter_cm IS 'Diamètre ou dimensions — saisi pour une taille personnalisée, ou surcharge du référentiel';
COMMENT ON COLUMN product_sizes.parts_count IS 'Nombre de parts fixe ou plage — saisi pour une taille personnalisée, ou surcharge du référentiel';

COMMIT;
