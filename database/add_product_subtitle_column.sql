-- Temporary script to inject the subtitle column into existing product tables.
-- Run this manually before deploying the updated application if the column is missing.
BEGIN;
ALTER TABLE product ADD COLUMN IF NOT EXISTS subtitle TEXT;
COMMIT;
