import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const db=createClient(Deno.env.get("SUPABASE_URL")!,Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!)
const cors={"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type","Access-Control-Allow-Methods":"GET,POST,OPTIONS"}

async function auth(req:Request){
  const h=req.headers.get("Authorization");
  if(!h) throw Error("غير مصرح")
  const {data:{user},error}=await db.auth.getUser(h.replace("Bearer ",""))
  if(error||!user?.id||!user.email) throw Error("جلسة غير صالحة")
  const {data:u,error:ue}=await db.from("users").select("id,company_id,status").eq("auth_id",user.id).maybeSingle()
  if(ue||!u?.company_id||String(u.status||"Active")!=="Active") throw Error("سياق الشركة غير محدد للمستخدم")
  return {user,companyId:u.company_id}
}

serve(async(req)=>{
  if(req.method==='OPTIONS') return new Response('ok',{headers:cors})
  try{
    const {user,companyId}=await auth(req)
    if(req.method==='GET'){
      const url=new URL(req.url)
      const orderId=url.searchParams.get('order_id')
      const planId=url.searchParams.get('installment_id')
      let q=db.from('installment_aging_v').select('*').eq('company_id',companyId).order('next_due_date',{ascending:true})
      if(orderId) q=q.eq('order_id',orderId)
      if(planId) q=q.eq('installment_id',planId)
      const {data,error}=await q
      if(error) throw Error(error.message)
      return new Response(JSON.stringify({success:true,data:data||[]}),{headers:{...cors,'Content-Type':'application/json'}})
    }
    const b=await req.json().catch(()=>({}))
    const action=String(b?.action||'list')
    let data:any
    if(action==='create'){
      data=await db.rpc('create_installment_plan_atomic',{p_company_id:companyId,p_order_id:b.order_id,p_schedule:b.schedule,p_created_by:user.email,p_operation_id:b.operation_id})
    }else if(action==='cancel'){
      data=await db.rpc('cancel_installment_plan_atomic',{p_company_id:companyId,p_installment_id:b.installment_id,p_user_email:user.email})
    }else if(action==='refresh'){
      data=await db.rpc('refresh_installment_plan_atomic',{p_company_id:companyId,p_installment_id:b.installment_id,p_as_of:b.as_of||new Date().toISOString().slice(0,10),p_user_email:user.email})
    }else if(action==='list'){
      let q=db.from('installment_aging_v').select('*').eq('company_id',companyId).order('next_due_date',{ascending:true})
      if(b.status) q=q.eq('effective_status',b.status)
      if(b.customer_id) q=q.eq('customer_id',b.customer_id)
      data=await q
    }else throw Error('عملية التقسيط غير مدعومة')
    if(data?.error) throw Error(data.error.message)
    return new Response(JSON.stringify(data),{headers:{...cors,'Content-Type':'application/json'}})
  }catch(e){
    return new Response(JSON.stringify({success:false,msg:e?.message||'فشل تنفيذ عملية التقسيط'}),{status:400,headers:{...cors,'Content-Type':'application/json'}})
  }
})