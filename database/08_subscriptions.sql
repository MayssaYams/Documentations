-- =====================================================
-- 08_subscriptions.sql
-- Tables abonnements, plans et analytics
-- =====================================================

-- Extension pour UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- TABLE: subscription_plans (plans d'abonnement)
-- =====================================================

CREATE TABLE IF NOT EXISTS subscription_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    plan_type VARCHAR(50) NOT NULL, -- 'basic', 'premium', 'pro', 'enterprise'
    billing_cycle VARCHAR(20) NOT NULL, -- 'monthly', 'yearly', 'weekly'
    price DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'EUR',
    trial_days INTEGER DEFAULT 0, -- Jours d'essai gratuits
    max_orders INTEGER, -- Nombre maximum de commandes par mois
    max_products INTEGER, -- Nombre maximum de produits
    max_bakers INTEGER, -- Nombre maximum de pâtissiers (pour les entreprises)
    features JSONB, -- Liste des fonctionnalités incluses
    limitations JSONB, -- Limitations du plan
    is_active BOOLEAN DEFAULT TRUE,
    is_popular BOOLEAN DEFAULT FALSE, -- Plan populaire/mis en avant
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE subscription_plans IS 'Plans d abonnement avec fonctionnalités et limitations';
COMMENT ON COLUMN subscription_plans.plan_type IS 'Type de plan (basic, premium, pro, enterprise)';
COMMENT ON COLUMN subscription_plans.features IS 'Fonctionnalités incluses dans le plan';
COMMENT ON COLUMN subscription_plans.limitations IS 'Limitations du plan';

-- =====================================================
-- TABLE: user_subscriptions (abonnements des utilisateurs)
-- =====================================================

CREATE TABLE IF NOT EXISTS user_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE,
    plan_id UUID REFERENCES subscription_plans(id) ON DELETE CASCADE,
    subscription_type VARCHAR(20) DEFAULT 'user', -- 'user', 'baker', 'enterprise'
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'cancelled', 'expired', 'suspended', 'trial'
    billing_cycle VARCHAR(20) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'EUR',
    start_date DATE NOT NULL,
    end_date DATE,
    next_billing_date DATE,
    trial_start_date DATE,
    trial_end_date DATE,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancellation_reason TEXT,
    auto_renew BOOLEAN DEFAULT TRUE,
    payment_method_id INTEGER REFERENCES payment_method(id) ON DELETE SET NULL,
    external_subscription_id VARCHAR(255), -- ID chez le fournisseur de paiement
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE user_subscriptions IS 'Abonnements des utilisateurs avec détails de facturation';
COMMENT ON COLUMN user_subscriptions.subscription_type IS 'Type d abonnement (user, baker, enterprise)';
COMMENT ON COLUMN user_subscriptions.external_subscription_id IS 'ID de l abonnement chez le fournisseur de paiement';

-- =====================================================
-- TABLE: subscription_billing (facturation des abonnements)
-- =====================================================

CREATE TABLE IF NOT EXISTS subscription_billing (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscription_id UUID REFERENCES user_subscriptions(id) ON DELETE CASCADE,
    billing_period_start DATE NOT NULL,
    billing_period_end DATE NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'EUR',
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'paid', 'failed', 'refunded'
    payment_id UUID REFERENCES payments(id) ON DELETE SET NULL,
    invoice_number VARCHAR(100),
    invoice_url VARCHAR(500),
    due_date DATE,
    paid_at TIMESTAMP WITH TIME ZONE,
    failed_at TIMESTAMP WITH TIME ZONE,
    failure_reason TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE subscription_billing IS 'Facturation des abonnements par période';
COMMENT ON COLUMN subscription_billing.invoice_url IS 'URL de la facture PDF';

-- =====================================================
-- TABLE: subscription_usage (utilisation des abonnements)
-- =====================================================

CREATE TABLE IF NOT EXISTS subscription_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscription_id UUID REFERENCES user_subscriptions(id) ON DELETE CASCADE,
    usage_type VARCHAR(50) NOT NULL, -- 'orders', 'products', 'storage', 'api_calls'
    usage_count INTEGER DEFAULT 0,
    limit_count INTEGER, -- Limite du plan
    billing_period_start DATE NOT NULL,
    billing_period_end DATE NOT NULL,
    is_over_limit BOOLEAN DEFAULT FALSE,
    overage_amount DECIMAL(10,2) DEFAULT 0, -- Montant des dépassements
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(subscription_id, usage_type, billing_period_start)
);

COMMENT ON TABLE subscription_usage IS 'Utilisation des quotas d abonnement par période';
COMMENT ON COLUMN subscription_usage.usage_type IS 'Type d utilisation (orders, products, storage, api_calls)';
COMMENT ON COLUMN subscription_usage.overage_amount IS 'Montant des dépassements de quota';

-- =====================================================
-- TABLE: subscription_analytics_daily (analytics quotidiennes des abonnements)
-- =====================================================

CREATE TABLE IF NOT EXISTS subscription_analytics_daily (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE NOT NULL,
    -- Métriques globales
    total_subscriptions INTEGER DEFAULT 0,
    active_subscriptions INTEGER DEFAULT 0,
    trial_subscriptions INTEGER DEFAULT 0,
    cancelled_subscriptions INTEGER DEFAULT 0,
    expired_subscriptions INTEGER DEFAULT 0,
    -- Métriques de revenus
    total_revenue DECIMAL(12,2) DEFAULT 0,
    monthly_revenue DECIMAL(12,2) DEFAULT 0,
    yearly_revenue DECIMAL(12,2) DEFAULT 0,
    -- Métriques par plan
    basic_subscriptions INTEGER DEFAULT 0,
    premium_subscriptions INTEGER DEFAULT 0,
    pro_subscriptions INTEGER DEFAULT 0,
    enterprise_subscriptions INTEGER DEFAULT 0,
    -- Métriques de conversion
    trial_to_paid_conversions INTEGER DEFAULT 0,
    conversion_rate DECIMAL(5,2) DEFAULT 0, -- % de conversion essai vers payant
    churn_rate DECIMAL(5,2) DEFAULT 0, -- % de désabonnement
    -- Métadonnées
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(date)
);

COMMENT ON TABLE subscription_analytics_daily IS 'Analytics quotidiennes des abonnements';
COMMENT ON COLUMN subscription_analytics_daily.conversion_rate IS 'Pourcentage de conversion essai vers payant';
COMMENT ON COLUMN subscription_analytics_daily.churn_rate IS 'Pourcentage de désabonnement';

-- =====================================================
-- TABLE: subscription_features (fonctionnalités des abonnements)
-- =====================================================

CREATE TABLE IF NOT EXISTS subscription_features (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_id UUID REFERENCES subscription_plans(id) ON DELETE CASCADE,
    feature_name VARCHAR(100) NOT NULL,
    feature_description TEXT,
    is_included BOOLEAN DEFAULT TRUE,
    limit_value INTEGER, -- Valeur limite (ex: 100 commandes)
    limit_type VARCHAR(20), -- 'count', 'storage', 'duration'
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE subscription_features IS 'Fonctionnalités détaillées des plans d abonnement';
COMMENT ON COLUMN subscription_features.limit_type IS 'Type de limite (count, storage, duration)';

-- =====================================================
-- TABLE: subscription_discounts (remises sur les abonnements)
-- =====================================================

CREATE TABLE IF NOT EXISTS subscription_discounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_id UUID REFERENCES subscription_plans(id) ON DELETE CASCADE,
    discount_code VARCHAR(50) UNIQUE,
    discount_type VARCHAR(20) NOT NULL, -- 'percentage', 'fixed_amount'
    discount_value DECIMAL(10,2) NOT NULL,
    max_uses INTEGER,
    used_count INTEGER DEFAULT 0,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE subscription_discounts IS 'Codes de remise pour les abonnements';
COMMENT ON COLUMN subscription_discounts.discount_type IS 'Type de remise (percentage, fixed_amount)';

-- =====================================================
-- TABLE: subscription_discount_usage (utilisation des remises)
-- =====================================================

CREATE TABLE IF NOT EXISTS subscription_discount_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    discount_id UUID REFERENCES subscription_discounts(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES user_subscriptions(id) ON DELETE CASCADE,
    discount_amount DECIMAL(10,2) NOT NULL,
    used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE subscription_discount_usage IS 'Historique d utilisation des remises d abonnement';

-- =====================================================
-- INDEX pour les performances
-- =====================================================

-- Index pour subscription_plans
CREATE INDEX IF NOT EXISTS idx_subscription_plans_type ON subscription_plans(plan_type);
CREATE INDEX IF NOT EXISTS idx_subscription_plans_active ON subscription_plans(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_subscription_plans_popular ON subscription_plans(is_popular) WHERE is_popular = TRUE;
CREATE INDEX IF NOT EXISTS idx_subscription_plans_sort ON subscription_plans(sort_order);

-- Index pour user_subscriptions
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user_id ON user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_plan_id ON user_subscriptions(plan_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_status ON user_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_type ON user_subscriptions(subscription_type);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_end_date ON user_subscriptions(end_date);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_next_billing ON user_subscriptions(next_billing_date);

-- Index pour subscription_billing
CREATE INDEX IF NOT EXISTS idx_subscription_billing_subscription_id ON subscription_billing(subscription_id);
CREATE INDEX IF NOT EXISTS idx_subscription_billing_status ON subscription_billing(status);
CREATE INDEX IF NOT EXISTS idx_subscription_billing_period ON subscription_billing(billing_period_start, billing_period_end);
CREATE INDEX IF NOT EXISTS idx_subscription_billing_due_date ON subscription_billing(due_date);

-- Index pour subscription_usage
CREATE INDEX IF NOT EXISTS idx_subscription_usage_subscription_id ON subscription_usage(subscription_id);
CREATE INDEX IF NOT EXISTS idx_subscription_usage_type ON subscription_usage(usage_type);
CREATE INDEX IF NOT EXISTS idx_subscription_usage_period ON subscription_usage(billing_period_start, billing_period_end);
CREATE INDEX IF NOT EXISTS idx_subscription_usage_over_limit ON subscription_usage(is_over_limit) WHERE is_over_limit = TRUE;

-- Index pour subscription_analytics_daily
CREATE INDEX IF NOT EXISTS idx_subscription_analytics_daily_date ON subscription_analytics_daily(date);

-- Index pour subscription_features
CREATE INDEX IF NOT EXISTS idx_subscription_features_plan_id ON subscription_features(plan_id);
CREATE INDEX IF NOT EXISTS idx_subscription_features_included ON subscription_features(is_included) WHERE is_included = TRUE;

-- Index pour subscription_discounts
CREATE INDEX IF NOT EXISTS idx_subscription_discounts_plan_id ON subscription_discounts(plan_id);
CREATE INDEX IF NOT EXISTS idx_subscription_discounts_code ON subscription_discounts(discount_code);
CREATE INDEX IF NOT EXISTS idx_subscription_discounts_active ON subscription_discounts(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_subscription_discounts_dates ON subscription_discounts(start_date, end_date);

-- Index pour subscription_discount_usage
CREATE INDEX IF NOT EXISTS idx_subscription_discount_usage_discount_id ON subscription_discount_usage(discount_id);
CREATE INDEX IF NOT EXISTS idx_subscription_discount_usage_user_id ON subscription_discount_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_subscription_discount_usage_subscription_id ON subscription_discount_usage(subscription_id);

-- =====================================================
-- TRIGGERS pour updated_at et compteurs
-- =====================================================

-- Trigger pour subscription_plans
CREATE OR REPLACE FUNCTION update_subscription_plans_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_subscription_plans_updated_at
    BEFORE UPDATE ON subscription_plans
    FOR EACH ROW
    EXECUTE FUNCTION update_subscription_plans_updated_at();

-- Trigger pour user_subscriptions
CREATE OR REPLACE FUNCTION update_user_subscriptions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_user_subscriptions_updated_at
    BEFORE UPDATE ON user_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_user_subscriptions_updated_at();

-- Trigger pour subscription_billing
CREATE OR REPLACE FUNCTION update_subscription_billing_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_subscription_billing_updated_at
    BEFORE UPDATE ON subscription_billing
    FOR EACH ROW
    EXECUTE FUNCTION update_subscription_billing_updated_at();

-- Trigger pour subscription_usage
CREATE OR REPLACE FUNCTION update_subscription_usage_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_subscription_usage_updated_at
    BEFORE UPDATE ON subscription_usage
    FOR EACH ROW
    EXECUTE FUNCTION update_subscription_usage_updated_at();

-- Trigger pour subscription_analytics_daily
CREATE OR REPLACE FUNCTION update_subscription_analytics_daily_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_subscription_analytics_daily_updated_at
    BEFORE UPDATE ON subscription_analytics_daily
    FOR EACH ROW
    EXECUTE FUNCTION update_subscription_analytics_daily_updated_at();

-- Trigger pour subscription_discounts
CREATE OR REPLACE FUNCTION update_subscription_discounts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_subscription_discounts_updated_at
    BEFORE UPDATE ON subscription_discounts
    FOR EACH ROW
    EXECUTE FUNCTION update_subscription_discounts_updated_at();

-- Trigger pour mettre à jour les compteurs
CREATE OR REPLACE FUNCTION update_subscription_counters()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_TABLE_NAME = 'subscription_discount_usage' THEN
        IF TG_OP = 'INSERT' THEN
            -- Incrémenter le compteur d'utilisation de la remise
            UPDATE subscription_discounts SET used_count = used_count + 1 WHERE id = NEW.discount_id;
        ELSIF TG_OP = 'DELETE' THEN
            -- Décrémenter le compteur d'utilisation de la remise
            UPDATE subscription_discounts SET used_count = used_count - 1 WHERE id = OLD.discount_id;
        END IF;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_subscription_discount_usage_counters
    AFTER INSERT OR DELETE ON subscription_discount_usage
    FOR EACH ROW
    EXECUTE FUNCTION update_subscription_counters();

-- =====================================================
-- VUES utiles
-- =====================================================

-- Vue pour les abonnements avec informations complètes
CREATE OR REPLACE VIEW subscriptions_complete AS
SELECT 
    us.*,
    au.email as user_email,
    au.first_name as user_first_name,
    au.last_name as user_last_name,
    sp.name as plan_name,
    sp.plan_type,
    sp.billing_cycle as plan_billing_cycle,
    sp.price as plan_price,
    sp.features as plan_features,
    sp.limitations as plan_limitations,
    pm.method_name as payment_method_name,
    COUNT(DISTINCT sb.id) as billing_count,
    SUM(sb.amount) as total_billed,
    MAX(sb.billing_period_end) as last_billing_period
FROM user_subscriptions us
JOIN accounts_user au ON us.user_id = au.id
JOIN subscription_plans sp ON us.plan_id = sp.id
LEFT JOIN payment_method pm ON us.payment_method_id = pm.id
LEFT JOIN subscription_billing sb ON us.id = sb.subscription_id
GROUP BY us.id, au.email, au.first_name, au.last_name, sp.name, sp.plan_type, 
         sp.billing_cycle, sp.price, sp.features, sp.limitations, pm.method_name;

-- Vue pour les plans avec statistiques
CREATE OR REPLACE VIEW subscription_plans_with_stats AS
SELECT 
    sp.*,
    COUNT(DISTINCT us.id) as total_subscribers,
    COUNT(DISTINCT us.id) FILTER (WHERE us.status = 'active') as active_subscribers,
    COUNT(DISTINCT us.id) FILTER (WHERE us.status = 'trial') as trial_subscribers,
    COUNT(DISTINCT us.id) FILTER (WHERE us.status = 'cancelled') as cancelled_subscribers,
    AVG(us.price) as average_price,
    SUM(sb.amount) as total_revenue
FROM subscription_plans sp
LEFT JOIN user_subscriptions us ON sp.id = us.plan_id
LEFT JOIN subscription_billing sb ON us.id = sb.subscription_id AND sb.status = 'paid'
GROUP BY sp.id;

-- Vue pour les utilisateurs avec leurs abonnements
CREATE OR REPLACE VIEW users_with_subscriptions AS
SELECT 
    au.*,
    us.id as subscription_id,
    us.status as subscription_status,
    us.subscription_type,
    sp.name as plan_name,
    sp.plan_type,
    us.start_date as subscription_start,
    us.end_date as subscription_end,
    us.next_billing_date,
    us.price as subscription_price,
    us.currency as subscription_currency,
    CASE 
        WHEN us.status = 'trial' AND us.trial_end_date < CURRENT_DATE THEN 'trial_expired'
        WHEN us.status = 'active' AND us.end_date < CURRENT_DATE THEN 'expired'
        WHEN us.status = 'active' AND us.end_date < CURRENT_DATE + INTERVAL '7 days' THEN 'expiring_soon'
        ELSE us.status
    END as subscription_status_detailed
FROM accounts_user au
LEFT JOIN user_subscriptions us ON au.id = us.user_id AND us.status IN ('active', 'trial')
LEFT JOIN subscription_plans sp ON us.plan_id = sp.id;

-- Vue pour les analytics des abonnements
CREATE OR REPLACE VIEW subscription_analytics_summary AS
SELECT 
    DATE_TRUNC('month', created_at) as month,
    COUNT(*) as new_subscriptions,
    COUNT(*) FILTER (WHERE status = 'active') as active_subscriptions,
    COUNT(*) FILTER (WHERE status = 'trial') as trial_subscriptions,
    COUNT(*) FILTER (WHERE status = 'cancelled') as cancelled_subscriptions,
    SUM(price) as monthly_revenue,
    AVG(price) as average_subscription_value,
    COUNT(DISTINCT plan_id) as plans_used
FROM user_subscriptions
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY month DESC;

COMMENT ON VIEW subscriptions_complete IS 'Abonnements avec informations complètes utilisateur et plan';
COMMENT ON VIEW subscription_plans_with_stats IS 'Plans d abonnement avec statistiques d utilisation';
COMMENT ON VIEW users_with_subscriptions IS 'Utilisateurs avec leurs abonnements actifs';
COMMENT ON VIEW subscription_analytics_summary IS 'Résumé des analytics d abonnement par mois';
