-- =====================================================
-- add_message_reports.sql
--
-- Contexte : PAT-38 — Google Play exige un mécanisme de signalement (UGC
-- policy) sur le contenu généré par les utilisateurs. Un mécanisme identique
-- existe déjà pour les avis (review_reports, voir
-- add_review_ownership_and_reports.sql) et fonctionne en production ; ce
-- script réplique exactement le même pattern pour les messages échangés
-- entre clients et bakers.
--
-- conversation_id est dénormalisé volontairement sur message_reports (évite
-- un JOIN vers messages pour l'écran admin qui liste les signalements) ;
-- table conversations bien confirmée dans 06_messages.sql:13 (nom pluriel).
--
-- Idempotent : peut être rejoué sans risque.
-- Usage :
--   ssh -p 31456 alvin@91.171.4.184 "PGPASSWORD=admin psql -h localhost -U local -d mytestpatisry" < add_message_reports.sql
-- =====================================================

CREATE TABLE IF NOT EXISTS message_reports (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id        UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    conversation_id   UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    reporter_user_id  INTEGER NOT NULL REFERENCES accounts_user(id) ON DELETE CASCADE,
    reason            TEXT NOT NULL,
    status            VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending | dismissed | resolved
    created_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at       TIMESTAMP WITH TIME ZONE,
    resolved_by       INTEGER REFERENCES accounts_user(id),
    UNIQUE(message_id, reporter_user_id)
);

CREATE INDEX IF NOT EXISTS idx_message_reports_status ON message_reports(status);

COMMENT ON TABLE message_reports IS 'Signalements de messages abusifs par les utilisateurs, traités depuis l''admin (PAT-38, Google Play UGC policy).';
