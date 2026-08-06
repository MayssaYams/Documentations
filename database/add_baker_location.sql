-- =====================================================
-- add_baker_location.sql
-- Migration standalone : ajout de la table baker_location
-- À exécuter sur la base de test avant toute utilisation
-- des endpoints de proximité du display-service.
--
-- Usage:
--   psql -h localhost -p 5433 -U <user> -d mytestpatisry \
--        -f add_baker_location.sql
-- =====================================================

-- =====================================================
-- TABLE: baker_location
-- Coordonnées géographiques d'un pâtissier.
-- La colonne baker.location reste l'adresse lisible par l'humain.
-- =====================================================

CREATE TABLE IF NOT EXISTS baker_location (
    baker_id    INTEGER PRIMARY KEY REFERENCES baker(id) ON DELETE CASCADE,
    latitude    DECIMAL(10, 7) NOT NULL,
    longitude   DECIMAL(10, 7) NOT NULL,
    address_label VARCHAR(255),          -- libellé humain, ex. "Paris 75001, France"
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE  baker_location                  IS 'Coordonnées GPS des pâtissiers (séparées de baker.location qui reste textuel)';
COMMENT ON COLUMN baker_location.baker_id         IS 'Référence vers le pâtissier (1-pour-1)';
COMMENT ON COLUMN baker_location.latitude         IS 'Latitude WGS-84';
COMMENT ON COLUMN baker_location.longitude        IS 'Longitude WGS-84';
COMMENT ON COLUMN baker_location.address_label    IS 'Libellé de l adresse pour affichage (optionnel)';

-- Index composite pour les requêtes de tri par distance
CREATE INDEX IF NOT EXISTS idx_baker_location_coords
    ON baker_location (latitude, longitude);

-- =====================================================
-- TRIGGER : mise à jour automatique de updated_at
-- =====================================================

CREATE OR REPLACE FUNCTION update_baker_location_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_baker_location_updated_at ON baker_location;
CREATE TRIGGER trigger_baker_location_updated_at
    BEFORE UPDATE ON baker_location
    FOR EACH ROW
    EXECUTE FUNCTION update_baker_location_updated_at();

-- =====================================================
-- Ajout de colonnes manquantes (idempotent)
-- Au cas où le script est rejoué après un ALTER partiel
-- =====================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'baker_location' AND column_name = 'address_label'
    ) THEN
        ALTER TABLE baker_location ADD COLUMN address_label VARCHAR(255);
    END IF;
END $$;

-- =====================================================
-- Données de test (bakers parisiens fictifs)
-- INSERT ignoré si la ligne existe déjà.
-- Ces lignes seront skippées si les baker_id n'existent pas.
-- =====================================================

DO $$
BEGIN
    -- Insère des coordonnées de test pour les premiers bakers connus
    -- en évitant les violations de contrainte FK ou PK
    IF EXISTS (SELECT 1 FROM baker WHERE id = 1) THEN
        INSERT INTO baker_location (baker_id, latitude, longitude, address_label)
        VALUES (1, 48.8566, 2.3522, 'Paris 1er, France')
        ON CONFLICT (baker_id) DO NOTHING;
    END IF;

    IF EXISTS (SELECT 1 FROM baker WHERE id = 2) THEN
        INSERT INTO baker_location (baker_id, latitude, longitude, address_label)
        VALUES (2, 45.7640, 4.8357, 'Lyon 2e, France')
        ON CONFLICT (baker_id) DO NOTHING;
    END IF;

    IF EXISTS (SELECT 1 FROM baker WHERE id = 3) THEN
        INSERT INTO baker_location (baker_id, latitude, longitude, address_label)
        VALUES (3, 43.2965, 5.3698, 'Marseille 1er, France')
        ON CONFLICT (baker_id) DO NOTHING;
    END IF;
END $$;

RAISE NOTICE 'Migration add_baker_location.sql appliquée avec succès.';
