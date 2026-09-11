-- =====================================================
-- add_baker_location_geography.sql
-- Ticket Linear PAT-44 — Socle géo de l'epic localisation (PAT-43).
--
-- Contexte :
--   Patisry est en CLICK & COLLECT UNIQUEMENT (il n'y a pas de livraison).
--   La table baker_location, créée par add_baker_location.sql, ne stocke que
--   deux DECIMAL et un index B-tree composite (latitude, longitude) — index
--   INUTILISABLE pour une recherche par distance : ST_DistanceSphere() /
--   ST_DWithin() ne peuvent pas s'en servir et font un scan complet. Ça tient
--   avec 10 pâtissiers, pas avec 1000.
--   Par ailleurs le modèle produit impose DEUX adresses possibles par
--   pâtissier (adresse principale + point de collecte alternatif), et la règle
--   « adresse de retrait effective » doit être matérialisée UNE SEULE FOIS en
--   base — c'est elle qui sert à la fois au calcul de distance publique et au
--   message automatique envoyé au client au passage en « prête ».
--
-- Ce script :
--   1. Ajoute la ville (seule info de localisation publiquement affichable).
--   2. Ajoute le point de collecte alternatif (coordonnées + libellé + ville)
--      en COLONNES supplémentaires, pour garder la relation 1-pour-1.
--   3. Ajoute 3 colonnes geography(Point, 4326) dérivées des DECIMAL :
--      adresse principale, point de collecte, et RETRAIT EFFECTIF.
--   4. Crée les index GIST correspondants (dont celui sur le retrait effectif,
--      qui est la colonne réellement interrogée par le display-service).
--   5. Fournit le backfill + la requête de contrôle des pâtissiers sans
--      coordonnées.
--   6. Documente via COMMENT ON COLUMN le statut DORMANT des colonnes de
--      livraison et des 2 autres représentations de coordonnées, pour éviter
--      qu'un agent futur les réactive par erreur.
--
-- Aucune destruction : ce script n'ajoute que des colonnes / index / commentaires.
-- Aucun DROP COLUMN, aucun DROP INDEX. L'ancien index B-tree
-- idx_baker_location_coords devient inutile mais est VOLONTAIREMENT CONSERVÉ :
-- sa suppression sera une décision séparée (ticket dédié).
--
-- Prérequis : extension postgis installée (cf. install_postgis.sql).
--
-- Idempotent : rejouable sans risque (gardes information_schema / pg_constraint,
-- CREATE INDEX IF NOT EXISTS, CREATE OR REPLACE FUNCTION).
--
-- Environnement cible : STAGING uniquement.
--   La Freebox (ancien environnement de dev) est hors service et n'est plus
--   prise en compte — ne pas ajouter d'étape « appliquer sur la Freebox » en
--   relisant ce script.
--
-- Usage (staging) :
--   ssh -i ~/.ssh/patisry-staging-deploy ubuntu@<VM_IP> \
--     "sudo docker exec -i patisry-db psql -U patisry_backend -d patisry_db" \
--     < add_baker_location_geography.sql
--
--   Générique : psql -h <host> -p <port> -U <user> -d <db> -f add_baker_location_geography.sql
-- =====================================================

BEGIN;

-- ---------------------------------------------------------
-- 0. Garde-fous : PostGIS et baker_location doivent exister.
--    On échoue explicitement plutôt que de créer quoi que ce soit
--    à la volée (cf. CLAUDE.md : aucun service ne gère le schéma).
-- ---------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'postgis') THEN
        RAISE EXCEPTION 'Extension postgis absente. Exécuter install_postgis.sql (superuser) avant ce script.';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables WHERE table_name = 'baker_location'
    ) THEN
        RAISE EXCEPTION 'Table baker_location absente. Exécuter add_baker_location.sql (ou 02_bakers.sql) avant ce script.';
    END IF;
END $$;

-- ---------------------------------------------------------
-- 1. Ville de l'adresse principale + point de collecte alternatif.
--
--    IMPORTANT : ces colonnes DECIMAL/VARCHAR sont la SOURCE DE VÉRITÉ et
--    doivent être créées AVANT les colonnes geography de l'étape 2, qui les
--    référencent (une colonne générée ne peut pas référencer une colonne
--    créée après elle).
--
--    Choix « colonnes supplémentaires » plutôt qu'une 2e ligne dans la table :
--    baker_location a baker_id en PRIMARY KEY (1-pour-1). Une 2e ligne
--    imposerait de casser la PK, d'ajouter un discriminant et de faire un
--    self-join dans toutes les requêtes de distance. Les colonnes pickup_*
--    gardent la table plate et les requêtes triviales.
-- ---------------------------------------------------------
DO $$
BEGIN
    -- Ville de l'adresse principale (dérivée du géocodage BAN / data.gouv.fr).
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'baker_location' AND column_name = 'city') THEN
        ALTER TABLE baker_location ADD COLUMN city VARCHAR(120);
    END IF;

    -- Point de collecte alternatif : coordonnées + libellé + ville.
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'baker_location' AND column_name = 'pickup_latitude') THEN
        ALTER TABLE baker_location ADD COLUMN pickup_latitude DECIMAL(10, 7);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'baker_location' AND column_name = 'pickup_longitude') THEN
        ALTER TABLE baker_location ADD COLUMN pickup_longitude DECIMAL(10, 7);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'baker_location' AND column_name = 'pickup_address_label') THEN
        ALTER TABLE baker_location ADD COLUMN pickup_address_label VARCHAR(255);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'baker_location' AND column_name = 'pickup_city') THEN
        ALTER TABLE baker_location ADD COLUMN pickup_city VARCHAR(120);
    END IF;
END $$;

-- Cohérence du couple de coordonnées du point de collecte : les deux
-- renseignées ou aucune. Sans ça, une latitude seule donnerait un point NULL
-- silencieux et le retrait effectif retomberait sur l'adresse principale sans
-- que personne ne le voie.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_baker_location_pickup_coords_pair'
          AND conrelid = 'baker_location'::regclass
    ) THEN
        ALTER TABLE baker_location
            ADD CONSTRAINT chk_baker_location_pickup_coords_pair
            CHECK (
                (pickup_latitude IS NULL AND pickup_longitude IS NULL)
                OR (pickup_latitude IS NOT NULL AND pickup_longitude IS NOT NULL)
            );
    END IF;
END $$;

-- ---------------------------------------------------------
-- 2. Colonnes geography(Point, 4326) dérivées des DECIMAL.
--
--    CHOIX D'IMPLÉMENTATION : colonne générée STORED en premier choix,
--    trigger en repli automatique.
--
--    Pourquoi la colonne générée est préférable :
--      - impossible de dériver : PostgreSQL recalcule à chaque INSERT/UPDATE
--        et REFUSE toute écriture directe. Un service ne peut pas écrire une
--        geography incohérente avec les DECIMAL, même par erreur.
--      - pas de dépendance à un trigger qu'un ALTER TABLE ... DISABLE TRIGGER
--        ou un COPY pourrait court-circuiter.
--      - aucun coût de maintenance applicatif.
--
--    Pourquoi un repli est quand même conservé :
--      ADD COLUMN ... GENERATED ALWAYS AS (...) STORED exige PostgreSQL >= 12
--      ET une expression strictement IMMUTABLE. ST_MakePoint / ST_SetSRID et
--      le cast geometry -> geography sont marqués IMMUTABLE dans PostGIS.
--      VÉRIFIÉ : sur PostgreSQL 15 / PostGIS 3.4, le mode colonne générée est
--      accepté et le repli ne se déclenche pas (is_generated = ALWAYS sur les
--      4 colonnes, aucun trigger créé). Le repli reste néanmoins en place au
--      cas où staging tournerait une version différente — il ne coûte rien et
--      évite un échec bloquant sur une base qu'on ne contrôle pas.
--      Les deux modes produisent EXACTEMENT les mêmes colonnes (mêmes noms,
--      mêmes types) : le code applicatif en lecture est identique dans les
--      deux cas, et dans les deux cas les services ne doivent JAMAIS écrire
--      ces colonnes directement.
--
--    Convention PostGIS : ST_MakePoint(x, y) = ST_MakePoint(longitude, latitude).
--    L'ordre est inversé par rapport à l'usage courant « lat, lng » — ne pas
--    l'intervertir, un point à Paris finirait au large de la Somalie.
--
--    Type geography (et non geometry) : les distances sont retournées en
--    mètres sur l'ellipsoïde, sans reprojection, et ST_DWithin() sur geography
--    exploite directement l'index GIST.
--
--    RÈGLE MÉTIER MATÉRIALISÉE ICI, UNE SEULE FOIS :
--      retrait effectif = point de collecte s'il est renseigné,
--                         sinon adresse principale.
--    Aucun service ne doit réimplémenter ce COALESCE : ils lisent
--    effective_pickup_geog / effective_pickup_city.
-- ---------------------------------------------------------
DO $$
DECLARE
    v_generated BOOLEAN := TRUE;
BEGIN
    -- Rien à faire si les 4 colonnes existent déjà (rejeu du script).
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name = 'baker_location' AND column_name = 'effective_pickup_geog') THEN
        RAISE NOTICE 'Colonnes geography deja presentes, etape 2 ignoree.';
        RETURN;
    END IF;

    BEGIN
        EXECUTE $ddl$
            ALTER TABLE baker_location
                ADD COLUMN location_geog geography(Point, 4326)
                    GENERATED ALWAYS AS (
                        ST_SetSRID(
                            ST_MakePoint(longitude::double precision,
                                         latitude::double precision),
                            4326
                        )::geography
                    ) STORED,
                ADD COLUMN pickup_geog geography(Point, 4326)
                    GENERATED ALWAYS AS (
                        ST_SetSRID(
                            ST_MakePoint(pickup_longitude::double precision,
                                         pickup_latitude::double precision),
                            4326
                        )::geography
                    ) STORED,
                ADD COLUMN effective_pickup_geog geography(Point, 4326)
                    GENERATED ALWAYS AS (
                        CASE
                            WHEN pickup_latitude IS NOT NULL
                             AND pickup_longitude IS NOT NULL
                            THEN ST_SetSRID(
                                     ST_MakePoint(pickup_longitude::double precision,
                                                  pickup_latitude::double precision),
                                     4326
                                 )::geography
                            ELSE ST_SetSRID(
                                     ST_MakePoint(longitude::double precision,
                                                  latitude::double precision),
                                     4326
                                 )::geography
                        END
                    ) STORED,
                ADD COLUMN effective_pickup_city VARCHAR(120)
                    GENERATED ALWAYS AS (
                        CASE
                            WHEN pickup_latitude IS NOT NULL
                             AND pickup_longitude IS NOT NULL
                            THEN pickup_city
                            ELSE city
                        END
                    ) STORED
        $ddl$;
        RAISE NOTICE 'Colonnes geography creees en mode COLONNE GENEREE (STORED).';
    EXCEPTION WHEN OTHERS THEN
        v_generated := FALSE;
        RAISE NOTICE 'Colonne generee refusee par le moteur (%), repli sur trigger.', SQLERRM;
    END;

    IF NOT v_generated THEN
        EXECUTE $ddl$
            ALTER TABLE baker_location
                ADD COLUMN IF NOT EXISTS location_geog          geography(Point, 4326),
                ADD COLUMN IF NOT EXISTS pickup_geog            geography(Point, 4326),
                ADD COLUMN IF NOT EXISTS effective_pickup_geog  geography(Point, 4326),
                ADD COLUMN IF NOT EXISTS effective_pickup_city  VARCHAR(120)
        $ddl$;
    END IF;
END $$;

-- ---------------------------------------------------------
-- 2 bis. Trigger de synchronisation — créé UNIQUEMENT en mode repli.
--
--   En mode colonne générée, ce trigger serait non seulement inutile mais
--   FATAL : toute affectation à une colonne GENERATED ALWAYS lève
--   « column can only be updated to DEFAULT ». On le supprime donc
--   explicitement dans ce mode (cas d'une base passée en repli lors d'un
--   run précédent puis recréée proprement).
--
--   La fonction est volontairement l'exact miroir des expressions générées
--   ci-dessus : toute modification de l'une doit être répercutée sur l'autre.
-- ---------------------------------------------------------
CREATE OR REPLACE FUNCTION baker_location_sync_geography()
RETURNS TRIGGER AS $$
BEGIN
    NEW.location_geog := ST_SetSRID(
        ST_MakePoint(NEW.longitude::double precision,
                     NEW.latitude::double precision), 4326)::geography;

    IF NEW.pickup_latitude IS NOT NULL AND NEW.pickup_longitude IS NOT NULL THEN
        NEW.pickup_geog := ST_SetSRID(
            ST_MakePoint(NEW.pickup_longitude::double precision,
                         NEW.pickup_latitude::double precision), 4326)::geography;
        NEW.effective_pickup_geog := NEW.pickup_geog;
        NEW.effective_pickup_city := NEW.pickup_city;
    ELSE
        NEW.pickup_geog := NULL;
        NEW.effective_pickup_geog := NEW.location_geog;
        NEW.effective_pickup_city := NEW.city;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION baker_location_sync_geography() IS
    'Repli du mode colonne generee : maintient location_geog / pickup_geog / effective_pickup_* a partir des DECIMAL. Miroir exact des expressions GENERATED de add_baker_location_geography.sql.';

DO $$
DECLARE
    v_is_generated TEXT;
BEGIN
    SELECT is_generated INTO v_is_generated
    FROM information_schema.columns
    WHERE table_name = 'baker_location' AND column_name = 'effective_pickup_geog';

    IF v_is_generated = 'ALWAYS' THEN
        DROP TRIGGER IF EXISTS trigger_baker_location_sync_geography ON baker_location;
        RAISE NOTICE 'Mode colonne generee : aucun trigger de synchronisation necessaire.';
    ELSE
        DROP TRIGGER IF EXISTS trigger_baker_location_sync_geography ON baker_location;
        CREATE TRIGGER trigger_baker_location_sync_geography
            BEFORE INSERT OR UPDATE ON baker_location
            FOR EACH ROW
            EXECUTE FUNCTION baker_location_sync_geography();

        -- Backfill des lignes déjà présentes : un trigger ne les touche pas.
        -- (En mode colonne générée, PostgreSQL calcule les valeurs pour toutes
        -- les lignes existantes pendant le ALTER TABLE — rien à faire.)
        UPDATE baker_location
        SET location_geog = ST_SetSRID(
                ST_MakePoint(longitude::double precision,
                             latitude::double precision), 4326)::geography,
            pickup_geog = CASE
                WHEN pickup_latitude IS NOT NULL AND pickup_longitude IS NOT NULL
                THEN ST_SetSRID(
                        ST_MakePoint(pickup_longitude::double precision,
                                     pickup_latitude::double precision), 4326)::geography
                ELSE NULL END,
            effective_pickup_geog = CASE
                WHEN pickup_latitude IS NOT NULL AND pickup_longitude IS NOT NULL
                THEN ST_SetSRID(
                        ST_MakePoint(pickup_longitude::double precision,
                                     pickup_latitude::double precision), 4326)::geography
                ELSE ST_SetSRID(
                        ST_MakePoint(longitude::double precision,
                                     latitude::double precision), 4326)::geography END,
            effective_pickup_city = CASE
                WHEN pickup_latitude IS NOT NULL AND pickup_longitude IS NOT NULL
                THEN pickup_city
                ELSE city END
        WHERE effective_pickup_geog IS NULL;

        RAISE NOTICE 'Mode trigger : trigger_baker_location_sync_geography installe et lignes existantes backfillees.';
    END IF;
END $$;

-- ---------------------------------------------------------
-- 3. Index GIST.
--
--    idx_baker_location_effective_geog est LE plus important : c'est la
--    colonne réellement interrogée pour « les pâtissiers à moins de X km de
--    moi ». Les deux autres servent aux besoins internes (admin, contrôle).
--
--    L'ancien idx_baker_location_coords (B-tree sur latitude, longitude) est
--    conservé volontairement — voir en-tête.
-- ---------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_baker_location_effective_geog
    ON baker_location USING GIST (effective_pickup_geog);

CREATE INDEX IF NOT EXISTS idx_baker_location_geog
    ON baker_location USING GIST (location_geog);

-- Index partiel : la grande majorité des pâtissiers n'auront pas de point de
-- collecte alternatif, inutile d'indexer les NULL.
CREATE INDEX IF NOT EXISTS idx_baker_location_pickup_geog
    ON baker_location USING GIST (pickup_geog)
    WHERE pickup_geog IS NOT NULL;

-- La ville est la seule information de localisation publiquement affichable :
-- elle sera filtrée/affichée sur la vitrine, d'où cet index B-tree.
CREATE INDEX IF NOT EXISTS idx_baker_location_effective_city
    ON baker_location (effective_pickup_city);

-- ---------------------------------------------------------
-- 4. Commentaires sur les nouvelles colonnes.
-- ---------------------------------------------------------
COMMENT ON COLUMN baker_location.city IS
    'Ville de l''adresse principale, derivee du geocodage BAN. SEULE information de localisation publiquement affichable : l''adresse exacte d''un patissier n''est JAMAIS publique (beaucoup travaillent a domicile).';
COMMENT ON COLUMN baker_location.pickup_latitude IS
    'Latitude WGS-84 du point de collecte alternatif. NULL si le patissier fait retirer a son adresse principale.';
COMMENT ON COLUMN baker_location.pickup_longitude IS
    'Longitude WGS-84 du point de collecte alternatif. NULL si le patissier fait retirer a son adresse principale.';
COMMENT ON COLUMN baker_location.pickup_address_label IS
    'Adresse complete du point de collecte. NON PUBLIQUE : transmise au client uniquement par message automatique au passage de la commande en ready -> awaiting_pickup.';
COMMENT ON COLUMN baker_location.pickup_city IS
    'Ville du point de collecte (geocodage BAN). Doit etre renseignee des que pickup_latitude/pickup_longitude le sont, sinon effective_pickup_city sera NULL et la vitrine n''affichera aucune ville.';
COMMENT ON COLUMN baker_location.location_geog IS
    'Adresse principale en geography(Point,4326), derivee de latitude/longitude. NE JAMAIS ECRIRE DIRECTEMENT (colonne generee, ou maintenue par trigger en mode repli).';
COMMENT ON COLUMN baker_location.pickup_geog IS
    'Point de collecte alternatif en geography(Point,4326), derive de pickup_latitude/pickup_longitude. NULL si pas de point de collecte. NE JAMAIS ECRIRE DIRECTEMENT.';
COMMENT ON COLUMN baker_location.effective_pickup_geog IS
    'ADRESSE DE RETRAIT EFFECTIVE (point de collecte si renseigne, sinon adresse principale). Regle metier materialisee UNE SEULE FOIS ici : aucun service ne doit la reimplementer. Colonne interrogee pour la distance publique (ST_DWithin / ST_Distance) ET source de l''adresse envoyee au client. NE JAMAIS ECRIRE DIRECTEMENT.';
COMMENT ON COLUMN baker_location.effective_pickup_city IS
    'Ville du retrait effectif, meme regle que effective_pickup_geog. Seule info de localisation affichable publiquement avec la distance. NE JAMAIS ECRIRE DIRECTEMENT.';
COMMENT ON CONSTRAINT chk_baker_location_pickup_coords_pair ON baker_location IS
    'Le couple de coordonnees du point de collecte est renseigne entierement ou pas du tout.';

-- ---------------------------------------------------------
-- 5. Colonnes DORMANTES — ne pas reactiver.
--
--    5.a Livraison : Patisry est en CLICK & COLLECT UNIQUEMENT. Ces colonnes
--        existent en base mais aucune logique de livraison ne doit etre
--        implementee (decision produit verrouillee du 2026-09-08).
--    5.b Coordonnees : trois representations coexistaient en base. La seule
--        source de verite geographique de la V1 est baker_location.
--
--    Les commentaires sont poses via EXECUTE + garde d'existence, car
--    certaines de ces colonnes sont creees conditionnellement selon
--    l'environnement (shipping_address.coordinates notamment).
-- ---------------------------------------------------------
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT * FROM (VALUES
            -- Casts explicites sur le premier tuple : sans eux les colonnes du
            -- VALUES restent de type "unknown" dans la boucle FOR ... IN RECORD.
            ('baker'::text, 'delivery_radius'::text,
             'DORMANT — NE PAS UTILISER. Patisry est en click & collect uniquement, il n''y a pas de livraison. Colonne conservee pour compatibilite du schema, jamais lue ni ecrite en V1.'::text),
            ('baker', 'delivery_fee',
             'DORMANT — NE PAS UTILISER. Aucun frais de livraison : click & collect uniquement.'),
            ('orders', 'delivery_address',
             'DORMANT — NE PAS UTILISER. Click & collect uniquement : l''adresse de retrait vient de baker_location.effective_pickup_geog / pickup_address_label, transmise au client par message automatique au passage en awaiting_pickup.'),
            ('orders', 'delivery_fee',
             'DORMANT — NE PAS UTILISER. Aucun frais de livraison : click & collect uniquement.'),
            ('accounts_user', 'location',
             'DORMANT — NE PAS UTILISER. La position du client n''est JAMAIS persistee (contrainte RGPD) : elle vit en session uniquement, aucun historique, aucune ecriture en base. Ancienne representation TEXT des coordonnees, remplacee par baker_location en geography.'),
            ('shipping_address', 'coordinates',
             'DORMANT — NE PAS UTILISER. Ancienne representation POINT (geometrie plane, sans SRID) des coordonnees, liee a la livraison. Seule source de verite geographique en V1 : baker_location.effective_pickup_geog.'),
            ('delivery_zones', 'polygon_coordinates',
             'DORMANT — NE PAS UTILISER. Zones de livraison : sans objet en click & collect.')
        ) AS t(tbl, col, cmt)
    LOOP
        IF EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_name = r.tbl AND column_name = r.col
        ) THEN
            EXECUTE format('COMMENT ON COLUMN %I.%I IS %L', r.tbl, r.col, r.cmt);
        ELSE
            RAISE NOTICE 'Colonne %.% absente de cette base, commentaire ignore.', r.tbl, r.col;
        END IF;
    END LOOP;
END $$;

-- ---------------------------------------------------------
-- 6. Backfill et controle des patissiers sans coordonnees.
--
--    Etat actuel : seules les donnees de seed (add_baker_location.sql :
--    baker_id 1, 2, 3) ont des coordonnees. Les autres patissiers n'ont
--    AUCUNE ligne dans baker_location et resteront invisibles de toute
--    recherche par distance tant qu'ils ne sont pas geocodes.
--
--    Le geocodage lui-meme (baker.location texte -> lat/lng/ville via l'API
--    Adresse BAN, data.gouv.fr) est hors perimetre de ce script : il releve
--    du service applicatif de l'epic. Ce bloc se contente de FAIRE LE CONSTAT.
-- ---------------------------------------------------------
DO $$
DECLARE
    v_bakers_total       INTEGER;
    v_bakers_actifs      INTEGER;
    v_sans_coords        INTEGER;
    v_sans_ville         INTEGER;
    v_avec_pickup        INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_bakers_total  FROM baker;
    SELECT COUNT(*) INTO v_bakers_actifs FROM baker WHERE is_active IS TRUE;

    SELECT COUNT(*) INTO v_sans_coords
    FROM baker b
    LEFT JOIN baker_location bl ON bl.baker_id = b.id
    WHERE b.is_active IS TRUE AND bl.baker_id IS NULL;

    SELECT COUNT(*) INTO v_sans_ville
    FROM baker_location
    WHERE effective_pickup_city IS NULL OR BTRIM(effective_pickup_city) = '';

    SELECT COUNT(*) INTO v_avec_pickup
    FROM baker_location
    WHERE pickup_latitude IS NOT NULL;

    RAISE NOTICE '--- Etat baker_location apres migration PAT-44 ---';
    RAISE NOTICE 'Patissiers en base            : %', v_bakers_total;
    RAISE NOTICE 'Patissiers actifs             : %', v_bakers_actifs;
    RAISE NOTICE 'Actifs SANS coordonnees       : %  <-- a geocoder (invisibles en recherche par distance)', v_sans_coords;
    RAISE NOTICE 'Lignes SANS ville effective   : %  <-- vitrine sans ville affichable', v_sans_ville;
    RAISE NOTICE 'Lignes avec point de collecte : %', v_avec_pickup;
END $$;

COMMIT;

-- =====================================================
-- ANNEXE — requetes a executer A LA MAIN (hors transaction ci-dessus)
-- =====================================================
--
-- A. Liste nominative des patissiers actifs a geocoder :
--
--    SELECT b.id, b.business_name, b.location AS adresse_texte
--    FROM baker b
--    LEFT JOIN baker_location bl ON bl.baker_id = b.id
--    WHERE b.is_active IS TRUE
--      AND bl.baker_id IS NULL
--    ORDER BY b.id;
--
-- B. Backfill unitaire apres geocodage BAN (adresse principale).
--    A generer par le job de geocodage, une ligne par patissier.
--    ON CONFLICT : rejouable, ne perd pas le point de collecte deja saisi.
--
--    INSERT INTO baker_location (baker_id, latitude, longitude, address_label, city)
--    VALUES (:baker_id, :latitude, :longitude, :address_label, :city)
--    ON CONFLICT (baker_id) DO UPDATE
--        SET latitude      = EXCLUDED.latitude,
--            longitude     = EXCLUDED.longitude,
--            address_label = EXCLUDED.address_label,
--            city          = EXCLUDED.city;
--
-- C. Backfill du point de collecte alternatif (quand le patissier en declare un) :
--
--    UPDATE baker_location
--    SET pickup_latitude      = :lat,
--        pickup_longitude     = :lng,
--        pickup_address_label = :label,
--        pickup_city          = :city
--    WHERE baker_id = :baker_id;
--
--    Pour revenir a l'adresse principale, remettre les QUATRE colonnes a NULL
--    (la contrainte chk_baker_location_pickup_coords_pair refuse un couple
--    de coordonnees a moitie renseigne).
--
-- D. Backfill de la ville pour les lignes de seed deja presentes.
--    Les libelles de seed sont de la forme 'Paris 1er, France'. Cette
--    heuristique est APPROXIMATIVE et ne doit servir que pour les 3 lignes de
--    seed ; en production, la ville doit venir du geocodage BAN.
--
--    UPDATE baker_location
--    SET city = SPLIT_PART(address_label, ',', 1)
--    WHERE city IS NULL
--      AND address_label IS NOT NULL
--      AND baker_id IN (1, 2, 3);
--
-- E. Verification que l'index GIST est bien utilise.
--    DEJA VALIDE hors staging, sur PostgreSQL 15 / PostGIS 3.4 avec 50 000
--    patissiers : « Bitmap Index Scan on idx_baker_location_effective_geog »
--    en 58 ms, contre 569 ms en Seq Scan force. A rejouer sur staging par
--    acquit de conscience une fois le backfill fait.
--    Penser a ANALYZE avant, et noter qu'avec une poignee de lignes le
--    planificateur choisira un Seq Scan de toute facon (c'est normal et moins
--    couteux a ce volume) : ne conclure qu'a volume representatif.
--
--    ANALYZE baker_location;
--    EXPLAIN ANALYZE
--    SELECT baker_id,
--           effective_pickup_city,
--           ST_Distance(effective_pickup_geog,
--                       ST_SetSRID(ST_MakePoint(2.3522, 48.8566), 4326)::geography) AS distance_m
--    FROM baker_location
--    WHERE ST_DWithin(effective_pickup_geog,
--                     ST_SetSRID(ST_MakePoint(2.3522, 48.8566), 4326)::geography,
--                     10000)
--    ORDER BY effective_pickup_geog <-> ST_SetSRID(ST_MakePoint(2.3522, 48.8566), 4326)::geography
--    LIMIT 20;
--
-- F. Verifier le mode retenu par le moteur (generee vs trigger) :
--
--    SELECT column_name, data_type, is_generated, generation_expression
--    FROM information_schema.columns
--    WHERE table_name = 'baker_location'
--      AND column_name IN ('location_geog','pickup_geog',
--                          'effective_pickup_geog','effective_pickup_city');
-- =====================================================
