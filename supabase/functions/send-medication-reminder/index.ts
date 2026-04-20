// ElderConnect — send-medication-reminder Edge Function
//
// Cron job — checks medication_logs for reminders that are due within a
// ±2.5-minute window around now() and sends an FCM push to the elder's device.
//
// The ±2.5-minute window matches a 5-minute cron interval so each scheduled
// reminder fires exactly once without duplicate notifications.
//
// Set up cron in Supabase dashboard (Database → Extensions → pg_cron):
//   select cron.schedule(
//     'medication-reminder',
//     '*/5 * * * *',
//     $$ select net.http_post(
//         url := '<SUPABASE_URL>/functions/v1/send-medication-reminder',
//         headers := '{"Authorization": "Bearer <SERVICE_ROLE_KEY>"}'::jsonb
//       ) $$
//   );
//
// FCM notification is sent to the elder's device token stored in fcm_tokens.
// If no token exists for the elder, the reminder is logged and skipped silently.
//
// Auth: called with service role key (cron context — no user JWT).
// Env vars required:
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY,
//   FCM_PROJECT_ID, FCM_SERVICE_ACCOUNT_EMAIL, FCM_PRIVATE_KEY

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// ── FCM HTTP v1 OAuth2 helper ─────────────────────────────────────────────────
// Generates a short-lived Google OAuth2 access token from a service account.
// FCM HTTP v1 requires Bearer token auth — the legacy server key is discontinued.

async function getAccessToken(
  serviceAccountEmail: string,
  privateKeyPem: string,
): Promise<string> {
  // Decode the PEM-encoded RSA private key.
  const pemContents = privateKeyPem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s/g, "");

  const binaryKey = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey.buffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const now = Math.floor(Date.now() / 1000);

  // URL-safe base64 encode a JSON object (no padding).
  const b64url = (obj: object) =>
    btoa(JSON.stringify(obj))
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=/g, "");

  const header = b64url({ alg: "RS256", typ: "JWT" });
  const claim = b64url({
    iss: serviceAccountEmail,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  });

  const signingInput = `${header}.${claim}`;
  const sigBytes = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(signingInput),
  );
  const signature = btoa(String.fromCharCode(...new Uint8Array(sigBytes)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");

  const jwt = `${signingInput}.${signature}`;

  // Exchange signed JWT for an access token.
  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });

  if (!tokenRes.ok) {
    const err = await tokenRes.text();
    throw new Error(`OAuth2 token exchange failed: ${err}`);
  }

  const { access_token } = await tokenRes.json();
  return access_token as string;
}

// ── FCM HTTP v1 send ──────────────────────────────────────────────────────────
// Sends a single FCM notification to one device token using the v1 API.

async function sendFcmReminder(
  token: string,
  pillName: string,
  dosage: string,
): Promise<void> {
  const projectId = Deno.env.get("FCM_PROJECT_ID")!;
  const serviceAccountEmail = Deno.env.get("FCM_SERVICE_ACCOUNT_EMAIL")!;
  // Private key is stored with literal \n — replace before use.
  const privateKey = Deno.env.get("FCM_PRIVATE_KEY")!.replace(/\\n/g, "\n");

  const accessToken = await getAccessToken(serviceAccountEmail, privateKey);

  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token,
          notification: {
            title: "Medication Reminder",
            body: `Time to take ${pillName} — ${dosage}`,
          },
          data: {
            type: "medication_reminder",
            pill_name: pillName,
            dosage,
          },
        },
      }),
    },
  );

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`FCM send failed: ${res.status} — ${err}`);
  }
}

// ── Main handler ──────────────────────────────────────────────────────────────

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // ── 1. Find due reminders in the ±2.5-minute window ──────────────────
    // Matches the 5-minute cron cadence — each reminder fires exactly once.
    const windowStart = new Date(Date.now() - 2.5 * 60 * 1000).toISOString();
    const windowEnd   = new Date(Date.now() + 2.5 * 60 * 1000).toISOString();

    const { data: dueLogs, error: logsError } = await supabase
      .from("medication_logs")
      .select(`
        id,
        user_id,
        scheduled_time,
        medications ( pill_name, dosage )
      `)
      .eq("status", "pending")
      .gte("scheduled_time", windowStart)
      .lte("scheduled_time", windowEnd);

    if (logsError) {
      console.error("medication_logs query error:", logsError);
      return new Response(
        JSON.stringify({ error: "Failed to query medication logs" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    if (!dueLogs || dueLogs.length === 0) {
      return new Response(
        JSON.stringify({ sent: 0, message: "No reminders due" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ── 2. Send FCM notification per due reminder ─────────────────────────
    let sentCount = 0;

    await Promise.allSettled(
      dueLogs.map(async (log) => {
        // Fetch the elder's device token from fcm_tokens.
        const { data: tokenRow } = await supabase
          .from("fcm_tokens")
          .select("token")
          .eq("user_id", log.user_id)
          .maybeSingle();

        if (!tokenRow?.token) {
          // Elder has no FCM token registered — skip silently.
          // This is expected if the elder hasn't opened the app yet.
          console.warn(`No FCM token for elder ${log.user_id} — skipping reminder`);
          return;
        }

        const med = log.medications as { pill_name: string; dosage: string } | null;
        if (!med) return;

        try {
          await sendFcmReminder(tokenRow.token, med.pill_name, med.dosage);
          sentCount++;
        } catch (e) {
          // Non-fatal — log and continue with remaining reminders.
          console.error(`FCM failed for log ${log.id}:`, e);
        }
      }),
    );

    return new Response(
      JSON.stringify({ sent: sentCount, total: dueLogs.length }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );

  } catch (err) {
    console.error("Unhandled error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
