# Report339 — إغلاق أزمة DirectSale / Fleet / Vouchers
## التاريخ
2026-09-24

## 1) الحقيقة المرجعية
تمت مراجعة governance وCURRENT_STATE ومجلد التقارير، ثم إعادة التحقق من Git وProduction وDatabase وDeployment قبل التنفيذ.

### System
Repository: papamohammed77-glitch/rawaie-erp-New
HEAD قبل هذا التقرير: eb22f825a145c88b27a3dd791ad189d767b2c8ff
Parent: f749d5fbfc3ee613d15e7e1d2b8b74d0c283b054

### Mother
Repository: papamohammed77-glitch/erp-frontend
Current HEAD: f26e7e995706ea45ad586a31238178d9c7891e71
Parent: d13537d0f4d8d7f0e2c0ac6d25d779bc4062760e
main.html blob: 6885ccdbb44344ae6aa839fbc7a4ccb93494bb24
main.html لم يُعدّل بواسطة المساعد.

### Production
Supabase project: fiilmooggumokxanwiyx
Fleet control plane: fleet_query + fleet_command_atomic
No new Edge Function.
create-stock-voucher deployed version: 12.
Physical Stock writer remains post_stock_movement.

## 2) السبب الجنائي
المشكلة نتجت من انفصال ثلاثة عقود:
1. Mother DirectSale كانت تعتبر voucher_id إلزاميًا في ربط المركبة بالعملية.
2. vouchers.html كانت تمسح المركبة عند اختيار مندوب البيع المباشر، ثم تشترط وجود الوجهة قبل المتابعة.
3. لم يكن هناك Master source مستقل لعلاقة مندوب البيع المباشر بالمركبة.

النتيجة: الربط التشغيلي كان يعتمد على وجود مستند مخزني بدل أن يكون الربط Master سابقًا على المستند.

لم يتم إعادة أي ربط بين vehicle.driver_id وDirect Sales Rep. الفصل الذي تم اعتماده سابقًا بقي كما هو.

## 3) Production الذي تم تنفيذه

### A — Master Contract
تم إنشاء:
public.fleet_vehicle_sales_rep_assignments

المفتاح التشغيلي:
company_id + vehicle_id + sales_rep_user_id

ويحفظ:
start_at / end_at / is_primary / reference / notes / created_by
مع Unique active primary لكل مندوب ولكل مركبة، وAudit Trigger وRLS.

### B — Fleet Command
تم تطوير نفس:
VEHICLE_OPERATION_BIND

وأضيف:
operation_type = DIRECT_SALE_MASTER

هذا المسار:
- يحتاج مركبة ومندوب بيع مباشر صالحين داخل الشركة.
- لا يحتاج voucher.
- يحفظ العلاقة Master.
- يدعم replay idempotency.
- لا ينتج حركة مخزون أو قيد محاسبي.

المسار القديم DIRECT_SALE لم يُلغَ ولم تُعاد صياغته.

### C — Fleet Query
تم تطوير نفس fleet_query لإظهار:
direct_sales_rep_assignments
و direct_sales_rep_id / direct_sales_rep_name في قراءات المركبات، وDirect Sales mapping في Vehicle Detail.

### D — Vouchers Backend
تم تطوير create_manual_stock_voucher_atomic_core_12_20260828 بحيث:
- DirectSale يمكن إنشاؤه بدون to_id.
- rep_id يحدد مندوب البيع المباشر.
- عند غياب to_id يتم Resolve للمركبة النشطة من Master assignment.
- المركبة يجب أن تكون Active وmobile_stock_enabled.
- لا توجد حركة مخزنية عند CREATE Draft.

### E — Edge
تم التحقق أن create-stock-voucher version 12 موجود بالفعل ويدعم rep_id وoperation_id ويمرر العملية إلى RPC الحالي.
لم يتم إنشاء Edge Function جديدة.

## 4) vouchers.html
تم تعديل:
Current/PWA/vouchers.html

Commit:
eb22f825a145c88b27a3dd791ad189d767b2c8ff

التغييرات الجراحية:
- تحميل direct_sales_rep_assignments وبناء repVehicleMap.
- عند اختيار مندوب البيع المباشر تظهر مركبته تلقائيًا.
- DirectSale لا يفرض toId قبل محاولة Resolve.
- الإرسال النهائي يستعمل المركبة المرتبطة عند توفرها.
- Transfer وبقية أنواع الأذونات احتفظت بشرط الوجهة.

Current vouchers blob:
d32d57eada0d3fdac4ce45dc469c6eeab19828a3

## 5) Production Verification

### Master Binding
تم تنفيذ VEHICLE_OPERATION_BIND مع:
Vehicle = CHV-2025-01
Rep = van-sales2

النتيجة:
success=true
status=Assigned

Replay بنفس operation_id وpayload:
duplicate=true

### Fleet Read
fleet_query(direct_sales_rep_assignments) = PASS
vehicle_detail = PASS
وظهر الربط داخل Vehicle Detail.

### DirectSale CREATE بدون مركبة
تم اختبار CREATE فعليًا:
- DirectSale
- to_id = NULL
- rep_id = direct sales rep

تم Resolve تلقائيًا إلى المركبة المرتبطة.
الحالة Draft.
custodian_user_id حُفظ للمندوب.
inventory_log = 0
journal_entries = 0

### Data Hygiene
تم تنظيف جميع بيانات اختبارات هذه الجلسة.
آخر تحقق:
QA vouchers = 0
QA operation identities = 0
QA fleet registry = 0
QA inventory_log = 0
QA audit rows = 0
Fleet active/historical test rows = 0

حارس stock_voucher_operations delete أعيد تمكينه.

## 6) التأثير المخزني والمحاسبي
Master Binding:
Stock delta = 0
GL delta = 0

DirectSale CREATE Draft:
Stock delta = 0
GL delta = 0

عند SEND يبقى Physical Stock ضمن post_stock_movement.
مستند DirectSale المخزني ليس هو فاتورة البيع المحاسبية؛ المسار المحاسبي للفوترة يظل في Sales/Invoice contract.

## 7) main.html — لا تعديل من المساعد

المطلوب من المالك فقط:

### PATCH 1 — السطر التقريبي 29233
ابحث عن:
var dsOptions = ds.map(function(x){

واستبدل العنصر كاملًا بـ:
var dsOptions = [[ '', 'بدون مستند — ربط المركبة بمندوب البيع المباشر' ]].concat(ds.map(function(x){
  var ref = String(x.reference||'').trim();
  return [x.id, (x.voucher_code||'—') + (ref ? ' · مرجع: '+ref : '') + ' · مندوب: ' + (x.direct_sales_rep_name||'—') + (x.current_vehicle_code ? ' · مركبة: '+x.current_vehicle_code : '')];
}));

### PATCH 2 — السطر التقريبي 29290
ابحث عن عنصر input الذي يحتوي:
id="fvo-ds-ref"
وهو حاليًا readonly.

استبدله كاملًا بـ:
<div><label class="font-bold text-sm text-slate-700">المرجع</label><input id="fvo-ds-ref" class="rw-input" style="height:46px;padding-right:14px;margin-top:6px;background:#fff" placeholder="مرجع الربط (اختياري)" value=""></div>

### PATCH 3 — داخل openVehicleOperationLinkForm() قرب السطر التقريبي 29313
ابحث تحديدًا عن:
} else if (type==='DIRECT_SALE') {
  payload.voucher_id = val('fvo-ds');
  payload.direct_sales_rep_id = val('fvo-ds-rep');
  if (!payload.voucher_id) throw new Error('اختر مستند البيع المباشر');
  if (!payload.direct_sales_rep_id) throw new Error('اختر مندوب البيع المباشر');
} else {

احذفه واستبدله كاملًا بـ:
} else if (type==='DIRECT_SALE') {
  payload.voucher_id = val('fvo-ds');
  payload.direct_sales_rep_id = val('fvo-ds-rep');
  payload.operation_type = payload.voucher_id ? 'DIRECT_SALE' : 'DIRECT_SALE_MASTER';
  payload.reference = val('fvo-ds-ref') || null;
  if (!payload.direct_sales_rep_id) throw new Error('اختر مندوب البيع المباشر');
} else {

لا تعديل لأي جزء آخر من main.html.

## 8) ما لم يُغلق بعد
Authenticated Browser E2E للـpublished Mother artifact = OPEN / UNVERIFIED.
لا يجوز تحويل DB/RPC PASS إلى Browser PASS.

بعد تطبيق PATCH 1-3 من المالك:
1. تحقق من Mother HEAD والـmain.html blob.
2. تحقق من published artifact.
3. نفذ Browser E2E مصادقًا.
4. تحقق من network calls إلى fleet_query / fleet_command_atomic / create-stock-voucher.
5. تحقق أن Master Binding لا يغير stock أو GL.
6. انتقل فقط بعدها إلى Closure Unit التالية.

## 9) ملاحظات الاستمرارية
لا تعِد فتح:
- DirectSale driver decoupling.
- custodian_user_id persistence.
- physical stock centralization.
- legacy update overload retirement.
- DirectReturn driver semantics.

ابدأ كل جلسة لاحقة من:
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT.
التقرير مرجع، وليس بديلًا عن إعادة إثبات الحقيقة.
