import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { autoRefreshToken: false, persistSession: false } }
);

serve(async (req) => {
  const origin = req.headers.get("Origin") || "*";
  const corsHeaders = {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  };
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const body = await req.json().catch(() => ({}));
    const operation = String(body?.operation || "").trim().toUpperCase();
    const runsheetCode = String(body?.runsheet_code || "").trim();
    const driverId = body?.driver_id ? String(body.driver_id) : null;
    const vehicleId = body?.vehicle_id ? String(body.vehicle_id) : null;

    if (!["UPDATE", "CANCEL", "DELETE"].includes(operation)) throw new Error("عملية الرانشيت غير مدعومة");
    if (!runsheetCode) throw new Error("رقم الرانشيت مطلوب");
    if (operation === "UPDATE" && body?.driver_id !== null && body?.driver_id !== undefined && !driverId) throw new Error("قيمة السائق غير صالحة");
    if (operation === "UPDATE" && body?.vehicle_id !== null && body?.vehicle_id !== undefined && !vehicleId) throw new Error("قيمة المركبة غير صالحة");

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) throw new Error("غير مصرح");
    const token = authHeader.replace(/^Bearer\s+/i, "").trim();
    if (!token) throw new Error("جلسة غير صالحة");

    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user?.id || !user.email) throw new Error("جلسة غير صالحة");

    const { data: pubUser, error: userError } = await supabase
      .from("users")
      .select("id,company_id,email,status,permissions")
      .eq("auth_id", user.id)
      .maybeSingle();
    if (userError) throw new Error("فشل قراءة المستخدم: " + userError.message);

    const { data: ownerProfile, error: ownerError } = await supabase
      .from("owner_profile")
      .select("auth_user_id,owner_email,license_status")
      .eq("auth_user_id", user.id)
      .maybeSingle();
    if (ownerError) throw new Error("فشل قراءة ملف المالك: " + ownerError.message);

    const isOwner = !!ownerProfile && user.user_metadata?.isOwner === true;
    if (!pubUser && !isOwner) throw new Error("المستخدم غير مسجل في النظام أو سياق الشركة غير محدد");
    if (pubUser?.status && pubUser.status !== "Active") throw new Error("المستخدم غير نشط");
    if (isOwner && ownerProfile?.license_status && ownerProfile.license_status !== "active") throw new Error("ترخيص المالك غير نشط");

    const permissions = Array.isArray(pubUser?.permissions) ? pubUser.permissions : [];
    if (!isOwner && !permissions.includes("*") && !permissions.includes("runsheets")) {
      throw new Error("لا تملك صلاحية إدارة الرانشيتات");
    }

    const companyId = pubUser?.company_id;
    if (!companyId) throw new Error("سياق الشركة غير محدد للمستخدم");

    const { data, error } = await supabase.rpc("manage_runsheet_atomic", {
      p_company_id: companyId,
      p_runsheet_code: runsheetCode,
      p_operation: operation,
      p_user_email: pubUser?.email || ownerProfile?.owner_email || user.email,
      p_driver_id: operation === "UPDATE" ? driverId : null,
      p_vehicle_id: operation === "UPDATE" ? vehicleId : null,
    });
    if (error) throw new Error(error.message);
    if (!data?.success) throw new Error(data?.msg || "فشلت عملية إدارة الرانشيت");

    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ success: false, msg: error?.message || "فشلت عملية إدارة الرانشيت" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});