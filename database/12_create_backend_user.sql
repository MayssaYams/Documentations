-- =====================================================
-- 12_create_backend_user.sql
-- Création de l'utilisateur applicatif patisry_backend
-- Cet user est utilisé par les 15 microservices Django.
-- L'admin (patisry_admin) reste réservé aux opérations DBA.
-- =====================================================

-- Créer l'utilisateur s'il n'existe pas déjà
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'patisry_backend') THEN
    CREATE USER patisry_backend WITH PASSWORD 'kXaMuYB0a9MrKj6e1pz4hogql6pym1SZ';
    RAISE NOTICE 'Utilisateur patisry_backend créé.';
  ELSE
    -- Mettre à jour le mot de passe si l'user existe déjà
    ALTER USER patisry_backend WITH PASSWORD 'kXaMuYB0a9MrKj6e1pz4hogql6pym1SZ';
    RAISE NOTICE 'Utilisateur patisry_backend déjà existant — mot de passe mis à jour.';
  END IF;
END
$$;

-- Connexion à la base autorisée
GRANT CONNECT ON DATABASE patisry_db TO patisry_backend;

-- Accès au schéma public
GRANT USAGE ON SCHEMA public TO patisry_backend;

-- Droits sur toutes les tables existantes
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO patisry_backend;

-- Droits sur les séquences (nécessaire pour les SERIAL / auto-increment)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO patisry_backend;

-- Droits automatiques sur les futures tables créées par patisry_admin
ALTER DEFAULT PRIVILEGES FOR ROLE patisry_admin IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO patisry_backend;

ALTER DEFAULT PRIVILEGES FOR ROLE patisry_admin IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO patisry_backend;

-- Vérification
SELECT rolname, rolcanlogin FROM pg_roles WHERE rolname = 'patisry_backend';
