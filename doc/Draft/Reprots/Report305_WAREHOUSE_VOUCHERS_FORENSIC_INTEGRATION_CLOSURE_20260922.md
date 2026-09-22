# تقرير 305 — إغلاق جنائي وتكامل تطبيق الأذونات المخزنية
## RAWAEA ERP — Warehouse Vouchers / DirectReturn / Van Sales Integration
التاريخ: 2026-09-22
الحالة: Backend + Production + Source Integrity CLOSED، Browser Authenticated E2E غير مثبت بأداة متصفح مباشرة.

---

## 1. قاعدة الحالة المعتمدة

الحالة الحالية لم تُبنَ على التقارير السابقة كحقيقة تشغيلية. تم التحقق من:
- CURRENT System Git
- CURRENT Frontend Git
- CURRENT Source
- CURRENT Supabase Production
- CURRENT Database Schema / RPCs / Triggers
- CURRENT Edge Deployments
- Persistent QA data
- Global Physical-Writer discovery

System Git قبل هذا الإغلاق:
HEAD = 0912800c500bf508ad20ddea4971dc2639b07f2d
Parent = 28b4a9b8848d942cf3a455c87bd929280c0c2356

Frontend Git:
HEAD = 1c386e5f5be1212e231672c1baaab676c54fe38c
Parent = b6a9c47a67037d414c1f08b0866231ccf0218413

Current vouchers.html:
Blob = 08054b20991e80a2527d4caf1463a4cda27a1641
2,569 lines
6 inline scripts
6/6 JavaScript parse PASS

Current van-sales.html:
Blob = 445dff4217fbf4a82f333fa716bba5d74def7680
2,124 lines
8 inline scripts
8/8 JavaScript parse PASS

---

## 2. ما ثبت تاريخيًا وما لم يُعاد إصلاحه

إصلاحات V-304 الخاصة بـ:
- JavaScript escaping
- Top panel collapse
- Supplier smart dropdown / fail-closed
- Vehicle picker / mobile branch
- DirectSale / DirectReturn
- KPI lifecycle
- Van Sales integration
- Physical Stock centralization

موجودة بالفعل في CURRENT SOURCE، ولم تتم إعادة تنفيذها.

لم يتم تعديل:
- vouchers.html
- van-sales.html
- main.html

---

## 3. الدور المعتمد للتطبيق

vouchers.html هو التطبيق التنفيذي المستقل للأذونات والحركات المخزنية غير المرتبطة بدورة Order/Runsheet.

هو ليس نظام مخزون مستقلاً.

التدفق المعتمد:

Main ERP
→ Warehouse / Inventory
→ Stock Vouchers
→ existing Edge capability
→ canonical RPC
→ post_stock_movement
→ stock_branches + inventory_log
→ Audit / KPI / Accounting / Supplier / Vehicle effects

أما:
Order → Picking → Loading → Delivery → Return

فهي سلسلة ميدانية مستقلة ولم يتم دمجها داخل vouchers.

---

## 4. مطابقة النظام الأم

main.html يثبت وجود:
إدارة المخازن والمخزون
- الأصناف
- المخازن والفروع
- مركز التحكم في المخزون
- العمليات المخزنية
- الأذونات المخزنية
- الجرد

وتحت الأذونات:
- تحويل مخزني
- صرف سيارة بيع مباشر
- استلام مرتجع سيارة
- مرتجع لمورد
- عرض الأذونات

لم يتم تعديل هذا البناء.

---

## 5. النتيجة الجنائية الرئيسية

النقص الفعلي الذي ظهر من Production لم يكن في أساس الواجهة الحالية.

الفجوات المثبتة كانت:
1. بعض voucher RPC authorization paths تحتاج Company Scope أكثر صرامة.
2. Audit actor يمكن أن يظهر تاريخيًا كـsystem عندما لا يتوفر JWT actor داخل trigger.
3. Operation Identity المرسل من التطبيق لم يكن ينتقل دائمًا إلى audit.
4. مسار DirectReturn اليدوي كان يحتاج توحيد mobile branch مع canonical vehicle identity.

تم إصلاح هذه النقاط داخل Production دون إنشاء Edge Function جديدة.

---

## 6. Production Hardening — Voucher Authorization + Audit

تم تطبيق migration:
voucher_audit_operation_identity_hardening_20260922_v2

ما تم إغلاقه:
- Company-scoped actor validation في CREATE/POST/SEND/COMPLETE/CANCEL.
- app.operation_id propagation.
- app.user_email propagation.
- audit actor resolution.
- audit company attribution.
- audit operation identity.

QA دائم:
IN-14
Operation:
QA-AUDIT-OP-20260922-01

تم إنشاؤه ثم إلغاؤه رسميًا.

Audit أثبت:
create → vouchers@rawaea.com
actor_user_id → 9a13c8c3-d2c9-4f75-8918-478b183a167a
company_id → الشركة الصحيحة
operation_id → QA-AUDIT-OP-20260922-01

والـcancel سجّل:
VoucherCancel:<company>:IN-14

---

## 7. Production Hardening — DirectReturn Mobile Branch

تم تطبيق migration:
direct_return_mobile_branch_convergence_20260922

قاعدة DirectReturn SEND الحالية:
1. vehicles.mobile_branch_id
2. fallback إلى VAN-<vehicle_code>

مع الحفاظ على:
- نفس Business Contract
- نفس operation identity
- نفس central stock engine

---

## 8. E2E دائم جديد — IN-15

تم إنشاء Item دائم:
ITM-1059
QA DirectReturn Mobile Branch 2026-09-22

Opening balance:
1

Opening location:
mobile branch للسيارة:
5372503d-f638-4e7f-808d-bda585825b2f

تم إنشاء opening balance بواسطة post_stock_movement.

Voucher:
IN-15
Type:
DirectReturn
Operation:
QA-E2E-MOBILE-BRANCH-DR-20260922-01

---

## 9. E2E Timeline

Created:
2026-09-22 14:02:13.890921+00

SEND:
2026-09-22 14:02:35.619324+00

RECEIVE:
2026-09-22 14:02:47.807939+00

COMPLETE:
2026-09-22 14:02:58.607327+00

---

## 10. Physical Movement Proof — IN-15

SEND:
movement_type = InventoryDecrease
qty = 1
source = mobile branch

idempotency:
DirectReturnOut:<company>:<voucher>:<item>

RECEIVE:
movement_type = DirectReturn
qty = 1
target = BR-01

idempotency:
ManualVoucher:RECEIVE:<company>:<voucher>:QA-E2E-MB-DR-RECV-20260922-01:<item>

COMPLETE:
status = Completed

---

## 11. Idempotency Proof

تمت إعادة نفس RECEIVE operation:

QA-E2E-MB-DR-RECV-20260922-01

النتيجة:
success = true
duplicate = true

ولم يتم إنشاء Movement ثانية.

---

## 12. Final stock proof — IN-15

للصنف ITM-1059:
BR-01:
qty = 1

VAN-VEH-TEST-260921:
qty = 0

allocated = 0

---

## 13. Audit Proof — IN-15

تم تسجيل:
1. create
2. SEND
3. RECEIVE
4. COMPLETE

وكلها تحتوي:
user_email = vouchers@rawaea.com
actor_user_id = 9a13c8c3-d2c9-4f75-8918-478b183a167a
company_id الصحيح
Operation Identity لكل مرحلة

---

## 14. DirectSale / DirectReturn Production Evidence

IN-9:
DirectSale
BR-01 → mobile vehicle stock
qty = 1
movement = DirectSale

IN-10:
DirectReturn
vehicle → InventoryDecrease
ثم Inventory → BR-01
movement = DirectReturn
ثم Completed

إعادة SEND لـIN-10 أعادت duplicate=true ولم تنشئ حركة ثانية.

---

## 15. SupplierReturn Production Evidence

IN-12:
Supplier = ابراهيم الأبيض
Supplier ID = 87c5a847-8e05-492e-a15d-30e0a5cc93cc

Physical:
SupplierReturn qty = 1

Financial:
Supplier Ledger Debit = 10
Journal = JE-SVR-IN-12
Debit Supplier AP = 10
Credit Inventory = 10

ERP Operation Registry:
- post_supplier_ledger_entry = completed
- post_journal_entry = completed

إعادة Complete أعادت duplicate=true دون إنشاء أثر مالي ثان.

النتيجة:
Supplier liability effect جزء رسمي من workflow.

---

## 16. Global Physical Writer Discovery

تم البحث في PostgreSQL عن:
- UPDATE stock_branches SET qty
- INSERT INTO inventory_log

النتيجة:
Physical Writer الوحيد المباشر المكتشف هو:
post_stock_movement

الاستثناءات:

reserve_stock
- يعدل allocated_qty
- Reservation فقط

release_stock_reservation
- يعدل allocated_qty
- Reservation فقط

setup_van_stock
- يهيئ صفوف المخزون بكمية صفر
- ليس حركة مخزنية

create_item_with_opening_stock
- يستدعي post_stock_movement عند وجود opening stock

بالتالي:

Physical Writers outside post_stock_movement = 0

---

## 17. Edge Function Constraint

لم يتم إنشاء Edge Function جديدة.

القائمة الحالية:
- create-stock-voucher v10
- send-stock-voucher v20
- receive-stock-voucher v22
- complete-stock-voucher v4
- cancel-stock-voucher v4

---

## 18. Current UI capability audit

موجود فعليًا:
- Pending / Completed / Account
- Transfer
- DirectSale
- DirectReturn
- SupplierReturn
- Scrap / Adjustment
- Smart supplier search
- Supplier↔Branch fail-closed
- Vehicle↔Rep validation
- Mobile branch handling
- Realtime
- lifecycle KPI
- Audit details
- Movement details
- operation identity
- scanner path

غير موجود كميزة UI صريحة:
- PDF/Print workflow
- Excel/CSV export
- Attachments workflow
- Advanced filter builder

هذه Competitive Feature Gaps وليست defects مثبتة في current contract.

---

## 19. Competitive comparison

Odoo:
- physical/count history
- counted vs on-hand vs difference
- barcode-assisted operations
- movement history

Dynamics 365 Business Central:
- transfer documents
- physical/cycle counting
- journal/reclassification
- preview/post discipline

SAP:
- movement type
- material/document history
- integrated accounting impact
- stock transfer / goods movement

Daftra:
- date/time
- warehouse
- customer/supplier
- notes
- attachments
- stock before/after
- detailed transaction reports
- advanced search
- printing/PDF

Manager.io:
- Date
- Reference
- Description
- Item
- Qty
- From
- To
- location-aware inventory

---

## 20. Owner-only surgical patch status — vouchers.html

الملف:
erp-frontend/companies/company-1/warehouse/vouchers.html

لا يوجد Bug جديد مثبت يستدعي patch جديد لهذه الجلسة.

لا تعاد إصلاحات V-304.

لا تحذف أو تستبدل:
- Top Panel logic
- Supplier smart-search logic
- KPI lifecycle logic
- operation-id logic
- DirectReturn validations
- parser fixes

الـcompetitive additions يمكن إعدادها كمرحلة owner patch منفصلة:
- print
- export
- advanced filters
- visible stock before/after
- value/cost summary
- attachments بعد اعتماد Business Contract

لم يتم تعديل الملف احترامًا لقاعدة owner-edit-only.

---

## 21. Git canonicalization

تمت إضافة migration 1:
supabase/migrations/20260922154500_voucher_audit_operation_identity_hardening_20260922.sql

Commit:
720724e7dab55b208d177d476982b1123fe6bdc7

تمت إضافة migration 2:
supabase/migrations/20260922155000_direct_return_mobile_branch_convergence_20260922.sql

Commit:
5c9bc25a53051b4e66c86fbbf989db4334ca82e9

---

## 22. Production Snapshot

Snapshot:
2026-09-22 14:00:16.993477+00

آخر snapshot قبل إضافة IN-15:
companies = 1
branches = 3
stock_vouchers = 14
stock_voucher_details = 16
stock_voucher_operations = 14
inventory_log = 11
audit_log = 2061

ثم أضيف IN-15 كـpersistent QA، ولذلك الأعداد النهائية أصبحت أعلى.

---

## 23. Browser Boundary

لم يتم تسجيل:
Authenticated Browser E2E = PASS

لأن جلسة التنفيذ لا توفر browser-authenticated runtime مباشرًا إلى artifact المنشور على Cloudflare.

تم إثبات:
- Source parse
- Production RPC execution
- Production stock effects
- idempotency
- authorization
- audit
- E2E business workflow
- persistent QA
- global writer discovery

لكن لم يتم تحويل Backend PASS إلى Browser PASS.

---

## 24. Final Self Audit

What was proved:
- Current System HEAD / Parent
- Current Frontend HEAD / Parent
- Current vouchers blob
- Current van-sales source
- Current main navigation
- Production voucher state
- DirectSale
- DirectReturn
- SupplierReturn
- Supplier ledger
- Journal
- Vehicle mobile branch
- Operation Identity
- Audit actor
- Global writer discovery
- No new Edge Function
- Git/Production alignment

What was not proved:
- Authenticated browser execution against the published Cloudflare artifact
- visual regression for any future owner-only feature patch

What was fixed:
- Company Scope hardening
- Audit actor hardening
- Operation identity propagation
- DirectReturn mobile branch convergence

What was not touched:
- main.html
- vouchers.html
- van-sales.html
- previously closed frontend repairs

---

## 25. سبب الأزمة النهائي

السبب لم يعد في Login ولا Supplier relation ولا KPI ولا Top Panel.

الـProduction forensic closure أثبت أن الباقي كان:
1. authorization context drift في بعض voucher RPC wrappers;
2. audit actor attribution drift;
3. operation identity drift داخل database trigger؛
4. DirectReturn manual path يستخدم identity legacy بدل canonical mobile branch.

تم إصلاحها في Production، وتم حفظ نفس الإصلاحات في Git.

أما المشكلة التاريخية الخاصة بتوقف الواجهة بسبب JavaScript parsing فقد كانت قد أغلقت بالفعل في CURRENT Frontend HEAD، ولذلك لم تُعاد.

---

## 26. إرشادات البداية للمساعد التالي

ابدأ من:
CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE

ثم:
1. تحقق من System HEAD النهائي وParent.
2. تحقق من Frontend HEAD.
3. تحقق من vouchers blob.
4. لا تعيد V-304.
5. لا تعدّل main.html.
6. لا تعدّل van-sales.html.
7. لا تنشئ Edge Function جديدة.
8. لا تنشئ Physical Stock writer.
9. إذا استؤنف العمل على vouchers.html، ابدأ فقط من Competitive Feature Gap.
10. أي attachment أو batch/lot/expiry/serial capability تحتاج Business Contract مستقل.
11. أي نسبة أو تقرير يجب أن يسبقه Production snapshot في نفس لحظة التقرير.
12. لا تعلن Browser PASS بدون Browser evidence.

---

## 27. Final Closure

PHYSICAL STOCK CENTRALIZATION = CLOSED

TENANT / COMPANY SCOPE = CLOSED FOR VOUCHER WRITERS

AUDIT ACTOR = CLOSED

OPERATION IDENTITY = CLOSED

DIRECTRETURN MOBILE BRANCH = CLOSED

DIRECTSALE = CLOSED

SUPPLIERRETURN FINANCIAL CONTRACT = CLOSED

GLOBAL PHYSICAL WRITERS OUTSIDE post_stock_movement = 0

NEW EDGE FUNCTIONS = 0

PERSISTENT QA = RETAINED

vouchers.html BUG REPAIR = CURRENT HEAD ALREADY FIXED

COMPETITIVE UI GAP = OWNER PATCH BACKLOG

AUTHENTICATED BROWSER E2E = UNVERIFIED

GLOBAL INVENTORY CORE = CLOSED at Production / Database / Source integrity level.

Browser runtime is the only unverified boundary.

# END OF REPORT 305
