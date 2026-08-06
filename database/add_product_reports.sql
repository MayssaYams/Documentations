-- =====================================================
-- add_product_reports.sql
--
-- Contexte : PAT-38 — Google Play exige un mécanisme de signalement (UGC
-- policy) sur le contenu généré par les utilisateurs. Un mécanisme identique
-- existe déjà pour les avis (review_reports, voir
-- add_review_ownership_and_reports.sql) et fonctionne en production ; ce
-- script réplique exactement le même pattern pour les produits, qui sont
-- eux aussi soumis par les bakers (contenu utilisateur au sens de la policy).
--
-- product.id est un SERIAL (INTEGER), confirmé dans 03_products.sql:15.
--
-- Idempotent : peut être rejoué sans risque.
-- Usage :
--   ssh -p 31456 alvin@91.171.4.184 "PGPASSWORD=admin psql -h localhost -U local -d mytestpatisry" < add_product_reports.sql
-- =====================================================

CREATE TABLE IF NOT EXISTS product_reports (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id        INTEGER NOT NULL REFERENCES product(id) ON DELETE CASCADE,
    reporter_user_id  INTEGER NOT NULL REFERENCES accounts_user(id) ON DELETE CASCADE,
    reason            TEXT NOT NULL,
    status            VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending | dismissed | resolved
    created_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at       TIMESTAMP WITH TIME ZONE,
    resolved_by       INTEGER REFERENCES accounts_user(id),
    UNIQUE(product_id, reporter_user_id)
);

CREATE INDEX IF NOT EXISTS idx_product_reports_status ON product_reports(status);

COMMENT ON TABLE product_reports IS 'Signalements de produits abusifs par les utilisateurs, traités depuis l''admin (PAT-38, Google Play UGC policy).';
