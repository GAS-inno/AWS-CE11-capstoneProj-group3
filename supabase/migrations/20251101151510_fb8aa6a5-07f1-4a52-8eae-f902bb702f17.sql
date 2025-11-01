-- Remove unique constraint on booking_reference to allow round-trip bookings
-- to share the same reference for both outbound and return legs
ALTER TABLE public.bookings 
DROP CONSTRAINT IF EXISTS bookings_booking_reference_key;