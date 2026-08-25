import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

serve(async (req) => {
  const origin = req.headers.get("Origin") || "*";
  const corsHeaders = {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  };

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const amount = Number(body?.amount || 0);
    if (!(amount > 0)) throw new Error("TREASURY_TRANSFER_AMOUNT_INVALID");

    const auth = req.headers.get("Authorization");
    if (!auth) throw new Error("UNAUTHORIZED");
    const token = auth.replace(/^Bearer\s+/i, "");
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) throw new Error("INVALID_SESSION");

    const { data: appUser, error: userError } = await supabase
      .from("users")
      .select("company_id,status")
      .eq("auth_id", user.id)
      .maybeSingle();

    if (userError || !appUser?.company_id || (appUser.status && appUser.status !== "Active")) {
      throw new Error("INVALID_COMPANY_CONTEXT");
    }

    const operationId = String(body?.operationId || body?.operation_id || "").trim();
    if (!operationId) throw new Error("TREASURY_TRANSFER_OPERATION_ID_REQUIRED");

    const sourceTreasuryId = body?.sourceTreasuryId || body?.source_treasury_id || null;
    const targetTreasuryId = body?.targetTreasuryId || body?.target_treasury_id || null;
    const sourceAccountId = body?.sourceAccountId || body?.source_account_id || null;
    const targetAccountId = body?.targetAccountId || body?.target_account_id || null;

    if (!sourceTreasuryId || !targetTreasuryId) {
      throw new Error("TREASURY_TRANSFER_TREASURY_REQUIRED");
    }
    if (!sourceAccountId || !targetAccountId) {
      throw new Error("TREASURY_TRANSFER_ACCOUNT_REQUIRED");
    }

    const { data, error } = await supabase.rpc("post_treasury_transfer_atomic", {
      p_company_id: appUser.company_id,
      p_operation_id: operationId,
      p_source_treasury_id: sourceTreasuryId,
      p_target_treasury_id: targetTreasuryId,
      p_source_account_id: sourceAccountId,
      p_target_account_id: targetAccountId,
      p_amount: amount,
      p_transfer_date: body?.transferDate || body?.transfer_date || new Date().toISOString().slice(0, 10),
      p_reference: body?.reference || null,
      p_description: body?.description || body?.notes || "تحويل بين الخزائن",
      p_created_by: user.email || "",
      p_notes: body?.notes || null,
    });

    if (error) throw error;

    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error: any) {
    return new Response(
      JSON.stringify({ success: false, error: error?.message || String(error) }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
