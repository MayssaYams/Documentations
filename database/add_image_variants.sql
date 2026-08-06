-- Temporary script to add image variant columns (thumbnail/medium) for product and baker images.
-- Run this manually before deploying the updated application if the columns are missing.
BEGIN;
ALTER TABLE product_image ADD COLUMN IF NOT EXISTS thumbnail_url VARCHAR(255);
ALTER TABLE product_image ADD COLUMN IF NOT EXISTS medium_url VARCHAR(255);
ALTER TABLE baker ADD COLUMN IF NOT EXISTS profile_thumbnail_url VARCHAR(500);
COMMIT;
