-- =====================================================
-- 03_products.sql
-- Tables produits, variantes, images, reviews et tracking
-- =====================================================

-- Extension pour UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- TABLE: product (table principale produits)
-- =====================================================

-- Création de la table product si elle n'existe pas
CREATE TABLE IF NOT EXISTS product (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    subtitle TEXT,
    dimensions VARCHAR(100),
    price DECIMAL(10,2) NOT NULL,
    preparation_time INTEGER, -- en heures
    is_refrigerated BOOLEAN,
    expiration_date DATE,
    available_from DATE,
    available_to DATE,
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    location TEXT, -- PostGIS geometry si nécessaire
    baker_id INTEGER REFERENCES baker(id) ON DELETE SET NULL,
    sku VARCHAR(100) UNIQUE,
    slug VARCHAR(255) UNIQUE,
    is_featured BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    is_available BOOLEAN DEFAULT TRUE,
    stock_quantity INTEGER DEFAULT 0,
    min_order_quantity INTEGER DEFAULT 1,
    max_order_quantity INTEGER,
    weight_grams INTEGER,
    serving_size VARCHAR(50),
    ingredients TEXT,
    nutritional_info JSONB,
    tags JSONB,
    customization_options JSONB,
    delivery_info JSONB,
    views_count INTEGER DEFAULT 0,
    favorites_count INTEGER DEFAULT 0,
    orders_count INTEGER DEFAULT 0,
    reviews_count INTEGER DEFAULT 0
);

COMMENT ON TABLE product IS 'Table principale des produits pâtissiers';
COMMENT ON COLUMN product.baker_id IS 'Référence vers le pâtissier propriétaire';
COMMENT ON COLUMN product.sku IS 'Stock Keeping Unit - identifiant unique du produit';
COMMENT ON COLUMN product.slug IS 'URL-friendly identifier';
COMMENT ON COLUMN product.is_featured IS 'Produit mis en avant';
COMMENT ON COLUMN product.preparation_time IS 'Temps de préparation en heures';
COMMENT ON COLUMN product.nutritional_info IS 'Informations nutritionnelles (JSON)';
COMMENT ON COLUMN product.customization_options IS 'Options de personnalisation (JSON)';

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_product_baker_id ON product(baker_id);
CREATE INDEX IF NOT EXISTS idx_product_is_active ON product(is_active);
CREATE INDEX IF NOT EXISTS idx_product_is_available ON product(is_available);
CREATE INDEX IF NOT EXISTS idx_product_is_featured ON product(is_featured);
CREATE INDEX IF NOT EXISTS idx_product_sku ON product(sku);
CREATE INDEX IF NOT EXISTS idx_product_slug ON product(slug);
CREATE INDEX IF NOT EXISTS idx_product_price ON product(price);
CREATE INDEX IF NOT EXISTS idx_product_average_rating ON product(average_rating);

-- Ajout de colonnes manquantes si elles n'existent pas
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product' AND column_name = 'subtitle') THEN
        ALTER TABLE product ADD COLUMN subtitle TEXT;
    END IF;

    -- Ajouter colonnes manquantes si elles n'existent pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product' AND column_name = 'baker_id') THEN
        ALTER TABLE product ADD COLUMN baker_id INTEGER REFERENCES baker(id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product' AND column_name = 'sku') THEN
        ALTER TABLE product ADD COLUMN sku VARCHAR(100) UNIQUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product' AND column_name = 'slug') THEN
        ALTER TABLE product ADD COLUMN slug VARCHAR(255) UNIQUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product' AND column_name = 'is_featured') THEN
        ALTER TABLE product ADD COLUMN is_featured BOOLEAN DEFAULT FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product' AND column_name = 'is_active') THEN
        ALTER TABLE product ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product' AND column_name = 'is_available') THEN
        ALTER TABLE product ADD COLUMN is_available BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product' AND column_name = 'stock_quantity') THEN
        ALTER TABLE product ADD COLUMN stock_quantity INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product' AND column_name = 'min_order_quantity') THEN
        ALTER TABLE product ADD COLUMN min_order_quantity INTEGER DEFAULT 1;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product' AND column_name = 'max_order_quantity') THEN
        ALTER TABLE product ADD COLUMN max_order_quantity INTEGER;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product' AND column_name = 'weight_grams') THEN
        ALTER TABLE product ADD COLUMN weight_grams INTEGER;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product' AND column_name = 'serving_size') THEN
        ALTER TABLE product ADD COLUMN serving_size VARCHAR(50);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product' AND column_name = 'ingredients') THEN
        ALTER TABLE product ADD COLUMN ingredients TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product' AND column_name = 'nutritional_info') THEN
        ALTER TABLE product ADD COLUMN nutritional_info JSONB;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product' AND column_name = 'tags') THEN
        ALTER TABLE product ADD COLUMN tags JSONB;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product' AND column_name = 'customization_options') THEN
        ALTER TABLE product ADD COLUMN customization_options JSONB;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product' AND column_name = 'delivery_info') THEN
        ALTER TABLE product ADD COLUMN delivery_info JSONB;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product' AND column_name = 'views_count') THEN
        ALTER TABLE product ADD COLUMN views_count INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product' AND column_name = 'favorites_count') THEN
        ALTER TABLE product ADD COLUMN favorites_count INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product' AND column_name = 'orders_count') THEN
        ALTER TABLE product ADD COLUMN orders_count INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product' AND column_name = 'reviews_count') THEN
        ALTER TABLE product ADD COLUMN reviews_count INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product' AND column_name = 'average_rating') THEN
        ALTER TABLE product ADD COLUMN average_rating DECIMAL(3,2) DEFAULT 0;
    END IF;
END $$;

-- =====================================================
-- TABLE: product_user (propriétaire du produit — pâtissier créateur)
-- =====================================================
-- Note historique : cette table était créée à la volée par le code applicatif
-- (product-service, POST /api/products/) au lieu d'un script versionné, ce qui
-- l'a fait disparaître silencieusement lors d'un reset de la base. Elle est
-- désormais définie ici et le code applicatif ne doit plus la créer lui-même.

CREATE TABLE IF NOT EXISTS product_user (
    product_id INTEGER PRIMARY KEY REFERENCES product(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES accounts_user(id) ON DELETE CASCADE,
    UNIQUE(product_id, user_id)
);

COMMENT ON TABLE product_user IS 'Relation produit -> utilisateur propriétaire (pâtissier créateur du produit)';

-- =====================================================
-- TABLE: product_image (images des produits)
-- =====================================================

-- Création de la table product_image si elle n'existe pas
CREATE TABLE IF NOT EXISTS product_image (
    id SERIAL PRIMARY KEY,
    productid INTEGER REFERENCES product(id) ON DELETE CASCADE,
    imageurl VARCHAR(255) NOT NULL,
    format VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    viewfrom VARCHAR(50) DEFAULT 'front',
    alt_text VARCHAR(255),
    is_primary BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    file_size_bytes BIGINT,
    width_pixels INTEGER,
    height_pixels INTEGER
);

COMMENT ON TABLE product_image IS 'Images associées aux produits';
COMMENT ON COLUMN product_image.productid IS 'Référence vers le produit';
COMMENT ON COLUMN product_image.is_primary IS 'Image principale du produit';
COMMENT ON COLUMN product_image.viewfrom IS 'Vue de l image (front, back, side, etc.)';

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_product_image_productid ON product_image(productid);
CREATE INDEX IF NOT EXISTS idx_product_image_is_primary ON product_image(is_primary);

-- Ajout de colonnes manquantes si elles n'existent pas
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product_image' AND column_name = 'viewfrom') THEN
        ALTER TABLE product_image ADD COLUMN viewfrom VARCHAR(50) DEFAULT 'front';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product_image' AND column_name = 'alt_text') THEN
        ALTER TABLE product_image ADD COLUMN alt_text VARCHAR(255);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product_image' AND column_name = 'is_primary') THEN
        ALTER TABLE product_image ADD COLUMN is_primary BOOLEAN DEFAULT FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product_image' AND column_name = 'sort_order') THEN
        ALTER TABLE product_image ADD COLUMN sort_order INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product_image' AND column_name = 'file_size_bytes') THEN
        ALTER TABLE product_image ADD COLUMN file_size_bytes BIGINT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product_image' AND column_name = 'width_pixels') THEN
        ALTER TABLE product_image ADD COLUMN width_pixels INTEGER;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product_image' AND column_name = 'height_pixels') THEN
        ALTER TABLE product_image ADD COLUMN height_pixels INTEGER;
    END IF;
END $$;

-- =====================================================
-- TABLE: product_variant (variantes de produits)
-- =====================================================

-- Création de la table product_variant si elle n'existe pas
CREATE TABLE IF NOT EXISTS product_variant (
    id SERIAL PRIMARY KEY,
    productid INTEGER REFERENCES product(id) ON DELETE CASCADE,
    variant_name VARCHAR(255) NOT NULL,
    ingredients TEXT,
    allergens TEXT,
    price DECIMAL(10,2),
    sku VARCHAR(100),
    stock_quantity INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,
    weight_grams INTEGER,
    preparation_time_hours INTEGER
);

COMMENT ON TABLE product_variant IS 'Variantes de produits (taille, saveur, etc.)';
COMMENT ON COLUMN product_variant.productid IS 'Référence vers le produit parent';
COMMENT ON COLUMN product_variant.variant_name IS 'Nom de la variante (ex: Chocolat, Vanille)';

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_product_variant_productid ON product_variant(productid);
CREATE INDEX IF NOT EXISTS idx_product_variant_is_active ON product_variant(is_active);

-- Ajout de colonnes manquantes si elles n'existent pas
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product_variant' AND column_name = 'price') THEN
        ALTER TABLE product_variant ADD COLUMN price DECIMAL(10,2);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product_variant' AND column_name = 'sku') THEN
        ALTER TABLE product_variant ADD COLUMN sku VARCHAR(100);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product_variant' AND column_name = 'stock_quantity') THEN
        ALTER TABLE product_variant ADD COLUMN stock_quantity INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product_variant' AND column_name = 'is_active') THEN
        ALTER TABLE product_variant ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product_variant' AND column_name = 'sort_order') THEN
        ALTER TABLE product_variant ADD COLUMN sort_order INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product_variant' AND column_name = 'weight_grams') THEN
        ALTER TABLE product_variant ADD COLUMN weight_grams INTEGER;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product_variant' AND column_name = 'preparation_time_hours') THEN
        ALTER TABLE product_variant ADD COLUMN preparation_time_hours INTEGER;
    END IF;
END $$;

-- =====================================================
-- TABLE: product_views (tracking des vues de produits)
-- =====================================================

CREATE TABLE IF NOT EXISTS product_views (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id INTEGER REFERENCES product(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES accounts_user(id) ON DELETE SET NULL,
    session_id UUID REFERENCES user_sessions(id) ON DELETE SET NULL,
    page_view_id UUID REFERENCES user_page_views(id) ON DELETE SET NULL,
    view_duration_seconds INTEGER DEFAULT 0,
    view_source VARCHAR(50), -- 'search', 'category', 'recommendation', 'direct', etc.
    referrer_url TEXT,
    metadata JSONB, -- Contexte de la vue
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE product_views IS 'Tracking des vues de produits avec contexte';
COMMENT ON COLUMN product_views.view_source IS 'Source de la vue (search, category, recommendation, direct)';

-- =====================================================
-- TABLE: baker_products (relation pâtissiers-produits)
-- =====================================================

CREATE TABLE IF NOT EXISTS baker_products (
    id SERIAL PRIMARY KEY,
    baker_id INTEGER REFERENCES baker(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES product(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(baker_id, product_id)
);

COMMENT ON TABLE baker_products IS 'Relation entre pâtissiers et produits (pour produits partagés)';

-- =====================================================
-- TABLE: baker_review (avis sur les pâtissiers)
-- =====================================================

CREATE TABLE IF NOT EXISTS baker_review (
    id SERIAL PRIMARY KEY,
    bakerid INTEGER REFERENCES baker(id) ON DELETE CASCADE,
    userid INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE,
    rating DECIMAL(2,1) NOT NULL CHECK (rating >= 0 AND rating <= 5),
    reviewtext TEXT,
    createdat TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(bakerid, userid) -- Un utilisateur ne peut donner qu'un avis par pâtissier
);

COMMENT ON TABLE baker_review IS 'Avis des utilisateurs sur les pâtissiers';
COMMENT ON COLUMN baker_review.rating IS 'Note de 0 à 5';
COMMENT ON COLUMN baker_review.reviewtext IS 'Texte de l avis';

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_baker_review_bakerid ON baker_review(bakerid);
CREATE INDEX IF NOT EXISTS idx_baker_review_userid ON baker_review(userid);
CREATE INDEX IF NOT EXISTS idx_baker_review_rating ON baker_review(rating);

-- =====================================================
-- TABLE: baker_comment (commentaires sur les pâtissiers)
-- =====================================================

CREATE TABLE IF NOT EXISTS baker_comment (
    id SERIAL PRIMARY KEY,
    bakerid INTEGER REFERENCES baker(id) ON DELETE CASCADE,
    userid INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE,
    commenttext TEXT NOT NULL,
    createdat TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE baker_comment IS 'Commentaires des utilisateurs sur les pâtissiers';
COMMENT ON COLUMN baker_comment.commenttext IS 'Texte du commentaire';

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_baker_comment_bakerid ON baker_comment(bakerid);
CREATE INDEX IF NOT EXISTS idx_baker_comment_userid ON baker_comment(userid);
CREATE INDEX IF NOT EXISTS idx_baker_comment_createdat ON baker_comment(createdat);

-- =====================================================
-- TABLE: product_reviews (avis sur les produits)
-- =====================================================

CREATE TABLE IF NOT EXISTS product_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id INTEGER REFERENCES product(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE,
    order_id INTEGER, -- FK vers orders sera ajoutée dans 10_indexes_and_constraints.sql
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(255),
    review_text TEXT NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    helpful_count INTEGER DEFAULT 0,
    images JSONB, -- URLs des images jointes
    metadata JSONB, -- Métadonnées supplémentaires
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(product_id, user_id) -- Un utilisateur ne peut donner qu'un avis par produit
);

COMMENT ON TABLE product_reviews IS 'Avis des utilisateurs sur les produits';
COMMENT ON COLUMN product_reviews.images IS 'URLs des images jointes à l avis';

-- =====================================================
-- TABLE: product_categories (catégories de produits)
-- =====================================================

CREATE TABLE IF NOT EXISTS product_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    parent_id UUID REFERENCES product_categories(id) ON DELETE SET NULL,
    image_url VARCHAR(500),
    icon VARCHAR(100), -- Nom de l'icône
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE product_categories IS 'Catégories de produits avec hiérarchie';
COMMENT ON COLUMN product_categories.parent_id IS 'Catégorie parente pour créer une hiérarchie';

-- =====================================================
-- TABLE: product_category_relations (relation produits-catégories)
-- =====================================================

CREATE TABLE IF NOT EXISTS product_category_relations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id INTEGER REFERENCES product(id) ON DELETE CASCADE,
    category_id UUID REFERENCES product_categories(id) ON DELETE CASCADE,
    is_primary BOOLEAN DEFAULT FALSE, -- Catégorie principale
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(product_id, category_id)
);

COMMENT ON TABLE product_category_relations IS 'Relation entre produits et catégories';
COMMENT ON COLUMN product_category_relations.is_primary IS 'Indique si c est la catégorie principale du produit';

-- =====================================================
-- TABLE: category (référentiel des catégories)
-- =====================================================

CREATE TABLE IF NOT EXISTS category (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    CONSTRAINT category_name_unique UNIQUE (name)
);

COMMENT ON TABLE category IS 'Référentiel des catégories de pâtisseries';
CREATE INDEX IF NOT EXISTS idx_category_name ON category(name);

-- =====================================================
-- TABLE: product_category (ancienne structure - fallback)
-- =====================================================

-- Table de fallback pour compatibilité avec l'ancienne structure
CREATE TABLE IF NOT EXISTS product_category (
    productid INTEGER REFERENCES product(id) ON DELETE CASCADE,
    categoryid INTEGER, -- Référence vers category (table définie ailleurs)
    PRIMARY KEY (productid, categoryid)
);

COMMENT ON TABLE product_category IS 'Ancienne structure de relation produits-catégories (fallback)';
COMMENT ON COLUMN product_category.productid IS 'Référence vers le produit';
COMMENT ON COLUMN product_category.categoryid IS 'Référence vers la catégorie (table category)';

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_product_category_productid ON product_category(productid);
CREATE INDEX IF NOT EXISTS idx_product_category_categoryid ON product_category(categoryid);

-- =====================================================
-- TABLE: allergen (allergènes de base)
-- =====================================================

CREATE TABLE IF NOT EXISTS allergen (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE allergen IS 'Table de base des allergènes';
COMMENT ON COLUMN allergen.name IS 'Nom unique de l allergène';

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_allergen_name ON allergen(name);

-- =====================================================
-- TABLE: product_allergen (relation produit-allergène)
-- =====================================================

CREATE TABLE IF NOT EXISTS product_allergen (
    id SERIAL PRIMARY KEY,
    productid INTEGER REFERENCES product(id) ON DELETE CASCADE,
    allergenid INTEGER REFERENCES allergen(id) ON DELETE CASCADE,
    isallergenic BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(productid, allergenid)
);

COMMENT ON TABLE product_allergen IS 'Relation entre produits et allergènes';
COMMENT ON COLUMN product_allergen.productid IS 'Référence vers le produit';
COMMENT ON COLUMN product_allergen.allergenid IS 'Référence vers l allergène';
COMMENT ON COLUMN product_allergen.isallergenic IS 'Indique si le produit contient cet allergène';

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_product_allergen_productid ON product_allergen(productid);
CREATE INDEX IF NOT EXISTS idx_product_allergen_allergenid ON product_allergen(allergenid);

-- =====================================================
-- TABLE: product_quantity_rule (règles de quantité)
-- =====================================================

CREATE TABLE IF NOT EXISTS product_quantity_rule (
    id SERIAL PRIMARY KEY,
    productid INTEGER REFERENCES product(id) ON DELETE CASCADE,
    ruletype VARCHAR(50) NOT NULL, -- 'min', 'max', 'lot', 'step', etc.
    minquantity INTEGER,
    maxquantity INTEGER,
    lotsize INTEGER, -- Taille du lot (ex: vendu par lots de 6)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE product_quantity_rule IS 'Règles de quantité pour les produits';
COMMENT ON COLUMN product_quantity_rule.productid IS 'Référence vers le produit';
COMMENT ON COLUMN product_quantity_rule.ruletype IS 'Type de règle (min, max, lot, step, etc.)';
COMMENT ON COLUMN product_quantity_rule.minquantity IS 'Quantité minimale autorisée';
COMMENT ON COLUMN product_quantity_rule.maxquantity IS 'Quantité maximale autorisée';
COMMENT ON COLUMN product_quantity_rule.lotsize IS 'Taille du lot (ex: vendu par lots de 6)';

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_product_quantity_rule_productid ON product_quantity_rule(productid);
CREATE INDEX IF NOT EXISTS idx_product_quantity_rule_ruletype ON product_quantity_rule(ruletype);

-- =====================================================
-- TABLE: product_history (historique des modifications)
-- =====================================================

CREATE TABLE IF NOT EXISTS product_history (
    id SERIAL PRIMARY KEY,
    productid INTEGER REFERENCES product(id) ON DELETE CASCADE,
    change_description TEXT NOT NULL,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    changed_by INTEGER REFERENCES accounts_user(id) ON DELETE SET NULL,
    metadata JSONB -- Métadonnées supplémentaires sur le changement
);

COMMENT ON TABLE product_history IS 'Historique des modifications de produits';
COMMENT ON COLUMN product_history.productid IS 'Référence vers le produit modifié';
COMMENT ON COLUMN product_history.change_description IS 'Description du changement effectué';
COMMENT ON COLUMN product_history.changed_by IS 'Utilisateur ayant effectué le changement';

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_product_history_productid ON product_history(productid);
CREATE INDEX IF NOT EXISTS idx_product_history_changed_at ON product_history(changed_at);
CREATE INDEX IF NOT EXISTS idx_product_history_changed_by ON product_history(changed_by);

-- =====================================================
-- TABLE: product_tags (tags de produits)
-- =====================================================

CREATE TABLE IF NOT EXISTS product_tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(100) NOT NULL UNIQUE,
    color VARCHAR(7), -- Code couleur hexadécimal
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE product_tags IS 'Tags pour catégoriser et filtrer les produits';

-- =====================================================
-- TABLE: product_tag_relations (relation produits-tags)
-- =====================================================

CREATE TABLE IF NOT EXISTS product_tag_relations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id INTEGER REFERENCES product(id) ON DELETE CASCADE,
    tag_id UUID REFERENCES product_tags(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(product_id, tag_id)
);

COMMENT ON TABLE product_tag_relations IS 'Relation entre produits et tags';

-- =====================================================
-- TABLE: product_analytics_daily (analytics quotidiennes des produits)
-- =====================================================

CREATE TABLE IF NOT EXISTS product_analytics_daily (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id INTEGER REFERENCES product(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    -- Métriques de visibilité
    views_count INTEGER DEFAULT 0,
    unique_views_count INTEGER DEFAULT 0,
    -- Métriques d'engagement
    favorites_additions INTEGER DEFAULT 0,
    cart_additions INTEGER DEFAULT 0,
    -- Métriques commerciales
    orders_count INTEGER DEFAULT 0,
    revenue DECIMAL(10,2) DEFAULT 0,
    -- Métriques de satisfaction
    reviews_count INTEGER DEFAULT 0,
    average_rating DECIMAL(3,2) DEFAULT 0,
    -- Métadonnées
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(product_id, date)
);

COMMENT ON TABLE product_analytics_daily IS 'Analytics quotidiennes agrégées par produit';

-- =====================================================
-- TABLE: product_recommendations (recommandations de produits)
-- =====================================================

CREATE TABLE IF NOT EXISTS product_recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id INTEGER REFERENCES product(id) ON DELETE CASCADE,
    recommended_product_id INTEGER REFERENCES product(id) ON DELETE CASCADE,
    recommendation_type VARCHAR(50) NOT NULL, -- 'similar', 'complementary', 'trending', 'personalized'
    score DECIMAL(5,4) DEFAULT 0, -- Score de recommandation (0-1)
    reason TEXT, -- Raison de la recommandation
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(product_id, recommended_product_id, recommendation_type)
);

COMMENT ON TABLE product_recommendations IS 'Recommandations de produits basées sur différents algorithmes';
COMMENT ON COLUMN product_recommendations.recommendation_type IS 'Type de recommandation (similar, complementary, trending, personalized)';


-- Création table category (manquante dans 03_products.sql)
CREATE TABLE IF NOT EXISTS category (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

-- Seed catégories pâtisserie
INSERT INTO category (name) VALUES
  ('Gâteaux'), ('Tartes'), ('Macarons'), ('Viennoiseries'),
  ('Choux'), ('Biscuits'), ('Chocolats'),
  ('Cupcakes'), ('Cheesecakes')
ON CONFLICT (name) DO NOTHING;

-- Seed allergènes (14 allergènes EU obligatoires)
INSERT INTO allergen (name) VALUES
  ('Gluten'), ('Crustacés'), ('Œufs'), ('Poisson'),
  ('Arachides'), ('Soja'), ('Lait'), ('Fruits à coque'),
  ('Céleri'), ('Moutarde'), ('Graines de sésame')
ON CONFLICT (name) DO NOTHING;

-- =====================================================
-- INDEX pour les performances
-- =====================================================

-- Index pour product
CREATE INDEX IF NOT EXISTS idx_product_baker_id ON product(baker_id);
CREATE INDEX IF NOT EXISTS idx_product_is_active ON product(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_product_is_featured ON product(is_featured) WHERE is_featured = TRUE;
CREATE INDEX IF NOT EXISTS idx_product_price ON product(price);
CREATE INDEX IF NOT EXISTS idx_product_average_rating ON product(average_rating);
CREATE INDEX IF NOT EXISTS idx_product_created_at ON product(created_at);

-- Index pour product_image
CREATE INDEX IF NOT EXISTS idx_product_image_product_id ON product_image(productid);
CREATE INDEX IF NOT EXISTS idx_product_image_primary ON product_image(productid, is_primary) WHERE is_primary = TRUE;
CREATE INDEX IF NOT EXISTS idx_product_image_viewfrom ON product_image(viewfrom);

-- Index pour product_variant
CREATE INDEX IF NOT EXISTS idx_product_variant_product_id ON product_variant(productid);
CREATE INDEX IF NOT EXISTS idx_product_variant_is_active ON product_variant(is_active) WHERE is_active = TRUE;

-- Index pour product_views
CREATE INDEX IF NOT EXISTS idx_product_views_product_id ON product_views(product_id);
CREATE INDEX IF NOT EXISTS idx_product_views_user_id ON product_views(user_id);
CREATE INDEX IF NOT EXISTS idx_product_views_session_id ON product_views(session_id);
CREATE INDEX IF NOT EXISTS idx_product_views_created_at ON product_views(created_at);

-- Index pour product_reviews
CREATE INDEX IF NOT EXISTS idx_product_reviews_product_id ON product_reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_product_reviews_user_id ON product_reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_product_reviews_rating ON product_reviews(rating);
CREATE INDEX IF NOT EXISTS idx_product_reviews_created_at ON product_reviews(created_at);

-- Index pour product_categories
CREATE INDEX IF NOT EXISTS idx_product_categories_parent_id ON product_categories(parent_id);
CREATE INDEX IF NOT EXISTS idx_product_categories_is_active ON product_categories(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_product_categories_slug ON product_categories(slug);

-- Index pour product_category_relations
CREATE INDEX IF NOT EXISTS idx_product_category_relations_product_id ON product_category_relations(product_id);
CREATE INDEX IF NOT EXISTS idx_product_category_relations_category_id ON product_category_relations(category_id);
CREATE INDEX IF NOT EXISTS idx_product_category_relations_primary ON product_category_relations(product_id, is_primary) WHERE is_primary = TRUE;

-- Index pour product_allergen
CREATE INDEX IF NOT EXISTS idx_product_allergen_productid ON product_allergen(productid);
CREATE INDEX IF NOT EXISTS idx_product_allergen_allergenid ON product_allergen(allergenid);

-- Index pour product_quantity_rule
CREATE INDEX IF NOT EXISTS idx_product_quantity_rule_productid ON product_quantity_rule(productid);
CREATE INDEX IF NOT EXISTS idx_product_quantity_rule_ruletype ON product_quantity_rule(ruletype);

-- Index pour product_history
CREATE INDEX IF NOT EXISTS idx_product_history_productid ON product_history(productid);
CREATE INDEX IF NOT EXISTS idx_product_history_changed_at ON product_history(changed_at);
CREATE INDEX IF NOT EXISTS idx_product_history_changed_by ON product_history(changed_by);

-- Index pour product_tags
CREATE INDEX IF NOT EXISTS idx_product_tags_is_active ON product_tags(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_product_tags_usage_count ON product_tags(usage_count);

-- Index pour product_tag_relations
CREATE INDEX IF NOT EXISTS idx_product_tag_relations_product_id ON product_tag_relations(product_id);
CREATE INDEX IF NOT EXISTS idx_product_tag_relations_tag_id ON product_tag_relations(tag_id);

-- Index pour product_analytics_daily
CREATE INDEX IF NOT EXISTS idx_product_analytics_daily_product_id ON product_analytics_daily(product_id);
CREATE INDEX IF NOT EXISTS idx_product_analytics_daily_date ON product_analytics_daily(date);

-- Index pour product_recommendations
CREATE INDEX IF NOT EXISTS idx_product_recommendations_product_id ON product_recommendations(product_id);
CREATE INDEX IF NOT EXISTS idx_product_recommendations_type ON product_recommendations(recommendation_type);
CREATE INDEX IF NOT EXISTS idx_product_recommendations_score ON product_recommendations(score);

-- =====================================================
-- TRIGGERS pour updated_at et compteurs
-- =====================================================

-- Trigger pour product_reviews
CREATE OR REPLACE FUNCTION update_product_reviews_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_product_reviews_updated_at ON product_reviews;
CREATE TRIGGER trigger_product_reviews_updated_at
    BEFORE UPDATE ON product_reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_product_reviews_updated_at();

-- Trigger pour product_categories
CREATE OR REPLACE FUNCTION update_product_categories_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_product_categories_updated_at ON product_categories;
CREATE TRIGGER trigger_product_categories_updated_at
    BEFORE UPDATE ON product_categories
    FOR EACH ROW
    EXECUTE FUNCTION update_product_categories_updated_at();

-- Trigger pour product_quantity_rule
CREATE OR REPLACE FUNCTION update_product_quantity_rule_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_product_quantity_rule_updated_at ON product_quantity_rule;
CREATE TRIGGER trigger_product_quantity_rule_updated_at
    BEFORE UPDATE ON product_quantity_rule
    FOR EACH ROW
    EXECUTE FUNCTION update_product_quantity_rule_updated_at();

-- Trigger pour product_analytics_daily
CREATE OR REPLACE FUNCTION update_product_analytics_daily_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_product_analytics_daily_updated_at ON product_analytics_daily;
CREATE TRIGGER trigger_product_analytics_daily_updated_at
    BEFORE UPDATE ON product_analytics_daily
    FOR EACH ROW
    EXECUTE FUNCTION update_product_analytics_daily_updated_at();

-- Trigger pour mettre à jour les compteurs de produits
CREATE OR REPLACE FUNCTION update_product_counters()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_TABLE_NAME = 'product_reviews' THEN
        IF TG_OP = 'INSERT' THEN
            UPDATE product SET 
                reviews_count = reviews_count + 1,
                average_rating = (
                    SELECT AVG(rating)::DECIMAL(3,2) 
                    FROM product_reviews 
                    WHERE product_id = NEW.product_id
                )
            WHERE id = NEW.product_id;
        ELSIF TG_OP = 'DELETE' THEN
            UPDATE product SET 
                reviews_count = reviews_count - 1,
                average_rating = (
                    SELECT COALESCE(AVG(rating)::DECIMAL(3,2), 0) 
                    FROM product_reviews 
                    WHERE product_id = OLD.product_id
                )
            WHERE id = OLD.product_id;
        END IF;
    ELSIF TG_TABLE_NAME = 'product_views' THEN
        IF TG_OP = 'INSERT' THEN
            UPDATE product SET views_count = views_count + 1 WHERE id = NEW.product_id;
        END IF;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_product_reviews_counters ON product_reviews;
CREATE TRIGGER trigger_product_reviews_counters
    AFTER INSERT OR DELETE ON product_reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_product_counters();

DROP TRIGGER IF EXISTS trigger_product_views_counters ON product_views;
CREATE TRIGGER trigger_product_views_counters
    AFTER INSERT ON product_views
    FOR EACH ROW
    EXECUTE FUNCTION update_product_counters();

-- =====================================================
-- VUES utiles
-- =====================================================

-- Vue pour les produits avec informations complètes
CREATE OR REPLACE VIEW product_complete_info AS
SELECT 
    p.*,
    b.userid as baker_user_id,
    au.first_name as baker_first_name,
    au.last_name as baker_last_name,
    au.email as baker_email,
    -- Images principales
    pi.imageurl as primary_image_url,
    pi.format as primary_image_format,
    -- Catégories principales
    STRING_AGG(DISTINCT pc.name, ', ') FILTER (WHERE pcr.is_primary = TRUE) as primary_categories,
    -- Tags
    STRING_AGG(DISTINCT pt.name, ', ') as product_tags,
    -- Statistiques
    COUNT(DISTINCT pv.id) as total_views,
    COUNT(DISTINCT pr.id) as total_reviews,
    COALESCE(AVG(pr.rating), 0) as calculated_average_rating
FROM product p
LEFT JOIN baker b ON p.baker_id = b.id
LEFT JOIN accounts_user au ON b.userid = au.id
LEFT JOIN product_image pi ON p.id = pi.productid AND pi.is_primary = TRUE
LEFT JOIN product_category_relations pcr ON p.id = pcr.product_id
LEFT JOIN product_categories pc ON pcr.category_id = pc.id
LEFT JOIN product_tag_relations ptr ON p.id = ptr.product_id
LEFT JOIN product_tags pt ON ptr.tag_id = pt.id
LEFT JOIN product_views pv ON p.id = pv.product_id
LEFT JOIN product_reviews pr ON p.id = pr.product_id
WHERE p.is_active = TRUE
GROUP BY p.id, b.userid, au.first_name, au.last_name, au.email, pi.imageurl, pi.format;

-- Vue pour les produits populaires
CREATE OR REPLACE VIEW popular_products AS
SELECT 
    pci.*,
    ROW_NUMBER() OVER (ORDER BY pci.total_views DESC, pci.calculated_average_rating DESC) as popularity_rank
FROM product_complete_info pci
WHERE pci.is_active = TRUE 
AND pci.is_available = TRUE
ORDER BY pci.total_views DESC, pci.calculated_average_rating DESC;

-- Vue pour les produits recommandés
CREATE OR REPLACE VIEW recommended_products AS
SELECT 
    pci.*,
    pr.recommendation_type,
    pr.score as recommendation_score,
    pr.reason as recommendation_reason
FROM product_complete_info pci
JOIN product_recommendations pr ON pci.id = pr.product_id
WHERE pci.is_active = TRUE 
AND pci.is_available = TRUE
ORDER BY pr.score DESC;

COMMENT ON VIEW product_complete_info IS 'Informations complètes des produits avec agrégations';
COMMENT ON VIEW popular_products IS 'Produits populaires triés par vues et notes';
COMMENT ON VIEW recommended_products IS 'Produits recommandés avec scores et raisons';
