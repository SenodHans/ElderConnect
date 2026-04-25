-- Migration 010: find_elder_by_pin SECURITY DEFINER function
--
-- Required by the elder PIN login screen (elder_pin_login_screen.dart).
-- The screen calls supabase.rpc('find_elder_by_pin', {pin_input: '1234'})
-- to do a global lookup across all elders without knowing which elder is
-- logging in (elder picks their device, enters their PIN).
--
-- Must be callable without an active session (anon key) because the elder
-- may arrive at the PIN screen before any Supabase session exists.
-- SECURITY DEFINER bypasses RLS so any authenticated/anon caller can match
-- a PIN — only returns the minimal needed fields (no sensitive data exposed
-- beyond what is necessary for authentication).

CREATE OR REPLACE FUNCTION public.find_elder_by_pin(pin_input text)
RETURNS TABLE (
  id              uuid,
  full_name       text,
  email           text,
  system_password text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only match elders (role = 'elderly') with a matching plain PIN.
  -- Returns at most one row (PINs should be unique per elder setup).
  RETURN QUERY
  SELECT
    u.id,
    u.full_name,
    u.email,
    u.system_password
  FROM public.users u
  WHERE u.role = 'elderly'
    AND u.pin_plain = pin_input
  LIMIT 1;
END;
$$;

-- Allow both anon (pre-login) and authenticated users to invoke this function.
-- The anon grant is required because the elder PIN screen is reachable before
-- any Supabase session exists on a freshly installed / logged-out device.
GRANT EXECUTE ON FUNCTION public.find_elder_by_pin(text) TO anon;
GRANT EXECUTE ON FUNCTION public.find_elder_by_pin(text) TO authenticated;
