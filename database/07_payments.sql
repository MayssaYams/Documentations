-- =====================================================
-- 07_payments.sql
-- Tables paiements, méthodes de paiement et promotions
-- =====================================================

-- Extension pour UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- TABLE: payment_method (méthodes de paiement)
-- =====================================================

-- Création de la table payment_method si elle n'existe pas
CREATE TABLE IF NOT EXISTS payment_method (
    id SERIAL PRIMARY KEY,
    userid INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE,
    method_name VARCHAR(100) NOT NULL,
    details TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_default BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    expiry_date DATE,
    card_last_four VARCHAR(4),
    card_brand VARCHAR(20), -- 'visa', 'mastercard', 'amex', etc.
    billing_address JSONB,
    is_verified BOOLEAN DEFAULT FALSE,
    verification_date TIMESTAMP WITH TIME ZONE
);

COMMENT ON TABLE payment_method IS 'Méthodes de paiement des utilisateurs';
COMMENT ON COLUMN payment_method.userid IS 'Utilisateur propriétaire de la méthode de paiement';
COMMENT ON COLUMN payment_method.method_name IS 'Nom de la méthode (Carte bancaire, PayPal, etc.)';
COMMENT ON COLUMN payment_method.details IS 'Détails de la méthode de paiement (chiffrés)';
COMMENT ON COLUMN payment_method.is_default IS 'Méthode de paiement par défaut';
COMMENT ON COLUMN payment_method.card_last_four IS '4 derniers chiffres de la carte';
COMMENT ON COLUMN payment_method.card_brand IS 'Marque de la carte (visa, mastercard, amex)';

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_payment_method_userid ON payment_method(userid);
CREATE INDEX IF NOT EXISTS idx_payment_method_is_default ON payment_method(userid, is_default) WHERE is_default = TRUE;
CREATE INDEX IF NOT EXISTS idx_payment_method_is_active ON payment_method(is_active);

-- Ajout de colonnes manquantes si elles n'existent pas
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_method' AND column_name = 'is_default') THEN
        ALTER TABLE payment_method ADD COLUMN is_default BOOLEAN DEFAULT FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_method' AND column_name = 'is_active') THEN
        ALTER TABLE payment_method ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_method' AND column_name = 'expiry_date') THEN
        ALTER TABLE payment_method ADD COLUMN expiry_date DATE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_method' AND column_name = 'card_last_four') THEN
        ALTER TABLE payment_method ADD COLUMN card_last_four VARCHAR(4);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_method' AND column_name = 'card_brand') THEN
        ALTER TABLE payment_method ADD COLUMN card_brand VARCHAR(20); -- 'visa', 'mastercard', 'amex', etc.
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_method' AND column_name = 'billing_address') THEN
        ALTER TABLE payment_method ADD COLUMN billing_address JSONB;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_method' AND column_name = 'is_verified') THEN
        ALTER TABLE payment_method ADD COLUMN is_verified BOOLEAN DEFAULT FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payment_method' AND column_name = 'verification_date') THEN
        ALTER TABLE payment_method ADD COLUMN verification_date TIMESTAMP WITH TIME ZONE;
    END IF;
END $$;

-- =====================================================
-- TABLE: payments (transactions de paiement)
-- =====================================================

CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE,
    payment_method_id INTEGER REFERENCES payment_method(id) ON DELETE SET NULL,
    payment_provider VARCHAR(50) NOT NULL, -- 'stripe', 'paypal', 'apple_pay', 'google_pay', 'bank_transfer'
    external_payment_id VARCHAR(255), -- ID du paiement chez le fournisseur
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'EUR',
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded'
    payment_type VARCHAR(20) DEFAULT 'payment', -- 'payment', 'refund', 'partial_refund'
    failure_reason TEXT,
    metadata JSONB, -- Données supplémentaires du fournisseur
    processed_at TIMESTAMP WITH TIME ZONE,
    failed_at TIMESTAMP WITH TIME ZONE,
    refunded_at TIMESTAMP WITH TIME ZONE,
    refund_amount DECIMAL(10,2) DEFAULT 0,
    refund_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE payments IS 'Transactions de paiement avec statuts et métadonnées';
COMMENT ON COLUMN payments.payment_provider IS 'Fournisseur de paiement (stripe, paypal, apple_pay, google_pay)';
COMMENT ON COLUMN payments.payment_type IS 'Type de transaction (payment, refund, partial_refund)';

-- =====================================================
-- TABLE: payment_transactions (historique des transactions)
-- =====================================================

CREATE TABLE IF NOT EXISTS payment_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payment_id UUID REFERENCES payments(id) ON DELETE CASCADE,
    transaction_type VARCHAR(20) NOT NULL, -- 'charge', 'refund', 'void', 'capture'
    amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) NOT NULL, -- 'pending', 'succeeded', 'failed', 'cancelled'
    external_transaction_id VARCHAR(255),
    gateway_response JSONB, -- Réponse complète du gateway
    error_code VARCHAR(50),
    error_message TEXT,
    processed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE payment_transactions IS 'Historique détaillé des transactions de paiement';
COMMENT ON COLUMN payment_transactions.transaction_type IS 'Type de transaction (charge, refund, void, capture)';
COMMENT ON COLUMN payment_transactions.gateway_response IS 'Réponse complète du gateway de paiement';

-- =====================================================
-- TABLE: promotion (codes promotionnels)
-- =====================================================

-- Création de la table promotion si elle n'existe pas
CREATE TABLE IF NOT EXISTS promotion (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    discount_value DECIMAL(10,2) NOT NULL,
    discount_type VARCHAR(20) DEFAULT 'percentage', -- 'percentage', 'fixed_amount', 'free_shipping'
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    usage_limit INTEGER,
    usage_count INTEGER DEFAULT 0,
    min_order_amount DECIMAL(10,2),
    max_discount_amount DECIMAL(10,2),
    applicable_products JSONB, -- IDs des produits applicables
    applicable_bakers JSONB, -- IDs des pâtissiers applicables
    applicable_users JSONB, -- IDs des utilisateurs applicables
    created_by INTEGER REFERENCES accounts_user(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE promotion IS 'Codes promotionnels et réductions';
COMMENT ON COLUMN promotion.code IS 'Code promotionnel unique';
COMMENT ON COLUMN promotion.discount_type IS 'Type de réduction (percentage, fixed_amount, free_shipping)';

-- Ajout de colonnes manquantes si elles n'existent pas
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'promotion' AND column_name = 'is_active') THEN
        ALTER TABLE promotion ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'promotion' AND column_name = 'usage_limit') THEN
        ALTER TABLE promotion ADD COLUMN usage_limit INTEGER;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'promotion' AND column_name = 'usage_count') THEN
        ALTER TABLE promotion ADD COLUMN usage_count INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'promotion' AND column_name = 'min_order_amount') THEN
        ALTER TABLE promotion ADD COLUMN min_order_amount DECIMAL(10,2);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'promotion' AND column_name = 'max_discount_amount') THEN
        ALTER TABLE promotion ADD COLUMN max_discount_amount DECIMAL(10,2);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'promotion' AND column_name = 'applicable_products') THEN
        ALTER TABLE promotion ADD COLUMN applicable_products JSONB; -- IDs des produits applicables
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'promotion' AND column_name = 'applicable_bakers') THEN
        ALTER TABLE promotion ADD COLUMN applicable_bakers JSONB; -- IDs des pâtissiers applicables
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'promotion' AND column_name = 'applicable_users') THEN
        ALTER TABLE promotion ADD COLUMN applicable_users JSONB; -- IDs des utilisateurs applicables
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'promotion' AND column_name = 'promotion_type') THEN
        ALTER TABLE promotion ADD COLUMN promotion_type VARCHAR(20) DEFAULT 'percentage'; -- 'percentage', 'fixed_amount', 'free_shipping'
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'promotion' AND column_name = 'created_by') THEN
        ALTER TABLE promotion ADD COLUMN created_by INTEGER REFERENCES accounts_user(id);
    END IF;
END $$;

-- =====================================================
-- TABLE: promotion_usage (utilisation des promotions)
-- =====================================================

CREATE TABLE IF NOT EXISTS promotion_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    promotion_id INTEGER REFERENCES promotion(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE,
    order_id INTEGER, -- FK vers orders sera ajoutée dans 10_indexes_and_constraints.sql
    discount_amount DECIMAL(10,2) NOT NULL,
    used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE promotion_usage IS 'Historique d utilisation des promotions par utilisateur';

-- =====================================================
-- TABLE: payment_analytics_daily (analytics quotidiennes des paiements)
-- =====================================================

CREATE TABLE IF NOT EXISTS payment_analytics_daily (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE NOT NULL,
    -- Métriques globales
    total_transactions INTEGER DEFAULT 0,
    total_amount DECIMAL(12,2) DEFAULT 0,
    successful_transactions INTEGER DEFAULT 0,
    failed_transactions INTEGER DEFAULT 0,
    refunded_transactions INTEGER DEFAULT 0,
    -- Métriques par fournisseur
    stripe_transactions INTEGER DEFAULT 0,
    stripe_amount DECIMAL(12,2) DEFAULT 0,
    paypal_transactions INTEGER DEFAULT 0,
    paypal_amount DECIMAL(12,2) DEFAULT 0,
    apple_pay_transactions INTEGER DEFAULT 0,
    apple_pay_amount DECIMAL(12,2) DEFAULT 0,
    google_pay_transactions INTEGER DEFAULT 0,
    google_pay_amount DECIMAL(12,2) DEFAULT 0,
    -- Métriques de performance
    success_rate DECIMAL(5,2) DEFAULT 0, -- % de transactions réussies
    average_transaction_amount DECIMAL(10,2) DEFAULT 0,
    refund_rate DECIMAL(5,2) DEFAULT 0, -- % de transactions remboursées
    -- Métadonnées
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(date)
);

COMMENT ON TABLE payment_analytics_daily IS 'Analytics quotidiennes des paiements par fournisseur';
COMMENT ON COLUMN payment_analytics_daily.success_rate IS 'Pourcentage de transactions réussies';

-- =====================================================
-- TABLE: payment_fees (frais de paiement)
-- =====================================================

CREATE TABLE IF NOT EXISTS payment_fees (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payment_id UUID REFERENCES payments(id) ON DELETE CASCADE,
    fee_type VARCHAR(50) NOT NULL, -- 'processing', 'gateway', 'platform', 'refund'
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'EUR',
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE payment_fees IS 'Frais associés aux paiements';
COMMENT ON COLUMN payment_fees.fee_type IS 'Type de frais (processing, gateway, platform, refund)';

-- =====================================================
-- TABLE: payment_methods_analytics (analytics des méthodes de paiement)
-- =====================================================

CREATE TABLE IF NOT EXISTS payment_methods_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE,
    payment_method_id INTEGER REFERENCES payment_method(id) ON DELETE CASCADE,
    usage_count INTEGER DEFAULT 0,
    total_amount DECIMAL(12,2) DEFAULT 0,
    last_used_at TIMESTAMP WITH TIME ZONE,
    success_rate DECIMAL(5,2) DEFAULT 0,
    failure_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, payment_method_id)
);

COMMENT ON TABLE payment_methods_analytics IS 'Analytics d utilisation des méthodes de paiement par utilisateur';

-- =====================================================
-- INDEX pour les performances
-- =====================================================

-- Index pour payment_method
CREATE INDEX IF NOT EXISTS idx_payment_method_user_id ON payment_method(userid);
CREATE INDEX IF NOT EXISTS idx_payment_method_active ON payment_method(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_payment_method_default ON payment_method(userid, is_default) WHERE is_default = TRUE;
CREATE INDEX IF NOT EXISTS idx_payment_method_expiry ON payment_method(expiry_date);

-- Index pour payments
CREATE INDEX IF NOT EXISTS idx_payments_order_id ON payments(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_user_id ON payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_method_id ON payments(payment_method_id);
CREATE INDEX IF NOT EXISTS idx_payments_provider ON payments(payment_provider);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_external_id ON payments(external_payment_id);
CREATE INDEX IF NOT EXISTS idx_payments_created_at ON payments(created_at);

-- Index pour payment_transactions
CREATE INDEX IF NOT EXISTS idx_payment_transactions_payment_id ON payment_transactions(payment_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_type ON payment_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON payment_transactions(status);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_external_id ON payment_transactions(external_transaction_id);

-- Index pour promotion
CREATE INDEX IF NOT EXISTS idx_promotion_code ON promotion(code);
CREATE INDEX IF NOT EXISTS idx_promotion_active ON promotion(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_promotion_dates ON promotion(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_promotion_type ON promotion(promotion_type);

-- Index pour promotion_usage
CREATE INDEX IF NOT EXISTS idx_promotion_usage_promotion_id ON promotion_usage(promotion_id);
CREATE INDEX IF NOT EXISTS idx_promotion_usage_user_id ON promotion_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_promotion_usage_order_id ON promotion_usage(order_id);
CREATE INDEX IF NOT EXISTS idx_promotion_usage_used_at ON promotion_usage(used_at);

-- Index pour payment_analytics_daily
CREATE INDEX IF NOT EXISTS idx_payment_analytics_daily_date ON payment_analytics_daily(date);

-- Index pour payment_fees
CREATE INDEX IF NOT EXISTS idx_payment_fees_payment_id ON payment_fees(payment_id);
CREATE INDEX IF NOT EXISTS idx_payment_fees_type ON payment_fees(fee_type);

-- Index pour payment_methods_analytics
CREATE INDEX IF NOT EXISTS idx_payment_methods_analytics_user_id ON payment_methods_analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_methods_analytics_method_id ON payment_methods_analytics(payment_method_id);

-- =====================================================
-- TRIGGERS pour updated_at et compteurs
-- =====================================================

-- Trigger pour payments
CREATE OR REPLACE FUNCTION update_payments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_payments_updated_at ON payments;
CREATE TRIGGER trigger_payments_updated_at
    BEFORE UPDATE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION update_payments_updated_at();

-- Trigger pour payment_analytics_daily
CREATE OR REPLACE FUNCTION update_payment_analytics_daily_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_payment_analytics_daily_updated_at ON payment_analytics_daily;
CREATE TRIGGER trigger_payment_analytics_daily_updated_at
    BEFORE UPDATE ON payment_analytics_daily
    FOR EACH ROW
    EXECUTE FUNCTION update_payment_analytics_daily_updated_at();

-- Trigger pour payment_methods_analytics
CREATE OR REPLACE FUNCTION update_payment_methods_analytics_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_payment_methods_analytics_updated_at ON payment_methods_analytics;
CREATE TRIGGER trigger_payment_methods_analytics_updated_at
    BEFORE UPDATE ON payment_methods_analytics
    FOR EACH ROW
    EXECUTE FUNCTION update_payment_methods_analytics_updated_at();

-- Trigger pour mettre à jour les compteurs
CREATE OR REPLACE FUNCTION update_payment_counters()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_TABLE_NAME = 'promotion_usage' THEN
        IF TG_OP = 'INSERT' THEN
            -- Incrémenter le compteur d'utilisation de la promotion
            UPDATE promotion SET usage_count = usage_count + 1 WHERE id = NEW.promotion_id;
        ELSIF TG_OP = 'DELETE' THEN
            -- Décrémenter le compteur d'utilisation de la promotion
            UPDATE promotion SET usage_count = usage_count - 1 WHERE id = OLD.promotion_id;
        END IF;
        
    ELSIF TG_TABLE_NAME = 'payments' THEN
        IF TG_OP = 'INSERT' THEN
            -- Mettre à jour les analytics de la méthode de paiement
            INSERT INTO payment_methods_analytics (user_id, payment_method_id, usage_count, total_amount, last_used_at)
            VALUES (NEW.user_id, NEW.payment_method_id, 1, NEW.amount, NOW())
            ON CONFLICT (user_id, payment_method_id) DO UPDATE SET
                usage_count = payment_methods_analytics.usage_count + 1,
                total_amount = payment_methods_analytics.total_amount + NEW.amount,
                last_used_at = NOW(),
                updated_at = NOW();
                
        ELSIF TG_OP = 'UPDATE' THEN
            -- Si le paiement échoue, incrémenter le compteur d'échecs
            IF OLD.status != 'failed' AND NEW.status = 'failed' THEN
                UPDATE payment_methods_analytics SET
                    failure_count = failure_count + 1,
                    updated_at = NOW()
                WHERE user_id = NEW.user_id AND payment_method_id = NEW.payment_method_id;
            END IF;
        END IF;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_promotion_usage_counters ON promotion_usage;
CREATE TRIGGER trigger_promotion_usage_counters
    AFTER INSERT OR DELETE ON promotion_usage
    FOR EACH ROW
    EXECUTE FUNCTION update_payment_counters();

DROP TRIGGER IF EXISTS trigger_payments_counters ON payments;
CREATE TRIGGER trigger_payments_counters
    AFTER INSERT OR UPDATE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION update_payment_counters();

-- =====================================================
-- VUES utiles
-- =====================================================

-- Vue pour les paiements avec informations complètes
CREATE OR REPLACE VIEW payments_complete AS
SELECT 
    p.*,
    o.order_number,
    o.status as order_status,
    au.email as user_email,
    au.first_name as user_first_name,
    au.last_name as user_last_name,
    pm.method_name as payment_method_name,
    pm.card_last_four,
    pm.card_brand,
    COUNT(DISTINCT pt.id) as transactions_count,
    COUNT(DISTINCT pf.id) as fees_count,
    SUM(pf.amount) as total_fees
FROM payments p
JOIN orders o ON p.order_id = o.id
JOIN accounts_user au ON p.user_id = au.id
LEFT JOIN payment_method pm ON p.payment_method_id = pm.id
LEFT JOIN payment_transactions pt ON p.id = pt.payment_id
LEFT JOIN payment_fees pf ON p.id = pf.payment_id
GROUP BY p.id, o.order_number, o.status, au.email, au.first_name, au.last_name, 
         pm.method_name, pm.card_last_four, pm.card_brand;

-- Vue pour les méthodes de paiement avec analytics
CREATE OR REPLACE VIEW payment_methods_with_analytics AS
SELECT 
    pm.*,
    au.email as user_email,
    au.first_name as user_first_name,
    au.last_name as user_last_name,
    pma.usage_count,
    pma.total_amount,
    pma.last_used_at,
    pma.success_rate,
    pma.failure_count,
    CASE 
        WHEN pm.expiry_date IS NOT NULL AND pm.expiry_date < CURRENT_DATE THEN 'expired'
        WHEN pm.expiry_date IS NOT NULL AND pm.expiry_date < CURRENT_DATE + INTERVAL '30 days' THEN 'expiring_soon'
        ELSE 'valid'
    END as expiry_status
FROM payment_method pm
JOIN accounts_user au ON pm.userid = au.id
LEFT JOIN payment_methods_analytics pma ON pm.id = pma.payment_method_id AND au.id = pma.user_id
WHERE pm.is_active = TRUE;

-- Vue pour les promotions actives
CREATE OR REPLACE VIEW active_promotions AS
SELECT 
    p.*,
    cb.first_name as created_by_first_name,
    cb.last_name as created_by_last_name,
    cb.email as created_by_email,
    COUNT(DISTINCT pu.id) as actual_usage_count,
    CASE 
        WHEN p.usage_limit IS NOT NULL THEN p.usage_limit - COUNT(DISTINCT pu.id)
        ELSE NULL
    END as remaining_uses
FROM promotion p
LEFT JOIN accounts_user cb ON p.created_by = cb.id
LEFT JOIN promotion_usage pu ON p.id = pu.promotion_id
WHERE p.is_active = TRUE 
AND p.start_date <= CURRENT_DATE 
AND p.end_date >= CURRENT_DATE
GROUP BY p.id, cb.first_name, cb.last_name, cb.email;

-- Vue pour les statistiques des paiements
CREATE OR REPLACE VIEW payment_stats AS
SELECT 
    DATE(created_at) as payment_date,
    COUNT(*) as total_payments,
    SUM(amount) as total_amount,
    COUNT(*) FILTER (WHERE status = 'completed') as successful_payments,
    COUNT(*) FILTER (WHERE status = 'failed') as failed_payments,
    COUNT(*) FILTER (WHERE status = 'refunded') as refunded_payments,
    AVG(amount) FILTER (WHERE status = 'completed') as average_amount,
    SUM(amount) FILTER (WHERE status = 'completed') as successful_amount,
    SUM(refund_amount) as total_refunds
FROM payments
GROUP BY DATE(created_at)
ORDER BY payment_date DESC;

COMMENT ON VIEW payments_complete IS 'Paiements avec informations complètes et métadonnées';
COMMENT ON VIEW payment_methods_with_analytics IS 'Méthodes de paiement avec analytics et statut d expiration';
COMMENT ON VIEW active_promotions IS 'Promotions actives avec compteurs d utilisation';
COMMENT ON VIEW payment_stats IS 'Statistiques quotidiennes des paiements';
