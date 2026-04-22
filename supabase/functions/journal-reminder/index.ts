// ElderConnect — journal-reminder Edge Function
//
// Cron: 30 3 * * * (03:30 UTC = 09:00 Sri Lanka time UTC+5:30)
// Sends a morning FCM push to all elderly users to open /mood/journal.
//
// Env vars: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY,
//           FCM_PROJECT_ID, FCM_SERVICE_ACCOUNT_EMAIL, FCM_PRIVATE_KEY

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

async function getAccessToken(email: string, pem: string): Promise<string> {
  const pemContents = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s/g, "");
  const binaryKey = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8", binaryKey.buffer,
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
    ...new Uint8Array(await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(si),
    )),
  )).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
  const r = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${si}.${sig}`,
  });
  const { access_token } = await r.json();
  return access_token as string;
}

async function sendReminder(
  fcmToken: string, firstName: string,
  accessToken: string, projectId: string,
): Promise<void> {
  await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: { Authorization: `Bearer ${accessToken}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: {
            title: `Good morning, ${firstName}! \u{1F305}`,
            body: "How are you feeling today? Tap to share.",
          },
          data: { type: "journal_reminder", route: "/mood/journal" },
          android: {
            priority: "normal",
            notification: { channel_id: "medication_reminders" },
          },
        },
      }),
    },
  );
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: elders, error } = await supabase
      .from("users").select("id, full_name").eq("role", "elderly");

    if (error) throw error;
    if (!elders || elders.length === 0) {
      return new Response(JSON.stringify({ sent: 0 }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    const { data: tokens } = await supabase
      .from("fcm_tokens").select("user_id, token")
      .in("user_id", elders.map((e) => e.id));

    if (!tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ sent: 0, reason: "no_fcm_tokens" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    const elderMap = new Map(
      elders.map((e) => [e.id, (e.full_name as string).split(" ")[0]]),
    );
    const projectId = Deno.env.get("FCM_PROJECT_ID")!;
    const accessToken = await getAccessToken(
      Deno.env.get("FCM_SERVICE_ACCOUNT_EMAIL")!,
      Deno.env.get("FCM_PRIVATE_KEY")!.replace(/\\n/g, "\n"),
    );

    const results = await Promise.allSettled(
      tokens.map((t) =>
        sendReminder(t.token, elderMap.get(t.user_id) ?? "Friend", accessToken, projectId)
      ),
    );

    const sent = results.filter((r) => r.status === "fulfilled").length;
    return new Response(
      JSON.stringify({ sent, failed: results.length - sent }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error("journal-reminder error:", err);
    return new Response(JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }
});
