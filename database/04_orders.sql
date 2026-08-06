-- =====================================================
-- 04_orders.sql
-- Tables commandes, panier, livraison et historique
-- =====================================================

-- Extension pour UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- TABLE: orders (table principale commandes)
-- =====================================================

-- Création de la table orders si elle n'existe pas
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    userid INTEGER REFERENCES accounts_user(id) ON DELETE SET NULL,
    total_price DECIMAL(10,2) NOT NULL,
    tax_included BOOLEAN DEFAULT FALSE,
    payment_method INTEGER, -- FK vers payment_method (créée dans 07_payments.sql)
    promotionid INTEGER, -- FK vers promotion (si table existe)
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    baker_id INTEGER REFERENCES baker(id) ON DELETE SET NULL,
    order_number VARCHAR(50) UNIQUE,
    checkout_reference UUID, -- Regroupe les N commandes (1 par baker) d'un même checkout
    delivery_address JSONB,
    delivery_date DATE,
    delivery_time_slot VARCHAR(50),
    delivery_instructions TEXT,
    delivery_fee DECIMAL(10,2) DEFAULT 0,
    service_fee DECIMAL(10,2) DEFAULT 0,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    subtotal DECIMAL(10,2),
    customer_notes TEXT,
    estimated_preparation_time INTEGER,
    actual_preparation_time INTEGER,
    delivery_tracking JSONB,
    cancellation_reason TEXT,
    refund_amount DECIMAL(10,2) DEFAULT 0,
    refund_reason TEXT,
    refund_date TIMESTAMP WITH TIME ZONE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT
);

COMMENT ON TABLE orders IS 'Table principale des commandes';
COMMENT ON COLUMN orders.userid IS 'Utilisateur qui a passé la commande';
COMMENT ON COLUMN orders.baker_id IS 'Pâtissier qui prépare la commande';
COMMENT ON COLUMN orders.status IS 'Statut: pending, confirmed, preparing, ready, delivered, cancelled';
COMMENT ON COLUMN orders.order_number IS 'Numéro unique de commande';
COMMENT ON COLUMN orders.delivery_address IS 'Adresse de livraison (JSON)';

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_orders_userid ON orders(userid);
CREATE INDEX IF NOT EXISTS idx_orders_baker_id ON orders(baker_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_order_number ON orders(order_number);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);

-- Ajout de colonnes manquantes si elles n'existent pas
DO $$ 
BEGIN
    -- Ajouter colonnes manquantes si elles n'existent pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'order_number') THEN
        ALTER TABLE orders ADD COLUMN order_number VARCHAR(50) UNIQUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'baker_id') THEN
        ALTER TABLE orders ADD COLUMN baker_id INTEGER REFERENCES baker(id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'delivery_address') THEN
        ALTER TABLE orders ADD COLUMN delivery_address JSONB;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'delivery_date') THEN
        ALTER TABLE orders ADD COLUMN delivery_date DATE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'delivery_time_slot') THEN
        ALTER TABLE orders ADD COLUMN delivery_time_slot VARCHAR(50);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'delivery_instructions') THEN
        ALTER TABLE orders ADD COLUMN delivery_instructions TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'delivery_fee') THEN
        ALTER TABLE orders ADD COLUMN delivery_fee DECIMAL(10,2) DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'service_fee') THEN
        ALTER TABLE orders ADD COLUMN service_fee DECIMAL(10,2) DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'discount_amount') THEN
        ALTER TABLE orders ADD COLUMN discount_amount DECIMAL(10,2) DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'subtotal') THEN
        ALTER TABLE orders ADD COLUMN subtotal DECIMAL(10,2);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'customer_notes') THEN
        ALTER TABLE orders ADD COLUMN customer_notes TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'estimated_preparation_time') THEN
        ALTER TABLE orders ADD COLUMN estimated_preparation_time INTEGER; -- en heures
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'actual_preparation_time') THEN
        ALTER TABLE orders ADD COLUMN actual_preparation_time INTEGER; -- en heures
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'delivery_tracking') THEN
        ALTER TABLE orders ADD COLUMN delivery_tracking JSONB;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'cancellation_reason') THEN
        ALTER TABLE orders ADD COLUMN cancellation_reason TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'refund_amount') THEN
        ALTER TABLE orders ADD COLUMN refund_amount DECIMAL(10,2) DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'refund_reason') THEN
        ALTER TABLE orders ADD COLUMN refund_reason TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'refund_date') THEN
        ALTER TABLE orders ADD COLUMN refund_date TIMESTAMP WITH TIME ZONE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'rating') THEN
        ALTER TABLE orders ADD COLUMN rating INTEGER CHECK (rating >= 1 AND rating <= 5);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'review_text') THEN
        ALTER TABLE orders ADD COLUMN review_text TEXT;
    END IF;

    -- Référence de checkout (UUID) : regroupe les N commandes (1 par baker)
    -- créées lors d'un même panier validé. Requise par order-service au checkout.
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'checkout_reference') THEN
        ALTER TABLE orders ADD COLUMN checkout_reference UUID;
    END IF;
END $$;

-- Index sur checkout_reference (placé après le DO pour que la colonne existe)
CREATE INDEX IF NOT EXISTS idx_orders_checkout_reference ON orders(checkout_reference);

-- =====================================================
-- TABLE: order_detail (détails des commandes)
-- =====================================================

-- Création de la table order_detail si elle n'existe pas
CREATE TABLE IF NOT EXISTS order_detail (
    id SERIAL PRIMARY KEY,
    orderid INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    productid INTEGER REFERENCES product(id) ON DELETE SET NULL,
    variantid INTEGER REFERENCES product_variant(id) ON DELETE SET NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    customization_options JSONB,
    special_instructions TEXT,
    preparation_time_hours INTEGER,
    is_prepared BOOLEAN DEFAULT FALSE,
    prepared_at TIMESTAMP WITH TIME ZONE
);

COMMENT ON TABLE order_detail IS 'Détails des produits dans chaque commande';
COMMENT ON COLUMN order_detail.orderid IS 'Référence vers la commande';
COMMENT ON COLUMN order_detail.productid IS 'Référence vers le produit';
COMMENT ON COLUMN order_detail.variantid IS 'Référence vers la variante du produit';
COMMENT ON COLUMN order_detail.unit_price IS 'Prix unitaire au moment de la commande';

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_order_detail_orderid ON order_detail(orderid);
CREATE INDEX IF NOT EXISTS idx_order_detail_productid ON order_detail(productid);

-- Ajout de colonnes manquantes si elles n'existent pas
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'order_detail' AND column_name = 'customization_options') THEN
        ALTER TABLE order_detail ADD COLUMN customization_options JSONB;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'order_detail' AND column_name = 'special_instructions') THEN
        ALTER TABLE order_detail ADD COLUMN special_instructions TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'order_detail' AND column_name = 'preparation_time_hours') THEN
        ALTER TABLE order_detail ADD COLUMN preparation_time_hours INTEGER;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'order_detail' AND column_name = 'is_prepared') THEN
        ALTER TABLE order_detail ADD COLUMN is_prepared BOOLEAN DEFAULT FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'order_detail' AND column_name = 'prepared_at') THEN
        ALTER TABLE order_detail ADD COLUMN prepared_at TIMESTAMP WITH TIME ZONE;
    END IF;
END $$;

-- =====================================================
-- TABLE: cart (panier utilisateur)
-- =====================================================

CREATE TABLE IF NOT EXISTS cart (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE,
    session_id UUID REFERENCES user_sessions(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id) -- Un seul panier actif par utilisateur
);

COMMENT ON TABLE cart IS 'Panier utilisateur avec expiration automatique';
COMMENT ON COLUMN cart.session_id IS 'Session anonyme pour les utilisateurs non connectés';

-- =====================================================
-- TABLE: cart_items (articles du panier)
-- =====================================================

CREATE TABLE IF NOT EXISTS cart_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cart_id UUID REFERENCES cart(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES product(id) ON DELETE CASCADE,
    product_variant_id INTEGER REFERENCES product_variant(id) ON DELETE SET NULL,
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    customization_options JSONB, -- Options de personnalisation
    special_instructions TEXT,
    delivery_date DATE,
    delivery_time_slot VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(cart_id, product_id, product_variant_id, delivery_date, delivery_time_slot)
);

COMMENT ON TABLE cart_items IS 'Articles dans le panier avec personnalisation et livraison';
COMMENT ON COLUMN cart_items.customization_options IS 'Options de personnalisation sélectionnées';

-- =====================================================
-- TABLE: shipping_address (amélioration de la table existante)
-- =====================================================

-- Ajout de colonnes manquantes si la table existe
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'shipping_address') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'shipping_address' AND column_name = 'is_default') THEN
            ALTER TABLE shipping_address ADD COLUMN is_default BOOLEAN DEFAULT FALSE;
        END IF;
    
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'shipping_address' AND column_name = 'address_type') THEN
            ALTER TABLE shipping_address ADD COLUMN address_type VARCHAR(20) DEFAULT 'home'; -- 'home', 'work', 'other'
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'shipping_address' AND column_name = 'coordinates') THEN
            ALTER TABLE shipping_address ADD COLUMN coordinates POINT; -- Coordonnées GPS
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'shipping_address' AND column_name = 'delivery_instructions') THEN
            ALTER TABLE shipping_address ADD COLUMN delivery_instructions TEXT;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'shipping_address' AND column_name = 'is_verified') THEN
            ALTER TABLE shipping_address ADD COLUMN is_verified BOOLEAN DEFAULT FALSE;
        END IF;
    END IF;
END $$;

-- =====================================================
-- TABLE: order_status_history (historique des statuts de commande)
-- =====================================================

CREATE TABLE IF NOT EXISTS order_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL,
    previous_status VARCHAR(50),
    changed_by INTEGER REFERENCES accounts_user(id) ON DELETE SET NULL, -- Qui a changé le statut
    change_reason TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE order_status_history IS 'Historique des changements de statut des commandes';
COMMENT ON COLUMN order_status_history.changed_by IS 'Utilisateur qui a effectué le changement de statut';

-- =====================================================
-- TABLE: order_tracking (suivi des commandes)
-- =====================================================

CREATE TABLE IF NOT EXISTS order_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    tracking_number VARCHAR(100) UNIQUE,
    carrier VARCHAR(100), -- Transporteur
    tracking_url TEXT,
    estimated_delivery TIMESTAMP WITH TIME ZONE,
    actual_delivery TIMESTAMP WITH TIME ZONE,
    delivery_attempts INTEGER DEFAULT 0,
    delivery_status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'in_transit', 'delivered', 'failed'
    delivery_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE order_tracking IS 'Suivi détaillé des livraisons';
COMMENT ON COLUMN order_tracking.delivery_status IS 'Statut de livraison (pending, in_transit, delivered, failed)';

-- =====================================================
-- TABLE: order_analytics_daily (analytics quotidiennes des commandes)
-- =====================================================

CREATE TABLE IF NOT EXISTS order_analytics_daily (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE NOT NULL,
    -- Métriques globales
    total_orders INTEGER DEFAULT 0,
    total_revenue DECIMAL(12,2) DEFAULT 0,
    average_order_value DECIMAL(10,2) DEFAULT 0,
    -- Métriques par statut
    pending_orders INTEGER DEFAULT 0,
    confirmed_orders INTEGER DEFAULT 0,
    preparing_orders INTEGER DEFAULT 0,
    ready_orders INTEGER DEFAULT 0,
    delivered_orders INTEGER DEFAULT 0,
    cancelled_orders INTEGER DEFAULT 0,
    -- Métriques de performance
    average_preparation_time DECIMAL(8,2) DEFAULT 0, -- en heures
    average_delivery_time DECIMAL(8,2) DEFAULT 0, -- en heures
    on_time_delivery_rate DECIMAL(5,2) DEFAULT 0, -- %
    -- Métriques de satisfaction
    average_rating DECIMAL(3,2) DEFAULT 0,
    reviews_count INTEGER DEFAULT 0,
    -- Métadonnées
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(date)
);

COMMENT ON TABLE order_analytics_daily IS 'Analytics quotidiennes agrégées des commandes';
COMMENT ON COLUMN order_analytics_daily.on_time_delivery_rate IS 'Pourcentage de livraisons à l heure';

-- =====================================================
-- TABLE: delivery_zones (zones de livraison)
-- =====================================================

CREATE TABLE IF NOT EXISTS delivery_zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baker_id INTEGER REFERENCES baker(id) ON DELETE CASCADE,
    zone_name VARCHAR(100) NOT NULL,
    zone_description TEXT,
    delivery_fee DECIMAL(10,2) DEFAULT 0,
    min_order_amount DECIMAL(10,2) DEFAULT 0,
    estimated_delivery_time INTEGER DEFAULT 60, -- en minutes
    is_active BOOLEAN DEFAULT TRUE,
    polygon_coordinates JSONB, -- Coordonnées du polygone de la zone
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE delivery_zones IS 'Zones de livraison par pâtissier';
COMMENT ON COLUMN delivery_zones.polygon_coordinates IS 'Coordonnées du polygone définissant la zone';

-- =====================================================
-- TABLE: delivery_time_slots (créneaux de livraison)
-- =====================================================

CREATE TABLE IF NOT EXISTS delivery_time_slots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baker_id INTEGER REFERENCES baker(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL, -- 0=dimanche, 1=lundi, ..., 6=samedi
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    max_orders INTEGER, -- Nombre maximum de commandes pour ce créneau
    current_orders INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(baker_id, day_of_week, start_time)
);

COMMENT ON TABLE delivery_time_slots IS 'Créneaux de livraison disponibles par pâtissier';
COMMENT ON COLUMN delivery_time_slots.max_orders IS 'Nombre maximum de commandes acceptées pour ce créneau';

-- =====================================================
-- INDEX pour les performances
-- =====================================================

-- Index pour orders
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(userid);
CREATE INDEX IF NOT EXISTS idx_orders_baker_id ON orders(baker_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_order_number ON orders(order_number);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);
CREATE INDEX IF NOT EXISTS idx_orders_delivery_date ON orders(delivery_date);

-- Index pour order_detail
CREATE INDEX IF NOT EXISTS idx_order_detail_order_id ON order_detail(orderid);
CREATE INDEX IF NOT EXISTS idx_order_detail_product_id ON order_detail(productid);
CREATE INDEX IF NOT EXISTS idx_order_detail_variant_id ON order_detail(variantid);

-- Index pour cart
CREATE INDEX IF NOT EXISTS idx_cart_user_id ON cart(user_id);
CREATE INDEX IF NOT EXISTS idx_cart_active ON cart(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_cart_expires_at ON cart(expires_at);

-- Index pour cart_items
CREATE INDEX IF NOT EXISTS idx_cart_items_cart_id ON cart_items(cart_id);
CREATE INDEX IF NOT EXISTS idx_cart_items_product_id ON cart_items(product_id);
CREATE INDEX IF NOT EXISTS idx_cart_items_variant_id ON cart_items(product_variant_id);

-- Index pour shipping_address (seulement si la table existe)
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'shipping_address') THEN
        CREATE INDEX IF NOT EXISTS idx_shipping_address_user_id ON shipping_address(userid);
        CREATE INDEX IF NOT EXISTS idx_shipping_address_default ON shipping_address(userid, is_default) WHERE is_default = TRUE;
    END IF;
END $$;

-- Index pour order_status_history
CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id ON order_status_history(order_id);
CREATE INDEX IF NOT EXISTS idx_order_status_history_status ON order_status_history(status);
CREATE INDEX IF NOT EXISTS idx_order_status_history_created_at ON order_status_history(created_at);

-- Index pour order_tracking
CREATE INDEX IF NOT EXISTS idx_order_tracking_order_id ON order_tracking(order_id);
CREATE INDEX IF NOT EXISTS idx_order_tracking_number ON order_tracking(tracking_number);
CREATE INDEX IF NOT EXISTS idx_order_tracking_status ON order_tracking(delivery_status);

-- Index pour order_analytics_daily
CREATE INDEX IF NOT EXISTS idx_order_analytics_daily_date ON order_analytics_daily(date);

-- Index pour delivery_zones
CREATE INDEX IF NOT EXISTS idx_delivery_zones_baker_id ON delivery_zones(baker_id);
CREATE INDEX IF NOT EXISTS idx_delivery_zones_active ON delivery_zones(is_active) WHERE is_active = TRUE;

-- Index pour delivery_time_slots
CREATE INDEX IF NOT EXISTS idx_delivery_time_slots_baker_id ON delivery_time_slots(baker_id);
CREATE INDEX IF NOT EXISTS idx_delivery_time_slots_day ON delivery_time_slots(day_of_week);
CREATE INDEX IF NOT EXISTS idx_delivery_time_slots_active ON delivery_time_slots(is_active) WHERE is_active = TRUE;

-- =====================================================
-- TRIGGERS pour updated_at et génération de numéros
-- =====================================================

-- Trigger pour cart
CREATE OR REPLACE FUNCTION update_cart_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_cart_updated_at ON cart;
CREATE TRIGGER trigger_cart_updated_at
    BEFORE UPDATE ON cart
    FOR EACH ROW
    EXECUTE FUNCTION update_cart_updated_at();

-- Trigger pour cart_items
CREATE OR REPLACE FUNCTION update_cart_items_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_cart_items_updated_at ON cart_items;
CREATE TRIGGER trigger_cart_items_updated_at
    BEFORE UPDATE ON cart_items
    FOR EACH ROW
    EXECUTE FUNCTION update_cart_items_updated_at();

-- Trigger pour order_tracking
CREATE OR REPLACE FUNCTION update_order_tracking_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_order_tracking_updated_at ON order_tracking;
CREATE TRIGGER trigger_order_tracking_updated_at
    BEFORE UPDATE ON order_tracking
    FOR EACH ROW
    EXECUTE FUNCTION update_order_tracking_updated_at();

-- Trigger pour order_analytics_daily
CREATE OR REPLACE FUNCTION update_order_analytics_daily_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_order_analytics_daily_updated_at ON order_analytics_daily;
CREATE TRIGGER trigger_order_analytics_daily_updated_at
    BEFORE UPDATE ON order_analytics_daily
    FOR EACH ROW
    EXECUTE FUNCTION update_order_analytics_daily_updated_at();

-- Trigger pour delivery_zones
CREATE OR REPLACE FUNCTION update_delivery_zones_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_delivery_zones_updated_at ON delivery_zones;
CREATE TRIGGER trigger_delivery_zones_updated_at
    BEFORE UPDATE ON delivery_zones
    FOR EACH ROW
    EXECUTE FUNCTION update_delivery_zones_updated_at();

-- Trigger pour delivery_time_slots
CREATE OR REPLACE FUNCTION update_delivery_time_slots_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_delivery_time_slots_updated_at ON delivery_time_slots;
CREATE TRIGGER trigger_delivery_time_slots_updated_at
    BEFORE UPDATE ON delivery_time_slots
    FOR EACH ROW
    EXECUTE FUNCTION update_delivery_time_slots_updated_at();

-- Trigger pour générer le numéro de commande
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.order_number IS NULL THEN
        NEW.order_number = 'ORD-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(NEXTVAL('order_number_seq')::TEXT, 6, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Créer la séquence si elle n'existe pas
CREATE SEQUENCE IF NOT EXISTS order_number_seq START 1;

DROP TRIGGER IF EXISTS trigger_generate_order_number ON orders;
CREATE TRIGGER trigger_generate_order_number
    BEFORE INSERT ON orders
    FOR EACH ROW
    EXECUTE FUNCTION generate_order_number();

-- Align orders.status CHECK with order-service STATUS_CHAIN (run as DB superuser / table owner).
-- Freebox / prod: sudo -u postgres psql -d mytestpatisry -v ON_ERROR_STOP=1 -f scripts/apply_order_status_constraint.sql

ALTER TABLE orders DROP CONSTRAINT IF EXISTS chk_order_status_valid;

ALTER TABLE orders ADD CONSTRAINT chk_order_status_valid CHECK (
  status IN (
    'pending_confirmation',
    'in_preparation',
    'ready',
    'awaiting_pickup',
    'out_for_delivery',
    'delivered',
    'completed',
    'cancelled',
    'pending',
    'confirmed',
    'processing',
    'shipped'
  )
);


-- =====================================================
-- VUES utiles
-- =====================================================

-- Vue pour les commandes avec informations complètes
CREATE OR REPLACE VIEW order_complete_info AS
SELECT 
    o.*,
    au.email as customer_email,
    au.first_name as customer_first_name,
    au.last_name as customer_last_name,
    au.phone_number as customer_phone,
    b.userid as baker_user_id,
    bau.first_name as baker_first_name,
    bau.last_name as baker_last_name,
    bau.email as baker_email,
    bau.phone_number as baker_phone,
    COUNT(DISTINCT od.id) as items_count,
    SUM(od.quantity) as total_quantity
FROM orders o
JOIN accounts_user au ON o.userid = au.id
LEFT JOIN baker b ON o.baker_id = b.id
LEFT JOIN accounts_user bau ON b.userid = bau.id
LEFT JOIN order_detail od ON o.id = od.orderid
GROUP BY o.id, au.email, au.first_name, au.last_name, au.phone_number, 
         b.userid, bau.first_name, bau.last_name, bau.email, bau.phone_number;

-- Vue pour les paniers actifs
CREATE OR REPLACE VIEW active_carts AS
SELECT 
    c.*,
    au.email as user_email,
    au.first_name as user_first_name,
    au.last_name as user_last_name,
    COUNT(DISTINCT ci.id) as items_count,
    SUM(ci.total_price) as total_price
FROM cart c
JOIN accounts_user au ON c.user_id = au.id
LEFT JOIN cart_items ci ON c.id = ci.cart_id
WHERE c.is_active = TRUE
GROUP BY c.id, au.email, au.first_name, au.last_name;

-- Vue pour les statistiques des commandes
CREATE OR REPLACE VIEW order_stats AS
SELECT 
    DATE(created_at) as order_date,
    COUNT(*) as total_orders,
    SUM(total_price) as total_revenue,
    AVG(total_price) as average_order_value,
    COUNT(*) FILTER (WHERE status = 'delivered') as delivered_orders,
    COUNT(*) FILTER (WHERE status = 'cancelled') as cancelled_orders,
    AVG(rating) FILTER (WHERE rating IS NOT NULL) as average_rating
FROM orders
GROUP BY DATE(created_at)
ORDER BY order_date DESC;

COMMENT ON VIEW order_complete_info IS 'Informations complètes des commandes avec détails client et pâtissier';
COMMENT ON VIEW active_carts IS 'Paniers actifs avec informations utilisateur et totaux';
COMMENT ON VIEW order_stats IS 'Statistiques quotidiennes des commandes';
