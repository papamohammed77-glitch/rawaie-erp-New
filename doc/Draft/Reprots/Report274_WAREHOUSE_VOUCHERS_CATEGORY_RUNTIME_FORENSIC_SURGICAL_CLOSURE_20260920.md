# التقرير الجنائي التنفيذي — الأذونات المخزنية / Standalone Voucher Consumer
## RAWAEA ERP — Current Reality + Surgical Closure
**التاريخ:** 2026-09-20
**نطاق الجلسة:** مراجعة أحدث حالة Production/Git/Source لتطبيق
`erp-frontend/companies/company-1/warehouse/vouchers.html`، مطابقة تكامله مع النظام الأم، إثبات سبب عطل تصنيفات الأصناف، وإصدار التعديل الجراحي الوحيد المطلوب.

---

## 1. قاعدة الحقيقة

الحقيقة المعتمدة في هذه الجلسة:

**CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE**

التقارير السابقة استرشادية فقط. لم يُعتبر أي إصلاح سابق «مفتوحًا» لمجرد أن تقريرًا قديمًا ذكره.

---

## 2. HEAD / Parent — آخر حالة مثبتة

### System Repository
`papamohammed77-glitch/rawaie-erp-New`

- HEAD: `c62639f45fdd7bc74c8e90a02d9cde53affb8d1a`
- Parent: `06b93f6b92f0041b09115f2bed8dc836e7b2a175`
- HEAD message: `docs: update current state after warehouse vouchers forensic closure`

### Frontend Repository
`papamohammed77-glitch/erp-frontend`

- HEAD: `8a1a75dd840b32cfc135178a9a9c466adefaf0ee`
- Parent: `cb77af4d55a5ff7e71da6c73edda98667cdd03ae`
- آخر سلسلة تغييرات مرتبطة بملف الأذونات تضمنت:
  - `8a1a75dd...` — تغيير نص زر التحديث فقط.
  - `fedd7138f7c8b266ae820f2c914f33298715d0e8` — تحديث `allowedBranch`.
  - `8e30320dbec24a1ea962c9616cd1b07f6702d706` — تحديث event listeners ومسار Service Worker.

### Current standalone source
- File: `companies/company-1/warehouse/vouchers.html`
- Current blob SHA: `cc9ec52b7e275cc7bccf24f5858261a97733698e`

---

## 3. Scope Lock

في هذه الجلسة:

- `main.html`: لم يُعدّل.
- `vouchers.html`: لم يُعدّل.
- `core.js`: لم يُعدّل.
- `sw.js`: لم يُعدّل.
- `register-sw.js`: لم يُعدّل.
- Edge Functions جديدة: **0**.
- لا Migration جديدة مطلوبة من أجل العيب المكتشف.
- Production SQL/RPC الحالية تمت مطابقتها ولم يُعاد إصلاح ما هو مغلق بالفعل.

---

## 4. لماذا تطبيق الأذونات موجود كتطبيق مستقل؟

إعادة البناء التاريخي تؤكد أن التصميم ليس فصلًا عشوائيًا.

### النظام الأم
Control Plane:

- Navigation.
- الصلاحيات والأدوار.
- الرؤية الموحدة.
- التقارير والبحث والفلترة.
- متابعة الحالة.
- التحكم الإداري.

### التطبيق المستقل
Operational Consumer:

- إنشاء وتشغيل الأذونات المخزنية اليدوية.
- اختيار المصدر والوجهة.
- التعامل مع الأصناف والباركود.
- تنفيذ دورة الإذن.
- إدارة عمليات Transfer / DirectSale / DirectReturn / SupplierReturn.
- إرسال والاستلام والإكمال حسب نوع الإذن.

### Production Core
Business Rule Authority:

```
Operational Request
        ↓
Public RPC / Existing Edge Capability
        ↓
Voucher Core
        ↓
post_stock_movement
        ↓
stock_branches + inventory_log
```

لا يجوز للتطبيق المستقل أن يصبح Physical Stock Engine منفصلًا.

---

## 5. التكامل مع النظام الأم — مثبت من المصدر

النظام الأم الحالي يقرأ:

```
stock_vouchers
  WHERE company_id = current company
```

ويعرض:

- النوع.
- التاريخ.
- الحالة.
- المرجع.
- المصدر.
- الوجهة.
- الإجراءات.
- البحث والفلترة والتقسيم إلى Pending / Completed.

التطبيق المستقل يكتب في نفس `stock_vouchers` / `stock_voucher_details` من خلال عقد Production الحالية.

إذًا تكامل الأذونات يشبه النمط المعتمد في بقية المشروع:

**Standalone App = Execution**
  
**Mother = Governance + Unified Visibility**

ولا توجد قاعدة بيانات ثانية للأذونات.

---

## 6. مطابقة دورة العمليات

### Transfer
`Branch → Branch`

- CREATE = Draft
- SEND = خصم من المصدر
- RECEIVE = إضافة للوجهة
- COMPLETE = إغلاق الدورة

### DirectSale
`Branch → Vehicle`

- إنشاء إذن صرف مستقل عن Order.
- رصيد المركبة يصبح هو مخزن المندوب.
- لا يعاد استخدام Order كبديل عن الإذن.

### DirectReturn
`Vehicle → Branch`

Production الحالية تثبت التسلسل صراحة:

- SEND = `InventoryDecrease` من مخزون المركبة.
- RECEIVE = `DirectReturn` إلى الفرع.
- ثم COMPLETE.

وهذا يطابق التصميم الميداني ولا يجب تبسيطه إلى حركة أحادية دون عقد جديد.

### SupplierReturn
`Branch → Supplier`

- صرف من مخزون الفرع.
- ارتباط المورد يتم داخل Production Contract.
- الأثر المحاسبي لا يخترع داخل شاشة الأذونات.

---

## 7. Production Reality الحالية

Production الآن:

- companies = 1
- branches = 2
- items = 17
- active vehicles = 0
- stock_vouchers = 0
- stock_voucher_details = 0
- stock_voucher_operations = 0
- inventory_log = 3
- active users with `active_warehouse_role='أذونات'` = 1

المستخدم:

- `vouchers@rawaea.com`
- role = `مخزني`
- active_warehouse_role = `أذونات`
- status = `Active`
- allowed_branch_ids = `BR-01`
- permissions = [`warehouse`]

لا يوجد Test Residue بعد الاختبارات.

---

## 8. Production Security / Writer Verification

تم التحقق من Production:

### Internal voucher cores

الدوال:

- `create_manual_stock_voucher_atomic_core_20260828`
- `create_manual_stock_voucher_atomic_core_12_20260828`
- `send_stock_voucher_atomic_core_20260828`
- `post_manual_stock_voucher_atomic_core_20260828`
- `complete_manual_stock_voucher_atomic_core_20260828`
- `cancel_manual_stock_voucher_atomic_core_20260828`

حالتها الحالية:

- PUBLIC EXECUTE = false
- anon EXECUTE = false
- authenticated EXECUTE = false
- service_role EXECUTE = false

### Physical Writer

الفحص الحالي لم يجد Writer مستقلًا داخل Voucher contract يعدل المخزون خارج المحرك المركزي.

العقد:

```
post_stock_movement
      ↓
stock_branches
+
inventory_log
```

`reserve_stock` يبقى Reservation Engine فقط.

---

## 9. E2E Production — اختبار فعلي Transactional

تم تنفيذ دورة Transfer كاملة داخل Transaction ثم تم Rollback:

```
CREATE
→ CREATE RETRY
→ SEND
→ SEND RETRY
→ RECEIVE
→ RECEIVE RETRY
→ COMPLETE
```

النتائج:

- CREATE retry = `duplicate=true`
- SEND retry = `duplicate=true`
- RECEIVE retry = `duplicate=true`
- `main_delta = -1`
- `branch2_delta = +1`
- Physical movements = 2
- Unique movement keys = 2
- لا توجد حركة ثالثة.
- Rollback أعاد Production إلى baseline.

هذه نتيجة E2E للـbackend/Production contract، وليست Browser E2E credential-backed.

---

# 10. INVESTIGATION — المشكلة التي ما زالت ظاهرة في الشاشة

الـConsole المبلغ عنه:

```
vouchers:1 Uncaught SyntaxError: Unexpected end of input
JSEventHandlerForContentAttribute
safeHTML
renderCats
renderWorkspace
```

تمت مطابقة ذلك مع المصدر الحالي نفسه.

### العنصر المسبب

الدالة:

```javascript
renderCats:function()
```

وتظهر في الملف الحالي ضمن منطقة workspace/catalog، في حدود السطر `444`.

النسخة الحالية تحتوي:

```javascript
return'<button onclick="App.catSet('+JSON.stringify(c)+')" ...
```

### السبب المثبت

عندما تكون الفئة مثل:

```
حلويات
```

يصبح HTML الناتج فعليًا من الشكل:

```html
<button onclick="App.catSet("حلويات")" ...>
```

وهذا يكسر attribute نفسه قبل أن يصل JavaScript إلى التنفيذ.

الـHTML parser يقرأ:

- onclick = `App.catSet(`
- ثم يعتبر بقية النص attribute منفصلًا.

وبالتالي عند الضغط على تبويب التصنيف يظهر:

```
SyntaxError: Unexpected end of input
```

### لذلك

- Tailwind warning ليس سبب العطل.
- Service Worker 404 القديم ليس سبب العطل في المصدر الحالي.
- `filterList` ليس سبب العطل.
- `App.init` ليس سبب هذا العطل.
- `allowedBranch` ليس سبب هذا العطل.

**Root Cause = renderCats inline handler construction.**

---

# 11. الإصلاح الجراحي الوحيد المطلوب الآن

## الملف المطلوب تعديله يدويًا

```
erp-frontend/companies/company-1/warehouse/vouchers.html
```

## ابحث حرفيًا عن

```javascript
renderCats:function(){var s=this,m={الكل:1};this.items.forEach(function(x){if(x.category)m[x.category]=1});RW_UI.safeHTML(RW_UI.byId('wsCats'),Object.keys(m).slice(0,40).map(function(c){return'<button onclick="App.catSet('+JSON.stringify(c)+')" class="px-3 py-1.5 rounded-full text-[11px] font-black '+(s.cat===c?'bg-blue-600 text-white':'bg-slate-800 text-slate-400')+'">'+s.esc(c)+'</button>'}).join(''))}
```

## احذفه بالكامل.

## واستبدله بالكامل بهذا:

```javascript
renderCats:function(){var s=this,m={'الكل':1};this.items.forEach(function(x){if(x.category)m[x.category]=1});var root=RW_UI.byId('wsCats');if(!root)return;RW_UI.safeHTML(root,Object.keys(m).slice(0,40).map(function(c){return'<button type="button" data-rw-cat="'+s.esc(c)+'" class="px-3 py-1.5 rounded-full text-[11px] font-black '+(s.cat===c?'bg-blue-600 text-white':'bg-slate-800 text-slate-400')+'">'+s.esc(c)+'</button>'}).join(''));if(!root._rwCatBound){root.addEventListener('click',function(e){var b=e.target.closest&&e.target.closest('[data-rw-cat]');if(b)s.catSet(b.getAttribute('data-rw-cat'))});root._rwCatBound=true}}
```

### خصائص الإصلاح

- لا Inline `onclick` للفئة.
- لا `JSON.stringify(c)` داخل HTML attribute.
- يعتمد على `data-rw-cat`.
- Event Delegation على `#wsCats`.
- يحافظ على `catSet` الحالية.
- يحافظ على شكل الأزرار الحالي.
- لا يغير API.
- لا يغير Production.
- لا يغير Mother.
- لا يعيد بناء Catalog.

---

## 12. Static verification للـowner patch

تم إنشاء نسخة in-memory من المصدر الحالي وتطبيق الاستبدال فقط.

النتائج:

- current vouchers SHA = `cc9ec52b7e275cc7bccf24f5858261a97733698e`
- renderCats occurrences = 1
- catSet occurrences = 1
- JSON.stringify(c) في renderCats قبل الإصلاح = موجود
- JSON.stringify(c) بعد الإصلاح = 0 داخل renderCats
- data-rw-cat بعد الإصلاح = موجود
- inline App.catSet handler بعد الإصلاح = 0

الإصلاح لا يحتاج أي Production migration.

---

# 13. ما تم إثباته بخصوص مشكلة فتح التطبيق

Patch A/B/C ليست ضمن هذه الجلسة وليست ضمن المطلوب إعادة تنفيذه.

المصدر الحالي بالفعل يحتوي:

```html
<script src="../core.js"></script>
```

و:

```javascript
RW_SW.register('../sw.js');
```

ولا يحتوي:

```html
<script src="register-sw.js"></script>
```

كما لا يحتوي:

```javascript
RW_SW.register('sw.js')
```

إذن لا تعاد هذه الإصلاحات.

---

# 14. الوضع التنافسي — ما ينقص وما لا يجوز اختراعه

تمت مطابقة ما يمكن إثباته من الأنظمة المنافسة الرسمية.

### Odoo

يوفر:

- Internal Transfers.
- Barcode processing.
- Inventory adjustments.
- Scrap.
- Lot / Serial support في عمليات المخزون.

المصادر:
- https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations/adjustments.html
- https://www.odoo.com/documentation/17.0/applications/inventory_and_mrp/barcode/operations/transfers_scratch.html
- https://www.odoo.com/documentation/master/applications/inventory_and_mrp/barcode/setup/operation_types.html

### SAP

يوفر:

- Goods Receipt.
- Goods Issue.
- Stock Transfer.
- Transfer Posting.
- Material Documents.
- Stock in transit في السيناريوهات المناسبة.
- مستندات حركة يمكن عرضها/عكسها.

المصادر:
- https://help.sap.com/docs/SAP_S4HANA_CLOUD/32da8359c8ee4e8b8e8c5e15cacba5aa/4fdef17912454fe595400e1c00df32ca.html
- https://help.sap.com/docs/SAP_S4HANA_CLOUD/6540a57e42314b5a8bca283e29e6/7cc07e548af58e4ce1000000a4450e5.html
- https://help.sap.com/docs/SAP_S4HANA_CLOUD/0864cb07010642b3bde45a20de4975bc/557a1702cb9d46559cfddda3e45d078e.html

### Manager.io

يوفر:

- Inventory Transfers.
- Inventory Locations.
- Write-offs.
- تقارير الكميات حسب الموقع.

المصادر:
- https://www2.manager.io/guides/10707
- https://www2.manager.io/guides/10677
- https://www2.manager.io/guides/10709

### Daftra

يوفر:

- Manual Transfer.
- Source / Destination.
- Notes / attachments.
- Available Before / After.
- Stock Requests.
- Approval / Reject.
- Convert Request → Requisition.
- Printable / document-oriented warehouse workflows.

المصادر:
- https://docs.daftra.com/en/user_manual/transferring-items-from-one-warehouse-to-another/
- https://docs.daftra.com/en/user_manual/stock-requests/
- https://docs.daftra.com/en/user_manual/inventory-and-products-settings-comprehensive-guide/

---

# 15. Competitive Gap — النقص الحقيقي في RAWAEA

هذه ليست أعطالًا حالية؛ هي Business Contracts غير مكتملة بعد:

| capability | RAWAEA current | القرار |
|---|---|---|
| Internal Transfer | موجود | مغلق |
| Direct Van Stock | موجود | مغلق |
| Direct Return | موجود | مغلق |
| Supplier Return | موجود | مغلق |
| Barcode item search | موجود | مغلق |
| Realtime refresh | موجود | مغلق |
| Idempotent CREATE | موجود | مغلق |
| Idempotent RECEIVE | موجود | مغلق |
| Audit / movement readback | موجود | مغلق |
| Historical Stock Before / After | غير مثبت كمعلومة محفوظة تاريخيًا | Contract مفتوح |
| Attachments | غير موجود كـvoucher contract | Contract مفتوح |
| Approval / Reject | غير موجود كـvoucher contract مستقل | Contract مفتوح |
| Stock Request → Voucher | غير موجود | Contract مفتوح |
| Lot / Serial / Expiry | غير معتمد في هذا العقد | لا يُبنى الآن |
| In-Transit lifecycle | غير معتمد كعقد مستقل | لا يُبنى الآن |
| Bulk CSV / Paste | غير موجود | Contract + UX مفتوح |
| Formal Print / Export | غير موحد | Contract مفتوح |

**القاعدة:** لا نُدخل أيًا من هذه الوظائف لمجرد أن المنافس يملكها. كل وظيفة تحتاج Business Contract RAWAEA قبل إنشاء schema أو UI أو workflow.

---

# 16. لماذا لم يتم تعديل Production في هذه الجولة؟

لأن التحقيق أثبت:

1. Physical Stock core سليم.
2. DirectReturn lifecycle موجود في Production.
3. Branch / Company scope محكم.
4. Internal Core ACL مغلق.
5. Idempotency موجود.
6. E2E backend ناجح.
7. العطل الحالي UI-only داخل `renderCats`.
8. أي تعديل Production إضافي سيكون تغييرًا غير ضروري.

**لا Migration جديدة مطلوبة لهذا الإصلاح.**

---

# 17. Browser E2E

الاختبار الحالي الذي تم تنفيذه هنا = Production/backend transactional E2E.

ما لم يُثبت بعد في هذه الجلسة:

- credential-backed browser login على المتصفح الحقيقي.
- تنفيذ الضغط الفعلي على تبويب التصنيف بعد إدخال patch.

لذلك لا يتم تسجيل Browser E2E = 100%.

بعد تطبيق Owner Patch يجب اختبار:

```
Login
→ Voucher App
→ New Voucher
→ اختيار المصدر
→ الضغط على أكثر من Category
→ ظهور المنتجات الصحيحة
→ Add Item
→ Save Draft
→ Mother → Vouchers
→ البحث والفلترة
```

---

# 18. Closure Status

## CLOSED

- Historical reconstruction.
- Mother/Standalone architecture mapping.
- Production voucher core verification.
- Physical Writer centralization.
- Branch scope / ACL.
- Core direct bypass.
- Current source boot path.
- Current SW path.
- Current `filterList`.
- Current `App.init`.
- Current `allowedBranch`.
- Current `pickArr`.
- Backend CREATE/SEND/RECEIVE/COMPLETE E2E.
- No test residue.

## OPEN — Owner Source Patch

- `renderCats` فقط.

---

# 19. التعليمات الدائمة للمساعد التالي

لا تبدأ من الصفر.

1. اقرأ هذا التقرير ثم `CURRENT_STATE.md`.
2. افحص آخر HEAD في مستودعي النظام والتطبيق.
3. افحص SHA الحالي لـ `vouchers.html`.
4. لا تعيد Patch A/B/C.
5. لا تعيد `App.init` أو `allowedBranch` أو `pickArr` ما لم يثبت Regression.
6. تأكد أن `renderCats` لم يعد يبني inline `App.catSet(JSON.stringify())`.
7. شغّل static syntax.
8. نفذ browser test على التصنيف.
9. طابق ظهور voucher في Mother.
10. أعد قراءة Production counts.
11. لا تنشئ Edge Function جديدة.
12. لا تفتح Business Contract جديدًا قبل إغلاق هذا الـConsumer.

---

# 20. SELF-AUDIT

### What was proved
- السبب الحالي لخطأ التصنيف مثبت من source.
- المشكلة ليست Tailwind warning.
- المشكلة ليست SW 404 في المصدر الحالي.
- المشكلة ليست `filterList`.
- Production Contract للأذونات سليم.
- DirectReturn مساره الحالي متعدد المراحل ومقصود.
- E2E backend يثبت عدم تكرار الحركة.
- لا يوجد Physical Writer موازي.

### What was fixed
في هذه الجلسة لم يتم تغيير source file؛ تم تجهيز **Owner surgical replacement** فقط، لأن سياسة النطاق تمنع تعديل `vouchers.html` مباشرة.

### What was not proved
- browser credential-backed E2E الحقيقي.
- نجاح الضغط الفعلي على Category بعد تطبيق patch.

### Final status
**WAREHOUSE VOUCHERS PRODUCTION CORE = CLOSED**

**STANDALONE VOUCHERS CONSUMER = OPEN FOR ONE SURGICAL OWNER PATCH: renderCats**

**No Production migration required.**

# END REPORT
