# Report280 — Warehouse Vouchers Standalone / `this.summary is not a function` — Forensic Surgical Closure
التاريخ: 2026-09-21
النطاق: `erp-frontend/companies/company-1/warehouse/vouchers.html`
Production Project: `fiilmooggumokxanwiyx`

## 1. Scope Lock
- تم إيقاف أي توسع خارج تبويب الأذونات المخزنية.
- `erp-frontend/companies/company-1/main.html` لم يتم لمسه.
- `erp-frontend/companies/company-1/warehouse/vouchers.html` لم يتم تعديله في Git وفق قيد الجلسة؛ تم إعداد التعديل الجراحي فقط.
- لا تم إنشاء Edge Function جديدة.
- لم يتم تنفيذ DDL إضافي في Production لهذه المشكلة لأن العقد الخلفي المثبت كان مكتملًا ولا يوجد خلل Production ثابت يبرر تغييرًا جديدًا.

## 2. CURRENT GIT — SYSTEM REPOSITORY
آخر commit مثبت في مستودع النظام:
`1cad6184e5a818b980b3c7fb5ae94cceb39c4536`
رسالة: `state: update current Mother voucher live forensic checkpoint`

الـparent:
`73a7b13fa8652994d6d7b5fad0f1f2a39c9053ff`

آخر تقرير حاكم للتبويب:
`Report279_WAREHOUSE_VOUCHERS_MOTHER_LIVE_FORENSIC_SURGICAL_CONTINUATION_20260921.md`

## 3. CURRENT GIT — FRONTEND REPOSITORY
الملف المستهدف:
`companies/company-1/warehouse/vouchers.html`

الحالة الحالية:
- Blob SHA: `3adf031cfb073c87db10c562c1b3e7d568bb61fd`
- آخر commit غيّر الملف:
  `a2de64c150c9e38f14af0c2ecafcbcd9861fa9cd`
- Parent:
  `f2229bec9106f1c4836769b1eccda3cc48d4a482`

الـcommit `a2de...` أعاد هيكلة `renderCart` وأضاف تحسينات صحيحة، لكنه حذف تعريف `summary:function(){...}` الموجود في الـparent دون إزالة الاستدعاءات المعتمدة عليه.

## 4. ROOT CAUSE — PROVEN
CURRENT SOURCE:
- `this.summary()` أو `s.summary()` موجودة 3 مرات.
- تعريف `summary:function(` = صفر.

مواضع الاستدعاء المثبتة في CURRENT SOURCE:
- السطر 483 تقريبًا داخل `pickSelect`
- السطر 485 تقريبًا في نهاية `renderWorkspace`
- السطر 622 تقريبًا داخل `updateSource`

الدالة التاريخية الصحيحة موجودة في الـparent `f2229...`، ونصها الكامل هو:

```js
summary:function(){var t='',fr=RW_UI.byId('wsFrom'),re=RW_UI.byId('wsRep'),to=RW_UI.byId('wsTo');if(fr&&fr.value)t+=(this.type==='DirectReturn'?'المركبة: ':'المصدر: ')+this.loc(fr.value,this.type==='DirectReturn'?'Vehicle':'Branch');if(re&&re.value){var r=this.refs.reps.find(function(x){return x.id===re.value});if(r)t+=(t?' · ':'')+'المندوب: '+(r.name||r.email)}if(to&&to.value)t+=(t?' · ':'')+(this.type==='DirectSale'?'المركبة: ':this.type==='SupplierReturn'?'المورد: ':'الوجهة: ')+this.loc(to.value,this.type==='DirectSale'||this.type==='DirectReturn'?'Vehicle':this.type==='SupplierReturn'?'Supplier':'Branch');RW_UI.safeText(RW_UI.byId('routeSummary'),t||'حدد عناصر المسار');RW_UI.safeText(RW_UI.byId('stockHint'),this.sourceBranch()?'المتاح محسوب من المصدر المحدد':'اختر المصدر لمعرفة المتاح')},
```

### Runtime reproduction
تم تنفيذ smoke runtime على CURRENT SOURCE:
`TypeError: App.summary is not a function`

### Runtime after surgical in-memory patch
بعد إدراج الدالة التاريخية نفسها قبل `updateSource`:
- `App.summary` = function
- `App.updateSource` = function
- استدعاء `App.summary()` نجح
- `routeSummary` عاد للقيمة: `حدد عناصر المسار`

Embedded JavaScript parser:
- CURRENT = PASS نحويًا.
- Patched = PASS نحويًا.
العيب Runtime object contract وليس Parser SyntaxError.

## 5. REQUIRED OWNER SURGICAL PATCH
### الملف
`papamohammed77-glitch/erp-frontend/companies/company-1/warehouse/vouchers.html`

### لا تبحث عن `summary:function`
لأنها غير موجودة في CURRENT SOURCE.

### ابحث عن هذا العنصر تحديدًا داخل كائن App:
```js
updateSource:function(){this.summary();this.renderProducts()},
```

الموضع الحالي:
السطر 622 تقريبًا.

### احذف هذا العنصر كاملًا
```js
updateSource:function(){this.summary();this.renderProducts()},
```

### واستبدله بالكامل بهذا النص
```js
summary:function(){var t='',fr=RW_UI.byId('wsFrom'),re=RW_UI.byId('wsRep'),to=RW_UI.byId('wsTo');if(fr&&fr.value)t+=(this.type==='DirectReturn'?'المركبة: ':'المصدر: ')+this.loc(fr.value,this.type==='DirectReturn'?'Vehicle':'Branch');if(re&&re.value){var r=this.refs.reps.find(function(x){return x.id===re.value});if(r)t+=(t?' · ':'')+'المندوب: '+(r.name||r.email)}if(to&&to.value)t+=(t?' · ':'')+(this.type==='DirectSale'?'المركبة: ':this.type==='SupplierReturn'?'المورد: ':'الوجهة: ')+this.loc(to.value,this.type==='DirectSale'||this.type==='DirectReturn'?'Vehicle':this.type==='SupplierReturn'?'Supplier':'Branch');RW_UI.safeText(RW_UI.byId('routeSummary'),t||'حدد عناصر المسار');RW_UI.safeText(RW_UI.byId('stockHint'),this.sourceBranch()?'المتاح محسوب من المصدر المحدد':'اختر المصدر لمعرفة المتاح')},
updateSource:function(){this.summary();this.renderProducts()},
```

### لا تعدل
- `renderWorkspace`
- `pickSelect`
- `renderCart`
- `filterList`
- `loadList`
- `receive`
- `details`
- `submit`
- `core.js`
- `register-sw.js`
- `main.html`

## 6. WHY THIS IS THE CORRECT FIX
هذا ليس إعادة بناء.
الـfunction مفقودة فقط، بينما:
- جميع المستهلكين ما زالوا يستخدمون `summary()`.
- الـDOM المستهدف `routeSummary` و`stockHint` ما زال موجودًا.
- الـhelper نفسه مثبت في الـparent التاريخي.
- إعادة الدالة تعيد العقد الذي اعتمد عليه `pickSelect` و`renderWorkspace` و`updateSource`.

لذلك لا يتم استبدال الاستدعاءات ولا إعادة تصميم الـworkflow.

## 7. STANDALONE APP ROLE — VERIFIED CONTRACT
التطبيق المستقل يقوم بالعمليات المخزنية اليدوية غير المرتبطة مباشرة بسلسلة Order/Runsheet:
- Transfer
- DirectSale
- DirectReturn
- SupplierReturn

ويبقى:
- Scrap / Adjustment على Adjustment Engine المنفصل.
- Order/Runsheet fulfillment خارج هذا التطبيق.

التكامل:
Mother / standalone
→ نفس `stock_vouchers`
→ نفس voucher RPC/control plane
→ Physical Stock:
`post_stock_movement`
→ `stock_branches + inventory_log`

ولا يوجد إنشاء لنموذج تاريخي ثانٍ.

## 8. PRODUCTION — CURRENT FACT
Production current snapshot:
- companies = 1
- active_branches = 2
- active_items = 16
- stock_vouchers = 0
- stock_voucher_details = 0
- inventory_log = 3
- audit_log = 2023
- stock_voucher_operations = 0

Current Voucher RPC contract موجود بالفعل:
- `create_manual_stock_voucher_atomic`
- `send_stock_voucher_atomic`
- `post_manual_stock_voucher_atomic`
- `complete_manual_stock_voucher_atomic`
- `cancel_manual_stock_voucher_atomic`
- `inventory_voucher_report`
- `post_stock_movement`

Current Edge:
- create-stock-voucher v10
- send-stock-voucher v20
- receive-stock-voucher v22
- complete-stock-voucher v4
- cancel-stock-voucher v4

No Production change was justified by the `summary()` defect.

## 9. PHYSICAL WRITER FORENSICS
Current Production search أثبت أن:
- `post_stock_movement` هو الـPhysical Writer المركزي الذي يعدل `stock_branches` ويكتب `inventory_log`.
- `reserve_stock` و`release_stock_reservation` لا ينفذان Physical Movement؛ هما Reservation Engine فقط.
- لا يوجد trigger على `stock_branches` أو `inventory_log` ينفذ Physical Movement إضافيًا.
- Voucher writers تصل إلى `post_stock_movement`.
- لذلك Physical Writers outside `post_stock_movement` = 0 في النطاق المثبت.

## 10. SERVICE WORKER — FORENSIC RESULT
CURRENT standalone `vouchers.html` يحتوي:
```js
RW_SW.register('../sw.js')
```

CURRENT `core.js` ينفذ:
```js
navigator.serviceWorker.register(path)
```
مع default/path المرسل كما هو.

والملف الموجود فعليًا:
`companies/company-1/sw.js`

يوجد أيضًا:
`companies/company-1/register-sw.js`
وهو يحتوي على:
```js
navigator.serviceWorker.register('./sw.js', {scope:'./'})
```

لا يوجد:
`companies/company-1/warehouse/sw.js`

الـ404 الذي ظهر في Console:
`/companies/company-1/warehouse/sw.js`

لا يصدر من CURRENT standalone `vouchers.html` نفسه؛ CURRENT standalone يطلب `../sw.js`، أي ملف `companies/company-1/sw.js`.

الاستنتاج:
- لا يجوز تعديل Service Worker path داخل `vouchers.html` لأن المصدر الحالي صحيح.
- سبب 404 المتبقي مرتبط بمسار/نسخة runtime أخرى تستدعي `register-sw.js` أو بنسخة cached أقدم؛ لا يوجد إثبات كافٍ لتغيير ملف آخر في هذه الجولة.
- لا يتم اختراع patch على `register-sw.js` بدون runtime evidence جديد.
- لا توجد علاقة سببية بين 404 Service Worker و`this.summary is not a function`.

## 11. COMPETITIVE GAP — WHAT WAS VALIDATED
المقارنة الحالية مع الأنظمة المنافسة تؤكد أن البناء الموجود في RAWAEA يحتوي على نفس المبادئ الجوهرية:
- Source / Destination
- stock movement ledger
- separate receipt/transfer lifecycle
- explicit movement history
- stock visibility before/after كـread model
- inventory adjustment كمسار منفصل

Odoo:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/inventory_valuation/operations_valuation.html
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/reporting/moves_history.html

Dynamics 365:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/inventory-journals
https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/configure-transfer-order-receiving-process

SAP:
https://help.sap.com/docs/s4hana-cloud-best-practices/stock-transfer-with-delivery-bme-sa/post-goods-receipt-for-stock-transport-order

Daftra:
https://docs.daftra.com/en/tutorial/transferring-stock/
https://docs.daftra.com/en/tutorial/inventory-detailed-transactions-report/

Manager.io:
https://www2.manager.io/guides/10707
https://www2.manager.io/guides/10709

لا تم إدخال Business Contract جديد في هذه الجولة بدون عقد مثبت.

## 12. E2E STATUS
### Static / In-memory E2E
- Current source object construction = PASS.
- Current defect reproduction = PASS.
- Surgical patch object construction = PASS.
- `App.summary()` after patch = PASS.
- `routeSummary` render after patch = PASS.

### Production
- Current clean state verified.
- No voucher residue.
- No data repair required.
- No new Edge Function.

### Browser
Browser click-through was not executable with the currently available toolset in this session.
لذلك لا يتم تحويل:
`In-memory PASS`
إلى:
`Browser PASS`

Final Browser gate remains:
1. open standalone vouchers
2. Transfer workspace
3. source/destination selection
4. add item
5. verify routeSummary
6. save Draft
7. send
8. receive
9. complete
10. duplicate retry
11. verify Mother unified history
12. final Production reread

## 13. GOVERNANCE SELF-AUDIT
### Confirmed
- Current system HEAD/parent checked.
- Current frontend HEAD/current vouchers SHA checked.
- Parent vouchers SHA checked.
- Current vouchers source inspected.
- Historical source inspected.
- Current Production schema/RPCs checked.
- Current Edge versions checked.
- Physical writer discovery checked.
- Service Worker source paths checked.
- Runtime error reproduced in controlled object smoke.
- Surgical patch verified in memory.
- No main.html write.
- No vouchers.html write.
- No new Edge Function.
- No unjustified Production DDL/data change.

### Unknown / Not proven
- Live browser click-through after owner patch.
- Exact runtime initiator of the `warehouse/sw.js` 404 in the currently served page.
- Positive DirectSale/DirectReturn/SupplierReturn browser flow against current Production because real active vehicles = 0 and Purchase Orders = 0.

## 14. CLOSURE STATUS
- Root Cause `this.summary is not a function` = PROVEN
- Surgical Fix = READY
- In-memory Verification = PASS
- Production Voucher Core = VERIFIED
- Physical Stock Centralization = VERIFIED
- Production Data Repair = NONE
- New Edge Function = NOT REQUIRED
- Standalone Source Commit = UNCHANGED BY THIS SESSION
- Mother main.html = UNTOUCHED
- Browser E2E = OPEN
- Full standalone voucher closure = PENDING OWNER PATCH + BROWSER E2E

## 15. NEXT SESSION INSTRUCTIONS
1. Read this report first.
2. Re-fetch current `vouchers.html` blob SHA before editing.
3. Search exactly:
`updateSource:function(){this.summary();this.renderProducts()},`
4. Replace exactly with the two-function block in section 5.
5. Do not reapply any older patches.
6. Run full-file JavaScript parse.
7. Open the page in browser and execute the Browser gate.
8. Verify Mother unified history.
9. Read Production immediately after browser E2E.
10. Record final Production snapshot.
11. Do not modify Service Worker files unless a new runtime trace identifies the caller of `warehouse/sw.js`.
12. Treat CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT + RUNTIME evidence as the only authoritative state.

## END REPORT280
