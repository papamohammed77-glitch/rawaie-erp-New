# Report331 — إغلاق عطل رفض تعديل مسودة تحويل فرع إلى فرع
## RAWAEA ERP — WAREHOUSE VOUCHERS DRAFT UPDATE DUPLICATE GUARD FORENSIC CLOSURE
التاريخ: 2026-09-24

### 1. الحقيقة المرجعية
تمت إعادة التحقق من:
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.
التقارير السابقة استُخدمت كسياق فقط.

### 2. الحالة الحالية التي تم إثباتها
System repository:
- آخر commit أنشأناه: 86e87aeb8cc4d5fcab3b3b19b238c47f441fbbe1
- parent: 1674614e50e4790ffb6d06bed4e2b09394a1d972
- migration إصلاح RPC: 20260924_fix_manual_voucher_update_itemcode_duplicate_guard.sql
- migration قيد uniqueness: 20260924_add_stock_voucher_detail_unique_item_guard.sql

Mother frontend:
- HEAD: 53b254de274af504022d0acf13becc40378bd4aa
- parent: 80e42653a4a83874ab739b8a87e7ddc4f407e6e4
- vouchers.html SHA: 287f9900efdf1ee595f6537e9d230ef06e347c06
- vouchers.html = 4395 lines
- full inline JavaScript parse = PASS
- لم يتم تعديل vouchers.html في هذا الإغلاق
- لم يتم تعديل main.html

### 3. العطل الفعلي
الأعراض:
POST /functions/v1/create-stock-voucher
HTTP 400
الرسالة: لا يجوز تكرار الصنف داخل نفس الإذن

المسار المثبت:
vouchers.html
→ RW_API.call('create-stock-voucher', action=update)
→ create-stock-voucher Version 12
→ update_manual_stock_voucher_atomic

### 4. التحقيق الجنائي
Current vouchers.html يكوّن editItems بصيغة:
itemCode / itemName / unit / qty / unitPrice / notes
ثم يرسلها إلى Edge الحالي.

Edge Version 12 يطبع البيانات إلى UPDATE RPC مع JWT المستخدم.

Production RPC كان يحتوي الحارس التالي:

~~~
IF EXISTS(
  SELECT 1
  FROM jsonb_to_recordset(p_items) AS x(itemCode text)
  GROUP BY x.itemCode
  HAVING count(*)>1
) THEN
  RAISE EXCEPTION 'لا يجوز تكرار الصنف داخل نفس الإذن';
END IF;
~~~

سبب الخطأ مثبت:
PostgreSQL تطبع الاسم غير المقتبس itemCode إلى itemcode، بينما JSON يستخدم المفتاح camelCase وهو itemCode.
لذلك قيمة الحقل المقروء بواسطة هذا الحارس تصبح NULL للصفوف، وعند إرسال أكثر من صنف يتم اعتبارها مجموعة واحدة ويُرفض الطلب على أنه مكرر.

هذا يفسر لماذا فشل طلب تعديل بخمسة أصناف مختلفة بنفس رسالة التكرار.

### 5. الإصلاح الجراحي في Production
تم تغيير الحارس فقط إلى:

~~~
IF EXISTS(
  SELECT 1
  FROM jsonb_array_elements(p_items) AS z(value)
  GROUP BY btrim(z.value->>'itemCode')
  HAVING count(*)>1
) THEN
  RAISE EXCEPTION 'لا يجوز تكرار الصنف داخل نفس الإذن';
END IF;
~~~

Migration:
20260924113537
fix_manual_voucher_update_itemcode_duplicate_guard

لم يتم تغيير:
- Business Contract
- Physical Stock Engine
- Transfer lifecycle
- Edit workflow
- Submit workflow
- Edge Function count
- Mother frontend

### 6. دفاع قاعدة البيانات
قبل تطبيق القيد تم إثبات أن duplicate voucher/item = 0.

تم تطبيق:
UNIQUE (voucher_id, item_id)

اسم القيد:
stock_voucher_details_voucher_item_key

Migration:
20260924113616
add_stock_voucher_detail_unique_item_guard

الهدف:
منع أي Consumer مستقبلي من تخزين الصنف مرتين داخل نفس الإذن حتى لو تجاوز الحارس البرمجي.

### 7. الاختبارات
#### Test A — positive
تم استخدام مستخدم Production الحقيقي:
vouchers@rawaea.com
role = مخزني
active_warehouse_role = أذونات
status = Active

تم إرسال خمسة أصناف مختلفة:
1001
1003
1004
1005
1006

بعد الإصلاح:
SUCCESS

داخل Transaction:
detail_rows = 5
distinct_items = 5

ثم ROLLBACK.

#### Test B — negative
تم إنشاء Voucher مؤقت داخل Transaction، ثم إرسال:
1001
1001

النتيجة:
REJECT
لا يجوز تكرار الصنف داخل نفس الإذن

ثم ROLLBACK.

إذن السلوك النهائي:
Unique input = PASS
Duplicate input = REJECT

### 8. إصلاح بيانات Production
أثناء التحقيق الحالي تم اكتشاف QA vouchers حديثة في Production:
IN-1
IN-2

ولا يوجد ارتباط مثبت بينهما وبين Orders أو Runsheets.

IN-1 كان يحتوي 5 TransferOut movements.
تم عكس هذه الحركات الخمس باستخدام post_stock_movement / InventoryIncrease ثم إزالة سجلات الاختبار والأذون الرسمية.

تم تسجيل عملية Data Repair في audit_log باستخدام action المعتمد delete.

نتيجة التنظيف:
voucher residue = 0
inventory_log QA residue = 0
linked operation residue = 0

تم استبقاء stock_voucher_operations غير المرتبطة فقط كتومبستونات تشغيلية، وهو سلوك مقصود للعناية بـ idempotency/history.

### 9. Snapshot Production النهائي
companies = 1
branches = 4
items = 16
stock_vouchers = 0
stock_voucher_details = 0
stock_voucher_operations = 13
inventory_log = 11
stock_branches = 48
audit_log = 2171

duplicate voucher/item keys = 0

رصيد BR-01 بعد عكس QA:
1001 = 12
1003 = 11
1004 = 12
1005 = 11
1006 = 13

### 10. التحقق من Physical Stock Core
ما زال العقد:
Voucher capability
→ Voucher RPC
→ post_stock_movement
→ stock_branches + inventory_log

لا يوجد Physical Stock writer موازٍ في هذا الإغلاق.

### 11. قرار vouchers.html
لا يوجد تعديل جراحي جديد مبرر في:
companies/company-1/warehouse/vouchers.html

الإجراء:
لا تحذف شيئًا.
لا تستبدل دالة.
لا تضف كودًا.

السبب:
الواجهة الحالية ترسل itemCode صحيحًا.
Edge الحالية تمرر نفس العقد.
الخلل كان في Production RPC وتم إصلاحه.
أي تعديل إضافي على editVoucher أو submit بدون Current evidence سيكون regression risk غير مبرر.

### 12. قرار main.html
main.html لم يتم تعديله.
ولا يحتاج تعديلًا لهذا العطل.

### 13. Edge Function
create-stock-voucher:
Version 12
ACTIVE
verify_jwt = false مع custom authentication عبر supabase.auth.getUser

في مسار UPDATE يتم تمرير JWT للمستخدم إلى RPC client.
لا Edge Function جديدة.
تم الالتزام بحد وظائف المشروع.

### 14. المنافسون — ما ثبت كمرشحات Business Contract مستقبلية
Odoo:
- Barcode operations
- transfers
- batch operations

Dynamics 365 Business Central:
- transfer orders
- shipment/receipt
- in-transit visibility

SAP:
- one-step / two-step transfer
- stock in transfer

Daftra:
- source/destination
- quantity
- before/after visibility
- detailed movement reports

Manager:
- date/reference/description/item/qty/from/to

فجوات RAWAEA المرشحة مستقبلًا:
- in-transit dashboard
- ETA / expected receipt
- transit aging
- attachments/proof
- approval workflow
- batch/wave transfer
- lot/serial/expiry
- bins/sublocations
- richer movement timeline
- saved analytical filters

لم يتم اختراع أي منها داخل هذا العطل لأنها تحتاج Business Contract مستقلًا وتأثيرًا معماريًا أوسع.

مصادر المنافسين:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations.html
https://learn.microsoft.com/en-us/dynamics365/business-central/inventory-how-transfer-between-locations
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE
https://docs.daftra.com/en/user_manual/transferring-items-from-one-warehouse-to-another/
https://docs.daftra.com/en/tutorial/inventory-detailed-transactions-report/
https://www2.manager.io/guides/10707

### 15. Browser E2E
Authenticated Browser E2E على الـserved artifact النهائي لم يتم إثباته في أدوات التنفيذ الحالية.
لذلك:
RPC PASS لا يساوي Browser PASS.
Static parse PASS لا يساوي Browser PASS.

هذه النقطة تبقى OPEN حتى تتوفر جلسة Browser مصادق عليها.

### 16. SELF-AUDIT
What I Proved:
- Current source and current production path.
- Exact root cause in PostgreSQL JSON field resolution.
- Surgical Production fix.
- Positive unique-item UPDATE.
- Negative duplicate-item rejection.
- Database uniqueness invariant.
- QA cleanup and audit trail.
- No new Edge Function.
- No frontend modification needed.
- Physical stock centralization preserved.

What I Did Not Prove:
- Authenticated Browser E2E على artifact المنشور فعليًا.

What I Initially Missed:
- تم أولًا الاشتباه في cart reconstruction.
- Current evidence أثبت أن cart كانت ترسل itemCode الصحيح وأن العيب في SQL identifier resolution.

Conflicts Resolved:
- historical QA-clean statements were superseded by current Production evidence showing IN-1/IN-2 existed; they were cleaned now.

### 17. FINAL STATUS
Production Draft Update duplicate guard = CLOSED / VERIFIED
Database uniqueness invariant = CLOSED / VERIFIED
QA data cleanup = CLOSED / VERIFIED
Physical Stock centralization = CLOSED / VERIFIED
Current vouchers.html syntax = CLOSED / VERIFIED
Current Edge integration = CLOSED / VERIFIED
vouchers.html surgical patch for this incident = NONE REQUIRED
main.html = UNTOUCHED
Authenticated Browser E2E = OPEN / UNVERIFIED
Served artifact identity = OPEN / UNVERIFIED

Overall current incident:
PRODUCTION CLOSED.
UI browser closure remains OPEN only for lack of authenticated browser evidence.

### 18. نقطة الاستئناف الدقيقة للمساعد القادم
1. Verify System HEAD = 86e87aeb8cc4d5fcab3b3b19b238c47f441fbbe1.
2. Verify parent = 1674614e50e4790ffb6d06bed4e2b09394a1d972.
3. Verify Mother HEAD = 53b254de274af504022d0acf13becc40378bd4aa.
4. Verify vouchers SHA = 287f9900efdf1ee595f6537e9d230ef06e347c06.
5. Verify Production function contains jsonb_array_elements(p_items) + itemCode.
6. Verify constraint stock_voucher_details_voucher_item_key.
7. Do not reopen this fix.
8. Do not modify vouchers.html or main.html for this incident.
9. If Browser becomes available, test:
   login
   → Warehouse
   → Inventory/Vouchers
   → Draft Transfer
   → Edit
   → Save unique 5 items
   → Console/Network
   → verify DB
   → retry same operation_id
10. Take Production snapshot in the same reporting moment.
11. Update CURRENT_STATE.

# END REPORT331
