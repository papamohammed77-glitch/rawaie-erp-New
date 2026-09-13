import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
const cors = {"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type","Access-Control-Allow-Methods":"POST, OPTIONS"};

async function actor(req: Request) {
  const h = req.headers.get("Authorization");
  if (!h) throw new Error("غير مصرح");
  const {data,error} = await db.auth.getUser(h.replace(/^Bearer\s+/i,""));
  if (error || !data.user?.id || !data.user.email) throw new Error("جلسة غير صالحة");
  const {data:u,error:ue} = await db.from("users").select("id,company_id,email,status,permissions,role").eq("auth_id",data.user.id).maybeSingle();
  if (ue || !u?.company_id || u.status !== "Active") throw new Error("سياق المستخدم غير صالح");
  const p = Array.isArray(u.permissions) ? u.permissions : [];
  if (!(String(u.role||"").toLowerCase()==="owner" || p.includes("*") || p.includes("orders") || p.includes("sales") || p.includes("price_lists"))) throw new Error("لا توجد صلاحية لقوائم الأسعار");
  return {company_id:u.company_id,email:u.email||data.user.email};
}

async function audit(companyId:string,email:string,action:string,table:string,id:string,oldData:any,newData:any){
  await db.from("audit_log").insert({user_email:email,action,table_name:table,record_id:id,old_data:oldData??null,new_data:newData??null});
}
function day(v:any){return v?String(v).slice(0,10):null;}

serve(async(req)=>{
  if(req.method==='OPTIONS') return new Response('ok',{headers:cors});
  try{
    const a=await actor(req); const b=await req.json().catch(()=>({})); const action=String(b?.action||'list').trim().toLowerCase(); const c=a.company_id;
    if(action==='list'){
      const {data,error}=await db.from('commercial_catalogs').select('*').eq('company_id',c).order('priority').order('name');
      if(error) throw new Error(error.message); return new Response(JSON.stringify({success:true,rows:data||[]}),{headers:{...cors,'Content-Type':'application/json'}});
    }
    if(action==='catalog'){
      const [lr,ir,cr,cu]=await Promise.all([
        db.from('commercial_catalogs').select('*').eq('company_id',c).eq('is_active',true).order('priority'),
        db.from('items').select('id,item_code,name,unit,sales_price,category_id,is_active').eq('is_active',true).order('item_code'),
        db.from('categories').select('id,category_name').eq('company_id',c).order('category_name'),
        db.from('customers').select('id,customer_code,name,phone').eq('company_id',c).eq('is_active',true).order('name')
      ]);
      for(const r of [lr,ir,cr,cu]) if(r.error) throw new Error(r.error.message);
      return new Response(JSON.stringify({success:true,lists:lr.data||[],items:ir.data||[],categories:cr.data||[],customers:cu.data||[]}),{headers:{...cors,'Content-Type':'application/json'}});
    }
    if(action==='detail'){
      const id=String(b?.catalog_id||''); if(!id) throw new Error('catalog_id مطلوب');
      const [lr,rr,cr]=await Promise.all([
        db.from('commercial_catalogs').select('*').eq('company_id',c).eq('id',id).maybeSingle(),
        db.from('commercial_catalog_rules').select('*').eq('catalog_id',id).order('sequence').order('min_qty'),
        db.from('commercial_customer_links').select('id,customer_id,is_primary,created_by,created_at').eq('company_id',c).eq('catalog_id',id)
      ]);
      if(lr.error||rr.error||cr.error) throw new Error((lr.error||rr.error||cr.error)!.message);
      if(!lr.data) throw new Error('قائمة الأسعار غير موجودة');
      return new Response(JSON.stringify({success:true,catalog:lr.data,rules:rr.data||[],customers:cr.data||[]}),{headers:{...cors,'Content-Type':'application/json'}});
    }
    if(action==='create'){
      const op=String(b?.operation_id||'').trim(); if(!op) throw new Error('operation_id مطلوب');
      const existing=(await db.from('erp_operation_registry').select('response_payload,status').eq('company_id',c).eq('operation_type','commercial_catalog_create').eq('operation_key',op).maybeSingle()).data;
      if(existing?.status==='completed') return new Response(JSON.stringify(existing.response_payload),{headers:{...cors,'Content-Type':'application/json'}});
      const payload={company_id:c,code:String(b?.code||'').trim(),name:String(b?.name||'').trim(),currency:String(b?.currency||'SAR'),priority:Number(b?.priority??100),is_default:Boolean(b?.is_default),is_active:b?.is_active!==false,valid_from:day(b?.valid_from),valid_until:day(b?.valid_until),notes:b?.notes||null,created_by:a.email};
      if(!payload.code||!payload.name) throw new Error('كود واسم قائمة الأسعار مطلوبان');
      if(payload.is_default) await db.from('commercial_catalogs').update({is_default:false,updated_at:new Date().toISOString()}).eq('company_id',c).eq('is_default',true);
      const {data:cat,error:ce}=await db.from('commercial_catalogs').insert(payload).select('*').single(); if(ce) throw new Error(ce.message);
      const rules=Array.isArray(b?.rules)?b.rules:[];
      if(rules.length){
        const rows=rules.map((r:any)=>({catalog_id:cat.id,sequence:Number(r.sequence??100),scope_type:r.scope_type,item_id:r.item_id||null,category_id:r.category_id||null,min_qty:Number(r.min_qty??1),pricing_method:r.pricing_method||'fixed',unit_price:Number(r.unit_price??0),percent_value:Number(r.percent_value??0),extra_fee:Number(r.extra_fee??0),rounding_multiple:Number(r.rounding_multiple??0),valid_from:day(r.valid_from),valid_until:day(r.valid_until),is_active:r.is_active!==false,notes:r.notes||null}));
        const {error:re}=await db.from('commercial_catalog_rules').insert(rows);
        if(re){await db.from('commercial_catalogs').delete().eq('id',cat.id).eq('company_id',c); throw new Error(re.message);}
      }
      await audit(c,a.email,'create','commercial_catalogs',cat.id,null,cat);
      const out={success:true,catalog:cat}; await db.from('erp_operation_registry').insert({company_id:c,operation_type:'commercial_catalog_create',operation_key:op,request_payload:b,status:'completed',response_payload:out,completed_at:new Date().toISOString()});
      return new Response(JSON.stringify(out),{headers:{...cors,'Content-Type':'application/json'}});
    }
    if(action==='update'){
      const id=String(b?.catalog_id||''); if(!id) throw new Error('catalog_id مطلوب');
      const {data:old,error:oe}=await db.from('commercial_catalogs').select('*').eq('company_id',c).eq('id',id).maybeSingle(); if(oe||!old) throw new Error('قائمة الأسعار غير موجودة');
      const patch={code:String(b?.code??old.code).trim(),name:String(b?.name??old.name).trim(),currency:String(b?.currency??old.currency),priority:Number(b?.priority??old.priority),is_default:Boolean(b?.is_default??old.is_default),is_active:b?.is_active!==false,valid_from:day(b?.valid_from??old.valid_from),valid_until:day(b?.valid_until??old.valid_until),notes:b?.notes??old.notes,updated_at:new Date().toISOString()};
      if(patch.is_default) await db.from('commercial_catalogs').update({is_default:false,updated_at:new Date().toISOString()}).eq('company_id',c).eq('is_default',true).neq('id',id);
      const {data:cat,error:ce}=await db.from('commercial_catalogs').update(patch).eq('company_id',c).eq('id',id).select('*').single(); if(ce) throw new Error(ce.message);
      if(Array.isArray(b?.rules)){
        const {error:de}=await db.from('commercial_catalog_rules').delete().eq('catalog_id',id); if(de) throw new Error(de.message);
        if(b.rules.length){const rows=b.rules.map((r:any)=>({catalog_id:id,sequence:Number(r.sequence??100),scope_type:r.scope_type,item_id:r.item_id||null,category_id:r.category_id||null,min_qty:Number(r.min_qty??1),pricing_method:r.pricing_method||'fixed',unit_price:Number(r.unit_price??0),percent_value:Number(r.percent_value??0),extra_fee:Number(r.extra_fee??0),rounding_multiple:Number(r.rounding_multiple??0),valid_from:day(r.valid_from),valid_until:day(r.valid_until),is_active:r.is_active!==false,notes:r.notes||null})); const {error:re}=await db.from('commercial_catalog_rules').insert(rows); if(re) throw new Error(re.message);}
      }
      await audit(c,a.email,'update','commercial_catalogs',id,old,cat); return new Response(JSON.stringify({success:true,catalog:cat}),{headers:{...cors,'Content-Type':'application/json'}});
    }
    if(action==='assign'){
      const customerId=String(b?.customer_id||''),catalogId=String(b?.catalog_id||''); if(!customerId||!catalogId) throw new Error('customer_id و catalog_id مطلوبان');
      const cu=(await db.from('customers').select('id').eq('id',customerId).eq('company_id',c).maybeSingle()).data; if(!cu) throw new Error('العميل غير تابع للشركة');
      const cat=(await db.from('commercial_catalogs').select('id').eq('id',catalogId).eq('company_id',c).eq('is_active',true).maybeSingle()).data; if(!cat) throw new Error('قائمة الأسعار غير صالحة');
      await db.from('commercial_customer_links').update({is_primary:false}).eq('company_id',c).eq('customer_id',customerId).eq('is_primary',true);
      const {data:row,error}=await db.from('commercial_customer_links').upsert({company_id:c,catalog_id:catalogId,customer_id:customerId,is_primary:true,created_by:a.email},{onConflict:'catalog_id,customer_id'}).select('*').single(); if(error) throw new Error(error.message);
      await audit(c,a.email,'create','commercial_customer_links',row.id,null,row); return new Response(JSON.stringify({success:true,row}),{headers:{...cors,'Content-Type':'application/json'}});
    }
    if(action==='resolve'){
      const itemId=String(b?.item_id||''); const qty=Number(b?.qty||0); if(!itemId) throw new Error('item_id مطلوب'); if(!(qty>0)) throw new Error('الكمية يجب أن تكون أكبر من صفر');
      const date=day(b?.on_date)||new Date().toISOString().slice(0,10); const customerId=b?.customer_id?String(b.customer_id):null; const explicit=b?.catalog_id?String(b.catalog_id):null;
      const {data:item,error:ie}=await db.from('items').select('id,item_code,name,sales_price,category_id').eq('id',itemId).maybeSingle(); if(ie||!item) throw new Error('الصنف غير موجود');
      let catalog:any=null;
      if(explicit) catalog=(await db.from('commercial_catalogs').select('*').eq('id',explicit).eq('company_id',c).eq('is_active',true).maybeSingle()).data||null;
      if(!catalog&&customerId){const link=(await db.from('commercial_customer_links').select('catalog_id').eq('company_id',c).eq('customer_id',customerId).eq('is_primary',true).maybeSingle()).data;if(link) catalog=(await db.from('commercial_catalogs').select('*').eq('id',link.catalog_id).eq('company_id',c).eq('is_active',true).maybeSingle()).data||null;}
      if(!catalog) catalog=(await db.from('commercial_catalogs').select('*').eq('company_id',c).eq('is_active',true).eq('is_default',true).order('priority').limit(1).maybeSingle()).data||null;
      if(!catalog) return new Response(JSON.stringify({success:true,price:item.sales_price,base_price:item.sales_price,source:'items.sales_price'}),{headers:{...cors,'Content-Type':'application/json'}});
      const {data:rules,error:re}=await db.from('commercial_catalog_rules').select('*').eq('catalog_id',catalog.id).eq('is_active',true).lte('min_qty',qty).order('min_qty',{ascending:false}).order('sequence',{ascending:true}); if(re) throw new Error(re.message);
      const valid=(rules||[]).filter((r:any)=>(!r.valid_from||String(r.valid_from)<=date)&&(!r.valid_until||String(r.valid_until)>=date));
      const matched=valid.filter((r:any)=>(r.scope_type==='item'&&r.item_id===item.id)||(r.scope_type==='category'&&r.category_id===item.category_id)||r.scope_type==='all').sort((x:any,y:any)=>{const sx=x.scope_type==='item'?1:x.scope_type==='category'?2:3,sy=y.scope_type==='item'?1:y.scope_type==='category'?2:3;return sx-sy||Number(y.min_qty)-Number(x.min_qty)||Number(x.sequence)-Number(y.sequence);})[0];
      if(!matched) return new Response(JSON.stringify({success:true,price:item.sales_price,base_price:item.sales_price,source:'catalog_no_matching_rule',catalog_id:catalog.id,catalog_code:catalog.code}),{headers:{...cors,'Content-Type':'application/json'}});
      let price=Number(item.sales_price||0); if(matched.pricing_method==='fixed') price=Number(matched.unit_price); else if(matched.pricing_method==='discount_percent') price*=1-Number(matched.percent_value||0)/100; else price*=1+Number(matched.percent_value||0)/100; price+=Number(matched.extra_fee||0); if(Number(matched.rounding_multiple||0)>0) price=Math.round(price/Number(matched.rounding_multiple))*Number(matched.rounding_multiple); price=Math.max(0,price);
      return new Response(JSON.stringify({success:true,price,base_price:item.sales_price,source:`catalog_${matched.scope_type}_rule`,catalog_id:catalog.id,catalog_code:catalog.code,rule_id:matched.id,min_qty:matched.min_qty,pricing_method:matched.pricing_method}),{headers:{...cors,'Content-Type':'application/json'}});
    }
    if(action==='delete'){
      const id=String(b?.catalog_id||''); const {data:old}=await db.from('commercial_catalogs').select('*').eq('id',id).eq('company_id',c).maybeSingle(); if(!old) throw new Error('قائمة الأسعار غير موجودة');
      const {data:cat,error}=await db.from('commercial_catalogs').update({is_active:false,is_default:false,updated_at:new Date().toISOString()}).eq('id',id).eq('company_id',c).select('*').single(); if(error) throw new Error(error.message);
      await audit(c,a.email,'update','commercial_catalogs',id,old,cat); return new Response(JSON.stringify({success:true,catalog:cat}),{headers:{...cors,'Content-Type':'application/json'}});
    }
    throw new Error('عملية قوائم أسعار غير معروفة');
  }catch(e){return new Response(JSON.stringify({success:false,msg:e instanceof Error?e.message:'فشل التنفيذ'}),{status:400,headers:{...cors,'Content-Type':'application/json'}});}
});
