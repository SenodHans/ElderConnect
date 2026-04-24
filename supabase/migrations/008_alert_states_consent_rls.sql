-- 008_alert_states_consent_rls.sql
--
-- Tightens the alert_states read policy to enforce mood_sharing_consent.
-- The original policy (002) only checked caretaker_links; it allowed a
-- caretaker to read 'warning'/'urgent' status for an elder who explicitly
-- declined mood sharing — contradicting the stated consent architecture.
--
-- This migration drops the old policy and replaces it with one that joins
-- through users to verify consent before exposing any alert data.

DROP POLICY IF EXISTS "Caretakers read alert states for linked elders"
  ON alert_states;

CREATE POLICY "Caretakers read alert states with consent"
  ON alert_states FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM caretaker_links cl
      JOIN users u ON u.id = alert_states.elderly_user_id
      WHERE cl.elderly_user_id = alert_states.elderly_user_id
        AND cl.caretaker_id    = (SELECT auth.uid())
        AND cl.status          = 'accepted'
        AND u.mood_sharing_consent = TRUE
    )
  );
