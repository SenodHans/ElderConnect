-- 002_add_alert_states.sql
--
-- Adds alert_states (one row per elder, upserted after each MOSAIC computation)
-- and fcm_tokens (device push token per user, for escalation notifications).

-- ── alert_states ─────────────────────────────────────────────────────────────
create table if not exists alert_states (
  id                  uuid primary key default gen_random_uuid(),
  elderly_user_id     uuid not null references users(id) on delete cascade,
  status              text not null check (status in ('stable', 'warning', 'urgent')),
  sentiment_slope     float not null default 0,   -- 7-day linear regression slope of HF scores
  activity_count      int   not null default 0,   -- posts submitted in last 7 days
  routine_adherence   float not null default 1.0, -- medication taken / scheduled ratio
  discrepancy_delta   float not null default 0,   -- score variance (mood consistency signal)
  computed_at         timestamptz not null default now(),
  notified_at         timestamptz                 -- last FCM escalation timestamp (null = never)
);

-- One active alert row per elder — compute-mood-alert uses upsert on this index.
create unique index if not exists alert_states_elder_unique
  on alert_states (elderly_user_id);

alter table alert_states enable row level security;

-- Caretakers may read alert states for their accepted linked elders only.
create policy "Caretakers read alert states for linked elders"
  on alert_states for select
  using (
    exists (
      select 1 from caretaker_links cl
      where cl.elderly_user_id = alert_states.elderly_user_id
        and cl.caretaker_id    = auth.uid()
        and cl.status          = 'accepted'
    )
  );

-- ── fcm_tokens ────────────────────────────────────────────────────────────────
-- Stores the latest FCM device token per user. Flutter writes this on each login
-- so the token stays current after app reinstalls or token rotations.
create table if not exists fcm_tokens (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references users(id) on delete cascade,
  token      text not null,
  updated_at timestamptz not null default now()
);

-- One token row per user — Flutter upserts on login.
create unique index if not exists fcm_tokens_user_unique
  on fcm_tokens (user_id);

alter table fcm_tokens enable row level security;

-- Users manage only their own FCM token.
create policy "Users manage own FCM token"
  on fcm_tokens for all
  using  (user_id = auth.uid())
  with check (user_id = auth.uid());
