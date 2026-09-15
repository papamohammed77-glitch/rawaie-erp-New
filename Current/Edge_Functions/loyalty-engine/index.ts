import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabase=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!)
const corsHeaders={'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization, x-client-info, apikey, content-type, idempotency-key','Access-Control-Allow-Methods':'POST, OPTIONS'}

Deno.serve(async(req)=>{
  if(req.method==='OPTIONS') return new Response('ok',{headers:corsHeaders})
  if(req.method!=='POST') return new Response(JSON.stringify({success:false,msg:'POST فقط'}),{status:405,headers:{...corsHeaders,'Content-Type':'application/json'}})
  try{
    const body=await req.json().catch(()=>({}))
    const operation=String(body?.operation||'').trim()
    const payload=body?.payload&&typeof body.payload==='object'?body.payload:{}
    const operationId=String(body?.operation_id||req.headers.get('Idempotency-Key')||'').trim()||null
    if(!operation) throw new Error('operation مطلوب')
    const ah=req.headers.get('Authorization')
    if(!ah) throw new Error('Authorization مطلوب')
    const token=ah.replace(/^Bearer\s+/i,'')
    const {data:{user},error:ae}=await supabase.auth.getUser(token)
    if(ae||!user?.id||!user?.email) throw new Error('جلسة غير صالحة')
    const {data:u,error:ue}=await supabase.from('users').select('id,company_id,email,status').eq('auth_id',user.id).maybeSingle()
    if(ue||!u?.company_id) throw new Error('سياق الشركة غير محدد للمستخدم')
    if(u.status&&u.status!=='Active') throw new Error('المستخدم غير نشط')
    const enriched={...payload}
    if(enriched.customer_id==null&&body?.customer_id) enriched.customer_id=body.customer_id
    if(enriched.order_id==null&&body?.order_id) enriched.order_id=body.order_id
    const {data,error}=await supabase.rpc('loyalty_engine_atomic',{p_company_id:u.company_id,p_operation:operation,p_user_email:user.email,p_payload:enriched,p_operation_id:operationId})
    if(error) throw new Error(error.message)
    return new Response(JSON.stringify(data),{headers:{...corsHeaders,'Content-Type':'application/json'}})
  }catch(e){
    return new Response(JSON.stringify({success:false,msg:e instanceof Error?e.message:'فشل محرك الولاء'}),{status:400,headers:{...corsHeaders,'Content-Type':'application/json'}})
  }
})
