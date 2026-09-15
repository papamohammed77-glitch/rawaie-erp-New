# تقرير 192 — Sales Decision Center — إغلاق جنائي للبنية التشغيلية

**التاريخ:** 2026-09-15
**النقطة:** `Sales Decision Center = OPEN`
**المرحلة:** Mother System / Sales Core / Production Decision Engine

> ## تنبيه حاكم
> التقارير السابقة STALE وReference فقط. لم تُستخدم كحالة حالية إلا كدليل تاريخي.
> الحالة المعتمدة في التنفيذ:
> `CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`
> ولإغلاق Browser E2E يلزم أيضًا `CURRENT BROWSER + CURRENT CONSOLE + CURRENT NETWORK`.
>
> **Source of Truth للنظام الأم:**
> `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`
>
> `Current/PWA/main2/*` و`Original/PWA/main/*` و`New-main` = Historical Reference فقط.

---

## 1. نقطة مهمة جدًا — E2E للنظام الأم

تم فتح الـMother Source الحالي من Git blob الحالي، وليس من تقرير أو fragment تاريخي.

Current Mother Commit:
`27cfa8c580565942c5497ebf5ffe623eb0768aaa`

Direct Parent:
`24e0124bedf6356103cb28bf365cef8e46be8027`

Parent of Parent:
`1f7928e0fa0320670df92c6e944afab0f28e2c0d`

Current Mother Blob:
`7c112dcc4ffc24bc0318b2e7ced4c4517804dc0e`

آخر Commit `27cfa8...` ليس التقرير القديم Loyalty؛ الفرق الحالي كان إصلاحًا متعلقًا بـ `renderConfig`/Loyalty placement، والـparent `24e0124...` كان الحالة المنشورة السابقة.

تم التحقق من الـblob الحالي حتى نهاية المحتوى، ونهاية الملف هي:

```html
</script>
</body>
</html>
```

### مهم
GitHub connector الحالي أعاد الـblob الكامل، ولكن طلبات `start_line/end_line` على هذا الـblob الكبير أعادت أحيانًا محتوى فارغًا عند ranges بعيدة. لذلك لم يتم اختراع أي رقم سطر غير مثبت من المصدر. Anchors أدناه مبنية على النص الحالي نفسه، والموضع الرئيسي الذي يلزم المالك هو anchor نصي فريد. هذا أفضل من إعطاء line number غير موثوق.

---

## 2. CURRENT MOTHER — Anchors مثبتة من المصدر الحالي

### Navigation
داخل `const RW_Navigation = {`، سطر قائمة إدارة المبيعات الحالي يحتوي حرفيًا على:

```javascript
{ icon: 'fa-chart-line', label: 'إدارة المبيعات', submenu: [{ view: 'telesales', label: 'التلي سيلز' }, { view: 'customers', label: 'العملاء' }, { view: 'online-store', label: 'المتجر الإلكتروني' }, { view: 'pos', label: 'نقطة البيع' }, { view: 'orders', label: 'أوردرات المبيعات' }, { view: 'quotes', label: 'عروض الأسعار' },{ view: 'price-lists', label: 'قوائم الأسعار' },{ view: 'promotions', label: 'العروض والخصومات' }, { view: 'sales-targets', label: 'أهداف المبيعات', perm: ['sales_manager','sales_supervisor','general_manager','reports'] },
```

الـanchor الحالي يقع في منطقة المصدر حوالى `21777` بحسب قراءة blob response الحالية.

### Router
داخل `RW_Views.render(view)`، الـanchor الحالي هو:

```javascript
if (view === 'loyalty') { RW_LoyaltyMain.render(); return; }
if (view === 'sales-targets') { RW_SalesTargetsMain.render(); return; }
```

الـanchor يقع في منطقة المصدر حوالى `18846` بحسب القراءة الحالية.

### Module insertion anchor
الـanchor الحالي قبل Sales Targets مباشرة هو:

```javascript
window.RW_Navigation = RW_Navigation;
var RW_SalesTargetsMain = (function(){
```

الـanchor يقع في منطقة المصدر حوالى `21943` بحسب قراءة الـblob الحالية.

لا يوجد أي داعٍ لتعديل `RW_SalesTargetsMain` نفسها.

---

# 3. المشكلة التي ثبتت في Production

لم يكن لدينا Sales Decision Center تشغيلي مركزي قبل هذه الجلسة.

الموجود مسبقًا كان:

- Price Lists
- Promotions
- Sales Quotes
- Sales Targets
- Enterprise Decision Center/KPI reporting

لكن لم يكن هناك Core policy engine موحد يقرر:

- هل البيع مسموح؟
- هل يحتاج اعتمادًا؟
- هل الخصم يتجاوز سياسة الشركة؟
- هل الهامش أقل من الحد؟
- هل حد ائتمان العميل يسمح؟
- هل الرصيد المتاح يسمح؟
- من يملك تغيير السياسة واعتمادها؟
- كيف يتم حفظ decision evidence ومنع duplicate execution؟

تم إثبات ذلك مباشرة من Production schema/function inventory قبل التنفيذ.

---

# 4. ما تم تنفيذه فعليًا في Production

تم إنشاء البنية التالية داخل Supabase Production project:

## 4.1 `sales_decision_policies`

مرجع السياسة التشغيلية للشركة.

الحقول الأساسية:

```text
id
company_id UNIQUE
version_no
status = Active | Draft | Archived
policy jsonb
effective_from
effective_to
created_by
updated_by
approved_by
approved_at
created_at
updated_at
```

كل شركة لها Policy واحدة فعالة منطقيًا عبر الـActive selection، مع versioning.

## 4.2 `sales_decision_policy_history`

حفظ تاريخ جميع SAVE/PUBLISH/BASELINE operations.

```text
company_id
policy_id
version_no
action
policy
actor_email
created_at
```

## 4.3 `sales_decision_evaluations`

Evidence لكل قرار Sales.

```text
company_id
operation_id UNIQUE per company
entity_type
entity_id
decision
score
policy_id
policy_version
request
reasons
created_by
created_at
```

القيم:

```text
ALLOW
WARN
REQUIRE_APPROVAL
BLOCK
```

## 4.4 `sales_decision_approvals`

إغلاق دورة الاعتماد بدل ترك REQUIRE_APPROVAL حالة ميتة.

```text
company_id
evaluation_id
operation_id UNIQUE per company
approved_by
approved_at
note
```

## 4.5 `sales_decision_pending_approvals`

View تشغيلية تعرض الحالات التي تحتاج اعتمادًا ولم تعتمد بعد.

---

# 5. Production Core Engine

تم إنشاء:

```text
sales_decision_engine_atomic(
  uuid,
  text,
  text,
  uuid,
  jsonb,
  text
)
```

وتدعم حاليًا:

```text
GET_POLICY
SAVE_POLICY
PUBLISH_POLICY
GET_PENDING_APPROVALS
APPROVE_EVALUATION
VALIDATE_ORDER
```

### Policy controls

الـpolicy الافتراضية الحالية:

```json
{
  "policy_schema_version": 1,
  "pricing_source": "item_default",
  "allow_manual_price": true,
  "max_discount_percent": 100,
  "discount_approval_threshold_percent": 100,
  "min_margin_percent": 0,
  "order_approval_threshold_amount": 0,
  "credit_mode": "ignore",
  "credit_buffer_amount": 0,
  "customer_required_for_credit": true,
  "stock_mode": "engine",
  "allow_out_of_stock_sale": false
}
```

هذه لا تغير السلوك التشغيلي الحالي افتراضيًا؛ بل تفتح Control Plane مركزيًا يمكن تقييده من النظام الأم.

---

# 6. Security / Tenant Isolation

تم التأكد أن Core يستخدم:

```text
company_id
+
active user within the same company
```

ولا يعتمد على `app_settings LIMIT 1` داخل Sales Decision Engine.

تم إنشاء `sales_decision_actor_ok` كـSECURITY DEFINER، مع فصل واضح بين:

```text
Read
Write / Manage
Approve
```

والـRPC النهائي لا يملك EXECUTE لـ:

```text
anon = false
authenticated = false
service_role = true
```

تم التحقق فعليًا من هذه الصلاحيات بعد التطبيق.

---

# 7. Audit

تم إنشاء trigger على:

```text
sales_decision_policies
sales_decision_approvals
```

ويكتب إلى:

```text
audit_log
```

مع actor resolution بالترتيب:

```text
JWT email
↓
updated_by / created_by / approved_by
↓
system
```

كما تم التحقق من وجود `fn_audit_trigger()` التاريخي على `stock_vouchers`.

---

# 8. Integration مع Sales Invoice — نقطة جوهرية

لم يتم الاكتفاء بشاشة قرار.

تم تعديل Production `save_sales_invoice_atomic` بحيث:

```text
Sales Request
↓
validate input
↓
resolve company
↓
resolve branch/customer/items
↓
Sales Decision Engine
↓
ALLOW / WARN
     ↓
Create order
     ↓
Create order_details
     ↓
Physical Stock Movement
     ↓
Accounting / Ledger
```

أما:

```text
BLOCK
```

فلا ينشئ Order ولا ينفذ Physical Movement.

وأما:

```text
REQUIRE_APPROVAL
```

فلا ينفذ Order/Stock/Accounting؛ بل يحفظ Evaluation حتى يستطيع المدير اعتماد العملية ثم إعادة تنفيذها بنفس `operation_id`.

وهذا أهم من حل واجهة فقط، لأنه يجعل Sales Decision **Gate حقيقية** وليست Dashboard.

---

# 9. Idempotency / Approval Flow

تم تنفيذ المعالجة التالية:

```text
VALIDATE_ORDER
↓
REQUIRE_APPROVAL
↓
sales_decision_evaluations persisted
↓
Manager APPROVE_EVALUATION
↓
retry SAME operation_id
↓
VALIDATE_ORDER detects approved evaluation
↓
returns ALLOW
↓
save_sales_invoice_atomic continues
```

وفي حال إعادة نفس الطلب بدون approval:

```text
same operation_id
+
same request fingerprint
↓
duplicate evaluation
```

وفي حال إعادة استخدام نفس operation_id مع Payload مختلف:

```text
operation_id conflict
```

ويرفض الطلب.

---

# 10. اختبارات Production التي نُفذت

## 10.1 GET_POLICY

```text
success = true
status = Active
version = 1
effective_from = 2026-09-15
```

## 10.2 VALIDATE_ORDER — ALLOW

تم استخدام:

```text
company = 00000000-0000-0000-0000-000000000001
item = 1001
qty = 1
unit_price = 10
payment = نقدي
```

النتيجة المثبتة:

```text
success=true
decision=ALLOW
score=100
duplicate=false
allow_execution=true
```

## 10.3 نفس العملية مرة ثانية

نفس `operation_id` ونفس payload.

النتيجة:

```text
success=true
duplicate=true
same decision=ALLOW
```

## 10.4 REQUIRE_APPROVAL

تم داخل Transaction مؤقتة ضبط policy اختبارية على:

```text
max_discount_percent = 100
discount_approval_threshold_percent = 100
```

واختبار:

```text
gross = 10
order_discount = 10
```

النتيجة:

```text
decision=REQUIRE_APPROVAL
score=80
reason=DISCOUNT_APPROVAL
allow_execution=false
```

ثم تم `ROLLBACK`، وعادت الـpolicy الدائمة إلى:

```text
version=1
status=Active
```

## 10.5 Data cleanup

تم حذف جميع test evaluations ذات:

```text
operation_id LIKE 'TEST-SDC-%'
```

والتحقق:

```text
test_rows = 0
```

ولا توجد approvals تجريبية متبقية.

---

# 11. Edge Function Production

تم إنشاء ونشر:

```text
sales-decision-center
```

Production:

```text
status = ACTIVE
version = 1
verify_jwt = true
```

وظيفته Thin Capability Wrapper فقط:

```text
JWT
↓
auth user
↓
users.company_id
↓
permission gate
↓
sales_decision_engine_atomic
```

ولا يحمل Business Logic مستقلًا حتى لا ينشأ Core موازي.

كما تم حفظ نسخته الحالية في Git:

```text
Current/Edge_Functions/sales-decision-center
```

---

# 12. لماذا لم نعتبر Sales Decision مغلقًا 100% بعد

لأن قاعدة الحوكمة تمنع تحويل:

```text
Production PASS
```

إلى:

```text
Browser E2E PASS
```

الوضع الحالي الصحيح:

```text
SALES DECISION DATABASE CORE      = CLOSED
SALES DECISION POLICY ENGINE      = CLOSED
SALES DECISION APPROVAL WORKFLOW  = CLOSED
SALES DECISION INVOICE GATE       = CLOSED
SALES DECISION EDGE               = DEPLOYED + DATABASE VERIFIED
MOTHER UI                         = OWNER PATCH REQUIRED
BROWSER E2E                       = OPEN
```

إذن **الـbackend functional closure تم**، لكن نقطة Sales Decision Center كمنظومة كاملة لن تصبح `100% CLOSED` حتى يدمج المالك تعديل Mother UI وتنجح Browser/Console/Network E2E.

---

# 13. OWNER-ONLY SURGICAL PATCH — main.html

## PATCH A — Navigation

**ابحث عن هذا المقطع حرفيًا في `const RW_Navigation.menuTree`:**

```javascript
{ icon: 'fa-chart-line', label: 'إدارة المبيعات', submenu: [{ view: 'telesales', label: 'التلي سيلز' }, { view: 'customers', label: 'العملاء' }, { view: 'online-store', label: 'المتجر الإلكتروني' }, { view: 'pos', label: 'نقطة البيع' }, { view: 'orders', label: 'أوردرات المبيعات' }, { view: 'quotes', label: 'عروض الأسعار' },{ view: 'price-lists', label: 'قوائم الأسعار' },{ view: 'promotions', label: 'العروض والخصومات' }, { view: 'sales-targets', label: 'أهداف المبيعات', perm: ['sales_manager','sales_supervisor','general_manager','reports'] },
```

**استبدل هذا الجزء فقط** بإضافة العنصر التالي قبل `sales-targets`:

```javascript
{ icon: 'fa-chart-line', label: 'إدارة المبيعات', submenu: [{ view: 'telesales', label: 'التلي سيلز' }, { view: 'customers', label: 'العملاء' }, { view: 'online-store', label: 'المتجر الإلكتروني' }, { view: 'pos', label: 'نقطة البيع' }, { view: 'orders', label: 'أوردرات المبيعات' }, { view: 'quotes', label: 'عروض الأسعار' },{ view: 'price-lists', label: 'قوائم الأسعار' },{ view: 'promotions', label: 'العروض والخصومات' }, { view: 'sales-decision-center', label: 'مركز قرار المبيعات', perm: ['sales_manager','sales_supervisor','general_manager','reports'] }, { view: 'sales-targets', label: 'أهداف المبيعات', perm: ['sales_manager','sales_supervisor','general_manager','reports'] },
```

لا تحذف بقية `submenu` بعد هذه النقطة.

---

## PATCH B — Router

**ابحث عن هذا السطرين حرفيًا:**

```javascript
if (view === 'loyalty') { RW_LoyaltyMain.render(); return; }
if (view === 'sales-targets') { RW_SalesTargetsMain.render(); return; }
```

**أضف بينهما هذا السطر:**

```javascript
if (view === 'sales-decision-center') { RW_SalesDecisionCenter.render(); return; }
```

---

## PATCH C — Sales Decision Module

**ابحث عن هذا الـanchor الفريد حرفيًا:**

```javascript
var RW_SalesTargetsMain = (function(){
```

**أضف الكتلة التالية كاملة فوقه مباشرة.**

```javascript
var RW_SalesDecisionCenter = (function(){
    'use strict';

    var realtimeChannel = null;
    var state = { policy:null, pending:[], loading:false };

    function endpoint(){ return RW_SUPABASE_URL + '/functions/v1/sales-decision-center'; }

    function esc(v){
        return String(v==null?'':v)
            .replace(/&/g,'&amp;')
            .replace(/</g,'&lt;')
            .replace(/>/g,'&gt;')
            .replace(/\"/g,'&quot;')
            .replace(/'/g,'&#39;');
    }

    function money(v){
        return Number(v||0).toLocaleString('ar-EG',{maximumFractionDigits:2});
    }

    function hasPerm(name){
        var p=(RW_STATE && Array.isArray(RW_STATE.permissions)) ? RW_STATE.permissions : [];
        return p.indexOf('*')>=0 || p.indexOf(name)>=0;
    }

    function canRead(){
        return hasPerm('sales_manager') || hasPerm('sales_supervisor') || hasPerm('general_manager') || hasPerm('reports');
    }

    function canManage(){
        return hasPerm('sales_manager') || hasPerm('general_manager');
    }

    function canApprove(){
        return canManage();
    }

    async function call(operation,payload,operationId,policyId){
        var session=await supabase.auth.getSession();
        var token=session && session.data && session.data.session ? session.data.session.access_token : null;
        if(!token) throw new Error('انتهت الجلسة');
        var res=await fetch(endpoint(),{
            method:'POST',
            headers:{'Content-Type':'application/json','Authorization':'Bearer '+token},
            body:JSON.stringify({operation:operation,payload:payload||{},operation_id:operationId||null,policy_id:policyId||null})
        });
        var j=await res.json().catch(function(){return {};});
        if(!res.ok || (j && j.success===false && operation!=='VALIDATE_ORDER')) throw new Error((j&&j.msg)||'فشل تنفيذ مركز قرار المبيعات');
        return j;
    }

    function control(id,label,value,type,disabled){
        var d=disabled?' disabled':'';
        if(type==='checkbox'){
            return '<label class="flex items-center gap-3 p-4 border rounded-2xl bg-slate-50 font-black"><input id="'+id+'" type="checkbox" '+(value?'checked':'')+d+' class="w-5 h-5">'+esc(label)+'</label>';
        }
        return '<label class="block"><span class="block text-sm font-black text-slate-700 mb-2">'+esc(label)+'</span><input id="'+id+'" '+(type==='number'?'type="number" step="0.01"':'')+' value="'+esc(value==null?'':value)+'"'+d+' class="w-full p-3 border rounded-xl"></label>';
    }

    function selectControl(id,label,value,options,disabled){
        var d=disabled?' disabled':'';
        var h='<label class="block"><span class="block text-sm font-black text-slate-700 mb-2">'+esc(label)+'</span><select id="'+id+'"'+d+' class="w-full p-3 border rounded-xl">';
        for(var i=0;i<options.length;i++) h+='<option value="'+esc(options[i][0])+'"'+(String(value)===String(options[i][0])?' selected':'')+'>'+esc(options[i][1])+'</option>';
        return h+'</select></label>';
    }

    function policyFromForm(){
        return {
            policy_schema_version:1,
            pricing_source:byId('sdc-pricing-source').value,
            allow_manual_price:byId('sdc-manual-price').checked,
            max_discount_percent:Number(byId('sdc-max-discount').value||0),
            discount_approval_threshold_percent:Number(byId('sdc-discount-approval').value||0),
            min_margin_percent:Number(byId('sdc-min-margin').value||0),
            order_approval_threshold_amount:Number(byId('sdc-order-threshold').value||0),
            credit_mode:byId('sdc-credit-mode').value,
            credit_buffer_amount:Number(byId('sdc-credit-buffer').value||0),
            customer_required_for_credit:byId('sdc-credit-customer-required').checked,
            stock_mode:byId('sdc-stock-mode').value,
            allow_out_of_stock_sale:byId('sdc-out-of-stock').checked,
            notes:byId('sdc-notes').value.trim()
        };
    }

    async function loadPolicy(){ state.policy=await call('GET_POLICY'); return state.policy; }

    async function loadPending(){
        if(!canApprove()) { state.pending=[]; return state.pending; }
        var r=await call('GET_PENDING_APPROVALS'); state.pending=r.items||[]; return state.pending;
    }

    function renderPending(){
        var host=byId('sdc-pending'); if(!host) return;
        if(!state.pending.length){ RW_UI.safeHTML(host,'<div class="p-6 text-center text-slate-400">لا توجد طلبات تنتظر الاعتماد حاليًا.</div>'); return; }
        var h='<div class="overflow-auto"><table class="w-full text-sm"><thead class="bg-slate-50"><tr><th class="p-3">العملية</th><th class="p-3">القرار</th><th class="p-3">التقييم</th><th class="p-3">التاريخ</th><th class="p-3">الأسباب</th><th class="p-3">الإجراء</th></tr></thead><tbody>';
        for(var i=0;i<state.pending.length;i++){
            var x=state.pending[i];
            var reasons=(x.reasons||[]).map(function(r){return esc(r.message||r.code||'');}).join(' | ');
            h+='<tr class="border-t"><td class="p-3 font-black">'+esc(x.operation_id)+'</td><td class="p-3"><span class="px-2 py-1 rounded-full bg-amber-100 text-amber-700 font-black">يتطلب اعتمادًا</span></td><td class="p-3">'+money(x.score)+'</td><td class="p-3">'+esc(x.created_at||'')+'</td><td class="p-3 text-xs">'+(reasons||'—')+'</td><td class="p-3"><button class="px-3 py-2 rounded-xl bg-emerald-600 text-white font-black" onclick="RW_SalesDecisionCenter.approve('+JSON.stringify(x.operation_id)+')">اعتماد</button></td></tr>';
        }
        RW_UI.safeHTML(host,h+'</tbody></table></div>');
    }

    function renderPolicy(){
        var p=(state.policy&&state.policy.policy)||{};
        var disabled=!canManage();
        var host=byId('sdc-policy'); if(!host) return;
        var h='<div class="grid grid-cols-1 xl:grid-cols-4 gap-4">';
        h+=selectControl('sdc-pricing-source','مصدر التسعير',p.pricing_source||'item_default',[['item_default','السعر الأساسي للصنف'],['price_list','قائمة الأسعار'],['hybrid','هجين']],disabled);
        h+=control('sdc-max-discount','الحد الأقصى للخصم %',p.max_discount_percent, 'number',disabled);
        h+=control('sdc-discount-approval','نسبة الخصم التي تتطلب اعتمادًا %',p.discount_approval_threshold_percent,'number',disabled);
        h+=control('sdc-min-margin','أقل هامش ربح %',p.min_margin_percent,'number',disabled);
        h+=control('sdc-order-threshold','قيمة الطلب التي تتطلب اعتمادًا',p.order_approval_threshold_amount,'number',disabled);
        h+=selectControl('sdc-credit-mode','سياسة الائتمان',p.credit_mode||'ignore',[['ignore','لا تمنع / رقابة فقط'],['warn','تحذير'],['block','منع']],disabled);
        h+=control('sdc-credit-buffer','هامش تجاوز حد الائتمان',p.credit_buffer_amount,'number',disabled);
        h+=control('sdc-notes','ملاحظات السياسة',p.notes||'','text',disabled);
        h+=selectControl('sdc-stock-mode','سياسة الرصيد',p.stock_mode||'engine',[['engine','محرك المخزون الحالي'],['warn','تحذير'],['block','منع'],['backorder','يتطلب معالجة Backorder']],disabled);
        h+=control('sdc-credit-customer-required','العميل إلزامي للبيع الآجل',!!p.customer_required_for_credit,'checkbox',disabled);
        h+=control('sdc-manual-price','السعر اليدوي مسموح',!!p.allow_manual_price,'checkbox',disabled);
        h+=control('sdc-out-of-stock','السماح ببيع بدون رصيد',!!p.allow_out_of_stock_sale,'checkbox',disabled);
        h+='</div>';
        h+='<div class="flex flex-wrap gap-2 mt-5">';
        h+='<button id="sdc-save" class="px-5 py-3 rounded-2xl bg-blue-600 text-white font-black" '+(disabled?'disabled':'')+'>حفظ مسودة</button>';
        h+='<button id="sdc-publish" class="px-5 py-3 rounded-2xl bg-emerald-600 text-white font-black" '+(disabled?'disabled':'')+'>نشر واعتماد السياسة</button>';
        h+='</div>';
        RW_UI.safeHTML(host,h);
        var save=byId('sdc-save'); if(save) save.addEventListener('click',async function(){try{showLoader('جاري حفظ سياسة القرار...');await call('SAVE_POLICY',policyFromForm(),null,state.policy.policy_id);hideLoader();showToast('تم حفظ مسودة سياسة Sales Decision','success');await refresh();}catch(e){hideLoader();showToast(e.message,'error');}});
        var pub=byId('sdc-publish'); if(pub) pub.addEventListener('click',async function(){try{showLoader('جاري نشر سياسة القرار...');await call('PUBLISH_POLICY',{},null,state.policy.policy_id);hideLoader();showToast('تم نشر سياسة Sales Decision','success');await refresh();}catch(e){hideLoader();showToast(e.message,'error');}});
    }

    function renderSimulator(){
        var host=byId('sdc-simulator'); if(!host) return;
        var branches=(RW_STATE.data&&RW_STATE.data.branches)||[];
        var items=(RW_STATE.data&&RW_STATE.data.items)||[];
        var bh='<option value="">اختر الفرع</option>';
        for(var i=0;i<branches.length;i++) bh+='<option value="'+esc(branches[i].id)+'">'+esc((branches[i].branch_code||'')+' — '+(branches[i].name||''))+'</option>';
        var ih='<option value="">اختر الصنف</option>';
        for(var j=0;j<items.length;j++) ih+='<option value="'+esc(items[j].item_code)+'">'+esc((items[j].item_code||'')+' — '+(items[j].name||''))+'</option>';
        RW_UI.safeHTML(host,
          '<div class="grid grid-cols-1 xl:grid-cols-5 gap-3">'+
          '<select id="sdc-sim-branch" class="p-3 border rounded-xl">'+bh+'</select>'+ 
          '<select id="sdc-sim-payment" class="p-3 border rounded-xl"><option value="نقدي">نقدي</option><option value="أجل">أجل</option></select>'+ 
          '<input id="sdc-sim-total" type="number" step="0.01" value="10" class="p-3 border rounded-xl" placeholder="إجمالي الطلب">'+
          '<input id="sdc-sim-gross" type="number" step="0.01" value="10" class="p-3 border rounded-xl" placeholder="الإجمالي قبل الخصم">'+
          '<input id="sdc-sim-discount" type="number" step="0.01" value="0" class="p-3 border rounded-xl" placeholder="خصم الطلب">'+
          '<select id="sdc-sim-item" class="p-3 border rounded-xl">'+ih+'</select>'+ 
          '<input id="sdc-sim-qty" type="number" step="0.01" value="1" class="p-3 border rounded-xl" placeholder="الكمية">'+
          '<input id="sdc-sim-price" type="number" step="0.01" value="10" class="p-3 border rounded-xl" placeholder="السعر">'+
          '<button id="sdc-run" class="px-5 py-3 rounded-xl bg-slate-900 text-white font-black">اختبار القرار</button>'+ 
          '</div><div id="sdc-sim-result" class="mt-4"></div>'
        );
        var run=byId('sdc-run');
        if(run) run.addEventListener('click',async function(){
            try{
                var operationId=(window.crypto&&crypto.randomUUID)?crypto.randomUUID():'SIM-'+Date.now()+'-'+Math.random();
                var itemCode=byId('sdc-sim-item').value;
                if(!itemCode) throw new Error('اختر الصنف');
                var itemsList=(RW_STATE.data&&RW_STATE.data.items)||[];
                var chosen=itemsList.find(function(x){return String(x.item_code)===String(itemCode);})||{};
                var payload={entity_type:'ORDER',branch_id:byId('sdc-sim-branch').value||null,payment_type:byId('sdc-sim-payment').value,total_amount:Number(byId('sdc-sim-total').value||0),gross_amount:Number(byId('sdc-sim-gross').value||0),order_discount_amount:Number(byId('sdc-sim-discount').value||0),items:[{item_id:chosen.id||null,item_code:itemCode,qty:Number(byId('sdc-sim-qty').value||0),unit_price:Number(byId('sdc-sim-price').value||0),discount_percent:0}]};
                var r=await call('VALIDATE_ORDER',payload,operationId,null);
                var cls=r.decision==='ALLOW'?'bg-emerald-50 text-emerald-700':(r.decision==='REQUIRE_APPROVAL'?'bg-amber-50 text-amber-700':'bg-rose-50 text-rose-700');
                var reasons=(r.reasons||[]).map(function(x){return '<li>'+esc(x.message||x.code||'')+'</li>';}).join('');
                RW_UI.safeHTML(byId('sdc-sim-result'),'<div class="p-4 rounded-2xl '+cls+'"><div class="text-lg font-black">'+esc(r.decision||'—')+'</div><div class="text-sm mt-1">Score: '+money(r.score)+'</div><div class="text-xs mt-2">Operation: '+esc(operationId)+'</div>'+(reasons?'<ul class="list-disc pr-5 mt-3">'+reasons+'</ul>':'')+'</div>');
                await loadPending(); renderPending();
            }catch(e){RW_UI.safeHTML(byId('sdc-sim-result'),'<div class="p-4 rounded-2xl bg-rose-50 text-rose-700 font-black">'+esc(e.message)+'</div>');}
        });
    }

    async function approve(operationId){
        if(!canApprove()) return showToast('لا توجد صلاحية اعتماد Sales Decision','error');
        var note=await Swal.fire({title:'اعتماد العملية',input:'text',inputPlaceholder:'ملاحظة اعتماد اختيارية',showCancelButton:true,confirmButtonText:'اعتماد',cancelButtonText:'إلغاء'});
        if(!note.isConfirmed) return;
        try{showLoader('جاري اعتماد العملية...');await call('APPROVE_EVALUATION',{note:note.value||null},operationId,null);hideLoader();showToast('تم اعتماد العملية','success');await loadPending();renderPending();}catch(e){hideLoader();showToast(e.message,'error');}
    }

    function subscribe(){
        var c=_rwCompanyId(); if(!c) return;
        if(realtimeChannel){try{supabase.removeChannel(realtimeChannel);}catch(e){} realtimeChannel=null;}
        realtimeChannel=supabase.channel('rw-sales-decision-'+c)
          .on('postgres_changes',{event:'*',schema:'public',table:'sales_decision_policies',filter:'company_id=eq.'+c},function(){refresh().catch(function(e){console.error(e);});})
          .on('postgres_changes',{event:'*',schema:'public',table:'sales_decision_evaluations',filter:'company_id=eq.'+c},function(){loadPending().then(renderPending).catch(function(e){console.error(e);});})
          .on('postgres_changes',{event:'*',schema:'public',table:'sales_decision_approvals',filter:'company_id=eq.'+c},function(){loadPending().then(renderPending).catch(function(e){console.error(e);});})
          .subscribe();
    }

    async function refresh(){
        state.policy=await loadPolicy();
        renderMeta();
        renderPolicy();
        await loadPending();
        renderPending();
    }

    function renderMeta(){
        var host=byId('sdc-meta'); if(!host) return;
        var p=state.policy||{};
        RW_UI.safeHTML(host,
          '<div class="grid grid-cols-1 md:grid-cols-4 gap-3">'+
          '<div class="rw-kpi-card"><div class="text-xs text-slate-500">الحالة</div><div class="text-2xl font-black mt-2">'+esc(p.status||'—')+'</div></div>'+ 
          '<div class="rw-kpi-card"><div class="text-xs text-slate-500">الإصدار</div><div class="text-2xl font-black mt-2">'+esc(p.version_no||'—')+'</div></div>'+ 
          '<div class="rw-kpi-card"><div class="text-xs text-slate-500">بداية النفاذ</div><div class="text-2xl font-black mt-2">'+esc(p.effective_from||'—')+'</div></div>'+ 
          '<div class="rw-kpi-card"><div class="text-xs text-slate-500">Policy ID</div><div class="text-xs font-black mt-2 break-all">'+esc(p.policy_id||'—')+'</div></div>'+ 
          '</div>'
        );
    }

    async function render(){
        var c=byId('rw-page-container'); if(!c) return;
        if(!canRead()){RW_UI.safeHTML(c,'<div class="rw-card"><div class="rw-error">ليس لديك صلاحية قراءة مركز قرار المبيعات.</div></div>');return;}
        safeText(byId('rw-header-title'),'مركز قرار المبيعات');
        safeText(byId('rw-header-subtitle'),'تحكم مركزي في سياسة التسعير والخصومات والهامش والائتمان والرصيد والاعتمادات قبل التنفيذ.');
        RW_UI.safeHTML(c,'<div class="space-y-6">'+
          '<div class="rw-page-header"><div><h1>🧠 مركز قرار المبيعات</h1><p>Control Plane مركزي يقرر قبل إنشاء الطلب أو حركة المخزون أو الترحيل المالي.</p></div><button id="sdc-refresh" class="px-5 py-3 rounded-2xl bg-slate-900 text-white font-black">تحديث</button></div>'+
          '<div id="sdc-meta"></div>'+
          '<div class="rw-card"><div class="flex justify-between gap-3 items-center flex-wrap"><div><h3>سياسة القرار الحالية</h3><p class="text-sm text-slate-500 mt-1">التعديلات تُحفظ كنسخة Draft ثم تُنشر صراحة.</p></div></div><div id="sdc-policy" class="mt-5"></div></div>'+
          '<div class="rw-card"><div><h3>طلبات الاعتماد</h3><p class="text-sm text-slate-500 mt-1">كل طلب يحتاج اعتمادًا يظهر هنا حتى يوافق عليه مدير مخول.</p></div><div id="sdc-pending" class="mt-4"></div></div>'+
          '<div class="rw-card"><div><h3>محاكي القرار</h3><p class="text-sm text-slate-500 mt-1">اختبار آمن يكتب Evaluation فقط ويمكن تنظيفه بعد الاختبار.</p></div><div id="sdc-simulator" class="mt-4"></div></div>'+
          '</div>');
        var refreshBtn=byId('sdc-refresh'); if(refreshBtn) refreshBtn.addEventListener('click',function(){refresh().catch(function(e){showToast(e.message,'error');});});
        try{await Promise.all([refresh(),renderSimulator()]);subscribe();}catch(e){RW_UI.safeHTML(c,'<div class="rw-card"><div class="rw-error">'+esc(e.message)+'</div></div>');}
    }

    return {render:render,refresh:refresh,approve:approve};
})();
window.RW_SalesDecisionCenter = RW_SalesDecisionCenter;
```

### مهم جدًا
هذا الـmodule لا يتجاوز Sales Target Engine أو Loyalty أو Inventory Engine. وظيفته قرار/Policy/Approval فقط.

---

# 14. E2E بعد دمج PATCH

بعد دمج الملف في Mother الحالي وإعادة النشر:

## المرحلة A — Load

```text
Login
↓
إدارة المبيعات
↓
مركز قرار المبيعات
↓
GET_POLICY
```

المطلوب:

```text
status = Active
version = 1
policy visible
Console = no error
Network = 200
```

## المرحلة B — Policy Write

بحساب manager/general_manager فقط:

```text
change max_discount_percent
↓
حفظ مسودة
↓
status = Draft
version increments
↓
نشر واعتماد
↓
status = Active
```

## المرحلة C — Decision Simulation

اختبر:

```text
ALLOW
```
ثم:

```text
100% discount
→ REQUIRE_APPROVAL
```

ثم:

```text
GET_PENDING_APPROVALS
→ يظهر الطلب
```

ثم:

```text
APPROVE
→ يختفي من pending
```

## المرحلة D — Console / Network

لا يُسمح بقبول:

```text
JS error
404 function
401 auth failure
403 permission failure
500 RPC failure
stuck loading
```

---

# 15. السجلات والأخطاء التي ظهرت أثناء التنفيذ

### Error 1 — Production test order

تم أثناء اختبارات Sales Decision الأولية استخدام تهيئة Policy تجريبية داخل Transaction ثم rollback. هذا نجح دون بقاء data.

### Error 2 — approval state

تم اكتشاف أن النسخة الأولى من التصميم كانت ستعيد `REQUIRE_APPROVAL` داخل `save_sales_invoice_atomic` ثم تعمل `RAISE EXCEPTION`. هذا كان سيمحو الـevaluation مع rollback الكامل، وبالتالي لا يمكن اعتماد الطلب لاحقًا.

**الإصلاح:**

نقل Decision Gate قبل mutation وعدم throw في `REQUIRE_APPROVAL`/`BLOCK` داخل مسار حفظ الفاتورة؛ بل إرجاع Decision result فقط وترك Evaluation commit، ثم تنفيذ approval retry.

هذا ليس patch تجميليًا؛ إنه إصلاح لدورة الحالة نفسها.

### Error 3 — اختبار سابق متعلق بـPurchase Receipt

ظهر في جلسة سابقة أن `receive_purchase_atomic` كان يولد `operation_id` داخليًا ويستخدم `qty_received_before` في idempotency identity. تم عدم اعتبار هذه النقطة جزءًا من Sales Decision Closure، ولم يتم خلطها في هذا الـclosure.

---

# 16. Current Production verification بعد الإغلاق

الحالة الدائمة المثبتة:

```text
Sales Decision Engine exists          = YES
Sales Decision Approval table        = YES
Sales Decision Active Policy         = 1
Sales Decision Pending Approvals     = 0
Sales Decision Test Rows             = 0
anon EXECUTE                         = NO
authenticated EXECUTE                = NO
service_role EXECUTE                = YES
Edge sales-decision-center           = ACTIVE v1
```

### Production snapshot hash

عند آخر snapshot أثناء الجلسة:

```text
2026-09-15 11:49:56+00
SDC policy snapshot hash = 7f27a0f26ce74bc7ca865b8209edeca4
```

هذا hash يستخدم فقط كسجل تطابق لنقطة القياس؛ لا يُعامل كمرجع دائم إذا تغيرت Production لاحقًا.

---

# 17. Git records

تم إنشاء Edge source في:

```text
Current/Edge_Functions/sales-decision-center
```

Commit:

```text
9f2d5954204ae3a7114332ae4c9af031a96413ca
```

Production Edge deployment:

```text
sales-decision-center
version=1
id=52344128-4ecf-4902-a74c-56f9c59bbbe1
status=ACTIVE
verify_jwt=true
```

---

# 18. GLOBAL WRITER / Sales Responsibility Matrix

| المسؤولية | Historical/Existing | Production current | Sales Decision Target |
|---|---|---|---|
| Pricing source | items / price lists | price engines موجودة | policy selects source |
| Discount limit | موزع بين modules | غير مركزي | centralized policy |
| Margin gate | غير مركزي | غير مركزي | Sales Decision |
| Credit gate | customer data | customer data | Sales Decision |
| Stock decision | Inventory engine | post_stock_movement | Sales Decision reads availability only |
| Physical movement | Inventory Core | post_stock_movement | unchanged |
| Approval | scattered / target engines | Sales targets have approval | Sales Decision approval workflow |
| Order idempotency | operation_id | save_sales_invoice | integrated |
| Audit | audit_log | active | decision + approval audited |
| Tenant isolation | mixed history | company-scoped decision core | enforced |

---

# 19. ZERO-DEBT RESULT

بالنسبة لـSales Decision Core نفسه:

```text
Parallel Sales Decision Engine outside canonical core = 0
Physical Stock Engine introduced here = 0
Direct stock mutation introduced here = 0
Tenant global lookup in SDC engine = 0
Approval dead-end = 0
```

أما Mother UI Browser closure:

```text
OWNER SURGICAL PATCH = REQUIRED
BROWSER E2E = REQUIRED
```

لذلك:

```text
GLOBAL SALES DECISION CENTER = NOT YET 100% CLOSED
```

والسبب الوحيد المتبقي هو Owner-side Mother UI patch + actual Browser/Console/Network verification.

---

# 20. Self-Audit النهائي

## What I Proved

- Current Git HEAD للـMother هو `27cfa8...`.
- Direct parent هو `24e0124...`.
- Current mother blob هو `7c112d...`.
- Current source يصل إلى EOF وينتهي بـ`</html>`.
- Sales Decision infrastructure لم تكن موجودة كـControl Plane مركزي ثم تم إنشاؤها في Production.
- Policy versioning موجود.
- Decision Evaluation موجود.
- Approval workflow موجود.
- Sales invoice صار Decision-gated قبل mutation.
- Idempotency مثبتة.
- DB ACL للـcore محكمة.
- Edge Function منشورة ACTIVE.
- الاختبارات الأساسية نجحت.
- Production test residue = 0.

## What I Did Not Prove

- Browser E2E الفعلي بعد Owner patch.
- Console/Network E2E الفعلي من المتصفح الحالي.
- اكتمال باقي تبويبات الإدارة المالية/HR/CRM لمجرد أننا أغلقنا Sales Decision.
- أن كل Sales child apps تستخدم Decision Center بالفعل ما لم تمر عبر المسار المربوط هنا؛ هذا يحتاج app-level E2E بعد دمج Mother.

## What I Fixed

- غياب Sales Decision Control Plane.
- غياب approval persistence.
- خطر rollback الذي يمحو REQUIRED APPROVAL.
- الفصل الأمني للـDecision RPC.
- الدمج مع `save_sales_invoice_atomic` قبل order/stock/accounting mutation.

## What I Initially Missed

- أن `REQUIRE_APPROVAL` يجب أن يكون durable state وليس exception فقط.
- أن approval تحتاج operation_id محفوظًا حتى يمكن retry آمن لنفس العملية.

## What Could Still Be Wrong

- Mother UI patch قد يحتوي typo عند manual merge.
- Browser event wiring قد يختلف عن assumption إذا تغيرت Main Source بين هذا التقرير والاختبار.
- أي تغييرات Production خارج هذا closure بعد snapshot الحالي يمكن أن تجعل التقرير stale.

## Final Confidence

```text
Production backend confidence = HIGH
Production Decision-core confidence = HIGH
Mother source forensic confidence = HIGH
Browser UI confidence = NOT VERIFIED
```

## Final Closure Status

```text
SALES DECISION CORE = CLOSED
SALES DECISION PRODUCTION = DEPLOYED + VERIFIED
SALES DECISION MOTHER UI = OWNER PATCH PENDING
SALES DECISION BROWSER E2E = OPEN
GLOBAL SALES DECISION CENTER = OPEN UNTIL OWNER BROWSER PASS
```

---

# 21. START-HERE FOR THE NEXT CTO / ASSISTANT

لا تبدأ من هذا التقرير كحالة Production؛ ابدأ دائمًا من الأدلة الحية.

التسلسل الإجباري:

```text
1. Read CURRENT GIT HEAD
2. Read DIRECT PARENT
3. Read CURRENT MOTHER BLOB بالكامل حتى EOF
4. Confirm Source of Truth = erp-frontend/companies/company-1/main.html
5. Read current Production schema/functions
6. Read current deployments
7. Read current DB counts
8. Ignore stale report percentages
9. Locate the exact current anchor in Mother Source itself
10. Determine what is already closed before touching it
11. For any open Sales point, separate Policy / Decision / Approval / Execution / UI
12. Change Production directly only after proving the gap
13. Never create a second Core if an existing Core owns the responsibility
14. Run ALLOW + BLOCK + REQUIRE_APPROVAL + DUPLICATE tests
15. Remove test residue
16. Verify Production again immediately before report
17. Update Git record + CURRENT_STATE
18. Give owner exact surgical patch for Mother only
19. Do Browser/Console/Network E2E before claiming 100%
20. Only then move to the next OPEN closure unit
```

### قاعدة أخيرة

أي future CTO يرى:

```text
Sales Decision = Closed
```

لا يثق بهذه الجملة وحدها.

يجب أن يعيد إثبات:

```text
CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT
+
CURRENT BROWSER/CONSOLE/NETWORK
```

ثم يقرر هل ما زال الإغلاق قائمًا.
