-- Fix function to set search_path
CREATE OR REPLACE FUNCTION public.generate_booking_reference()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  ref TEXT;
BEGIN
  ref := 'SW' || LPAD(FLOOR(RANDOM() * 999999)::TEXT, 6, '0');
  RETURN ref;
END;
$$;