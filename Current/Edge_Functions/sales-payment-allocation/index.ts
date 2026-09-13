import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const supabase=createClient(Deno.env.get("SUPABASE_URL")!,Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
serve(async(req)=>{
 const origin=req.headers.get("Origin")||"*";
 const cors={"Access-Control-Allow-Origin":origin,"Access-Control-Allow-Headers":"authorization,x-client-info,apikey,content-type","Access-Control-Allow-Methods":"POST,OPTIONS"};
 if(req.method==="OPTIONS") return new Response("ok",{headers:cors});
 try{
  const auth=req.headers.get("Authorization"); if(!auth) throw new Error("UNAUTHORIZED");
  const token=auth.replace(/^Bearer\s+/i,"");
  const {data:{user},error:ae}=await supabase.auth.getUser(token); if(ae||!user?.id||!user.email) throw new Error("INVALID_SESSION");
  const {data:actor,error:ue}=await supabase.from("users").select("company_id,status").eq("auth_id",user.id).maybeSingle();
  if(ue||!actor?.company_id||(actor.status&&actor.status!=="Active")) throw new Error("USER_COMPANY_CONTEXT_INVALID");
  const companyId=actor.company_id;
  const body=await req.json().catch(()=>({}));
  const action=String(body?.action||"").trim().toLowerCase();
  if(action==="catalog"){
   const [c,t]=await Promise.all([
    supabase.from("customers").select("id,customer_code,name,phone,payment_type,is_active").eq("company_id",companyId).eq("is_active",true).order("name"),
    supabase.from("treasury").select("id,account_code,account_name,type,current_balance,is_active").eq("company_id",companyId).eq("is_active",true).order("account_code")
   ]); if(c.error) throw c.error; if(t.error) throw t.error;
   return new Response(JSON.stringify({success:true,customers:c.data||[],treasury:t.data||[]}),{headers:{...cors,"Content-Type":"application/json"}});
  }
  if(action==="open_orders"){
   const customerId=String(body?.customer_id||"").trim(); if(!customerId) throw new Error("CUSTOMER_REQUIRED");
   const {data:customer,error:ce}=await supabase.from("customers").select("id,customer_code,name").eq("id",customerId).eq("company_id",companyId).maybeSingle(); if(ce||!customer) throw new Error("CUSTOMER_NOT_FOUND_OR_WRONG_COMPANY");
   const {data,error}=await supabase.from("orders").select("id,order_code,order_date,order_status,total_amount,amount_paid,payment_type").eq("company_id",companyId).eq("customer_id",customerId).neq("order_status","Cancelled").order("order_date").order("order_code"); if(error) throw error;
   const orders=(data||[]).map((o:any)=>({...o,outstanding:Math.max(0,Number(o.total_amount||0)-Number(o.amount_paid||0))})).filter((o:any)=>o.outstanding>0);
   return new Response(JSON.stringify({success:true,customer,orders}),{headers:{...cors,"Content-Type":"application/json"}});
  }
  if(action==="list"){
   const customerId=body?.customer_id?String(body.customer_id).trim():"";
   let q=supabase.from("sales_payment_receipts").select("id,customer_id,receipt_code,receipt_date,amount,allocated_amount,unallocated_amount,reference,notes,status,created_by,created_at").eq("company_id",companyId).order("receipt_date",{ascending:false}).order("created_at",{ascending:false}).limit(200); if(customerId) q=q.eq("customer_id",customerId);
   const {data:receipts,error}=await q; if(error) throw error;
   const ids=(receipts||[]).map((r:any)=>r.id); let allocations:any[]=[]; if(ids.length){const ar=await supabase.from("sales_payment_allocations").select("id,receipt_id,order_id,allocated_amount,created_at").eq("company_id",companyId).in("receipt_id",ids); if(ar.error) throw ar.error; allocations=ar.data||[];}
   const orderIds=allocations.map((a:any)=>a.order_id); let orders:any[]=[]; if(orderIds.length){const or=await supabase.from("orders").select("id,order_code,total_amount,amount_paid,order_status").eq("company_id",companyId).in("id",orderIds); if(or.error) throw or.error; orders=or.data||[];}
   return new Response(JSON.stringify({success:true,receipts:receipts||[],allocations,orders}),{headers:{...cors,"Content-Type":"application/json"}});
  }
  if(action==="detail"){
   const receiptId=String(body?.receipt_id||"").trim(); if(!receiptId) throw new Error("RECEIPT_REQUIRED");
   const {data:receipt,error:re}=await supabase.from("sales_payment_receipts").select("*").eq("id",receiptId).eq("company_id",companyId).maybeSingle(); if(re||!receipt) throw new Error("RECEIPT_NOT_FOUND_OR_WRONG_COMPANY");
   const {data:allocations,error:ae2}=await supabase.from("sales_payment_allocations").select("id,order_id,allocated_amount,created_at").eq("receipt_id",receipt.id).eq("company_id",companyId); if(ae2) throw ae2;
   const orderIds=(allocations||[]).map((a:any)=>a.order_id); let orders:any[]=[]; if(orderIds.length){const or=await supabase.from("orders").select("id,order_code,order_date,order_status,total_amount,amount_paid,payment_type").eq("company_id",companyId).in("id",orderIds); if(or.error) throw or.error; orders=or.data||[];}
   return new Response(JSON.stringify({success:true,receipt,allocations:allocations||[],orders}),{headers:{...cors,"Content-Type":"application/json"}});
  }
  if(action==="create"){
   const operationId=String(body?.operation_id||body?.operationId||"").trim(),customerId=String(body?.customer_id||body?.customerId||"").trim(),treasuryId=String(body?.treasury_id||body?.treasuryId||"").trim(),amount=Number(body?.amount),allocations=Array.isArray(body?.allocations)?body.allocations:[],receiptDate=String(body?.receipt_date||body?.receiptDate||new Date().toISOString().slice(0,10)),reference=body?.reference==null?null:String(body.reference),notes=body?.notes==null?null:String(body.notes);
   if(!operationId) throw new Error("OPERATION_ID_REQUIRED"); if(!customerId) throw new Error("CUSTOMER_REQUIRED"); if(!treasuryId) throw new Error("TREASURY_REQUIRED"); if(!(amount>0)) throw new Error("AMOUNT_INVALID");
   const {data,error}=await supabase.rpc("post_sales_payment_allocation_atomic",{p_company_id:companyId,p_operation_id:operationId,p_customer_id:customerId,p_treasury_id:treasuryId,p_amount:amount,p_receipt_date:receiptDate,p_allocations:allocations,p_reference:reference,p_notes:notes,p_created_by:user.email});
   if(error) throw error; return new Response(JSON.stringify(data),{headers:{...cors,"Content-Type":"application/json"}});
  }
  throw new Error("UNKNOWN_ACTION");
 }catch(error:any){return new Response(JSON.stringify({success:false,msg:error?.message||String(error)}),{status:400,headers:{...cors,"Content-Type":"application/json"}})}
});