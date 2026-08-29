from pathlib import Path
import re

MAIN = Path('Current/PWA/main.html')

s = MAIN.read_text(encoding='utf-8')
original = s

required = [
    'window.RW_STATE = RW_STATE;',
    'window.RW_Navigation = RW_Navigation;',
    'window.RW_Views = RW_Views;',
    'var RW_Views = {'
]
for marker in required:
    if marker not in s:
        raise SystemExit(f'P0_ABORT missing anchor: {marker}')

# 1) Canonical authenticated tenant context.
if 'window.RW_ShellContext' not in s:
    anchor = 'window.RW_Navigation = RW_Navigation;'
    pos = s.find(anchor)
    if pos < 0:
        raise SystemExit('P0_ABORT navigation export anchor missing')
    pos += len(anchor)
    block = r'''
// ============================================================
// P0 ERP SHELL — AUTHENTICATED TENANT CONTEXT
// Company comes from the authenticated user, never app_settings LIMIT 1.
// ============================================================
var RW_ShellContext = (function () {
    var companyId = null;
    var resolving = null;
    function resolve(callback) {
        if (companyId) {
            RW_STATE.app.companyId = companyId;
            if (callback) callback(true, companyId);
            return Promise.resolve(companyId);
        }
        if (resolving) return resolving.then(function (id) {
            if (callback) callback(true, id);
            return id;
        });
        var user = RW_STATE.app.currentUser || {};
        if (!user.email) {
            if (callback) callback(false, null);
            return Promise.resolve(null);
        }
        resolving = supabase.from('users')
            .select('id,company_id,name,role,status')
            .eq('email', user.email)
            .eq('status', 'Active')
            .maybeSingle()
            .then(function (res) {
                if (res.error || !res.data || !res.data.company_id) {
                    throw new Error('تعذر تحديد سياق الشركة للمستخدم');
                }
                companyId = res.data.company_id;
                RW_STATE.app.companyId = companyId;
                RW_STATE.app.userId = res.data.id || null;
                if (RW_STATE.app.currentUser) {
                    if (res.data.name) RW_STATE.app.currentUser.name = res.data.name;
                    if (res.data.role) RW_STATE.app.currentUser.role = res.data.role;
                }
                return companyId;
            }).finally(function () { resolving = null; });
        return resolving.then(function (id) {
            if (callback) callback(true, id);
            return id;
        }).catch(function (err) {
            companyId = null;
            RW_STATE.app.companyId = null;
            if (callback) callback(false, null);
            throw err;
        });
    }
    function getCompanyId() {
        if (!companyId && RW_STATE.app.companyId) companyId = RW_STATE.app.companyId;
        if (!companyId) throw new Error('TENANT_CONTEXT_UNAVAILABLE');
        return companyId;
    }
    function hasCompany() {
        return !!(companyId || (RW_STATE.app && RW_STATE.app.companyId));
    }
    return { resolve: resolve, getCompanyId: getCompanyId, hasCompany: hasCompany };
})();
window.RW_ShellContext = RW_ShellContext;

// Preserve the original Parent-PWA entry method; only gate it on tenant context.
var _rwOriginalEnterSystem = RW_Auth.enterSystem;
RW_Auth.enterSystem = function () {
    var self = this;
    if (!RW_ShellContext.hasCompany()) {
        RW_ShellContext.resolve(function (ok) {
            if (ok) self.enterSystem();
            else {
                hideLoader();
                showToast('تعذر تحديد سياق الشركة للمستخدم', 'error');
            }
        }).catch(function (e) { console.error('TENANT_CONTEXT_ERROR', e); });
        return;
    }
    return _rwOriginalEnterSystem.apply(this, arguments);
};
'''
    s = s[:pos] + block + s[pos:]

# 2) Remove known global app_settings LIMIT 1 reads. Already-scoped reads are unchanged.
s = re.sub(
    r"\.from\('app_settings'\)(\s*\.select\([^\n;]*?\))(\s*)\.limit\(1\)",
    r".from('app_settings')\1.eq('company_id', RW_ShellContext.getCompanyId())\2.limit(1)",
    s
)

# 3) Scope known tenant-owned bootstrap reads. Item Master is intentionally untouched:
# Production enforces UNIQUE(item_code) globally and item identity is item_id.
known_reads = [
    ("supabase.from('customers').select('*').then(function(res)", "supabase.from('customers').select('*').eq('company_id', RW_ShellContext.getCompanyId()).then(function(res)"),
    ("supabase.from('branches').select('*').then(function(res)", "supabase.from('branches').select('*').eq('company_id', RW_ShellContext.getCompanyId()).then(function(res)"),
    ("supabase.from('suppliers').select('*').then(function(r)", "supabase.from('suppliers').select('*').eq('company_id', RW_ShellContext.getCompanyId()).then(function(r)"),
    ("supabase.from('users').select('*')", "supabase.from('users').select('*').eq('company_id', RW_ShellContext.getCompanyId())"),
    ("supabase.from('orders').select('order_code, customer_id, total_amount, order_date, area')", "supabase.from('orders').select('order_code, customer_id, total_amount, order_date, area').eq('company_id', RW_ShellContext.getCompanyId())"),
    ("supabase.from('orders').select('total_amount')", "supabase.from('orders').select('total_amount').eq('company_id', RW_ShellContext.getCompanyId())"),
    ("supabase.from('purchase_orders').select('total_amount')", "supabase.from('purchase_orders').select('total_amount').eq('company_id', RW_ShellContext.getCompanyId())"),
    ("supabase.from('purchase_orders').select('*')", "supabase.from('purchase_orders').select('*').eq('company_id', RW_ShellContext.getCompanyId())")
]
for before, after in known_reads:
    s = s.replace(before, after)

# 4) Preserve existing navigation and add one capability: Vehicles.
if "view: 'vehicles'" not in s:
    nav_anchor = "{ view: 'vehicle-count', label: 'جرد سيارة' }, { view: 'branch-count', label: 'جرد فرع' },"
    if nav_anchor not in s:
        raise SystemExit('P0_ABORT vehicle navigation anchor missing')
    s = s.replace(
        nav_anchor,
        "{ view: 'vehicle-count', label: 'جرد سيارة' }, { view: 'vehicles', label: 'السيارات والمركبات', perm: 'vehicles.manage' }, { view: 'branch-count', label: 'جرد فرع' },",
        1
    )

# 5) Integrated Vehicle Master. No direct mutation of vehicle/branch/stock tables.
if 'window.RW_Fleet' not in s:
    anchor = "window.RW_Views = RW_Views;"
    pos = s.find(anchor)
    if pos < 0:
        raise SystemExit('P0_ABORT RW_Views export anchor missing')
    pos += len(anchor)
    block = r'''
// ============================================================
// RW_Fleet — Vehicle Master inside Parent ERP Shell.
// Mutation contract: create_vehicle_atomic only.
// ============================================================
var RW_Fleet = (function () {
    var vehicles = [];
    var drivers = [];
    function cid() { return RW_ShellContext.getCompanyId(); }
    function esc(v) {
        return String(v == null ? '' : v).replace(/[&<>"']/g, function (m) {
            return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m];
        });
    }
    function driverName(id) {
        for (var i = 0; i < drivers.length; i++) {
            if (drivers[i].id === id) return drivers[i].name || drivers[i].email || '';
        }
        return 'غير معين';
    }
    async function load() {
        var v = await supabase.from('vehicles')
            .select('id,vehicle_code,model,license_plate,driver_id,status,vehicle_type,operation_mode,ownership_type,max_weight_kg,max_volume_m3,min_trip_value,refrigerated,mobile_stock_enabled,mobile_branch_id')
            .eq('company_id', cid()).order('vehicle_code', { ascending: true });
        if (v.error) throw v.error;
        vehicles = v.data || [];
        var d = await supabase.from('users')
            .select('id,name,email,role,status')
            .eq('company_id', cid()).eq('status', 'Active')
            .in('role', ['driver','سائق','مندوب']).order('name', { ascending: true });
        if (d.error) throw d.error;
        drivers = d.data || [];
    }
    function draw(term) {
        var w = byId('rw-fleet-table'); if (!w) return;
        term = String(term || '').trim().toLowerCase();
        var rows = vehicles.filter(function (v) {
            return !term || [v.vehicle_code,v.license_plate,v.model,v.status,v.vehicle_type,v.operation_mode,v.ownership_type,driverName(v.driver_id)].join(' ').toLowerCase().indexOf(term) !== -1;
        });
        if (!rows.length) { safeHTML(w, '<div class="p-10 text-center text-gray-400">لا توجد سيارات ضمن الشركة الحالية.</div>'); return; }
        var h = '<table class="rw-table"><thead><tr><th>الكود</th><th>اللوحة</th><th>الموديل</th><th>المندوب</th><th>النمط</th><th>الحالة</th><th>Mobile Stock</th></tr></thead><tbody>';
        rows.forEach(function (v) {
            h += '<tr><td>'+esc(v.vehicle_code)+'</td><td>'+esc(v.license_plate)+'</td><td>'+esc(v.model||'-')+'</td><td>'+esc(driverName(v.driver_id))+'</td><td>'+esc(v.operation_mode||'-')+'</td><td>'+esc(v.status||'-')+'</td><td>'+(v.mobile_stock_enabled?'مفعل':'غير مفعل')+'</td></tr>';
        });
        h += '</tbody></table>';
        safeHTML(w, h);
    }
    async function driverSearch(term) {
        term = String(term || '').trim();
        var q = supabase.from('users').select('id,name,email,role,status')
            .eq('company_id', cid()).eq('status','Active').in('role',['driver','سائق','مندوب']).limit(20);
        if (term) q = q.or('name.ilike.%'+term+'%,email.ilike.%'+term+'%');
        var r = await q;
        var w = byId('vf-driver-results'); if (!w) return;
        var h = '';
        (r.data || []).forEach(function (d) {
            h += '<button type="button" class="block w-full text-right p-3 border-b bg-white" onclick="RW_Fleet.pickDriver(\\''+d.id+'\\',\\''+esc(d.name)+'\\',\\''+esc(d.email)+'\\')">'+esc(d.name)+' <span class="text-gray-500">'+esc(d.email)+'</span></button>';
        });
        safeHTML(w, h || '<div class="p-3 text-gray-400">لا يوجد مندوب مطابق.</div>');
    }
    function pickDriver(id,name,email) {
        var hidden=byId('vf-driver-id'), input=byId('vf-driver-search');
        if (hidden) hidden.value=id;
        if (input) input.value=name+' ('+email+')';
        safeHTML(byId('vf-driver-results'),'');
    }
    async function create() {
        var code=String((byId('vf-code')||{}).value||'').trim();
        var plate=String((byId('vf-plate')||{}).value||'').trim();
        if(!code||!plate){Swal.showValidationMessage('كود السيارة ورقم اللوحة مطلوبان');return false;}
        var u=RW_STATE.app.currentUser||{};
        var r=await supabase.rpc('create_vehicle_atomic',{
            p_company_id:cid(), p_vehicle_code:code, p_model:(byId('vf-model')||{}).value||null,
            p_license_plate:plate, p_driver_id:(byId('vf-driver-id')||{}).value||null,
            p_max_weight_kg:Number((byId('vf-weight')||{}).value)||null,
            p_max_volume_m3:Number((byId('vf-volume')||{}).value)||null,
            p_min_trip_value:Number((byId('vf-mintrip')||{}).value)||null,
            p_status:(byId('vf-status')||{}).value||'Active', p_notes:(byId('vf-notes')||{}).value||null,
            p_vehicle_type:(byId('vf-type')||{}).value||'Delivery', p_operation_mode:(byId('vf-mode')||{}).value||'Mixed',
            p_ownership_type:(byId('vf-own')||{}).value||'Owned', p_model_year:Number((byId('vf-year')||{}).value)||null,
            p_vin:(byId('vf-vin')||{}).value||null, p_fuel_type:(byId('vf-fuel')||{}).value||null,
            p_refrigerated:!!(byId('vf-refrigerated')||{}).checked,
            p_mobile_stock_enabled:!!(byId('vf-mobile-stock')||{}).checked,
            p_created_by:u.email||null
        });
        if(r.error){Swal.showValidationMessage(r.error.message);return false;}
        if(!r.data||!r.data.success){Swal.showValidationMessage((r.data&&r.data.error)||'فشل إنشاء السيارة');return false;}
        return r.data;
    }
    function openCreate(){
        var html='<div dir="rtl"><div class="grid grid-cols-1 md:grid-cols-2 gap-3">'+
        '<input id="vf-code" class="rw-input" placeholder="كود السيارة *"><input id="vf-plate" class="rw-input" placeholder="رقم اللوحة *">'+
        '<input id="vf-model" class="rw-input" placeholder="الموديل"><input id="vf-weight" type="number" step="0.01" class="rw-input" placeholder="أقصى وزن kg">'+
        '<input id="vf-volume" type="number" step="0.01" class="rw-input" placeholder="أقصى حجم m³"><input id="vf-mintrip" type="number" step="0.01" class="rw-input" placeholder="الحد الأدنى لقيمة الرحلة">'+
        '<select id="vf-type" class="rw-input"><option value="Delivery">Delivery</option><option value="Sales">Sales</option><option value="Mixed" selected>Mixed</option></select>'+
        '<select id="vf-mode" class="rw-input"><option value="Mixed" selected>Mixed</option><option value="DirectSales">Direct Sales</option><option value="Delivery">Delivery</option></select>'+
        '<select id="vf-own" class="rw-input"><option value="Owned" selected>Owned</option><option value="Leased">Leased</option><option value="Rented">Rented</option></select>'+
        '<select id="vf-status" class="rw-input"><option value="Active" selected>Active</option><option value="Inactive">Inactive</option><option value="Maintenance">Maintenance</option></select>'+
        '<input id="vf-year" type="number" class="rw-input" placeholder="سنة الموديل"><input id="vf-vin" class="rw-input" placeholder="VIN"><input id="vf-fuel" class="rw-input" placeholder="نوع الوقود">'+
        '<div class="md:col-span-2"><input id="vf-driver-search" class="rw-input" placeholder="بحث ذكي بالمندوب / السائق" oninput="RW_Fleet.driverSearch(this.value)"><input id="vf-driver-id" type="hidden"><div id="vf-driver-results" class="border rounded-xl mt-2 max-h-40 overflow-auto"></div></div>'+
        '<label class="flex items-center gap-2 md:col-span-2"><input id="vf-refrigerated" type="checkbox"> مركبة مبردة</label>'+
        '<label class="flex items-center gap-2 md:col-span-2"><input id="vf-mobile-stock" type="checkbox" checked> Mobile Stock</label>'+
        '<textarea id="vf-notes" class="rw-input md:col-span-2" style="height:90px;padding:12px 18px" placeholder="ملاحظات"></textarea></div></div>';
        Swal.fire({title:'إضافة سيارة',html:html,width:820,showCancelButton:true,confirmButtonText:'إنشاء السيارة',cancelButtonText:'إلغاء',preConfirm:function(){return create();}});
        driverSearch('');
    }
    return {render:function(){safeText(byId('rw-header-title'),'السيارات والمركبات');safeText(byId('rw-header-subtitle'),'Vehicle Master • مندوب • سيارة • Mobile Branch • Van Stock');safeHTML(byId('rw-page-container'),'<div class="space-y-5"><div class="rw-card"><div class="flex justify-between items-center gap-3 flex-wrap"><div><h2 class="text-xl font-black">السيارات والمركبات</h2><p class="text-sm text-gray-500 mt-1">سجل موحد للأسطول مرتبط بالمندوب والفرع المتنقل والمخزون.</p></div><button class="rw-btn-primary" onclick="RW_Fleet.openCreate()">إضافة سيارة</button></div></div><div class="rw-card p-0 overflow-hidden"><div class="p-4 border-b"><input id="rw-fleet-search" class="rw-input" style="height:52px;padding-right:18px" placeholder="بحث ذكي بالكود، اللوحة، الموديل، المندوب، الحالة..." oninput="RW_Fleet.draw(this.value)"></div><div id="rw-fleet-table" class="overflow-auto"></div></div></div>');load().then(function(){draw('');}).catch(function(e){safeHTML(byId('rw-fleet-table'),'<div class="p-8 text-center text-red-500 font-bold">'+esc(e.message)+'</div>');});},draw:draw,openCreate:openCreate,driverSearch:driverSearch,pickDriver:pickDriver};
})();
window.RW_Fleet=RW_Fleet;
'''
    s=s[:pos]+block+s[pos:]

# Route Vehicles without replacing any existing route.
if "if (view === 'vehicles') { RW_Fleet.render(); return; }" not in s:
    anchor = "        if (view === 'audit-log') { RW_Audit_renderTab(); return; }"
    if anchor not in s:
        raise SystemExit('P0_ABORT audit route anchor missing')
    s=s.replace(anchor,"        if (view === 'vehicles') { RW_Fleet.render(); return; }\n"+anchor,1)

# Register Fleet in the sidebar after the existing builder runs; honor the existing wildcard/permission semantics.
if 'rw-nav-vehicles' not in s:
    marker = 'window.RW_Views = RW_Views;'
    pos=s.find(marker)
    if pos<0: raise SystemExit('P0_ABORT second RW_Views anchor')
    pos += len(marker)
    side = r'''
(function () {
    function addFleetNavigation() {
        var nav = byId('rw-sidebar-nav');
        if (!nav || byId('rw-nav-vehicles')) return;
        var allowed = false;
        try { allowed = RW_Permissions_check('vehicles.manage'); } catch (e) { allowed = false; }
        if (!allowed) return;
        var button = document.createElement('button');
        button.id = 'rw-nav-vehicles';
        button.type = 'button';
        button.className = 'rw-sidebar-link';
        button.setAttribute('data-view','vehicles');
        button.innerHTML = '<span class="rw-sidebar-link-icon"><i class="fa-solid fa-car-side"></i></span><span class="rw-sidebar-link-text">السيارات والمركبات</span>';
        button.onclick = function () { RW_Navigation.navigate('vehicles'); };
        nav.appendChild(button);
    }
    try {
        var observer = new MutationObserver(addFleetNavigation);
        observer.observe(document.documentElement, { childList: true, subtree: true });
    } catch (e) {}
    setTimeout(addFleetNavigation, 600);
    setTimeout(addFleetNavigation, 1800);
})();
'''
    s=s[:pos]+side+s[pos:]

# Static forbidden pattern must be absent.
for bad in [
    ".from('app_settings')\n            .select('*')\n            .limit(1",
    ".from('app_settings').select('*').limit(1).single()"
]:
    if bad in s:
        raise SystemExit('P0_ABORT unscoped app_settings remains')

MAIN.write_text(s, encoding='utf-8')
print(f'P0_PATCHED {len(original.encode())} -> {len(s.encode())}')
