from pathlib import Path
import re

p=Path("Current/PWA/main.html")
s=p.read_text(encoding="utf-8")
orig=s

anchors=["window.RW_STATE = RW_STATE;","window.RW_Navigation = RW_Navigation;","window.RW_Views = RW_Views;","var RW_Views = {"]
for a in anchors:
    if a not in s:
        raise SystemExit("P0_ABORT missing "+a)

# Parent tenant context: always resolve from authenticated users.company_id.
if "window.RW_ShellContext" not in s:
    a="window.RW_Navigation = RW_Navigation;"
    block=r'''\nvar RW_ShellContext=(function(){\n  var companyId=null, resolving=null;\n  function resolve(){\n    if(companyId)return Promise.resolve(companyId);\n    if(resolving)return resolving;\n    var u=RW_STATE.app.currentUser||{};\n    if(!u.email)return Promise.reject(new Error("AUTH_USER_UNAVAILABLE"));\n    resolving=supabase.from("users").select("id,company_id,name,role,status")\n      .eq("email",u.email).eq("status","Active").maybeSingle().then(function(r){\n        if(r.error||!r.data||!r.data.company_id)throw new Error("TENANT_CONTEXT_UNAVAILABLE");\n        companyId=r.data.company_id;\n        RW_STATE.app.companyId=companyId;\n        RW_STATE.app.userId=r.data.id||null;\n        if(RW_STATE.app.currentUser){\n          RW_STATE.app.currentUser.company_id=companyId;\n          if(r.data.name)RW_STATE.app.currentUser.name=r.data.name;\n          if(r.data.role)RW_STATE.app.currentUser.role=r.data.role;\n        }\n        return companyId;\n      }).finally(function(){resolving=null;});\n    return resolving;\n  }\n  function getCompanyId(){\n    if(!companyId&&RW_STATE.app.companyId)companyId=RW_STATE.app.companyId;\n    if(!companyId)throw new Error("TENANT_CONTEXT_UNAVAILABLE");\n    return companyId;\n  }\n  return {resolve:resolve,getCompanyId:getCompanyId,hasCompany:function(){return !!(companyId||(RW_STATE.app&&RW_STATE.app.companyId));}};\n})();\nwindow.RW_ShellContext=RW_ShellContext;\nvar _rwParentEnterSystem=RW_Auth.enterSystem;\nRW_Auth.enterSystem=function(){\n  var a=arguments,ctx=this;\n  return (RW_ShellContext.hasCompany()?Promise.resolve(RW_ShellContext.getCompanyId()):RW_ShellContext.resolve())\n    .then(function(){return _rwParentEnterSystem.apply(ctx,a);});\n};\n'''
    s=s.replace(a,a+block,1)

# Company-scope app_settings reads in Parent PWA.
s=re.sub(
    r"\.from\('app_settings'\)(?P<t>\s*\.select\([^;]*?\))(?P<u>\s*\.limit\(1\))(?P<v>\.single\(\))?",
    lambda m: ".from('app_settings')"+m.group('t')+".eq('company_id',RW_ShellContext.getCompanyId())"+m.group('u')+(m.group('v') or ''),
    s
)

# Tenant-owned collection reads in the shell.
for t in ("customers","branches","suppliers","users"):
    s=re.sub(
        rf"supabase\.from\('{t}'\)\.select\('\*'\)(?!\.eq\('company_id')",
        f"supabase.from('{t}').select('*').eq('company_id',RW_ShellContext.getCompanyId())",
        s
    )

# Vehicle Master native integration retained from the prior governed executor.
if "view: 'vehicles'" not in s:
    a="{ view: 'vehicle-count', label: 'جرد سيارة' },"
    if a not in s: raise SystemExit("P0_ABORT vehicle anchor")
    s=s.replace(a,"{ view: 'vehicles', label: 'السيارات والمركبات', perm: 'vehicles.manage' }, "+a,1)

if "window.RW_Fleet" not in s:
    a="window.RW_Views = RW_Views;"
    block=r'''\nvar RW_Fleet=(function(){\n  function cid(){return RW_ShellContext.getCompanyId();}\n  function esc(v){return String(v==null?"":v).replace(/[&<>\"]/g,function(m){return{"&":"&amp;","<":"&lt;",">":"&gt;",\"\" : "&quot;"}[m]||m;});}\n  function load(){return Promise.all([supabase.from("vehicles").select("id,vehicle_code,model,license_plate,driver_id,status,vehicle_type,operation_mode,ownership_type,mobile_stock_enabled").eq("company_id",cid()).order("vehicle_code"),supabase.from("users").select("id,name,email,role").eq("company_id",cid()).eq("status","Active").in("role",["driver","سائق","مندوب"]).order("name")]).then(function(r){if(r[0].error)throw r[0].error;if(r[1].error)throw r[1].error;return{vehicles:r[0].data||[],drivers:r[1].data||[]};});}\n  function render(){safeText(byId("rw-header-title"),"السيارات والمركبات");safeText(byId("rw-header-subtitle"),"Vehicle Master داخل Parent PWA");safeHTML(byId("rw-page-container"),'<div class="space-y-5"><div class="rw-card"><div class="flex justify-between items-center"><div><h2 class="text-xl font-black">السيارات والمركبات</h2><p class="text-sm text-gray-500">أسطول الشركة مع السائق والمخزون المتنقل.</p></div><button class="rw-btn-primary" onclick="RW_Fleet.openCreate()">إضافة سيارة</button></div></div><div class="rw-card p-0"><div id="rw-fleet-table" class="overflow-auto p-4">جاري التحميل...</div></div></div>');load().then(function(x){var d={};(x.drivers||[]).forEach(function(u){d[u.id]=u.name||u.email||"";});var h='<table class="rw-table"><thead><tr><th>الكود</th><th>اللوحة</th><th>الموديل</th><th>السائق</th><th>الحالة</th><th>Mobile Stock</th></tr></thead><tbody>';(x.vehicles||[]).forEach(function(v){h+='<tr><td>'+esc(v.vehicle_code)+'</td><td>'+esc(v.license_plate)+'</td><td>'+esc(v.model||"-")+'</td><td>'+esc(d[v.driver_id]||"غير معين")+'</td><td>'+esc(v.status||"-")+'</td><td>'+(v.mobile_stock_enabled?"مفعل":"غير مفعل")+'</td></tr>';});h+='</tbody></table>';safeHTML(byId("rw-fleet-table"),h);}).catch(function(e){safeHTML(byId("rw-fleet-table"),'<div class="p-8 text-red-500">'+esc(e.message)+'</div>');});}\n  function openCreate(){var h='<div dir="rtl"><input id="vf-code" class="rw-input" placeholder="كود السيارة *"><input id="vf-plate" class="rw-input mt-2" placeholder="رقم اللوحة *"><input id="vf-model" class="rw-input mt-2" placeholder="الموديل"><input id="vf-driver" class="rw-input mt-2" placeholder="Driver UUID (اختياري)"><select id="vf-status" class="rw-input mt-2"><option value="Active">Active</option><option value="Inactive">Inactive</option><option value="Maintenance">Maintenance</option></select><label class="block mt-3"><input id="vf-mobile" type="checkbox"> Mobile Stock</label></div>';Swal.fire({title:"إضافة سيارة",html:h,showCancelButton:true,confirmButtonText:"إنشاء",preConfirm:function(){var code=String((byId("vf-code")||{}).value||"").trim(),plate=String((byId("vf-plate")||{}).value||"").trim();if(!code||!plate){Swal.showValidationMessage("الكود واللوحة مطلوبان");return false;}return supabase.rpc("create_vehicle_atomic",{p_company_id:cid(),p_vehicle_code:code,p_model:(byId("vf-model")||{}).value||null,p_license_plate:plate,p_driver_id:(byId("vf-driver")||{}).value||null,p_status:(byId("vf-status")||{}).value||"Active",p_mobile_stock_enabled:!!(byId("vf-mobile")||{}).checked,p_created_by:(RW_STATE.app.currentUser||{}).email||null}).then(function(r){if(r.error)throw r.error;if(!r.data||!r.data.success)throw new Error((r.data&&r.data.error)||"فشل إنشاء السيارة");return r.data;});}}).then(function(r){if(r.isConfirmed)render();});}\n  return {render:render,openCreate:openCreate};\n})();\nwindow.RW_Fleet=RW_Fleet;\n'''
    s=s.replace(a,a+block,1)

if "if (view === 'vehicles') { RW_Fleet.render(); return; }" not in s:
    a="        if (view === 'audit-log') { RW_Audit_renderTab(); return; }"
    if a not in s: raise SystemExit("P0_ABORT route anchor")
    s=s.replace(a,"        if (view === 'vehicles') { RW_Fleet.render(); return; }\n"+a,1)

# OWNER contract: preserve isOwner + wildcard; never create wildcard as a fallback.
s=s.replace("RW_STATE.permissions = meta.permissions || ['*'];", "RW_STATE.permissions = Array.isArray(meta.permissions) ? meta.permissions.slice() : [];")

if "window.RW_OwnerContract" not in s:
    a="window.RW_Settings = RW_Settings;"
    block=r'''\nvar RW_OwnerContract=(function(){\n  function isOwner(){\n    var u=RW_STATE.app.currentUser||{};\n    return u.isOwner===true && Array.isArray(RW_STATE.permissions) && RW_STATE.permissions.indexOf('*')!==-1;\n  }\n  return {isOwner:isOwner};\n})();\nwindow.RW_OwnerContract=RW_OwnerContract;\n'''
    if a not in s: raise SystemExit("P0_ABORT settings export anchor")
    s=s.replace(a,a+block,1)

# Owner-only license route.
s=s.replace(
    "if (view === 'license') { RW_OwnerLicense.render(); return; }",
    "if (view === 'license') { if (!RW_OwnerContract.isOwner()) { showToast('هذه الشاشة متاحة لمالك النظام فقط', 'error'); return; } RW_OwnerLicense.render(); return; }"
)

# Add missing currency to settings state; retain historical fields for read compatibility but backend will whitelist.
s=s.replace(
    "tax_rate: appSets.tax_rate || 0,\n                    company_name:",
    "tax_rate: appSets.tax_rate || 0,\n                    currency: appSets.currency || 'SAR',\n                    company_name:",1
)

# Restore and bind the real app_settings-backed store/company identity panel.
if "RW_SettingsIdentity" not in s:
    a="window.RW_Settings = RW_Settings;"
    block=r'''\nvar RW_SettingsIdentity=(function(){\n  function esc(v){return String(v==null?'':v).replace(/[&<>\"]/g,function(m){return{'&':'&amp;','<':'&lt;','>':'&gt;',\"\":'&quot;'}[m]||m;});}\n  async function render(){\n    var container=byId('rw-page-container'); if(!container)return;\n    var cid=RW_ShellContext.getCompanyId();\n    var res=await supabase.from('app_settings').select('company_id,company_name,company_phone,company_logo,store_name,store_logo,store_primary_color,store_secondary_color,payment_method,currency,delivery_fee,min_invoice_amount,tax_rate').eq('company_id',cid).order('created_at',{ascending:true}).limit(1).maybeSingle();\n    if(res.error)throw res.error;\n    var s=res.data||{};\n    var old=byId('rw-restored-identity-card'); if(old)old.remove();\n    var card=document.createElement('div'); card.id='rw-restored-identity-card'; card.className='bg-white rounded-2xl shadow-sm border p-6 mt-6';\n    var logo=s.company_logo||s.store_logo||'';\n    card.innerHTML='<h3 class="text-lg font-black text-blue-600 border-b pb-2 mb-4"><i class="fa-solid fa-id-card ml-2"></i>هوية النظام والمتجر</h3>'+\n      '<p class="text-sm text-gray-500 mb-4">هذه البيانات مرتبطة مباشرة بـ app_settings للشركة الحالية.</p>'+\n      '<div class="grid grid-cols-1 md:grid-cols-2 gap-4">'+\n      '<label class="text-sm font-bold">اسم المشروع/الشركة<input id="rw-id-company-name" class="w-full mt-1 p-2.5 bg-gray-50 border rounded-lg" value="'+esc(s.company_name||'')+'"></label>'+\n      '<label class="text-sm font-bold">هاتف الشركة<input id="rw-id-company-phone" class="w-full mt-1 p-2.5 bg-gray-50 border rounded-lg" value="'+esc(s.company_phone||'')+'"></label>'+\n      '<label class="text-sm font-bold">اسم المتجر<input id="rw-id-store-name" class="w-full mt-1 p-2.5 bg-gray-50 border rounded-lg" value="'+esc(s.store_name||s.company_name||'')+'"></label>'+\n      '<label class="text-sm font-bold">شعار المتجر (URL)<input id="rw-id-store-logo" class="w-full mt-1 p-2.5 bg-gray-50 border rounded-lg" value="'+esc(s.store_logo||'')+'"></label>'+\n      '<label class="text-sm font-bold">اللون الأساسي<input id="rw-id-primary" type="text" class="w-full mt-1 p-2.5 bg-gray-50 border rounded-lg" value="'+esc(s.store_primary_color||'')+'"></label>'+\n      '<label class="text-sm font-bold">اللون الثانوي<input id="rw-id-secondary" type="text" class="w-full mt-1 p-2.5 bg-gray-50 border rounded-lg" value="'+esc(s.store_secondary_color||'')+'"></label>'+\n      '<label class="text-sm font-bold">طريقة الدفع<input id="rw-id-payment" class="w-full mt-1 p-2.5 bg-gray-50 border rounded-lg" value="'+esc(s.payment_method||'')+'"></label>'+\n      '<label class="text-sm font-bold">العملة<input id="rw-id-currency" class="w-full mt-1 p-2.5 bg-gray-50 border rounded-lg" value="'+esc(s.currency||'')+'"></label>'+\n      '</div>'+\n      (logo?'<div class="mt-4 flex items-center gap-3"><img src="'+esc(logo)+'" class="w-16 h-16 rounded-xl object-contain border bg-gray-50"><span class="text-xs text-gray-500">الشعار المحفوظ حاليًا</span></div>':'')+\n      '<div class="flex justify-end mt-5"><button id="rw-id-save" class="px-6 py-2.5 bg-blue-600 text-white rounded-xl font-bold">حفظ الهوية والإعدادات</button></div>';\n    container.appendChild(card);\n    byId('rw-id-save').onclick=save;\n  }\n  async function save(){\n    var payload={\n      company_name:(byId('rw-id-company-name')||{}).value||'',\n      company_phone:(byId('rw-id-company-phone')||{}).value||'',\n      store_name:(byId('rw-id-store-name')||{}).value||'',\n      store_logo:(byId('rw-id-store-logo')||{}).value||null,\n      store_primary_color:(byId('rw-id-primary')||{}).value||null,\n      store_secondary_color:(byId('rw-id-secondary')||{}).value||null,\n      payment_method:(byId('rw-id-payment')||{}).value||null,\n      currency:(byId('rw-id-currency')||{}).value||null\n    };\n    showLoader('جاري حفظ هوية النظام...');\n    try{\n      var ses=await supabase.auth.getSession(); var token=ses.data&&ses.data.session?ses.data.session.access_token:null;\n      if(!token)throw new Error('SESSION_UNAVAILABLE');\n      var res=await fetch(RW_SUPABASE_URL+'/functions/v1/save-settings',{method:'POST',headers:{'Content-Type':'application/json','Authorization':'Bearer '+token},body:JSON.stringify(payload)});\n      var json=await res.json();\n      if(!res.ok||!json.success)throw new Error(json.error||json.msg||'فشل حفظ الإعدادات');\n      await RW_ShellBranding.load();\n      showToast('تم حفظ هوية النظام والمتجر','success');\n    }catch(e){showToast('فشل حفظ الإعدادات: '+(e.message||e),'error');}\n    finally{hideLoader();}\n  }\n  return {render:render,save:save};\n})();\nwindow.RW_SettingsIdentity=RW_SettingsIdentity;\nvar _rwSettingsRender=RW_Settings.render;\nRW_Settings.render=async function(){\n  await _rwSettingsRender.apply(this,arguments);\n  await RW_SettingsIdentity.render();\n};\n'''
    s=s.replace(a,a+block,1)

# Branding bridge: authenticated tenant -> app_settings -> shell/login identity.
if "window.RW_ShellBranding" not in s:
    a="window.RW_OwnerContract=RW_OwnerContract;"
    block=r'''\nvar RW_ShellBranding=(function(){\n  async function load(){\n    var cid=RW_ShellContext.getCompanyId();\n    var r=await supabase.from('app_settings').select('company_name,company_logo,company_phone,store_name,store_logo,store_primary_color,store_secondary_color,payment_method,currency').eq('company_id',cid).order('created_at',{ascending:true}).limit(1).maybeSingle();\n    if(r.error||!r.data)return null;\n    var x=r.data;\n    RW_STATE.app.company={\n      name:x.company_name||'الروائع ERP',logo:x.company_logo||'ر',phone:x.company_phone||'',\n      storeName:x.store_name||x.company_name||'الروائع ERP',storeLogo:x.store_logo||x.company_logo||'',\n      primaryColor:x.store_primary_color||'',secondaryColor:x.store_secondary_color||'',\n      paymentMethod:x.payment_method||'',currency:x.currency||'SAR'\n    };\n    safeText(byId('rw-sidebar-company-name'),RW_STATE.app.company.name);\n    safeText(byId('rw-company-name'),RW_STATE.app.company.name);\n    var sideLogo=byId('rw-sidebar-brand-logo'); if(sideLogo&&RW_STATE.app.company.logo&&String(RW_STATE.app.company.logo).indexOf('data:')!==0)sideLogo.src=RW_STATE.app.company.logo;\n    var loginLogo=byId('rw-login-logo'); if(loginLogo&&RW_STATE.app.company.logo&&String(RW_STATE.app.company.logo).indexOf('http')===0){loginLogo.style.backgroundImage='url("'+RW_STATE.app.company.logo.replace(/"/g,'')+'")';loginLogo.style.backgroundSize='contain';loginLogo.style.backgroundRepeat='no-repeat';} \n    return x;\n  }\n  return {load:load};\n})();\nwindow.RW_ShellBranding=RW_ShellBranding;\nvar _rwBrandEnterSystem=RW_Auth.enterSystem;\nRW_Auth.enterSystem=function(){\n  var ctx=this,args=arguments;\n  return RW_ShellContext.resolve().then(function(){return RW_ShellBranding.load();}).then(function(){return _rwBrandEnterSystem.apply(ctx,args);});\n};\n'''
    if a not in s: raise SystemExit("P0_ABORT owner contract anchor")
    s=s.replace(a,a+block,1)

# Fail closed: no bootstrap bypass.
pat=r"\s*forceEnterFallback:\s*function\(\)\s*\{.*?\n\s*\},\n\s*logout:\s*function\(\)"
m=re.search(pat,s,re.S)
if not m: raise SystemExit("P0_ABORT forceEnterFallback anchor")
replacement=r'''\n    forceEnterFallback: function() {\n        hideLoader();\n        console.error('RAWAEA_BOOTSTRAP_FAIL_CLOSED');\n        try {\n            var lp = byId('rw-login-page'), sh = byId('rw-main-shell');\n            if (lp) lp.style.display = 'flex';\n            if (sh) sh.style.display = 'none';\n            showToast('تعذر تشغيل النظام والتحقق من سياقه. يرجى إعادة المحاولة.', 'error');\n        } catch(e) {\n            document.body.innerHTML = '<div style="min-height:100vh;display:flex;align-items:center;justify-content:center;flex-direction:column;font-family:Cairo;"><h1>RAWAEA ERP</h1><p>تعذر التحقق من بيئة التشغيل</p><button onclick="location.reload()">إعادة التحميل</button></div>';\n        }\n    },\n    logout: function('''
s=s[:m.start()]+replacement+s[m.end():]

if re.search(r"\.from\('app_settings'\)\.select\('\*'\)\.limit\(1\)",s):
    raise SystemExit("P0_ABORT global app_settings remains")
if "meta.permissions || ['*']" in s:
    raise SystemExit("P0_ABORT wildcard fallback remains")
if "RW_SettingsIdentity" not in s or "RW_ShellBranding" not in s:
    raise SystemExit("P0_ABORT identity bridge missing")
if s==orig:
    raise SystemExit("P0_ABORT no change")
p.write_text(s,encoding="utf-8")
print("P0_PATCHED",len(orig),len(s))
