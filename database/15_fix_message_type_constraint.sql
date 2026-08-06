-- ============================================================================
-- 15_fix_message_type_constraint.sql
--
-- Contexte : chk_message_type_valid (créée dans 06_messages.sql) n'autorisait
-- que 'text', 'image', 'file', 'system', 'order' — mais order-service (checkout)
-- et l'app Flutter (réponse baker) insèrent respectivement 'order_request' et
-- 'order_reply' depuis le début. Chaque tentative d'insertion violait la
-- contrainte, était avalée par un except silencieux côté order-service, et
-- aucun message de commande n'a donc jamais pu être créé.
--
-- Idempotent : peut être rejoué sans risque.
-- Usage :
--   docker exec -i patisry-db psql -U <user> -d <db> < 15_fix_message_type_constraint.sql
-- ============================================================================

ALTER TABLE messages DROP CONSTRAINT IF EXISTS chk_message_type_valid;

ALTER TABLE messages ADD CONSTRAINT chk_message_type_valid
    CHECK (message_type::text = ANY (ARRAY[
        'text', 'image', 'file', 'system', 'order',
        'order_request', 'order_reply'
    ]::text[]));

COMMENT ON COLUMN messages.message_type IS
    'Type de message (text, image, file, system, order, order_request, order_reply)';
