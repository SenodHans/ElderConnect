// ElderConnect — mosaic-nightly Edge Function
//
// Cron: 30 18 * * * (18:30 UTC = midnight Sri Lanka time UTC+5:30)
//
// For each elder:
//   1. Compute 4-signal weighted composite score for today
//   2. Write nightly_composite row to mood_logs
//   3. Linear regression on last 7 nightly composite scores
//   4. Adaptive thresholds (mean ± stddev) or fixed if < 7 days
//   5. Upsert alert_states + FCM to caretakers on escalation
//
// Composite formula:
//   score = 0.40 × sentiment + 0.20 × (1 − discrepancy) + 0.20 × social + 0.20 × adherence
//
// Env vars: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY,
//           FCM_PROJECT_ID, FCM_SERVICE_ACCOUNT_EMAIL, FCM_PRIVATE_KEY

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// ── Statistics ────────────────────────────────────────────────────────────────

function arrayMean(values: number[]): number {
  return values.length === 0 ? 0 : values.reduce((a, b) => a + b, 0) / values.length;
}

function arrayStddev(values: number[], avg: number): number {
  if (values.length < 2) return 0;
  return Math.sqrt(
    values.reduce((acc, v) => acc + (v - avg) ** 2, 0) / values.length,
  );
}

function linearSlope(values: number[]): number {
  const n = values.length;
  if (n < 2) return 0; // need at least 2 points for a meaningful slope
  const sumX = (n * (n - 1)) / 2;
  const sumX2 = (n * (n - 1) * (2 * n - 1)) / 6;
  const sumY = values.reduce((a, b) => a + b, 0);
  const sumXY = values.reduce((acc, y, i) => acc + i * y, 0);
  const denom = n * sumX2 - sumX * sumX;
  return denom === 0 ? 0 : (n * sumXY - sumX * sumY) / denom;
}

function adaptiveStatus(
  history: number[], todayScore: number, slope: number,
): "stable" | "warning" | "urgent" {
  if (history.length < 7) {
    if (slope < -0.25) return "urgent";
    if (slope < -0.15) return "warning";
    return "stable";
  }
  const avg = arrayMean(history);
  const sd = arrayStddev(history, avg);
  if (todayScore < avg - 2.5 * sd) return "urgent";
  if (todayScore < avg - 1.5 * sd) return "warning";
  return "stable";
}

// ── FCM ───────────────────────────────────────────────────────────────────────

async function getAccessToken(email: string, pem: string): Promise<string> {
  const clean = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s/g, "");
  const key = await crypto.subtle.importKey(
    "pkcs8",
    Uint8Array.from(atob(clean), (c) => c.charCodeAt(0)).buffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"],
  );
  const now = Math.floor(Date.now() / 1000);
  const b64 = (o: object) =>
    btoa(JSON.stringify(o)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
  const hdr = b64({ alg: "RS256", typ: "JWT" });
  const clm = b64({
    iss: email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now, exp: now + 3600,
  });
  const si = `${hdr}.${clm}`;
  const sig = btoa(String.fromCharCode(
    ...new Uint8Array(
      await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(si)),
    ),
  )).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
  const r = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${si}.${sig}`,
  });
  const { access_token } = await r.json();
  return access_token as string;
}

async function sendFcm(
  token: string, name: string, status: string,
  projectId: string, accessToken: string,
): Promise<void> {
  const body = status === "urgent"
    ? `${name} may need immediate attention — mood has declined significantly.`
    : `${name}'s mood trend has shifted. Check their activity log.`;
  await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
    method: "POST",
    headers: { Authorization: `Bearer ${accessToken}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      message: {
        token,
        notification: { title: status === "urgent" ? "Urgent Mood Alert" : "Mood Warning", body },
        data: { type: "mood_alert", status, elderly_name: name },
      },
    }),
  });
}

// ── Per-elder processing ──────────────────────────────────────────────────────

async function processElder(
  supabase: ReturnType<typeof createClient>,
  elderId: string, elderName: string,
  fcmAccessToken: string, fcmProjectId: string,
): Promise<void> {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const todayEnd = new Date(today);
  todayEnd.setHours(23, 59, 59, 999);
  const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

  // Signal 1 & 2: today's sentiment mean + discrepancy rate
  const { data: todayLogs } = await supabase
    .from("mood_logs")
    .select("score, discrepancy_flagged")
    .eq("user_id", elderId)
    .in("source", ["post", "daily_prompt"])
    .gte("created_at", today.toISOString())
    .lte("created_at", todayEnd.toISOString());

  const scores = (todayLogs ?? []).map((l) => l.score as number);
  const sentimentScore = scores.length > 0 ? arrayMean(scores) : 0.5;
  const discrepantCount = (todayLogs ?? []).filter((l) => l.discrepancy_flagged).length;
  const discrepancyPenalty =
    (todayLogs ?? []).length > 0 ? discrepantCount / (todayLogs ?? []).length : 0;

  // Signal 3: social activity (today's posts)
  const { count: postCount } = await supabase
    .from("posts").select("id", { count: "exact", head: true })
    .eq("user_id", elderId)
    .gte("created_at", today.toISOString())
    .lte("created_at", todayEnd.toISOString());
  const socialScore = Math.min((postCount ?? 0) / 3, 1);

  // Signal 4: medication adherence (today)
  const { data: medLogs } = await supabase
    .from("medication_logs").select("status")
    .eq("user_id", elderId)
    .gte("scheduled_time", today.toISOString())
    .lte("scheduled_time", todayEnd.toISOString());
  const scheduled = (medLogs ?? []).length;
  const taken = (medLogs ?? []).filter((l) => l.status === "taken").length;
  const adherence = scheduled > 0 ? taken / scheduled : 1.0;

  // Composite
  const composite =
    0.40 * sentimentScore +
    0.20 * (1 - discrepancyPenalty) +
    0.20 * socialScore +
    0.20 * adherence;

  const moodLabel = composite >= 0.6 ? "POSITIVE" : composite >= 0.4 ? "NEUTRAL" : "NEGATIVE";

  // Guard against duplicate runs (cron edge cases / manual re-triggers).
  // If a nightly_composite row already exists for today, skip the insert
  // to avoid polluting the 7-day regression history.
  const { data: existing } = await supabase
    .from("mood_logs")
    .select("id")
    .eq("user_id", elderId)
    .eq("source", "nightly_composite")
    .gte("created_at", today.toISOString())
    .lte("created_at", todayEnd.toISOString())
    .maybeSingle();

  if (!existing) {
    await supabase.from("mood_logs").insert({
      user_id: elderId,
      label: moodLabel,
      score: composite,
      source: "nightly_composite",
      composite_score: composite,
    });
  }

  // Trend analysis — last 7 nightly composites
  const { data: history } = await supabase
    .from("mood_logs")
    .select("composite_score")
    .eq("user_id", elderId)
    .eq("source", "nightly_composite")
    .gte("created_at", sevenDaysAgo.toISOString())
    .order("created_at", { ascending: true });

  const historicScores = (history ?? [])
    .map((h) => h.composite_score as number)
    .filter((s) => !isNaN(s));

  const slope = linearSlope(historicScores);
  const newStatus = adaptiveStatus(historicScores, composite, slope);

  // Previous status for escalation detection
  const { data: prev } = await supabase
    .from("alert_states").select("status")
    .eq("elderly_user_id", elderId).maybeSingle();

  const prevStatus = prev?.status as string | undefined;
  const order: Record<string, number> = { stable: 0, warning: 1, urgent: 2 };
  const escalated = !prevStatus || order[newStatus] > (order[prevStatus] ?? 0);

  await supabase.from("alert_states").upsert(
    {
      elderly_user_id: elderId,
      status: newStatus,
      sentiment_slope: slope,
      activity_count: postCount ?? 0,
      routine_adherence: adherence,
      discrepancy_delta: discrepancyPenalty,
      computed_at: new Date().toISOString(),
      ...(escalated && newStatus !== "stable"
        ? { notified_at: new Date().toISOString() } : {}),
    },
    { onConflict: "elderly_user_id" },
  );

  if (escalated && newStatus !== "stable") {
    const { data: links } = await supabase
      .from("caretaker_links").select("caretaker_id")
      .eq("elderly_user_id", elderId).eq("status", "accepted");

    if (links && links.length > 0) {
      const { data: tokens } = await supabase
        .from("fcm_tokens").select("token")
        .in("user_id", links.map((l) => l.caretaker_id));

      await Promise.allSettled(
        (tokens ?? []).map((t) =>
          sendFcm(t.token, elderName, newStatus, fcmProjectId, fcmAccessToken)
        ),
      );
    }
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

    // Only process elders who have explicitly consented to mood sharing.
    // alert_states carries mood-derived information — writing it for
    // non-consenting elders would expose that data via the DB even if RLS
    // blocks the read, and contradicts the stated consent architecture.
    const { data: elders, error } = await supabase
      .from("users")
      .select("id, full_name")
      .eq("role", "elderly")
      .eq("mood_sharing_consent", true);

    if (error) throw error;
    if (!elders || elders.length === 0) {
      return new Response(JSON.stringify({ processed: 0 }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    const projectId = Deno.env.get("FCM_PROJECT_ID")!;
    const fcmAccessToken = await getAccessToken(
      Deno.env.get("FCM_SERVICE_ACCOUNT_EMAIL")!,
      Deno.env.get("FCM_PRIVATE_KEY")!.replace(/\\n/g, "\n"),
    );

    const results = await Promise.allSettled(
      elders.map((e) =>
        processElder(supabase, e.id, e.full_name as string, fcmAccessToken, projectId)
      ),
    );

    const processed = results.filter((r) => r.status === "fulfilled").length;
    return new Response(
      JSON.stringify({ processed, failed: results.length - processed }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error("mosaic-nightly error:", err);
    return new Response(JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }
});
