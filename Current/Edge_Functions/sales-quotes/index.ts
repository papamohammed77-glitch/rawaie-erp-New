import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase=createClient(Deno.env.get("SUPABASE_URL")!,Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
const cors={"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type","Access-Control-Allow-Methods":"POST, OPTIONS"};

async function actor(req:Request){
  const h=req.headers.get("Authorization");
  if(!h) throw new Error("غير مصرح");
  const token=h.replace(/^Bearer\s+/i,"");
  const {data,error}=await supabase.auth.getUser(token);
  if(error||!data.user?.id||!data.user.email) throw new Error("جلسة غير صالحة");
  const {data:u,error:ue}=await supabase.from("users").select("id,company_id,email,status,permissions").eq("auth_id",data.user.id).maybeSingle();
  if(ue||!u?.company_id||u.status!=="Active") throw new Error("سياق المستخدم غير صالح");
  return {id:u.id,company_id:u.company_id,email:u.email||data.user.email};
}
function uuidOrNull(v:unknown){const s=String(v??"").trim();return s||null;}
async function rpc(fn:string,args:Record<string,unknown>){const {data,error}=await supabase.rpc(fn,args);if(error)throw new Error(error.message);return data;}

serve(async(req)=>{
  if(req.method==="OPTIONS") return new Response("ok",{headers:cors});
  try{
    const a=await actor(req); const b=await req.json().catch(()=>({}));
    const action=String(b?.action||"list").trim().toLowerCase(); const c=a.company_id; let data;
    switch(action){
      case "list": data=await rpc("list_sales_quotes",{p_company_id:c,p_user_email:a.email,p_status:b?.status||null,p_query:b?.query||null,p_from_date:b?.from_date||null,p_to_date:b?.to_date||null,p_limit:Number(b?.limit||50),p_offset:Number(b?.offset||0)});break;
      case "summary": data=await rpc("get_sales_quote_summary",{p_company_id:c,p_user_email:a.email,p_from_date:b?.from_date||null,p_to_date:b?.to_date||null});break;
      case "detail": data=await rpc("get_sales_quote_detail",{p_company_id:c,p_quote_code:b?.quote_code,p_user_email:a.email});break;
      case "create": { const op=uuidOrNull(b?.operation_id); if(!op)throw new Error("operation_id مطلوب"); data=await rpc("create_sales_quote_atomic",{p_company_id:c,p_quote_date:b?.quote_date||null,p_valid_until:b?.valid_until||null,p_customer_id:uuidOrNull(b?.customer_id),p_customer_name:b?.customer_name||null,p_customer_phone:b?.customer_phone||null,p_area:b?.area||null,p_branch_id:uuidOrNull(b?.branch_id),p_sales_rep_id:uuidOrNull(b?.sales_rep_id),p_currency:b?.currency||"SAR",p_discount_amount:Number(b?.discount_amount||0),p_delivery_fee:Number(b?.delivery_fee||0),p_reference:b?.reference||null,p_notes:b?.notes||null,p_terms:b?.terms||null,p_created_by:a.email,p_operation_id:op,p_items:Array.isArray(b?.items)?b.items:[]});break; }
      case "update": data=await rpc("update_sales_quote_atomic",{p_company_id:c,p_quote_code:b?.quote_code,p_valid_until:b?.valid_until||null,p_customer_id:uuidOrNull(b?.customer_id),p_customer_name:b?.customer_name||null,p_customer_phone:b?.customer_phone||null,p_area:b?.area||null,p_branch_id:uuidOrNull(b?.branch_id),p_sales_rep_id:uuidOrNull(b?.sales_rep_id),p_currency:b?.currency||"SAR",p_discount_amount:Number(b?.discount_amount||0),p_delivery_fee:Number(b?.delivery_fee||0),p_reference:b?.reference||null,p_notes:b?.notes||null,p_terms:b?.terms||null,p_user_email:a.email,p_items:Array.isArray(b?.items)?b.items:[]});break;
      case "send":case "accept":case "reject":case "cancel": data=await rpc("change_sales_quote_status_atomic",{p_company_id:c,p_quote_code:b?.quote_code,p_action:action.toUpperCase(),p_user_email:a.email,p_note:b?.note||null});break;
      case "expire_due": data=await rpc("expire_due_sales_quotes_atomic",{p_company_id:c,p_user_email:a.email});break;
      case "convert": { const op=uuidOrNull(b?.operation_id); if(!op)throw new Error("operation_id مطلوب للتحويل"); data=await rpc("convert_sales_quote_to_order_atomic",{p_company_id:c,p_quote_code:b?.quote_code,p_user_email:a.email,p_operation_id:op});break; }
      default: throw new Error("عملية عروض أسعار غير معروفة");
    }
    return new Response(JSON.stringify(data),{headers:{...cors,"Content-Type":"application/json"}});
  }catch(e){return new Response(JSON.stringify({success:false,msg:e instanceof Error?e.message:"فشل تنفيذ العملية"}),{status:400,headers:{...cors,"Content-Type":"application/json"}});}
});
