// ElderConnect — mood-detection-proxy Edge Function
//
// Proxies post text to the HuggingFace Inference API for sentiment analysis.
// Called by the Flutter client immediately after an elderly user submits a post.
//
// The HuggingFace API key never leaves the server. The Flutter client sends
// only post_id + text; this function handles the API call and writes the
// result to mood_logs.
//
// Mood analysis only runs if users.mood_sharing_consent = true.
// If not, returns { status: "consent_not_given" } — Flutter discards silently.
//
// HuggingFace model: j-hartmann/emotion-english-distilroberta-base
// Cold-start handling: one retry after 20s on 503 → returns { status: "loading" }
// so Flutter can show a brief "Analysing mood…" state and retry.
//
// Input (JSON body):
//   { post_id: string, text: string }
//
// Output:
//   { status: "ok", label: "POSITIVE"|"NEGATIVE"|"NEUTRAL", score: number }
//   { status: "loading" }
//   { status: "consent_not_given" }
//
// Auth: valid elderly user JWT in Authorization header.
// Env vars required:
//   SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY, HUGGINGFACE_API_KEY

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const HF_MODEL = "j-hartmann/emotion-english-distilroberta-base";
const HF_API_URL = `https://api-inference.huggingface.co/models/${HF_MODEL}`;

// Maps the top HuggingFace emotion label to an ElderConnect mood label.
// Scores below 0.4 are treated as NEUTRAL (low-confidence default per spec).
function toMoodLabel(hfLabel: string, score: number): string {
  if (score < 0.4) return "NEUTRAL";
  const positive = new Set(["joy", "love", "surprise"]);
  const negative = new Set(["anger", "disgust", "fear", "sadness"]);
  const lower = hfLabel.toLowerCase();
  if (positive.has(lower)) return "POSITIVE";
  if (negative.has(lower)) return "NEGATIVE";
  return "NEUTRAL";
}

// Calls HuggingFace with one automatic retry on 503 (model cold start).
// Returns null if still loading after the retry.
async function queryHuggingFace(
  text: string,
  apiKey: string,
): Promise<{ label: string; score: number } | null> {
  const call = () =>
    fetch(HF_API_URL, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ inputs: text }),
    });

  let res = await call();

  if (res.status === 503) {
    // Model is warming up — wait 20s then retry once.
    await new Promise((r) => setTimeout(r, 20_000));
    res = await call();
    if (res.status === 503) return null;
  }

  if (!res.ok) throw new Error(`HuggingFace error: ${res.status}`);

  // Shape: [[{label, score}, ...]] — return the highest-scoring candidate.
  const json = await res.json() as [[{ label: string; score: number }]];
  const candidates = json[0];
  return candidates.reduce((best, c) => (c.score > best.score ? c : best));
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ── 1. Authenticate the calling elderly user ──────────────────────────
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing Authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const supabaseAnon = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: { user }, error: authError } = await supabaseAnon.auth.getUser();
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired session" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ── 2. Check mood_sharing_consent ─────────────────────────────────────
    const { data: profile, error: profileError } = await supabaseAnon
      .from("users")
      .select("role, mood_sharing_consent")
      .eq("id", user.id)
      .single();

    if (profileError || profile?.role !== "elderly") {
      return new Response(
        JSON.stringify({ error: "Caller is not a registered elderly user" }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    if (!profile.mood_sharing_consent) {
      return new Response(
        JSON.stringify({ status: "consent_not_given" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ── 3. Parse request body ─────────────────────────────────────────────
    const { post_id, text } = await req.json();

    if (!text || typeof text !== "string" || text.trim() === "") {
      return new Response(
        JSON.stringify({ error: "text is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }
    if (!post_id || typeof post_id !== "string") {
      return new Response(
        JSON.stringify({ error: "post_id is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ── 4. Call HuggingFace ───────────────────────────────────────────────
    const topEmotion = await queryHuggingFace(
      text.trim(),
      Deno.env.get("HUGGINGFACE_API_KEY")!,
    );

    if (!topEmotion) {
      // Still loading after retry — Flutter retries after a brief delay.
      return new Response(
        JSON.stringify({ status: "loading" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const moodLabel = toMoodLabel(topEmotion.label, topEmotion.score);

    // ── 5. Write to mood_logs ─────────────────────────────────────────────
    // Uses service role so RLS does not interfere with the server-side write.
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { error: insertError } = await supabaseAdmin
      .from("mood_logs")
      .insert({
        user_id: user.id,
        label: moodLabel,
        score: topEmotion.score,
        source_post_id: post_id,
      });

    if (insertError) {
      // Non-fatal: log the error but don't surface it to the elder — the post
      // was already submitted. The caretaker simply won't see this log entry.
      console.error("mood_logs insert error:", insertError);
    } else {
      // Trigger MOSAIC alert computation in the background.
      // Fire-and-forget — the elder's post response is not delayed by this call.
      fetch(`${Deno.env.get("SUPABASE_URL")}/functions/v1/compute-mood-alert`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ elderly_user_id: user.id }),
      }).catch((e) => console.error("compute-mood-alert trigger failed:", e));
    }

    return new Response(
      JSON.stringify({ status: "ok", label: moodLabel, score: topEmotion.score }),
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
