-- =====================================================
-- Add stripe_payment_method_id column to payment_method table
-- =====================================================

-- Add stripe_payment_method_id column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'payment_method' 
        AND column_name = 'stripe_payment_method_id'
    ) THEN
        ALTER TABLE payment_method 
        ADD COLUMN stripe_payment_method_id VARCHAR(255);
        
        COMMENT ON COLUMN payment_method.stripe_payment_method_id IS 'Stripe PaymentMethod ID for saved payment methods';
    END IF;
END $$;






