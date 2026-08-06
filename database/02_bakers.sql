-- =====================================================
-- 02_bakers.sql
-- Tables pâtissiers, spécialités, certifications et analytics
-- =====================================================

-- Extension pour UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- TABLE: baker (table principale pâtissiers)
-- =====================================================

-- Création de la table baker si elle n'existe pas
CREATE TABLE IF NOT EXISTS baker (
    id SERIAL PRIMARY KEY,
    userid INTEGER UNIQUE REFERENCES accounts_user(id) ON DELETE SET NULL,
    description TEXT,
    experience TEXT,
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    location VARCHAR(255),
    business_name VARCHAR(255),
    profile_image_url VARCHAR(500),
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    accepts_orders BOOLEAN DEFAULT TRUE,
    phone_number VARCHAR(20),
    email VARCHAR(255),
    years_experience INTEGER DEFAULT 0,
    delivery_radius INTEGER DEFAULT 10, -- en km
    min_order_amount DECIMAL(10,2) DEFAULT 0,
    delivery_fee DECIMAL(10,2) DEFAULT 0,
    preparation_time_hours INTEGER DEFAULT 24,
    commission_rate DECIMAL(5,2) DEFAULT 10.00, -- % commission
    social_links JSONB, -- {facebook, instagram, twitter, etc.}
    bank_details JSONB, -- Détails bancaires pour paiements
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE baker IS 'Table principale des pâtissiers';
COMMENT ON COLUMN baker.userid IS 'Référence vers le compte utilisateur associé (unique)';
COMMENT ON COLUMN baker.average_rating IS 'Note moyenne calculée à partir des avis';
COMMENT ON COLUMN baker.delivery_radius IS 'Rayon de livraison en kilomètres';
COMMENT ON COLUMN baker.commission_rate IS 'Taux de commission en pourcentage';
COMMENT ON COLUMN baker.social_links IS 'Liens réseaux sociaux (JSON)';
COMMENT ON COLUMN baker.bank_details IS 'Détails bancaires pour paiements (JSON)';

-- Contrainte d'unicité sur userid pour éviter qu'un utilisateur ait plusieurs profils pâtissier
-- NOTE: Ajouté UNIQUE directement dans la définition de colonne ci-dessus
-- Cette contrainte assure qu'un utilisateur ne peut avoir qu'un seul profil pâtissier

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_baker_userid ON baker(userid);
CREATE INDEX IF NOT EXISTS idx_baker_is_active ON baker(is_active);
CREATE INDEX IF NOT EXISTS idx_baker_is_verified ON baker(is_verified);
CREATE INDEX IF NOT EXISTS idx_baker_accepts_orders ON baker(accepts_orders);
CREATE INDEX IF NOT EXISTS idx_baker_location ON baker(location);

-- Ajout de colonnes manquantes si elles n'existent pas
DO $$ 
BEGIN
    -- Ajouter colonnes manquantes si elles n'existent pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'baker' AND column_name = 'business_name') THEN
        ALTER TABLE baker ADD COLUMN business_name VARCHAR(255);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'baker' AND column_name = 'profile_image_url') THEN
        ALTER TABLE baker ADD COLUMN profile_image_url VARCHAR(500);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'baker' AND column_name = 'is_verified') THEN
        ALTER TABLE baker ADD COLUMN is_verified BOOLEAN DEFAULT FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'baker' AND column_name = 'phone_number') THEN
        ALTER TABLE baker ADD COLUMN phone_number VARCHAR(20);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'baker' AND column_name = 'email') THEN
        ALTER TABLE baker ADD COLUMN email VARCHAR(255);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'baker' AND column_name = 'years_experience') THEN
        ALTER TABLE baker ADD COLUMN years_experience INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'baker' AND column_name = 'is_active') THEN
        ALTER TABLE baker ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'baker' AND column_name = 'accepts_orders') THEN
        ALTER TABLE baker ADD COLUMN accepts_orders BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'baker' AND column_name = 'delivery_radius') THEN
        ALTER TABLE baker ADD COLUMN delivery_radius INTEGER DEFAULT 10; -- en km
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'baker' AND column_name = 'min_order_amount') THEN
        ALTER TABLE baker ADD COLUMN min_order_amount DECIMAL(10,2) DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'baker' AND column_name = 'delivery_fee') THEN
        ALTER TABLE baker ADD COLUMN delivery_fee DECIMAL(10,2) DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'baker' AND column_name = 'preparation_time_hours') THEN
        ALTER TABLE baker ADD COLUMN preparation_time_hours INTEGER DEFAULT 24;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'baker' AND column_name = 'social_links') THEN
        ALTER TABLE baker ADD COLUMN social_links JSONB;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'baker' AND column_name = 'bank_details') THEN
        ALTER TABLE baker ADD COLUMN bank_details JSONB;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'baker' AND column_name = 'commission_rate') THEN
        ALTER TABLE baker ADD COLUMN commission_rate DECIMAL(5,2) DEFAULT 10.00; -- % commission
    END IF;
END $$;

-- =====================================================
-- TABLE: baker_specialties (spécialités des pâtissiers)
-- =====================================================

CREATE TABLE IF NOT EXISTS baker_specialties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baker_id INTEGER REFERENCES baker(id) ON DELETE CASCADE,
    specialty_name VARCHAR(100) NOT NULL,
    specialty_description TEXT,
    is_primary BOOLEAN DEFAULT FALSE, -- Spécialité principale
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(baker_id, specialty_name)
);

COMMENT ON TABLE baker_specialties IS 'Spécialités des pâtissiers (gâteaux, macarons, etc.)';
COMMENT ON COLUMN baker_specialties.is_primary IS 'Indique si c est la spécialité principale du pâtissier';

-- =====================================================
-- TABLE: baker_languages (langues parlées par les pâtissiers)
-- =====================================================

CREATE TABLE IF NOT EXISTS baker_languages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baker_id INTEGER REFERENCES baker(id) ON DELETE CASCADE,
    language_code VARCHAR(10) NOT NULL, -- 'fr', 'en', 'es', etc.
    language_name VARCHAR(50) NOT NULL,
    proficiency_level VARCHAR(20) DEFAULT 'native', -- 'native', 'fluent', 'intermediate', 'basic'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(baker_id, language_code)
);

COMMENT ON TABLE baker_languages IS 'Langues parlées par les pâtissiers';
COMMENT ON COLUMN baker_languages.proficiency_level IS 'Niveau de maîtrise de la langue';

-- =====================================================
-- TABLE: baker_certifications (certifications des pâtissiers)
-- =====================================================

CREATE TABLE IF NOT EXISTS baker_certifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baker_id INTEGER REFERENCES baker(id) ON DELETE CASCADE,
    certification_name VARCHAR(255) NOT NULL,
    certification_type VARCHAR(100), -- 'diploma', 'certificate', 'award', 'training'
    issuing_authority VARCHAR(255),
    issue_date DATE,
    expiry_date DATE,
    certificate_url VARCHAR(500),
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE baker_certifications IS 'Certifications et diplômes des pâtissiers';
COMMENT ON COLUMN baker_certifications.certification_type IS 'Type de certification (diploma, certificate, award, training)';

-- =====================================================
-- TABLE: baker_working_hours (horaires de travail)
-- =====================================================

CREATE TABLE IF NOT EXISTS baker_working_hours (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baker_id INTEGER REFERENCES baker(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL, -- 0=dimanche, 1=lundi, ..., 6=samedi
    day_name VARCHAR(20) NOT NULL, -- 'Lundi', 'Mardi', etc.
    is_open BOOLEAN DEFAULT TRUE,
    open_time TIME,
    close_time TIME,
    is_break_day BOOLEAN DEFAULT FALSE, -- Jour de repos
    notes TEXT, -- Notes spéciales pour ce jour
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(baker_id, day_of_week)
);

COMMENT ON TABLE baker_working_hours IS 'Horaires de travail des pâtissiers par jour de la semaine';
COMMENT ON COLUMN baker_working_hours.day_of_week IS 'Jour de la semaine (0=dimanche, 1=lundi, ..., 6=samedi)';

-- =====================================================
-- TABLE: baker_products (relation pâtissier-produits)
-- =====================================================
-- NOTE: La contrainte FK vers product sera ajoutée dans 10_indexes_and_constraints.sql
-- après la création de la table product dans 03_products.sql

CREATE TABLE IF NOT EXISTS baker_products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baker_id INTEGER REFERENCES baker(id) ON DELETE CASCADE,
    product_id INTEGER, -- FK vers product sera ajoutée dans 10_indexes_and_constraints.sql
    is_featured BOOLEAN DEFAULT FALSE, -- Produit mis en avant
    custom_price DECIMAL(10,2), -- Prix personnalisé par pâtissier
    availability_status VARCHAR(20) DEFAULT 'available', -- 'available', 'unavailable', 'limited'
    preparation_time_hours INTEGER, -- Temps de préparation spécifique
    notes TEXT, -- Notes spécifiques du pâtissier
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(baker_id, product_id)
);

COMMENT ON TABLE baker_products IS 'Relation entre pâtissiers et produits avec informations spécifiques';
COMMENT ON COLUMN baker_products.availability_status IS 'Statut de disponibilité du produit chez ce pâtissier';

-- =====================================================
-- TABLE: baker_analytics_daily (analytics quotidiennes des pâtissiers)
-- =====================================================

CREATE TABLE IF NOT EXISTS baker_analytics_daily (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baker_id INTEGER REFERENCES baker(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    -- Métriques de visibilité
    profile_views INTEGER DEFAULT 0,
    product_views INTEGER DEFAULT 0,
    search_appearances INTEGER DEFAULT 0,
    -- Métriques d'engagement
    messages_received INTEGER DEFAULT 0,
    reviews_received INTEGER DEFAULT 0,
    favorites_additions INTEGER DEFAULT 0,
    -- Métriques commerciales
    orders_received INTEGER DEFAULT 0,
    total_revenue DECIMAL(10,2) DEFAULT 0,
    average_order_value DECIMAL(10,2) DEFAULT 0,
    -- Métriques de performance
    response_time_minutes DECIMAL(8,2) DEFAULT 0, -- Temps de réponse moyen aux messages
    order_completion_rate DECIMAL(5,2) DEFAULT 0, -- % de commandes complétées
    customer_satisfaction DECIMAL(3,2) DEFAULT 0, -- Note moyenne des avis
    -- Métadonnées
    metadata JSONB, -- Données supplémentaires
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(baker_id, date)
);

COMMENT ON TABLE baker_analytics_daily IS 'Analytics quotidiennes agrégées par pâtissier';
COMMENT ON COLUMN baker_analytics_daily.order_completion_rate IS 'Pourcentage de commandes complétées avec succès';
COMMENT ON COLUMN baker_analytics_daily.customer_satisfaction IS 'Note moyenne des avis clients';

-- =====================================================
-- TABLE: baker_reviews (amélioration de la table existante)
-- =====================================================
-- NOTE: Cette table sera créée dans review-service, on ajoute les colonnes seulement si elle existe

-- Ajout de colonnes manquantes si la table existe
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'baker_review') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'baker_review' AND column_name = 'title') THEN
            ALTER TABLE baker_review ADD COLUMN title VARCHAR(255);
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'baker_review' AND column_name = 'is_verified') THEN
            ALTER TABLE baker_review ADD COLUMN is_verified BOOLEAN DEFAULT FALSE;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'baker_review' AND column_name = 'helpful_count') THEN
            ALTER TABLE baker_review ADD COLUMN helpful_count INTEGER DEFAULT 0;
        END IF;
        
        -- La FK vers orders sera ajoutée dans 10_indexes_and_constraints.sql après création de orders
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'baker_review' AND column_name = 'order_id') THEN
            ALTER TABLE baker_review ADD COLUMN order_id INTEGER;
        END IF;
    END IF;
END $$;

-- =====================================================
-- TABLE: baker_comment (amélioration de la table existante)
-- =====================================================
-- NOTE: Cette table sera créée dans review-service, on ajoute les colonnes seulement si elle existe

-- Ajout de colonnes manquantes si la table existe
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'baker_comment') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'baker_comment' AND column_name = 'is_public') THEN
            ALTER TABLE baker_comment ADD COLUMN is_public BOOLEAN DEFAULT TRUE;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'baker_comment' AND column_name = 'parent_comment_id') THEN
            ALTER TABLE baker_comment ADD COLUMN parent_comment_id INTEGER REFERENCES baker_comment(id);
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'baker_comment' AND column_name = 'likes_count') THEN
            ALTER TABLE baker_comment ADD COLUMN likes_count INTEGER DEFAULT 0;
        END IF;
    END IF;
END $$;

-- =====================================================
-- TABLE: baker_followers (suivi des pâtissiers)
-- =====================================================

CREATE TABLE IF NOT EXISTS baker_followers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baker_id INTEGER REFERENCES baker(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE,
    notification_preferences JSONB, -- Préférences de notification
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(baker_id, user_id)
);

COMMENT ON TABLE baker_followers IS 'Utilisateurs qui suivent des pâtissiers';
COMMENT ON COLUMN baker_followers.notification_preferences IS 'Préférences de notification (new_products, promotions, etc.)';

-- =====================================================
-- TABLE: baker_availability (disponibilité des pâtissiers)
-- =====================================================

CREATE TABLE IF NOT EXISTS baker_availability (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baker_id INTEGER REFERENCES baker(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    max_orders INTEGER, -- Nombre maximum de commandes pour ce jour
    current_orders INTEGER DEFAULT 0, -- Nombre actuel de commandes
    notes TEXT, -- Notes spéciales pour ce jour
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(baker_id, date)
);

COMMENT ON TABLE baker_availability IS 'Disponibilité des pâtissiers par date';
COMMENT ON COLUMN baker_availability.max_orders IS 'Nombre maximum de commandes acceptées pour ce jour';

-- =====================================================
-- INDEX pour les performances
-- =====================================================

-- Index pour baker_specialties
CREATE INDEX IF NOT EXISTS idx_baker_specialties_baker_id ON baker_specialties(baker_id);
CREATE INDEX IF NOT EXISTS idx_baker_specialties_specialty_name ON baker_specialties(specialty_name);
CREATE INDEX IF NOT EXISTS idx_baker_specialties_primary ON baker_specialties(baker_id, is_primary) WHERE is_primary = TRUE;

-- Index pour baker_languages
CREATE INDEX IF NOT EXISTS idx_baker_languages_baker_id ON baker_languages(baker_id);
CREATE INDEX IF NOT EXISTS idx_baker_languages_language_code ON baker_languages(language_code);

-- Index pour baker_certifications
CREATE INDEX IF NOT EXISTS idx_baker_certifications_baker_id ON baker_certifications(baker_id);
CREATE INDEX IF NOT EXISTS idx_baker_certifications_type ON baker_certifications(certification_type);

-- Index pour baker_working_hours
CREATE INDEX IF NOT EXISTS idx_baker_working_hours_baker_id ON baker_working_hours(baker_id);
CREATE INDEX IF NOT EXISTS idx_baker_working_hours_day ON baker_working_hours(day_of_week);

-- Index pour baker_products
CREATE INDEX IF NOT EXISTS idx_baker_products_baker_id ON baker_products(baker_id);
CREATE INDEX IF NOT EXISTS idx_baker_products_product_id ON baker_products(product_id);
CREATE INDEX IF NOT EXISTS idx_baker_products_featured ON baker_products(baker_id, is_featured) WHERE is_featured = TRUE;

-- Index pour baker_analytics_daily
CREATE INDEX IF NOT EXISTS idx_baker_analytics_daily_baker_id ON baker_analytics_daily(baker_id);
CREATE INDEX IF NOT EXISTS idx_baker_analytics_daily_date ON baker_analytics_daily(date);

-- Index pour baker_followers
CREATE INDEX IF NOT EXISTS idx_baker_followers_baker_id ON baker_followers(baker_id);
CREATE INDEX IF NOT EXISTS idx_baker_followers_user_id ON baker_followers(user_id);

-- Index pour baker_availability
CREATE INDEX IF NOT EXISTS idx_baker_availability_baker_id ON baker_availability(baker_id);
CREATE INDEX IF NOT EXISTS idx_baker_availability_date ON baker_availability(date);
CREATE INDEX IF NOT EXISTS idx_baker_availability_available ON baker_availability(baker_id, is_available, date) WHERE is_available = TRUE;

-- =====================================================
-- TRIGGERS pour updated_at
-- =====================================================

-- Trigger pour baker_products
CREATE OR REPLACE FUNCTION update_baker_products_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_baker_products_updated_at ON baker_products;
CREATE TRIGGER trigger_baker_products_updated_at
    BEFORE UPDATE ON baker_products
    FOR EACH ROW
    EXECUTE FUNCTION update_baker_products_updated_at();

-- Trigger pour baker_analytics_daily
CREATE OR REPLACE FUNCTION update_baker_analytics_daily_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_baker_analytics_daily_updated_at ON baker_analytics_daily;
CREATE TRIGGER trigger_baker_analytics_daily_updated_at
    BEFORE UPDATE ON baker_analytics_daily
    FOR EACH ROW
    EXECUTE FUNCTION update_baker_analytics_daily_updated_at();

-- Trigger pour baker_availability
CREATE OR REPLACE FUNCTION update_baker_availability_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_baker_availability_updated_at ON baker_availability;
CREATE TRIGGER trigger_baker_availability_updated_at
    BEFORE UPDATE ON baker_availability
    FOR EACH ROW
    EXECUTE FUNCTION update_baker_availability_updated_at();

-- =====================================================
-- TABLE: baker_location
-- Coordonnées GPS des pâtissiers (séparées de baker.location)
-- baker.location reste le champ texte d'adresse humaine.
-- =====================================================

CREATE TABLE IF NOT EXISTS baker_location (
    baker_id      INTEGER PRIMARY KEY REFERENCES baker(id) ON DELETE CASCADE,
    latitude      DECIMAL(10, 7) NOT NULL,
    longitude     DECIMAL(10, 7) NOT NULL,
    address_label VARCHAR(255),          -- libellé humain, ex. "Paris 75001, France"
    created_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE  baker_location               IS 'Coordonnées GPS des pâtissiers (séparées de baker.location qui reste textuel)';
COMMENT ON COLUMN baker_location.baker_id      IS 'Référence vers le pâtissier (relation 1-pour-1)';
COMMENT ON COLUMN baker_location.latitude      IS 'Latitude WGS-84';
COMMENT ON COLUMN baker_location.longitude     IS 'Longitude WGS-84';
COMMENT ON COLUMN baker_location.address_label IS 'Libellé de l adresse pour affichage (optionnel)';

CREATE INDEX IF NOT EXISTS idx_baker_location_coords
    ON baker_location (latitude, longitude);

-- Trigger : mise à jour automatique de updated_at
CREATE OR REPLACE FUNCTION update_baker_location_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_baker_location_updated_at ON baker_location;
CREATE TRIGGER trigger_baker_location_updated_at
    BEFORE UPDATE ON baker_location
    FOR EACH ROW
    EXECUTE FUNCTION update_baker_location_updated_at();

-- Ajout de colonnes manquantes (idempotent)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'baker_location' AND column_name = 'address_label'
    ) THEN
        ALTER TABLE baker_location ADD COLUMN address_label VARCHAR(255);
    END IF;
END $$;

-- =====================================================
-- VUES utiles
-- =====================================================
-- NOTE: Ces vues seront créées dans 09_analytics_views.sql après la création
-- de toutes les tables nécessaires (product, orders, baker_review, etc.)
