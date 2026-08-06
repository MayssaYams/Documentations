-- =====================================================
-- 14_admin_and_audit.sql
-- Table d'audit partagée + colonnes réelles pour remplacer les bricolages
-- de modération dans admin-service (suspension pâtissier, signalement produit)
-- =====================================================
-- Idempotent : peut être rejoué sans risque (IF NOT EXISTS partout).

-- =====================================================
-- TABLE: audit_log (traçabilité des actions sensibles)
-- =====================================================
CREATE TABLE IF NOT EXISTS audit_log (
    id BIGSERIAL PRIMARY KEY,
    occurred_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    actor_user_id INTEGER REFERENCES accounts_user(id) ON DELETE SET NULL,
    actor_email VARCHAR(255),
    actor_role VARCHAR(20),
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id VARCHAR(100),
    service_name VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'success',
    ip_address INET,
    user_agent TEXT,
    metadata JSONB
);

COMMENT ON TABLE audit_log IS 'Trace des actions sensibles (auth, actions admin, mutations produits/commandes) sur tous les services';
COMMENT ON COLUMN audit_log.actor_email IS 'Snapshot de l''email au moment de l''action, survit à la suppression du compte';
COMMENT ON COLUMN audit_log.service_name IS 'Microservice ayant écrit la ligne (auth-service, admin-service, product-service, order-service...)';
COMMENT ON COLUMN audit_log.status IS 'success ou failure (ex: tentative de connexion échouée, accès admin refusé)';

CREATE INDEX IF NOT EXISTS idx_audit_log_actor ON audit_log(actor_user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_action ON audit_log(action);
CREATE INDEX IF NOT EXISTS idx_audit_log_occurred_at ON audit_log(occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_resource ON audit_log(resource_type, resource_id);

-- =====================================================
-- Suspension admin d'un pâtissier
-- =====================================================
-- Note : baker.is_verified existe déjà — réutilisé pour "vérifier", pas de
-- nouvelle colonne pour ça. Seule la suspension (distincte de la propre
-- désactivation du pâtissier via is_active/accepts_orders) a besoin de
-- métadonnées dédiées pour savoir qui a suspendu, quand, pourquoi.
ALTER TABLE baker ADD COLUMN IF NOT EXISTS suspended_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE baker ADD COLUMN IF NOT EXISTS suspension_reason TEXT;
ALTER TABLE baker ADD COLUMN IF NOT EXISTS suspended_by INTEGER REFERENCES accounts_user(id) ON DELETE SET NULL;

COMMENT ON COLUMN baker.suspended_at IS 'Date de suspension par un admin (NULL si jamais suspendu ou levé)';
COMMENT ON COLUMN baker.suspended_by IS 'Admin ayant prononcé la suspension';

-- =====================================================
-- Signalement produit
-- =====================================================
-- Note : product.is_featured existe déjà — réutilisé pour "mettre en avant".
-- Remplace le proxy "average_rating <= 1.0" qui servait de faux indicateur
-- de signalement.
ALTER TABLE product ADD COLUMN IF NOT EXISTS is_flagged BOOLEAN DEFAULT FALSE;
ALTER TABLE product ADD COLUMN IF NOT EXISTS flag_reason TEXT;

COMMENT ON COLUMN product.is_flagged IS 'Produit signalé par un admin (modération), remplace le proxy sur average_rating';
