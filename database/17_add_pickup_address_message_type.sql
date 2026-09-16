-- ============================================================================
-- 17_add_pickup_address_message_type.sql
-- Ticket Linear PAT-51 (epic localisation PAT-43)
--
-- Contexte : quand le pâtissier fait passer une commande en « prête »
-- (status = 'ready'), order-service insère automatiquement dans la
-- conversation client ↔ pâtissier un message contenant l'adresse de retrait
-- effective (point de collecte s'il est renseigné, sinon adresse principale).
-- Ce message porte un nouveau message_type : 'pickup_address'.
--
-- La contrainte chk_message_type_valid (cf. 15_fix_message_type_constraint.sql,
-- vérifiée sur staging le 2026-09-16) n'autorise pas encore cette valeur :
--   CHECK (message_type IN ('text','image','file','system','order',
--                           'order_request','order_reply'))
-- Sans ce script, l'INSERT échoue, la transaction d'order-service est annulée
-- et le passage en « prête » répond 500 (la commande reste dans son statut
-- précédent : aucune commande « prête » sans adresse envoyée).
--
-- => À APPLIQUER AVANT de déployer la version d'order-service qui porte PAT-51.
--
-- Longueur : 'pickup_address' = 14 caractères, compatible avec
-- messages.message_type VARCHAR(20).
--
-- Idempotent : peut être rejoué sans risque. Toutes les valeurs existantes
-- sont conservées ; le DROP + ADD est fait dans une transaction, la table n'est
-- jamais sans contrainte pour les autres sessions.
-- Usage (staging) :
--   docker exec -i patisry-db psql -U patisry_backend -d patisry_db \
--     < 17_add_pickup_address_message_type.sql
-- ============================================================================

BEGIN;

ALTER TABLE messages DROP CONSTRAINT IF EXISTS chk_message_type_valid;

ALTER TABLE messages ADD CONSTRAINT chk_message_type_valid
    CHECK (message_type::text = ANY (ARRAY[
        'text', 'image', 'file', 'system', 'order',
        'order_request', 'order_reply',
        'pickup_address'
    ]::text[]));

COMMENT ON COLUMN messages.message_type IS
    'Type de message (text, image, file, system, order, order_request, order_reply, pickup_address). '
    'order_request et pickup_address sont insérés automatiquement par order-service.';

COMMIT;

-- Contrôle :
--   SELECT pg_get_constraintdef(oid) FROM pg_constraint
--   WHERE conname = 'chk_message_type_valid';
