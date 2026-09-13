import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS'
}

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' }
  })
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })

  try {
    const auth = req.headers.get('Authorization')
    if (!auth) throw new Error('غير مصرح')

    const token = auth.replace(/^Bearer\s+/i, '')
    const { data: authData, error: authError } = await supabase.auth.getUser(token)
    if (authError || !authData.user?.id || !authData.user.email) throw new Error('جلسة غير صالحة')

    const { data: actor, error: actorError } = await supabase
      .from('users')
      .select('id,company_id,status')
      .eq('auth_id', authData.user.id)
      .maybeSingle()

    if (actorError || !actor?.company_id || actor.status === 'Inactive') {
      throw new Error('سياق الشركة غير متاح للمستخدم')
    }

    const body = await req.json().catch(() => ({}))
    const action = String(body?.action || 'list').trim().toLowerCase()
    const companyId = actor.company_id
    const email = authData.user.email

    if (action === 'list') {
      const { data, error } = await supabase.rpc('list_sales_return_management', {
        p_company_id: companyId,
        p_from_date: body?.from_date || null,
        p_to_date: body?.to_date || null,
        p_review_status: body?.review_status || null,
        p_source_type: body?.source_type || null,
        p_query: body?.query || null,
        p_limit: Number(body?.limit ?? 50),
        p_offset: Number(body?.offset ?? 0),
        p_actor_email: email
      })
      if (error) throw new Error(error.message)
      return json(data)
    }

    if (action === 'summary') {
      const { data, error } = await supabase.rpc('get_sales_return_management_summary', {
        p_company_id: companyId,
        p_from_date: body?.from_date || null,
        p_to_date: body?.to_date || null,
        p_actor_email: email
      })
      if (error) throw new Error(error.message)
      return json(data)
    }

    if (action === 'detail') {
      if (!body?.credit_note_id) throw new Error('credit_note_id مطلوب')
      const { data, error } = await supabase.rpc('get_sales_return_management_detail', {
        p_company_id: companyId,
        p_credit_note_id: body.credit_note_id,
        p_actor_email: email
      })
      if (error) throw new Error(error.message)
      return json(data)
    }

    if (action === 'review') {
      if (!body?.credit_note_id) throw new Error('credit_note_id مطلوب')
      const { data, error } = await supabase.rpc('save_sales_return_review', {
        p_company_id: companyId,
        p_credit_note_id: body.credit_note_id,
        p_status: String(body?.status || 'open'),
        p_assigned_to: body?.assigned_to || null,
        p_note: body?.note || null,
        p_resolution: body?.resolution || null,
        p_actor_email: email
      })
      if (error) throw new Error(error.message)
      return json(data)
    }

    throw new Error('عملية غير مدعومة')
  } catch (error) {
    return json({ success: false, msg: error instanceof Error ? error.message : 'فشل إدارة المرتجعات' }, 400)
  }
})
