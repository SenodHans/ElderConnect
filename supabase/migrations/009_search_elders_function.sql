-- Migration 009: SECURITY DEFINER function for elder search
--
-- Problem: the users table RLS only lets a caretaker read profiles of elders
-- they are already linked to. There is no policy allowing a caretaker to
-- discover unlinked elders — so the Network Management search returned 0 rows.
--
-- Solution: a SECURITY DEFINER function that any authenticated user can call.
-- It runs with the privileges of the function owner (postgres), bypassing RLS,
-- but only returns the three safe public fields (name, phone, avatar_url) for
-- rows whose role = 'elderly'. No sensitive columns are exposed.

CREATE OR REPLACE FUNCTION public.search_elderly_users(search_query text DEFAULT '')
RETURNS TABLE (
  id         uuid,
  full_name  text,
  phone      text,
  avatar_url text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id,
    u.full_name,
    u.phone,
    u.avatar_url
  FROM public.users u
  WHERE
    u.role = 'elderly'
    AND (
      search_query = ''
      OR u.full_name ILIKE '%' || search_query || '%'
    )
  ORDER BY u.full_name
  LIMIT 50;
END;
$$;

-- Allow any authenticated user (caretaker) to invoke this function.
GRANT EXECUTE ON FUNCTION public.search_elderly_users(text) TO authenticated;
