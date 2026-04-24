// ElderConnect — restore-elder-session Edge Function
//
// Allows an elder to recover their session after app reinstall using
// their phone number + PIN — no stored credentials needed.
//
// Flow:
//   1. Derive synthetic email from phone number
//   2. Fetch the elder's pin_hash from the users table
//   3. Verify the submitted PIN against the hash (bcrypt via pg crypt())
//   4. Sign in as the elder using admin auth, return access + refresh tokens
//
// No JWT required (verify_jwt: false via config.toml or header omission).
// Phone number is the only identifier — matches the synthetic email pattern.
//
// Env vars required: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import * as bcrypt from "https://deno.land/x/bcrypt@v0.4.1/mod.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { phone, pin } = await req.json();
    if (!phone || !pin) {
      return new Response(JSON.stringify({ error: "phone and pin required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // Derive synthetic email from phone — same pattern as create-elder-account.
    const normalised = String(phone).replace(/\D/g, "");
    const elderEmail = `elder_${normalised}@elderconnect.internal`;

    // Fetch the elder's pin_hash and id.
    const { data: elderRow, error: fetchError } = await supabase
      .from("users")
      .select("id, pin_hash, full_name")
      .eq("email", elderEmail)
      .single();

    if (fetchError || !elderRow || !elderRow.pin_hash) {
      return new Response(JSON.stringify({ error: "invalid_credentials" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Verify PIN against bcrypt hash.
    const pinMatch = await bcrypt.compare(String(pin), elderRow.pin_hash);
    if (!pinMatch) {
      return new Response(JSON.stringify({ error: "invalid_credentials" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Generate a session for the elder using admin signInWithPassword.
    // The system password is fetched from the users table (stored at registration).
    const { data: credRow } = await supabase
      .from("users")
      .select("system_password")
      .eq("id", elderRow.id)
      .single();

    if (!credRow?.system_password) {
      return new Response(JSON.stringify({ error: "cannot_restore" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Sign in as the elder to generate fresh tokens.
    const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({
      email: elderEmail,
      password: credRow.system_password,
    });

    if (signInError || !signInData.session) {
      return new Response(JSON.stringify({ error: "session_failed" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(
      JSON.stringify({
        access_token: signInData.session.accessToken,
        refresh_token: signInData.session.refreshToken,
        elder_id: elderRow.id,
        full_name: elderRow.full_name,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
