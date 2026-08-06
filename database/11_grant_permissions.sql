-- =====================================================
-- 11_grant_permissions.sql
-- Attribution des droits à l'utilisateur local pour les tests
-- =====================================================

-- =====================================================
-- ACCORD DES PRIVILÈGES SUR LE SCHÉMA PUBLIC
-- =====================================================

-- Accorder l'usage du schéma public
GRANT USAGE ON SCHEMA public TO local;

-- Accorder tous les privilèges sur toutes les tables existantes
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO local;

-- Accorder tous les privilèges sur toutes les séquences existantes
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO local;

-- Accorder tous les privilèges sur toutes les fonctions existantes
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO local;

-- =====================================================
-- CONFIGURATION DES PRIVILÈGES PAR DÉFAUT
-- =====================================================

-- Définir les privilèges par défaut pour les futures tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
    GRANT ALL PRIVILEGES ON TABLES TO local;

-- Définir les privilèges par défaut pour les futures séquences
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
    GRANT ALL PRIVILEGES ON SEQUENCES TO local;

-- Définir les privilèges par défaut pour les futures fonctions
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
    GRANT ALL PRIVILEGES ON FUNCTIONS TO local;

-- =====================================================
-- ACCORD DES PRIVILÈGES SUR LES VUES
-- =====================================================

-- Accorder les privilèges sur toutes les vues existantes
GRANT SELECT ON ALL TABLES IN SCHEMA public TO local;

-- Définir les privilèges par défaut pour les futures vues
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
    GRANT SELECT ON TABLES TO local;

-- =====================================================
-- ACCORD DES PRIVILÈGES SPÉCIFIQUES PAR TABLE
-- =====================================================

-- Cette section accorde explicitement les privilèges sur chaque table
-- pour s'assurer que toutes les tables sont couvertes

DO $$ 
DECLARE
    tbl_name TEXT;
BEGIN
    -- Parcourir toutes les tables du schéma public
    FOR tbl_name IN 
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_type = 'BASE TABLE'
    LOOP
        -- Accorder tous les privilèges sur la table
        EXECUTE format('GRANT ALL PRIVILEGES ON TABLE %I TO local', tbl_name);
    END LOOP;
    
    -- Parcourir toutes les séquences du schéma public
    FOR tbl_name IN 
        SELECT sequence_name 
        FROM information_schema.sequences 
        WHERE sequence_schema = 'public'
    LOOP
        -- Accorder tous les privilèges sur la séquence
        EXECUTE format('GRANT ALL PRIVILEGES ON SEQUENCE %I TO local', tbl_name);
    END LOOP;
    
    -- Parcourir toutes les vues du schéma public
    FOR tbl_name IN 
        SELECT table_name 
        FROM information_schema.views 
        WHERE table_schema = 'public'
    LOOP
        -- Accorder le privilège SELECT sur la vue
        EXECUTE format('GRANT SELECT ON TABLE %I TO local', tbl_name);
    END LOOP;
END $$;

-- =====================================================
-- VÉRIFICATION DES PRIVILÈGES
-- =====================================================

-- Afficher un résumé des privilèges accordés
DO $$ 
DECLARE
    table_count INTEGER;
    sequence_count INTEGER;
    view_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE';
    
    SELECT COUNT(*) INTO sequence_count
    FROM information_schema.sequences 
    WHERE sequence_schema = 'public';
    
    SELECT COUNT(*) INTO view_count
    FROM information_schema.views 
    WHERE table_schema = 'public';
    
    RAISE NOTICE 'Privilèges accordés à l''utilisateur local:';
    RAISE NOTICE '  - % tables', table_count;
    RAISE NOTICE '  - % séquences', sequence_count;
    RAISE NOTICE '  - % vues', view_count;
    RAISE NOTICE 'Tous les privilèges ont été accordés avec succès!';
END $$;

-- =====================================================
-- COMMENTAIRES
-- =====================================================

COMMENT ON SCHEMA public IS 'Schéma public avec tous les privilèges accordés à l''utilisateur local pour les tests';











