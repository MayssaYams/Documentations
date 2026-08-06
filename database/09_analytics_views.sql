-- =====================================================
-- 09_analytics_views.sql
-- Vues pour KPIs, dashboard et analytics
-- =====================================================

-- =====================================================
-- VUES GLOBALES - KPIs principaux
-- =====================================================

-- Vue pour les KPIs globaux de l'application
CREATE OR REPLACE VIEW global_kpis AS
SELECT 
    CURRENT_DATE as date,
    -- Utilisateurs
    COUNT(DISTINCT au.id) as total_users,
    COUNT(DISTINCT au.id) FILTER (WHERE au.date_joined >= CURRENT_DATE - INTERVAL '30 days') as new_users_30d,
    COUNT(DISTINCT au.id) FILTER (WHERE au.last_login >= CURRENT_DATE - INTERVAL '7 days') as active_users_7d,
    -- Pâtissiers
    COUNT(DISTINCT b.id) as total_bakers,
    COUNT(DISTINCT b.id) FILTER (WHERE b.is_active = TRUE) as active_bakers,
    COUNT(DISTINCT b.id) FILTER (WHERE b.is_verified = TRUE) as verified_bakers,
    -- Produits
    COUNT(DISTINCT p.id) as total_products,
    COUNT(DISTINCT p.id) FILTER (WHERE p.is_active = TRUE) as active_products,
    COUNT(DISTINCT p.id) FILTER (WHERE p.is_featured = TRUE) as featured_products,
    -- Commandes
    COUNT(DISTINCT o.id) as total_orders,
    COUNT(DISTINCT o.id) FILTER (WHERE o.created_at >= CURRENT_DATE - INTERVAL '30 days') as orders_30d,
    COUNT(DISTINCT o.id) FILTER (WHERE o.status = 'delivered') as delivered_orders,
    COUNT(DISTINCT o.id) FILTER (WHERE o.status = 'cancelled') as cancelled_orders,
    -- Revenus
    COALESCE(SUM(o.total_price) FILTER (WHERE o.status = 'delivered'), 0) as total_revenue,
    COALESCE(SUM(o.total_price) FILTER (WHERE o.created_at >= CURRENT_DATE - INTERVAL '30 days' AND o.status = 'delivered'), 0) as revenue_30d,
    COALESCE(AVG(o.total_price) FILTER (WHERE o.status = 'delivered'), 0) as average_order_value,
    -- Paiements
    COUNT(DISTINCT pay.id) as total_payments,
    COUNT(DISTINCT pay.id) FILTER (WHERE pay.status = 'completed') as successful_payments,
    COUNT(DISTINCT pay.id) FILTER (WHERE pay.status = 'failed') as failed_payments,
    -- Abonnements
    COUNT(DISTINCT us.id) as total_subscriptions,
    COUNT(DISTINCT us.id) FILTER (WHERE us.status = 'active') as active_subscriptions,
    COUNT(DISTINCT us.id) FILTER (WHERE us.status = 'trial') as trial_subscriptions,
    -- Messages
    COUNT(DISTINCT m.id) as total_messages,
    COUNT(DISTINCT c.id) as total_conversations,
    -- Favoris
    COUNT(DISTINCT (uf.user_id, uf.product_id)) as total_favorites,
    COUNT(DISTINCT fg.id) as total_favorite_groups
FROM accounts_user au
LEFT JOIN baker b ON au.id = b.userid
LEFT JOIN product p ON b.id = p.baker_id
LEFT JOIN orders o ON au.id = o.userid
LEFT JOIN payments pay ON o.id = pay.order_id
LEFT JOIN user_subscriptions us ON au.id = us.user_id
LEFT JOIN messages m ON au.id = m.sender_id
LEFT JOIN conversations c ON au.id = c.created_by
LEFT JOIN user_favoris uf ON au.id = uf.user_id
LEFT JOIN favorite_groups fg ON au.id = fg.user_id;

-- Vue pour les KPIs quotidiens
CREATE OR REPLACE VIEW daily_kpis AS
SELECT 
    DATE(au.date_joined) as date,
    -- Utilisateurs
    COUNT(DISTINCT au.id) as new_users,
    COUNT(DISTINCT au.id) FILTER (WHERE au.last_login >= DATE(au.date_joined)) as active_users,
    -- Commandes
    COUNT(DISTINCT o.id) as orders_count,
    COUNT(DISTINCT o.id) FILTER (WHERE o.status = 'delivered') as delivered_orders,
    COUNT(DISTINCT o.id) FILTER (WHERE o.status = 'cancelled') as cancelled_orders,
    -- Revenus
    COALESCE(SUM(o.total_price) FILTER (WHERE o.status = 'delivered'), 0) as daily_revenue,
    COALESCE(AVG(o.total_price) FILTER (WHERE o.status = 'delivered'), 0) as avg_order_value,
    -- Paiements
    COUNT(DISTINCT pay.id) as payments_count,
    COUNT(DISTINCT pay.id) FILTER (WHERE pay.status = 'completed') as successful_payments,
    COUNT(DISTINCT pay.id) FILTER (WHERE pay.status = 'failed') as failed_payments,
    -- Messages
    COUNT(DISTINCT m.id) as messages_count,
    COUNT(DISTINCT c.id) as conversations_count,
    -- Favoris
    COUNT(DISTINCT (uf.user_id, uf.product_id)) as favorites_added,
    COUNT(DISTINCT fg.id) as groups_created
FROM accounts_user au
LEFT JOIN orders o ON au.id = o.userid
LEFT JOIN payments pay ON o.id = pay.order_id
LEFT JOIN messages m ON au.id = m.sender_id
LEFT JOIN conversations c ON au.id = c.created_by
LEFT JOIN user_favoris uf ON au.id = uf.user_id AND DATE(uf.added_at) = DATE(au.date_joined)
LEFT JOIN favorite_groups fg ON au.id = fg.user_id AND DATE(fg.created_at) = DATE(au.date_joined)
GROUP BY DATE(au.date_joined)
ORDER BY DATE(au.date_joined) DESC;

-- =====================================================
-- VUES PÂTISSIER - Dashboard pâtissier
-- =====================================================

-- Vue pour le dashboard pâtissier
CREATE OR REPLACE VIEW baker_dashboard AS
SELECT 
    b.id as baker_id,
    b.userid as baker_user_id,
    au.first_name as baker_first_name,
    au.last_name as baker_last_name,
    au.email as baker_email,
    b.business_name,
    b.is_verified,
    b.is_active,
    -- Produits
    COUNT(DISTINCT p.id) as total_products,
    COUNT(DISTINCT p.id) FILTER (WHERE p.is_active = TRUE) as active_products,
    COUNT(DISTINCT p.id) FILTER (WHERE p.is_featured = TRUE) as featured_products,
    -- Commandes
    COUNT(DISTINCT o.id) as total_orders,
    COUNT(DISTINCT o.id) FILTER (WHERE o.created_at >= CURRENT_DATE - INTERVAL '30 days') as orders_30d,
    COUNT(DISTINCT o.id) FILTER (WHERE o.status = 'delivered') as delivered_orders,
    COUNT(DISTINCT o.id) FILTER (WHERE o.status = 'cancelled') as cancelled_orders,
    -- Revenus
    COALESCE(SUM(o.total_price) FILTER (WHERE o.status = 'delivered'), 0) as total_revenue,
    COALESCE(SUM(o.total_price) FILTER (WHERE o.created_at >= CURRENT_DATE - INTERVAL '30 days' AND o.status = 'delivered'), 0) as revenue_30d,
    COALESCE(AVG(o.total_price) FILTER (WHERE o.status = 'delivered'), 0) as average_order_value,
    -- Avis
    COUNT(DISTINCT br.id) as total_reviews,
    COALESCE(AVG(br.rating), 0) as average_rating,
    COUNT(DISTINCT br.id) FILTER (WHERE br.rating = 5) as five_star_reviews,
    COUNT(DISTINCT br.id) FILTER (WHERE br.rating = 4) as four_star_reviews,
    COUNT(DISTINCT br.id) FILTER (WHERE br.rating = 3) as three_star_reviews,
    COUNT(DISTINCT br.id) FILTER (WHERE br.rating = 2) as two_star_reviews,
    COUNT(DISTINCT br.id) FILTER (WHERE br.rating = 1) as one_star_reviews,
    -- Followers
    COUNT(DISTINCT bf.user_id) as total_followers,
    -- Messages
    COUNT(DISTINCT m.id) as messages_received,
    COUNT(DISTINCT c.id) as conversations_count,
    -- Vues produits
    COUNT(DISTINCT pv.id) as product_views,
    -- Favoris produits
    COUNT(DISTINCT (uf.user_id, uf.product_id)) as product_favorites
FROM baker b
JOIN accounts_user au ON b.userid = au.id
LEFT JOIN product p ON b.id = p.baker_id
LEFT JOIN orders o ON b.userid = o.userid
LEFT JOIN baker_review br ON b.id = br.bakerid
LEFT JOIN baker_followers bf ON b.id = bf.baker_id
LEFT JOIN messages m ON b.userid = m.sender_id
LEFT JOIN conversations c ON b.userid = c.created_by
LEFT JOIN product_views pv ON p.id = pv.product_id
LEFT JOIN user_favoris uf ON p.id = uf.product_id
GROUP BY b.id, b.userid, au.first_name, au.last_name, au.email, b.business_name, b.is_verified, b.is_active;

-- Vue pour les analytics quotidiennes des pâtissiers
CREATE OR REPLACE VIEW baker_daily_analytics AS
SELECT 
    b.id as baker_id,
    DATE(o.created_at) as date,
    COUNT(DISTINCT o.id) as orders_count,
    COUNT(DISTINCT o.id) FILTER (WHERE o.status = 'delivered') as delivered_orders,
    COUNT(DISTINCT o.id) FILTER (WHERE o.status = 'cancelled') as cancelled_orders,
    COALESCE(SUM(o.total_price) FILTER (WHERE o.status = 'delivered'), 0) as daily_revenue,
    COALESCE(AVG(o.total_price) FILTER (WHERE o.status = 'delivered'), 0) as avg_order_value,
    COUNT(DISTINCT br.id) as reviews_received,
    COALESCE(AVG(br.rating), 0) as daily_avg_rating,
    COUNT(DISTINCT pv.id) as product_views,
    COUNT(DISTINCT (uf.user_id, uf.product_id)) as favorites_added,
    COUNT(DISTINCT m.id) as messages_received
FROM baker b
LEFT JOIN orders o ON b.userid = o.userid
LEFT JOIN baker_review br ON b.id = br.bakerid AND DATE(br.createdat) = DATE(o.created_at)
LEFT JOIN product p ON b.id = p.baker_id
LEFT JOIN product_views pv ON p.id = pv.product_id AND DATE(pv.created_at) = DATE(o.created_at)
LEFT JOIN user_favoris uf ON p.id = uf.product_id AND DATE(uf.added_at) = DATE(o.created_at)
LEFT JOIN messages m ON b.userid = m.sender_id AND DATE(m.created_at) = DATE(o.created_at)
WHERE o.created_at IS NOT NULL
GROUP BY b.id, DATE(o.created_at)
ORDER BY b.id, date DESC;

-- =====================================================
-- VUES PRODUIT - Analytics produits
-- =====================================================

-- Vue pour les analytics des produits
CREATE OR REPLACE VIEW product_analytics AS
SELECT 
    p.id as product_id,
    p.name as product_name,
    p.price,
    p.is_active,
    p.is_featured,
    b.userid as baker_user_id,
    au.first_name as baker_first_name,
    au.last_name as baker_last_name,
    -- Commandes
    COUNT(DISTINCT o.id) as total_orders,
    COUNT(DISTINCT o.id) FILTER (WHERE o.created_at >= CURRENT_DATE - INTERVAL '30 days') as orders_30d,
    COUNT(DISTINCT o.id) FILTER (WHERE o.status = 'delivered') as delivered_orders,
    -- Revenus
    COALESCE(SUM(od.quantity * od.unit_price) FILTER (WHERE o.status = 'delivered'), 0) as total_revenue,
    COALESCE(SUM(od.quantity * od.unit_price) FILTER (WHERE o.created_at >= CURRENT_DATE - INTERVAL '30 days' AND o.status = 'delivered'), 0) as revenue_30d,
    -- Avis
    COUNT(DISTINCT pr.id) as total_reviews,
    COALESCE(AVG(pr.rating), 0) as average_rating,
    COUNT(DISTINCT pr.id) FILTER (WHERE pr.rating = 5) as five_star_reviews,
    COUNT(DISTINCT pr.id) FILTER (WHERE pr.rating = 4) as four_star_reviews,
    COUNT(DISTINCT pr.id) FILTER (WHERE pr.rating = 3) as three_star_reviews,
    COUNT(DISTINCT pr.id) FILTER (WHERE pr.rating = 2) as two_star_reviews,
    COUNT(DISTINCT pr.id) FILTER (WHERE pr.rating = 1) as one_star_reviews,
    -- Vues
    COUNT(DISTINCT pv.id) as total_views,
    COUNT(DISTINCT pv.id) FILTER (WHERE pv.created_at >= CURRENT_DATE - INTERVAL '30 days') as views_30d,
    -- Favoris
    COUNT(DISTINCT (uf.user_id, uf.product_id)) as total_favorites,
    COUNT(DISTINCT (uf.user_id, uf.product_id)) FILTER (WHERE uf.added_at >= CURRENT_DATE - INTERVAL '30 days') as favorites_30d,
    -- Panier
    COUNT(DISTINCT ci.id) as cart_additions,
    COUNT(DISTINCT ci.id) FILTER (WHERE ci.created_at >= CURRENT_DATE - INTERVAL '30 days') as cart_additions_30d
FROM product p
JOIN baker b ON p.baker_id = b.id
JOIN accounts_user au ON b.userid = au.id
LEFT JOIN order_detail od ON p.id = od.productid
LEFT JOIN orders o ON od.orderid = o.id
LEFT JOIN product_reviews pr ON p.id = pr.product_id
LEFT JOIN product_views pv ON p.id = pv.product_id
LEFT JOIN user_favoris uf ON p.id = uf.product_id
LEFT JOIN cart_items ci ON p.id = ci.product_id
GROUP BY p.id, p.name, p.price, p.is_active, p.is_featured, b.userid, au.first_name, au.last_name;

-- Vue pour les produits les plus performants
CREATE OR REPLACE VIEW top_performing_products AS
SELECT 
    pa.*,
    ROW_NUMBER() OVER (ORDER BY pa.total_revenue DESC) as revenue_rank,
    ROW_NUMBER() OVER (ORDER BY pa.total_orders DESC) as orders_rank,
    ROW_NUMBER() OVER (ORDER BY pa.average_rating DESC) as rating_rank,
    ROW_NUMBER() OVER (ORDER BY pa.total_views DESC) as views_rank,
    ROW_NUMBER() OVER (ORDER BY pa.total_favorites DESC) as favorites_rank
FROM product_analytics pa
WHERE pa.is_active = TRUE
ORDER BY pa.total_revenue DESC;

-- =====================================================
-- VUES UTILISATEUR - Analytics utilisateur
-- =====================================================

-- Vue pour les analytics des utilisateurs
CREATE OR REPLACE VIEW user_analytics AS
SELECT 
    au.id as user_id,
    au.email,
    au.first_name,
    au.last_name,
    au.date_joined,
    au.last_login,
    -- Commandes
    COUNT(DISTINCT o.id) as total_orders,
    COUNT(DISTINCT o.id) FILTER (WHERE o.created_at >= CURRENT_DATE - INTERVAL '30 days') as orders_30d,
    COUNT(DISTINCT o.id) FILTER (WHERE o.status = 'delivered') as delivered_orders,
    COUNT(DISTINCT o.id) FILTER (WHERE o.status = 'cancelled') as cancelled_orders,
    -- Revenus dépensés
    COALESCE(SUM(o.total_price) FILTER (WHERE o.status = 'delivered'), 0) as total_spent,
    COALESCE(SUM(o.total_price) FILTER (WHERE o.created_at >= CURRENT_DATE - INTERVAL '30 days' AND o.status = 'delivered'), 0) as spent_30d,
    COALESCE(AVG(o.total_price) FILTER (WHERE o.status = 'delivered'), 0) as average_order_value,
    -- Favoris
    COUNT(DISTINCT (uf.user_id, uf.product_id)) as total_favorites,
    COUNT(DISTINCT fg.id) as total_favorite_groups,
    -- Messages
    COUNT(DISTINCT m.id) as messages_sent,
    COUNT(DISTINCT c.id) as conversations_started,
    -- Sessions
    COUNT(DISTINCT us.id) as total_sessions,
    COUNT(DISTINCT us.id) FILTER (WHERE us.created_at >= CURRENT_DATE - INTERVAL '30 days') as sessions_30d,
    -- Pages vues
    COUNT(DISTINCT upv.id) as total_page_views,
    COUNT(DISTINCT upv.id) FILTER (WHERE upv.created_at >= CURRENT_DATE - INTERVAL '30 days') as page_views_30d,
    -- Actions
    COUNT(DISTINCT ua.id) as total_actions,
    COUNT(DISTINCT ua.id) FILTER (WHERE ua.created_at >= CURRENT_DATE - INTERVAL '30 days') as actions_30d,
    -- Recherches
    COUNT(DISTINCT ush.id) as total_searches,
    COUNT(DISTINCT ush.id) FILTER (WHERE ush.created_at >= CURRENT_DATE - INTERVAL '30 days') as searches_30d
FROM accounts_user au
LEFT JOIN orders o ON au.id = o.userid
LEFT JOIN user_favoris uf ON au.id = uf.user_id
LEFT JOIN favorite_groups fg ON au.id = fg.user_id
LEFT JOIN messages m ON au.id = m.sender_id
LEFT JOIN conversations c ON au.id = c.created_by
LEFT JOIN user_sessions us ON au.id = us.user_id
LEFT JOIN user_page_views upv ON au.id = upv.user_id
LEFT JOIN user_actions ua ON au.id = ua.user_id
LEFT JOIN user_search_history ush ON au.id = ush.user_id
GROUP BY au.id, au.email, au.first_name, au.last_name, au.date_joined, au.last_login;

-- Vue pour les utilisateurs les plus actifs
CREATE OR REPLACE VIEW top_active_users AS
SELECT 
    ua.*,
    ROW_NUMBER() OVER (ORDER BY ua.total_spent DESC) as spending_rank,
    ROW_NUMBER() OVER (ORDER BY ua.total_orders DESC) as orders_rank,
    ROW_NUMBER() OVER (ORDER BY ua.total_page_views DESC) as activity_rank,
    ROW_NUMBER() OVER (ORDER BY ua.total_actions DESC) as engagement_rank
FROM user_analytics ua
ORDER BY ua.total_spent DESC;

-- =====================================================
-- VUES TEMPORELLES - Tendances et évolution
-- =====================================================

-- Vue pour les tendances mensuelles
CREATE OR REPLACE VIEW monthly_trends AS
SELECT 
    DATE_TRUNC('month', au.date_joined) as month,
    -- Utilisateurs
    COUNT(DISTINCT au.id) as new_users,
    COUNT(DISTINCT au.id) FILTER (WHERE au.last_login >= DATE_TRUNC('month', au.date_joined)) as active_users,
    -- Commandes
    COUNT(DISTINCT o.id) as orders_count,
    COUNT(DISTINCT o.id) FILTER (WHERE o.status = 'delivered') as delivered_orders,
    -- Revenus
    COALESCE(SUM(o.total_price) FILTER (WHERE o.status = 'delivered'), 0) as monthly_revenue,
    COALESCE(AVG(o.total_price) FILTER (WHERE o.status = 'delivered'), 0) as avg_order_value,
    -- Paiements
    COUNT(DISTINCT pay.id) as payments_count,
    COUNT(DISTINCT pay.id) FILTER (WHERE pay.status = 'completed') as successful_payments,
    -- Messages
    COUNT(DISTINCT m.id) as messages_count,
    -- Favoris
    COUNT(DISTINCT (uf.user_id, uf.product_id)) as favorites_added
FROM accounts_user au
LEFT JOIN orders o ON au.id = o.userid
LEFT JOIN payments pay ON o.id = pay.order_id
LEFT JOIN messages m ON au.id = m.sender_id
LEFT JOIN user_favoris uf ON au.id = uf.user_id AND DATE_TRUNC('month', uf.added_at) = DATE_TRUNC('month', au.date_joined)
GROUP BY DATE_TRUNC('month', au.date_joined)
ORDER BY DATE_TRUNC('month', au.date_joined) DESC;

-- Vue pour les tendances hebdomadaires
CREATE OR REPLACE VIEW weekly_trends AS
SELECT 
    DATE_TRUNC('week', au.date_joined) as week,
    -- Utilisateurs
    COUNT(DISTINCT au.id) as new_users,
    COUNT(DISTINCT au.id) FILTER (WHERE au.last_login >= DATE_TRUNC('week', au.date_joined)) as active_users,
    -- Commandes
    COUNT(DISTINCT o.id) as orders_count,
    COUNT(DISTINCT o.id) FILTER (WHERE o.status = 'delivered') as delivered_orders,
    -- Revenus
    COALESCE(SUM(o.total_price) FILTER (WHERE o.status = 'delivered'), 0) as weekly_revenue,
    COALESCE(AVG(o.total_price) FILTER (WHERE o.status = 'delivered'), 0) as avg_order_value,
    -- Messages
    COUNT(DISTINCT m.id) as messages_count,
    -- Favoris
    COUNT(DISTINCT (uf.user_id, uf.product_id)) as favorites_added
FROM accounts_user au
LEFT JOIN orders o ON au.id = o.userid
LEFT JOIN messages m ON au.id = m.sender_id
LEFT JOIN user_favoris uf ON au.id = uf.user_id AND DATE_TRUNC('week', uf.added_at) = DATE_TRUNC('week', au.date_joined)
GROUP BY DATE_TRUNC('week', au.date_joined)
ORDER BY week DESC;

-- =====================================================
-- VUES GÉOGRAPHIQUES - Analytics par localisation
-- =====================================================

-- Vue pour les analytics par ville
CREATE OR REPLACE VIEW city_analytics AS
SELECT 
    au.city,
    au.region,
    au.country,
    COUNT(DISTINCT au.id) as total_users,
    COUNT(DISTINCT b.id) as total_bakers,
    COUNT(DISTINCT o.id) as total_orders,
    COALESCE(SUM(o.total_price) FILTER (WHERE o.status = 'delivered'), 0) as total_revenue,
    COALESCE(AVG(o.total_price) FILTER (WHERE o.status = 'delivered'), 0) as avg_order_value
FROM accounts_user au
LEFT JOIN baker b ON au.id = b.userid
LEFT JOIN orders o ON au.id = o.userid
WHERE au.city IS NOT NULL
GROUP BY au.city, au.region, au.country
ORDER BY total_revenue DESC;

-- =====================================================
-- COMMENTAIRES DES VUES
-- =====================================================

-- Commentaires conditionnels pour les vues
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'global_kpis') THEN
        COMMENT ON VIEW global_kpis IS 'KPIs globaux de l application avec métriques principales';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'daily_kpis') THEN
        COMMENT ON VIEW daily_kpis IS 'KPIs quotidiens pour suivi des tendances';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'baker_dashboard') THEN
        COMMENT ON VIEW baker_dashboard IS 'Dashboard complet pour les pâtissiers avec toutes les métriques';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'baker_daily_analytics') THEN
        COMMENT ON VIEW baker_daily_analytics IS 'Analytics quotidiennes par pâtissier';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'product_analytics') THEN
        COMMENT ON VIEW product_analytics IS 'Analytics complètes par produit avec métriques de performance';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'top_performing_products') THEN
        COMMENT ON VIEW top_performing_products IS 'Produits les plus performants avec classements';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'user_analytics') THEN
        COMMENT ON VIEW user_analytics IS 'Analytics complètes par utilisateur avec métriques d engagement';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'top_active_users') THEN
        COMMENT ON VIEW top_active_users IS 'Utilisateurs les plus actifs avec classements';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'monthly_trends') THEN
        COMMENT ON VIEW monthly_trends IS 'Tendances mensuelles pour analyse de croissance';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'weekly_trends') THEN
        COMMENT ON VIEW weekly_trends IS 'Tendances hebdomadaires pour suivi court terme';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'city_analytics') THEN
        COMMENT ON VIEW city_analytics IS 'Analytics par localisation géographique';
    END IF;
END $$;
