// send-stock-voucher – إرسال إذن مخزني وخصم المخزون
// الإصدار 2.0 – مع سجل المخزون (inventory_log)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

var supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!)
var corsHeaders = {"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type","Access-Control-Allow-Methods":"POST, OPTIONS"}

serve(async function(req) {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders })
  try {
    var rawBody = await req.text(); var body = {}; if (rawBody && rawBody.trim() !== "") { try { body = JSON.parse(rawBody) } catch (e) { throw new Error("صيغة JSON غير صالحة") } }
    var voucher_code = body.voucher_code; if (!voucher_code) throw new Error("رقم الإذن مطلوب")
    var authHeader = req.headers.get("Authorization"); if (!authHeader) throw new Error("غير مصرح")
    var token = authHeader.replace("Bearer ", ""); var authResult = await supabase.auth.getUser(token); if (authResult.error || !authResult.data.user) throw new Error("جلسة غير صالحة")
    var user = authResult.data.user
    var settingsResult = await supabase.from("app_settings").select("main_branch_id").limit(1).maybeSingle(); if (!settingsResult.data || !settingsResult.data.main_branch_id) throw new Error("الفرع الرئيسي غير محدد في الإعدادات")
    var mainBranchId = settingsResult.data.main_branch_id
    var voucherResult = await supabase.from("stock_vouchers").select("id, type, status, from_type, from_id").eq("voucher_code", voucher_code).maybeSingle(); if (voucherResult.error || !voucherResult.data) throw new Error("الإذن غير موجود")
    var voucher = voucherResult.data; if (voucher.status !== "Draft") throw new Error("يمكن إرسال المسودات فقط")
    var fromBranchId = voucher.from_id || mainBranchId
    var deductTypes = ["Transfer", "DirectSale", "SupplierReturn"]
    if (deductTypes.indexOf(voucher.type) !== -1) {
      var detailsResult = await supabase.from("stock_voucher_details").select("item_code, qty").eq("voucher_id", voucher.id); var details = detailsResult.data || []
      for (var i=0;i<details.length;i++) { var det=details[i]; var qty=Number(det.qty)||0; if(qty<=0) continue
        var itemResult=await supabase.from("items").select("id").eq("item_code",det.item_code).maybeSingle(); if(!itemResult.data) throw new Error("الصنف غير موجود: "+det.item_code)
        var itemId=itemResult.data.id; var stockResult=await supabase.from("stock_branches").select("qty, allocated_qty").eq("branch_id",fromBranchId).eq("item_id",itemId).maybeSingle(); var currentQty=Number(stockResult.data?.qty||0); var currentAllocated=Number(stockResult.data?.allocated_qty||0); var available=currentQty-currentAllocated
        if(available<qty) throw new Error("الرصيد غير كافٍ للصنف "+det.item_code)
        var stockError=await supabase.from("stock_branches").update({qty:currentQty-qty}).eq("branch_id",fromBranchId).eq("item_id",itemId); if(stockError.error) throw new Error("فشل خصم المخزون لـ "+det.item_code+": "+stockError.error.message)
        var logCode="OUT-"+Date.now()+"-"+Math.floor(Math.random()*1000)
        await supabase.from("inventory_log").insert({company_id:"00000000-0000-0000-0000-000000000001",log_code:logCode,movement_date:new Date().toISOString().split("T")[0],voucher_id:voucher_code,item_id:itemId,item_code:det.item_code,item_name:det.item_name||det.item_code,movement_type:voucher.type,qty:qty,reference:voucher_code,user_email:user.email})
      }
    }
    await supabase.from("stock_vouchers").update({status:"Sent",sent_date:new Date().toISOString()}).eq("id",voucher.id)
    return new Response(JSON.stringify({success:true,msg:"تم إرسال الإذن وخصم المخزون"}),{headers:Object.assign({},corsHeaders,{"Content-Type":"application/json"})})
  } catch(error) { return new Response(JSON.stringify({success:false,msg:error.message}),{status:400,headers:Object.assign({},corsHeaders,{"Content-Type":"application/json"})}) }
})
