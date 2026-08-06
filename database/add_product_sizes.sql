-- =====================================================
-- add_product_sizes.sql
-- Tailles de produit : référentiel par catégorie (product_size_options) +
-- tailles réellement proposées par un produit, prix ABSOLU (product_sizes).
--
-- Distinct de product_variant (03_products.sql) qui reste inchangé : les
-- variantes (parfums, garnitures...) s'additionnent au prix, les tailles le
-- remplacent. Un produit dont la catégorie a des tailles configurées doit en
-- avoir au moins une avec is_default = TRUE (imposé côté application, voir
-- product-service/products/views.py) — le prix catalogue affiché est celui
-- de la taille par défaut.
--
-- À exécuter manuellement (jamais via manage.py migrate/makemigrations).
-- =====================================================

BEGIN;

-- =====================================================
-- TABLE: product_size_options (référentiel, géré en admin)
-- =====================================================

CREATE TABLE IF NOT EXISTS product_size_options (
    id SERIAL PRIMARY KEY,
    category_id INTEGER NOT NULL REFERENCES category(id) ON DELETE CASCADE,
    label VARCHAR(255) NOT NULL,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT product_size_options_category_label_unique UNIQUE (category_id, label)
);

COMMENT ON TABLE product_size_options IS 'Référentiel des tailles proposées par catégorie de pâtisserie (CRUD admin uniquement)';
COMMENT ON COLUMN product_size_options.category_id IS 'Catégorie à laquelle ce choix de taille s''applique';

CREATE INDEX IF NOT EXISTS idx_product_size_options_category_id ON product_size_options(category_id);
CREATE INDEX IF NOT EXISTS idx_product_size_options_is_active ON product_size_options(is_active) WHERE is_active = TRUE;

-- =====================================================
-- TABLE: product_sizes (tailles réelles d'un produit, prix absolu)
-- =====================================================

CREATE TABLE IF NOT EXISTS product_sizes (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES product(id) ON DELETE CASCADE,
    size_option_id INTEGER REFERENCES product_size_options(id) ON DELETE SET NULL,
    custom_label VARCHAR(255),
    price DECIMAL(10,2) NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Une taille est soit issue du référentiel, soit un libellé libre
    -- ("Autre taille" saisie par le pâtissier) — jamais aucun des deux.
    CONSTRAINT product_sizes_label_required CHECK (size_option_id IS NOT NULL OR custom_label IS NOT NULL)
);

COMMENT ON TABLE product_sizes IS 'Tailles proposées par un produit — prix ABSOLU (remplace le prix de base, contrairement à product_variant qui l''additionne)';
COMMENT ON COLUMN product_sizes.price IS 'Prix absolu de cette taille (pas un supplément)';
COMMENT ON COLUMN product_sizes.custom_label IS 'Libellé libre, utilisé uniquement si size_option_id est NULL (taille hors référentiel)';
COMMENT ON COLUMN product_sizes.is_default IS 'Taille pré-sélectionnée — son prix est celui affiché en catalogue';

CREATE INDEX IF NOT EXISTS idx_product_sizes_product_id ON product_sizes(product_id);
CREATE INDEX IF NOT EXISTS idx_product_sizes_size_option_id ON product_sizes(size_option_id);

-- Un seul is_default = TRUE par produit, imposé au niveau base.
CREATE UNIQUE INDEX IF NOT EXISTS idx_product_sizes_one_default_per_product
    ON product_sizes(product_id) WHERE is_default = TRUE;

CREATE OR REPLACE FUNCTION update_product_size_options_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_product_size_options_updated_at ON product_size_options;
CREATE TRIGGER trigger_product_size_options_updated_at
    BEFORE UPDATE ON product_size_options
    FOR EACH ROW
    EXECUTE FUNCTION update_product_size_options_updated_at();

CREATE OR REPLACE FUNCTION update_product_sizes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_product_sizes_updated_at ON product_sizes;
CREATE TRIGGER trigger_product_sizes_updated_at
    BEFORE UPDATE ON product_sizes
    FOR EACH ROW
    EXECUTE FUNCTION update_product_sizes_updated_at();

COMMIT;
