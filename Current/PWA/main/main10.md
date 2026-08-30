// RAWAEA ERP — MAIN10
// Owner / License Management + Global View Router
// UI/orchestration only. No direct Physical Stock, Accounting, Ledger, or tenant-authority writes.

var RW_OwnerLicense = (function () {
    'use strict';

    function cid() {
        if (!window.RW_ShellContext || typeof RW_ShellContext.getCompanyId !== 'function') {
            throw new Error('TENANT_CONTEXT_UNAVAILABLE');
        }
        var id = RW_ShellContext.getCompanyId();
        if (!id) throw new Error('TENANT_CONTEXT_UNAVAILABLE');
        return id;
    }
    function owner() {
        return !!(window.RW_STATE && RW_STATE.app && RW_STATE.app.currentUser &&
            RW_STATE.app.currentUser.isOwner === true);
    }
    function esc(v) {
        return String(v == null ? '' : v).replace(/[&<>"']/g, function (c) {
            return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c];
        });
    }
    function toast(m, t) {
        try { if (typeof showToast === 'function') showToast(m, t || 'info'); }
        catch (e) { console.error(m); }
    }
    function loader(m) { try { if (typeof showLoader === 'function') showLoader(m); } catch (e) {} }
    function unload() { try { if (typeof hideLoader === 'function') hideLoader(); } catch (e) {} }

    function settings() {
        var company = cid();
        return supabase.from('app_settings')
            .select('id,company_id,company_name,status,trial_end_date,subscription_end_date,main_branch_id,created_at,updated_at')
            .eq('company_id', company)
            .order('created_at', {ascending:true})
            .order('id', {ascending:true})
            .limit(1).maybeSingle()
            .then(function (r) {
                if (r.error) throw r.error;
                if (!r.data) throw new Error('LICENSE_SETTINGS_NOT_FOUND');
                return r.data;
            });
    }
    function authUser() {
        return supabase.auth.getUser().then(function (r) {
            if (r.error || !r.data || !r.data.user) throw new Error('SESSION_INVALID');
            return r.data.user;
        });
    }
    function profile() {
        var company = cid();
        return authUser().then(function (u) {
            return supabase.from('users')
                .select('id,auth_id,company_id,email,name,role,status,permissions')
                .eq('auth_id', u.id).eq('company_id', company).maybeSingle()
                .then(function (r) {
                    if (r.error) throw r.error;
                    return {user:u, profile:r.data || null};
                });
        });
    }
    function render() {
        var c = byId('rw-page-container');
        if (!c) return;
        if (!owner()) {
            safeHTML(c, '<div class="rw-card" style="max-width:720px;margin:40px auto;padding:60px 20px;text-align:center"><div style="font-size:64px">🔒</div><h2 style="font-weight:900">غير مصرح</h2><p style="color:#6b7280">هذا التبويب مخصص للمالك فقط.</p></div>');
            return;
        }
        safeText(byId('rw-header-title'), 'إدارة الترخيص');
        safeText(byId('rw-header-subtitle'), 'حالة الشركة وبيانات المالك');
        safeHTML(c, '<div id="license-main-container" class="p-4 max-w-3xl mx-auto"><div class="text-center py-10 text-gray-400"><i class="fa-solid fa-spinner fa-spin text-2xl"></i><div class="mt-2">جاري التحميل...</div></div></div>');
        load();
    }
    function load() {
        if (!owner()) return;
        Promise.all([settings(), profile()]).then(function (x) {
            build(x[0], x[1]);
        }).catch(function (e) {
            console.error('RW_OwnerLicense.load', e);
            toast('تعذر تحميل بيانات الترخيص.', 'error');
        });
    }
    window.togglePasswordVisibility = function (id, btn) {
        var i = document.getElementById(id);
        if (!i) return;
        i.type = i.type === 'password' ? 'text' : 'password';
        if (btn) btn.innerHTML = i.type === 'password' ? '<i class="fa-solid fa-eye"></i>' : '<i class="fa-solid fa-eye-slash"></i>';
    };
    function build(s, p) {
        var c = byId('license-main-container');
        if (!c) return;
        var u = p.user || {}, profileRow = p.profile || {}, email = u.email || profileRow.email || '';
        var html = '';
        html += '<div class="bg-white rounded-2xl shadow-sm border p-6">';
        html += '<h3 class="text-lg font-black text-indigo-600 border-b pb-3 mb-5"><i class="fa-solid fa-shield-halved ml-2"></i> إعدادات الترخيص</h3>';
        html += '<div class="grid grid-cols-1 md:grid-cols-2 gap-4">';
        html += '<div><label class="text-sm font-bold">حالة الشركة</label><select id="license-status" class="mt-2 p-3 bg-gray-50 border rounded-xl w-full">';
        html += '<option value="trial"'+(s.status==='trial'?' selected':'')+'>فترة تجربة</option><option value="active"'+(s.status==='active'?' selected':'')+'>نشطة</option><option value="suspended"'+(s.status==='suspended'?' selected':'')+'>موقوفة</option><option value="cancelled"'+(s.status==='cancelled'?' selected':'')+'>ملغاة</option>';
        html += '</select></div>';
        html += '<div><label class="text-sm font-bold">الحساب الحالي</label><input class="mt-2 p-3 bg-gray-100 border rounded-xl w-full" readonly value="'+esc(email)+'"></div>';
        html += '<div><label class="text-sm font-bold">تاريخ انتهاء التجربة</label><input id="license-trial-end" type="date" class="mt-2 p-3 bg-gray-50 border rounded-xl w-full" value="'+esc(s.trial_end_date||'')+'"></div>';
        html += '<div><label class="text-sm font-bold">تاريخ انتهاء الاشتراك</label><input id="license-sub-end" type="date" class="mt-2 p-3 bg-gray-50 border rounded-xl w-full" value="'+esc(s.subscription_end_date||'')+'"></div>';
        html += '</div><div class="flex justify-end pt-5"><button id="btn-save-license-only" type="button" class="px-6 py-3 bg-indigo-600 text-white rounded-xl font-bold">حفظ إعدادات الترخيص</button></div></div>';
        html += '<div class="bg-white rounded-2xl shadow-sm border p-6 mt-6"><h3 class="text-lg font-black text-blue-600 border-b pb-3 mb-5"><i class="fa-solid fa-envelope ml-2"></i> تغيير البريد الإلكتروني</h3>';
        html += '<input id="owner-current-email" readonly class="p-3 bg-gray-100 border rounded-xl w-full mb-3" value="'+esc(email)+'">';
        html += '<input id="owner-new-email" type="email" autocomplete="email" class="p-3 bg-gray-50 border rounded-xl w-full mb-3" placeholder="أدخل البريد الإلكتروني الجديد">';
        html += '<div class="flex justify-end"><button id="btn-change-email" type="button" class="px-6 py-3 bg-blue-600 text-white rounded-xl font-bold">تغيير البريد الإلكتروني</button></div></div>';
        html += '<div class="bg-white rounded-2xl shadow-sm border p-6 mt-6"><h3 class="text-lg font-black text-red-600 border-b pb-3 mb-5"><i class="fa-solid fa-key ml-2"></i> تغيير كلمة المرور</h3>';
        html += '<div class="relative mb-3"><input id="owner-new-password" type="password" autocomplete="new-password" class="p-3 bg-gray-50 border rounded-xl w-full pl-12" placeholder="كلمة المرور الجديدة"><button type="button" onclick="window.togglePasswordVisibility(\'owner-new-password\',this)" class="absolute left-2 top-2.5 p-2"><i class="fa-solid fa-eye"></i></button></div>';
        html += '<div class="relative mb-3"><input id="owner-confirm-password" type="password" autocomplete="new-password" class="p-3 bg-gray-50 border rounded-xl w-full pl-12" placeholder="تأكيد كلمة المرور"><button type="button" onclick="window.togglePasswordVisibility(\'owner-confirm-password\',this)" class="absolute left-2 top-2.5 p-2"><i class="fa-solid fa-eye"></i></button></div>';
        html += '<div class="flex justify-end"><button id="btn-change-password" type="button" class="px-6 py-3 bg-red-600 text-white rounded-xl font-bold">تغيير كلمة المرور</button></div></div>';
        safeHTML(c, html); bind(s);
    }
    function bind(s) {
        var b = byId('btn-save-license-only');
        if (b) b.addEventListener('click', function () {
            if (!owner()) return toast('غير مصرح','error');
            saveSettings({
                status: (byId('license-status')||{}).value || s.status || 'trial',
                trial_end_date: (byId('license-trial-end')||{}).value || null,
                subscription_end_date: (byId('license-sub-end')||{}).value || null
            });
        });
        b = byId('btn-change-email');
        if (b) b.addEventListener('click', function () {
            var n = String((byId('owner-new-email')||{}).value||'').trim().toLowerCase();
            if (!n) return toast('أدخل البريد الإلكتروني الجديد','error');
            if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(n)) return toast('صيغة البريد الإلكتروني غير صحيحة','error');
            authUser().then(function (u) {
                if (n === String(u.email||'').trim().toLowerCase()) throw new Error('البريد الإلكتروني الجديد مطابق للحالي');
                loader('جاري تغيير البريد الإلكتروني...');
                return supabase.auth.updateUser({email:n});
            }).then(function (r) {
                unload(); if (r && r.error) throw r.error;
                if (byId('owner-new-email')) byId('owner-new-email').value='';
                toast('تم طلب تغيير البريد الإلكتروني. تحقق من رسالة التأكيد.','success');
            }).catch(function(e){ unload(); toast(e.message||'فشل تغيير البريد الإلكتروني','error'); });
        });
        b = byId('btn-change-password');
        if (b) b.addEventListener('click', function () {
            var n = String((byId('owner-new-password')||{}).value||''), c = String((byId('owner-confirm-password')||{}).value||'');
            if (!n) return toast('أدخل كلمة المرور الجديدة','error');
            if (n.length < 6) return toast('كلمة المرور يجب ألا تقل عن 6 أحرف.','error');
            if (n !== c) return toast('تأكيد كلمة المرور غير مطابق.','error');
            loader('جاري تغيير كلمة المرور...');
            supabase.auth.updateUser({password:n}).then(function(r){
                unload(); if (r.error) throw r.error;
                if (byId('owner-new-password')) byId('owner-new-password').value='';
                if (byId('owner-confirm-password')) byId('owner-confirm-password').value='';
                toast('تم تغيير كلمة المرور بنجاح.','success');
            }).catch(function(e){ unload(); toast(e.message||'فشل تغيير كلمة المرور','error'); });
        });
    }
    function saveSettings(payload) {
        cid(); loader('جاري حفظ إعدادات الترخيص...');
        supabase.auth.getSession().then(function (r) {
            if (!r.data || !r.data.session) throw new Error('SESSION_INVALID');
            return fetch(RW_SUPABASE_URL+'/functions/v1/save-settings',{
                method:'POST', headers:{'Content-Type':'application/json','Authorization':'Bearer '+r.data.session.access_token},
                body:JSON.stringify(payload)
            });
        }).then(function(r){ return r.json().then(function(b){ if(!r.ok || !b || b.success!==true) throw new Error(b && (b.error||b.msg) || 'فشل حفظ إعدادات الترخيص'); return b; }); })
          .then(function(){ unload(); toast('تم حفظ إعدادات الترخيص بنجاح.','success'); load(); })
          .catch(function(e){ unload(); console.error('RW_OwnerLicense.saveSettings',e); toast(e.message||'فشل حفظ إعدادات الترخيص','error'); });
    }
    return {render:render,reload:load};
})();
window.RW_OwnerLicense = RW_OwnerLicense;

var RW_Views = (function () {
    'use strict';
    var permissions = {
        dashboard:'dash', items:'items', telesales:'orders', customers:'customers', suppliers:'suppliers',
        branches:'branches', pos:'pos', 'purchase-pos':'purchases', purchases:'purchases', orders:'orders',
        runsheets:'runsheets', 'online-store':'online-store', users:'users', roles:'roles', license:'license',
        settings:'settings', settlement:'settlement', receiving:'receiving', picking:'picking', loading:'loading',
        delivery:'delivery', return:'return', unloading:'unloading', vouchers:'vouchers', transfer:'transfer',
        'direct-sale':'direct-sale', 'direct-return':'direct-return', 'supplier-return':'supplier-return',
        'vehicle-count':'vehicle-count', 'branch-count':'branch-count', 'general-count':'general-count',
        'reports-dashboard':'reports', 'reports-detailed':'reports', 'reports-comprehensive':'reports',
        'audit-log':'owner', hr:'users', crm:'customers'
    };
    function allowed(k) {
        try {
            if (k === 'owner') return !!(RW_STATE.app.currentUser && RW_STATE.app.currentUser.isOwner === true);
            if (typeof RW_Permissions_check === 'function') return RW_Permissions_check(k) === true;
            var p = RW_STATE.app.currentUser && RW_STATE.app.currentUser.permissions;
            return Array.isArray(p) && (p.indexOf('*') >= 0 || p.indexOf(k) >= 0);
        } catch (e) { return false; }
    }
    function err(c, title, text) {
        safeHTML(c, '<div class="rw-card" style="max-width:720px;margin:40px auto;padding:60px 20px;text-align:center"><div style="font-size:56px">⚠️</div><h2 style="font-weight:900">'+esc(title)+'</h2><p style="color:#6b7280">'+esc(text)+'</p></div>');
    }
    function render(view) {
        var c = byId('rw-page-container'); if (!c) return;
        var pk = permissions[view];
        if (pk && !allowed(pk)) return err(c,'غير مصرح','ليس لديك صلاحية الوصول إلى هذا التبويب.');
        if (view === 'audit-log') {
            if (typeof window.RW_Audit_renderTab !== 'function') return err(c,'الوحدة غير متاحة','RW_Audit_renderTab غير محملة.');
            try { window.RW_Audit_renderTab(); } catch (e) { console.error(e); err(c,'حدث خطأ','تعذر فتح سجل التدقيق.'); }
            return;
        }
        if (['transfer','direct-sale','direct-return','supplier-return'].indexOf(view)>=0) {
            if (!window.RW_Warehouse || typeof RW_Warehouse.loadVoucherForm !== 'function') return err(c,'الوحدة غير متاحة','RW_Warehouse.loadVoucherForm غير محملة.');
            try { RW_Warehouse.loadVoucherForm(view==='transfer'?'Transfer':view==='direct-sale'?'DirectSale':view==='direct-return'?'DirectReturn':'SupplierReturn'); }
            catch(e){ console.error(e); err(c,'حدث خطأ','تعذر فتح نموذج المخزون.'); }
            return;
        }
        var map = {
            dashboard:[RW_Dashboard,'render'], items:[RW_Items,'render'], customers:[RW_Customers,'render'],
            suppliers:[RW_Suppliers,'render'], branches:[RW_Branches,'render'], settings:[RW_Settings,'render'],
            hr:[RW_HR,'render'], crm:[RW_CRM,'render'], users:[RW_Users,'render'], roles:[RW_Roles,'render'],
            license:[RW_OwnerLicense,'render'], telesales:[RW_TeleSales,'render'], pos:[RW_POS,'render'],
            orders:[RW_Orders,'render'], runsheets:[RW_Runsheets,'render'], 'online-store':[RW_OnlineStore,'render'],
            purchases:[RW_Purchases,'renderOrders'], 'purchase-pos':[RW_Purchases,'renderPOS'],
            picking:[RW_Warehouse,'loadPicking'], loading:[RW_Warehouse,'loadLoading'], delivery:[RW_Warehouse,'loadDelivery'],
            return:[RW_Warehouse,'loadReturn'], unloading:[RW_Warehouse,'loadUnloading'], receiving:[RW_Warehouse,'loadReceiving'],
            vouchers:[RW_Warehouse,'loadVouchers'], 'vehicle-count':[RW_Warehouse,'loadVehicleCount'],
            'branch-count':[RW_Warehouse,'loadBranchCount'], 'general-count':[RW_Warehouse,'loadGeneralCount'],
            settlement:[RW_Warehouse,'loadSettlement'], 'reports-dashboard':[RW_Reports,'renderDashboard'],
            'reports-detailed':[RW_Reports,'renderDetailedReports'], 'reports-comprehensive':[RW_Reports_Comprehensive,'render']
        };
        if (view === 'finance' && window.RW_Finance) map.finance=[RW_Finance,'render'];
        var h = map[view];
        if (!h || !h[0] || typeof h[0][h[1]] !== 'function') return err(c,'الوحدة غير متاحة','الوحدة المطلوبة غير محملة.');
        try { h[0][h[1]](); } catch(e){ console.error('RW_Views.'+view,e); err(c,'حدث خطأ','تعذر فتح التبويب المطلوب.'); }
    }
    return {render:render,permissionMap:permissions};
})();
window.RW_Views = RW_Views;
