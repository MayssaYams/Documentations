-- =====================================================
-- add_review_ownership_and_reports.sql
--
-- Contexte : le endpoint de création d'avis (review-service) faisait confiance
-- au user_id envoyé par le client au lieu du JWT authentifié, et n'importe qui
-- pouvait laisser un avis sans jamais avoir commandé (order_id jamais vérifié).
-- Ce script :
--   1. Rend order_id obligatoire + lui ajoute une vraie FK vers orders(id)
--      (promise jamais tenue dans 03_products.sql:388).
--   2. Remplace UNIQUE(product_id, user_id) par UNIQUE(order_id, product_id)
--      pour permettre un avis par commande (au lieu d'un avis à vie/produit).
--   3. Ajoute review_reports (signalements d'avis abusifs).
--   4. Ajoute baker_reply/baker_reply_at (réponse du pâtissier à un avis).
--   5. Ajoute platform_settings (clé/valeur) + seed du seuil de commandes
--      nécessaire avant d'afficher la note d'un pâtissier.
--   6. Étend trigger_product_reviews_counters pour recalculer la note produit
--      aussi sur UPDATE (elle ne l'était que sur INSERT/DELETE — bug trouvé
--      en marge, la note ne se mettait jamais à jour quand un avis existant
--      était modifié).
--
-- Vérifié sur Freebox (dev) le 2026-07-25 : product_reviews est vide (0 ligne,
-- 0 order_id NULL) — NOT NULL/FK appliqués directement, aucun backfill requis.
--
-- Idempotent : peut être rejoué sans risque.
-- Usage :
--   ssh -p 31456 alvin@91.171.4.184 "PGPASSWORD=admin psql -h localhost -U local -d mytestpatisry" < add_review_ownership_and_reports.sql
-- =====================================================

-- ---------------------------------------------------------
-- 1 + 2. order_id obligatoire, FK, nouvelle contrainte d'unicité
-- ---------------------------------------------------------
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'product_reviews_product_id_user_id_key'
        AND table_name = 'product_reviews'
    ) THEN
        ALTER TABLE product_reviews DROP CONSTRAINT product_reviews_product_id_user_id_key;
    END IF;
END $$;

ALTER TABLE product_reviews ALTER COLUMN order_id SET NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'product_reviews_order_id_fkey'
        AND table_name = 'product_reviews'
    ) THEN
        ALTER TABLE product_reviews
            ADD CONSTRAINT product_reviews_order_id_fkey
            FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'product_reviews_order_id_product_id_key'
        AND table_name = 'product_reviews'
    ) THEN
        ALTER TABLE product_reviews
            ADD CONSTRAINT product_reviews_order_id_product_id_key
            UNIQUE (order_id, product_id);
    END IF;
END $$;

-- ---------------------------------------------------------
-- 3. Signalements d'avis
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS review_reports (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    review_id         UUID NOT NULL REFERENCES product_reviews(id) ON DELETE CASCADE,
    reporter_user_id  INTEGER NOT NULL REFERENCES accounts_user(id) ON DELETE CASCADE,
    reason            TEXT NOT NULL,
    status            VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending | dismissed | resolved
    created_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at       TIMESTAMP WITH TIME ZONE,
    resolved_by       INTEGER REFERENCES accounts_user(id),
    UNIQUE(review_id, reporter_user_id)
);

CREATE INDEX IF NOT EXISTS idx_review_reports_status ON review_reports(status);

COMMENT ON TABLE review_reports IS 'Signalements d''avis abusifs par les utilisateurs, traités depuis l''admin.';

-- ---------------------------------------------------------
-- 4. Réponse du pâtissier à un avis
-- ---------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product_reviews' AND column_name = 'baker_reply') THEN
        ALTER TABLE product_reviews ADD COLUMN baker_reply TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product_reviews' AND column_name = 'baker_reply_at') THEN
        ALTER TABLE product_reviews ADD COLUMN baker_reply_at TIMESTAMP WITH TIME ZONE;
    END IF;
END $$;

-- ---------------------------------------------------------
-- 5. Réglages globaux (clé/valeur) — seuil d'affichage de la note pâtissier
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS platform_settings (
    key         VARCHAR(100) PRIMARY KEY,
    value       TEXT NOT NULL,
    updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_by  INTEGER REFERENCES accounts_user(id)
);

INSERT INTO platform_settings (key, value)
VALUES ('min_orders_for_baker_rating', '10')
ON CONFLICT (key) DO NOTHING;

COMMENT ON TABLE platform_settings IS 'Réglages globaux de la plateforme, modifiables depuis l''admin (clé/valeur).';

-- ---------------------------------------------------------
-- 6. La note produit ne se recalculait pas sur UPDATE (seulement
--    INSERT/DELETE) — un avis modifié ne changeait jamais average_rating.
-- ---------------------------------------------------------
CREATE OR REPLACE FUNCTION update_product_counters()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_TABLE_NAME = 'product_reviews' THEN
        IF TG_OP = 'INSERT' THEN
            UPDATE product SET
                reviews_count = reviews_count + 1,
                average_rating = (
                    SELECT AVG(rating)::DECIMAL(3,2)
                    FROM product_reviews
                    WHERE product_id = NEW.product_id
                )
            WHERE id = NEW.product_id;
        ELSIF TG_OP = 'UPDATE' THEN
            UPDATE product SET
                average_rating = (
                    SELECT AVG(rating)::DECIMAL(3,2)
                    FROM product_reviews
                    WHERE product_id = NEW.product_id
                )
            WHERE id = NEW.product_id;
        ELSIF TG_OP = 'DELETE' THEN
            UPDATE product SET
                reviews_count = reviews_count - 1,
                average_rating = (
                    SELECT COALESCE(AVG(rating)::DECIMAL(3,2), 0)
                    FROM product_reviews
                    WHERE product_id = OLD.product_id
                )
            WHERE id = OLD.product_id;
        END IF;
    ELSIF TG_TABLE_NAME = 'product_views' THEN
        IF TG_OP = 'INSERT' THEN
            UPDATE product SET views_count = views_count + 1 WHERE id = NEW.product_id;
        END IF;
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_product_reviews_counters ON product_reviews;
CREATE TRIGGER trigger_product_reviews_counters
    AFTER INSERT OR DELETE ON product_reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_product_counters();

DROP TRIGGER IF EXISTS trigger_product_reviews_counters_update ON product_reviews;
CREATE TRIGGER trigger_product_reviews_counters_update
    AFTER UPDATE OF rating ON product_reviews
    FOR EACH ROW
    WHEN (OLD.rating IS DISTINCT FROM NEW.rating)
    EXECUTE FUNCTION update_product_counters();
