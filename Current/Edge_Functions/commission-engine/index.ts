import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabase=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!)
const cors={'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization,x-client-info,apikey,content-type','Access-Control-Allow-Methods':'POST,OPTIONS'}

serve(async(req)=>{
  if(req.method==='OPTIONS') return new Response('ok',{headers:cors})
  try{
    const b=await req.json().catch(()=>({}))
    const operation=String(b?.operation||'').trim()
    if(!operation) throw new Error('عملية العمولة مطلوبة')
    const ah=req.headers.get('Authorization')
    if(!ah) throw new Error('غير مصرح')
    const {data:{user},error:ae}=await supabase.auth.getUser(ah.replace('Bearer ',''))
    if(ae||!user?.id||!user?.email) throw new Error('جلسة غير صالحة')
    const {data:u,error:ue}=await supabase.from('users').select('id,company_id,role,status').eq('auth_id',user.id).maybeSingle()
    if(ue||!u?.company_id||u.status!=='Active') throw new Error('سياق المستخدم غير متاح')
    const allowed=['PLAN_SAVE','PLAN_APPROVE','PLAN_ASSIGN','PREVIEW','POST','APPROVE_RUN','MARK_PAID','REVERSE_RUN']
    if(!allowed.includes(operation)) throw new Error('عملية Commission غير مدعومة')
    const args={
      p_company_id:u.company_id,p_operation:operation,p_user_email:user.email,
      p_plan_id:b?.plan_id||null,p_plan_payload:b?.plan_payload||null,p_rule_payload:b?.rule_payload||null,
      p_assignment_payload:b?.assignment_payload||null,p_period_start:b?.period_start||null,p_period_end:b?.period_end||null,
      p_sales_rep_id:b?.sales_rep_id||null,p_operation_id:b?.operation_id||null,p_run_id:b?.run_id||null,
      p_reason:b?.reason||null,p_payment_reference:b?.payment_reference||null
    }
    const {data,error}=await supabase.rpc('commission_engine_atomic',args)
    if(error) throw new Error(error.message)
    return new Response(JSON.stringify(data),{headers:{...cors,'Content-Type':'application/json'}})
  }catch(e){
    return new Response(JSON.stringify({success:false,msg:e?.message||'فشل تشغيل محرك العمولات'}),{status:400,headers:{...cors,'Content-Type':'application/json'}})
  }
})
