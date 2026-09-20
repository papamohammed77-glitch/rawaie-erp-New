# تقرير 272 — الإغلاق الجنائي الجراحي لتطبيق الأذونات المخزنية
التاريخ: 2026-09-20
النطاق: companies/company-1/warehouse/vouchers.html فقط. main.html لم يُلمس، وvouchers.html لم يُعدل من جهة CTO.

## 1. الحقيقة الحالية
System HEAD: 4d40ee2a2ffffc2e3a2169e0d632b0b486042f37
System parent: da627d4947a309a792f98459ffc117ddad03b381
Standalone vouchers current SHA: 550ef7284116828f540ce22b5938a056744c8404
Standalone source: 741 lines / 69,303 bytes
Mother main.html blob: 453565c39a50fdcf73eb03a97a1fc7d7ac10bb2f

Latest relevant vouchers commit:
bc747e2b7157c13bbb1d6dd6b33a9464778e9cd5
"Fix script source paths in vouchers.html"

هذا الـcommit أصلح Patch A بالفعل:
- core.js أصبح ../core.js
- أزيل var supabase=window.supabase

لا تعاد Patch A.

## 2. سبب الخطأ في Console
الـConsole المعروض يجمع حالة قديمة مع حالة أحدث.

قبل Patch A كان core.js يُطلب من warehouse/core.js ويعطي 404، فيغيب RW_UI وRW_SW وتفشل doLogin.

الحالة الحالية لم تعد تحتوي ذلك الخطأ في source.

المتبقي فعليًا في Current Source:
- line 739: RW_SW.register('sw.js')
- line 740: <script src="register-sw.js"></script>

لذلك:
- warehouse/sw.js = مسار خاطئ.
- warehouse/register-sw.js = مسار خاطئ وغير مطلوب.
- Tailwind CDN warning ليس سبب فشل الدخول.

Static in-memory validation بعد B/C:
- ../core.js = 1
- wrong core.js = 0
- ../sw.js registration = 1
- wrong sw.js registration = 0
- register-sw.js tag = 0
- filterList = 1 definition
- over-escaped JS = 0
- inline JS parser = PASS

## 3. الدور المعتمد للتطبيق
التطبيق هو Operational Consumer للحركات المخزنية غير المرتبطة بأوردر/رانشيت:
Transfer
DirectSale
DirectReturn
SupplierReturn

ويحتوي Workspace لأوضاع Scrap/Adjustment، لكن Production يعالجها عبر bulk-stock-adjustment وليس عبر stock_vouchers. لذلك لا نعيد تعريف هذا الـcontract دون قرار أعمال مثبت.

Mother مسؤول عن التحكم/الصلاحيات/فتح الوظيفة/الرؤية الموحدة.
Standalone مسؤول عن التنفيذ الميداني.
Production Core مسؤول عن قواعد الحركة.

Physical Stock Contract:
post_stock_movement
→ stock_branches + inventory_log

Current vouchers source لا يكتب stock_branches أو inventory_log مباشرة.

## 4. Production Current Truth
Supabase project: fiilmooggumokxanwiyx

counts:
companies=1
branches=2
items=17
stock_vouchers=0
stock_voucher_details=0
stock_voucher_operations=0
inventory_log=3

voucher user:
vouchers@rawaea.com
role=مخزني
active_warehouse_role=أذونات
status=Active
permissions=["warehouse"]
allowed_branch_ids=BR-01

الحساب موجود وصالح.

Production functions:
create_manual_stock_voucher_atomic (10 args)
create_manual_stock_voucher_atomic (12 args)
send_stock_voucher_atomic
post_manual_stock_voucher_atomic
complete_manual_stock_voucher_atomic
cancel_manual_stock_voucher_atomic
inventory_control(text,jsonb)
post_stock_movement (9/10 args)
reserve_stock

Existing Edge:
create-stock-voucher v10
send-stock-voucher v20
receive-stock-voucher v22
complete-stock-voucher v4
cancel-stock-voucher v4
bulk-stock-adjustment v7

No new Edge Function created.

## 5. Production E2E
تم تنفيذ Transactional E2E داخل Production ثم Rollback:
Create Transfer → Send → Receive → Retry Receive بنفس operation_id → Complete.

ثبت:
status=Completed
movement_count=2
unique movement keys=2
TransferOut=1
TransferIn=1
لا حركة ثالثة من Retry.

بعد Rollback:
stock_vouchers=0
stock_voucher_details=0
stock_voucher_operations=0
E2E logs=0

إذن Production Voucher Core صالح للتشغيل ولا يحتاج Migration إضافية لهذه المشكلة.

## 6. التعديل الجراحي الوحيد المطلوب من المالك
الملف:
erp-frontend/companies/company-1/warehouse/vouchers.html
SHA الحالي:
550ef7284116828f540ce22b5938a056744c8404

### PATCH B
ابحث حرفيًا داخل نهاية الـinline script عن:
RW_SW.register('sw.js')

السطر الحالي: 739

احذفه تمامًا واستبدله بـ:
RW_SW.register('../sw.js')

### PATCH C
ابحث حرفيًا في السطر 740 عن:
<script src="register-sw.js"></script>

احذفه تمامًا.

النهاية الصحيحة:
</script></body></html>

لا تضع بديلًا لـ register-sw.js.

## 7. ممنوع تعديل
لا تعدل:
doLogin
init
filterList
details
receive
submit
core.js
register-sw.js
sw.js
main.html
post_stock_movement
Receive idempotency
Inventory Core

هذه العناصر إما مثبتة أو مغلقة بالفعل.

## 8. المنافسة — ما هو موجود
Odoo 19 يوثق Internal Transfers وBarcode وInventory Adjustments وScrap.
Dynamics 365 يفصل Movement وInventory adjustment وTransfer وCounting وTag counting ويستخدم Transfer Order عندما يلزم تتبع in-transit.
SAP يعتمد Goods Issue/Goods Receipt/Transfer Posting مع مستندات حركة مادية.
Daftra يثبت Manual Transfer مع From/To/Notes/Qty وAvailable Before/After وUnit Price/Total، ويدعم bulk paste والصلاحيات والتقارير.
Manager.io يثبت Inventory Transfers وWrite-offs وLocations وتقارير الكمية/القيمة.

مصادر الويب الرسمية التي تمت مراجعتها:
- Odoo Inventory/Barcode/Scrap
- Microsoft Learn Inventory journals/Tag counting
- SAP Help Portal Goods Movements
- Daftra Knowledge Base
- Manager Guides

## 9. الفجوات الحقيقية التي لا يجوز اختراعها ترقيعًا
Before/After historical stock: غير مثبت لأن inventory_log لا يحفظ snapshot تاريخي.
Bulk Paste/CSV: غير موجود في Current Voucher consumer.
Approval workflow: لا يوجد عقد RAWAEA عام مستقل مثبت.
Attachments: لا يوجد contract مثبت على stock_vouchers.
Lot/Serial/Expiry: لا يوجد contract مثبت على Voucher identity.
Independent In-Transit stock model: غير مثبت.

هذه Business Contracts مفتوحة وليست Bugs. لا تُبنى من مجرد وجودها في المنافسين.

## 10. SELF AUDIT
What was proved:
- Current Source إلى EOF.
- Current SHA.
- System HEAD/parent.
- Latest relevant frontend commit.
- Mother current blob.
- Production user.
- Production RPCs/Edge versions.
- Central movement contract.
- Full transactional E2E.
- Retry no-duplication.
- Rollback cleanup.
- Patch A already applied.
- B/C are the remaining source boot defects.

What was not proved:
- Browser E2E بعد تطبيق B/C.
- Final deployed artifact بعد نشر owner patch.

Final:
Voucher Production Core = CLOSED
Voucher Source Boot = B/C READY
Standalone Voucher Consumer = OPEN until browser E2E
Mother = UNTOUCHED
New Edge Functions = 0

## 11. تعليمات الجلسة التالية
ابدأ دائمًا من:
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT

ثم:
1. تحقق من SHA.
2. تحقق من B/C حرفيًا.
3. افحص deployment artifact وليس Git فقط.
4. نفذ Browser E2E.
5. افحص network وConsole.
6. افحص voucher movements/idempotency.
7. بعد النجاح فقط غيّر حالة Standalone Voucher Consumer إلى CLOSED.

لا تعيد Patch A أو أي نقطة أُغلقت دون Regression مثبت.

# END REPORT 272
