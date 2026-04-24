// ElderConnect — send-sos-alert Edge Function
//
// Called by the elder's device when the SOS button is tapped.
// Finds all caretakers linked to the elder and sends an urgent FCM push
// notification to each of their registered devices.
//
// Auth: called with the elder's user JWT (standard authenticated request).
// Env vars required:
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY,
//   FCM_PROJECT_ID, FCM_SERVICE_ACCOUNT_EMAIL, FCM_PRIVATE_KEY

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Extract elder identity from their JWT.
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // Decode the elder's user id from their JWT.
    const userRes = await createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    ).auth.getUser();

    const elderId = userRes.data.user?.id;
    if (!elderId) {
      return new Response(JSON.stringify({ error: "Could not identify elder" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Get the elder's full name for the notification body.
    const { data: elderRow } = await supabase
      .from("users")
      .select("full_name")
      .eq("id", elderId)
      .single();

    const elderName = elderRow?.full_name ?? "Your elder";

    // Find all caretakers linked to this elder.
    const { data: links } = await supabase
      .from("caretaker_links")
      .select("caretaker_id")
      .eq("elderly_user_id", elderId);

    if (!links || links.length === 0) {
      // No caretaker linked — SOS recorded but no one to notify.
      return new Response(
        JSON.stringify({ sent: 0, message: "No linked caretakers" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const caretakerIds = links.map((l: { caretaker_id: string }) => l.caretaker_id);

    // Fetch FCM tokens for all linked caretakers.
    const { data: tokenRows } = await supabase
      .from("fcm_tokens")
      .select("token")
      .in("user_id", caretakerIds);

    if (!tokenRows || tokenRows.length === 0) {
      return new Response(
        JSON.stringify({ sent: 0, message: "No FCM tokens for caretakers" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Send FCM to each caretaker token.
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${Deno.env.get("FCM_PROJECT_ID")}/messages:send`;
    const accessToken = await getFcmAccessToken();

    let sent = 0;
    for (const { token } of tokenRows) {
      const body = {
        message: {
          token,
          notification: {
            title: "🆘 SOS Alert",
            body: `${elderName} has pressed the SOS button and needs help immediately.`,
          },
          android: {
            priority: "high",
            notification: { channel_id: "sos_alerts", sound: "default" },
          },
          apns: {
            payload: { aps: { sound: "default", badge: 1 } },
            headers: { "apns-priority": "10" },
          },
          data: {
            type: "sos_alert",
            elder_id: elderId,
            elder_name: elderName,
          },
        },
      };

      const res = await fetch(fcmUrl, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(body),
      });

      if (res.ok) sent++;
    }

    return new Response(JSON.stringify({ sent }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

// Generates a short-lived OAuth 2.0 access token for the FCM v1 API
// using the service account credentials stored in environment variables.
async function getFcmAccessToken(): Promise<string> {
  const email = Deno.env.get("FCM_SERVICE_ACCOUNT_EMAIL")!;
  const rawKey = Deno.env.get("FCM_PRIVATE_KEY")!.replace(/\\n/g, "\n");
  const scope = "https://www.googleapis.com/auth/firebase.messaging";

  const now = Math.floor(Date.now() / 1000);
  const payload = { iss: email, scope, aud: "https://oauth2.googleapis.com/token", iat: now, exp: now + 3600 };

  const header = btoa(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const body = btoa(JSON.stringify(payload));
  const unsigned = `${header}.${body}`;

  const keyData = rawKey
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const binaryKey = Uint8Array.from(atob(keyData), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8", binaryKey, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5", cryptoKey,
    new TextEncoder().encode(unsigned),
  );
  const jwt = `${unsigned}.${btoa(String.fromCharCode(...new Uint8Array(sig)))}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const { access_token } = await tokenRes.json();
  return access_token;
}
