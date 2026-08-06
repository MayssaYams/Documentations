-- =====================================================
-- 01_users_and_auth.sql
-- Tables utilisateurs, authentification et tracking
-- =====================================================

-- Extension pour UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- TABLE: accounts_user (table principale utilisateurs)
-- =====================================================

-- Création de la table accounts_user si elle n'existe pas
CREATE TABLE IF NOT EXISTS accounts_user (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    first_name VARCHAR(30),
    last_name VARCHAR(30),
    is_active BOOLEAN DEFAULT TRUE,
    is_staff BOOLEAN DEFAULT FALSE,
    is_superuser BOOLEAN,
    phone_number VARCHAR(20),
    address_complement VARCHAR(255),
    city VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    region VARCHAR(100),
    street VARCHAR(255),
    street_number VARCHAR(20),
    date_joined TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    date_of_birth DATE,
    last_login TIMESTAMP WITH TIME ZONE,
    group_id INTEGER, -- FK vers auth_group (créée par Django)
    location TEXT -- PostGIS geometry si nécessaire
);

COMMENT ON TABLE accounts_user IS 'Table principale des utilisateurs du système';
COMMENT ON COLUMN accounts_user.email IS 'Email unique de l utilisateur (identifiant principal)';
COMMENT ON COLUMN accounts_user.is_active IS 'Indique si le compte est actif';
COMMENT ON COLUMN accounts_user.is_staff IS 'Indique si l utilisateur a accès à l interface admin';
COMMENT ON COLUMN accounts_user.is_superuser IS 'Indique si l utilisateur est superutilisateur';
COMMENT ON COLUMN accounts_user.location IS 'Localisation géographique (PostGIS geometry)';
COMMENT ON COLUMN accounts_user.group_id IS 'Référence vers le groupe d utilisateur (FK vers auth_group)';

-- =====================================================
-- TABLE: auth_group (groupes d'utilisateurs)
-- =====================================================

-- Vérifier si la table existe déjà avant de la créer
DO $$ 
BEGIN
    -- Création de la table auth_group si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'auth_group'
    ) THEN
        CREATE TABLE auth_group (
            id SERIAL PRIMARY KEY,
            name VARCHAR(150) UNIQUE NOT NULL
        );
        
        COMMENT ON TABLE auth_group IS 'Groupes d utilisateurs pour les permissions';
        COMMENT ON COLUMN auth_group.name IS 'Nom unique du groupe';
        
        RAISE NOTICE 'Table auth_group créée avec succès';
    ELSE
        RAISE NOTICE 'Table auth_group existe déjà';
    END IF;
END $$;

-- Insertion des groupes de base (avec gestion des conflits)
INSERT INTO auth_group (id, name) VALUES 
    (1, 'Admin'),
    (2, 'User'),
    (3, 'Baker')
ON CONFLICT (id) DO NOTHING;

-- Ajout de la contrainte de clé étrangère si elle n'existe pas
-- Vérifier si la contrainte existe avant de l'ajouter
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'accounts_user_group_id_fkey' 
        AND table_name = 'accounts_user'
        AND table_schema = 'public'
    ) THEN
        -- Vérifier que la table accounts_user existe
        IF EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = 'accounts_user'
        ) THEN
            ALTER TABLE accounts_user 
            ADD CONSTRAINT accounts_user_group_id_fkey 
            FOREIGN KEY (group_id) REFERENCES auth_group(id) ON DELETE SET NULL;
            
            RAISE NOTICE 'Contrainte de clé étrangère ajoutée avec succès';
        ELSE
            RAISE WARNING 'Table accounts_user n existe pas, contrainte non ajoutée';
        END IF;
    ELSE
        RAISE NOTICE 'Contrainte de clé étrangère existe déjà';
    END IF;
END $$;

-- Index pour email (déjà unique, mais index pour performance)
CREATE INDEX IF NOT EXISTS idx_accounts_user_email ON accounts_user(email);
CREATE INDEX IF NOT EXISTS idx_accounts_user_is_active ON accounts_user(is_active);

-- Ajout de colonnes manquantes si elles n'existent pas
DO $$ 
BEGIN
    -- Ajouter colonnes de tracking si elles n'existent pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'accounts_user' AND column_name = 'profile_image_url') THEN
        ALTER TABLE accounts_user ADD COLUMN profile_image_url VARCHAR(500);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'accounts_user' AND column_name = 'is_verified') THEN
        ALTER TABLE accounts_user ADD COLUMN is_verified BOOLEAN DEFAULT FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'accounts_user' AND column_name = 'preferred_language') THEN
        ALTER TABLE accounts_user ADD COLUMN preferred_language VARCHAR(10) DEFAULT 'fr';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'accounts_user' AND column_name = 'timezone') THEN
        ALTER TABLE accounts_user ADD COLUMN timezone VARCHAR(50) DEFAULT 'Europe/Paris';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'accounts_user' AND column_name = 'marketing_consent') THEN
        ALTER TABLE accounts_user ADD COLUMN marketing_consent BOOLEAN DEFAULT FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'accounts_user' AND column_name = 'privacy_consent') THEN
        ALTER TABLE accounts_user ADD COLUMN privacy_consent BOOLEAN DEFAULT FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'accounts_user' AND column_name = 'last_activity') THEN
        ALTER TABLE accounts_user ADD COLUMN last_activity TIMESTAMP WITH TIME ZONE;
    END IF;
END $$;

-- =====================================================
-- TABLE: user_sessions (tracking des sessions utilisateur)
-- =====================================================

CREATE TABLE IF NOT EXISTS user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    refresh_token VARCHAR(255) UNIQUE,
    device_info JSONB, -- {device_type, os, browser, version, etc.}
    ip_address INET,
    user_agent TEXT,
    location JSONB, -- {country, city, coordinates}
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE user_sessions IS 'Sessions utilisateur avec tracking device et géolocalisation';
COMMENT ON COLUMN user_sessions.device_info IS 'Informations sur le device (type, OS, navigateur)';
COMMENT ON COLUMN user_sessions.location IS 'Localisation géographique de la session';

-- =====================================================
-- TABLE: user_page_views (tracking des pages visitées)
-- =====================================================

CREATE TABLE IF NOT EXISTS user_page_views (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE,
    session_id UUID REFERENCES user_sessions(id) ON DELETE CASCADE,
    page_name VARCHAR(100) NOT NULL, -- 'home', 'product', 'cart', etc.
    page_url TEXT NOT NULL,
    page_title VARCHAR(255),
    referrer_url TEXT,
    duration_seconds INTEGER DEFAULT 0,
    scroll_depth_percentage INTEGER DEFAULT 0,
    metadata JSONB, -- {product_id, baker_id, search_query, etc.}
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE user_page_views IS 'Tracking des pages visitées avec métadonnées';
COMMENT ON COLUMN user_page_views.page_name IS 'Nom de la page (home, product, cart, etc.)';
COMMENT ON COLUMN user_page_views.metadata IS 'Métadonnées contextuelles (product_id, baker_id, etc.)';

-- =====================================================
-- TABLE: user_actions (tracking de chaque action utilisateur)
-- =====================================================

CREATE TABLE IF NOT EXISTS user_actions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE,
    session_id UUID REFERENCES user_sessions(id) ON DELETE CASCADE,
    page_view_id UUID REFERENCES user_page_views(id) ON DELETE CASCADE,
    action_type VARCHAR(50) NOT NULL, -- 'click', 'scroll', 'search', 'add_to_cart', etc.
    target_element VARCHAR(100), -- 'button', 'link', 'product_card', etc.
    target_id VARCHAR(100), -- ID de l'élément ciblé
    target_text TEXT, -- Texte de l'élément cliqué
    coordinates JSONB, -- {x, y} position du clic
    context JSONB, -- Contexte complet de l'action
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE user_actions IS 'Tracking granulaire de chaque action utilisateur';
COMMENT ON COLUMN user_actions.action_type IS 'Type d action (click, scroll, search, add_to_cart, etc.)';
COMMENT ON COLUMN user_actions.target_element IS 'Type d élément ciblé (button, link, product_card, etc.)';
COMMENT ON COLUMN user_actions.context IS 'Contexte complet de l action (product_id, baker_id, search_query, etc.)';

-- =====================================================
-- TABLE: user_search_history (historique des recherches)
-- =====================================================

CREATE TABLE IF NOT EXISTS user_search_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE,
    session_id UUID REFERENCES user_sessions(id) ON DELETE CASCADE,
    search_query VARCHAR(255) NOT NULL,
    search_type VARCHAR(50) DEFAULT 'general', -- 'general', 'products', 'bakers', 'location'
    filters JSONB, -- Filtres appliqués
    results_count INTEGER DEFAULT 0,
    clicked_results JSONB, -- Résultats sur lesquels l'utilisateur a cliqué
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE user_search_history IS 'Historique des recherches utilisateur avec contexte';
COMMENT ON COLUMN user_search_history.search_type IS 'Type de recherche (general, products, bakers, location)';
COMMENT ON COLUMN user_search_history.clicked_results IS 'Résultats sur lesquels l utilisateur a cliqué';

-- =====================================================
-- TABLE: user_analytics_daily (agrégation quotidienne des KPIs)
-- =====================================================

CREATE TABLE IF NOT EXISTS user_analytics_daily (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    -- Métriques de navigation
    page_views_count INTEGER DEFAULT 0,
    unique_pages_count INTEGER DEFAULT 0,
    total_session_duration INTEGER DEFAULT 0, -- en secondes
    -- Métriques d'engagement
    actions_count INTEGER DEFAULT 0,
    searches_count INTEGER DEFAULT 0,
    products_viewed_count INTEGER DEFAULT 0,
    bakers_viewed_count INTEGER DEFAULT 0,
    -- Métriques commerciales
    cart_additions_count INTEGER DEFAULT 0,
    favorites_additions_count INTEGER DEFAULT 0,
    orders_count INTEGER DEFAULT 0,
    total_spent DECIMAL(10,2) DEFAULT 0,
    -- Métriques de conversion
    conversion_rate DECIMAL(5,2) DEFAULT 0, -- % de sessions converties
    bounce_rate DECIMAL(5,2) DEFAULT 0, -- % de sessions avec une seule page
    -- Métadonnées
    metadata JSONB, -- Données supplémentaires
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, date)
);

COMMENT ON TABLE user_analytics_daily IS 'Agrégation quotidienne des KPIs utilisateur';
COMMENT ON COLUMN user_analytics_daily.conversion_rate IS 'Pourcentage de sessions converties en commande';
COMMENT ON COLUMN user_analytics_daily.bounce_rate IS 'Pourcentage de sessions avec une seule page vue';

-- =====================================================
-- TABLE: user_notifications (notifications utilisateur)
-- =====================================================

CREATE TABLE IF NOT EXISTS user_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE,
    notification_type VARCHAR(50) NOT NULL, -- 'order_update', 'promotion', 'message', 'review', etc.
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    data JSONB, -- Données contextuelles
    is_read BOOLEAN DEFAULT FALSE,
    is_sent BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE user_notifications IS 'Notifications utilisateur (push, email, in-app)';
COMMENT ON COLUMN user_notifications.notification_type IS 'Type de notification (order_update, promotion, message, etc.)';
COMMENT ON COLUMN user_notifications.data IS 'Données contextuelles (order_id, product_id, etc.)';

-- =====================================================
-- TABLE: user_preferences (préférences utilisateur)
-- =====================================================

CREATE TABLE IF NOT EXISTS user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE UNIQUE,
    -- Préférences de notification
    email_notifications BOOLEAN DEFAULT TRUE,
    push_notifications BOOLEAN DEFAULT TRUE,
    sms_notifications BOOLEAN DEFAULT FALSE,
    -- Préférences de contenu
    preferred_categories JSONB, -- Catégories préférées
    preferred_bakers JSONB, -- Pâtissiers préférés
    dietary_restrictions JSONB, -- Restrictions alimentaires
    -- Préférences d'affichage
    theme VARCHAR(20) DEFAULT 'light', -- 'light', 'dark', 'auto'
    language VARCHAR(10) DEFAULT 'fr',
    currency VARCHAR(3) DEFAULT 'EUR',
    -- Préférences de recherche
    search_radius INTEGER DEFAULT 10, -- Rayon de recherche en km
    sort_preference VARCHAR(50) DEFAULT 'relevance', -- 'relevance', 'distance', 'rating', 'price'
    -- Métadonnées
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE user_preferences IS 'Préférences utilisateur pour personnalisation';
COMMENT ON COLUMN user_preferences.preferred_categories IS 'Catégories de produits préférées';
COMMENT ON COLUMN user_preferences.dietary_restrictions IS 'Restrictions alimentaires (allergies, régimes)';

-- =====================================================
-- INDEX pour les performances
-- =====================================================

-- Index pour user_sessions
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_session_token ON user_sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_user_sessions_active ON user_sessions(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_user_sessions_created_at ON user_sessions(created_at);

-- Index pour user_page_views
CREATE INDEX IF NOT EXISTS idx_user_page_views_user_id ON user_page_views(user_id);
CREATE INDEX IF NOT EXISTS idx_user_page_views_session_id ON user_page_views(session_id);
CREATE INDEX IF NOT EXISTS idx_user_page_views_page_name ON user_page_views(page_name);
CREATE INDEX IF NOT EXISTS idx_user_page_views_created_at ON user_page_views(created_at);

-- Index pour user_actions
CREATE INDEX IF NOT EXISTS idx_user_actions_user_id ON user_actions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_actions_session_id ON user_actions(session_id);
CREATE INDEX IF NOT EXISTS idx_user_actions_action_type ON user_actions(action_type);
CREATE INDEX IF NOT EXISTS idx_user_actions_target_element ON user_actions(target_element);
CREATE INDEX IF NOT EXISTS idx_user_actions_created_at ON user_actions(created_at);

-- Index pour user_search_history
CREATE INDEX IF NOT EXISTS idx_user_search_history_user_id ON user_search_history(user_id);
CREATE INDEX IF NOT EXISTS idx_user_search_history_search_query ON user_search_history(search_query);
CREATE INDEX IF NOT EXISTS idx_user_search_history_created_at ON user_search_history(created_at);

-- Index pour user_analytics_daily
CREATE INDEX IF NOT EXISTS idx_user_analytics_daily_user_id ON user_analytics_daily(user_id);
CREATE INDEX IF NOT EXISTS idx_user_analytics_daily_date ON user_analytics_daily(date);

-- Index pour user_notifications
CREATE INDEX IF NOT EXISTS idx_user_notifications_user_id ON user_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_user_notifications_type ON user_notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_user_notifications_unread ON user_notifications(user_id, is_read) WHERE is_read = FALSE;

-- =====================================================
-- TRIGGERS pour updated_at
-- =====================================================

-- Trigger pour user_sessions
CREATE OR REPLACE FUNCTION update_user_sessions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    NEW.last_activity = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_user_sessions_updated_at
    BEFORE UPDATE ON user_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_user_sessions_updated_at();

-- Trigger pour user_analytics_daily
CREATE OR REPLACE FUNCTION update_user_analytics_daily_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_user_analytics_daily_updated_at
    BEFORE UPDATE ON user_analytics_daily
    FOR EACH ROW
    EXECUTE FUNCTION update_user_analytics_daily_updated_at();

-- Trigger pour user_preferences
CREATE OR REPLACE FUNCTION update_user_preferences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_user_preferences_updated_at
    BEFORE UPDATE ON user_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_user_preferences_updated_at();

-- =====================================================
-- VUES utiles
-- =====================================================

-- Vue pour les sessions actives
CREATE OR REPLACE VIEW active_user_sessions AS
SELECT 
    us.*,
    au.email,
    au.first_name,
    au.last_name
FROM user_sessions us
JOIN accounts_user au ON us.user_id = au.id
WHERE us.is_active = TRUE 
AND us.expires_at > NOW();

-- Vue pour les statistiques utilisateur
CREATE OR REPLACE VIEW user_stats AS
SELECT 
    au.id,
    au.email,
    au.first_name,
    au.last_name,
    au.date_joined,
    au.last_login,
    COUNT(DISTINCT us.id) as total_sessions,
    COUNT(DISTINCT upv.id) as total_page_views,
    COUNT(DISTINCT ua.id) as total_actions,
    COUNT(DISTINCT ush.id) as total_searches,
    COUNT(DISTINCT un.id) as unread_notifications
FROM accounts_user au
LEFT JOIN user_sessions us ON au.id = us.user_id
LEFT JOIN user_page_views upv ON au.id = upv.user_id
LEFT JOIN user_actions ua ON au.id = ua.user_id
LEFT JOIN user_search_history ush ON au.id = ush.user_id
LEFT JOIN user_notifications un ON au.id = un.user_id AND un.is_read = FALSE
GROUP BY au.id, au.email, au.first_name, au.last_name, au.date_joined, au.last_login;

COMMENT ON VIEW active_user_sessions IS 'Sessions utilisateur actives avec informations utilisateur';
COMMENT ON VIEW user_stats IS 'Statistiques agrégées par utilisateur';


CREATE TABLE IF NOT EXISTS password_reset_codes (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES accounts_user(id) ON DELETE CASCADE,
    code VARCHAR(6) NOT NULL,
    reset_type VARCHAR(10) NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_password_reset_codes_user_id ON password_reset_codes(user_id);
CREATE INDEX IF NOT EXISTS idx_password_reset_codes_code ON password_reset_codes(code);
CREATE INDEX IF NOT EXISTS idx_password_reset_codes_is_used ON password_reset_codes(is_used) WHERE is_used = FALSE;


-- Colonne email_verified sur accounts_user
ALTER TABLE accounts_user
  ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT FALSE;

-- Table des codes de vérification email
CREATE TABLE IF NOT EXISTS email_verification_codes (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES accounts_user(id) ON DELETE CASCADE,
    code VARCHAR(6) NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_email_verif_user_id
  ON email_verification_codes(user_id);
CREATE INDEX IF NOT EXISTS idx_email_verif_code
  ON email_verification_codes(code);
CREATE INDEX IF NOT EXISTS idx_email_verif_is_used
  ON email_verification_codes(is_used) WHERE is_used = FALSE;
