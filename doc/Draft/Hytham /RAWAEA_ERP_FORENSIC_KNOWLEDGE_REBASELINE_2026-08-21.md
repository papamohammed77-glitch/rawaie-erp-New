# RAWAEA ERP — FORENSIC KNOWLEDGE RE-BASELINE

**Date:** 2026-08-21  
**Role / Stage:** Production Forensic CTO / Autonomous CTO Readiness Acquisition  
**Authority:** Live Production evidence first; Current Git second; historical/original sources for contract reconstruction; reports only as chronological evidence.  
**Production changes performed in this re-baseline:** None.  
**Purpose:** Build and preserve the current ERP-wide knowledge model before the next critical execution task.

---

## 1. EXECUTIVE DETERMINATION

التحقيق الحالي غيّر نقطة الارتكاز من **"Inventory rescue report"** إلى **"ERP-wide production reality"**.

RAWAEA ERP لم يعد في حالة الـ15–20 أغسطس القديمة. Production تقدمت بالفعل إلى طبقات:

```text
Inventory Core
→ Voucher Contract
→ Idempotency
→ Tenant-safe Main CRUD
→ Warehouse Supervisor Scope
→ Sales/Purchase Operation Identity
→ Return/Delivery Core
→ Legacy Surface Retirement
→ Production Data Cleanup
→ Zero-debt evidence cleanup
```

الحقيقة الحالية ليست أن كل ERP مغلق، وليست أن المشروع ما زال عند Voucher UI.

الحقيقة الحالية هي:

> **Production Core أصبح متقدمًا ومركزيًا في Inventory/Fulfillment/Voucher/Purchase/Sales slices، بينما اكتمال المعرفة والتنفيذ على Accounting/Ledger/Global Consumers/Deployment Lineage/Concurrency/ERP-wide regression لم يُثبت بعد.**

ولا يجوز إعلان `AUTONOMOUS CTO READY` في هذه اللقطة.

---

# 2. SOURCES RECONSTRUCTED

تم فتح السلسلة المطلوبة كاملة كمسار تاريخي متسلسل:

`Hussin Prompt 11 → 45`  
مع `Appendix Prompt 29`  
وملف:

`الخطة العامة الكبرى لـ RAWAEA ERP`

كما تمت مواجهة هذا التاريخ مع:

- Production PostgreSQL.
- Production migrations.
- Current Git source.
- Current CTO / governance artifacts.
- Edge/Core definitions التي تم التقاطها من Production.
- Schema / constraints / indexes / RLS / triggers.

القاعدة التي حكمت القراءة:

```text
Production Runtime
> Deployed Definitions
> Current Git
> Architecture / ADR
> Historical / Original
> Previous Reports
```

والتقرير السابق أو Prompt تاريخي لا يُرفع إلى `FACT` إلا إذا بقي صحيحًا بعد إعادة التحقق.

---

# 3. HOW THE HUSSIN CHAIN ACTUALLY EVOLVED

## P11–P15 — Manual Voucher Discovery

السلسلة بدأت من اكتشاف أن Manual Vouchers ليست مجرد UI، بل Business Capability مستقلة لها lifecycle وعلاقات مخزنية مختلفة.

العقد التاريخي كان يميز ستة أنواع:

- Transfer
- DirectSale
- DirectReturn
- SupplierReturn
- Scrap
- Adjustment

لكن Production لم تكن تدعم الستة بنفس الـlifecycle. هذا التمييز أصبح أساسًا مهمًا لمنع اختراع Contracts.

## P16 — First Critical False-Closure Detection

أثبتت السلسلة أن نسخة `vouchers.html` التي بدت مكتملة كانت تحتوي handlers مفقودة. وجود زر في HTML لم يكن دليلًا على وجود capability.

هذه اللحظة أصبحت قاعدة تشغيلية:

> **UI presence is not functional closure.**

## P18 — Authentication / NO_SESSION

تم التمييز بين:

`NO_SESSION`

كحالة طبيعية للزائر، وبين:

`SESSION RESTORE ERROR`

كخطأ حقيقي.

وبذلك لم يعد فتح الصفحة يحول غياب الجلسة إلى `انتهت الجلسة`.

## P19–P25 — Warehouse Supervisor / Roles

ظهر النموذج:

```text
role = مخزني
active_warehouse_role = المهمة الحالية
```

والمهام الحالية تشمل:

- استلام
- تحضير
- تحميل
- مرتجعات
- تفريغ
- أذونات
- جرد
- احتياطي

ثم أُغلقت مشاكل:

- company scope
- branch scope
- supervisor authorization
- public.users.id vs auth.users.id
- direct users update bypass
- team read scope

## P26 — Credential Diagnosis

ثبت أن مشاكل `vouchers@rawaea.com` يجب ألا تعالج بالتخمين أو بتغيير كلمة المرور يدويًا. الـRecovery flow أصبح هو المسار الصحيح عند الحاجة.

## P27 — Main CRUD Tenant Safety

هذه كانت نقطة انتقال كبيرة من Voucher repair إلى ERP architecture:

تم كشف hard-coded tenant context وunscoped writes/reads في main CRUD paths مثل:

- save-employee
- save-item
- save-branch
- save-customer
- save-supplier
- save-role
- save-settings
- save-journal-entry

ثم اتجه الإصلاح إلى:

```text
Authenticated User
→ public.users
→ company_id
→ tenant-safe operation
```

كما أُدخلت حدود Company حقيقية في البيانات والحسابات المالية.

## P28 — Central Engine Reconciliation

تم تثبيت الفرق بين:

```text
Production Core = centralized
```

و:

```text
Current Git artifact = قد يكون stale
```

وأصبح إصلاح Git drift نفسه جزءًا من الـClosure Unit.

## P29–P45 — Gold Master / Runtime / Core / Deployment Discipline

السلسلة انتقلت من مجرد بناء Voucher UI إلى:

- POS-style voucher workspace.
- Recovery continuity.
- Dexie compatibility.
- No direct stock writers in UI.
- Smart selectors.
- Product search.
- Warehouse-safe item display.
- Target stock row auto-init.
- DirectSale target-stock contract.
- Retry idempotency.
- Tenant-safe main CRUD.
- Legacy surface retirement.
- Data cleanup.
- One-file deployment discipline.

وأصبحت القاعدة التشغيلية:

> **Production direction + deployable application artifact direction.**

---

# 4. CURRENT PRODUCTION SNAPSHOT — 2026-08-21

لقطة Production الحالية من PostgreSQL:

| Metric | Current |
|---|---:|
| Public tables | 62 |
| Public functions | 42 |
| Public RLS policies | 102 |
| Public triggers | 13 |
| Companies | 3 |
| Users | 26 |
| Branches | 5 |
| Items | 50 |
| Stock rows | 26 |
| Inventory logs | 3 |
| Stock vouchers | 0 |
| Orders | 0 |
| Runsheets | 0 |
| Purchase Orders | 0 |

**ملاحظة حاسمة:** التقارير السابقة كانت تسجل 62 inventory logs وvoucher موجود. هذه لم تعد حقيقة حالية. Production نفذت تنظيفًا فعليًا لاحقًا.

---

# 5. CURRENT PRODUCTION MIGRATION STATE

أحدث التغييرات المطبقة فعليًا في Production تشمل:

```text
20260821023458  remove_orphan_e2e_inventory_logs_20260821
20260821023348  remove_confirmed_duplicate_indexes_20260821_v2
20260821023255  production_data_cleanup_test_voucher_and_orphan_company_20260821_v3
20260821023150  company_license_settings_integrity_20260821
20260820183912  20260820_fix_direct_sale_voucher_target_stock
20260820180154  voucher_vehicle_lifecycle_contract_fix_20260820
20260820155958  20260820_send_voucher_retry_idempotency
20260820154957  20260820_inventory_target_stock_row_autoinit
20260820035950  20260820_tenant_safe_main_crud
20260820030942  20260820_warehouse_supervisor_team_read_scope
20260819235822  20260820_disable_legacy_manual_stock_voucher_v2
20260819224407  warehouse_supervisor_branch_scoped_team_roles
20260819204036  20260819_set_active_warehouse_role
20260819162911  20260819_manual_voucher_reference_required
20260819162607  20260819_manual_voucher_lifecycle_company_scope
20260819162537  20260819_manual_voucher_vehicle_stock_contract
20260819062328  revoke_legacy_complete_runsheet_picking_overload
20260819055112  add_complete_picking_request_idempotency
20260819052701  unique_sales_operation_identity_20260819
20260819052558  purchase_order_tenant_read_write_boundary_20260819
20260819052458  enforce_van_branch_company_context_20260819
20260819052241  inventory_tenant_read_and_voucher_write_boundary_20260819
20260819050353  20260819_inventory_write_boundary_zero_debt
20260819040729  retire_post_stock_movement_legacy_overload
```

هذه migration history هي الآن أقوى شاهد على أن الخطة التنفيذية تحركت بعد تقارير 19 أغسطس.

---

# 6. PHYSICAL INVENTORY CORE — CURRENT TRUTH

## Canonical Physical Engine

```text
Business Operation
      ↓
Domain RPC
      ↓
post_stock_movement (10 args)
      ↓
stock_branches
+
inventory_log
```

`post_stock_movement(10)` هو الـcanonical Physical Movement Engine.

يدعم حاليًا movement vocabulary تشمل:

- PurchaseIn
- TransferOut
- TransferIn
- DirectSale
- DirectReturn
- SupplierReturn
- POSSale
- VanSale
- SalesReturn
- PurchaseReturn
- InventoryIncrease
- InventoryDecrease
- Loading
- Unloading

ويفرض idempotency key في Loading/Unloading، ويقفل stock rows ويقوم بالـstate/history mutation داخل المعاملة.

## Reservation

```text
reserve_stock
release_stock_reservation
```

هما Reservation engines، ويتعاملان مع `allocated_qty` فقط.

## Initialization

`setup_van_stock` هو Initialization writer وليس Business Movement writer.

## Writer conclusion

في Production الحالية:

> **لم يثبت وجود Physical Stock Engine منافس لـ`post_stock_movement`.**

والـ9-argument overload الموجود في catalog ليس parallel engine؛ هو compatibility wrapper، كما أن صلاحية تنفيذه غير متاحة للـanon/authenticated/service_role في اللقطة الحالية، بينما الـ10-arg canonical هو واجهة التنفيذ الفعلية.

---

# 7. CURRENT DOMAIN CORE MAP

## Picking

```text
runsheet
→ Picking
→ reserve_stock
→ allocated_qty
```

Picking ليس Physical Stock Movement.

الـ5-argument `complete_runsheet_picking(...operation_id)` هو المسار المهم حاليًا، بينما الـlegacy overload بقي كـcatalog residue بعد migration تقاعده.

## Loading

```text
MAIN
→ VAN
→ Loading
→ post_stock_movement
```

مع loading_cycle_id/idempotency.

## Unloading

```text
VAN
→ MAIN
→ Unloading
→ post_stock_movement
```

## Reopen Loading

يعكس الحركة السابقة ثم يبدأ loading cycle جديد.

## Sales

```text
MAIN branch → POSSale
VAN branch  → VanSale
```

والحركة تمر عبر `post_stock_movement`، ثم توجد آثار Accounting/Ledger داخل Sales Core.

## Purchase Receiving

```text
PO
→ receiving.operation_id
→ PurchaseIn
→ post_stock_movement
→ PO state
→ Journal
→ Supplier Ledger
```

## Return

`complete_return_atomic` هو Business Core مركب يتعامل مع:

- returned quantities
- return conditions
- shortage
- driver liability
- SalesReturn movement
- accounting
- customer ledger
- derived runsheet details
- operation registry

## Delivery

`complete_order_delivery_atomic` هو Fulfillment state transition وليس Physical Stock Movement.

يغير:

- order_details.qty_delivered
- order_status
- run_sheet_details
- operation registry
- audit

---

# 8. MANUAL VOUCHER — CURRENT CONTRACT

Production الحالية تثبت أن CREATE lifecycle يدعم أربعة أنواع:

```text
Transfer
DirectSale
DirectReturn
SupplierReturn
```

مع العقود:

```text
Transfer       = Branch → Branch
DirectSale     = Branch → Vehicle/VAN
DirectReturn   = Vehicle/VAN → Branch
SupplierReturn = Branch → Supplier
```

أما:

```text
Scrap
Adjustment
```

فهما **Engine Operations** وليسَا حاليًا Manual Voucher lifecycle مطابقًا للأنواع الأربعة.

يوجد `post_inventory_adjustment_atomic`، لكنه Adjustment Engine وليس CREATE/SEND/RECEIVE/COMPLETE Voucher lifecycle.

لذلك لم يتم تحويل الفرق الشكلي إلى Contract وهمي.

---

# 9. RECEIVE / IDEMPOTENCY CURRENT TRUTH

هناك الآن عدة طبقات حقيقية للـoperation identity:

### Manual Voucher RECEIVE
`operation_id` + inventory idempotency key.

### Purchase Receive
`receiving.operation_id` وunique constraint.

### Sales
`orders.operation_id` وunique constraint.

### Picking
`erp_operation_registry` + operation_id في canonical overload.

### Delivery
`erp_operation_registry` مع operation key.

### Return
`erp_operation_registry` مع operation key.

ويوجد unique:

```text
(company_id, idempotency_key)
```

في `inventory_log`.

إذن الـidempotency لم تعد مجرد UI local variable.

لكن ما زال مطلوبًا إثبات concurrency runtime بشكل مستقل عن مجرد وجود database uniqueness/locks.

---

# 10. LEGACY SURFACES — CURRENT STATUS

المعرفة القديمة كانت تقول إن:

`receive_manual_stock_voucher_v2`

ما زالت consumer فعالة.

Production الحالية تنسف هذا كحقيقة حالية:

- migration `20260820_disable_legacy_manual_stock_voucher_v2` موجودة.
- function موجودة كـcatalog residue.
- لا يوجد `EXECUTE` للـanon/authenticated/service_role في اللقطة الحالية.

إذًا التصنيف الصحيح الآن:

> **DISABLED / LEGACY CATALOG RESIDUE — not proven active consumer.**

ونفس المبدأ ينطبق على legacy `post_stock_movement(9)` وlegacy picking overload.

هذا تصحيح مهم للتاريخ السابق.

---

# 11. TENANT / COMPANY MODEL — CURRENT TRUTH

Production الحالية تحتوي 3 شركات، وكلها لديها الآن `app_settings`:

| Company | Users | Branches | Items | Settings |
|---|---:|---:|---:|---:|
| MAIN / الروائع | 24 | 2 | 17 | 1 |
| COMP-01 / الروائع للتجارة | 1 | 0 | 31 | 1 |
| ALRAWAE / الروائع للتوزيع | 1 | 3 | 2 | 1 |

إذن claim التاريخ السابق:

> “company has no app_settings”

أصبح **STALE**.

لكن `COMP-01` لديها 0 branches؛ وهذا يبقى Configuration/Operational Context question وليس Missing Settings.

---

# 12. IDENTITY MODEL

Production تثبت:

```text
auth.users.id
      ↓
public.users.auth_id
      ↓
public.users.id
      ↓
public.users.company_id
```

وهي هويات مختلفة يجب عدم خلطها.

كما أن:

`items.item_code`

Global Unique بالفعل بسبب unique index:

`items_item_code_key`.

لذلك لا يجوز اختراع `(company_id,item_code)` كهوية بديلة.

---

# 13. RLS / SECURITY

Production الحالية:

- 102 public RLS policies.
- RLS مفعّل على الجداول الحساسة.
- Core RPCs الحساسة تعمل غالبًا كـ`SECURITY DEFINER` و`search_path=public`.
- الوظائف الحساسة ليست مفتوحة للـanon/authenticated.
- الـcanonical physical writer 10-arg متاح لـservice_role فقط عبر grant، بينما واجهات القراءة/الـEdge تبقى capability boundaries.

هذه الصورة تدعم Security Model مركبًا:

```text
JWT
→ User Identity
→ Company Context
→ Edge Authorization
→ RPC Gate
→ SECURITY DEFINER
→ RLS / Target-row checks
```

ولكن لا تعتبر هذه بمفردها Authorization Matrix كاملة لكل Capability. ذلك ما يزال Closure Unit مستقلة.

---

# 14. ACCOUNTING / LEDGER — KNOWLEDGE STATUS

تقدم Inventory Architecture أثبت وجود روابط محاسبية فعلية:

### Purchase
Inventory Dr / Supplier Cr + Supplier Ledger.

### Sales
Cash/AR Dr / Sales Cr + COGS Dr / Inventory Cr عند Invoiced.

### Returns
Inventory return movement + COGS reversal logic + customer ledger effects في return core.

### Van Sales
يوجد driver ledger impact في حالات البيع الآجل.

لكن المخطط العام يطلب خطوة أعمق:

```text
post_journal_entry
→ Journal Core
→ Ledger Engines
→ Treasury
→ Daily Settlement
```

وهذه السلسلة **لم تُثبت كقلب مركزي موحد ERP-wide** بنفس قوة `post_stock_movement`.

التصنيف الحالي:

> **Accounting integration = proven in key domains.**  
> **Central Accounting Engine = not yet fully proven.**  
> **Unified Ledger Engine = not yet fully proven.**

---

# 15. FULFILLMENT — KNOWLEDGE STATUS

المعرفة الحالية أصبحت واضحة:

```text
orders
→ order_details
→ runsheets
→ run_sheet_details
```

والعقد التشغيلي الحالي يجعل `order_details` authoritative fulfillment data في الحركات الرئيسية، بينما `run_sheet_details` يُحدث كـderived aggregate.

تم إثبات وظائف:

- Picking
- Loading
- Delivery
- Return
- Unloading
- Reopen Loading
- Backorder updates

لكن الـFulfillment domain لم يُغلق ERP-wide كـclosure graph كامل يشمل:

Order creation
→ confirmation
→ assignment
→ run sheet generation
→ partial fulfillment
→ refusal
→ return
→ settlement
→ customer financial closure.

الحالة:

> **Strong / not globally closed.**

---

# 16. DATA REPAIR ENGINEERING

Production الحالية تثبت أن Data Repair أصبح جزءًا من الخطة نفسها، وليس نشاطًا ثانويًا.

أحدث migrations تشمل:

- `production_data_cleanup_test_voucher_and_orphan_company_20260821_v3`
- `remove_orphan_e2e_inventory_logs_20260821`
- `company_license_settings_integrity_20260821`
- `remove_confirmed_duplicate_indexes_20260821_v2`

وهذا يعني أن المشروع انتقل إلى:

```text
Detect
→ Classify
→ Trace
→ Repair
→ Verify
→ Prevent recurrence
```

واللقطة الحالية بالفعل تشهد على التنظيف:

`inventory_log = 3`  
`stock_vouchers = 0`

لكن لا يمكن اعتبار Data Integrity 100% مكتملة من count alone.

---

# 17. CONSUMER UNDERSTANDING

السلسلة التاريخية أثبتت أن:

```text
PWA
→ Edge
→ RPC
→ DB
```

يمكن أن تنحرف بسهولة.

أمثلة تاريخية موثقة:

- vouchers HTML handler drift.
- warehouse.supervisor JS parse error.
- warehouse supervisor company identity mismatch.
- RLS hiding team rows.
- `complete-loading` stale Current source while Production Core was already centralized.
- Gold Master helper-file drift.

الحالة الحالية:

> **Core understanding = strong.**  
> **Global Consumer closure = incomplete.**

خصوصًا:

- full browser E2E
- PWA parity
- single-file deployment verification
- current hosting runtime
- consumer-to-RPC matrix لكل العمليات الحساسة.

---

# 18. DEPLOYMENT / RUNTIME LINEAGE

التاريخ أثبت الفرق بين:

```text
Git Source Updated
```

و:

```text
Production Runtime Verified
```

وهذا ما يجب عدم كسره.

حتى عندما تكون Source file سليمة، لا يصبح الـartifact `PRODUCTION VERIFIED` إلا بعد:

```text
Git Commit
→ Deployment Artifact
→ Edge/PWA Runtime
→ Browser/Client
→ Production DB
→ Runtime Logs
```

هذه السلسلة ليست مغلقة ERP-wide حاليًا.

الحالة:

> **Deployment knowledge = strong conceptually, incomplete as complete lineage for every critical consumer.**

---

# 19. CONCURRENCY

البنية الحالية تحتوي عناصر قوية:

- `FOR UPDATE`
- unique idempotency keys
- operation registry locks
- state predicates
- atomic DB transactions
- CAS-style updates.

لكن هذا لا يساوي automatically runtime concurrency proof.

ما لم يتم إثباته ERP-wide:

- two independent authenticated sessions.
- same business operation concurrently.
- duplicate submissions.
- retry during timeout.
- conflict resolution.
- rollback after partial exception.

الحالة:

> **Concurrency engineering = structurally strong / live cross-session proof incomplete.**

---

# 20. CURRENT PLAN — WHERE THE PROJECT REALLY IS

الخطة الكبرى تقول:

```text
1. SSOT
2. Stop Distributed Logic
3. Inventory Rescue
4. Full Inventory Lifecycle
5. Central Accounting
6. Unified Ledgers
7. Fulfillment
8. Multi-Tenancy / Identity
9. Security
10. Surgical Edge Closure
11. Consumers
12. Migration/Deployment
13. Global Regression/Concurrency
14. Zero-Debt
15. Final ERP
```

الواقع الحالي:

| Phase | Current understanding |
|---|---|
| SSOT / Truth hierarchy | **VERIFIED as governance** |
| Distributed stock writer removal | **STRONG / Inventory slice nearly centralized** |
| Inventory Core | **VERIFIED** |
| Inventory Lifecycle | **STRONG / not global closure** |
| Accounting Core | **PARTIALLY PROVEN** |
| Ledger Engines | **PARTIALLY PROVEN** |
| Fulfillment | **STRONG / not global closure** |
| Tenant/Identity | **STRONG / active evolution** |
| Security | **STRONG infrastructure / matrix incomplete** |
| Edge closure | **PARTIALLY CLOSED by domain** |
| Consumers | **OPEN** |
| Deployment lineage | **OPEN** |
| Regression/Concurrency | **OPEN** |
| Zero-Debt | **IN PROGRESS / active cleanup** |
| Autonomous CTO Ready | **NO** |

---

# 21. KNOWLEDGE GRAPH — THE MODEL NOW BUILT

## Identity Graph

```text
auth.users
   ↓
public.users.auth_id
   ↓
public.users.id
   ↓
company_id
   ↓
role
   ↓
permissions
   ↓
active_warehouse_role
```

## Operational Graph

```text
Order
 ↓
Order Details
 ↓
Runsheet
 ↓
Picking
 ↓
Reservation
 ↓
Loading
 ↓
VAN Custody
 ↓
Sale / Delivery
 ↓
Return
 ↓
Unloading
```

## Inventory Graph

```text
Physical Event
 ↓
post_stock_movement
 ↓
stock_branches.qty
 ↓
inventory_log
```

```text
Reservation
 ↓
reserve_stock / release_stock_reservation
 ↓
allocated_qty
```

## Financial Graph

```text
Inventory / Business Event
 ↓
Journal
 ↓
Customer / Supplier / Driver Ledger
 ↓
Treasury / Settlement
```

الجزء الأخير ما زال يحتاج بناء knowledge graph كامل وليس مجرد معرفة الدوال الفردية.

---

# 22. GLOBAL REALITY MATRIX

| Layer | Historical | Original | Current Git | Production | Core | Consumers | Target | Runtime | Status |
|---|---|---|---|---|---|---|---|---|---|
| Inventory Physical | extensive | legacy writers | mostly aligned | centralized | `post_stock_movement` | many | one engine | structural proof | **STRONG / OPEN GLOBAL WRITER LINEAGE** |
| Reservation | established | direct alloc | aligned | `reserve_stock` | reservation core | picker | reservation-only | structural proof | **VERIFIED** |
| Manual Voucher | six historical types | older lifecycle | Gold/Diamond UI | four voucher types + adjustment engine | voucher cores | vouchers PWA | contract-preserving | partial runtime | **STRONG / FOUR-TYPE LIFECYCLE VERIFIED** |
| Sales | historical POS/Van | original paths | current adapters | Sales Core | `save_sales_invoice_atomic` | POS/Van | unified event flow | partial | **STRONG** |
| Purchase | historical | original receiving | current adapter | `receive_purchase_atomic` | purchase core | receiving/PWA | centralized receive | partial | **STRONG** |
| Picking | historical | original | current + legacy residue | canonical 5-arg | reservation core | picker | one path | partial | **STRONG** |
| Loading | historical direct writer | original | corrected | canonical core | `complete_runsheet_loading` | loader | central movement | structural | **VERIFIED CORE** |
| Unloading | historical | original | current | canonical core | `complete_runsheet_unloading` | unloader | central movement | structural | **STRONG** |
| Return | historical | original | current | core | `complete_return_atomic` | returns | central return | partial | **STRONG / NOT GLOBAL CLOSE** |
| Delivery | historical | original | current | core | `complete_order_delivery_atomic` | driver | fulfillment-only | partial | **STRONG / NOT GLOBAL CLOSE** |
| Tenant CRUD | legacy risk | original | repaired current | tenant-safe migrations | CRUD RPCs | main.html | company isolation | structural | **STRONG** |
| Warehouse Supervisor | historical | original | current | role/team RPCs | `set_active_warehouse_role`, team read | supervisor | branch-safe staffing | partial | **STRONG** |
| Accounting | historical | original | multiple | working in key domains | not unified proven | main/accounting | central journal engine | partial | **OPEN** |
| Ledgers | historical | original | multiple | working | not unified proven | finance/sales | central ledger engines | partial | **OPEN** |
| Consumer parity | historical | original | many revisions | actual runtime varies | domain cores | many PWAs | aligned consumers | not global | **OPEN** |
| Deployment lineage | historical | original | current branches | deployed versions | N/A | all | one clear lineage | partial | **OPEN** |
| Concurrency | historical | existing locks | current | DB primitives | locks/idempotency | consumers | true race proof | incomplete | **OPEN** |
| Data Repair | historical incidents | legacy residue | repair migrations | current cleaned state | cleanup migrations | all | invariant-preserving data | partial | **IN PROGRESS** |

---

# 23. STALE / CORRECTED HISTORICAL CLAIMS

## Claim: `stock_vouchers.completed_by` is absent
**Current:** FALSE / STALE.  
Production now contains `completed_by`.

## Claim: a Production company has no `app_settings`
**Current:** FALSE / STALE.  
All 3 companies currently have one `app_settings` row.

## Claim: `receive_manual_stock_voucher_v2` is still an active callable path
**Current:** NOT PROVEN and contradicted by current privileges + disable migration.  
Classification: disabled legacy catalog residue.

## Claim: 9-argument stock engine remains callable application surface
**Current:** catalog residue only in current privilege state.  
Canonical executable boundary is the 10-argument engine.

## Claim: old report counts describe current Production
**Current:** FALSE.  
2026-08-21 cleanup changed data counts materially.

These corrections are not criticism of the original reports; they are simply the consequence of time-aware forensic truth handling.

---

# 24. MATERIAL KNOWLEDGE GAPS REMAINING

## P0

### K-001 — ERP-wide Accounting Core Map
Need a complete graph:

```text
Business Event
→ Journal Entry
→ Journal Lines
→ Account Scope
→ Financial Posting
→ Ledger
```

### K-002 — ERP-wide Ledger Core
Need authoritative writers for:

- Customer Ledger
- Supplier Ledger
- Driver Ledger
- Treasury
- Daily Settlement

### K-003 — Consumer Closure Matrix
For every sensitive Edge/RPC:

```text
PWA / main.html
→ Edge
→ RPC
→ Core
→ tables
→ audit
```

### K-004 — Deployment Lineage
Need exact:

```text
Git SHA
→ artifact
→ deployed version
→ runtime endpoint
→ browser/runtime evidence
```

### K-005 — True Concurrency Proof
Need independent-session race tests for the operations where concurrency matters.

## P1

### K-006 — Full Fulfillment Knowledge Graph
Complete lifecycle from order creation to settlement.

### K-007 — Security Authorization Matrix
JWT → public.users → company → role → capability → Edge → RPC → RLS → target rows.

### K-008 — Data Integrity Graph
Cross-tenant references, orphan identities, impossible states, stale/fixture residues, ledger mismatch, inventory/accounting reconciliation.

### K-009 — Architecture Decision Registry
Need permanent registry of:

- accepted decisions
- owner decisions
- rejected alternatives
- reasons
- source evidence

### K-010 — Current / Original / Historical / Production Matrix
Per Closure Unit, not only per domain.

### K-011 — Runtime PWA Gold Master Verification
Especially actual hosted version and service-worker/deployment lineage.

### K-012 — Zero-Debt Global Sweep
Direct writers, duplicate engines, legacy catalog, hidden triggers, temporary harnesses, stale consumers.

---

# 25. WHAT IS NOT A GAP ANYMORE

The following are now established strongly enough not to be re-opened without new contradictory evidence:

1. `post_stock_movement` is the canonical Physical Stock Engine.
2. Reservation is distinct from Physical Stock.
3. `item_code` is globally unique.
4. DirectSale current Production contract is Branch → Vehicle/VAN.
5. DirectReturn current Production contract is Vehicle/VAN → Branch.
6. Loading is MAIN → VAN Physical Movement.
7. Unloading is VAN → MAIN Physical Movement.
8. Picking is reservation-oriented rather than physical movement.
9. `order_details` is authoritative fulfillment detail in the current model.
10. RLS is active on sensitive tables.
11. `public.users.id` and `auth.users.id` are distinct identities linked by `users.auth_id`.
12. Tenant-safe main CRUD is now a real production concern and has received dedicated migrations.
13. Data cleanup is now an actual Production activity, not merely an audit recommendation.

---

# 26. CURRENT CTO READINESS

| Capability | Current Level |
|---|---|
| Production Forensics | **Expert** |
| PostgreSQL / Inventory | **Expert** |
| Voucher / Warehouse Core | **Expert-level within verified slice** |
| Tenant / Identity | **Strong** |
| Edge Forensics | **Strong** |
| Historical Reconstruction | **Very Strong** |
| Consumer Understanding | **Intermediate / incomplete globally** |
| Runtime / Browser E2E | **Intermediate / incomplete** |
| Deployment Lineage | **Intermediate / incomplete** |
| Accounting Architecture | **Incomplete** |
| Ledger Architecture | **Incomplete** |
| Fulfillment Architecture | **Strong but incomplete ERP-wide** |
| Data Repair Engineering | **Strong in current rescue slice / needs ERP-wide generalization** |
| Concurrency Engineering | **Structurally strong / runtime proof incomplete** |
| Global Zero-Debt Governance | **In progress** |
| Autonomous RAWAEA ERP CTO | **NOT READY YET** |

---

# 27. NEXT KNOWLEDGE ACQUISITION ORDER

وفق الخطة الكبرى، المرحلة التالية يجب ألا تعيد فتح Inventory Core من الصفر.

التسلسل المنطقي الحالي:

```text
CURRENT PRODUCTION RE-BASELINE
          ↓
ACCOUNTING CORE FORENSICS
          ↓
LEDGER CORE FORENSICS
          ↓
FULFILLMENT GLOBAL GRAPH
          ↓
CONSUMER MATRIX
          ↓
SECURITY MATRIX
          ↓
DEPLOYMENT / RUNTIME LINEAGE
          ↓
CONCURRENCY PROOF
          ↓
GLOBAL DATA RECONCILIATION
          ↓
GLOBAL ZERO-DEBT SWEEP
          ↓
AUTONOMOUS CTO READINESS GATE
```

Inventory remains a prerequisite foundation, not the entire project.

---

# 28. PENDING FINDINGS — PROMOTED FROM INTERNAL STORAGE

هذه ليست “حلولًا”، بل عناصر يجب إبقاؤها في سجل المتابعة حتى تثبت نهايتها:

- Complete ERP-wide Journal Writer closure.
- Complete ERP-wide Ledger Writer closure.
- Full browser/runtime proof for critical PWAs.
- Exact current deployment lineage for every critical Edge/PWA artifact.
- Independent-session concurrency proofs.
- Full tenant authorization matrix.
- Full cross-domain Data Repair reconciliation.
- Architecture/Owner/Rejected decision registry.
- Consumer drift sweep after the latest Production migrations.

---

# 29. SELF-AUDIT

## What I Proved

- Current Production topology and counts.
- Current migration progression through 2026-08-21.
- Central Physical Stock boundary.
- Reservation boundary.
- Current voucher contract.
- Current Sales / Purchase / Return / Delivery / Loading / Unloading Core relationships.
- Current tenant configuration counts.
- Global item identity.
- Current RLS / sensitive RPC execution posture.
- Current disabled/legacy surfaces that are no longer callable.
- Current Production data cleanup outcome.

## What Historical Work Contributed

- Business contract history.
- Reasons for architectural decisions.
- Previously discovered failure modes.
- Consumer pitfalls.
- Identity pitfalls.
- Deployment and source-drift traps.
- Gold Master / single-file deployment discipline.

## What Previous Records Could No Longer Be Treated As Current

- Old stock/voucher counts.
- Missing `completed_by` claim.
- Missing `app_settings` claim.
- Active legacy Voucher V2 claim.
- Callable legacy stock overload claim.
- Old “Inventory only” perception of the rescue stage.

## What I Did Not Prove

- Global browser E2E for every critical PWA.
- Full concurrent runtime proofs.
- Full Accounting/Ledger centralization.
- Full deployment lineage for every Edge/PWA artifact.
- ERP-wide consumer closure.

## What Could Still Be Wrong

- A critical consumer may still be outside the current Core contract.
- A deployed browser artifact may differ from current Git.
- A financial writer may still duplicate another financial writer outside the currently reviewed paths.
- Some historical data may still require forensic classification even after cleanup.

---

# 30. FINAL CTO STATION

```text
CURRENT TRUTH
Production has moved beyond the historical Voucher-only rescue snapshot.

CORE:
Central Physical Stock Engine = VERIFIED
Reservation Separation = VERIFIED

CURRENT BUSINESS CORE:
Voucher / Sales / Purchase / Loading / Unloading / Return / Delivery = STRONG

DATA:
Recent E2E/orphan cleanup is now in Production.
Current inventory_log count = 3.
Current stock_vouchers count = 0.

TENANCY:
3 companies currently have app_settings.

LEGACY:
Legacy stock/voucher overloads exist in catalog history but the critical ones are disabled/not executable through current grants.

OPEN:
Accounting
Ledger
Consumers
Deployment Lineage
Concurrency
ERP-wide Data Reconciliation
Global Zero-Debt

READINESS:
Senior/Lead Forensic ERP Engineering level is strongly evidenced.
Fully Autonomous RAWAEA ERP CTO = NOT YET VERIFIED.

NEXT KNOWLEDGE STAGE:
Accounting → Ledger → Fulfillment Global Graph → Consumers → Security → Deployment → Concurrency → Zero-Debt.
```

---

# 31. GOVERNING PRINCIPLE

لا نعيد استكشاف المشروع من الصفر.
ولا نورث ذاكرة قديمة.
ولا نرفض التغيير الصحيح لأنه جاء بعد التقرير.
ولا نمرر التغيير الخطأ لأنه دخل Git.
ولا نعتبر نجاح Git نجاح Production.
ولا نعتبر نجاح Production نجاح Runtime.
ولا نعلن `100%` مع Unknown مؤثر.

المنهج المستمر هو:

```text
READ
→ UNDERSTAND
→ RELATE
→ RE-PROVE
→ CLASSIFY
→ RECONCILE
→ PATCH ONLY WHEN PROVEN
→ VERIFY
→ DOCUMENT
→ CLOSE
→ CONTINUE
```

وهذا هو نموذج المعرفة الحاكم للمرحلة التالية من RAWAEA ERP.
