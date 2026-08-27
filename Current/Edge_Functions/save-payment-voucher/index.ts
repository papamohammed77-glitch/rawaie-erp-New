// Canonical financial adapter deployed to SMART ERP Production v5.
// Authenticates the caller, resolves company context, validates the selected treasury/account IDs,
// and delegates all posting to post_cash_payment_atomic.
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const supabase=createClient(Deno.env.get("SUPABASE_URL")!,Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
serve(async(req)=>{
 const origin=req.headers.get("Origin")||"*";
 const cors={"Access-Control-Allow-Origin":origin,"Access-Control-Allow-Headers":"authorization,x-client-info,apikey,content-type","Access-Control-Allow-Methods":"POST,OPTIONS"};
 if(req.method==="OPTIONS") return new Response("ok",{headers:cors});
 try{
  const body=await req.json(); const header=body?.header,lines=body?.lines;
  if(!header||!Array.isArray(lines)||!lines.length) throw new Error("PAYMENT_PAYLOAD_INVALID");
  const auth=req.headers.get("Authorization"); if(!auth) throw new Error("UNAUTHORIZED");
  const token=auth.replace(/^Bearer\s+/i,"");
  const {data:{user},error:ae}=await supabase.auth.getUser(token); if(ae||!user) throw new Error("INVALID_SESSION");
  const {data:u,error:ue}=await supabase.from("users").select("company_id,status").eq("auth_id",user.id).maybeSingle();
  if(ue||!u?.company_id||(u.status&&u.status!=="Active")) throw new Error("USER_COMPANY_CONTEXT_INVALID");
  const companyId=u.company_id;
  const amount=lines.reduce((s:any,l:any)=>s+Number(l.amount||0),0); if(!(amount>0)) throw new Error("PAYMENT_AMOUNT_INVALID");
  const operationId=String(header.operationId||header.operation_id||"").trim(); if(!operationId) throw new Error("PAYMENT_OPERATION_ID_REQUIRED");
  const treasuryId=String(header.treasuryId||header.treasury_id||"").trim(); if(!treasuryId) throw new Error("PAYMENT_TREASURY_ID_REQUIRED");
  const {data:treasury,error:te}=await supabase.from("treasury").select("id,account_code,current_balance").eq("id",treasuryId).eq("company_id",companyId).eq("is_active",true).maybeSingle();
  if(te||!treasury) throw new Error("PAYMENT_TREASURY_NOT_FOUND_OR_WRONG_COMPANY");
  const cashAccountId=String(header.cashAccountId||header.cash_account_id||"").trim(); if(!cashAccountId) throw new Error("PAYMENT_CASH_ACCOUNT_ID_REQUIRED");
  const offsetAccountId=String(header.offsetAccountId||header.offset_account_id||header.mainAccountId||header.main_account_id||"").trim(); if(!offsetAccountId) throw new Error("PAYMENT_OFFSET_ACCOUNT_ID_REQUIRED");
  const {data:result,error}=await supabase.rpc("post_cash_payment_atomic",{p_company_id:companyId,p_operation_id:operationId,p_treasury_id:treasuryId,p_cash_account_id:cashAccountId,p_offset_account_id:offsetAccountId,p_amount:amount,p_entry_date:header.date||new Date().toISOString().slice(0,10),p_reference:header.reference||header.referenceCode||null,p_description:header.notes||"سند صرف",p_created_by:user.email||null,p_source_name:header.mainAccountName||null,p_source_type:"ACCOUNTANT",p_source_id:null,p_notes:header.notes||null,p_voucher_code:header.voucherCode||null});
  if(error) throw error; return new Response(JSON.stringify(result),{headers:{...cors,"Content-Type":"application/json"}});
 }catch(error:any){return new Response(JSON.stringify({success:false,error:error?.message||String(error)}),{status:400,headers:{...cors,"Content-Type":"application/json"}})}
});