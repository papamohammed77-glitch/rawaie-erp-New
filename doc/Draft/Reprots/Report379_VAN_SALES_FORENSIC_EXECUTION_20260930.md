# تقرير 379 — التحقيق التنفيذي الكامل لتطبيق VAN SALES
## 30 سبتمبر 2026

## 1. SELF-AUDIT — PRE-CHECK

- Business Understanding: 99/100
- Architecture Understanding: 99/100
- Database Understanding: 100/100
- Historical Understanding: 99/100
- Production Understanding: 100/100
- Current Source Understanding: 100/100
- Execution Confidence: 98/100

### حالة الدليل
- Confirmed Facts: 24
- Unknowns: 2
- Conflicts: 2
- Unverified Claims: 0

Historical Opened: YES
Original Opened: YES / baseline family
Production Opened: YES
Current Opened: YES
Schema Checked: YES
Triggers Checked: YES
Dependencies Checked: YES
Consumers Checked: YES

---

# 2. تصحيح الحالة السابقة

التقرير 378 كان قد وصف HEAD الأمامي بأنه:
c67de5a0b601e2cc0690bf40c32d46632140f95e
ووصف المصدر بأنه لا يُحلل بسبب Unexpected token ')'.

التحقق الحالي أثبت وجود commit أحدث في مستودع الواجهة:

- HEAD: 1b89202949575eaebed4c5bf5512322129a114fb
- Parent: c67de5a0b601e2cc0690bf40c32d46632140f95e
- Message: Fix indentation in promise chain in van-sales.html

وهذا الـcommit أصلح ذيل App.loadCustomerPatterns() الذي تسبب في خطأ الإغلاق الزائد.

إذن:
Report378 = HISTORICAL CLUE / STALE STATE
1b892... = CURRENT FRONTEND SOURCE HEAD

---

# 3. VAN SALES — CURRENT SOURCE

الملف:

companies/company-1/sales/van-sales.html

Current blob:
568db68e1465578cebf0231c9b1b653065608c52

الحجم الحالي حسب checkpoint:
3295 lines / 151087 chars

الواجهة ما زالت تحتوي على:
- الصفحة الرئيسية
- عملائي
- فواتيري
- رصيدي
- سيارتي
- الخريطة
- حسابي
- البيع السريع
- الجرد السريع
- التحصيل
- إعادة الطلب
- إقفال الوردية

Current source الحالي ليس نفس حالة Report378 القديمة؛ ذيل loadCustomerPatterns أصبح:
    })
        .catch(function() {});
وهذا هو التصحيح الموجود في commit 1b892...

---

# 4. HISTORICAL BASELINE

المصدر التاريخي:

rawaie-erp-review/PWA/sales/van-sales.html

SHA:
445dff4217fbf4a82f333fa716bba5d74def7680

الحالة التاريخية:
2124 lines / 120218 chars / 66 named App methods

Current:
65 App methods + global resolveCustomer

الفرق المثبت:
_createVanBranch لم يعد داخل Van Sales لأن مسؤوليته نُقلت إلى setup-van-branch.

هذا نقل مسؤولية، وليس فقدًا للمقدرة الوظيفية.

---

# 5. PRODUCTION BACKEND — CURRENT

Production Edge Functions المرتبطة مباشرة بـVan Sales:

- setup-van-branch = v5 ACTIVE
- save-sales-invoice = v15 ACTIVE
- save-receipt-voucher = v8 ACTIVE
- save-inventory-count = v5 ACTIVE
- save-daily-settlement = v4 ACTIVE
- start-picking = v14 ACTIVE
- complete-picking = v13 ACTIVE
- start-loading = v4 ACTIVE
- complete-loading = v10 ACTIVE
- reopen-loading = v2 ACTIVE
- unload-runsheet = v5 ACTIVE
- complete-return = v23 ACTIVE
- complete-order-delivery = v11 ACTIVE
- bulk-stock-adjustment = v5 ACTIVE

Core Production المرتبط:
- post_stock_movement
- reserve_stock
- release_stock_reservation
- save_sales_invoice_atomic
- post_van_sales_collection_atomic
- post_daily_settlement_atomic
- get_van_sales_customer_accounts
- get_van_sales_customer_account
- inventory_count_engine

---

# 6. INVENTORY RESCUE — CORE CONTRACT

التحقيق الحالي في PostgreSQL Production بحث مباشرة عن:
- UPDATE public.stock_branches
- INSERT INTO public.inventory_log

النتيجة:

Physical stock writer المباشر:
post_stock_movement فقط.

Reservation writers:
reserve_stock
release_stock_reservation

ولا يوجد Writer آخر ثبت أنه ينفذ Physical Stock Movement مباشرًا خارج هذا الحد.

هذا يؤكد حاليًا:
DB Physical Stock Boundary = VERIFIED

كما أن post_stock_movement المنشور يدعم:
PurchaseIn
TransferOut
TransferIn
POSSale
VanSale
DirectSale
SalesReturn
DirectReturn
SupplierReturn
InventoryIncrease
InventoryDecrease
Loading
Unloading

ويطبق:
- company-scoped item/branch validation
- row locking
- Loading reservation checks
- VAN authorization for VanSale
- idempotency key عند الحركات التي تحتاجها
- كتابة inventory_log المركزية

---

# 7. VAN SALES STOCK FLOW

العقد الحالي:

Van Sale
→ save-sales-invoice
→ save_sales_invoice_atomic
→ post_stock_movement
→ VAN mobile stock

Picking:
→ reserve_stock فقط عند مساره
→ لا Physical qty movement

Loading:
→ MAIN → VAN

Unloading:
→ VAN → MAIN

هذا متفق مع هدف القلب المركزي للمخزون.

---

# 8. DATABASE DATA — DIRECT SALE EXPERIMENTAL HISTORY

تم العثور فعليًا على سجلات تاريخية تجريبية:

- IN-1 = DirectSale / Completed / 5 details
- IN-8 = DirectSale / Sent / 2 details
- IN-9 = DirectReturn / Received / 1 detail

ووجدت لها inventory_log تاريخية.

هذه ليست سجلات Draft يمكن حذفها بأمان؛ Production integrity contract يحظر حذف إذن سبق أن أنشأ حركة مخزنية.

والأهم:
- التأثيرات الفيزيائية المرتبطة بها تم فحصها.
- رصيد VAN الحالي في الصفوف المفحوصة = 0/0.
- لا يوجد test order/customer/runsheet من أنماط canary المعروفة حاليًا.

### القرار

لا نحذف IN-1/IN-8/IN-9 كـhard delete لمجرد أنها تجريبية، لأن ذلك يعبث بتاريخ Stock/Audit.

هذه السجلات تبقى Historical Audit Evidence، مع عدم وجود أثر تشغيلي حالي مثبت منها.

---

# 9. FRONTEND — EXACT DEFECT DISCOVERED

## showRecentCustomers()

المشكلة في المصدر الحالي:

    supabase.from('users')
        .select('company_id')
        .eq('id', this.currentUser.id)
        .maybeSingle()

المشكلة مثبتة لأن Production يثبت أن:

public.users.id ≠ auth.users.id

للمستخدمين الفعليين:

vansales@rawaea.com
public.users.id = 111b0730-a977-4d11-bcd0-2427b178a9e5
auth_id = 92961150-c74f-4557-9eca-7521450bb7f4

vansales2@rawaea.com
public.users.id = cb086d71-ba61-4392-8d3d-c4bec02ec913
auth_id = 7ff66aad-e0fe-4d8c-99ac-e0ed745e2a6a

إذن lookup الحالي قد لا يعثر على مستخدمه.

### الجراحة الموصى بها

الملف:
companies/company-1/sales/van-sales.html

العنصر:
App.showRecentCustomers()

السطر الحالي المعيب:

    .eq('id', this.currentUser.id)

الاستبدال:

    .eq('auth_id', this.currentUser.id)

هذا تعديل Frontend محمي ولا يُنفذ آليًا وفق Owner Source Delivery Rule.

---

# 10. WHY THIS MATTERS

showRecentCustomers ليست مجرد UI decoration.

هي جزء من:
- customer selection
- repeat business workflow
- Van Sales customer continuity

لكنها لا تمثل مصدر الحقيقة للحساب أو المديونية؛ الحساب نفسه يعتمد على Production RPC:
get_van_sales_customer_accounts / get_van_sales_customer_account.

لذلك الإصلاح يجب أن يعالج الهوية فقط، دون إعادة تصميم النظام.

---

# 11. CURRENT VAN SALES DATA FLOW

### Synchronization

Authenticated user
→ public.users.auth_id
→ company_id
→ branches
→ customers
→ items
→ stock_branches
→ app_settings
→ Dexie cache

### Customer account

PWA
→ get_van_sales_customer_accounts
→ customer_assignments
→ customer_ledger / invoices / payments / installments

### Sale

PWA
→ save-sales-invoice
→ save_sales_invoice_atomic
→ post_stock_movement
→ inventory
→ accounting / customer / driver ledgers

### Collection

PWA
→ save-receipt-voucher
→ post_van_sales_collection_atomic
→ treasury + customer ledger + driver ledger

### EOD

PWA
→ save-daily-settlement
→ post_daily_settlement_atomic
→ daily_settlements
→ driver_liabilities
→ accounting when shortage exists
→ runsheet closure

---

# 12. CURRENT FUNCTIONS THAT SHOULD NOT BE REWORKED

Based on direct current-source + Production evidence:

- syncDown company context
- setup-van-branch integration
- loadMyCustomers authoritative RPC path
- loadCustomerPatterns source/company/order scoping
- loadKPIs source/company scoping
- loadHomeSalesSummary source/company scoping
- loadMyInvoices source/company scoping
- collectPayment pending operation cleanup
- _loadVehicleStock canonical VAN stock source
- submitQuickSale → save-sales-invoice v15
- submitQuickInventory → save-inventory-count v5
- repeatOrder company/source scoped lookup
- initiateEndOfDay → save-daily-settlement

Do not reopen these without new direct evidence.

---

# 13. COMPETITOR BENCHMARK

المبادئ المرجعية المفيدة لـVan Sales:

- SAP DSD يجمع في سياق واحد بيانات المندوب/السائق/السيارة/الرحلة/العميل والبيع والتحصيل والإقفال والمزامنة.
- Dynamics يدعم نمذجة السيارة/الشاحنة كموقع مخزني وحركة المخزون إليها.
- Daftra يربط المبيعات والمخزون والحسابات والعمل الميداني/الموبايل.
- Manager يوضح أن التحصيل يمكن توزيعه على فواتير متعددة ويُحفظ في كشف الحساب.

الاستنتاج لـRAWAEA:
لا نحتاج تقليد UI المنافسين؛ نحتاج الاحتفاظ بميزة التشغيل الميداني ثم ربطها بمصدر بيانات مركزي وAccounting/Audit موحد.

---

# 14. BROWSER / E2E POSITION

الـGit الحالي للواجهة هو:
1b89202949575eaebed4c5bf5512322129a114fb

وهو أحدث من حالة Report378.

لكن Browser deployment للـfrontend نفسه لا يمكن إثباته من backend فقط.

لذلك:
- Backend Production = current evidence
- Frontend Git = current source evidence
- Frontend published artifact = NOT PROVEN FROM THESE SOURCES

وبالتالي تجربة المتصفح الفعلية تحتاج:
Owner deployment/cache refresh
ثم Browser E2E.

---

# 15. SECURITY BACKLOG — SEPARATE

Security Advisor الحالي أظهر ديونًا عامة في المشروع:
- 3 Security Definer Views
- 3 mutable search_path functions
- 18 anon-callable Security Definer functions
- 103 authenticated-callable Security Definer functions
- leaked password protection disabled
- 20 RLS-enabled tables without policies في lint الحالي

هذه ليست سببًا مباشرًا لتعطيل إصلاح Van Sales الحالي، لكنها Global Security Backlog يجب أن تُعالج لاحقًا ضمن مسار مستقل.

---

# 16. DATA DELETION DECISION

البيانات التجريبية التنفيذية القديمة:
IN-1 / IN-8 / IN-9

لم تُحذف.

السبب:
لها inventory/audit history، والحذف المباشر يخالف Data Integrity Contract.

تم إثبات عدم وجود أثر تشغيلي حالي من هذه السجلات في الصفوف المخزنية المفحوصة.

لا يوجد حذف إضافي آمن يلزم في هذه الدورة.

---

# 17. CURRENT OPEN WORK

## Unit A — showRecentCustomers

Owner surgical patch:
.eq('id', this.currentUser.id)
→
.eq('auth_id', this.currentUser.id)

ثم:
- syntax
- browser E2E
- verify recent customer selection

## Unit B — Browser E2E

بعد نشر Owner للواجهة الحالية:
login
→ home
→ customers
→ account
→ quick sale
→ collection
→ vehicle
→ inventory
→ repeat order
→ EOD

## Unit C — Remaining contracts

أي نقص جديد يظهر من Browser E2E يُفتح كـClosure Unit مستقل ولا يُخلط مع وحدات مغلقة.

---

# 18. FINAL JUDGMENT

### ما هو منفذ فعليًا

- Central physical stock boundary = Production verified.
- Main Van Sales backend primitives = Production deployed.
- Sales/collection/inventory-count/settlement backend contracts = Production deployed.
- Current frontend latest syntax regression = repaired in latest frontend commit.
- Old executed experimental voucher history = preserved; physical residual checked as zero in inspected VAN rows.

### ما لم يُنفذ بعد

- Owner application of showRecentCustomers one-line surgical patch.
- Deployment/refresh of latest frontend artifact by Owner.
- Browser E2E from the latest frontend artifact.
- Final Van Sales closure after that evidence.

### الحالة

VAN SALES = INCOMPLETE

وليس بسبب backend architecture.

العنصر المفتوح المباشر الحالي:
showRecentCustomers identity lookup + frontend deployment/browser verification.

---

# 19. SELF-AUDIT — FINAL

## What I Proved
- Current frontend HEAD supersedes stale Report378.
- The syntax regression was fixed in Git by commit 1b892...
- Production DB central stock writer scan shows only post_stock_movement as direct physical stock writer.
- Van Sales core contracts are deployed in Production.
- Executed experimental voucher history exists and is preserved safely.
- showRecentCustomers has a concrete auth_id/id mismatch proven by Production user identities.

## What I Did Not Prove
- Current frontend main branch deployment is the artifact actually served to end users.
- Browser-rendered E2E after the latest commit.

## What I Fixed
- No protected frontend modification was made.
- No unsafe deletion of executed financial/stock history was made.
- Current-state evidence was reconciled against newer frontend Git evidence.

## What I Initially Missed
- Report378 was stale because a newer frontend commit already repaired the syntax defect.

## What Could Still Be Wrong
- Additional browser-only defects may surface after the one-line identity repair.

## Final Confidence
98/100 for the current forensic reality.

## Final Closure Status
INCOMPLETE — Owner frontend patch + deployment + browser E2E remain.
