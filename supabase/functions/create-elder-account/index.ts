// ElderConnect — create-elder-account Edge Function
//
// Creates a Supabase Auth account for an elderly user on behalf of
// their caretaker. Called with the caretaker's valid JWT so that
// the caretaker_id can be verified from the JWT claims.
//
// The elder never interacts with this flow — they are passive throughout
// registration. Their auth credentials are system-generated and stored
// server-side only. The system_password is never returned to any client.
//
// Input (JSON body):
//   { phone: string, full_name: string }
//
// Output (JSON):
//   { elder_id: string, email: string }
//
// Auth requirement: valid caretaker JWT in Authorization header.
// Environment variables required:
//   SUPABASE_URL            — project URL
//   SUPABASE_SERVICE_ROLE_KEY — service role key (bypasses RLS for admin ops)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ── 1. Authenticate the calling caretaker ─────────────────────────────
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing Authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Verify the caretaker's JWT using the anon client.
    const supabaseAnon = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: { user: caretaker }, error: authError } = await supabaseAnon.auth.getUser();
    if (authError || !caretaker) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired caretaker session" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Confirm calling user has role=caretaker in the users table.
    const { data: caretakerProfile, error: profileError } = await supabaseAnon
      .from("users")
      .select("role")
      .eq("id", caretaker.id)
      .single();

    if (profileError || caretakerProfile?.role !== "caretaker") {
      return new Response(
        JSON.stringify({ error: "Caller is not a registered caretaker" }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ── 2. Parse and validate request body ───────────────────────────────
    const { phone, full_name } = await req.json();

    if (!phone || typeof phone !== "string" || phone.trim() === "") {
      return new Response(
        JSON.stringify({ error: "phone is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    if (!full_name || typeof full_name !== "string" || full_name.trim() === "") {
      return new Response(
        JSON.stringify({ error: "full_name is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ── 3. Generate elder credentials ─────────────────────────────────────
    // Email: deterministic from phone so the elder can be re-looked-up.
    // Password: random UUID — never exposed to any user interface.
    const elderEmail = `elder_${phone.replace(/\D/g, "")}@elderconnect.internal`;
    const systemPassword = crypto.randomUUID();

    // ── 4. Create Supabase Auth user via service role (bypasses RLS) ──────
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
      email: elderEmail,
      password: systemPassword,
      phone: phone,
      email_confirm: true, // Mark as confirmed — elder never verifies email
      // Store role in user_metadata so GoRouter redirect can check it
      // synchronously via currentUser.userMetadata['role'] without a DB query.
      user_metadata: { role: "elderly", full_name: full_name.trim() },
    });

    if (createError || !newUser.user) {
      // If the email already exists (elder was registered before), return a clear error.
      if (createError?.message?.includes("already registered")) {
        return new Response(
          JSON.stringify({ error: "An elder with this phone number is already registered" }),
          { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }
      console.error("Auth createUser error:", createError);
      return new Response(
        JSON.stringify({ error: "Failed to create elder auth account" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const elderId = newUser.user.id;

    // ── 5. Insert row into users table ────────────────────────────────────
    // system_password is stored here so that the elder's device can restore
    // their session via flutter_secure_storage + supabase.auth.setSession().
    // This is the only place system_password is written — never returned to client.
    const { error: insertError } = await supabaseAdmin
      .from("users")
      .insert({
        id: elderId,
        email: elderEmail,
        role: "elderly",
        full_name: full_name.trim(),
        phone: phone.trim(),
        system_password: systemPassword,
      });

    if (insertError) {
      // Rollback: delete the auth user if the profile insert fails.
      await supabaseAdmin.auth.admin.deleteUser(elderId);
      console.error("Profile insert error:", insertError);
      return new Response(
        JSON.stringify({ error: "Failed to create elder profile" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ── 6. Return elder_id and email — NEVER return system_password ───────
    return new Response(
      JSON.stringify({ elder_id: elderId, email: elderEmail }),
      { status: 201, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );

  } catch (err) {
    console.error("Unhandled error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
