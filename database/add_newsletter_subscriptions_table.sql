-- =====================================================
-- add_newsletter_subscriptions_table.sql
--
-- Contexte : subscription-service a un modèle NewsletterSubscription
-- (subscription_app/models.py) et une API fonctionnelle (POST/GET/DELETE
-- /newsletter/, PUT /newsletter/{id}/unsubscribe/) depuis longtemps, mais
-- aucun script SQL ne crée cette table nulle part dans le repo — dérive de
-- schéma pure. Si la base est reconstruite depuis les scripts trackés,
-- cette table n'existe pas.
--
-- Idempotent : peut être rejoué sans risque (CREATE TABLE IF NOT EXISTS).
-- Usage :
--   docker exec -i patisry-db psql -U <user> -d <db> < add_newsletter_subscriptions_table.sql
-- =====================================================

CREATE TABLE IF NOT EXISTS newsletter_subscriptions (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email       VARCHAR(254) NOT NULL,
    user_id     INTEGER REFERENCES accounts_user(id) ON DELETE SET NULL,
    is_active   BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(email, user_id)
);

CREATE INDEX IF NOT EXISTS idx_newsletter_subscriptions_email ON newsletter_subscriptions(email);
CREATE INDEX IF NOT EXISTS idx_newsletter_subscriptions_active ON newsletter_subscriptions(is_active) WHERE is_active = TRUE;

COMMENT ON TABLE newsletter_subscriptions IS 'Abonnés à la newsletter — gérée par subscription-service, consultée en lecture par admin-service.';
