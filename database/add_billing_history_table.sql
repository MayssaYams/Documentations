-- =====================================================
-- add_billing_history_table.sql
--
-- Contexte : subscription-service a un modèle BillingHistory
-- (subscription_app/models.py) utilisé par ses vues, et la table existait
-- sur la Freebox (dev) — mais aucun script SQL ne la créait nulle part dans
-- le repo. Dérive de schéma identique à celle de newsletter_subscriptions :
-- une base reconstruite depuis les scripts trackés n'avait pas cette table,
-- ce qui a été constaté sur staging le 2026-07-27 lors de l'audit de schéma
-- Freebox <-> staging.
--
-- Définition alignée sur celle réellement en place sur la Freebox.
--
-- Idempotent : peut être rejoué sans risque (CREATE TABLE IF NOT EXISTS).
-- Usage :
--   docker exec -i patisry-db psql -U <user> -d <db> < add_billing_history_table.sql
-- =====================================================

CREATE TABLE IF NOT EXISTS billing_history (
    id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_subscription_id UUID NOT NULL REFERENCES user_subscriptions(id) ON DELETE CASCADE,
    invoice_date         TIMESTAMP WITH TIME ZONE NOT NULL,
    amount               NUMERIC(10,2) NOT NULL,
    description          TEXT
);

CREATE INDEX IF NOT EXISTS idx_billing_history_user_subscription_id
    ON billing_history(user_subscription_id);

COMMENT ON TABLE billing_history IS 'Historique de facturation des abonnements — géré par subscription-service.';
