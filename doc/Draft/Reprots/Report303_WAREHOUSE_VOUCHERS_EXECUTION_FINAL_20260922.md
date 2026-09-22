# تقرير 303 — الإغلاق التنفيذي النهائي لجولة الأذونات المخزنية
**التاريخ:** 2026-09-22  
**النطاق:** Warehouse Management → Stock Vouchers → `companies/company-1/warehouse/vouchers.html`  
**Production:** Supabase `fiilmooggumokxanwiyx`

---

## 1. قاعدة الحقيقة

تمت إعادة بناء الحالة من:

- CURRENT GIT
- CURRENT SOURCE
- CURRENT PRODUCTION
- CURRENT DATABASE
- CURRENT DEPLOYMENT EVIDENCE

ولم تُعامل التقارير التاريخية كبديل عن هذه الطبقات.

### آخر Current Git الذي تمت مراجعته قبل هذه الجولة

System repository:
- HEAD عند بدء الجولة: `3838fd33e98f689ec6d8e778ee539e6c89774c13`
- Parent: `8cc3b7538619bdf04585dfb60f44781234c3642e`

Frontend repository:
- HEAD: `6715825ec05e62482a4e37335ab366f5512805cf`
- Parent: `745a615ccd0baff09ad2619b0316e46507a862e9`

Target source:
- `vouchers.html`: `b23a7a8f605ff6151fd87b021de1e1d593672a57`
- `van-sales.html`: `8d61382a8e0025a0d079e71dd94f33d106d9088e`
- `main.html`: `8c3d6b05fd6a94a6b488f12b29da85ae888f70bc`

---

# 2. نطاق المسؤولية المعماري

تم تثبيت الوظيفة الفعلية لتطبيق الأذونات:

### Transfer
`Branch → Branch`

### DirectSale
`Branch → Vehicle Mobile Stock`

وهذا **ليس Customer Sale**.

### DirectReturn
`Vehicle Mobile Stock → Branch`

### SupplierReturn
`Branch → Supplier`

النظام الأم:
- Control Plane
- Navigation Plane
- Monitoring / Reporting Plane

التطبيق المستقل:
- Operational Plane

Physical Stock:
`post_stock_movement`

لا يوجد إعادة بناء لدورة Order / Runsheet داخل الأذونات.

---

# 3. main.html

تم فتح ومراجعة علاقة:

Warehouse Management
→ Stock Vouchers
→ Transfer / DirectSale / DirectReturn / SupplierReturn / Voucher List

وتم التحقق من أن النظام الأم يحتوي أصلًا على واجهة التحكم والرقابة لهذه الوحدة.

### القرار

`main.html` **لم يتم تعديله**.

---

# 4. Van Sales

تم فتح:

`companies/company-1/sales/van-sales.html`

والتحقق من:

- `loadVanBranch()`
- `setup-van-branch`
- mobile branch identity
- vehicle / driver relationship
- operation identity
- `save-sales-invoice`

وتم التأكد أن:

`vehicle.driver_id`

هو هوية المندوب/الوصي على Mobile Stock.

### القرار

لا Defect جديد مثبت في Van Sales في هذه الجولة.

`van-sales.html` **لم يتم تعديله**.

---

# 5. Production — Current Evidence

### Company 1
`00000000-0000-0000-0000-000000000001`

### Branches
- `BR-01`
- `BR-2`
- `VAN-VEH-TEST-260921`

### Vehicle
`VEH-TEST-260921`

Status:
`Active`

Mobile Stock:
مفعّل.

### Direct Sales Representative
`vansales@rawaea.com`

### Voucher User
`vouchers@rawaea.com`

Role:
`مخزني`

Active Warehouse Role:
`أذونات`

### Supplier
`SUPP-1001`
`ابراهيم الأبيض`

### Item
`1001`

---

# 6. Persistent QA Data — لا تُحذف

تم إنشاء QA حقيقية في Production وتركها عمدًا.

## QA Purchase Order

`QA-PO-SUPPLIER-LINK-20260922`

- Status = Draft
- Supplier = SUPP-1001
- Branch = BR-01
- Item = 1001
- Qty Ordered = 1
- Qty Received = 0

هذه البيانات تثبت علاقة Supplier↔Branch من خلال Business Document حقيقي موجود في Schema.

## QA Vouchers

| Voucher | Type | Status | Reference |
|---|---|---|---|
| IN-2 | DirectSale | Draft | QA-VEHICLE-PICKER-20260922 |
| IN-3 | DirectSale | Draft | QA-INVALID-JSON-DETAILS-20260922 |
| IN-4 | DirectReturn | Draft | QA-DIRECT-RETURN-DETAILS-20260922 |
| IN-5 | DirectSale | Draft | QA-VOUCHER-DS-KPI-20260922 |
| IN-6 | DirectReturn | Draft | QA-VOUCHER-DR-KPI-20260922 |
| IN-7 | SupplierReturn | Draft | QA-VOUCHER-SR-SUPPLIER-20260922 |

### QA Safety

جميع هذه الأذونات Draft.

لا توجد حركة Physical Stock ناتجة عنها.

---

# 7. Current Stock Baseline

Item `1001`:

### BR-01
- qty = 2
- allocated_qty = 0
- available = 2

### BR-2
- qty = 0
- allocated_qty = 0

### Vehicle Mobile Branch
- qty = 0
- allocated_qty = 0

لم يحدث تغيير Physical Stock نتيجة إنشاء QA.

---

# 8. ROOT CAUSE — طي القائمة العليا

### السبب المثبت

الإصلاح التاريخي لمشكلة clipping كان صحيحًا عندما نقل:

`routeHtml()`

خارج:

`wsTopPanel`

لأن `wsTopPanel` يستخدم:

`overflow:hidden`

لكن `toggleTopPanel()` بقي يتحكم فقط في:

`wsTopPanel`

وبالتالي:

- Branch picker يبقى ظاهرًا.
- Representative picker يبقى ظاهرًا.
- Vehicle/Supplier picker يبقى ظاهرًا.
- بينما Reference/Notes تختفي.

إذن زر:

`طي الخيارات`

لا يطوي كل Context block.

### سبب الوصول لهذا البناء

السبب ليس خطأ تصميم أصليًا في Smart Menu.

بل نتيجة صحيحة لإصلاح clipping سابق لم يُستكمل معه عقد Toggle الخاص بالرأس.

---

# 9. OWNER SURGICAL PATCH

## الملف الوحيد

`companies/company-1/warehouse/vouchers.html`

### V-302-01
CSS route panel.

### V-302-02
`toggleTopPanel:function()`

### V-302-03
`renderWorkspace:function()`

### V-302-04
`pickSearch:function(key,q)`

### V-302-05
`renderList:function(scope)`

### V-302-06
`cards:function(rows,scope)`

التعديلات الكاملة الجاهزة للاستبدال محفوظة حرفيًا في:

`Report302_WAREHOUSE_VOUCHERS_FORENSIC_KPI_UI_SUPPLIER_RELATION_CLOSURE_20260922.md`

### OWNER RULE

لا تعاد أي Patch سابق خاص بـ:

- vehicle picker
- clipping
- newWorkspace
- main.html
- DirectSale backend
- DirectReturn backend

لأنها مغلقة ومثبتة.

---

# 10. ROOT CAUSE — Supplier Smart Search

### Current Production قبل QA

مورد موجود.

لكن:

Supplier↔Branch relation = 0

لأن جدول `suppliers` لا يملك branch assignment مباشرًا.

العقد الحالي الصحيح يعتمد على:

`purchase_orders.company_id + supplier_id + branch_id`

### Current Source

`pickArr('wsTo')` في SupplierReturn:

- إذا ثبتت العلاقة → المورد يظهر.
- إذا لم تثبت → `[]`.

هذا Fail-Closed behavior صحيح.

### defect الحقيقي

المستخدم يرى dropdown فارغًا، لكن الرسالة الحالية عامة:

`لا توجد نتائج مرتبطة بالسياق المحدد`

ولا توضح:

**لماذا**.

### المعالجة

V-302-04 لا يفتح كل الموردين.

بل يشرح للمستخدم أن:
- لا علاقة Supplier↔Branch موثقة.
- الموردين غير المرتبطين محجوبون عمدًا.
- عند وجود Purchase Order حقيقي للفرع والمورد سيظهر المورد تلقائيًا.

---

# 11. SupplierReturn QA proof

بعد إنشاء:

`QA-PO-SUPPLIER-LINK-20260922`

أصبح:

`SUPP-1001 ↔ BR-01 = 1`

تم بعدها إنشاء:

`IN-7`

بنظام:

`SupplierReturn`

بنجاح عبر Production RPC الحالي.

إذن:

- Database relation = صحيح.
- RPC validation = صحيح.
- Voucher creation = صحيح.
- UI candidate source = يمكنه الآن رؤية العلاقة الحالية.

---

# 12. KPI GAP

Production كانت تحتوي بالفعل على:

- `created_at`
- `sent_date`
- `received_date`
- `completed_at`

لكن `VOUCHER_AUDIT` لم يكن يعيدها كـKPI lifecycle contract موحد.

لم ننشئ جدولًا جديدًا.

لم ننشئ Edge Function.

تم تعديل RPC الحالي:

`inventory_control(text,jsonb)`

وتحديدًا:

`VOUCHER_AUDIT`

ليعيد:

### KPI

- `start_at`
- `sent_at`
- `received_at`
- `completed_at`
- `end_at`
- `created_to_sent_seconds`
- `sent_to_received_seconds`
- `received_to_completed_seconds`
- `created_to_completed_seconds`
- `current_age_seconds`

### semantics

بداية الإذن:
`created_at`

بداية التنفيذ:
`sent_date`

النهاية المثبتة:
`completed_at` ثم `received_date`

العمر الحالي:
`now - created_at`

ولا يُنشأ أي timestamp وهمي.

---

# 13. Production migration

تم تطبيق Production migration:

`voucher_audit_kpi_contract_20260922`

Production version:
`20260922102930`

تم توحيد الاسم في Git ليطابق Production:

`supabase/migrations/20260922102930_voucher_audit_kpi_contract_20260922.sql`

والملف القديم ذي الاسم المضلل:

`20260922104000_voucher_audit_kpi_contract_20260922.sql`

أزيل من Git فقط، ولم تُحذف أي بيانات أو تقارير.

---

# 14. VOUCHER_AUDIT Runtime Proof

تم استدعاء:

`inventory_control('VOUCHER_AUDIT',...)`

على:

`IN-7`

تحت سياق مستخدم الأذونات.

النتيجة:

- success = true
- voucher = present
- details = present
- audit = present
- operations = present
- movements = []
- kpi = present
- current_age_seconds = calculated

وبذلك أصبح KPI جزءًا من العقد الفعلي في Production.

---

# 15. Edge / Gateway

تم التحقق من Edge الحالية:

`create-stock-voucher`

Current Production version:

`10`

وتعمل:

- verify_jwt = true
- company context من authenticated user
- existing `create_manual_stock_voucher_atomic`
- 12-argument signature عند وجود operation/rep
- operation_id محفوظ.

كما تم التحقق من أن Current `vouchers.html` يرسل:

`operation_id`

إلى:

`create-stock-voucher`

إذن:

**لا توجد حاجة لإنشاء Edge Function جديدة.**

وقد تم تجاوز gateway limit بأمان عبر الـRPC الحالي.

---

# 16. Physical Stock Core

تمت إعادة التحقق من العقد:

`Physical Stock Movement`

→ `post_stock_movement`

→ `stock_branches`

+

`inventory_log`

ولا يوجد Writer جديد تم إدخاله في هذه الجولة.

---

# 17. DirectSale / DirectReturn

هذه المسارات سبق إثباتها في Production:

### DirectSale
Branch → Vehicle

### DirectReturn
Vehicle → Branch

DirectReturn الحالي two-stage:

SEND:
إخراج من Mobile Stock.

RECEIVE:
إضافة إلى Branch.

تم عدم إعادة إصلاح هذه النقطة لأنها مثبتة بالفعل.

---

# 18. Competitive Review — capability level

تمت مراجعة الأنماط الرسمية الحالية في:

- Odoo
- Microsoft Dynamics 365
- SAP
- Daftra
- Manager.io

وتم تثبيت أن RAWAEA يحتوي بالفعل على الأساسيات المنافسة في هذه الوحدة:

- source / destination context
- mobile stock
- operational voucher lifecycle
- item selection/search
- quantity controls
- stock availability
- barcode/search
- audit path
- centralized movement engine
- independent operational apps

أما المزايا التي تحتاج Business Contracts مستقلة فلم تُخترع هنا، ومنها:

- Lot/Serial
- Expiry management
- Attachments/evidence
- approvals
- stock-in-transit model
- supplier branch master
- historical valuation layer

لا تُضاف هذه العناصر من خلال UI patch قبل فتح عقد مستقل لها.

---

# 19. Current Source status

`vouchers.html` الحالي:

`b23a7a8f605ff6151fd87b021de1e1d593672a57`

### لم يتغير

لأن الملف Owner-managed.

### جاهز فقط

Owner patches V-302-01 … V-302-06.

---

# 20. Browser E2E

Workflow الموجود في Frontend هو:

`.github/workflows/warehouse_vouchers_browser_e2e_20260920.yml`

وقد تمت مراجعته.

يحتوي على:

- source syntax gate
- canonical asset path validation
- Chromium boot smoke
- console errors
- page errors
- login controls presence

لكن هذا workflow لا ينفذ authenticated business E2E لدورة:

New Voucher → DirectSale → SupplierReturn → Save/Send

ومن ثم:

### Browser Business E2E

**OPEN / NOT VERIFIED**

ولا يجوز تحويل:

DB/RPC PASS

إلى:

Browser PASS.

---

# 21. سبب الخطأ النهائي — الصورة الجنائية

الأزمة الحالية ليست Defect واحدًا:

## A — Top Panel
نقل `routeHtml()` خارج `wsTopPanel` كان علاج clipping صحيحًا، لكن Toggle لم يُعاد ربطه بالمنطقة الجديدة.

## B — Supplier Dropdown
SupplierReturn يعتمد على verified Supplier↔Branch relation.
عند عدم وجود العلاقة، Fail-Closed هو السلوك الصحيح.
الخلل كان في مستوى UX/Explanation وليس في فتح البيانات.

## C — KPI
Lifecycle timestamps موجودة في Production، لكن لم يكن لها Response Contract موحد داخل `VOUCHER_AUDIT`.

## D — Gateway
لا توجد ضرورة Edge Function جديدة.
الموجود حاليًا يستخدم RPC canonical.

---

# 22. ما تم تنفيذه فعليًا

### Production
- KPI contract live.
- canonical migration saved.
- persistent QA data created.
- Supplier↔Branch relation proven.
- VOUCHER_AUDIT runtime verified.
- no new Edge Function.

### Git system
- Report302 created.
- Report303 created.
- migration filename reconciled.
- CURRENT_STATE updated.

### Frontend
- no direct source mutation.
- exact surgical replacements prepared.

### main.html
- untouched.

### van-sales.html
- untouched.

---

# 23. FINAL CLOSURE MATRIX

| النقطة | الحالة |
|---|---|
| Physical Stock centralization | CLOSED |
| DirectSale contract | CLOSED |
| DirectReturn contract | CLOSED |
| Vehicle ↔ Rep | CLOSED |
| Van Sales integration | CLOSED |
| SupplierReturn server guard | CLOSED |
| Supplier↔Branch contract | PROVEN |
| Supplier smart-search root cause | PROVEN |
| KPI Production contract | CLOSED |
| KPI UI | OWNER PATCH READY |
| Top collapse root cause | PROVEN |
| Top collapse UI | OWNER PATCH READY |
| main.html | UNTOUCHED |
| van-sales.html | UNTOUCHED |
| New Edge Function | NONE |
| Browser authenticated business E2E | OPEN |

---

# 24. SELF-AUDIT

## What I Proved
- Current System Git and Parent.
- Current Frontend Git and Parent.
- Current target blobs.
- Current Production supplier/branch/vehicle/rep.
- Current Production voucher state.
- Current Production stock baseline.
- Current SupplierReturn guard.
- Supplier↔Branch relationship behavior.
- Current create-stock-voucher Edge v10.
- Current operation_id flow.
- KPI Production response.
- Persistent QA records.
- No Physical Stock side effect from QA drafts.

## What I Did Not Prove
- Browser business E2E against published Cloudflare artifact.
- Published artifact equality to the current frontend HEAD after owner applies V-302.

## What I Fixed
Production:
- `inventory_control VOUCHER_AUDIT` KPI contract.

Data:
- persistent QA PO and vouchers.

Governance:
- canonical migration filename aligned to actual Production version.
- CURRENT_STATE updated.

## What I Did Not Touch
- main.html
- vouchers.html
- van-sales.html
- closed Vehicle Picker patch
- closed clipping repair
- closed DirectSale/DirectReturn backend.

---

# 25. تعليمات دقيقة للمساعد التالي

1. اقرأ CURRENT_STATE أولًا.
2. Verify System HEAD/Parent.
3. Verify Frontend HEAD/Parent.
4. Verify target `vouchers.html` blob.
5. Do not reopen Reports 296–301.
6. Apply only V-302-01 through V-302-06.
7. Parse the full file.
8. Deploy frontend.
9. Run authenticated business browser E2E.
10. Verify:
   - DirectSale
   - DirectReturn
   - SupplierReturn
   - top collapse/expand
   - supplier smart search
   - KPI display
11. Snapshot Production again at the same report moment.
12. Do not create another Edge Function.
13. Do not add a Supplier Branch master without a new Business Contract Closure Unit.

---

# 26. المخرج الحالي

### Final Report
`Report303_WAREHOUSE_VOUCHERS_EXECUTION_FINAL_20260922.md`

### Surgical Patch Source
`Report302_WAREHOUSE_VOUCHERS_FORENSIC_KPI_UI_SUPPLIER_RELATION_CLOSURE_20260922.md`

### State
`CURRENT_STATE.md`

---

# END OF REPORT 303
