-- =====================================================
-- test_data.sql
-- Données de référence pour les tests d'intégration
-- =====================================================

-- Extension pour UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- TABLE: allergen (données de test)
-- =====================================================

-- Insérer un allergène de test si il n'existe pas
INSERT INTO allergen (id, name, description, created_at)
VALUES (1, 'Test Allergen', 'Allergène de test pour les tests d''intégration', NOW())
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;

-- Insérer quelques allergènes supplémentaires pour les tests
INSERT INTO allergen (id, name, description, created_at)
VALUES 
    (2, 'Gluten', 'Contient du gluten', NOW()),
    (3, 'Lactose', 'Contient du lactose', NOW()),
    (4, 'Oeufs', 'Contient des oeufs', NOW())
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;

-- =====================================================
-- TABLE: category (ancienne structure - fallback)
-- =====================================================

-- Créer la table category si elle n'existe pas
CREATE TABLE IF NOT EXISTS category (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

-- Insérer une catégorie de test si elle n'existe pas
INSERT INTO category (id, name)
VALUES (1, 'Test Category')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;

-- Insérer quelques catégories supplémentaires
INSERT INTO category (id, name)
VALUES 
    (2, 'Gâteaux'),
    (3, 'Pâtisseries'),
    (4, 'Viennoiseries')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;

-- =====================================================
-- TABLE: product_categories (nouvelle structure avec UUID)
-- =====================================================

-- Insérer une catégorie de test dans product_categories si elle n'existe pas
INSERT INTO product_categories (id, name, slug, description, is_active, sort_order, created_at, updated_at)
SELECT 
    '00000000-0000-0000-0000-000000000001'::uuid,
    'Test Category',
    'test-category',
    'Catégorie de test pour les tests d''intégration',
    TRUE,
    0,
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM product_categories WHERE id = '00000000-0000-0000-0000-000000000001'::uuid
);

-- Insérer quelques catégories supplémentaires
INSERT INTO product_categories (id, name, slug, description, is_active, sort_order, created_at, updated_at)
SELECT 
    '00000000-0000-0000-0000-000000000002'::uuid,
    'Gâteaux',
    'gateaux',
    'Catégorie pour les gâteaux',
    TRUE,
    1,
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM product_categories WHERE id = '00000000-0000-0000-0000-000000000002'::uuid
)
UNION ALL
SELECT 
    '00000000-0000-0000-0000-000000000003'::uuid,
    'Pâtisseries',
    'patisseries',
    'Catégorie pour les pâtisseries',
    TRUE,
    2,
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM product_categories WHERE id = '00000000-0000-0000-0000-000000000003'::uuid
);

-- =====================================================
-- Seed catégories standard (ancienne structure - table category)
-- =====================================================

INSERT INTO category (name) VALUES
  ('Gâteaux'), ('Tartes'), ('Macarons'), ('Viennoiseries'),
  ('Choux'), ('Biscuits'), ('Chocolats'),
  ('Cupcakes'), ('Cheesecakes')
ON CONFLICT (name) DO NOTHING;

-- =====================================================
-- Seed 14 allergènes EU obligatoires
-- =====================================================

INSERT INTO allergen (name) VALUES
  ('Gluten'), ('Crustacés'), ('Œufs'), ('Poisson'),
  ('Arachides'), ('Soja'), ('Lait'), ('Fruits à coque'),
  ('Céleri'), ('Moutarde'), ('Graines de sésame')
ON CONFLICT (name) DO NOTHING;

COMMENT ON TABLE allergen IS 'Table des allergènes - données de test insérées';
COMMENT ON TABLE category IS 'Table des catégories (ancienne structure) - données de test insérées';
COMMENT ON TABLE product_categories IS 'Table des catégories (nouvelle structure) - données de test insérées';
