// ElderConnect — mood-detection-proxy Edge Function
//
// Proxies post/journal text to HuggingFace for emotion classification.
// Handles two sources:
//   'post'         — called after elder submits a social post (post_id required)
//   'daily_prompt' — called after elder submits daily journal prompt (no post_id)
//
// New in MOSAIC sprint:
//   - Accepts optional emoji_self_report ('😄'|'🙂'|'😐'|'😔'|'😢')
//   - Computes discrepancy_flagged when emoji and AI inference disagree
//   - Writes source, emoji_self_report, discrepancy_flagged to mood_logs
//
// Input (JSON body):
//   { text: string, source: 'post' | 'daily_prompt', post_id?: string, emoji_self_report?: string }
//
// Output:
//   { status: "ok", label: string, score: number, discrepancy_flagged: boolean }
//   { status: "loading" }
//   { status: "consent_not_given" }
//
// Auth: valid elderly user JWT in Authorization header.
// Env vars: SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY, HUGGINGFACE_API_KEY

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const HF_MODEL = "j-hartmann/emotion-english-distilroberta-base";
const HF_API_URL = `https://api-inference.huggingface.co/models/${HF_MODEL}`;

// Maps the highest-scoring HuggingFace emotion to POSITIVE / NEGATIVE / NEUTRAL.
// Scores below 0.4 default to NEUTRAL (low-confidence).
function toMoodLabel(hfLabel: string, score: number): string {
  if (score < 0.4) return "NEUTRAL";
  const positive = new Set(["joy", "love", "surprise"]);
  const negative = new Set(["anger", "disgust", "fear", "sadness"]);
  const lower = hfLabel.toLowerCase();
  if (positive.has(lower)) return "POSITIVE";
  if (negative.has(lower)) return "NEGATIVE";
  return "NEUTRAL";
}

// Discrepancy detection: flagged when the elder's emoji self-report and the
// HuggingFace inference disagree on positive vs negative valence.
// Neutral emoji (😐) never triggers a discrepancy.
function isDiscrepancyFlagged(moodLabel: string, emoji: string | null): boolean {
  if (!emoji) return false;
  const positiveEmojis = new Set(["😄", "🙂"]);
  const negativeEmojis = new Set(["😔", "😢"]);
  const emojiPositive = positiveEmojis.has(emoji);
  const emojiNegative = negativeEmojis.has(emoji);
  return (emojiPositive && moodLabel === "NEGATIVE") ||
         (emojiNegative && moodLabel === "POSITIVE");
}

// Calls HuggingFace with one retry on 503 (model cold start).
// Logs precise server-side latency for thesis performance measurements.
// Each attempt has a 20s hard timeout via AbortController to prevent
// hanging the Edge Function slot on slow/partial TCP responses.
async function queryHuggingFace(
  text: string,
  apiKey: string,
): Promise<{ label: string; score: number } | null> {
  const call = () => {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 20_000);
    return fetch(HF_API_URL, {
      signal: controller.signal,
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ inputs: text }),
    }).finally(() => clearTimeout(timer));
  };

  const hfStart = Date.now();
  let res = await call();

  if (res.status === 503) {
    console.log(`[MOSAIC] HuggingFace cold-start detected. Retrying after 25s... | model: ${HF_MODEL}`);
    await new Promise((r) => setTimeout(r, 25_000));
    res = await call();
    if (res.status === 503) {
      console.log(`[MOSAIC] HuggingFace unavailable after retry | total_wait_ms: ${Date.now() - hfStart}`);
      return null;
    }
    console.log(`[MOSAIC] HuggingFace latency after cold-start: ${Date.now() - hfStart}ms | model: ${HF_MODEL}`);
  } else {
    console.log(`[MOSAIC] HuggingFace latency: ${Date.now() - hfStart}ms | model: ${HF_MODEL} | cold_start: false`);
  }

  if (!res.ok) throw new Error(`HuggingFace error: ${res.status}`);

  const json = await res.json() as [[{ label: string; score: number }]];
  if (!Array.isArray(json) || !Array.isArray(json[0]) || json[0].length === 0) {
    throw new Error(`Unexpected HuggingFace response: ${JSON.stringify(json)}`);
  }
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

    // ── 3. Parse and validate request body ───────────────────────────────
    const body = await req.json();
    const { text, source = "post", post_id = null, emoji_self_report = null } = body;

    if (!text || typeof text !== "string" || text.trim() === "") {
      return new Response(
        JSON.stringify({ error: "text is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    if (!["post", "daily_prompt"].includes(source)) {
      return new Response(
        JSON.stringify({ error: "source must be 'post' or 'daily_prompt'" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Emoji self-report must be one of the five allowed options or absent.
    const ALLOWED_EMOJIS = new Set(["😄", "🙂", "😐", "😔", "😢"]);
    if (emoji_self_report !== null && !ALLOWED_EMOJIS.has(emoji_self_report)) {
      return new Response(
        JSON.stringify({ error: "emoji_self_report must be one of: 😄 🙂 😐 😔 😢" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // post_id is required for source='post', optional for 'daily_prompt'
    if (source === "post" && (!post_id || typeof post_id !== "string")) {
      return new Response(
        JSON.stringify({ error: "post_id is required for source='post'" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ── 4. Call HuggingFace ───────────────────────────────────────────────
    const topEmotion = await queryHuggingFace(
      text.trim(),
      Deno.env.get("HUGGINGFACE_API_KEY")!,
    );

    if (!topEmotion) {
      return new Response(
        JSON.stringify({ status: "loading" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const moodLabel = toMoodLabel(topEmotion.label, topEmotion.score);
    const discrepancyFlagged = isDiscrepancyFlagged(moodLabel, emoji_self_report);

    // ── 5. Write to mood_logs ─────────────────────────────────────────────
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
        source_post_id: post_id ?? null,
        source,
        emoji_self_report: emoji_self_report ?? null,
        discrepancy_flagged: discrepancyFlagged,
      });

    if (insertError) {
      console.error("mood_logs insert error:", insertError);
    } else if (source === "post") {
      // Fire MOSAIC alert recomputation for this elder (fire-and-forget).
      // Only triggered for posts — the nightly batch handles daily_prompt source.
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
      JSON.stringify({
        status: "ok",
        label: moodLabel,
        score: topEmotion.score,
        discrepancy_flagged: discrepancyFlagged,
      }),
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
