// RAWAEA ERP — RW_FleetManagement
// Parent PWA surgical module; does not touch main.html.
// All writes -> fleet_command_atomic
// All reads  -> fleet_query
(function () {
  'use strict';

  var state = {
    tab: 'dashboard',
    search: '',
    selectedVehicleId: null,
    selectedDriverId: null,
    cache: {}
  };

  function esc(v) {
    return String(v == null ? '' : v)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function n(v) {
    var x = Number(v);
    return Number.isFinite(x) ? x : 0;
  }

  function money(v) {
    return n(v).toLocaleString('ar-EG', { maximumFractionDigits: 2 });
  }

  function date(v) {
    if (!v) return '—';
    try { return new Date(v).toLocaleDateString('ar-EG'); } catch (e) { return String(v); }
  }

  function companyId() {
    return (window.RW_STATE && RW_STATE.app && (
      RW_STATE.app.companyId ||
      (RW_STATE.app.company && RW_STATE.app.company.id)
    )) || null;
  }

  function currentUser() {
    return (window.RW_STATE && RW_STATE.app && RW_STATE.app.currentUser) || null;
  }

  function op(prefix) {
    var r = Math.random().toString(36).slice(2, 10);
    return 'FLEET-UI-' + prefix + '-' + Date.now() + '-' + r;
  }

  function canManage() {
    var u = currentUser();
    if (!u) return false;
    if (u.isOwner === true) return true;
    var p = Array.isArray(RW_STATE.permissions) ? RW_STATE.permissions : [];
    return p.indexOf('*') !== -1 ||
      p.indexOf('fleet.manage') !== -1 ||
      p.indexOf('general_manager') !== -1 ||
      p.indexOf('warehouse_manager') !== -1 ||
      u.role === 'مدير عام' ||
      u.role === 'مدير مخازن';
  }

  function canRead() {
    var u = currentUser();
    if (!u) return false;
    if (u.isOwner === true) return true;
    var p = Array.isArray(RW_STATE.permissions) ? RW_STATE.permissions : [];
    return p.indexOf('*') !== -1 ||
      p.indexOf('fleet.manage') !== -1 ||
      p.indexOf('fleet.read') !== -1 ||
      p.indexOf('reports') !== -1 ||
      p.indexOf('general_manager') !== -1 ||
      p.indexOf('warehouse_manager') !== -1 ||
      p.indexOf('delivery_supervisor') !== -1 ||
      p.indexOf('finance_manager') !== -1 ||
      u.role === 'مدير عام' ||
      u.role === 'مدير مخازن' ||
      u.role === 'مشرف توصيل' ||
      u.role === 'مدير مالي';
  }

  async function query(view, payload) {
    var c = companyId();
    if (!c) throw new Error('سياق الشركة غير محدد');
    var u = currentUser() || {};
    var res = await supabase.rpc('fleet_query', {
      p_company_id: c,
      p_view: view,
      p_payload: payload || {},
      p_actor_user_id: null
    });
    if (res.error) throw new Error(res.error.message);
    if (!res.data || res.data.success === false) throw new Error((res.data && (res.data.msg || res.data.message)) || 'فشل قراءة Fleet');
    return res.data;
  }

  async function command(commandName, payload) {
    if (!canManage()) throw new Error('ليس لديك صلاحية تنفيذ عمليات Fleet');
    var c = companyId();
    if (!c) throw new Error('سياق الشركة غير محدد');
    var u = currentUser() || {};
    var res = await supabase.rpc('fleet_command_atomic', {
      p_company_id: c,
      p_command: commandName,
      p_payload: payload || {},
      p_operation_id: op(commandName),
      p_actor_user_id: null,
      p_actor_email: u.email || null
    });
    if (res.error) throw new Error(res.error.message);
    if (!res.data || res.data.success === false) throw new Error((res.data && (res.data.msg || res.data.message)) || 'فشل تنفيذ Fleet');
    return res.data;
  }

  function card(title, value, icon, hint) {
    return '<div class="rw-kpi-card">' +
      '<div style="display:flex;justify-content:space-between;gap:16px;align-items:flex-start">' +
      '<div><div style="font-size:13px;color:#64748b;font-weight:800">' + esc(title) + '</div>' +
      '<div style="font-size:30px;font-weight:900;color:#0f172a;margin-top:8px">' + esc(value) + '</div>' +
      (hint ? '<div style="font-size:11px;color:#94a3b8;margin-top:5px;font-weight:700">' + esc(hint) + '</div>' : '') +
      '</div><div style="width:48px;height:48px;border-radius:16px;background:#eff6ff;color:#2563eb;display:flex;align-items:center;justify-content:center;font-size:19px"><i class="fa-solid ' + esc(icon) + '"></i></div>' +
      '</div></div>';
  }

  function tabs() {
    var items = [
      ['dashboard','لوحة الأسطول','fa-gauge-high'],
      ['vehicles','المركبات','fa-truck'],
      ['drivers','السائقون','fa-id-badge'],
      ['trips','الرحلات والعداد','fa-route'],
      ['alerts','التنبيهات','fa-bell'],
      ['costs','التكاليف','fa-coins'],
      ['performance','أداء السائقين','fa-chart-line']
    ];
    return '<div style="display:flex;gap:8px;flex-wrap:wrap;background:white;padding:10px;border:1px solid #e5e7eb;border-radius:20px;margin-bottom:18px">' +
      items.map(function (x) {
        return '<button onclick="RW_FleetManagement.switchTab(\'' + x[0] + '\')" style="border:0;border-radius:14px;padding:10px 15px;font-weight:800;cursor:pointer;background:' +
          (state.tab === x[0] ? '#eff6ff' : '#f8fafc') + ';color:' + (state.tab === x[0] ? '#2563eb' : '#475569') + '">' +
          '<i class="fa-solid ' + x[2] + '" style="margin-left:7px"></i>' + x[1] + '</button>';
      }).join('') + '</div>';
  }

  function shell(title, body) {
    return '<div style="padding:2px">' +
      '<div style="display:flex;justify-content:space-between;align-items:flex-start;gap:15px;flex-wrap:wrap;margin-bottom:18px">' +
      '<div><div style="font-size:28px;font-weight:900;color:#111827">' + esc(title) + '</div>' +
      '<div style="color:#64748b;font-size:13px;font-weight:700;margin-top:5px">المركبات، السائقون، الحركة، الصيانة، الوقود والتكلفة — فوق نفس دورة التشغيل الحالية</div></div>' +
      '<div style="display:flex;gap:8px;flex-wrap:wrap">' +
      (canManage() ? '<button onclick="RW_FleetManagement.openVehicleForm()" class="rw-login-btn" style="width:auto;height:46px;padding:0 18px;margin:0;border-radius:14px;font-size:13px;box-shadow:none"><i class="fa-solid fa-plus"></i> مركبة</button>' : '') +
      (canManage() ? '<button onclick="RW_FleetManagement.openDriverForm()" class="rw-login-btn" style="width:auto;height:46px;padding:0 18px;margin:0;border-radius:14px;font-size:13px;box-shadow:none"><i class="fa-solid fa-user-plus"></i> سائق</button>' : '') +
      '</div></div>' + tabs() + body + '</div>';
  }

  function set(html) {
    var c = byId('rw-page-container');
    if (c) safeHTML(c, html);
  }

  async function loadDashboard() {
    var d = await query('dashboard', {});
    var html = '<div class="rw-kpi-grid">' +
      card('إجمالي المركبات', d.vehicles, 'fa-truck') +
      card('المركبات النشطة', d.active_vehicles, 'fa-circle-check') +
      card('صيانة مستحقة / قريبة', d.maintenance_due, 'fa-screwdriver-wrench') +
      card('مستندات تنتهي خلال 30 يوم', d.documents_expiring_30d, 'fa-file-circle-exclamation') +
      '</div>' +
      '<div class="rw-kpi-grid">' +
      card('تكلفة الوقود — 30 يوم', money(d.fuel_cost_30d), 'fa-gas-pump', 'بالعملة التشغيلية') +
      card('كمية الوقود — 30 يوم', money(d.fuel_liters_30d) + ' لتر', 'fa-droplet') +
      card('المسافة من الرانشيتات — 30 يوم', money(d.distance_km_30d) + ' كم', 'fa-road') +
      card('متوسط الاستهلاك', d.trip_fuel_efficiency == null ? '—' : money(d.trip_fuel_efficiency) + ' لتر/100كم', 'fa-chart-simple') +
      '</div>' +
      '<div class="rw-card" style="padding:22px">' +
      '<div style="font-weight:900;color:#111827;font-size:17px">محاور الرقابة</div>' +
      '<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(210px,1fr));gap:12px;margin-top:15px">' +
      ['هوية المركبة ↔ الرانشيت','السائق ↔ المركبة','العداد ↔ الصيانة','الوقود ↔ الرحلة','المصروف ↔ المركبة','الحادث ↔ أداء السائق'].map(function (x) {
        return '<div style="padding:16px;border-radius:16px;background:#f8fafc;border:1px solid #e5e7eb;font-weight:800;color:#334155"><i class="fa-solid fa-link" style="color:#2563eb;margin-left:8px"></i>' + x + '</div>';
      }).join('') + '</div></div>';
    set(shell('إدارة الأسطول والحركة', html));
  }

  async function loadVehicles() {
    var d=await query('vehicles',{search:state.search,limit:100,offset:0});state.cache.vehicles=d.rows||[];var rows=state.cache.vehicles;
    var html='<div class="rw-card" style="padding:18px"><div style="display:flex;gap:10px;flex-wrap:wrap;margin-bottom:15px"><input id="fleet-vehicle-search" value="'+esc(state.search)+'" onkeydown="if(event.key===\'Enter\'){RW_FleetManagement.setSearch(this.value)}" placeholder="كود المركبة / اللوحة / الموديل" class="rw-input" style="height:48px;max-width:420px;padding-right:15px"></div><div style="overflow:auto"><table class="w-full"><thead><tr>'+
      ['المركبة','اللوحة','السعة طن','حجم الصندوق م³','الكفاءة','الحالة/المسار','الملكية','السائق'].map(function(x){return '<th class="p-3 text-right">'+x+'</th>';}).join('')+
      '</tr></thead><tbody>';
    if(!rows.length) html+='<tr><td colspan="8" class="text-center p-8 text-slate-400">لا توجد مركبات مسجلة</td></tr>';
    rows.forEach(function(v){
      html+='<tr style="border-top:1px solid #eef2f7;cursor:pointer" onclick="RW_FleetManagement.openVehicleDetail(\''+v.id+'\')">'+
        '<td class="p-3"><strong>'+esc(v.vehicle_code)+'</strong><div class="text-xs text-slate-400">'+esc(v.model||'')+'</div></td><td class="p-3">'+esc(v.license_plate)+'</td>'+
        '<td class="p-3">'+(v.max_weight_kg==null?'—':money(Number(v.max_weight_kg)/1000))+'</td><td class="p-3">'+(v.max_volume_m3==null?'—':money(v.max_volume_m3))+'</td>'+
        '<td class="p-3">'+(v.expected_km_per_liter==null?'—':money(v.expected_km_per_liter)+' كم/ل')+'</td>'+
        '<td class="p-3"><strong>'+esc(v.operational_condition||'—')+'</strong><div class="text-xs text-slate-400">'+esc(v.route_capability||'—')+'</div></td>'+
        '<td class="p-3">'+esc(v.ownership_type||'—')+'</td><td class="p-3">'+esc(v.fleet_driver_id||v.driver_id||'—')+'</td></tr>';
    });
    html+='</tbody></table></div></div>';set(shell('المركبات',html));
  }

async function loadDrivers() {
    var d = await query('drivers', {search: state.search, limit: 100, offset: 0});
    state.cache.drivers = d.rows || [];
    var html = '<div class="rw-card" style="padding:18px"><div style="overflow:auto"><table class="w-full"><thead><tr>' +
      ['الكود','السائق','الهاتف','الحالة','صلاحية الرخصة','أحداث جسيمة','نقاط الأداء 90 يوم','مركبات نشطة'].map(function(x){return '<th class="p-3 text-right">'+x+'</th>';}).join('') +
      '</tr></thead><tbody>';
    if (!state.cache.drivers.length) html += '<tr><td colspan="8" class="text-center p-8 text-slate-400">لا توجد ملفات سائقين</td></tr>';
    state.cache.drivers.forEach(function(d){
      html += '<tr style="border-top:1px solid #eef2f7;cursor:pointer" onclick="RW_FleetManagement.openDriverDetail(\''+d.id+'\')">' +
        '<td class="p-3">'+esc(d.driver_code)+'</td><td class="p-3"><strong>'+esc(d.full_name)+'</strong></td><td class="p-3">'+esc(d.phone||'—')+'</td>' +
        '<td class="p-3">'+esc(d.status)+'</td><td class="p-3">'+date(d.license_expiry)+'</td><td class="p-3">'+d.serious_events+'</td><td class="p-3">'+d.performance_points+'</td><td class="p-3">'+d.active_vehicle_count+'</td></tr>';
    });
    html += '</tbody></table></div></div>';
    set(shell('السائقون', html));
  }

  async function loadTrips() {
    var d=await query('trips',{limit:100,offset:0}),rows=d.rows||[];
    var html='<div class="rw-card" style="padding:18px"><div style="overflow:auto"><table class="w-full"><thead><tr>'+
      ['الرانشيت','التاريخ','المركبة','العداد بداية/نهاية','المسافة','الوقود','لتر/100كم','قيمة المبيعات','إدارة'].map(function(x){return '<th class="p-3 text-right">'+x+'</th>';}).join('')+
      '</tr></thead><tbody>';
    if(!rows.length) html+='<tr><td colspan="9" class="text-center p-8 text-slate-400">لا توجد رحلات مؤرخة مرتبطة بمركبات</td></tr>';
    rows.forEach(function(r){
      html+='<tr style="border-top:1px solid #eef2f7"><td class="p-3">'+esc(r.runsheet_code)+'</td><td class="p-3">'+date(r.run_date)+'</td><td class="p-3">'+esc(r.vehicle_code||r.vehicle_id||'—')+'</td>'+
        '<td class="p-3">'+money(r.meter_start)+' / '+money(r.meter_end)+'</td><td class="p-3">'+money(r.distance_km||0)+' كم</td><td class="p-3">'+money(r.fuel_liters||0)+' لتر</td><td class="p-3">'+(r.liters_per_100km==null?'—':money(r.liters_per_100km))+'</td><td class="p-3">'+money(r.sales_value||0)+'</td>'+
        '<td class="p-3"><button onclick="event.stopPropagation();RW_FleetManagement.openRunsheetAssignmentForm(\''+r.runsheet_code+'\')" class="px-3 py-2 rounded-xl bg-slate-900 text-white font-bold">إسناد</button></td></tr>';
    });
    html+='</tbody></table></div></div>';set(shell('الرحلات والعداد',html));
  }

  async function openRunsheetAssignmentForm(runsheetCode){
    if(!runsheetCode) return;
    var p=await query('vehicle_planning',{runsheet_code:runsheetCode}),candidates=p.candidates||[];
    if(!candidates.length) throw new Error('لا توجد مركبات مسجلة للتخطيط');
    var dr=state.cache.drivers||[];if(!dr.length){var x=await query('drivers',{limit:100,offset:0});dr=x.rows||[];}
    var vopts=candidates.map(function(v){return [v.id,(v.vehicle_code||'')+' — '+(v.model||'')+' | '+(v.planning_status||'')+' | وزن '+(v.weight_utilization_pct==null?'—':money(v.weight_utilization_pct)+'%')+' | حجم '+(v.volume_utilization_pct==null?'—':money(v.volume_utilization_pct)+'%')+(v.planning_warning?' | '+v.planning_warning:'')];});
    var dopts=dr.filter(function(x){return x.user_id;}).map(function(x){return [x.user_id,x.driver_code+' — '+x.full_name+' | '+(x.employment_type||'')];});
    await modal('إسناد الرانشيت '+runsheetCode,
      '<div style="text-align:right"><div style="padding:12px 14px;background:#f8fafc;border-radius:14px;margin-bottom:12px;font-weight:900">الحمل الوزني: '+money(p.load?.weight_kg||0)+' كجم — الحجم: '+money(p.load?.volume_m3||0)+' م³</div>'+
      selectInput('fa-vehicle','المركبة',p.runsheet?.vehicle_id||'',vopts)+selectInput('fa-driver','السائق التشغيلي',p.runsheet?.driver_id||'',dopts)+
      '<div style="margin-top:10px;font-size:12px;color:#64748b">يُمنع الإسناد عند تجاوز السعة الوزنية أو حجم الصندوق. البيانات الناقصة تظهر كـ INCOMPLETE_DATA.</div></div>',
      async function(){
        if(!val('fa-vehicle')) throw new Error('المركبة مطلوبة');
        var chosen=candidates.find(function(x){return String(x.id)===String(val('fa-vehicle'));});
        if(chosen&&chosen.planning_status==='BLOCKED') throw new Error('المركبة المختارة غير مناسبة للحمولة الحالية');
        var chosenDriver=dr.find(function(x){return String(x.user_id)===String(val('fa-driver'));})||{};
        await command('RUNSHEET_ASSIGN',{runsheet_id:p.runsheet.id,vehicle_id:val('fa-vehicle'),driver_user_id:val('fa-driver')||null,fleet_driver_id:chosenDriver.id||null});
        await refresh();showToast('تم إسناد الرانشيت للمركبة والسائق','success');
      });
  }

async function loadAlerts() {
    var d = await query('alerts', {});
    function block(title, rows, key) {
      var h = '<div class="rw-card" style="padding:18px"><div style="font-weight:900;font-size:17px">'+title+'</div><div style="margin-top:12px">';
      if (!rows || !rows.length) h += '<div class="text-slate-400 text-sm">لا توجد تنبيهات</div>';
      (rows||[]).forEach(function(x){
        h += '<div style="padding:12px;border:1px solid #fee2e2;background:#fff7f7;border-radius:14px;margin-bottom:8px"><strong>'+esc(x[key]||x.name||x.contract_number||x.document_type||'تنبيه')+'</strong> <span style="color:#64748b;font-size:11px;margin-right:8px">'+esc(date(x.expiry_date||x.end_date||x.next_service_date))+'</span></div>';
      });
      return h+'</div></div>';
    }
    var html = block('مستندات المركبات', d.vehicle_documents, 'document_type') +
      block('رخص السائقين', d.driver_documents, 'document_type') +
      block('العقود', d.contracts, 'contract_number') +
      block('الصيانة', d.maintenance, 'name');
    set(shell('التنبيهات', html));
  }

  async function loadCosts() {
    var d = await query('costs', {});
    var rows = d.rows || [];
    var html = '<div class="rw-card" style="padding:18px"><div style="overflow:auto"><table class="w-full"><thead><tr>' +
      ['المركبة','وقود','صيانة','مصروفات أخرى','عقود','الإجمالي'].map(function(x){return '<th class="p-3 text-right">'+x+'</th>';}).join('') +
      '</tr></thead><tbody>';
    if (!rows.length) html += '<tr><td colspan="6" class="text-center p-8 text-slate-400">لا توجد تكاليف مسجلة</td></tr>';
    rows.forEach(function(r){
      var total=n(r.fuel_cost)+n(r.maintenance_cost)+n(r.other_cost)+n(r.contract_cost);
      html += '<tr style="border-top:1px solid #eef2f7"><td class="p-3"><strong>'+esc(r.vehicle_code)+'</strong><div class="text-xs text-slate-400">'+esc(r.license_plate||'')+'</div></td>' +
        '<td class="p-3">'+money(r.fuel_cost)+'</td><td class="p-3">'+money(r.maintenance_cost)+'</td><td class="p-3">'+money(r.other_cost)+'</td><td class="p-3">'+money(r.contract_cost)+'</td><td class="p-3 font-black">'+money(total)+'</td></tr>';
    });
    html += '</tbody></table></div></div>';
    set(shell('التكاليف', html));
  }

  async function loadPerformance() {
    var d = await query('performance', {limit:100,offset:0});
    var rows=d.rows||[];
    var html='<div class="rw-card" style="padding:18px"><div style="overflow:auto"><table class="w-full"><thead><tr>' +
      ['التاريخ','السائق','الفئة','الخطورة','النقاط','السبب','الحالة'].map(function(x){return '<th class="p-3 text-right">'+x+'</th>';}).join('') +
      '</tr></thead><tbody>';
    if(!rows.length) html+='<tr><td colspan="7" class="text-center p-8 text-slate-400">لا توجد أحداث أداء</td></tr>';
    rows.forEach(function(r){
      html+='<tr style="border-top:1px solid #eef2f7"><td class="p-3">'+date(r.event_date)+'</td><td class="p-3">'+esc(r.fleet_driver_id||r.driver_user_id||'—')+'</td><td class="p-3">'+esc(r.category)+'</td><td class="p-3">'+esc(r.severity)+'</td><td class="p-3">'+r.points+'</td><td class="p-3">'+esc(r.description)+'</td><td class="p-3">'+esc(r.status)+'</td></tr>';
    });
    html+='</tbody></table></div></div>';
    set(shell('أداء السائقين',html));
  }

  async function openVehicleDetail(id) {
    state.selectedVehicleId=id;
    var d=await query('vehicle_detail',{vehicle_id:id});
    var v=d.vehicle||{};
    var driver=d.driver||{};
    var html='<div class="rw-card" style="padding:20px">'+
      '<div style="display:flex;justify-content:space-between;gap:15px;flex-wrap:wrap"><div><div style="font-size:25px;font-weight:900">'+esc(v.vehicle_code)+'</div><div style="color:#64748b;font-weight:700">'+esc(v.model)+' • '+esc(v.license_plate)+'</div></div>'+
      '<div style="display:flex;gap:7px;flex-wrap:wrap">'+
      (canManage()? '<button onclick="RW_FleetManagement.openOdometerForm()" class="px-3 py-2 rounded-xl bg-slate-100 font-bold">عداد</button><button onclick="RW_FleetManagement.openFuelForm()" class="px-3 py-2 rounded-xl bg-slate-100 font-bold">وقود</button><button onclick="RW_FleetManagement.openMaintenanceForm()" class="px-3 py-2 rounded-xl bg-slate-100 font-bold">صيانة</button><button onclick="RW_FleetManagement.openContractForm()" class="px-3 py-2 rounded-xl bg-slate-100 font-bold">عقد</button><button onclick="RW_FleetManagement.openVehicleDocumentForm()" class="px-3 py-2 rounded-xl bg-slate-100 font-bold">مستند</button><button onclick="RW_FleetManagement.openIncidentForm()" class="px-3 py-2 rounded-xl bg-slate-100 font-bold">حادث</button><button onclick="RW_FleetManagement.openExpenseForm()" class="px-3 py-2 rounded-xl bg-slate-100 font-bold">مصروف</button>' : '')+
      '</div></div>'+
      '<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(170px,1fr));gap:12px;margin-top:20px">'+
      card('الحالة',v.status||'—','fa-circle')+card('آخر عداد',money(v.last_odometer_km)+' كم','fa-gauge-high')+card('السائق',driver.full_name||v.fleet_driver_id||v.driver_id||'—','fa-user')+card('نوع الملكية',v.ownership_type||'—','fa-file-contract')+
      '</div>'+
      '<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(290px,1fr));gap:14px;margin-top:18px">'+
      listBlock('المستندات',d.documents,'document_type','expiry_date')+
      listBlock('العقود',d.contracts,'contract_number','end_date')+
      listBlock('الصيانة',d.maintenance,'description','service_date')+
      listBlock('الوقود',d.fuel,'station_name','transaction_date')+
      listBlock('الحوادث',d.incidents,'incident_type','occurred_at')+
      listBlock('الرحلات',d.runsheets,'runsheet_code','run_date')+
      '</div>'+
      '<div style="display:flex;gap:8px;flex-wrap:wrap;margin-top:18px"><button onclick="RW_FleetManagement.navigateExisting(\'vehicle-count\')" class="px-4 py-2 rounded-xl bg-slate-900 text-white font-bold">جرد السيارة</button><button onclick="RW_FleetManagement.navigateExisting(\'runsheets\')" class="px-4 py-2 rounded-xl bg-slate-100 font-bold">الرانشيتات</button></div></div>';
    set(shell('تفاصيل المركبة',html));
  }

  function listBlock(title, rows, labelKey, dateKey) {
    var h='<div class="rw-card" style="padding:16px"><div style="font-weight:900">'+title+'</div><div style="margin-top:10px">';
    if(!rows||!rows.length) return h+'<div class="text-sm text-slate-400">لا توجد سجلات</div></div></div>';
    rows.slice(0,8).forEach(function(x){h+='<div style="padding:10px;border-bottom:1px solid #eef2f7"><div style="font-weight:800">'+esc(x[labelKey]||'—')+'</div><div style="font-size:11px;color:#94a3b8">'+esc(date(x[dateKey]))+'</div></div>';});
    return h+'</div></div>';
  }

  async function openDriverDetail(id) {
    state.selectedDriverId=id;
    var d=await query('driver_detail',{driver_id:id});
    var x=d.driver||{};
    var html='<div class="rw-card" style="padding:20px"><div style="display:flex;justify-content:space-between;gap:10px;flex-wrap:wrap"><div><div style="font-size:25px;font-weight:900">'+esc(x.full_name)+'</div><div style="color:#64748b;font-weight:700">'+esc(x.driver_code)+'</div></div><div>'+
      (canManage()?'<button onclick="RW_FleetManagement.openDriverDocumentForm()" class="px-3 py-2 rounded-xl bg-slate-100 font-bold">رخصة / مستند</button><button onclick="RW_FleetManagement.openPerformanceForm()" class="px-3 py-2 rounded-xl bg-slate-100 font-bold" style="margin-right:6px">حدث أداء</button>':'')+
      '</div></div>'+
      '<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(190px,1fr));gap:12px;margin-top:18px">'+
      card('الحالة',x.status||'—','fa-user-check')+card('صلاحية الرخصة',date((d.documents||[])[0]&&d.documents[0].expiry_date),'fa-id-card')+card('نقاط الأداء',money((d.performance||[]).reduce(function(a,z){return a+n(z.points)},0)),'fa-chart-line')+card('مسؤوليات/التزامات',String((d.liabilities||[]).length),'fa-scale-balanced')+
      '</div>'+
      listBlock('مستندات السائق',d.documents,'document_type','expiry_date')+
      listBlock('سجل الأداء',d.performance,'category','event_date')+
      listBlock('الحوادث',d.incidents,'incident_type','occurred_at')+
      '</div>';
    set(shell('ملف السائق',html));
  }

  function input(id,label,value,type) {
    return '<div><label class="font-bold text-sm text-slate-700">'+label+'</label><input id="'+id+'" type="'+(type||'text')+'" value="'+esc(value||'')+'" class="rw-input" style="height:46px;padding-right:14px;margin-top:6px"></div>';
  }

  function val(id){ var x=byId(id); return x ? String(x.value||'').trim() : ''; }
  function selectInput(id,label,value,options){var h='<div><label class="font-bold text-sm text-slate-700">'+label+'</label><select id="'+id+'" class="rw-input" style="height:46px;padding-right:14px;margin-top:6px">';(options||[]).forEach(function(o){h+='<option value="'+esc(o[0])+'"'+(String(o[0])===String(value||'')?' selected':'')+'>'+esc(o[1])+'</option>';});return h+'</select></div>'; }\n

  async function modal(title, html, onSave, saveText) {
    if (!window.Swal) return showToast('واجهة النوافذ المنبثقة غير متاحة','error');
    var r=await Swal.fire({
      title:title,html:html,showCancelButton:true,confirmButtonText:saveText||'حفظ',cancelButtonText:'إلغاء',
      focusConfirm:false,allowOutsideClick:false,
      preConfirm:async function(){try{return await onSave();}catch(e){Swal.showValidationMessage(e.message||'فشل الحفظ');return false;}}
    });
    return r;
  }

  async function openVehicleForm(){
    await modal('إضافة مركبة',
      '<div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;text-align:right">'+
      input('fv-code','كود المركبة','')+input('fv-model','الموديل','')+input('fv-plate','رقم اللوحة','')+
      input('fv-type','نوع المركبة','Delivery')+input('fv-mode','نمط التشغيل','Mixed')+
      selectInput('fv-owner','الملكية','Owned',[['Owned','مملوكة للشركة'],['RentedPerTrip','مستأجرة بالنقلة'],['RentedMonthly','مستأجرة بالشهر'],['Other','أخرى']])+
      input('fv-weight-ton','السعة الوزنية (طن)','5','number')+
      input('fv-l','طول صندوق المركبة (م)','','number')+input('fv-w','عرض صندوق المركبة (م)','','number')+input('fv-h','ارتفاع صندوق المركبة (م)','','number')+
      selectInput('fv-condition','حالة وكفاءة المركبة','Good',[['Excellent','ممتازة'],['Good','جيدة'],['Fair','متوسطة'],['Poor','ضعيفة']])+
      selectInput('fv-route','قدرة المسار','Any',[['LocalOnly','محلية / قريبة فقط'],['Regional','إقليمية / متوسطة'],['LongHaul','بعيدة / مسافات طويلة'],['Any','مناسبة لكل المسارات']])+
      input('fv-eff','الكفاءة المتوقعة (كم/لتر)','','number')+input('fv-year','سنة الصنع','','number')+input('fv-vin','VIN / Chassis','')+input('fv-fuel','نوع الوقود','Diesel')+
      '<div style="grid-column:1/3;padding:12px 14px;border-radius:14px;background:#f8fafc;border:1px solid #e2e8f0;font-size:12px;font-weight:800;color:#475569">حجم الصندوق = الطول × العرض × الارتفاع، ويُحفظ تلقائيًا كم³ لاستخدامه في تخطيط الحمولة.</div>'+
      '<label style="display:flex;align-items:center;gap:8px;font-weight:800;padding-top:12px"><input id="fv-mobile" type="checkbox" checked> تفعيل مخزون المركبة</label></div>',
      async function(){
        var tons=Number(val('fv-weight-ton')),l=Number(val('fv-l')),w=Number(val('fv-w')),h=Number(val('fv-h'));
        if(!val('fv-code')||!val('fv-model')||!val('fv-plate')) throw new Error('الكود والموديل واللوحة مطلوبة');
        if(!(tons>0)) throw new Error('السعة الوزنية يجب أن تكون أكبر من صفر');
        if(!(l>0&&w>0&&h>0)) throw new Error('أبعاد صندوق المركبة الثلاثة مطلوبة');
        await command('VEHICLE_CREATE',{vehicle_code:val('fv-code'),model:val('fv-model'),license_plate:val('fv-plate'),vehicle_type:val('fv-type')||'Delivery',operation_mode:val('fv-mode')||'Mixed',ownership_type:val('fv-owner')||'Owned',max_weight_kg:tons*1000,max_volume_m3:l*w*h,cargo_length_m:l,cargo_width_m:w,cargo_height_m:h,operational_condition:val('fv-condition')||'Good',route_capability:val('fv-route')||'Any',expected_km_per_liter:val('fv-eff')||null,model_year:val('fv-year')||null,vin:val('fv-vin')||null,fuel_type:val('fv-fuel')||null,mobile_stock_enabled:byId('fv-mobile').checked,status:'Active'});
        await refresh(); showToast('تم إنشاء المركبة ببيانات التخطيط والحمولة','success');
      });
  }

async function openDriverForm(){
    await modal('إضافة سائق',
      '<div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;text-align:right">'+
      input('fd-code','كود السائق','')+input('fd-name','الاسم بالكامل','')+input('fd-phone','الهاتف','')+input('fd-email','البريد الإلكتروني','')+
      selectInput('fd-license-type','نوع الرخصة','ProfessionalSecond',[['Private','خاصة'],['ProfessionalFirst','مهنية أولى'],['ProfessionalSecond','مهنية ثانية'],['ProfessionalThird','مهنية ثالثة']])+
      input('fd-license-no','رقم الرخصة','')+input('fd-license-issue','تاريخ إصدار الرخصة','','date')+input('fd-license-expiry','تاريخ انتهاء الرخصة','','date')+
      selectInput('fd-emp','نوع التعاقد','Employee',[['Employee','موظف'],['PerTrip','بالنقلة'],['Monthly','بالشهر'],['Contractor','متعاقد'],['Outsourced','تعهد / شركة خارجية'],['Other','أخرى']])+
      input('fd-hire','تاريخ التعيين / بدء التعاقد','','date')+'</div>',
      async function(){
        if(!val('fd-code')||!val('fd-name')) throw new Error('كود السائق والاسم مطلوبان');
        if(!val('fd-license-type')) throw new Error('نوع الرخصة مطلوب');
        await command('DRIVER_CREATE',{driver_code:val('fd-code'),full_name:val('fd-name'),phone:val('fd-phone')||null,email:val('fd-email')||null,employment_type:val('fd-emp')||'Employee',license_type:val('fd-license-type'),license_number:val('fd-license-no')||null,license_issue_date:val('fd-license-issue')||null,license_expiry_date:val('fd-license-expiry')||null,hire_date:val('fd-hire')||null,status:'Active'});
        await refresh(); showToast('تم إنشاء ملف السائق وربط بيانات الرخصة والتعاقد','success');
      });
  }

async function openOdometerForm(){
    if(!state.selectedVehicleId) return;
    await modal('تسجيل قراءة العداد',input('fo-odo','قراءة العداد (كم)','','number')+input('fo-ref','مرجع القراءة',''),
      async function(){var q=Number(val('fo-odo'));if(!Number.isFinite(q)||q<0)throw new Error('قراءة غير صالحة');await command('ODOMETER_RECORD',{vehicle_id:state.selectedVehicleId,meter_reading:q,source_type:'Manual',reference:val('fo-ref')||null});await openVehicleDetail(state.selectedVehicleId);showToast('تم تسجيل العداد','success');});
  }

  async function openFuelForm(){
    if(!state.selectedVehicleId) return;
    await modal('تسجيل الوقود',
      '<div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;text-align:right">'+input('ff-odo','العداد (كم)','','number')+input('ff-liters','اللترات','','number')+input('ff-price','سعر اللتر','','number')+input('ff-type','نوع الوقود','Diesel')+input('ff-station','المحطة','')+input('ff-ref','المرجع','')+'</div>',
      async function(){var l=Number(val('ff-liters')),p=Number(val('ff-price'));if(!(l>0))throw new Error('اللترات يجب أن تكون أكبر من صفر');if(p<0)throw new Error('سعر الوقود غير صالح');await command('FUEL_RECORD',{vehicle_id:state.selectedVehicleId,odometer_km:val('ff-odo')||null,liters:l,unit_price:p,fuel_type:val('ff-type')||null,station_name:val('ff-station')||null,reference:val('ff-ref')||null});await openVehicleDetail(state.selectedVehicleId);showToast('تم تسجيل الوقود','success');});
  }

  async function openMaintenanceForm(){
    if(!state.selectedVehicleId)return;
    await modal('تسجيل صيانة',
      '<div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;text-align:right">'+input('fm-type','نوع الصيانة','Preventive')+input('fm-date','التاريخ','','date')+input('fm-odo','العداد','','number')+input('fm-vendor','الورشة / المورد','')+input('fm-cost','التكلفة','','number')+input('fm-nextodo','العداد التالي','','number')+input('fm-nextdate','موعد الصيانة التالية','','date')+input('fm-desc','الوصف','')+'</div>',
      async function(){if(!val('fm-desc'))throw new Error('وصف الصيانة مطلوب');await command('MAINTENANCE_RECORD',{vehicle_id:state.selectedVehicleId,maintenance_type:val('fm-type')||'Preventive',service_date:val('fm-date')||null,odometer_km:val('fm-odo')||null,vendor_name:val('fm-vendor')||null,cost:Number(val('fm-cost')||0),next_service_odometer_km:val('fm-nextodo')||null,next_service_date:val('fm-nextdate')||null,status:'Completed',description:val('fm-desc')});await openVehicleDetail(state.selectedVehicleId);showToast('تم تسجيل الصيانة','success');});
  }

  async function openContractForm(){
    if(!state.selectedVehicleId)return;
    await modal('عقد مركبة',
      '<div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;text-align:right">'+input('fc-no','رقم العقد','')+input('fc-type','نوع العقد','Lease')+input('fc-start','البداية','','date')+input('fc-end','النهاية','','date')+input('fc-month','التكلفة الشهرية','','number')+input('fc-km','الكيلومترات المشمولة','','number')+input('fc-excess','سعر الكيلومتر الزائد','','number')+'</div>',
      async function(){if(!val('fc-no')||!val('fc-start'))throw new Error('رقم العقد والبداية مطلوبان');await command('VEHICLE_CONTRACT_UPSERT',{vehicle_id:state.selectedVehicleId,contract_number:val('fc-no'),contract_type:val('fc-type')||'Lease',start_date:val('fc-start'),end_date:val('fc-end')||null,monthly_cost:Number(val('fc-month')||0),included_km:val('fc-km')||null,excess_km_rate:val('fc-excess')||null,status:'Active'});await openVehicleDetail(state.selectedVehicleId);showToast('تم تسجيل العقد','success');});
  }

  async function openVehicleDocumentForm(){
    if(!state.selectedVehicleId)return;
    await modal('مستند المركبة',
      '<div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;text-align:right">'+input('vd-type','نوع المستند','Registration')+input('vd-no','رقم المستند','')+input('vd-issue','تاريخ الإصدار','','date')+input('vd-expiry','تاريخ الانتهاء','','date')+input('vd-alert','تنبيه قبل (أيام)','30','number')+'</div>',
      async function(){await command('VEHICLE_DOCUMENT_UPSERT',{vehicle_id:state.selectedVehicleId,document_type:val('vd-type')||'Registration',document_number:val('vd-no')||null,issue_date:val('vd-issue')||null,expiry_date:val('vd-expiry')||null,alert_days_before:Number(val('vd-alert')||30),status:'Active'});await openVehicleDetail(state.selectedVehicleId);showToast('تم حفظ المستند','success');});
  }

  async function openIncidentForm(){
    if(!state.selectedVehicleId)return;
    await modal('تسجيل حادث / واقعة',
      '<div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;text-align:right">'+input('fi-type','نوع الواقعة','Accident')+input('fi-sev','الخطورة','Medium')+input('fi-product','خسارة المنتج','','number')+input('fi-damage','تكلفة أضرار المركبة','','number')+
      '<div style="grid-column:1/3">'+input('fi-desc','الوصف','')+'</div><div style="grid-column:1/3">'+input('fi-cause','السبب الجذري','')+'</div><div style="grid-column:1/3">'+input('fi-action','الإجراء التصحيحي','')+'</div></div>',
      async function(){if(!val('fi-desc'))throw new Error('وصف الواقعة مطلوب');await command('INCIDENT_CREATE',{vehicle_id:state.selectedVehicleId,incident_type:val('fi-type')||'Accident',severity:val('fi-sev')||'Medium',description:val('fi-desc'),root_cause:val('fi-cause')||null,corrective_action:val('fi-action')||null,product_loss_value:Number(val('fi-product')||0),vehicle_damage_cost:Number(val('fi-damage')||0)});await openVehicleDetail(state.selectedVehicleId);showToast('تم تسجيل الواقعة','success');});
  }

  async function openExpenseForm(){
    if(!state.selectedVehicleId)return;
    await modal('مصروف مركبة',input('fe-cat','الفئة','Toll')+input('fe-amt','المبلغ','','number')+input('fe-ref','المرجع',''),
      async function(){var amount=Number(val('fe-amt'));if(!(amount>=0))throw new Error('المبلغ غير صالح');await command('EXPENSE_CREATE',{vehicle_id:state.selectedVehicleId,category:val('fe-cat')||'Other',amount:amount,reference:val('fe-ref')||null});await openVehicleDetail(state.selectedVehicleId);showToast('تم تسجيل المصروف','success');});
  }

  async function openDriverDocumentForm(){
    if(!state.selectedDriverId)return;
    await modal('رخصة / مستند السائق',
      '<div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;text-align:right">'+input('dd-type','النوع','DriverLicense')+input('dd-no','رقم الرخصة','')+input('dd-class','الفئة','C')+input('dd-issue','الإصدار','','date')+input('dd-exp','الانتهاء','','date')+input('dd-alert','تنبيه قبل (أيام)','30','number')+'</div>',
      async function(){await command('DRIVER_DOCUMENT_UPSERT',{fleet_driver_id:state.selectedDriverId,document_type:val('dd-type')||'DriverLicense',document_number:val('dd-no')||null,license_class:val('dd-class')||null,issue_date:val('dd-issue')||null,expiry_date:val('dd-exp')||null,alert_days_before:Number(val('dd-alert')||30),status:'Active'});await openDriverDetail(state.selectedDriverId);showToast('تم حفظ مستند السائق','success');});
  }

  async function openPerformanceForm(){
    if(!state.selectedDriverId)return;
    await modal('حدث أداء سائق',input('fp-cat','الفئة','RepeatedError')+input('fp-sev','الخطورة','Medium')+input('fp-points','النقاط','5','number')+input('fp-desc','الوصف','')+input('fp-action','الإجراء التصحيحي',''),
      async function(){if(!val('fp-desc'))throw new Error('وصف الحدث مطلوب');await command('PERFORMANCE_EVENT_CREATE',{fleet_driver_id:state.selectedDriverId,category:val('fp-cat')||'RepeatedError',severity:val('fp-sev')||'Medium',points:Number(val('fp-points')||0),description:val('fp-desc'),corrective_action:val('fp-action')||null,status:'Open'});await openDriverDetail(state.selectedDriverId);showToast('تم تسجيل حدث الأداء','success');});
  }

  async function refresh(){
    if(state.tab==='dashboard')return loadDashboard();
    if(state.tab==='vehicles')return loadVehicles();
    if(state.tab==='drivers')return loadDrivers();
    if(state.tab==='trips')return loadTrips();
    if(state.tab==='alerts')return loadAlerts();
    if(state.tab==='costs')return loadCosts();
    if(state.tab==='performance')return loadPerformance();
  }

  async function switchTab(tab){
    state.tab=tab;state.search='';state.selectedVehicleId=null;state.selectedDriverId=null;
    try{showLoader('جاري تحميل إدارة الأسطول...');await refresh();}catch(e){set(shell('إدارة الأسطول والحركة','<div class="rw-card" style="padding:30px"><div style="font-weight:900;color:#b91c1c">تعذر تحميل Fleet</div><div style="margin-top:8px;color:#64748b">'+esc(e.message)+'</div></div>'));}finally{hideLoader();}
  }

  function setSearch(v){state.search=String(v||'').trim();refresh().catch(function(e){showToast(e.message||'فشل البحث','error');});}

  function navigateExisting(view){
    if(window.RW_Navigation&&typeof RW_Navigation.navigate==='function') RW_Navigation.navigate(view);
    else if(window.RW_Views&&typeof RW_Views.render==='function') RW_Views.render(view);
  }

  async function render(){
    if(!canRead()){set(shell('إدارة الأسطول والحركة','<div class="rw-card" style="padding:60px;text-align:center"><div style="font-size:52px">🔒</div><h2>غير مصرح</h2><p>لا تملك صلاحية قراءة إدارة الأسطول</p></div>'));return;}
    try{showLoader('جاري تحميل إدارة الأسطول...');await loadDashboard();}catch(e){set(shell('إدارة الأسطول والحركة','<div class="rw-card" style="padding:30px;color:#b91c1c;font-weight:800">'+esc(e.message)+'</div>'));}finally{hideLoader();}
  }

  var api = {
    render: render,
    switchTab: switchTab,
    setSearch: setSearch,
    openVehicleDetail: openVehicleDetail,
    openDriverDetail: openDriverDetail,
    openVehicleForm: openVehicleForm,
    openDriverForm: openDriverForm,
    openOdometerForm: openOdometerForm,
    openFuelForm: openFuelForm,
    openMaintenanceForm: openMaintenanceForm,
    openContractForm: openContractForm,
    openVehicleDocumentForm: openVehicleDocumentForm,
    openIncidentForm: openIncidentForm,
    openExpenseForm: openExpenseForm,
    openDriverDocumentForm: openDriverDocumentForm,
    openPerformanceForm: openPerformanceForm,
    openRunsheetAssignmentForm: openRunsheetAssignmentForm,
    navigateExisting: navigateExisting
  };
  window.RW_FleetManagement = api;
  return api;
})();
