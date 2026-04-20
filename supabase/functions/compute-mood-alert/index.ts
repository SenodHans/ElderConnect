// ElderConnect — compute-mood-alert Edge Function
//
// MOSAIC alert computation — called internally by mood-detection-proxy
// after each new mood_logs entry. Not exposed as a public endpoint.
//
// Four signals (rolling 7-day window):
//   1. sentiment_slope     — linear regression slope of HF scores
//                            negative slope = worsening trend
//   2. activity_count      — number of posts submitted
//   3. routine_adherence   — medication taken / scheduled ratio
//   4. discrepancy_delta   — score variance (high = inconsistent mood signal)
//
// Alert thresholds:
//   urgent  → slope < -0.30 AND activity < 2 AND adherence < 0.50
//   warning → slope < -0.15 OR  activity < 3 OR  adherence < 0.70
//   stable  → otherwise
//
// FCM escalation: fired when status worsens (stable→warning, *→urgent).
// Uses Firebase HTTP v1 API with service account OAuth2.
//
// Input (JSON body): { elderly_user_id: string }
// Auth: must be called with service role key (internal use only).
// Env vars required:
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY,
//   FCM_PROJECT_ID, FCM_SERVICE_ACCOUNT_EMAIL, FCM_PRIVATE_KEY

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// ── MOSAIC thresholds ─────────────────────────────────────────────────────────

function computeStatus(
  slope: number,
  activityCount: number,
  adherence: number,
): "stable" | "warning" | "urgent" {
  if (slope < -0.30 && activityCount < 2 && adherence < 0.50) return "urgent";
  if (slope < -0.15 || activityCount < 3 || adherence < 0.70) return "warning";
  return "stable";
}

// ── Linear regression slope ───────────────────────────────────────────────────
// Returns the slope of the best-fit line through (index, score) pairs.
// Fewer than 3 data points → returns 0 (insufficient signal).

function linearSlope(scores: number[]): number {
  if (scores.length < 3) return 0;
  const n = scores.length;
  const sumX = (n * (n - 1)) / 2;
  const sumX2 = (n * (n - 1) * (2 * n - 1)) / 6;
  const sumY = scores.reduce((a, b) => a + b, 0);
  const sumXY = scores.reduce((acc, y, i) => acc + i * y, 0);
  const denom = n * sumX2 - sumX * sumX;
  if (denom === 0) return 0;
  return (n * sumXY - sumX * sumY) / denom;
}

// ── Score variance (discrepancy_delta proxy) ──────────────────────────────────

function scoreVariance(scores: number[]): number {
  if (scores.length < 2) return 0;
  const mean = scores.reduce((a, b) => a + b, 0) / scores.length;
  const variance = scores.reduce((acc, s) => acc + (s - mean) ** 2, 0) / scores.length;
  return Math.sqrt(variance);
}

// ── FCM HTTP v1 OAuth2 helper ─────────────────────────────────────────────────

async function getAccessToken(
  serviceAccountEmail: string,
  privateKeyPem: string,
): Promise<string> {
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

// ── FCM escalation notification ───────────────────────────────────────────────

async function sendFcmAlert(
  token: string,
  elderName: string,
  status: string,
): Promise<void> {
  const projectId = Deno.env.get("FCM_PROJECT_ID")!;
  const serviceAccountEmail = Deno.env.get("FCM_SERVICE_ACCOUNT_EMAIL")!;
  const privateKey = Deno.env.get("FCM_PRIVATE_KEY")!.replace(/\\n/g, "\n");

  const accessToken = await getAccessToken(serviceAccountEmail, privateKey);

  const body = status === "urgent"
    ? `${elderName} may need immediate attention — mood has declined significantly.`
    : `${elderName}'s mood trend has shifted. Check their activity log.`;

  await fetch(
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
            title: status === "urgent" ? "Urgent Mood Alert" : "Mood Warning",
            body,
          },
          data: { type: "mood_alert", status, elderly_name: elderName },
        },
      }),
    },
  );
}

// ── Main handler ──────────────────────────────────────────────────────────────

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { elderly_user_id } = await req.json();

    if (!elderly_user_id || typeof elderly_user_id !== "string") {
      return new Response(
        JSON.stringify({ error: "elderly_user_id is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();

    // ── 1. Fetch mood scores (last 7 days, chronological) ─────────────────
    const { data: moodLogs } = await supabase
      .from("mood_logs")
      .select("score, created_at")
      .eq("user_id", elderly_user_id)
      .gte("created_at", sevenDaysAgo)
      .order("created_at", { ascending: true });

    const scores = (moodLogs ?? []).map((m) => m.score as number);
    const slope = linearSlope(scores);
    const discrepancyDelta = scoreVariance(scores);

    // ── 2. Fetch post activity count ──────────────────────────────────────
    const { count: activityCount } = await supabase
      .from("posts")
      .select("id", { count: "exact", head: true })
      .eq("user_id", elderly_user_id)
      .gte("created_at", sevenDaysAgo);

    // ── 3. Fetch medication adherence ─────────────────────────────────────
    const { data: medLogs } = await supabase
      .from("medication_logs")
      .select("status")
      .eq("user_id", elderly_user_id)
      .gte("scheduled_time", sevenDaysAgo);

    const totalScheduled = (medLogs ?? []).length;
    const takenCount = (medLogs ?? []).filter((l) => l.status === "taken").length;
    // No medications scheduled → adherence is not applicable; default to 1.0.
    const routineAdherence = totalScheduled > 0 ? takenCount / totalScheduled : 1.0;

    // ── 4. Compute MOSAIC alert status ────────────────────────────────────
    const newStatus = computeStatus(slope, activityCount ?? 0, routineAdherence);

    // ── 5. Read previous status for escalation detection ─────────────────
    const { data: previousAlert } = await supabase
      .from("alert_states")
      .select("status")
      .eq("elderly_user_id", elderly_user_id)
      .maybeSingle();

    const previousStatus = previousAlert?.status as string | undefined;
    const statusOrder = { stable: 0, warning: 1, urgent: 2 };
    const escalated =
      previousStatus === undefined ||
      statusOrder[newStatus] > statusOrder[previousStatus as keyof typeof statusOrder];

    // ── 6. Upsert alert_states ────────────────────────────────────────────
    await supabase
      .from("alert_states")
      .upsert(
        {
          elderly_user_id,
          status: newStatus,
          sentiment_slope: slope,
          activity_count: activityCount ?? 0,
          routine_adherence: routineAdherence,
          discrepancy_delta: discrepancyDelta,
          computed_at: new Date().toISOString(),
          ...(escalated && newStatus !== "stable"
            ? { notified_at: new Date().toISOString() }
            : {}),
        },
        { onConflict: "elderly_user_id" },
      );

    // ── 7. FCM escalation notification ───────────────────────────────────
    if (escalated && newStatus !== "stable") {
      // Fetch the elder's name for the notification message.
      const { data: elderProfile } = await supabase
        .from("users")
        .select("full_name")
        .eq("id", elderly_user_id)
        .single();

      const elderName = elderProfile?.full_name ?? "Your elder";

      // Find all caretakers with an accepted link to this elder.
      const { data: links } = await supabase
        .from("caretaker_links")
        .select("caretaker_id")
        .eq("elderly_user_id", elderly_user_id)
        .eq("status", "accepted");

      if (links && links.length > 0) {
        const caretakerIds = links.map((l) => l.caretaker_id);

        const { data: tokens } = await supabase
          .from("fcm_tokens")
          .select("token")
          .in("user_id", caretakerIds);

        // Fire notifications concurrently — non-fatal if any individual send fails.
        await Promise.allSettled(
          (tokens ?? []).map((t) => sendFcmAlert(t.token, elderName, newStatus)),
        );
      }
    }

    return new Response(
      JSON.stringify({ status: newStatus, escalated }),
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
