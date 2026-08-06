-- =====================================================
-- 16_fix_analytics_trend_views.sql
-- Corrige daily_kpis, monthly_trends, weekly_trends (09_analytics_views.sql)
--
-- Bug : ces 3 vues groupaient par la date d'INSCRIPTION de l'utilisateur
-- (DATE(au.date_joined) / DATE_TRUNC('month'|'week', au.date_joined)) au
-- lieu de la date réelle de l'événement (commande, message, favori...).
-- Résultat : une commande passée en juin par un utilisateur inscrit en
-- janvier remontait dans le seau "janvier" — les tendances affichées
-- étaient trompeuses. Chaque métrique est maintenant agrégée sur sa propre
-- colonne de date, puis les résultats sont combinés par période via des
-- FULL OUTER JOIN (une période n'ayant que des messages, par exemple,
-- apparaît quand même).
-- =====================================================

-- Vue pour les KPIs quotidiens
CREATE OR REPLACE VIEW daily_kpis AS
WITH new_users AS (
    SELECT DATE(date_joined) AS date,
           COUNT(*) AS new_users
    FROM accounts_user
    GROUP BY DATE(date_joined)
),
active_users AS (
    SELECT DATE(last_login) AS date,
           COUNT(DISTINCT id) AS active_users
    FROM accounts_user
    WHERE last_login IS NOT NULL
    GROUP BY DATE(last_login)
),
order_stats AS (
    SELECT DATE(created_at) AS date,
           COUNT(*) AS orders_count,
           COUNT(*) FILTER (WHERE status = 'delivered') AS delivered_orders,
           COUNT(*) FILTER (WHERE status = 'cancelled') AS cancelled_orders,
           COALESCE(SUM(total_price) FILTER (WHERE status = 'delivered'), 0) AS daily_revenue,
           COALESCE(AVG(total_price) FILTER (WHERE status = 'delivered'), 0) AS avg_order_value
    FROM orders
    GROUP BY DATE(created_at)
),
payment_stats AS (
    SELECT DATE(created_at) AS date,
           COUNT(*) AS payments_count,
           COUNT(*) FILTER (WHERE status = 'completed') AS successful_payments,
           COUNT(*) FILTER (WHERE status = 'failed') AS failed_payments
    FROM payments
    GROUP BY DATE(created_at)
),
message_stats AS (
    SELECT DATE(created_at) AS date, COUNT(*) AS messages_count
    FROM messages
    GROUP BY DATE(created_at)
),
conversation_stats AS (
    SELECT DATE(created_at) AS date, COUNT(*) AS conversations_count
    FROM conversations
    GROUP BY DATE(created_at)
),
favorite_stats AS (
    SELECT DATE(added_at) AS date, COUNT(*) AS favorites_added
    FROM user_favoris
    GROUP BY DATE(added_at)
),
group_stats AS (
    SELECT DATE(created_at) AS date, COUNT(*) AS groups_created
    FROM favorite_groups
    GROUP BY DATE(created_at)
)
SELECT
    COALESCE(nu.date, au2.date, os.date, ps.date, ms.date, cs.date, fs.date, gs.date) AS date,
    COALESCE(nu.new_users, 0) AS new_users,
    COALESCE(au2.active_users, 0) AS active_users,
    COALESCE(os.orders_count, 0) AS orders_count,
    COALESCE(os.delivered_orders, 0) AS delivered_orders,
    COALESCE(os.cancelled_orders, 0) AS cancelled_orders,
    COALESCE(os.daily_revenue, 0) AS daily_revenue,
    COALESCE(os.avg_order_value, 0) AS avg_order_value,
    COALESCE(ps.payments_count, 0) AS payments_count,
    COALESCE(ps.successful_payments, 0) AS successful_payments,
    COALESCE(ps.failed_payments, 0) AS failed_payments,
    COALESCE(ms.messages_count, 0) AS messages_count,
    COALESCE(cs.conversations_count, 0) AS conversations_count,
    COALESCE(fs.favorites_added, 0) AS favorites_added,
    COALESCE(gs.groups_created, 0) AS groups_created
FROM new_users nu
FULL OUTER JOIN active_users au2 ON nu.date = au2.date
FULL OUTER JOIN order_stats os ON COALESCE(nu.date, au2.date) = os.date
FULL OUTER JOIN payment_stats ps ON COALESCE(nu.date, au2.date, os.date) = ps.date
FULL OUTER JOIN message_stats ms ON COALESCE(nu.date, au2.date, os.date, ps.date) = ms.date
FULL OUTER JOIN conversation_stats cs ON COALESCE(nu.date, au2.date, os.date, ps.date, ms.date) = cs.date
FULL OUTER JOIN favorite_stats fs ON COALESCE(nu.date, au2.date, os.date, ps.date, ms.date, cs.date) = fs.date
FULL OUTER JOIN group_stats gs ON COALESCE(nu.date, au2.date, os.date, ps.date, ms.date, cs.date, fs.date) = gs.date
ORDER BY date DESC;

-- Vue pour les tendances mensuelles
CREATE OR REPLACE VIEW monthly_trends AS
WITH new_users AS (
    SELECT DATE_TRUNC('month', date_joined) AS month,
           COUNT(*) AS new_users
    FROM accounts_user
    GROUP BY DATE_TRUNC('month', date_joined)
),
active_users AS (
    SELECT DATE_TRUNC('month', last_login) AS month,
           COUNT(DISTINCT id) AS active_users
    FROM accounts_user
    WHERE last_login IS NOT NULL
    GROUP BY DATE_TRUNC('month', last_login)
),
order_stats AS (
    SELECT DATE_TRUNC('month', created_at) AS month,
           COUNT(*) AS orders_count,
           COUNT(*) FILTER (WHERE status = 'delivered') AS delivered_orders,
           COALESCE(SUM(total_price) FILTER (WHERE status = 'delivered'), 0) AS monthly_revenue,
           COALESCE(AVG(total_price) FILTER (WHERE status = 'delivered'), 0) AS avg_order_value
    FROM orders
    GROUP BY DATE_TRUNC('month', created_at)
),
payment_stats AS (
    SELECT DATE_TRUNC('month', created_at) AS month,
           COUNT(*) AS payments_count,
           COUNT(*) FILTER (WHERE status = 'completed') AS successful_payments
    FROM payments
    GROUP BY DATE_TRUNC('month', created_at)
),
message_stats AS (
    SELECT DATE_TRUNC('month', created_at) AS month, COUNT(*) AS messages_count
    FROM messages
    GROUP BY DATE_TRUNC('month', created_at)
),
favorite_stats AS (
    SELECT DATE_TRUNC('month', added_at) AS month, COUNT(*) AS favorites_added
    FROM user_favoris
    GROUP BY DATE_TRUNC('month', added_at)
)
SELECT
    COALESCE(nu.month, au2.month, os.month, ps.month, ms.month, fs.month) AS month,
    COALESCE(nu.new_users, 0) AS new_users,
    COALESCE(au2.active_users, 0) AS active_users,
    COALESCE(os.orders_count, 0) AS orders_count,
    COALESCE(os.delivered_orders, 0) AS delivered_orders,
    COALESCE(os.monthly_revenue, 0) AS monthly_revenue,
    COALESCE(os.avg_order_value, 0) AS avg_order_value,
    COALESCE(ps.payments_count, 0) AS payments_count,
    COALESCE(ps.successful_payments, 0) AS successful_payments,
    COALESCE(ms.messages_count, 0) AS messages_count,
    COALESCE(fs.favorites_added, 0) AS favorites_added
FROM new_users nu
FULL OUTER JOIN active_users au2 ON nu.month = au2.month
FULL OUTER JOIN order_stats os ON COALESCE(nu.month, au2.month) = os.month
FULL OUTER JOIN payment_stats ps ON COALESCE(nu.month, au2.month, os.month) = ps.month
FULL OUTER JOIN message_stats ms ON COALESCE(nu.month, au2.month, os.month, ps.month) = ms.month
FULL OUTER JOIN favorite_stats fs ON COALESCE(nu.month, au2.month, os.month, ps.month, ms.month) = fs.month
ORDER BY month DESC;

-- Vue pour les tendances hebdomadaires
CREATE OR REPLACE VIEW weekly_trends AS
WITH new_users AS (
    SELECT DATE_TRUNC('week', date_joined) AS week,
           COUNT(*) AS new_users
    FROM accounts_user
    GROUP BY DATE_TRUNC('week', date_joined)
),
active_users AS (
    SELECT DATE_TRUNC('week', last_login) AS week,
           COUNT(DISTINCT id) AS active_users
    FROM accounts_user
    WHERE last_login IS NOT NULL
    GROUP BY DATE_TRUNC('week', last_login)
),
order_stats AS (
    SELECT DATE_TRUNC('week', created_at) AS week,
           COUNT(*) AS orders_count,
           COUNT(*) FILTER (WHERE status = 'delivered') AS delivered_orders,
           COALESCE(SUM(total_price) FILTER (WHERE status = 'delivered'), 0) AS weekly_revenue,
           COALESCE(AVG(total_price) FILTER (WHERE status = 'delivered'), 0) AS avg_order_value
    FROM orders
    GROUP BY DATE_TRUNC('week', created_at)
),
message_stats AS (
    SELECT DATE_TRUNC('week', created_at) AS week, COUNT(*) AS messages_count
    FROM messages
    GROUP BY DATE_TRUNC('week', created_at)
),
favorite_stats AS (
    SELECT DATE_TRUNC('week', added_at) AS week, COUNT(*) AS favorites_added
    FROM user_favoris
    GROUP BY DATE_TRUNC('week', added_at)
)
SELECT
    COALESCE(nu.week, au2.week, os.week, ms.week, fs.week) AS week,
    COALESCE(nu.new_users, 0) AS new_users,
    COALESCE(au2.active_users, 0) AS active_users,
    COALESCE(os.orders_count, 0) AS orders_count,
    COALESCE(os.delivered_orders, 0) AS delivered_orders,
    COALESCE(os.weekly_revenue, 0) AS weekly_revenue,
    COALESCE(os.avg_order_value, 0) AS avg_order_value,
    COALESCE(ms.messages_count, 0) AS messages_count,
    COALESCE(fs.favorites_added, 0) AS favorites_added
FROM new_users nu
FULL OUTER JOIN active_users au2 ON nu.week = au2.week
FULL OUTER JOIN order_stats os ON COALESCE(nu.week, au2.week) = os.week
FULL OUTER JOIN message_stats ms ON COALESCE(nu.week, au2.week, os.week) = ms.week
FULL OUTER JOIN favorite_stats fs ON COALESCE(nu.week, au2.week, os.week, ms.week) = fs.week
ORDER BY week DESC;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'daily_kpis') THEN
        COMMENT ON VIEW daily_kpis IS 'KPIs quotidiens pour suivi des tendances (corrigé : groupé par date réelle de l''événement, pas par date d''inscription)';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'monthly_trends') THEN
        COMMENT ON VIEW monthly_trends IS 'Tendances mensuelles (corrigé : groupé par date réelle de l''événement, pas par date d''inscription)';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'weekly_trends') THEN
        COMMENT ON VIEW weekly_trends IS 'Tendances hebdomadaires (corrigé : groupé par date réelle de l''événement, pas par date d''inscription)';
    END IF;
END $$;
