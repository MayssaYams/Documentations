-- =====================================================
-- seed_cake_allergens.sql
-- Référentiel complet des allergènes et catégories de pâtisseries/gâteaux
-- Allergènes : 14 allergènes à déclaration obligatoire (réglement UE n° 1169/2011)
-- =====================================================
-- Idempotent (ON CONFLICT DO NOTHING) : peut être rejoué sans risque, y
-- compris si les seeds partiels de 03_products.sql ont déjà été exécutés.

-- =====================================================
-- Catégories
-- =====================================================
INSERT INTO category (name) VALUES
  ('Gâteaux'), ('Tartes'), ('Macarons'), ('Viennoiseries'),
  ('Choux'), ('Biscuits'), ('Chocolats'), ('Cupcakes'), ('Cheesecakes'), ('Layer Cakes')
  -- ('Entremets'), ('Éclairs'), ('Mille-feuilles'), ('Cookies'),
  -- ('Muffins'), ('Brownies'), ('Financiers'), ('Madeleines'),
  -- ('Cannelés'), ('Religieuses'), ('Bûches'), ('Galettes des rois'),
  -- ('Verrines'), ('Confiseries'), ('Gâteaux sur-mesure'), ('Wedding cakes')
ON CONFLICT (name) DO NOTHING;

-- =====================================================
-- Allergènes
-- =====================================================
INSERT INTO allergen (name, description) VALUES
  ('Gluten', 'Céréales contenant du gluten : blé (farine), seigle, orge, avoine — présent dans la plupart des pâtes, génoises, biscuits et viennoiseries.'),
  ('Crustacés', 'Rarement utilisé en pâtisserie sucrée, à déclarer en cas de risque de contamination croisée en atelier.'),
  ('Œufs', 'Très courant en pâtisserie : génoises, crèmes, meringues, pâtes à choux, dorure.'),
  ('Poisson', 'Rarement utilisé en pâtisserie sucrée, à déclarer en cas de risque de contamination croisée en atelier.'),
  ('Arachides', 'Cacahuètes et dérivés (pâte, huile) — présents dans certains biscuits, pralinés et décors.'),
  ('Soja', 'Lécithine de soja utilisée comme émulsifiant dans certains chocolats, margarines et pâtes à tartiner.'),
  ('Lait', 'Lait, crème, beurre, fromage — présent dans la quasi-totalité des pâtisseries (crèmes, génoises, glaçages).'),
  ('Fruits à coque', 'Amandes, noisettes, noix, noix de cajou, noix de pécan, noix du Brésil, pistaches, noix de Macadamia — poudre d''amande, pralin, décors, nougatine.'),
  ('Céleri', 'Rarement utilisé en pâtisserie sucrée, à déclarer en cas de risque de contamination croisée en atelier.'),
  ('Moutarde', 'Rarement utilisé en pâtisserie sucrée, à déclarer en cas de risque de contamination croisée en atelier.'),
  ('Graines de sésame', 'Utilisées dans certaines pâtisseries orientales (tahini, halva) et décors de graines.'),
  ('Sulfites', 'Anhydride sulfureux et sulfites (> 10 mg/kg) — présents dans les fruits secs, fruits confits et certains nappages/glaçages.'),
  ('Lupin', 'Farine de lupin, utilisée comme substitut dans certaines recettes sans gluten ou riches en protéines.'),
  ('Mollusques', 'Rarement utilisé en pâtisserie sucrée, à déclarer en cas de risque de contamination croisée en atelier.')
ON CONFLICT (name) DO NOTHING;
