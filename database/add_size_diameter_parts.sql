-- =====================================================
-- add_size_diameter_parts.sql
-- Ajoute diamètre (cm) et nombre de parts aux tailles — demandé pour que le
-- client voie clairement ce qu'il commande (ex: "20cm — 6-8 parts").
--
-- diameter_cm/parts_count sur product_size_options : valeurs par défaut du
-- référentiel (gérées par l'admin), héritées par une taille standard.
-- diameter_cm/parts_count sur product_sizes : utilisées pour une taille
-- personnalisée (size_option_id NULL) où le pâtissier saisit lui-même ces
-- valeurs — ou pour surcharger le référentiel si besoin (résolution en
-- COALESCE(ps.xxx, pso.xxx), voir product-service et display-service).
-- =====================================================

BEGIN;

ALTER TABLE product_size_options ADD COLUMN IF NOT EXISTS diameter_cm INTEGER;
ALTER TABLE product_size_options ADD COLUMN IF NOT EXISTS parts_count INTEGER;

ALTER TABLE product_sizes ADD COLUMN IF NOT EXISTS diameter_cm INTEGER;
ALTER TABLE product_sizes ADD COLUMN IF NOT EXISTS parts_count INTEGER;

COMMENT ON COLUMN product_size_options.diameter_cm IS 'Diamètre en cm (gâteaux ronds) — facultatif';
COMMENT ON COLUMN product_size_options.parts_count IS 'Nombre de parts — facultatif';
COMMENT ON COLUMN product_sizes.diameter_cm IS 'Diamètre en cm — saisi pour une taille personnalisée, ou surcharge du référentiel';
COMMENT ON COLUMN product_sizes.parts_count IS 'Nombre de parts — saisi pour une taille personnalisée, ou surcharge du référentiel';

COMMIT;
