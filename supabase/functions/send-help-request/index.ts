// ElderConnect — send-help-request Edge Function
//
// Unauthenticated help notification — called from the PIN screen when the elder
// cannot restore a session (e.g. after app reinstall). Identifies the elder by
// phone number, then sends an FCM push to all linked caretakers.
//
// No JWT required — uses anon key. Rate-limiting is the only protection,
// so this is intentionally low-privilege: it only sends a notification,
// no data is returned about the elder.
//
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
    const { phone } = await req.json();
    if (!phone) {
      return new Response(JSON.stringify({ error: "phone required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // Derive elder email from phone — same format used at account creation.
    const normalised = phone.replace(/\D/g, "");
    const elderEmail = `elder_${normalised}@elderconnect.internal`;

    // Find the elder by their synthetic email.
    const { data: elderRow } = await supabase
      .from("users")
      .select("id, full_name")
      .eq("email", elderEmail)
      .single();

    if (!elderRow) {
      // Return 200 so the UI shows a success message regardless — prevents
      // phone number enumeration.
      return new Response(JSON.stringify({ sent: 0 }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const elderId: string = elderRow.id;
    const elderName: string = elderRow.full_name ?? "Your elder";

    // Find linked caretakers.
    const { data: links } = await supabase
      .from("caretaker_links")
      .select("caretaker_id")
      .eq("elderly_user_id", elderId);

    if (!links || links.length === 0) {
      return new Response(JSON.stringify({ sent: 0 }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const caretakerIds = links.map((l: { caretaker_id: string }) => l.caretaker_id);

    const { data: tokenRows } = await supabase
      .from("fcm_tokens")
      .select("token")
      .in("user_id", caretakerIds);

    if (!tokenRows || tokenRows.length === 0) {
      return new Response(JSON.stringify({ sent: 0 }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${Deno.env.get("FCM_PROJECT_ID")}/messages:send`;
    const accessToken = await getFcmAccessToken();

    let sent = 0;
    for (const { token } of tokenRows) {
      const payload = {
        message: {
          token,
          notification: {
            title: "🔔 Elder Needs Help",
            body: `${elderName} needs help logging in to ElderConnect.`,
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
            type: "help_request",
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
        body: JSON.stringify(payload),
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
