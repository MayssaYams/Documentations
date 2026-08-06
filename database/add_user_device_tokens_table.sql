-- =====================================================
-- add_user_device_tokens_table.sql
--
-- Contexte : nouvelle table pour le push FCM (app + web), portée par
-- notification-service — propriétaire naturel de "comment joindre cet
-- utilisateur". UNIQUE(token) et non UNIQUE(user_id) : un même appareil
-- n'a qu'un seul token FCM ; un re-login avec un autre compte sur le même
-- appareil doit mettre à jour user_id sur la ligne existante (upsert),
-- pas en créer une nouvelle.
--
-- Idempotent : peut être rejoué sans risque.
-- Usage :
--   docker exec -i patisry-db psql -U <user> -d <db> < add_user_device_tokens_table.sql
-- =====================================================

CREATE TABLE IF NOT EXISTS user_device_tokens (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id       INTEGER NOT NULL REFERENCES accounts_user(id) ON DELETE CASCADE,
    token         TEXT NOT NULL,
    platform      VARCHAR(20) NOT NULL,   -- 'android' | 'ios' | 'web'
    device_info   JSONB,
    is_active     BOOLEAN DEFAULT TRUE,
    last_used_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(token)
);

CREATE INDEX IF NOT EXISTS idx_user_device_tokens_user_id ON user_device_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_user_device_tokens_active ON user_device_tokens(user_id, is_active) WHERE is_active = TRUE;

COMMENT ON TABLE user_device_tokens IS 'Tokens FCM enregistrés par appareil, pour le dispatch des notifications push.';
