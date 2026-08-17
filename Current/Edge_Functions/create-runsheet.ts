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
    const { selectedOrders } = await req.json();
    if (!Array.isArray(selectedOrders) || !selectedOrders.length) {
      throw new Error("يجب اختيار أوردر واحد على الأقل");
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) throw new Error("غير مصرح");
    const token = authHeader.replace(/^Bearer\s+/i, "").trim();
    if (!token) throw new Error("جلسة غير صالحة");

    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user?.id || !user.email) throw new Error("جلسة غير صالحة");

    const { data: pubUser, error: userError } = await supabase
      .from("users")
      .select("id,company_id,email,status")
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
    if (!pubUser && !isOwner) {
      throw new Error("المستخدم غير مسجل في النظام أو سياق الشركة غير محدد");
    }
    if (pubUser?.status && pubUser.status !== "Active") {
      throw new Error("المستخدم غير نشط");
    }
    if (isOwner && ownerProfile?.license_status && ownerProfile.license_status !== "active") {
      throw new Error("ترخيص المالك غير نشط");
    }

    const requestedCodes = [...new Set(
      selectedOrders.map((x: unknown) => String(x).trim()).filter(Boolean)
    )];
    if (!requestedCodes.length) throw new Error("يجب اختيار أوردر واحد على الأقل");

    const { data: ordersData, error: ordersError } = await supabase
      .from("orders")
      .select("id,order_code,order_status,runsheet_id,total_amount,company_id")
      .in("order_code", requestedCodes);
    if (ordersError) throw new Error("فشل جلب بيانات الأوردرات المحددة: " + ordersError.message);
    if (!ordersData?.length) throw new Error("فشل جلب بيانات الأوردرات المحددة");
    if (ordersData.length !== requestedCodes.length) throw new Error("أحد الأوردرات المحددة غير موجود");

    const companyIds = [...new Set(ordersData.map((o) => o.company_id).filter(Boolean))];
    if (companyIds.length !== 1) throw new Error("لا يمكن إنشاء رانشيت لأوردرات من أكثر من شركة");

    const companyId = companyIds[0];
    if (pubUser?.company_id && pubUser.company_id !== companyId) {
      throw new Error("الأوردرات المحددة تابعة لشركة أخرى");
    }

    const { data, error: coreError } = await supabase.rpc("create_runsheet_atomic", {
      p_company_id: companyId,
      p_selected_orders: requestedCodes,
      p_user_email: pubUser?.email || ownerProfile?.owner_email || user.email,
    });
    if (coreError) throw new Error(coreError.message);
    if (!data?.success) throw new Error(data?.msg || "فشل إنشاء الرانشيت");

    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error: any) {
    return new Response(JSON.stringify({
      success: false,
      msg: error?.message || "فشل إنشاء الرانشيت",
    }), {
      status: 400,
      headers: {
        "Access-Control-Allow-Origin": origin,
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
        "Content-Type": "application/json",
      },
    });
  }
});