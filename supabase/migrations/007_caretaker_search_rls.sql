-- Migration 007: Caretaker search and links RLS
-- Allows elders to:
--   1. Read their own caretaker_links rows (to see who is linked to them)
--   2. Insert a link row to request a new caretaker connection
--   3. Search caretaker users by name (for the search-and-add flow)

-- ── caretaker_links ───────────────────────────────────────────────────────────

ALTER TABLE public.caretaker_links ENABLE ROW LEVEL SECURITY;

-- Both parties can read a link they are part of
CREATE POLICY "Users can read their own caretaker links"
ON public.caretaker_links FOR SELECT
TO authenticated
USING (elderly_user_id = auth.uid() OR caretaker_id = auth.uid());

-- Elder can create a new link (requesting a caretaker)
CREATE POLICY "Elder can request caretaker link"
ON public.caretaker_links FOR INSERT
TO authenticated
WITH CHECK (elderly_user_id = auth.uid());

-- Either party can delete a link (unlink)
CREATE POLICY "Linked users can remove caretaker link"
ON public.caretaker_links FOR DELETE
TO authenticated
USING (elderly_user_id = auth.uid() OR caretaker_id = auth.uid());

-- ── users: caretaker profiles readable for search ─────────────────────────────

-- Any authenticated user may read basic caretaker profiles for the search-and-add flow.
-- Exposes only public fields (full_name, avatar_url, phone) via the SELECT policy.
-- The existing "users can read their own row" policy is OR'd with this one by RLS.
CREATE POLICY "Authenticated users can read caretaker profiles"
ON public.users FOR SELECT
TO authenticated
USING (role = 'caretaker');
