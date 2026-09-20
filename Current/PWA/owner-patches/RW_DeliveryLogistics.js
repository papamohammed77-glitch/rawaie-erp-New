// RAWAEA ERP — RW_DeliveryLogistics
// Delivery & Logistics Control Plane — Mother surgical module.
// Does not modify driver/supervisor field apps and does not create Edge Functions.
// Reads: delivery_logistics_query / fleet_query.
// Writes: delivery_logistics_command_atomic only.
// Physical stock, fulfillment and run-sheet mutation remain owned by existing canonical engines.
(function () {
  'use strict';

  var S = {
    tab: 'dashboard',
    routeId: null,
    search: '',
    cache: { routes: [], planning: [], agents: [], collections: [], performance: [] },
    ops: {},
    busy: false
  };

  function E(id){ return typeof byId === 'function' ? byId(id) : document.getElementById(id); }
  function esc(v){
    return String(v == null ? '' : v)
      .replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')
      .replace(/"/g,'&quot;').replace(/'/g,'&#39;');
  }
  function n(v){ var x=Number(v); return Number.isFinite(x)?x:0; }
  function money(v){ return n(v).toLocaleString('ar-EG',{maximumFractionDigits:2}); }
  function date(v){ if(!v)return '—'; try{return new Date(v).toLocaleDateString('ar-EG');}catch(e){return String(v);} }
  function dt(v){ if(!v)return '—'; try{return new Date(v).toLocaleString('ar-EG',{dateStyle:'short',timeStyle:'short'});}catch(e){return String(v);} }
  function companyId(){
    return (window.RW_STATE&&RW_STATE.app&&(
      RW_STATE.app.companyId || (RW_STATE.app.company&&RW_STATE.app.company.id)
    )) || null;
  }
  function user(){ return (window.RW_STATE&&RW_STATE.app&&RW_STATE.app.currentUser)||null; }
  function perms(){ return (window.RW_STATE&&Array.isArray(RW_STATE.permissions))?RW_STATE.permissions:[]; }
  function canRead(){
    var u=user(); if(!u)return false;
    return u.isOwner===true || perms().indexOf('*')!==-1 ||
      perms().indexOf('delivery_supervisor')!==-1 || perms().indexOf('fleet.read')!==-1 ||
      perms().indexOf('fleet.manage')!==-1 || perms().indexOf('general_manager')!==-1 ||
      perms().indexOf('warehouse_manager')!==-1 || perms().indexOf('finance_manager')!==-1 ||
      u.role==='مدير عام' || u.role==='مدير مخازن' || u.role==='مشرف توصيل' || u.role==='مدير مالي';
  }
  function canManage(){
    var u=user(); if(!u)return false;
    return u.isOwner===true || perms().indexOf('*')!==-1 ||
      perms().indexOf('delivery_supervisor')!==-1 || perms().indexOf('fleet.manage')!==-1 ||
      perms().indexOf('general_manager')!==-1 || perms().indexOf('warehouse_manager')!==-1 ||
      perms().indexOf('finance_manager')!==-1 ||
      u.role==='مدير عام' || u.role==='مدير مخازن' || u.role==='مشرف توصيل' || u.role==='مدير مالي';
  }
  function op(key){
    if(!S.ops[key])S.ops[key]='DLM-UI-'+key+'-'+Date.now()+'-'+Math.random().toString(36).slice(2,9);
    return S.ops[key];
  }
  function clearOp(key){ delete S.ops[key]; }
  function toast(m,k){
    if(typeof showToast==='function')return showToast(m,k||'success');
    if(window.Swal)return Swal.fire({toast:true,position:'top-end',icon:k||'success',title:m,showConfirmButton:false,timer:2600});
    alert(m);
  }
  function set(html){ var c=E('rw-page-container'); if(c) safeHTML(c,html); }
  function card(title,sub,body,actions){
    return '<section class="rw-card" style="padding:0;overflow:hidden;margin-bottom:16px">'+
      '<div style="padding:16px 18px;background:#f8fafc;border-bottom:1px solid #eef2f7;display:flex;justify-content:space-between;gap:10px;align-items:flex-start;flex-wrap:wrap">'+
      '<div><div style="font-size:17px;font-weight:900;color:#0f172a">'+esc(title)+'</div><div style="font-size:12px;color:#64748b;margin-top:4px">'+esc(sub||'')+'</div></div>'+
      '<div style="display:flex;gap:7px;flex-wrap:wrap">'+(actions||'')+'</div></div><div style="padding:18px">'+body+'</div></section>';
  }
  function stat(title,value,icon,kind){
    var b=kind==='ok'?'#ecfdf5':kind==='warn'?'#fffbeb':kind==='bad'?'#fef2f2':'#eff6ff';
    var c=kind==='ok'?'#047857':kind==='warn'?'#b45309':kind==='bad'?'#b91c1c':'#2563eb';
    return '<div style="background:#fff;border:1px solid #eef2f7;border-radius:18px;padding:16px;box-shadow:0 5px 20px rgba(15,23,42,.04)">'+
      '<div style="display:flex;justify-content:space-between;align-items:center"><div><div style="font-size:11px;color:#64748b;font-weight:800">'+esc(title)+'</div><div style="font-size:25px;font-weight:900;color:#0f172a;margin-top:5px">'+esc(value)+'</div></div>'+
      '<div style="width:42px;height:42px;border-radius:14px;background:'+b+';color:'+c+';display:flex;align-items:center;justify-content:center"><i class="fa-solid '+icon+'"></i></div></div></div>';
  }
  function badge(v,k){
    var m={ok:['#ecfdf5','#047857'],warn:['#fffbeb','#b45309'],bad:['#fef2f2','#b91c1c'],info:['#eff6ff','#1d4ed8'],muted:['#f8fafc','#64748b']};
    var x=m[k||'muted']||m.muted;
    return '<span style="display:inline-flex;align-items:center;padding:5px 9px;border-radius:999px;background:'+x[0]+';color:'+x[1]+';font-size:11px;font-weight:900">'+esc(v)+'</span>';
  }
  function btn(t,a,cls){
    return '<button type="button" data-dlm-action="'+esc(a)+'" class="'+(cls||'px-3 py-2 rounded-xl bg-slate-900 text-white font-bold')+'">'+esc(t)+'</button>';
  }
  function input(id,label,val,type,extra){
    return '<label style="display:block;text-align:right"><span style="display:block;font-size:12px;font-weight:900;color:#475569;margin-bottom:5px">'+esc(label)+'</span>'+
      '<input id="'+esc(id)+'" type="'+esc(type||'text')+'" value="'+esc(val==null?'':val)+'" '+(extra||'')+' class="rw-input" style="height:44px;padding-right:12px"></label>';
  }
  function textarea(id,label,val){
    return '<label style="display:block;text-align:right"><span style="display:block;font-size:12px;font-weight:900;color:#475569;margin-bottom:5px">'+esc(label)+'</span>'+
      '<textarea id="'+esc(id)+'" class="rw-input" style="height:85px;padding:10px">'+esc(val||'')+'</textarea></label>';
  }
  function select(id,label,value,opts){
    return '<label style="display:block;text-align:right"><span style="display:block;font-size:12px;font-weight:900;color:#475569;margin-bottom:5px">'+esc(label)+'</span>'+
      '<select id="'+esc(id)+'" class="rw-input" style="height:44px;padding-right:12px">'+(opts||[]).map(function(x){
        return '<option value="'+esc(x[0])+'"'+(String(x[0])===String(value==null?'':value)?' selected':'')+'>'+esc(x[1])+'</option>';
      }).join('')+'</select></label>';
  }
  function val(id){ var x=E(id); return x?String(x.value||'').trim():''; }
  function modal(title,body,onSave,saveText){
    if(!window.Swal){toast('واجهة النوافذ المنبثقة غير متاحة','error');return Promise.reject(new Error('Swal unavailable'));}
    var root=document.createElement('div');
    root.innerHTML='<div style="display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:12px;text-align:right">'+body+'</div>';
    return Swal.fire({
      title:title,html:root.innerHTML,width:900,showCancelButton:true,confirmButtonText:saveText||'حفظ',
      cancelButtonText:'إلغاء',focusConfirm:false,reverseButtons:true,
      preConfirm:async function(){try{return await onSave();}catch(e){Swal.showValidationMessage(e.message||'فشل التنفيذ');throw e;}}
    });
  }
  async function q(view,payload){
    var c=companyId(); if(!c)throw new Error('سياق الشركة غير محدد');
    var u=user()||{};
    var r=await supabase.rpc('delivery_logistics_query',{
      p_company_id:c,p_view:view,p_payload:payload||{},p_actor_user_id:null,p_actor_email:u.email||null
    });
    if(r.error)throw new Error(r.error.message);
    if(!r.data||r.data.success===false)throw new Error((r.data&&(r.data.msg||r.data.message))||'فشل قراءة مركز التوصيل');
    return r.data;
  }
  async function c(command,payload,key){
    if(!canManage())throw new Error('ليس لديك صلاحية إدارة التوصيل واللوجستيات');
    var company=companyId(),u=user()||{};
    if(!company)throw new Error('سياق الشركة غير محدد');
    var k=key||command;
    var r=await supabase.rpc('delivery_logistics_command_atomic',{
      p_company_id:company,p_command:command,p_payload:payload||{},p_operation_id:op(k),
      p_actor_user_id:null,p_actor_email:u.email||null
    });
    if(r.error)throw new Error(r.error.message);
    if(!r.data||r.data.success===false)throw new Error((r.data&&(r.data.msg||r.data.message))||'فشل تنفيذ أمر التوصيل');
    clearOp(k);return r.data;
  }

  function tabs(){
    var list=[['dashboard','لوحة القيادة','fa-chart-pie'],['planning','التخطيط','fa-layer-group'],
      ['routes','الرحلات والمسارات','fa-route'],['agents','مناديب التوصيل','fa-user-ninja'],
      ['collections','التحصيلات','fa-money-bill-wave'],['performance','الأداء','fa-chart-line']];
    return '<div style="display:flex;gap:8px;flex-wrap:wrap;background:#fff;border:1px solid #eef2f7;border-radius:18px;padding:8px;margin-bottom:16px">'+
      list.map(function(x){return '<button type="button" data-dlm-tab="'+x[0]+'" style="border:0;border-radius:13px;padding:10px 14px;font-weight:900;cursor:pointer;background:'+(S.tab===x[0]?'#eff6ff':'#f8fafc')+';color:'+(S.tab===x[0]?'#2563eb':'#475569')+'"><i class="fa-solid '+x[2]+'" style="margin-left:6px"></i>'+x[1]+'</button>';}).join('')+
      '</div>';
  }
  function shell(body){
    return '<div style="padding:2px"><div style="display:flex;justify-content:space-between;gap:12px;align-items:flex-start;flex-wrap:wrap;margin-bottom:14px">'+
      '<div><div style="font-size:28px;font-weight:900;color:#111827">إدارة التوصيل والشحن</div>'+
      '<div style="color:#64748b;font-size:13px;font-weight:700;margin-top:4px">مركز التحكم اللوجيستي فوق الرانشيت والأسطول والتوصيل الميداني — بدون إنشاء دورة تشغيل موازية</div></div>'+
      '<div style="display:flex;gap:7px;flex-wrap:wrap">'+
      (canManage()?btn('مندوب جديد','agent-new','px-3 py-2 rounded-xl bg-indigo-600 text-white font-bold'): '')+
      btn('تحديث','refresh','px-3 py-2 rounded-xl bg-slate-100 text-slate-700 font-bold')+
      '</div></div>'+tabs()+body+'</div>';
  }

  async function dashboard(){
    var d=await q('dashboard',{});
    var body='<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:12px;margin-bottom:16px">'+
      stat('خطط اليوم',d.plans_today||0,'fa-calendar-day','info')+
      stat('رحلات نشطة',d.active_plans||0,'fa-truck-fast','ok')+
      stat('رحلات بلا مندوب',d.unassigned_plans||0,'fa-user-slash',d.unassigned_plans?'warn':'ok')+
      stat('نقاط قيد التنفيذ',d.pending_stops||0,'fa-location-dot',d.pending_stops?'warn':'muted')+
      stat('تحصيلات مسجلة',money(d.recorded_collections||0)+' EGP','fa-money-bill-wave','ok')+
      stat('قيمة مفتوحة',money(d.outstanding_order_value||0)+' EGP','fa-file-invoice-dollar','warn')+
      stat('في الموعد',d.on_time_pct==null?'—':money(d.on_time_pct)+'%','fa-clock',d.on_time_pct==null?'muted':(d.on_time_pct>=90?'ok':'warn'))+
      '</div>';
    body+=card('ماذا يربط هذا المركز؟','الرؤية الموحدة','<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(190px,1fr));gap:10px">'+
      ['الأوردر → الرانشيت','الرانشيت → السعة والمركبة','الرحلة → مندوب التوصيل','النقاط → ETA والتسليم','التسليم → POD','التحصيل → أداء مالي','التسليم → تقارير الأداء'].map(function(x){return '<div style="padding:13px;background:#f8fafc;border:1px solid #eef2f7;border-radius:14px;font-weight:900;color:#334155"><i class="fa-solid fa-link" style="color:#2563eb;margin-left:6px"></i>'+x+'</div>';}).join('')+
      '</div>');
    set(shell(body));
  }

  async function planning(){
    var d=await q('planning',{from_date:new Date().toISOString().slice(0,10),to_date:new Date(Date.now()+86400000*7).toISOString().slice(0,10),limit:200,offset:0});
    S.cache.planning=d.rows||[];
    var rows=S.cache.planning.map(function(x){
      var cap=x.vehicle_id?'<span style="font-size:11px;color:#64748b">'+esc(x.vehicle_code||x.vehicle_id)+'</span>':badge('بدون مركبة','warn');
      return '<tr style="border-top:1px solid #eef2f7"><td class="p-3"><b>'+esc(x.runsheet_code)+'</b><div style="font-size:11px;color:#94a3b8">'+date(x.run_date)+'</div></td>'+
        '<td class="p-3">'+esc(x.status)+'</td><td class="p-3">'+esc(x.order_count)+'</td><td class="p-3">'+money(x.loaded_qty||0)+'</td>'+
        '<td class="p-3">'+cap+'</td><td class="p-3">'+(x.has_route_plan?badge('لها خطة','ok'):badge('غير مخططة','warn'))+'</td>'+
        '<td class="p-3"><div style="display:flex;gap:6px;flex-wrap:wrap">'+
        (x.has_route_plan?btn('فتح الخطة','run-open:'+esc(x.runsheet_code),'px-3 py-2 rounded-xl bg-slate-100 text-slate-700 font-bold'):btn('إنشاء خطة','plan-new:'+esc(x.runsheet_code),'px-3 py-2 rounded-xl bg-indigo-600 text-white font-bold'))+
        '<button type="button" onclick="event.stopPropagation();RW_FleetManagement.openRunsheetAssignmentForm(\''+esc(x.runsheet_code)+'\')" class="px-3 py-2 rounded-xl bg-slate-900 text-white font-bold">فحص/إسناد المركبة</button>'+
        '</div></td></tr>';
    }).join('');
    var table='<div style="overflow:auto"><table class="w-full"><thead><tr>'+['الرانشيت','الحالة','الأوردرات','المحمّل','المركبة','الخطة','إدارة'].map(function(h){return '<th class="p-3 text-right">'+h+'</th>';}).join('')+'</tr></thead><tbody>'+
      (rows||'<tr><td colspan="7" class="text-center p-8 text-slate-400">لا توجد رحلات متاحة للتخطيط</td></tr>')+'</tbody></table></div>';
    set(shell(card('لوحة التخطيط','كل رحلة مرشحة للربط بخطة توصيل','<div style="padding:10px 12px;border-radius:14px;background:#eff6ff;color:#1e40af;font-weight:800;margin-bottom:12px">السعة لا تُعاد حسابها هنا. زر فحص/إسناد المركبة يمر إلى Fleet الحالي، حيث الوزن والحجم وحارس الإسناد هما المرجع.</div>'+table)));
  }

  async function openPlanCreate(runsheetCode){
    await modal('إنشاء خطة توصيل — '+runsheetCode,
      input('dl-start','نقطة البداية — Latitude','31.200000','number','step="0.000001"')+
      input('dn-start','نقطة البداية — Longitude','29.900000','number','step="0.000001"')+
      input('dl-speed','السرعة المخططة كم/س','','number','min="1" step="0.1"')+
      input('dl-time','بداية الرحلة','','datetime-local')+
      input('dl-service','زمن خدمة المحطة (دقيقة)','5','number','min="0"')+
      input('dl-endlat','نقطة النهاية — Latitude','','number','step="0.000001"')+
      input('dl-endlon','نقطة النهاية — Longitude','','number','step="0.000001"')+
      textarea('dl-notes','ملاحظات التخطيط',''),
      async function(){
        var speed=n(val('dl-speed')); if(!(speed>0))throw new Error('السرعة المخططة مطلوبة وأكبر من صفر');
        if(!val('dl-start')||!val('dn-start'))throw new Error('إحداثيات البداية مطلوبة');
        var planned=val('dl-time')?new Date(val('dl-time')).toISOString():null;
        var r=await c('ROUTE_PLAN_CREATE',{
          runsheet_code:runsheetCode,optimization_strategy:'GeographicNearest',
          planned_start_at:planned,start_latitude:n(val('dl-start')),start_longitude:n(val('dn-start')),
          end_latitude:val('dl-endlat')?n(val('dl-endlat')):null,end_longitude:val('dl-endlon')?n(val('dl-endlon')):null,
          planned_speed_kmh:speed,default_service_minutes:n(val('dl-service')),notes:val('dl-notes')||null
        },'plan-create:'+runsheetCode);
        closePlanModal(); S.routeId=r.plan_id; S.tab='routes'; await refresh(); toast('تم إنشاء خطة الرحلة','success');
      });
  }

  function closePlanModal(){try{Swal.close();}catch(e){}}

  async function routes(){
    var d=await q('routes',{from_date:new Date(Date.now()-86400000*30).toISOString().slice(0,10),to_date:new Date(Date.now()+86400000*14).toISOString().slice(0,10),limit:200,offset:0});
    S.cache.routes=d.rows||[];
    var rows=S.cache.routes.map(function(x){
      var st=x.status==='Completed'?'ok':x.status==='Cancelled'?'bad':x.status==='InProgress'?'warn':'info';
      return '<tr style="border-top:1px solid #eef2f7"><td class="p-3"><b>'+esc(x.plan_code)+'</b><div style="font-size:11px;color:#94a3b8">'+esc(x.runsheet_code)+'</div></td>'+
        '<td class="p-3">'+badge(x.status,st)+'</td><td class="p-3">'+(x.delivery_agent_name?esc(x.delivery_agent_name):badge('غير مسند','warn'))+'</td>'+
        '<td class="p-3">'+(x.vehicle_code?esc(x.vehicle_code):'—')+'</td><td class="p-3">'+esc(x.stop_count)+'</td>'+
        '<td class="p-3">'+money(x.planned_total_km)+' كم<div style="font-size:11px;color:#94a3b8">'+money(x.planned_duration_minutes)+' د</div></td>'+
        '<td class="p-3">'+money(x.collected_amount||0)+' EGP</td>'+
        '<td class="p-3"><div style="display:flex;gap:6px;flex-wrap:wrap">'+
        btn('فتح','route-open:'+esc(x.id),'px-3 py-2 rounded-xl bg-slate-100 text-slate-700 font-bold')+
        (canManage()?btn('تحسين','route-opt:'+esc(x.id),'px-3 py-2 rounded-xl bg-indigo-600 text-white font-bold'):'')+
        '</div></td></tr>';
    }).join('');
    var table='<div style="overflow:auto"><table class="w-full"><thead><tr>'+['الخطة','الحالة','مندوب التوصيل','المركبة','المحطات','المسافة/الزمن المخطط','التحصيل','إدارة'].map(function(h){return '<th class="p-3 text-right">'+h+'</th>';}).join('')+'</tr></thead><tbody>'+
      (rows||'<tr><td colspan="8" class="text-center p-8 text-slate-400">لا توجد خطط توصيل</td></tr>')+'</tbody></table></div>';
    set(shell(card('الرحلات والمسارات','خطة مقابل تنفيذ ومحصلة مالية',table)));
  }

  async function openRoute(id){
    S.routeId=id;
    var d=await q('route_detail',{plan_id:id});
    var p=d.plan||{},stops=d.stops||[];
    var body='<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:10px;margin-bottom:15px">'+
      stat('الرانشيت',p.runsheet_code||'—','fa-file-invoice','info')+
      stat('المركبة',p.vehicle_code||'—','fa-truck','muted')+
      stat('سائق المركبة',p.driver_user_id?'مرتبط':'غير مرتبط','fa-user-tie','muted')+
      stat('مندوب التوصيل',p.delivery_agent_name||'غير مسند','fa-user-ninja',p.delivery_agent_name?'ok':'warn')+
      stat('المسافة',money(p.planned_total_km||0)+' كم','fa-road','info')+
      stat('ETA',money(p.planned_duration_minutes||0)+' د','fa-clock','info')+
      '</div>';
    var controls=btn('تحسين المسار','route-opt:'+id,'px-3 py-2 rounded-xl bg-indigo-600 text-white font-bold');
    if(canManage()) controls+=btn('إسناد مندوب','route-agent:'+id,'px-3 py-2 rounded-xl bg-slate-900 text-white font-bold');
    controls+=btn('إسناد/تغيير المركبة','fleet-open:'+esc(p.runsheet_code||'') ,'px-3 py-2 rounded-xl bg-slate-100 text-slate-700 font-bold');
    controls+=btn('إنهاء الرحلة','route-status:'+id+':Completed','px-3 py-2 rounded-xl bg-emerald-600 text-white font-bold');
    body+=card(p.plan_code||'تفاصيل الرحلة','المسار، الإثباتات، التحصيل والتنفيذ',controls+
      '<div style="overflow:auto"><table class="w-full"><thead><tr>'+['#','الأوردر','العميل','موعد الوصول المخطط','الوصول الفعلي','الحالة','التسليم','POD','تحصيل','إجراء'].map(function(h){return '<th class="p-3 text-right">'+h+'</th>';}).join('')+'</tr></thead><tbody>'+
      (stops.length?stops.map(function(s){
        var os=s.order_status||'—';
        var outcome=s.status==='Delivered'?'ok':(s.status==='Refused'||s.status==='Returned'?'bad':'warn');
        var ot=s.on_time==null?'—':(s.on_time?badge('في الموعد','ok'):badge('متأخر','bad'));
        return '<tr style="border-top:1px solid #eef2f7"><td class="p-3">'+esc(s.stop_sequence)+'</td><td class="p-3"><b>'+esc(s.order_code)+'</b><div style="font-size:11px;color:#94a3b8">'+esc(os)+'</div></td>'+
          '<td class="p-3">'+esc(s.customer_name||'—')+'</td><td class="p-3">'+dt(s.planned_arrival_at)+'</td><td class="p-3">'+dt(s.actual_arrival_at)+' '+ot+'</td>'+
          '<td class="p-3">'+badge(s.status,outcome)+'</td><td class="p-3">'+money(s.delivered_qty||0)+' / '+money(s.loaded_qty||0)+'</td>'+
          '<td class="p-3">'+(s.pod_method?badge(s.pod_method,'ok'):badge('غير مثبت','warn'))+'</td><td class="p-3">'+money(s.collected_amount||0)+'</td>'+
          '<td class="p-3"><div style="display:flex;gap:5px;flex-wrap:wrap">'+btn('وصل','stop-arrive:'+s.id,'px-2 py-1.5 rounded-lg bg-amber-50 text-amber-700 font-bold')+btn('POD','stop-pod:'+s.id,'px-2 py-1.5 rounded-lg bg-blue-50 text-blue-700 font-bold')+btn('تحصيل','collect:'+s.id,'px-2 py-1.5 rounded-lg bg-emerald-50 text-emerald-700 font-bold')+'</div></td></tr>';
      }).join(''):'<tr><td colspan="10" class="text-center p-8 text-slate-400">لا توجد محطات</td></tr>')+
      '</tbody></table></div>');
    set(shell(body));
  }

  async function agents(){
    var d=await q('agents',{search:S.search,status:'Active',limit:200,offset:0}); S.cache.agents=d.rows||[];
    var rows=S.cache.agents.map(function(a){
      return '<tr style="border-top:1px solid #eef2f7"><td class="p-3"><b>'+esc(a.agent_code)+'</b></td><td class="p-3">'+esc(a.full_name)+'</td>'+
        '<td class="p-3">'+esc(a.phone||'—')+'</td><td class="p-3">'+esc(a.employment_type)+'</td><td class="p-3">'+(a.user_id?badge('حساب ميداني مرتبط','ok'):badge('بدون حساب','warn'))+'</td>'+
        '<td class="p-3">'+esc(a.active_routes)+'</td><td class="p-3">'+esc(a.stops_delivered)+' / '+esc(a.stops_total)+'</td><td class="p-3">'+money(a.collected_amount||0)+' EGP</td></tr>';
    }).join('');
    set(shell(card('مناديب التوصيل','هوية مستقلة عن سائق المركبة',input('dl-agent-search','بحث','','text','style="max-width:340px;margin-bottom:12px"')+
      '<div style="overflow:auto"><table class="w-full"><thead><tr>'+['الكود','الاسم','الهاتف','نوع التعاقد','ربط التطبيق','الرحلات النشطة','التوصيلات','التحصيل'].map(function(h){return '<th class="p-3 text-right">'+h+'</th>';}).join('')+'</tr></thead><tbody>'+(
        rows||'<tr><td colspan="8" class="text-center p-8 text-slate-400">لا يوجد مناديب مسجلون</td></tr>')+'</tbody></table></div>')));
    var s=E('dl-agent-search'); if(s)s.oninput=function(){S.search=this.value;setTimeout(function(){agents().catch(function(e){toast(e.message,'error');})},180)};
  }

  async function openAgentForm(){
    await modal('تسجيل مندوب توصيل',
      input('da-code','كود المندوب','')+
      input('da-name','الاسم الكامل','')+
      input('da-phone','الهاتف','')+
      input('da-email','البريد الإلكتروني','')+
      select('da-emp','نوع التعاقد','Employee',[['Employee','موظف'],['Contractor','متعاقد'],['Outsourced','شركة خارجية'],['PerTrip','بالنقلة'],['Monthly','بالشهر'],['Other','أخرى']])+
      select('da-status','الحالة','Active',[['Active','نشط'],['Inactive','غير نشط'],['Suspended','موقوف']])+
      input('da-user','User UUID — اختياري','','text','placeholder="اربط حسابًا ميدانيًا موجودًا فقط"')+
      input('da-branch','الفرع الافتراضي UUID — اختياري','','text'),
      async function(){
        if(!val('da-code')||!val('da-name'))throw new Error('الكود والاسم مطلوبان');
        await c('AGENT_CREATE',{
          agent_code:val('da-code'),full_name:val('da-name'),phone:val('da-phone')||null,email:val('da-email')||null,
          employment_type:val('da-emp'),status:val('da-status'),user_id:val('da-user')||null,default_branch_id:val('da-branch')||null
        },'agent-create:'+val('da-code'));
        Swal.close();await refresh();toast('تم تسجيل مندوب التوصيل وربطه بهوية مستقلة','success');
      });
  }

  async function collections(){
    var d=await q('collections',{from_date:new Date(Date.now()-86400000*30).toISOString().slice(0,10),to_date:new Date().toISOString().slice(0,10),limit:300,offset:0});
    S.cache.collections=d.rows||[];
    var rows=S.cache.collections.map(function(x){return '<tr style="border-top:1px solid #eef2f7"><td class="p-3"><b>'+esc(x.receipt_code)+'</b></td><td class="p-3">'+dt(x.collected_at)+'</td><td class="p-3">'+esc(x.order_code)+'</td>'+
      '<td class="p-3">'+esc(x.delivery_agent_name)+'</td><td class="p-3">'+money(x.amount)+' EGP</td><td class="p-3">'+esc(x.payment_method)+'</td><td class="p-3">'+badge(x.status,x.status==='Voided'?'bad':'ok')+'</td>'+
      '<td class="p-3">'+(x.status!=='Voided'&&canManage()?btn('إلغاء','collection-void:'+x.id,'px-2 py-1.5 rounded-lg bg-rose-50 text-rose-700 font-bold'):'—')+'</td></tr>';}).join('');
    set(shell(card('التحصيلات','سجل مالي تشغيلي لمندوب التوصيل — لا ينشئ قيدًا محاسبيًا بديلًا', '<div style="overflow:auto"><table class="w-full"><thead><tr>'+['السند','التاريخ','الأوردر','المندوب','المبلغ','طريقة الدفع','الحالة','إدارة'].map(function(h){return '<th class="p-3 text-right">'+h+'</th>';}).join('')+'</tr></thead><tbody>'+(
      rows||'<tr><td colspan="8" class="text-center p-8 text-slate-400">لا توجد تحصيلات</td></tr>')+'</tbody></table></div>')));
  }

  async function performance(){
    var d=await q('performance',{from_date:new Date(Date.now()-86400000*90).toISOString().slice(0,10),to_date:new Date().toISOString().slice(0,10),limit:200,offset:0});
    S.cache.performance=d.rows||[];
    var rows=S.cache.performance.map(function(x){
      return '<tr style="border-top:1px solid #eef2f7"><td class="p-3"><b>'+esc(x.full_name)+'</b><div style="font-size:11px;color:#94a3b8">'+esc(x.agent_code)+'</div></td>'+
        '<td class="p-3">'+esc(x.assigned_stops)+'</td><td class="p-3">'+esc(x.delivered_stops)+'</td><td class="p-3">'+esc(x.partial_stops)+'</td><td class="p-3">'+esc(x.refused_stops)+'</td><td class="p-3">'+esc(x.returned_stops)+'</td>'+
        '<td class="p-3">'+(x.on_time_pct==null?'—':badge(money(x.on_time_pct)+'%','ok'))+'</td><td class="p-3">'+money(x.order_value||0)+' EGP</td><td class="p-3">'+money(x.collected_amount||0)+' EGP</td></tr>';
    }).join('');
    set(shell(card('أداء مناديب التوصيل','90 يومًا — من نفس بيانات الأوردر والرحلة والتحصيل', '<div style="overflow:auto"><table class="w-full"><thead><tr>'+['المندوب','المحطات','تم التسليم','جزئي','مرفوض','مرتجع','في الموعد','قيمة الأوردرات','التحصيل'].map(function(h){return '<th class="p-3 text-right">'+h+'</th>';}).join('')+'</tr></thead><tbody>'+(
      rows||'<tr><td colspan="9" class="text-center p-8 text-slate-400">لا توجد بيانات أداء</td></tr>')+'</tbody></table></div>')));
  }

  async function refresh(){
    if(S.busy)return;
    S.busy=true;
    try{
      if(S.tab==='dashboard')await dashboard();
      else if(S.tab==='planning')await planning();
      else if(S.tab==='routes')await routes();
      else if(S.tab==='agents')await agents();
      else if(S.tab==='collections')await collections();
      else if(S.tab==='performance')await performance();
    }catch(e){
      set(shell('<div class="rw-card" style="padding:40px;text-align:center;color:#b91c1c;font-weight:900">تعذر تحميل مركز التوصيل واللوجستيات<div style="font-size:12px;color:#64748b;margin-top:8px">'+esc(e.message)+'</div>'+btn('إعادة المحاولة','refresh','px-3 py-2 rounded-xl bg-slate-900 text-white font-bold')+'</div>'));
    }finally{S.busy=false;}
  }

  async function stopArrive(id){
    await c('STOP_ARRIVE',{stop_id:id},'stop-arrive:'+id); await openRoute(S.routeId); toast('تم تسجيل الوصول الفعلي','success');
  }
  async function stopPod(id){
    await modal('إثبات التسليم',
      input('pod-recipient','اسم المستلم','')+
      select('pod-method','طريقة الإثبات','OTP',[['OTP','OTP'],['Signature','توقيع'],['Photo','صورة'],['Reference','مرجع'],['None','بدون']])+
      select('pod-outcome','نتيجة التسليم','Delivered',[['Delivered','تم التسليم'],['Partial','تسليم جزئي'],['Refused','مرفوض'],['Returned','مرتجع']])+
      input('pod-ref','مرجع الإثبات','')+
      input('pod-lat','Latitude','','number','step="0.000001"')+
      input('pod-lon','Longitude','','number','step="0.000001"')+
      textarea('pod-note','ملاحظات',''),
      async function(){
        await c('STOP_POD',{
          stop_id:id,pod_method:val('pod-method'),delivery_result:val('pod-outcome'),
          recipient_name:val('pod-recipient')||null,pod_reference:val('pod-ref')||null,
          latitude:val('pod-lat')?n(val('pod-lat')):null,longitude:val('pod-lon')?n(val('pod-lon')):null,pod_note:val('pod-note')||null
        },'stop-pod:'+id);Swal.close();await openRoute(S.routeId);toast('تم تسجيل إثبات التسليم','success');
      });
  }
  async function collect(id){
    await modal('تسجيل تحصيل',
      input('col-amount','المبلغ','0','number','min="0.01" step="0.01"')+
      select('col-method','طريقة الدفع','Cash',[['Cash','نقدي'],['Transfer','تحويل'],['Other','أخرى']])+
      input('col-ref','مرجع العملية','')+
      textarea('col-notes','ملاحظات',''),
      async function(){
        var amount=n(val('col-amount'));if(!(amount>0))throw new Error('المبلغ يجب أن يكون أكبر من صفر');
        await c('COLLECTION_RECORD',{stop_id:id,amount:amount,payment_method:val('col-method'),reference:val('col-ref')||null,notes:val('col-notes')||null},'collect:'+id);
        Swal.close();await openRoute(S.routeId);toast('تم تسجيل التحصيل','success');
      });
  }
  async function assignAgent(planId){
    var d=await q('agents',{status:'Active',limit:200,offset:0}),agents=d.rows||[];
    if(!agents.length)throw new Error('لا يوجد مندوبي توصيل نشطون. أنشئ مندوبًا أولًا.');
    await modal('إسناد مندوب للرحلة',select('ra-agent','مندوب التوصيل',agents[0].id,agents.map(function(a){return[a.id,a.agent_code+' — '+a.full_name]})),
      async function(){await c('ROUTE_AGENT_ASSIGN',{plan_id:planId,delivery_agent_id:val('ra-agent')},'route-agent:'+planId);Swal.close();await openRoute(planId);toast('تم ربط مندوب التوصيل بالرحلة','success');});
  }
  async function routeStatus(id,status){
    await c('ROUTE_STATUS',{plan_id:id,status:status},'route-status:'+id+':'+status);await openRoute(id);toast('تم تحديث حالة الخطة','success');
  }

  async function handle(action){
    var p=String(action||'').split(':'),k=p.shift(),id=p.join(':');
    try{
      if(k==='refresh'){return refresh();}
      if(k==='agent-new'){return openAgentForm();}
      if(k==='plan-new'){return openPlanCreate(id);}
      if(k==='route-open'){return openRoute(id);}
      if(k==='route-opt'){
        var r=await c('ROUTE_OPTIMIZE',{plan_id:id},'route-opt:'+id);
        if(r.status==='INCOMPLETE_DATA'){toast(r.msg||'بيانات التخطيط ناقصة','error');return openRoute(id);}
        toast('تم تحسين المسار جغرافيًا','success');return openRoute(id);
      }
      if(k==='route-agent'){return assignAgent(id);}
      if(k==='stop-arrive'){return stopArrive(id);}
      if(k==='stop-pod'){return stopPod(id);}
      if(k==='collect'){return collect(id);}
      if(k==='collection-void'){await c('COLLECTION_VOID',{receipt_id:id},'collection-void:'+id);return refresh();}
      if(k==='route-status'){var rsParts=id.split(':');var rsId=rsParts.shift();var rsStatus=rsParts.join(':')||'Completed';return routeStatus(rsId,rsStatus);}
      if(k==='fleet-open'){if(window.RW_FleetManagement&&typeof RW_FleetManagement.openRunsheetAssignmentForm==='function')return RW_FleetManagement.openRunsheetAssignmentForm(id);return toast('وحدة Fleet غير متاحة','error');}
      if(k==='run-open'){
        var rs=dummyFind(S.cache.routes,id);if(rs)return openRoute(rs.id);
        var x=await q('routes',{from_date:'2000-01-01',to_date:'2100-01-01',limit:500,offset:0});
        var row=(x.rows||[]).find(function(z){return z.runsheet_code===id});if(row)return openRoute(row.id);
        throw new Error('خطة الرحلة غير موجودة');
      }
      throw new Error('إجراء Delivery غير معروف: '+action);
    }catch(e){toast(e.message||'فشل التنفيذ','error');}
  }
  function dummyFind(rows,key){return (rows||[]).find(function(x){return x.id===key||x.plan_code===key||x.runsheet_code===key;});}

  async function render(){
    if(!canRead()){set('<div class="rw-card" style="padding:60px;text-align:center"><div style="font-size:55px">🔒</div><h2 style="font-weight:900">غير مصرح</h2><p style="color:#64748b">لا تملك صلاحية مركز التوصيل واللوجستيات</p></div>');return;}
    await refresh();
  }

  var api={render:render,refresh:refresh,handle:handle,openRoute:openRoute};
  window.RW_DeliveryLogistics=api;

  var root=document;
  root.addEventListener('click',function(e){
    var tab=e.target.closest&&e.target.closest('[data-dlm-tab]');
    if(tab){S.tab=tab.getAttribute('data-dlm-tab');S.routeId=null;refresh();return;}
    var act=e.target.closest&&e.target.closest('[data-dlm-action]');
    if(act){e.preventDefault();handle(act.getAttribute('data-dlm-action'));return;}
  },true);

  // The field delivery apps remain authoritative for field execution; this module is supervisory/control-plane only.
  window.RW_DeliveryLogistics=api;
})();