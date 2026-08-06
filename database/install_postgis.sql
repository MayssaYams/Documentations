-- Script to install PostGIS extension
-- This must be run by a database superuser
-- Usage: psql -h localhost -p 5433 -U postgres -d mytestpatisry -f install_postgis.sql

-- Install PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- Verify installation
SELECT PostGIS_version();

