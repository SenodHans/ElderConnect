-- Migration 004: Elder self-registration support + emergency contacts
--
-- Adds:
--   users.pin_plain          — plain-text PIN readable by linked caretaker only
--   users.avatar_url         — profile photo URL (Supabase Storage)
--   users.emergency_contact_name  — primary emergency contact display name
--   users.emergency_contact_phone — primary emergency contact phone number

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS pin_plain               text,
  ADD COLUMN IF NOT EXISTS avatar_url              text,
  ADD COLUMN IF NOT EXISTS emergency_contact_name  text,
  ADD COLUMN IF NOT EXISTS emergency_contact_phone text;

-- RLS: caretakers can read pin_plain only for elders they are linked to.
-- Elder cannot read their own pin_plain (they already know their PIN).
CREATE POLICY "caretaker_read_elder_pin_plain"
  ON users
  FOR SELECT
  USING (
    auth.uid() IN (
      SELECT caretaker_id FROM caretaker_links
      WHERE elderly_user_id = users.id
    )
  );
