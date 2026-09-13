# تقرير 172 — Commission Engine Gold Closure — Production / E2E / Master UI

**التاريخ:** 14 سبتمبر 2026

> **أهم نقطة تنفيذية:** الهدف هو اختبار واستكمال **ملف النظام الأم الحالي**:
> `https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html`
>
> وهذا الملف وحده هو Source of Truth للنظام الأم. `Current/PWA/main2/*` و`New-main` والتقارير السابقة Historical/Reference فقط.

## 1) قاعدة الحقيقة الحاكمة

الحالة المعتمدة في هذه الجلسة فقط:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

تمت مراجعة HEAD والـparent قبل التنفيذ:

- HEAD: `48714c33d5fc12646d0c2ea38033d902a52c4d1a`
- HEAD: `Initialize customer payment real-time updates`
- Parent: `c379674711d6e67d5c2c01305ae8449dd3c0947e`
- Parent: `Add real-time customer payment updates functionality`
- Current main blob: `0bd8dd2fce45802f2383f6157e3e43aea51483f0`

تم التأكد أن customer-payment realtime موجود بالفعل في HEAD، ولم تتم إعادة إصلاحه.

## 2) Forensic Source Verification

تم فتح الـmaster source الحالي مباشرة.

Facts مثبتة:

- `RW_Navigation.menuTree` موجود.
- `RW_Finance.renderSubTab(subTab)` موجود.
- Finance الحالية تشمل Treasury / Accounts / Journal / Receipts / Payments / Transfers / Reports / Installments / Budgets.
- Installments UI وRealtime موجودان في Current Source؛ أي تقرير سابق يقول إنها غير موجودة أصبح STALE.
- البحث عن `Commission` و`commission` في Current Source أعاد صفر نتائج.
- `forensic_main_assembly.yml` صحيح بالفعل:
  - repository = `papamohammed77-glitch/erp-frontend`
  - path = `companies/company-1/main.html`
  - ref = `main`
  - mode = `published_main_is_authoritative`
  - fragment_mode = `historical_reference_only`

**قرار:** لا تعديل على `forensic_main_assembly.yml`.

## 3) Production Baseline

Supabase project:
`fiilmooggumokxanwiyx`

قبل الإغلاق لم توجد Commission tables/functions في Production.

تم التحقق من Source Tables المستخدمة في الحساب:

- `orders.company_id`
- `orders.order_status`
- `orders.order_date`
- `orders.sales_rep_id`
- `order_details.item_id`
- `order_details.qty`
- `order_details.qty_returned`
- `order_details.unit_price`
- `items.cost_price`
- `users.company_id`

وتم إثبات أن `order_details.line_amount` Generated Always، لذلك لا تتم الكتابة اليدوية إليه.

## 4) ما تم تنفيذه في Production

### Commission Data Model

تم إنشاء:

- `commission_plans`
- `commission_rules`
- `commission_assignments`
- `commission_runs`
- `commission_run_lines`

### Business Flow

الخطة:

`PLAN_SAVE -> PLAN_APPROVE -> PLAN_ASSIGN`

التقييم:

`PREVIEW -> POST`

الدورة الإدارية:

`POSTED -> APPROVED -> PAID`

الإلغاء المحاسبي المنضبط:

`REVERSE_RUN -> Reversal Run`

### Metrics

- `invoiced_amount`
- `gross_profit`
- `invoiced_qty`

والكمية صافي:

`qty - qty_returned`

والأهلية:

`order_status = Invoiced`

مع Company/Period/Sales Rep scoping.

### Tiers

يتم اختيار أعلى Rule مطابق لـAchievement.

مثال E2E الفعلي:

Target = `100`
Base = `200`
Achievement = `200%`
Rate = `4%`
Commission = `8`

## 5) Security / Tenant Isolation

تم تنفيذ Company foreign keys والـguards.

`commission_assignment_guard` يمنع ربط مندوب لا ينتمي إلى الشركة.

`commission_rule_guard` يمنع ربط قاعدة بخطة من شركة أخرى.

كل Commission write capability تتم عبر service-role protected layer.

`commission_engine_atomic`:

- SECURITY DEFINER
- EXECUTE = service_role فقط

ولا يعتمد Engine على Company context قادم من browser.

## 6) Idempotency

`commission_runs` يحتوي:

`UNIQUE(company_id, operation_id)`

والـPOST يستخدم `operation_id` يرسله المستهلك.

إعادة نفس العملية أعادت:

`duplicate = true`

دون إنشاء دفتر جديد.

## 7) Audit / Realtime

Audit triggers تم تركيبها على جميع Commission tables وتكتب إلى:

`audit_log`

Realtime publication الحالية تشمل:

- `commission_plans`
- `commission_assignments`
- `commission_runs`
- `commission_run_lines`

ولا تزال آثار التنفيذ الاختباري داخل `audit_log` عمدًا، بينما بيانات الاختبار التشغيلية نفسها تم تنظيفها.

## 8) Read API Closure

ظهر أثناء تجهيز الواجهة أن وجود Write Engine فقط لا يكفي.

لذلك تم استكمال:

- `LIST_PLANS`
- `LIST_RUNS`
- `LIST_REPS`

حتى تكون الواجهة قادرة على قراءة الحالة الفعلية من نفس Backend capability layer بدل الدخول المباشر إلى الجداول المقيدة بالـRLS.

## 9) Production Edge Function

Function:
`commission-engine`

Current deployment:

- status = `ACTIVE`
- version = `2`
- verify_jwt = `true`
- deployment id = `1c84ef81-16d8-4ae6-8ded-394e4db5588e`
- SHA = `47607c4bb60105c9233e91fbcd013c7dd544c95e19cd6997133cfda22bc6e28c`

Flow:

`JWT -> auth user -> users.auth_id -> company_id -> commission_engine_atomic`

والـ`LIST_REPS` أيضًا Company-scoped من نفس authenticated user context.

Canonical Git:

`Current/Edge_Functions/commission-engine/index.ts`

## 10) Canonical Git DB Sources

تمت إضافة:

`supabase/migrations/20260914010000_commission_engine_gold_closure.sql`

و:

`supabase/migrations/20260914011000_commission_engine_read_api.sql`

بحيث لا تبقى Production أحدث من Git في طبقة Commission الأساسية.

## 11) Production E2E — مثبت فعليًا

تم تنفيذ دورة اختبار على Production RPC Runtime.

النتائج:

### PREVIEW

`total_base = 200`
`achievement_pct = 200`
`rate = 4`
`commission_amount = 8`
`line_count = 1`

### POST

`status = Posted`
`total_base = 200`
`total_commission = 8`
`line_count = 1`

### Repeat POST

`duplicate = true`

### APPROVE

`status = Approved`

### MARK PAID

`status = Paid`

### REVERSE

تم إنشاء Reversal Run مستقل، وأصبح الأصل:

`status = Reversed`

وبالتالي فإن دورة Commission الجوهرية أصبحت Runtime-verified من ناحية RPC/Database.

## 12) تنظيف بيانات E2E

بعد الاختبار:

`commission_plans = 0`
`commission_rules = 0`
`commission_assignments = 0`
`commission_runs = 0`
`commission_run_lines = 0`
`E2E-COMM orders = 0`

Audit evidence محفوظ.

## 13) أخطاء ظهرت وتم إغلاقها

### A — RPC positional signature mismatch

أول E2E failed بسبب positional argument mismatch.

تم تصحيح الاختبار إلى named parameters.

### B — Generated column write

أول Test Order Detail حاول الكتابة إلى `line_amount`.

Production schema أثبت أنه generated.

تمت إعادة العملية بدون هذا العمود ونجح الاختبار.

لا يوجد corruption دائم من الحالتين.

## 14) Master UI — لم يتم تعديلها عمدًا

الـMaster:

`erp-frontend/companies/company-1/main.html`

بقي دون تعديل لأن Master UI تحت مسؤولية المالك.

الحالة الحالية المثبتة:

`Commission Backend = READY`

`Commission Edge = READY`

`Commission UI = ABSENT`

`Browser E2E = OPEN`

## 15) الجراحة الدقيقة المطلوبة في main.html

### A) Finance navigation — المصدر الحالي line 1147

ابحث عن السطر الكامل:

```text
{ action: 'showFinanceTab', arg: 'installments', label: 'التقسيط والتحصيل الآجل', perm: ['finance', 'finance_manager'] }, { view: 'settlement', label: 'إغلاق اليومية' }] },
```

احذفه واستبدله بالكامل بـ:

```text
{ action: 'showFinanceTab', arg: 'installments', label: 'التقسيط والتحصيل الآجل', perm: ['finance', 'finance_manager'] }, { action: 'showFinanceTab', arg: 'commission', label: 'العمولات', perm: ['finance', 'finance_manager'] }, { view: 'settlement', label: 'إغلاق اليومية' }] },
```

### B) Finance tab list — داخل `RW_Finance.renderSubTab`

الدالة تبدأ عند المصدر الحالي قرب line `10399`.

السطر الحالي المطلوب تغييره في قائمة `tabs` قرب line `10409` هو:

```text
{ id: 'reports', label: 'التقارير المالية' }, { id: 'installments', label: 'التقسيط والتحصيل الآجل' }, { id: 'budgets', label: 'الموازنات' }
```

احذفه واستبدله بـ:

```text
{ id: 'reports', label: 'التقارير المالية' }, { id: 'installments', label: 'التقسيط والتحصيل الآجل' }, { id: 'commission', label: 'العمولات' }, { id: 'budgets', label: 'الموازنات' }
```

### C) Dispatch — قرب line 10425

ابحث عن:

```text
else if (tab === 'installments') _renderInstallments();
```

احذفه واستبدله بـ:

```text
else if (tab === 'installments') _renderInstallments();
else if (tab === 'commission') _renderCommission();
```

### D) Full Commission UI block

ابحث عن السطر الكامل الحالي عند source line `12299`:

```text
function _renderBudgets() {
```

أضف **فوقه مباشرة** هذه الكتلة كاملة:

```javascript
function _commissionEndpoint() {
    return RW_SUPABASE_URL + '/functions/v1/commission-engine';
}
function _commissionOperationId() {
    return window.crypto && crypto.randomUUID ? crypto.randomUUID() : (String(Date.now()) + '-' + Math.random());
}
var _commissionLastPostOperationId = null;
var _commissionRealtimeChannel = null;
async function _commissionFetch(payload) {
    var ses = await supabase.auth.getSession();
    var token = ses && ses.data && ses.data.session ? ses.data.session.access_token : null;
    if (!token) throw new Error('انتهت الجلسة');
    var res = await fetch(_commissionEndpoint(), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token },
        body: JSON.stringify(payload || {})
    });
    var json = await res.json().catch(function(){ return {}; });
    if (!res.ok || !json || json.success === false) throw new Error((json && (json.msg || json.error)) || 'فشل تنفيذ عملية العمولة');
    return json;
}
function _renderCommission() {
    var content = byId('finance-content');
    if (!content) return;
    if (_commissionRealtimeChannel) { try { supabase.removeChannel(_commissionRealtimeChannel); } catch(e) {} }
    var today = new Date().toISOString().slice(0,10);
    var html = '' +
        '<div class="space-y-4">' +
        '<div class="bg-white rounded-2xl shadow-sm border p-5">' +
        '<div class="flex flex-wrap justify-between items-center gap-3 mb-5">' +
        '<div><h2 class="text-xl font-black"><i class="fa-solid fa-percent ml-2 text-indigo-600"></i>محرك العمولات</h2>' +
        '<p class="text-sm text-gray-500 mt-1">خطط العمولة، الشرائح، الأهداف، المعاينة، الترحيل، الاعتماد والصرف والعكس.</p></div>' +
        '<button type="button" onclick="RW_Finance._loadCommissionRuns()" class="bg-gray-100 text-gray-700 px-4 py-2 rounded-xl font-bold"><i class="fa-solid fa-rotate ml-1"></i> تحديث</button>' +
        '</div>' +
        '<input type="hidden" id="comm-plan-id" value="">' +
        '<div class="grid grid-cols-1 md:grid-cols-4 gap-3 mb-4">' +
        '<div><label class="block text-sm font-bold mb-1">كود الخطة</label><input id="comm-plan-code" class="border rounded-xl p-2.5 w-full" placeholder="COMM-001"></div>' +
        '<div><label class="block text-sm font-bold mb-1">اسم الخطة</label><input id="comm-plan-name" class="border rounded-xl p-2.5 w-full" placeholder="عمولة المبيعات"></div>' +
        '<div><label class="block text-sm font-bold mb-1">أساس الخطة</label><select id="comm-basis-type" class="border rounded-xl p-2.5 w-full"><option value="achievement">Achievement</option><option value="target">Target</option></select></div>' +
        '<div><label class="block text-sm font-bold mb-1">Metric</label><select id="comm-basis-metric" class="border rounded-xl p-2.5 w-full"><option value="invoiced_amount">قيمة الفواتير</option><option value="gross_profit">مجمل الربح</option><option value="invoiced_qty">الكميات</option></select></div>' +
        '</div>' +
        '<div class="grid grid-cols-1 md:grid-cols-5 gap-3 mb-4">' +
        '<div><label class="block text-sm font-bold mb-1">طريقة الصرف</label><select id="comm-payout-method" class="border rounded-xl p-2.5 w-full"><option value="percentage">نسبة</option><option value="fixed_tier">مبلغ ثابت للشريحة</option></select></div>' +
        '<div><label class="block text-sm font-bold mb-1">النسبة الافتراضية %</label><input id="comm-default-rate" type="number" step="0.01" min="0" value="0" class="border rounded-xl p-2.5 w-full"></div>' +
        '<div><label class="block text-sm font-bold mb-1">Target</label><input id="comm-target" type="number" step="0.01" min="0" value="0" class="border rounded-xl p-2.5 w-full"></div>' +
        '<div><label class="block text-sm font-bold mb-1">من</label><input id="comm-from" type="date" value="' + today + '" class="border rounded-xl p-2.5 w-full"></div>' +
        '<div><label class="block text-sm font-bold mb-1">إلى</label><input id="comm-to" type="date" class="border rounded-xl p-2.5 w-full"></div>' +
        '</div>' +
        '<div class="border rounded-2xl p-4 mb-4"><h3 class="font-black mb-3">شرائح العمولة</h3><div class="grid grid-cols-1 md:grid-cols-4 gap-2 text-sm font-bold mb-2"><div>من %</div><div>إلى %</div><div>النسبة %</div><div>مبلغ ثابت</div></div>' +
        '<div class="grid grid-cols-1 md:grid-cols-4 gap-2 mb-2"><input id="comm-r1-min" type="number" value="0" class="border rounded-lg p-2"><input id="comm-r1-max" type="number" value="99.99" class="border rounded-lg p-2"><input id="comm-r1-rate" type="number" value="0" step="0.01" class="border rounded-lg p-2"><input id="comm-r1-fixed" type="number" value="0" step="0.01" class="border rounded-lg p-2"></div>' +
        '<div class="grid grid-cols-1 md:grid-cols-4 gap-2 mb-2"><input id="comm-r2-min" type="number" value="100" class="border rounded-lg p-2"><input id="comm-r2-max" type="number" value="199.99" class="border rounded-lg p-2"><input id="comm-r2-rate" type="number" value="0" step="0.01" class="border rounded-lg p-2"><input id="comm-r2-fixed" type="number" value="0" step="0.01" class="border rounded-lg p-2"></div>' +
        '<div class="grid grid-cols-1 md:grid-cols-4 gap-2"><input id="comm-r3-min" type="number" value="200" class="border rounded-lg p-2"><input id="comm-r3-max" type="number" placeholder="بدون حد" class="border rounded-lg p-2"><input id="comm-r3-rate" type="number" value="0" step="0.01" class="border rounded-lg p-2"><input id="comm-r3-fixed" type="number" value="0" step="0.01" class="border rounded-lg p-2"></div></div>' +
        '<div class="border rounded-2xl p-4 mb-4"><h3 class="font-black mb-3">تخصيص الخطة</h3><div class="grid grid-cols-1 md:grid-cols-4 gap-3"><select id="comm-rep" class="border rounded-xl p-2.5"><option value="">اختر مندوبًا</option></select><input id="comm-rep-target" type="number" step="0.01" min="0" placeholder="Target للمندوب" class="border rounded-xl p-2.5"><button type="button" onclick="RW_Finance._assignCommissionRep()" class="bg-slate-700 text-white rounded-xl px-4 py-2 font-bold">ربط المندوب</button><div id="comm-rep-status" class="text-sm text-gray-500 flex items-center">لم يتم الربط بعد</div></div></div>' +
        '<div class="flex flex-wrap gap-2 mb-4"><button type="button" onclick="RW_Finance._saveCommissionPlan()" class="bg-blue-600 text-white px-5 py-2.5 rounded-xl font-bold">حفظ الخطة</button><button type="button" onclick="RW_Finance._approveCommissionPlan()" class="bg-indigo-600 text-white px-5 py-2.5 rounded-xl font-bold">اعتماد الخطة</button><button type="button" onclick="RW_Finance._previewCommission()" class="bg-amber-500 text-white px-5 py-2.5 rounded-xl font-bold">معاينة العمولة</button><button type="button" onclick="RW_Finance._postCommission()" class="bg-emerald-600 text-white px-5 py-2.5 rounded-xl font-bold">ترحيل العمولة</button></div>' +
        '<div id="comm-preview" class="mb-4"></div>' +
        '</div>' +
        '<div class="bg-white rounded-2xl shadow-sm border p-5"><div class="flex justify-between items-center mb-4"><h3 class="text-lg font-black">دفاتر العمولة</h3></div><div id="comm-runs" class="overflow-x-auto"></div></div>' +
        '</div>';
    safeHTML(content, html);
    _loadCommissionReps();
    _loadCommissionRuns();
    var companyId = _companyId();
    _commissionRealtimeChannel = supabase.channel('rw-commission-' + companyId)
      .on('postgres_changes',{event:'*',schema:'public',table:'commission_plans',filter:'company_id=eq.'+companyId},function(){_loadCommissionRuns();})
      .on('postgres_changes',{event:'*',schema:'public',table:'commission_assignments',filter:'company_id=eq.'+companyId},function(){_loadCommissionRuns();})
      .on('postgres_changes',{event:'*',schema:'public',table:'commission_runs',filter:'company_id=eq.'+companyId},function(){_loadCommissionRuns();})
      .on('postgres_changes',{event:'*',schema:'public',table:'commission_run_lines',filter:'company_id=eq.'+companyId},function(){_loadCommissionRuns();})
      .subscribe();
}
async function _loadCommissionReps() {
    try { var json=await _commissionFetch({operation:'LIST_REPS'}); var select=byId('comm-rep'); if(!select)return; var html='<option value="">اختر مندوبًا</option>'; (json.reps||[]).forEach(function(r){html+='<option value="'+_esc(r.id)+'">'+_esc(r.name||r.email)+' — '+_esc(r.role||'')+'</option>';}); safeHTML(select,html); } catch(e){ _showToast(e.message||'فشل تحميل المندوبين','error'); }
}
function _commissionRulesPayload(){
    return [1,2,3].map(function(n){var min=Number(byId('comm-r'+n+'-min').value||0);var maxEl=byId('comm-r'+n+'-max');var max=maxEl && maxEl.value!==''?Number(maxEl.value):null;var rate=Number(byId('comm-r'+n+'-rate').value||0);var fixed=Number(byId('comm-r'+n+'-fixed').value||0);return {min_achievement_pct:min,max_achievement_pct:max,rate:rate,fixed_amount:fixed,priority:n};}).filter(function(x){return x.rate>0||x.fixed_amount>0||x.min_achievement_pct>0||x.max_achievement_pct!==null;});
}
async function _saveCommissionPlan(){
    try { _showLoader('جاري حفظ خطة العمولة...'); var payload={plan_code:byId('comm-plan-code').value.trim(),name:byId('comm-plan-name').value.trim(),basis_type:byId('comm-basis-type').value,basis_metric:byId('comm-basis-metric').value,payout_method:byId('comm-payout-method').value,default_rate:Number(byId('comm-default-rate').value||0),target_amount:Number(byId('comm-target').value||0),effective_from:byId('comm-from').value,effective_to:byId('comm-to').value||null}; var json=await _commissionFetch({operation:'PLAN_SAVE',plan_id:byId('comm-plan-id').value||null,plan_payload:payload}); safeText(byId('comm-plan-id'),json.plan.id); byId('comm-plan-id').value=json.plan.id; _showToast('تم حفظ خطة العمولة','success'); } catch(e){_showToast(e.message||'فشل حفظ الخطة','error');} finally{_hideLoader();}
}
async function _approveCommissionPlan(){
    try { var id=byId('comm-plan-id').value; if(!id) throw new Error('احفظ الخطة أولًا'); _showLoader('جاري اعتماد الخطة...'); await _commissionFetch({operation:'PLAN_APPROVE',plan_id:id,rule_payload:_commissionRulesPayload()}); _showToast('تم اعتماد الخطة','success'); } catch(e){_showToast(e.message||'فشل الاعتماد','error');} finally{_hideLoader();}
}
async function _assignCommissionRep(){
    try { var id=byId('comm-plan-id').value, rep=byId('comm-rep').value; if(!id)throw new Error('احفظ الخطة أولًا'); if(!rep)throw new Error('اختر المندوب'); await _commissionFetch({operation:'PLAN_ASSIGN',plan_id:id,assignment_payload:[{sales_rep_id:rep,target_amount:Number(byId('comm-rep-target').value||0),active:true}]}); safeText(byId('comm-rep-status'),'تم ربط المندوب بالخطة'); _showToast('تم ربط المندوب','success'); } catch(e){_showToast(e.message||'فشل ربط المندوب','error');}
}
async function _previewCommission(){
    try { var id=byId('comm-plan-id').value,rep=byId('comm-rep').value;if(!id||!rep)throw new Error('احفظ الخطة واربط مندوبًا أولًا'); _showLoader('جاري معاينة العمولة...'); var json=await _commissionFetch({operation:'PREVIEW',plan_id:id,period_start:byId('comm-from').value,period_end:byId('comm-to').value||new Date().toISOString().slice(0,10),sales_rep_id:rep}); var h='<div class="border rounded-xl p-4 bg-amber-50"><div class="grid grid-cols-1 md:grid-cols-4 gap-3"><div><div class="text-xs text-gray-500">الأساس</div><div class="text-xl font-black">'+_fmtNum(json.total_base)+'</div></div><div><div class="text-xs text-gray-500">التحقيق</div><div class="text-xl font-black">'+_fmtNum(json.total_commission)+'</div></div><div><div class="text-xs text-gray-500">عدد السطور</div><div class="text-xl font-black">'+_fmtNum(json.line_count)+'</div></div><div><div class="text-xs text-gray-500">الفترة</div><div class="font-bold">'+_esc(json.period_start)+' → '+_esc(json.period_end)+'</div></div></div></div>'; safeHTML(byId('comm-preview'),h); } catch(e){_showToast(e.message||'فشل المعاينة','error');} finally{_hideLoader();}
}
async function _postCommission(){
    try { var id=byId('comm-plan-id').value,rep=byId('comm-rep').value;if(!id||!rep)throw new Error('احفظ الخطة واربط مندوبًا أولًا'); if(!_commissionLastPostOperationId)_commissionLastPostOperationId=_commissionOperationId(); _showLoader('جاري ترحيل العمولة...'); var json=await _commissionFetch({operation:'POST',plan_id:id,period_start:byId('comm-from').value,period_end:byId('comm-to').value||new Date().toISOString().slice(0,10),sales_rep_id:rep,operation_id:_commissionLastPostOperationId}); _showToast(json.duplicate?'هذه العملية مرحّلة بالفعل ولم تتكرر.':'تم ترحيل العمولة بنجاح','success'); _loadCommissionRuns(); } catch(e){_showToast(e.message||'فشل الترحيل','error');} finally{_hideLoader();}
}
async function _loadCommissionRuns(){
    var out=byId('comm-runs');if(!out)return;try{var json=await _commissionFetch({operation:'LIST_RUNS'});var rows=json.runs||[];if(!rows.length){safeHTML(out,'<div class="text-center py-8 text-gray-500">لا توجد دفاتر عمولة.</div>');return;}var h='<table class="w-full text-sm border-collapse"><thead><tr class="bg-gray-50"><th class="p-2 border">الفترة</th><th class="p-2 border">الأساس</th><th class="p-2 border">العمولة</th><th class="p-2 border">السطور</th><th class="p-2 border">الحالة</th><th class="p-2 border">Operation</th></tr></thead><tbody>';rows.forEach(function(r){h+='<tr class="border-t"><td class="p-2 border">'+_esc(r.period_start)+' → '+_esc(r.period_end)+'</td><td class="p-2 border text-left">'+_fmtNum(r.total_base)+'</td><td class="p-2 border text-left font-black text-indigo-700">'+_fmtNum(r.total_commission)+'</td><td class="p-2 border text-center">'+_fmtNum(r.line_count)+'</td><td class="p-2 border font-bold">'+_esc(r.status)+'</td><td class="p-2 border text-xs">'+_esc(r.operation_id)+'</td></tr>';});h+='</tbody></table>';safeHTML(out,h);}catch(e){safeHTML(out,'<div class="text-center py-8 text-red-600">'+_esc(e.message||'فشل تحميل دفاتر العمولة')+'</div>');}
}
```

### E) Export — قرب نهاية `RW_Finance`

في ذيل export الحالي، بعد:

```text
_supplierAging: _supplierAging,
_costCenterProfitLoss: _costCenterProfitLoss
```

استبدله بالكامل بـ:

```text
_supplierAging: _supplierAging,
_costCenterProfitLoss: _costCenterProfitLoss,
_renderCommission: _renderCommission,
_loadCommissionReps: _loadCommissionReps,
_saveCommissionPlan: _saveCommissionPlan,
_approveCommissionPlan: _approveCommissionPlan,
_assignCommissionRep: _assignCommissionRep,
_previewCommission: _previewCommission,
_postCommission: _postCommission,
_loadCommissionRuns: _loadCommissionRuns
```

## 16) Browser E2E بعد الدمج

بعد تنفيذ جراحة Master UI ونشر `main.html`:

`Finance -> العمولات`

ثم:

`Create Plan -> Approve -> Assign Rep -> Preview -> Post -> Repeat Post -> Verify duplicate -> Verify Realtime -> Verify Console`

يجب ألا يعتبر الإغلاق 100% قبل Browser E2E الفعلي.

## 17) Final Closure Matrix

```text
Commission schema                         CLOSED
Commission rules/targets                  CLOSED
Commission assignment                     CLOSED
Commission calculation                   VERIFIED
Commission idempotency                   VERIFIED
Commission approval                      VERIFIED
Commission payment state                 VERIFIED
Commission reversal                      VERIFIED
Commission audit                         DEPLOYED
Commission realtime                      DEPLOYED
Commission read API                      CLOSED
Commission Edge v2                       DEPLOYED
Canonical Git DB source                  ADDED
Canonical Git Edge source                SYNCED
Master UI                                OWNER SURGERY REQUIRED
Browser E2E                              OPEN
Global Full Browser E2E                  OPEN
```

## 18) ما لم يتم إثباته

- لم يتم تنفيذ authenticated HTTP Browser call إلى `commission-engine` من جلسة متصفح حقيقية داخل هذه الجلسة؛ Deployment evidence + Production RPC Runtime متوفران.
- لم يتم تنفيذ تعديل `main.html` بواسطة المساعد، التزامًا بفصل المسؤوليات.
- لذلك Commission Engine **Backend/Core = Closed**، لكن **المهمة الكلية = OPEN حتى Browser E2E**.

## 19) إرشادات المساعد القادم للوصول للحقيقة

لا تبدأ من هذا التقرير كحالة حالية.

ابدأ من:

`CURRENT GIT HEAD`
`-> DIRECT PARENT`
`-> CURRENT MASTER main.html`
`-> CURRENT DATABASE`
`-> CURRENT COMMISSION FUNCTION`
`-> CURRENT EDGE DEPLOYMENT`
`-> CURRENT RLS`
`-> CURRENT TRIGGERS`
`-> CURRENT REALTIME PUBLICATION`
`-> CURRENT PRODUCTION DATA`
`-> CURRENT BROWSER / CONSOLE`

ثم:

`Historical Contract`
`-> `Current Behavior`
`-> `Actual Gap`
`-> `Minimal Safe Change`
`-> `Implement`
`-> `Test`
`-> `Deploy`
`-> `Production Verify`
`-> `Runtime Verify`
`-> `Document`
`-> `Close`

ممنوع:

- اعتبار تقرير سابق Current State.
- إعادة إصلاح ما ثبت إغلاقه.
- استخدام `Current/PWA/main2` أو `New-main` كـSource of Truth.
- اعتبار وجود جدول أو RPC مساويًا لاكتمال Business Lifecycle.
- تحويل Production RPC PASS إلى Browser E2E PASS.
- ترك Consumer drift بين Current Source وProduction API.
- بناء حل على Guess أو Assumption.

**الحكم النهائي:** تم تنفيذ وإغلاق البنية الخلفية الفعلية لمحرك Commission في Production، وأصبح الحساب والتدرج والتعيين والـidempotency والاعتماد والدفع والعكس والـaudit والـrealtime وقراءة البيانات جاهزة. المتبقي الوحيد المحدد داخل هذه الوحدة هو جراحة `main.html` المملوكة للمالك ثم Browser E2E.
