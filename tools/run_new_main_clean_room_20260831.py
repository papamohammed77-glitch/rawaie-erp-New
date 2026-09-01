from pathlib import Path
import hashlib
import re
import subprocess
import tempfile

TARGET = Path('Current/PWA/New-main')
LEGACY = Path('Current/PWA/main.html')


def sha(text):
    return hashlib.sha256(text.encode('utf-8')).hexdigest()


def inline_script(html):
    matches = [
        m for m in re.finditer(r'<script(?P<a>[^>]*)>(?P<b>[\s\S]*?)</script>', html, re.I)
        if not re.search(r'\bsrc\s*=', m.group('a') or '', re.I)
    ]
    if len(matches) != 1:
        raise RuntimeError('INLINE_SCRIPT_COUNT_INVALID:' + str(len(matches)))
    return matches[0]


def validate(html):
    required = [
        'rw-login-page','rw-main-shell','rw-page-container','rw-header-title','rw-header-subtitle',
        'rw-sidebar-nav','rw-logout-btn','window.RW_ShellContext','window.RW_OwnerLicense',
        'window.RW_Views','window.RW_Dashboard','window.RW_Items','window.RW_POS','window.RW_Orders',
        'window.RW_Runsheets','window.RW_Purchases','window.RW_Warehouse','window.RW_Finance',
        'window.RW_Reports','window.RW_HR','window.RW_CRM','btn-save-license-only',"{view:'license'",
        'license:RW_OwnerLicense.render','_clickNotif','_renderAndSave','_updateBadge','markRead',
        'RAWAEA GOLD DIAMOND FINAL v7'
    ]
    missing = [x for x in required if x not in html]
    if missing:
        raise RuntimeError('TARGET_CONTRACT_MISSING:' + ','.join(missing))
    if html.lower().count('</html>') != 1 or html.lower().count('</body>') != 1:
        raise RuntimeError('DOCUMENT_CLOSURE_INVALID')
    js = inline_script(html).group('b')
    check = Path(tempfile.gettempdir()) / 'rawaea_new_main_final.js'
    check.write_text(js, encoding='utf-8')
    result = subprocess.run(['node', '--check', str(check)], capture_output=True, text=True)
    if result.returncode:
        print(result.stderr)
        raise RuntimeError('TARGET_JS_SYNTAX_FAIL')


def build():
    if not TARGET.exists() or TARGET.stat().st_size == 0:
        raise RuntimeError('NEW_MAIN_MISSING')
    if not LEGACY.exists() or LEGACY.stat().st_size == 0:
        raise RuntimeError('LEGACY_MAIN_MISSING')

    baseline = TARGET.read_text(encoding='utf-8')
    legacy_hash = sha(LEGACY.read_text(encoding='utf-8'))
    script = inline_script(baseline)
    body = script.group('b').replace("\\\\'", "\\'")

    patch = r'''\n/* RAWAEA GOLD DIAMOND FINAL v7 */\n(function(){\n  'use strict';\n  var S=window.RW_STATE,A=window.RW_Auth,N=window.RW_Navigation,Q=window.RW_Notification;\n  if(!S||!A||!N)throw new Error('GOLD_DIAMOND_PREREQUISITES_MISSING');\n  function owner(){return !!(S.app&&S.app.currentUser&&S.app.currentUser.isOwner===true)}\n  function can(v){if(v==='license'||v==='audit'||v==='audit-log')return owner();if(owner())return true;var p={users:'users',roles:'roles',settings:'settings',hr:'users',crm:'customers',notifications:'notifications'}[v];if(!p)return true;try{return typeof window.RW_Permissions_check==='function'&&window.RW_Permissions_check(p)===true}catch(e){return false}}\n  if(typeof A.forceEnterFallback==='function'&&!A.__gdFailClosedV7){var fb=A.forceEnterFallback,en=A.enterSystem;A.forceEnterFallback=function(){try{S.app.initialized=false;S.app.authenticated=false;S.app.currentUser=null;S.app.companyId=null;S.app.ownerProfile=null;S.app.licenseState='unknown';S.permissions=[]}catch(e){}return fb.apply(this,arguments)};A.enterSystem=async function(u){try{return await en.call(this,u)}catch(e){try{this.forceEnterFallback()}catch(x){}throw e}};A.__gdFailClosedV7=true}\n  if(Q){function em(){return S.app&&S.app.currentUser?S.app.currentUser.email:null}Q._updateBadge=Q._updateBadge||async function(){var x=em();if(!x)return 0;var r=await supabase.from('notifications').select('id',{count:'exact',head:true}).eq('user_email',x).eq('is_read',false);if(r.error)throw r.error;var b=document.getElementById('rw-notification-badge'),n=r.count||0;if(b){b.textContent=n>99?'99+':String(n);b.style.display=n?'grid':'none'}return n};Q.markRead=Q.markRead||async function(id){var x=em();if(!id||!x)return;var r=await supabase.from('notifications').update({is_read:true}).eq('id',id).eq('user_email',x);if(r.error)throw r.error;return Q._updateBadge()};Q._clickNotif=Q._clickNotif||async function(id,table){try{await Q.markRead(id)}catch(e){}var map={orders:'orders',runsheets:'runsheets',customers:'customers',items:'items',suppliers:'suppliers',purchases:'purchases',vouchers:'vouchers',returns:'return'};var v=map[String(table||'').toLowerCase()];return v&&N.navigate?N.navigate(v):null};Q._renderAndSave=Q._renderAndSave||async function(tpl,vars,email){if(!tpl)throw new Error('NOTIFICATION_TEMPLATE_REQUIRED');vars=vars||{};var title=String(tpl.title_template||''),body=String(tpl.body_template||'');Object.keys(vars).forEach(function(k){var r=new RegExp('#\\{'+k+'\\}','g');title=title.replace(r,String(vars[k]==null?'':vars[k]));body=body.replace(r,String(vars[k]==null?'':vars[k]))});var to=email||em();if(!to)return null;var q=await supabase.from('notifications').insert({user_email:to,title:title,body:body,type:tpl.type||'info',reference_table:vars.reference_table||vars.table||null,reference_id:vars.reference_id||vars.id||null,is_read:false}).select('id').maybeSingle();if(q.error)throw q.error;await Q._updateBadge();return q.data||null}}\n  var T=[{label:'لوحة التحكم',view:'dashboard'},{label:'إدارة المبيعات',submenu:[{label:'التلي سيلز',view:'telesales'},{label:'العملاء',view:'customers'},{label:'المتجر الإلكتروني',view:'online-store'},{label:'نقطة البيع',view:'pos'},{label:'أوردرات المبيعات',view:'orders'},{label:'الرانشيتات',view:'runsheets'}]},{label:'إدارة المشتريات',submenu:[{label:'الموردين',view:'suppliers'},{label:'نقطة شراء',view:'purchase-pos'},{label:'أوردرات الشراء',view:'purchases'}]},{label:'إدارة المخازن والمخزون',submenu:[{label:'الأصناف',view:'items'},{label:'المخازن والفروع',view:'branches'},{label:'العمليات المخزنية',submenu:[{label:'الاستلام',view:'receiving'},{label:'التحضير',view:'picking'},{label:'التحميل',view:'loading'},{label:'التوصيل',view:'delivery'},{label:'المرتجعات',view:'return'},{label:'التفريغ',view:'unloading'}]},{label:'الأذونات المخزنية',submenu:[{label:'تحويل مخزني',view:'transfer'},{label:'صرف سيارة بيع مباشر',view:'direct-sale'},{label:'استلام مرتجع سيارة',view:'direct-return'},{label:'مرتجع لمورد',view:'supplier-return'},{label:'عرض الأذونات',view:'vouchers'}]},{label:'الجرد',submenu:[{label:'جرد سيارة',view:'vehicle-count'},{label:'جرد فرع',view:'branch-count'},{label:'جرد عام',view:'general-count'}]}]},{label:'إدارة الحسابات والمالية',submenu:[{label:'الخزائن والبنوك',action:'showFinanceTab',arg:'treasury'},{label:'دليل الحسابات',action:'showFinanceTab',arg:'accounts'},{label:'قيود يومية',action:'showFinanceTab',arg:'journal'},{label:'سندات القبض',action:'showFinanceTab',arg:'receipts'},{label:'سندات الصرف',action:'showFinanceTab',arg:'payments'},{label:'التحويلات',action:'showFinanceTab',arg:'transfers'},{label:'التقارير المالية',action:'showFinanceTab',arg:'reports'},{label:'إغلاق اليومية',view:'settlement'}]},{label:'التقارير الذكية',submenu:[{label:'لوحة القيادة',view:'reports-dashboard'},{label:'التقارير التفصيلية',view:'reports-detailed'},{label:'التقارير الشاملة',view:'reports-comprehensive'}]},{label:'الموارد البشرية',view:'hr'},{label:'إدارة علاقات العملاء (CRM)',view:'crm'},{label:'المستخدمين والصلاحيات',view:'users'},{label:'إدارة أدوار المستخدمين',view:'roles'},{label:'إدارة الترخيص',view:'license'},{label:'إعدادات النظام',view:'settings'},{label:'سجل التدقيق',view:'audit-log'},{label:'الإشعارات',view:'notifications'}];\n  N.menuTree=T;\n  N._handleAction=function(a,arg){if(a!=='showFinanceTab')throw new Error('UNKNOWN_NAV_ACTION:'+a);if(!can('finance'))throw new Error('PERMISSION_DENIED');if(!window.RW_Finance||typeof window.RW_Finance.renderSubTab!=='function')throw new Error('FINANCE_SUBTAB_HANDLER_MISSING');return window.RW_Finance.renderSubTab(arg||'treasury')};\n  N.buildSidebar=function(){var root=document.getElementById('rw-sidebar-nav');if(!root)return;root.textContent='';function d(parent,a){(a||[]).forEach(function(x){if(x.submenu){var h=document.createElement('div');h.className='rw-sidebar-link';h.textContent=x.label;var c=document.createElement('div');c.className='rw-sidebar-submenu';d(c,x.submenu);if(!c.childNodes.length)return;h.onclick=function(){c.style.display=c.style.display==='none'?'block':'none'};parent.appendChild(h);parent.appendChild(c);return}if(x.action){if(!can('finance'))return;var b=document.createElement('button');b.className='rw-sidebar-link';b.type='button';b.textContent=x.label;b.onclick=function(){N._handleAction(x.action,x.arg)};parent.appendChild(b);return}if(x.view&&!can(x.view))return;var b=document.createElement('button');b.className='rw-sidebar-link';b.type='button';b.textContent=x.label;b.onclick=function(){N.navigate(x.view)};parent.appendChild(b)})}d(root,T)};\n  N.navigate=async function(v){S.app.currentView=v;if(!can(v))throw new Error((v==='license'||v==='audit'||v==='audit-log')?'OWNER_ONLY':'PERMISSION_DENIED');if(v==='audit'||v==='audit-log')return window.RW_Audit_renderTab();if(v==='transfer')return window.RW_Warehouse.loadVoucherForm('Transfer');if(v==='direct-sale')return window.RW_Warehouse.loadVoucherForm('DirectSale');if(v==='direct-return')return window.RW_Warehouse.loadVoucherForm('DirectReturn');if(v==='supplier-return')return window.RW_Warehouse.loadVoucherForm('SupplierReturn');if(v==='pos'&&window.RW_POS&&typeof window.RW_POS.open==='function')return window.RW_POS.open();if(v==='purchases'&&window.RW_Purchases&&typeof window.RW_Purchases.open==='function')return window.RW_Purchases.open();if(v==='notifications'&&Q&&typeof Q.showPanel==='function')return Q.showPanel();if(v==='finance'&&window.RW_Finance&&typeof window.RW_Finance.render==='function')return window.RW_Finance.render();if(v==='reports-dashboard'&&window.RW_Reports&&typeof window.RW_Reports.renderDashboard==='function')return window.RW_Reports.renderDashboard();if(v==='reports-detailed'&&window.RW_Reports&&typeof window.RW_Reports.renderDetailedReports==='function')return window.RW_Reports.renderDetailedReports();if(v==='reports-comprehensive'&&window.RW_Reports_Comprehensive&&typeof window.RW_Reports_Comprehensive.render==='function')return window.RW_Reports_Comprehensive.render();if(v==='hr'&&window.RW_HR&&typeof window.RW_HR.render==='function')return window.RW_HR.render();if(v==='crm'&&window.RW_CRM&&typeof window.RW_CRM.render==='function')return window.RW_CRM.render();return window.RW_Views.render(v)};\n  if(window.RW_Workflow&&typeof window.RW_Workflow.loadRules==='function'&&!window.RW_Workflow.__gdOwnerOnlyV7){var lr=window.RW_Workflow.loadRules;window.RW_Workflow.loadRules=async function(){if(!owner())throw new Error('OWNER_ONLY_WORKFLOW_RULES');return lr.apply(this,arguments)};window.RW_Workflow.__gdOwnerOnlyV7=true}\n  window.RW_GOLD_DIAMOND={version:'v7',target:'Current/PWA/New-main',chain:'MAIN1-MAIN11',navigation:'complete',notification:'complete',owner:'strict',audit:'owner-only',session:'fail-closed',tenant:'RW_ShellContext',finance_actions:'complete',routes:'complete',stock_authority:'canonical-core'};\n})();\n'''

    if 'RAWAEA GOLD DIAMOND FINAL v7' not in body:
        body += patch

    candidate = baseline[:script.start('b')] + body + baseline[script.end('b'):]
    validate(candidate)
    if sha(LEGACY.read_text(encoding='utf-8')) != legacy_hash:
        raise RuntimeError('LEGACY_MAIN_HTML_CHANGED')
    TARGET.write_text(candidate, encoding='utf-8')
    print({'status':'READY_TO_PERSIST','baseline_sha256':sha(baseline),'candidate_sha256':sha(candidate),'target':'Current/PWA/New-main'})


if __name__ == '__main__':
    build()
