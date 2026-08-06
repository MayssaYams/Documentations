-- =====================================================
-- add_product_allowed_quantity_table.sql
-- La table product_allowed_quantity est référencée par product-service
-- (models.py: ProductAllowedQuantity) et par 10_indexes_and_constraints.sql
-- (liste des tables avec trigger updated_at) mais son CREATE TABLE avait été
-- oublié dans le schéma versionné — toute requête sur GET .../full_product/
-- plantait silencieusement (fallback all-empty dans la vue) sur CE point,
-- pas seulement pour les tailles. Découvert le 2026-07-24 en vérifiant
-- l'ajout des tailles produit.
-- =====================================================

BEGIN;

CREATE TABLE IF NOT EXISTS product_allowed_quantity (
    productid INTEGER PRIMARY KEY REFERENCES product(id) ON DELETE CASCADE,
    allowedquantity INTEGER NOT NULL
);

COMMENT ON TABLE product_allowed_quantity IS 'Quantité autorisée par produit (une ligne par produit)';

COMMIT;
