from pathlib import Path
import re

p=Path("Current/PWA/main.html")
s=p.read_text(encoding="utf-8")
orig=s

for a in ["window.RW_STATE = RW_STATE;","window.RW_Navigation = RW_Navigation;","window.RW_Views = RW_Views;","var RW_Views = {"]:
    if a not in s: raise SystemExit("P0_ABORT missing "+a)

if "window.RW_ShellContext" not in s:
    a="window.RW_Navigation = RW_Navigation;"
    block=r'''\nvar RW_ShellContext=(function(){\n  var companyId=null, resolving=null;\n  function resolve(){\n    if(companyId)return Promise.resolve(companyId);\n    if(resolving)return resolving;\n    var u=RW_STATE.app.currentUser||{};\n    if(!u.email)return Promise.reject(new Error("AUTH_USER_UNAVAILABLE"));\n    resolving=supabase.from("users").select("id,company_id,name,role,status")\n      .eq("email",u.email).eq("status","Active").maybeSingle().then(function(r){\n        if(r.error||!r.data||!r.data.company_id)throw new Error("TENANT_CONTEXT_UNAVAILABLE");\n        companyId=r.data.company_id; RW_STATE.app.companyId=companyId; RW_STATE.app.userId=r.data.id||null;\n        if(RW_STATE.app.currentUser){RW_STATE.app.currentUser.company_id=companyId;if(r.data.name)RW_STATE.app.currentUser.name=r.data.name;if(r.data.role)RW_STATE.app.currentUser.role=r.data.role;}\n        return companyId;\n      }).finally(function(){resolving=null;});\n    return resolving;\n  }\n  function getCompanyId(){if(!companyId&&RW_STATE.app.companyId)companyId=RW_STATE.app.companyId;if(!companyId)throw new Error("TENANT_CONTEXT_UNAVAILABLE");return companyId;}\n  return {resolve:resolve,getCompanyId:getCompanyId,hasCompany:function(){return !!(companyId||(RW_STATE.app&&RW_STATE.app.companyId));}};\n})();\nwindow.RW_ShellContext=RW_ShellContext;\nvar _rwParentEnterSystem=RW_Auth.enterSystem;\nRW_Auth.enterSystem=function(){var a=arguments;if(RW_ShellContext.hasCompany())return _rwParentEnterSystem.apply(this,a);return RW_ShellContext.resolve().then(function(){return _rwParentEnterSystem.apply(this,a);}.bind(this));};\n'''
    s=s.replace(a,a+block,1)

s=re.sub(r"\.from\('app_settings'\)(?P<t>\s*\.select\([^;]*?\))(?P<u>\s*\.limit\(1\))(?P<v>\.single\(\))?",
         lambda m: ".from('app_settings')"+m.group('t')+".eq('company_id',RW_ShellContext.getCompanyId())"+m.group('u')+(m.group('v') or ''), s)

for t in ("customers","branches","suppliers","users"):
    s=re.sub(rf"supabase\.from\('{t}'\)\.select\('\*'\)(?!\.eq\('company_id')",
             f"supabase.from('{t}').select('*').eq('company_id',RW_ShellContext.getCompanyId())",s)

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

if re.search(r"\.from\('app_settings'\)\.select\('\*'\)\.limit\(1\)",s):
    raise SystemExit("P0_ABORT global app_settings remains")
if s==orig: raise SystemExit("P0_ABORT no change")
p.write_text(s,encoding="utf-8")
print("P0_PATCHED",len(orig),len(s))
