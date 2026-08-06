-- =====================================================
-- 05_favorites.sql
-- Tables favoris, groupes de favoris et analytics
-- =====================================================

-- Extension pour UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- TABLE: user_favoris (favoris utilisateur)
-- =====================================================

-- Création de la table user_favoris si elle n'existe pas
CREATE TABLE IF NOT EXISTS user_favoris (
    user_id INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES product(id) ON DELETE CASCADE,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    
    PRIMARY KEY (user_id, product_id) -- Clé primaire composite
);

COMMENT ON TABLE user_favoris IS 'Produits favoris des utilisateurs';
COMMENT ON COLUMN user_favoris.user_id IS 'Utilisateur qui a ajouté le favori';
COMMENT ON COLUMN user_favoris.product_id IS 'Produit favori';
COMMENT ON COLUMN user_favoris.is_public IS 'Favori visible par les autres utilisateurs';

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_user_favoris_user_id ON user_favoris(user_id);
CREATE INDEX IF NOT EXISTS idx_user_favoris_product_id ON user_favoris(product_id);
CREATE INDEX IF NOT EXISTS idx_user_favoris_added_at ON user_favoris(added_at);

-- Ajout de colonnes manquantes si elles n'existent pas
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_favoris' AND column_name = 'added_at') THEN
        ALTER TABLE user_favoris ADD COLUMN added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_favoris' AND column_name = 'notes') THEN
        ALTER TABLE user_favoris ADD COLUMN notes TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_favoris' AND column_name = 'is_public') THEN
        ALTER TABLE user_favoris ADD COLUMN is_public BOOLEAN DEFAULT FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_favoris' AND column_name = 'sort_order') THEN
        ALTER TABLE user_favoris ADD COLUMN sort_order INTEGER DEFAULT 0;
    END IF;
END $$;

-- =====================================================
-- TABLE: favorite_groups (groupes de favoris)
-- =====================================================

CREATE TABLE IF NOT EXISTS favorite_groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    color VARCHAR(7), -- Code couleur hexadécimal
    icon VARCHAR(100), -- Nom de l'icône
    is_public BOOLEAN DEFAULT FALSE,
    is_default BOOLEAN DEFAULT FALSE, -- Groupe par défaut "Tous"
    sort_order INTEGER DEFAULT 0,
    items_count INTEGER DEFAULT 0, -- Compteur d'articles
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, name) -- Nom unique par utilisateur
);

COMMENT ON TABLE favorite_groups IS 'Groupes de favoris créés par les utilisateurs';
COMMENT ON COLUMN favorite_groups.is_default IS 'Indique si c est le groupe par défaut "Tous"';
COMMENT ON COLUMN favorite_groups.items_count IS 'Compteur d articles dans le groupe';

-- =====================================================
-- TABLE: favorite_group_items (articles dans les groupes)
-- =====================================================

CREATE TABLE IF NOT EXISTS favorite_group_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID REFERENCES favorite_groups(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES product(id) ON DELETE CASCADE,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT,
    sort_order INTEGER DEFAULT 0,
    
    UNIQUE(group_id, product_id) -- Un produit ne peut être qu'une fois par groupe
);

COMMENT ON TABLE favorite_group_items IS 'Articles dans les groupes de favoris';
COMMENT ON COLUMN favorite_group_items.notes IS 'Notes personnelles sur le produit dans ce groupe';

-- =====================================================
-- TABLE: favorite_shares (partage de groupes de favoris)
-- =====================================================

CREATE TABLE IF NOT EXISTS favorite_shares (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID REFERENCES favorite_groups(id) ON DELETE CASCADE,
    shared_by INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE,
    shared_with INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE,
    permission_level VARCHAR(20) DEFAULT 'view', -- 'view', 'edit', 'admin'
    is_active BOOLEAN DEFAULT TRUE,
    shared_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    
    UNIQUE(group_id, shared_with)
);

COMMENT ON TABLE favorite_shares IS 'Partage de groupes de favoris entre utilisateurs';
COMMENT ON COLUMN favorite_shares.permission_level IS 'Niveau de permission (view, edit, admin)';

-- =====================================================
-- TABLE: favorite_analytics_daily (analytics des favoris)
-- =====================================================

CREATE TABLE IF NOT EXISTS favorite_analytics_daily (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    -- Métriques d'ajout
    favorites_added INTEGER DEFAULT 0,
    favorites_removed INTEGER DEFAULT 0,
    groups_created INTEGER DEFAULT 0,
    groups_deleted INTEGER DEFAULT 0,
    -- Métriques d'engagement
    favorites_viewed INTEGER DEFAULT 0,
    groups_viewed INTEGER DEFAULT 0,
    shares_made INTEGER DEFAULT 0,
    shares_received INTEGER DEFAULT 0,
    -- Métriques de conversion
    favorites_to_cart INTEGER DEFAULT 0, -- Favoris ajoutés au panier
    favorites_to_order INTEGER DEFAULT 0, -- Favoris convertis en commande
    -- Métadonnées
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, date)
);

COMMENT ON TABLE favorite_analytics_daily IS 'Analytics quotidiennes des favoris par utilisateur';
COMMENT ON COLUMN favorite_analytics_daily.favorites_to_cart IS 'Nombre de favoris ajoutés au panier';
COMMENT ON COLUMN favorite_analytics_daily.favorites_to_order IS 'Nombre de favoris convertis en commande';

-- =====================================================
-- TABLE: product_favorite_stats (statistiques des favoris par produit)
-- =====================================================

CREATE TABLE IF NOT EXISTS product_favorite_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id INTEGER REFERENCES product(id) ON DELETE CASCADE,
    total_favorites INTEGER DEFAULT 0,
    unique_users INTEGER DEFAULT 0,
    groups_count INTEGER DEFAULT 0, -- Nombre de groupes contenant ce produit
    last_added TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(product_id)
);

COMMENT ON TABLE product_favorite_stats IS 'Statistiques agrégées des favoris par produit';

-- =====================================================
-- TABLE: favorite_recommendations (recommandations basées sur les favoris)
-- =====================================================

CREATE TABLE IF NOT EXISTS favorite_recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE,
    recommended_product_id INTEGER REFERENCES product(id) ON DELETE CASCADE,
    recommendation_type VARCHAR(50) NOT NULL, -- 'similar_favorites', 'group_based', 'trending_in_groups'
    score DECIMAL(5,4) DEFAULT 0, -- Score de recommandation (0-1)
    reason TEXT, -- Raison de la recommandation
    source_group_id UUID REFERENCES favorite_groups(id) ON DELETE SET NULL,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, recommended_product_id, recommendation_type)
);

COMMENT ON TABLE favorite_recommendations IS 'Recommandations de produits basées sur les favoris';
COMMENT ON COLUMN favorite_recommendations.recommendation_type IS 'Type de recommandation (similar_favorites, group_based, trending_in_groups)';

-- =====================================================
-- INDEX pour les performances
-- =====================================================

-- Index pour user_favoris
CREATE INDEX IF NOT EXISTS idx_user_favoris_user_id ON user_favoris(user_id);
CREATE INDEX IF NOT EXISTS idx_user_favoris_product_id ON user_favoris(product_id);
CREATE INDEX IF NOT EXISTS idx_user_favoris_added_at ON user_favoris(added_at);

-- Index pour favorite_groups
CREATE INDEX IF NOT EXISTS idx_favorite_groups_user_id ON favorite_groups(user_id);
CREATE INDEX IF NOT EXISTS idx_favorite_groups_is_public ON favorite_groups(is_public) WHERE is_public = TRUE;
CREATE INDEX IF NOT EXISTS idx_favorite_groups_is_default ON favorite_groups(user_id, is_default) WHERE is_default = TRUE;
CREATE INDEX IF NOT EXISTS idx_favorite_groups_created_at ON favorite_groups(created_at);

-- Index pour favorite_group_items
CREATE INDEX IF NOT EXISTS idx_favorite_group_items_group_id ON favorite_group_items(group_id);
CREATE INDEX IF NOT EXISTS idx_favorite_group_items_product_id ON favorite_group_items(product_id);
CREATE INDEX IF NOT EXISTS idx_favorite_group_items_added_at ON favorite_group_items(added_at);

-- Index pour favorite_shares
CREATE INDEX IF NOT EXISTS idx_favorite_shares_group_id ON favorite_shares(group_id);
CREATE INDEX IF NOT EXISTS idx_favorite_shares_shared_by ON favorite_shares(shared_by);
CREATE INDEX IF NOT EXISTS idx_favorite_shares_shared_with ON favorite_shares(shared_with);
CREATE INDEX IF NOT EXISTS idx_favorite_shares_active ON favorite_shares(is_active) WHERE is_active = TRUE;

-- Index pour favorite_analytics_daily
CREATE INDEX IF NOT EXISTS idx_favorite_analytics_daily_user_id ON favorite_analytics_daily(user_id);
CREATE INDEX IF NOT EXISTS idx_favorite_analytics_daily_date ON favorite_analytics_daily(date);

-- Index pour product_favorite_stats
CREATE INDEX IF NOT EXISTS idx_product_favorite_stats_product_id ON product_favorite_stats(product_id);
CREATE INDEX IF NOT EXISTS idx_product_favorite_stats_total_favorites ON product_favorite_stats(total_favorites);

-- Index pour favorite_recommendations
CREATE INDEX IF NOT EXISTS idx_favorite_recommendations_user_id ON favorite_recommendations(user_id);
CREATE INDEX IF NOT EXISTS idx_favorite_recommendations_product_id ON favorite_recommendations(recommended_product_id);
CREATE INDEX IF NOT EXISTS idx_favorite_recommendations_type ON favorite_recommendations(recommendation_type);
CREATE INDEX IF NOT EXISTS idx_favorite_recommendations_score ON favorite_recommendations(score);

-- =====================================================
-- TRIGGERS pour updated_at et compteurs
-- =====================================================

-- Trigger pour favorite_groups
CREATE OR REPLACE FUNCTION update_favorite_groups_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_favorite_groups_updated_at ON favorite_groups;
CREATE TRIGGER trigger_favorite_groups_updated_at
    BEFORE UPDATE ON favorite_groups
    FOR EACH ROW
    EXECUTE FUNCTION update_favorite_groups_updated_at();

-- Trigger pour favorite_analytics_daily
CREATE OR REPLACE FUNCTION update_favorite_analytics_daily_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_favorite_analytics_daily_updated_at ON favorite_analytics_daily;
CREATE TRIGGER trigger_favorite_analytics_daily_updated_at
    BEFORE UPDATE ON favorite_analytics_daily
    FOR EACH ROW
    EXECUTE FUNCTION update_favorite_analytics_daily_updated_at();

-- Trigger pour product_favorite_stats
CREATE OR REPLACE FUNCTION update_product_favorite_stats_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_product_favorite_stats_updated_at ON product_favorite_stats;
CREATE TRIGGER trigger_product_favorite_stats_updated_at
    BEFORE UPDATE ON product_favorite_stats
    FOR EACH ROW
    EXECUTE FUNCTION update_product_favorite_stats_updated_at();

-- Trigger pour mettre à jour les compteurs
CREATE OR REPLACE FUNCTION update_favorite_counters()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_TABLE_NAME = 'favorite_group_items' THEN
        IF TG_OP = 'INSERT' THEN
            -- Mettre à jour le compteur du groupe
            UPDATE favorite_groups SET items_count = items_count + 1 WHERE id = NEW.group_id;
            
            -- Mettre à jour les stats du produit
            INSERT INTO product_favorite_stats (product_id, total_favorites, unique_users, groups_count, last_added)
            VALUES (NEW.product_id, 1, 1, 1, NEW.added_at)
            ON CONFLICT (product_id) DO UPDATE SET
                total_favorites = product_favorite_stats.total_favorites + 1,
                groups_count = product_favorite_stats.groups_count + 1,
                last_added = NEW.added_at,
                updated_at = NOW();
                
        ELSIF TG_OP = 'DELETE' THEN
            -- Mettre à jour le compteur du groupe
            UPDATE favorite_groups SET items_count = items_count - 1 WHERE id = OLD.group_id;
            
            -- Mettre à jour les stats du produit
            UPDATE product_favorite_stats SET
                total_favorites = total_favorites - 1,
                groups_count = groups_count - 1,
                updated_at = NOW()
            WHERE product_id = OLD.product_id;
        END IF;
        
    ELSIF TG_TABLE_NAME = 'user_favoris' THEN
        IF TG_OP = 'INSERT' THEN
            -- Mettre à jour les stats du produit
            INSERT INTO product_favorite_stats (product_id, total_favorites, unique_users, last_added)
            VALUES (NEW.product_id, 1, 1, NEW.added_at)
            ON CONFLICT (product_id) DO UPDATE SET
                total_favorites = product_favorite_stats.total_favorites + 1,
                unique_users = product_favorite_stats.unique_users + 1,
                last_added = NEW.added_at,
                updated_at = NOW();
                
        ELSIF TG_OP = 'DELETE' THEN
            -- Mettre à jour les stats du produit
            UPDATE product_favorite_stats SET
                total_favorites = total_favorites - 1,
                unique_users = unique_users - 1,
                updated_at = NOW()
            WHERE product_id = OLD.product_id;
        END IF;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_favorite_group_items_counters ON favorite_group_items;
CREATE TRIGGER trigger_favorite_group_items_counters
    AFTER INSERT OR DELETE ON favorite_group_items
    FOR EACH ROW
    EXECUTE FUNCTION update_favorite_counters();

DROP TRIGGER IF EXISTS trigger_user_favoris_counters ON user_favoris;
CREATE TRIGGER trigger_user_favoris_counters
    AFTER INSERT OR DELETE ON user_favoris
    FOR EACH ROW
    EXECUTE FUNCTION update_favorite_counters();

-- =====================================================
-- VUES utiles
-- =====================================================

-- Vue pour les groupes de favoris avec informations complètes
CREATE OR REPLACE VIEW favorite_groups_complete AS
SELECT 
    fg.*,
    au.first_name as user_first_name,
    au.last_name as user_last_name,
    au.email as user_email,
    COUNT(DISTINCT fgi.product_id) as actual_items_count,
    COUNT(DISTINCT fs.shared_with) as shares_count,
    MAX(fgi.added_at) as last_item_added
FROM favorite_groups fg
JOIN accounts_user au ON fg.user_id = au.id
LEFT JOIN favorite_group_items fgi ON fg.id = fgi.group_id
LEFT JOIN favorite_shares fs ON fg.id = fs.group_id AND fs.is_active = TRUE
GROUP BY fg.id, au.first_name, au.last_name, au.email;

-- Vue pour les favoris avec informations produit
CREATE OR REPLACE VIEW user_favorites_with_products AS
SELECT 
    uf.*,
    p.name as product_name,
    p.price as product_price,
    p.description as product_description,
    pi.imageurl as product_image_url,
    b.userid as baker_user_id,
    au.first_name as baker_first_name,
    au.last_name as baker_last_name,
    pfs.total_favorites as product_total_favorites,
    pfs.groups_count as product_groups_count
FROM user_favoris uf
JOIN product p ON uf.product_id = p.id
LEFT JOIN product_image pi ON p.id = pi.productid AND pi.is_primary = TRUE
LEFT JOIN baker b ON p.baker_id = b.id
LEFT JOIN accounts_user au ON b.userid = au.id
LEFT JOIN product_favorite_stats pfs ON p.id = pfs.product_id
ORDER BY uf.added_at DESC;

-- Vue pour les produits les plus favorisés
CREATE OR REPLACE VIEW most_favorited_products AS
SELECT 
    p.*,
    pfs.total_favorites,
    pfs.unique_users,
    pfs.groups_count,
    pfs.last_added,
    pi.imageurl as primary_image_url,
    b.userid as baker_user_id,
    au.first_name as baker_first_name,
    au.last_name as baker_last_name,
    ROW_NUMBER() OVER (ORDER BY pfs.total_favorites DESC, pfs.unique_users DESC) as popularity_rank
FROM product p
JOIN product_favorite_stats pfs ON p.id = pfs.product_id
LEFT JOIN product_image pi ON p.id = pi.productid AND pi.is_primary = TRUE
LEFT JOIN baker b ON p.baker_id = b.id
LEFT JOIN accounts_user au ON b.userid = au.id
WHERE p.is_active = TRUE
ORDER BY pfs.total_favorites DESC, pfs.unique_users DESC;

-- Vue pour les statistiques des favoris par utilisateur
CREATE OR REPLACE VIEW user_favorite_stats AS
SELECT 
    au.id as user_id,
    au.email,
    au.first_name,
    au.last_name,
    COUNT(DISTINCT uf.product_id) as total_favorites,
    COUNT(DISTINCT fg.id) as total_groups,
    COUNT(DISTINCT fgi.product_id) as total_group_items,
    COUNT(DISTINCT fs.id) as total_shares_made,
    COUNT(DISTINCT fs2.id) as total_shares_received,
    MAX(uf.added_at) as last_favorite_added,
    MAX(fg.created_at) as last_group_created
FROM accounts_user au
LEFT JOIN user_favoris uf ON au.id = uf.user_id
LEFT JOIN favorite_groups fg ON au.id = fg.user_id
LEFT JOIN favorite_group_items fgi ON fg.id = fgi.group_id
LEFT JOIN favorite_shares fs ON au.id = fs.shared_by
LEFT JOIN favorite_shares fs2 ON au.id = fs2.shared_with
GROUP BY au.id, au.email, au.first_name, au.last_name;

COMMENT ON VIEW favorite_groups_complete IS 'Groupes de favoris avec informations complètes et compteurs';
COMMENT ON VIEW user_favorites_with_products IS 'Favoris utilisateur avec informations produit et pâtissier';
COMMENT ON VIEW most_favorited_products IS 'Produits les plus favorisés avec statistiques';
COMMENT ON VIEW user_favorite_stats IS 'Statistiques des favoris par utilisateur';
