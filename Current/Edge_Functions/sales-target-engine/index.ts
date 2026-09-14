import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const supabase=createClient(Deno.env.get("SUPABASE_URL")!,Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!)
const cors={"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type","Access-Control-Allow-Methods":"POST, OPTIONS"}

serve(async(req)=>{
  if(req.method==='OPTIONS') return new Response('ok',{headers:cors})
  try{
    const body=await req.json().catch(()=>({}))
    const auth=req.headers.get('Authorization')
    if(!auth) throw new Error('غير مصرح')
    const {data:{user},error:ae}=await supabase.auth.getUser(auth.replace('Bearer ',''))
    if(ae||!user?.id||!user?.email) throw new Error('جلسة غير صالحة')
    const {data:actor,error:ue}=await supabase.from('users').select('id,company_id').eq('auth_id',user.id).maybeSingle()
    if(ue||!actor?.company_id) throw new Error('سياق الشركة غير محدد للمستخدم')
    const payload=body?.payload && typeof body.payload==='object' ? body.payload : {}
    const {data,error}=await supabase.rpc('sales_target_engine_atomic',{
      p_company_id:actor.company_id,
      p_operation:String(body?.operation||'').trim(),
      p_user_email:user.email,
      p_plan_id:body?.plan_id||null,
      p_payload:payload,
      p_operation_id:body?.operation_id||null
    })
    if(error) throw new Error(error.message)
    return new Response(JSON.stringify(data),{headers:{...cors,'Content-Type':'application/json'}})
  }catch(e){
    return new Response(JSON.stringify({success:false,msg:e?.message||'فشل تنفيذ محرك مستهدفات المبيعات'}),{status:400,headers:{...cors,'Content-Type':'application/json'}})
  }
})
