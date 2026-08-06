-- =====================================================
-- 10_indexes_and_constraints.sql
-- Index de performance, contraintes d'intégrité et triggers
-- =====================================================

-- Extensions nécessaires pour les index
CREATE EXTENSION IF NOT EXISTS pg_trgm; -- Pour les index trigram (recherche textuelle)
-- Note: postgis est optionnel pour les index géographiques

-- =====================================================
-- INDEX DE PERFORMANCE SUPPLÉMENTAIRES
-- =====================================================

-- Index composites pour les requêtes fréquentes
CREATE INDEX IF NOT EXISTS idx_orders_user_status_date ON orders(userid, status, created_at);
CREATE INDEX IF NOT EXISTS idx_orders_baker_status_date ON orders(baker_id, status, created_at);
CREATE INDEX IF NOT EXISTS idx_product_baker_active ON product(baker_id, is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_product_price_active ON product(price, is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_user_sessions_active_expires ON user_sessions(is_active, expires_at) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_messages_conversation_created ON messages(conversation_id, created_at) WHERE is_deleted = FALSE;
CREATE INDEX IF NOT EXISTS idx_payments_user_status ON payments(user_id, status);
CREATE INDEX IF NOT EXISTS idx_payments_order_status ON payments(order_id, status);

-- Index pour les recherches textuelles
CREATE INDEX IF NOT EXISTS idx_product_name_trgm ON product USING gin(name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_product_description_trgm ON product USING gin(description gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_baker_description_trgm ON baker USING gin(description gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_user_search_query_trgm ON user_search_history USING gin(search_query gin_trgm_ops);

-- Index pour les requêtes géographiques (nécessite postgis)
-- Ces index sont créés seulement si la colonne location existe et est de type geometry
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'accounts_user' AND column_name = 'location' AND data_type = 'USER-DEFINED') THEN
        CREATE INDEX IF NOT EXISTS idx_user_location_gist ON accounts_user USING gist(location);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'shipping_address' AND column_name = 'coordinates') THEN
        CREATE INDEX IF NOT EXISTS idx_shipping_address_coordinates ON shipping_address USING gist(coordinates);
    END IF;
END $$;

-- Index pour les requêtes JSONB
CREATE INDEX IF NOT EXISTS idx_user_preferences_categories ON user_preferences USING gin(preferred_categories);
CREATE INDEX IF NOT EXISTS idx_product_tags_json ON product USING gin(tags);
CREATE INDEX IF NOT EXISTS idx_product_customization_options ON product USING gin(customization_options);
CREATE INDEX IF NOT EXISTS idx_message_read_by ON messages USING gin(read_by);
CREATE INDEX IF NOT EXISTS idx_payment_metadata ON payments USING gin(metadata);

-- Index pour les requêtes de fenêtrage (window functions)
CREATE INDEX IF NOT EXISTS idx_orders_user_created_window ON orders(userid, created_at);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_created_window ON messages(conversation_id, created_at);
CREATE INDEX IF NOT EXISTS idx_user_actions_user_created_window ON user_actions(user_id, created_at);

-- Index pour les requêtes d'agrégation
CREATE INDEX IF NOT EXISTS idx_orders_status_created_agg ON orders(status, created_at);
CREATE INDEX IF NOT EXISTS idx_payments_status_created_agg ON payments(status, created_at);
CREATE INDEX IF NOT EXISTS idx_user_sessions_created_agg ON user_sessions(created_at);

-- =====================================================
-- CONTRAINTES D'INTÉGRITÉ SUPPLÉMENTAIRES
-- =====================================================

-- Contraintes de validation des données
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'chk_email_format' AND table_name = 'accounts_user') THEN
        ALTER TABLE accounts_user ADD CONSTRAINT chk_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'chk_phone_format' AND table_name = 'accounts_user') THEN
        ALTER TABLE accounts_user ADD CONSTRAINT chk_phone_format CHECK (phone_number ~* '^\+?[1-9]\d{1,14}$' OR phone_number IS NULL);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'chk_postal_code_format' AND table_name = 'accounts_user') THEN
        ALTER TABLE accounts_user ADD CONSTRAINT chk_postal_code_format CHECK (postal_code ~* '^\d{5}$' OR postal_code IS NULL);
    END IF;
END $$;

-- Contraintes pour les prix et montants
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'chk_product_price_positive' AND table_name = 'product') THEN
        ALTER TABLE product ADD CONSTRAINT chk_product_price_positive CHECK (price > 0);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'chk_variant_price_positive' AND table_name = 'product_variant') THEN
        ALTER TABLE product_variant ADD CONSTRAINT chk_variant_price_positive CHECK (price > 0);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'chk_order_total_positive' AND table_name = 'orders') THEN
        ALTER TABLE orders ADD CONSTRAINT chk_order_total_positive CHECK (total_price > 0);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'chk_payment_amount_positive' AND table_name = 'payments') THEN
        ALTER TABLE payments ADD CONSTRAINT chk_payment_amount_positive CHECK (amount > 0);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'chk_plan_price_positive' AND table_name = 'subscription_plans') THEN
        ALTER TABLE subscription_plans ADD CONSTRAINT chk_plan_price_positive CHECK (price > 0);
    END IF;
END $$;

-- Contraintes pour les quantités
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'chk_order_detail_quantity_positive' AND table_name = 'order_detail') THEN
        ALTER TABLE order_detail ADD CONSTRAINT chk_order_detail_quantity_positive CHECK (quantity > 0);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'chk_cart_item_quantity_positive' AND table_name = 'cart_items') THEN
        ALTER TABLE cart_items ADD CONSTRAINT chk_cart_item_quantity_positive CHECK (quantity > 0);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'chk_product_stock_non_negative' AND table_name = 'product') THEN
        ALTER TABLE product ADD CONSTRAINT chk_product_stock_non_negative CHECK (stock_quantity >= 0);
    END IF;
END $$;

-- Contraintes pour les notes et évaluations
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'chk_baker_rating_range' AND table_name = 'baker_review') THEN
        ALTER TABLE baker_review ADD CONSTRAINT chk_baker_rating_range CHECK (rating >= 1 AND rating <= 5);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'chk_product_rating_range' AND table_name = 'product_reviews') THEN
        ALTER TABLE product_reviews ADD CONSTRAINT chk_product_rating_range CHECK (rating >= 1 AND rating <= 5);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'chk_order_rating_range' AND table_name = 'orders') THEN
        ALTER TABLE orders ADD CONSTRAINT chk_order_rating_range CHECK (rating IS NULL OR (rating >= 1 AND rating <= 5));
    END IF;
END $$;

-- Contraintes pour les dates
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'chk_order_delivery_date_future' AND table_name = 'orders') THEN
        ALTER TABLE orders ADD CONSTRAINT chk_order_delivery_date_future CHECK (delivery_date IS NULL OR delivery_date >= CURRENT_DATE);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_plans' AND column_name = 'start_date') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'chk_plan_dates_valid' AND table_name = 'subscription_plans') THEN
            ALTER TABLE subscription_plans ADD CONSTRAINT chk_plan_dates_valid CHECK (start_date IS NULL OR end_date IS NULL OR start_date <= end_date);
        END IF;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'promotion' AND column_name = 'start_date') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'chk_promotion_dates_valid' AND table_name = 'promotion') THEN
            ALTER TABLE promotion ADD CONSTRAINT chk_promotion_dates_valid CHECK (start_date <= end_date);
        END IF;
    END IF;
END $$;

-- Contraintes pour les pourcentages
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'chk_commission_rate_range' AND table_name = 'baker') THEN
        ALTER TABLE baker ADD CONSTRAINT chk_commission_rate_range CHECK (commission_rate >= 0 AND commission_rate <= 100);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'chk_conversion_rate_range' AND table_name = 'subscription_analytics_daily') THEN
        ALTER TABLE subscription_analytics_daily ADD CONSTRAINT chk_conversion_rate_range CHECK (conversion_rate >= 0 AND conversion_rate <= 100);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'chk_churn_rate_range' AND table_name = 'subscription_analytics_daily') THEN
        ALTER TABLE subscription_analytics_daily ADD CONSTRAINT chk_churn_rate_range CHECK (churn_rate >= 0 AND churn_rate <= 100);
    END IF;
END $$;

-- Contraintes pour les statuts
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'chk_order_status_valid' AND table_name = 'orders') THEN
        ALTER TABLE orders ADD CONSTRAINT chk_order_status_valid CHECK (status IN ('pending', 'confirmed', 'preparing', 'ready', 'delivered', 'cancelled'));
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'chk_payment_status_valid' AND table_name = 'payments') THEN
        ALTER TABLE payments ADD CONSTRAINT chk_payment_status_valid CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded'));
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'chk_subscription_status_valid' AND table_name = 'user_subscriptions') THEN
        ALTER TABLE user_subscriptions ADD CONSTRAINT chk_subscription_status_valid CHECK (status IN ('active', 'cancelled', 'expired', 'suspended', 'trial'));
    END IF;
END $$;

-- Contraintes pour les types de données
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'chk_message_type_valid' AND table_name = 'messages') THEN
        ALTER TABLE messages ADD CONSTRAINT chk_message_type_valid CHECK (message_type IN ('text', 'image', 'file', 'system', 'order'));
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'chk_transaction_type_valid' AND table_name = 'payment_transactions') THEN
        ALTER TABLE payment_transactions ADD CONSTRAINT chk_transaction_type_valid CHECK (transaction_type IN ('charge', 'refund', 'void', 'capture'));
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'chk_plan_type_valid' AND table_name = 'subscription_plans') THEN
        ALTER TABLE subscription_plans ADD CONSTRAINT chk_plan_type_valid CHECK (plan_type IN ('basic', 'premium', 'pro', 'enterprise'));
    END IF;
END $$;

-- =====================================================
-- TRIGGERS SUPPLÉMENTAIRES
-- =====================================================

-- Trigger pour mettre à jour automatiquement les timestamps
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Application du trigger updated_at sur toutes les tables qui en ont besoin
DO $$
DECLARE
    tbl_name TEXT;
    tables_with_updated_at TEXT[] := ARRAY[
        'accounts_user', 'baker', 'product', 'orders', 'order_detail',
        'payment_method', 'shipping_address', 'promotion', 'category',
        'allergen', 'product_image', 'product_variant', 'product_allergen',
        'product_category', 'product_quantity_rule', 'product_allowed_quantity',
        'product_history', 'product_user', 'sales_analytics', 'user_favoris'
    ];
BEGIN
    FOREACH tbl_name IN ARRAY tables_with_updated_at
    LOOP
        -- Vérifier si la colonne updated_at existe
        IF EXISTS (
            SELECT 1 FROM information_schema.columns c
            WHERE c.table_name = tbl_name AND c.column_name = 'updated_at' AND c.table_schema = 'public'
        ) THEN
            -- Créer le trigger s'il n'existe pas déjà
            EXECUTE format('
                DROP TRIGGER IF EXISTS trigger_%s_updated_at ON %I;
                CREATE TRIGGER trigger_%s_updated_at
                    BEFORE UPDATE ON %I
                    FOR EACH ROW
                    EXECUTE FUNCTION update_timestamp()',
                tbl_name, tbl_name, tbl_name, tbl_name
            );
        END IF;
    END LOOP;
END $$;

-- Trigger pour valider les données avant insertion
CREATE OR REPLACE FUNCTION validate_order_data()
RETURNS TRIGGER AS $$
BEGIN
    -- Vérifier que la date de livraison est dans le futur
    IF NEW.delivery_date IS NOT NULL AND NEW.delivery_date < CURRENT_DATE THEN
        RAISE EXCEPTION 'La date de livraison doit être dans le futur';
    END IF;
    
    -- Vérifier que le montant total est cohérent
    IF NEW.subtotal IS NOT NULL AND NEW.total_price IS NOT NULL THEN
        IF NEW.total_price < NEW.subtotal THEN
            RAISE EXCEPTION 'Le montant total ne peut pas être inférieur au sous-total';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_validate_order_data ON orders;
CREATE TRIGGER trigger_validate_order_data
    BEFORE INSERT OR UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION validate_order_data();

-- Trigger pour valider les données de paiement
CREATE OR REPLACE FUNCTION validate_payment_data()
RETURNS TRIGGER AS $$
BEGIN
    -- Vérifier que le montant du remboursement ne dépasse pas le montant du paiement
    IF NEW.refund_amount > NEW.amount THEN
        RAISE EXCEPTION 'Le montant du remboursement ne peut pas dépasser le montant du paiement';
    END IF;
    
    -- Vérifier la cohérence des statuts
    IF NEW.status = 'refunded' AND NEW.refund_amount = 0 THEN
        RAISE EXCEPTION 'Un paiement remboursé doit avoir un montant de remboursement > 0';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_validate_payment_data ON payments;
CREATE TRIGGER trigger_validate_payment_data
    BEFORE INSERT OR UPDATE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION validate_payment_data();

-- Trigger pour valider les données d'abonnement
CREATE OR REPLACE FUNCTION validate_subscription_data()
RETURNS TRIGGER AS $$
BEGIN
    -- Vérifier que la date de fin est après la date de début
    IF NEW.end_date IS NOT NULL AND NEW.end_date <= NEW.start_date THEN
        RAISE EXCEPTION 'La date de fin doit être après la date de début';
    END IF;
    
    -- Vérifier que la date de facturation suivante est dans le futur
    IF NEW.next_billing_date IS NOT NULL AND NEW.next_billing_date <= CURRENT_DATE THEN
        RAISE EXCEPTION 'La date de facturation suivante doit être dans le futur';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_validate_subscription_data ON user_subscriptions;
CREATE TRIGGER trigger_validate_subscription_data
    BEFORE INSERT OR UPDATE ON user_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION validate_subscription_data();

-- =====================================================
-- FONCTIONS UTILITAIRES
-- =====================================================

-- Fonction pour nettoyer les données anciennes
CREATE OR REPLACE FUNCTION cleanup_old_data()
RETURNS VOID AS $$
BEGIN
    -- Supprimer les sessions expirées
    DELETE FROM user_sessions WHERE expires_at < NOW() - INTERVAL '30 days';
    
    -- Supprimer les actions utilisateur anciennes (garder 90 jours)
    DELETE FROM user_actions WHERE created_at < NOW() - INTERVAL '90 days';
    
    -- Supprimer les vues de pages anciennes (garder 90 jours)
    DELETE FROM user_page_views WHERE created_at < NOW() - INTERVAL '90 days';
    
    -- Supprimer les notifications lues anciennes (garder 30 jours)
    DELETE FROM user_notifications WHERE is_read = TRUE AND read_at < NOW() - INTERVAL '30 days';
    
    -- Supprimer les messages supprimés anciens (garder 30 jours)
    DELETE FROM messages WHERE is_deleted = TRUE AND deleted_at < NOW() - INTERVAL '30 days';
    
    -- Supprimer les paniers inactifs anciens (garder 7 jours)
    DELETE FROM cart WHERE is_active = FALSE AND updated_at < NOW() - INTERVAL '7 days';
    
    RAISE NOTICE 'Nettoyage des données anciennes terminé';
END;
$$ LANGUAGE plpgsql;

-- Fonction pour calculer les statistiques en temps réel
CREATE OR REPLACE FUNCTION calculate_real_time_stats()
RETURNS TABLE (
    metric_name TEXT,
    metric_value NUMERIC,
    last_updated TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'total_users'::TEXT,
        COUNT(*)::NUMERIC,
        NOW()
    FROM accounts_user
    
    UNION ALL
    
    SELECT 
        'active_users_today'::TEXT,
        COUNT(DISTINCT user_id)::NUMERIC,
        NOW()
    FROM user_sessions 
    WHERE created_at >= CURRENT_DATE AND is_active = TRUE
    
    UNION ALL
    
    SELECT 
        'orders_today'::TEXT,
        COUNT(*)::NUMERIC,
        NOW()
    FROM orders 
    WHERE created_at >= CURRENT_DATE
    
    UNION ALL
    
    SELECT 
        'revenue_today'::TEXT,
        COALESCE(SUM(total_price), 0)::NUMERIC,
        NOW()
    FROM orders 
    WHERE created_at >= CURRENT_DATE AND status = 'delivered'
    
    UNION ALL
    
    SELECT 
        'messages_today'::TEXT,
        COUNT(*)::NUMERIC,
        NOW()
    FROM messages 
    WHERE created_at >= CURRENT_DATE AND is_deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour obtenir les métriques de performance
CREATE OR REPLACE FUNCTION get_performance_metrics()
RETURNS TABLE (
    table_name TEXT,
    row_count BIGINT,
    index_size TEXT,
    table_size TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        schemaname||'.'||tablename as table_name,
        n_tup_ins - n_tup_del as row_count,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as index_size,
        pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as table_size
    FROM pg_stat_user_tables 
    WHERE schemaname = 'public'
    ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- VUES DE MONITORING
-- =====================================================

-- Vue pour surveiller les performances des requêtes (nécessite pg_stat_statements)
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_stat_statements') THEN
        EXECUTE 'CREATE OR REPLACE VIEW query_performance AS
        SELECT 
            query,
            calls,
            total_time,
            mean_time,
            rows,
            100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0) AS hit_percent
        FROM pg_stat_statements 
        WHERE query NOT LIKE ''%pg_stat_statements%''
        ORDER BY total_time DESC
        LIMIT 20';
    END IF;
END $$;

-- Vue pour surveiller l'utilisation des index
CREATE OR REPLACE VIEW index_usage AS
SELECT 
    schemaname,
    relname as tablename,
    indexrelname as indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes 
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;

-- Vue pour surveiller les verrous
CREATE OR REPLACE VIEW lock_monitoring AS
SELECT 
    pg_class.relname,
    pg_locks.locktype,
    pg_locks.database,
    pg_locks.relation,
    pg_locks.page,
    pg_locks.tuple,
    pg_locks.virtualxid,
    pg_locks.transactionid,
    pg_locks.classid,
    pg_locks.objid,
    pg_locks.objsubid,
    pg_locks.virtualtransaction,
    pg_locks.pid,
    pg_locks.mode,
    pg_locks.granted,
    pg_locks.fastpath
FROM pg_locks
JOIN pg_class ON pg_locks.relation = pg_class.oid
WHERE pg_class.relname NOT LIKE 'pg_%'
ORDER BY pg_locks.pid;

-- =====================================================
-- TÂCHES DE MAINTENANCE AUTOMATIQUES
-- =====================================================

-- Fonction pour analyser les statistiques
CREATE OR REPLACE FUNCTION analyze_tables()
RETURNS VOID AS $$
DECLARE
    table_name TEXT;
BEGIN
    FOR table_name IN 
        SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        EXECUTE 'ANALYZE ' || table_name;
    END LOOP;
    
    RAISE NOTICE 'Analyse des statistiques terminée';
END;
$$ LANGUAGE plpgsql;

-- Fonction pour réindexer les tables
CREATE OR REPLACE FUNCTION reindex_tables()
RETURNS VOID AS $$
DECLARE
    table_name TEXT;
BEGIN
    FOR table_name IN 
        SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        EXECUTE 'REINDEX TABLE ' || table_name;
    END LOOP;
    
    RAISE NOTICE 'Réindexation terminée';
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- COMMENTAIRES FINAUX
-- =====================================================

COMMENT ON FUNCTION cleanup_old_data() IS 'Nettoie les données anciennes pour maintenir les performances';
COMMENT ON FUNCTION calculate_real_time_stats() IS 'Calcule les statistiques en temps réel';
COMMENT ON FUNCTION get_performance_metrics() IS 'Obtient les métriques de performance des tables';
COMMENT ON FUNCTION analyze_tables() IS 'Analyse les statistiques de toutes les tables';
COMMENT ON FUNCTION reindex_tables() IS 'Réindexe toutes les tables pour optimiser les performances';

-- Commentaires conditionnels pour les vues de monitoring
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'query_performance') THEN
        COMMENT ON VIEW query_performance IS 'Surveille les performances des requêtes les plus lentes';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'index_usage') THEN
        COMMENT ON VIEW index_usage IS 'Surveille l utilisation des index';
    END IF;
END $$;
COMMENT ON VIEW lock_monitoring IS 'Surveille les verrous de base de données';

-- =====================================================
-- SCRIPT DE MAINTENANCE RECOMMANDÉ
-- =====================================================

-- Créer un script de maintenance quotidien
CREATE OR REPLACE FUNCTION daily_maintenance()
RETURNS VOID AS $$
BEGIN
    -- Nettoyer les données anciennes
    PERFORM cleanup_old_data();
    
    -- Analyser les statistiques
    PERFORM analyze_tables();
    
    -- Calculer les statistiques en temps réel
    PERFORM calculate_real_time_stats();
    
    RAISE NOTICE 'Maintenance quotidienne terminée à %', NOW();
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION daily_maintenance() IS 'Effectue la maintenance quotidienne de la base de données';
