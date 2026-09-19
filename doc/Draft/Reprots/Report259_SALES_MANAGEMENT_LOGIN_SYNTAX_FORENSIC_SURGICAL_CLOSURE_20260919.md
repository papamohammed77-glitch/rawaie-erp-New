# تقرير 259 — الاستكمال الجراحي لتبويب إدارة المبيعات بعد التحقيق الحي
**التاريخ:** 2026-09-19
**النطاق:** إدارة المبيعات وتبويباتها الفرعية فقط
**قاعدة الحقيقة:** CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT
**Mother main.html:** لم يعدل بواسطة CTO.

---

## 1. نقطة البداية المثبتة

### System Repository
- Repository: `papamohammed77-glitch/rawaie-erp-New`
- Current HEAD: `891f77fed9c57aa9af1b25d96fb67e37b211a166`
- Parent: `759ea2661727748bf808bb6d250694001ca36c2e`
- HEAD message: `Add files via upload`
- Parent message: `state: update current state after sales management forensic closure`
- HEAD adds only: `Current/main.md`
- Current snapshot blob: `638aa5745aa8f11cb20bf74102a1fd701073a348`

### Mother Repository
- Repository: `papamohammed77-glitch/erp-frontend`
- Current HEAD: `95c83863a4ccc2c3242250722101b0f3e2a75cb5`
- Parent: `2ff692e09f0cd83ea39c7b24040c6c62435349f1`
- `2ff692...` parent: `a96101d00c791fbeaae1708f0000893c46663ad5`
- Current `companies/company-1/main.html` blob: `f7857bed20bf46f520b4c21abefa5012a2a7c06a`
- Latest Mother HEAD modifies only the forensic extract file; the main.html content remains the result of the `2ff692...` commit.

### Historical reports
Report258 and the MASTER CTO GOVERNANCE document were used only as historical/architectural evidence. They were not treated as current Production truth.

---

# 2. MASTER GOVERNANCE RULES APPLIED

- Study before edit.
- Reconstruct historical contract.
- Trace current source and runtime.
- Verify current Production/database/deployment.
- Do not re-fix already-closed work.
- No new Edge Function for this scope.
- Production changes only when current evidence proves a backend need.
- Mother changes are Owner Changesets only.
- No browser PASS claim without a real browser.

---

# 3. FORENSIC ROOT CAUSE OF THE LOGIN FAILURE

## Exact current defect

**File**
`erp-frontend/companies/company-1/main.html`

**Object**
`RW_Navigation.menuTree`

**Current lines**
1485–1504

**Defective exact boundary**
```
        ] }
        { icon: 'fa-truck', label: 'إدارة المشتريات', submenu: [
```

The first line closes the Sales submenu object but is missing the comma required before the next object in `menuTree`.

## Historical proof

Commit:
`2ff692e09f0cd83ea39c7b24040c6c62435349f1`

This commit added Sales Management Center and changed the original:
```
        ] },
```
to:
```
        ] }
```

while immediately retaining the next object:
```
        { icon: 'fa-truck', label: 'إدارة المشتريات', submenu: [
```

## Static parser proof

Current main.html was parsed before the fix:
`SyntaxError: Unexpected token '{'`

An in-memory surgical correction of only the missing comma was then parsed again:
`PASS`

Therefore the Console error at line 1504 is caused by this missing comma.

## Tailwind warning

`cdn.tailwindcss.com should not be used in production` is a production-architecture warning only. It does **not** explain the login deadlock.

---

# 4. SECOND CURRENT DEFECT REVEALED AFTER FORENSIC RECONSTRUCTION

Fixing the comma alone exposes another real source defect in the new Sales Management route.

### Current code
```
if (view === 'sales-management-center') {
    var salesUser = (typeof RW_STATE !== 'undefined' && RW_STATE && RW_STATE.app) ? RW_STATE.app.currentUser : null;
    var salesPerms = (salesUser && Array.isArray(salesUser.permissions)) ? salesUser.permissions : [];
    var salesAllowed = !!(salesUser && (
        salesUser.isOwner === true ||
        salesPerms.indexOf('*') !== -1 ||
        salesPerms.indexOf('sales_manager') !== -1 ||
        salesPerms.indexOf('sales_supervisor') !== -1 ||
        salesPerms.indexOf('general_manager') !== -1 ||
        salesPerms.indexOf('reports') !== -1
    ));
    if (!salesAllowed) {
        safeHTML(c, '<div class="rw-card" style="text-align:center;padding:60px 20px"><div style="font-size:64px;margin-bottom:20px">🔒</div><h2>غير مصرح</h2><p>ليس لديك صلاحية الوصول إلى مركز إدارة المبيعات</p></div>');
        return;
    }
}
```

### Why it is wrong

The current authentication bootstrap writes permissions to:
```
RW_STATE.permissions
```

and the current canonical permission helper `RW_Permissions_check()` already reads:
```
RW_STATE.permissions
```

The `currentUser` object does not carry the permissions array.

Therefore a non-owner Sales Manager / Sales Supervisor / General Manager can be denied from the Sales Management Center even when the session legitimately contains the required permission.

This is current-source evidence, not an assumption.

---

# 5. OWNER SURGICAL PATCHES

## PATCH-259-01 — Fix the syntax blocker

**File:** `erp-frontend/companies/company-1/main.html`

**Find exactly:**
```
        ] }
        { icon: 'fa-truck', label: 'إدارة المشتريات', submenu: [
```

**Replace exactly with:**
```
        ] },
        { icon: 'fa-truck', label: 'إدارة المشتريات', submenu: [
```

Do not change any other line in `RW_Navigation.menuTree`.

---

## PATCH-259-02 — Fix Sales Management permission source

**File:** `erp-frontend/companies/company-1/main.html`

**Current location:** `RW_Views.render()`
**Current block begins:** line 27273

**Delete exactly the current block:**
```
if (view === 'sales-management-center') {
    var salesUser = (typeof RW_STATE !== 'undefined' && RW_STATE && RW_STATE.app) ? RW_STATE.app.currentUser : null;
    var salesPerms = (salesUser && Array.isArray(salesUser.permissions)) ? salesUser.permissions : [];
    var salesAllowed = !!(salesUser && (
        salesUser.isOwner === true ||
        salesPerms.indexOf('*') !== -1 ||
        salesPerms.indexOf('sales_manager') !== -1 ||
        salesPerms.indexOf('sales_supervisor') !== -1 ||
        salesPerms.indexOf('general_manager') !== -1 ||
        salesPerms.indexOf('reports') !== -1
    ));
    if (!salesAllowed) {
        safeHTML(c, '<div class="rw-card" style="text-align:center;padding:60px 20px"><div style="font-size:64px;margin-bottom:20px">🔒</div><h2>غير مصرح</h2><p>ليس لديك صلاحية الوصول إلى مركز إدارة المبيعات</p></div>');
        return;
    }
}
```

**Replace it completely with:**
```
if (view === 'sales-management-center') {
    var salesUser = (typeof RW_STATE !== 'undefined' && RW_STATE && RW_STATE.app) ? RW_STATE.app.currentUser : null;
    var salesPerms = (typeof RW_STATE !== 'undefined' && Array.isArray(RW_STATE.permissions)) ? RW_STATE.permissions : [];
    var salesAllowed = !!(salesUser && (
        salesUser.isOwner === true ||
        salesPerms.indexOf('*') !== -1 ||
        salesPerms.indexOf('sales_manager') !== -1 ||
        salesPerms.indexOf('sales_supervisor') !== -1 ||
        salesPerms.indexOf('general_manager') !== -1 ||
        salesPerms.indexOf('reports') !== -1
    ));
    if (!salesAllowed) {
        safeHTML(c, '<div class="rw-card" style="text-align:center;padding:60px 20px"><div style="font-size:64px;margin-bottom:20px">🔒</div><h2>غير مصرح</h2><p>ليس لديك صلاحية الوصول إلى مركز إدارة المبيعات</p></div>');
        return;
    }
}
```

Do not touch `RW_Permissions_check()`; it is already the canonical permission helper.

---

# 6. CURRENT SALES MANAGEMENT CENTER REALITY

The following are already present in current Mother and were NOT rebuilt:

- Sales Management Center navigation entry.
- Sales Management Center icon.
- Sales Management Center route.
- Sales Management Center page/module.
- Authenticated RPC read path.
- Sales KPIs.
- Order-status counters.
- Quotes summary.
- Returns summary.
- Payment summary.
- Runsheet summary.
- Decision Center summary.
- Commercial catalog / promotions summary.
- Targets summary.
- Channel sales.
- Top sales representatives.
- Top items.
- Top customers.
- Branch sales.
- Payment mix.
- Recent orders.
- Date filtering.
- Navigation back into existing sales surfaces.

No duplicate center was created.

---

# 7. CURRENT PRODUCTION VERIFICATION

## Sales Management Center RPC

`public.sales_management_center_read`

Security:
- SECURITY DEFINER
- authenticated execution: allowed
- anon execution: denied
- service_role execution: allowed
- authenticated company + actor validation exists
- Sales Decision actor authorization exists

## Direct Production read

Verified using:
- `sales.manager@rawaea.com`
- `general.manager@rawaea.com`

Both returned:
`success=true`

Current Production sales data at this checkpoint:
- orders = 0
- order_details = 0
- sales_quotes = 0
- commercial_catalogs = 0
- promotions = 0
- sales_payment_receipts = 0
- sales_payment_allocations = 0
- sales_return_reviews = 0
- sales_target_plans = 0
- loyalty_programs = 0
- loyalty_transactions = 0

These values are current Production values, not historical report values.

---

# 8. PRODUCTION E2E DATABASE TEST

Temporary transaction created:

`Delivered Order`
→ `order_details`
→ `sales_management_center_read`

Test payload:
- order total = 120
- item = 1001
- quantity = 3
- unit price = 40
- branch = الفرع الرئيسي
- channel = e2e-test
- payment = نقدي
- paid = 120

Observed Production result:
- total orders = 1
- delivered = 1
- sales value = 120
- top item 1001 = qty 3 / value 120
- top rep = sales.manager@rawaea.com / 120
- branch sales = الفرع الرئيسي / 120
- channel = e2e-test / 120
- payment mix = نقدي / 120 paid

The transaction was rolled back.

Post-test Production verification:
- e2e orders = 0
- e2e order_details = 0

No test data remains.

---

# 9. INVENTORY / FIELD OPERATIONS PRESERVATION

No change was made to:
- Picking
- Loading
- Delivery
- Returns
- Unloading
- Runsheet
- Reservation engine
- Physical Stock engine

The Sales Management Center remains a command/read surface over the existing operational architecture.

The field applications remain the execution owners.

---

# 10. COMPETITIVE CONTRACT REVIEW

## Odoo

Current official documentation shows a sales chain from quotation to sales order, followed by delivery and invoicing. Odoo also supports quotation deadlines, optional products, margins, signatures/payments, and different delivery/invoice addresses.

Relevant contract patterns for RAWAEA:
- document lifecycle
- fulfillment linkage
- delivery/invoice visibility
- deadline/validity
- customer-facing terms

Source:
https://www.odoo.com/documentation/19.0/applications/sales/sales.html

## Microsoft Dynamics 365

Current documentation shows:
- Quote → Order → Invoice lifecycle
- Product catalog + Price List + Currency
- revision behavior
- Current Pricing vs Prices Locked
- per-line pricing and discount behavior

Relevant contract patterns:
- price basis
- price lock
- revision identity
- order/invoice continuity

Sources:
https://learn.microsoft.com/en-us/dynamics365/sales/sales-transactions
https://learn.microsoft.com/en-us/dynamics365/sales/create-edit-order-sales
https://learn.microsoft.com/en-us/dynamics365/sales/lock-unlock-price-order-invoice

## SAP

Current SAP Help documentation describes sales pricing conditions covering:
- prices
- discounts
- surcharges
- taxes
- customer/material-specific conditions
- organizational sales-unit scope

Relevant contract patterns:
- deterministic pricing
- condition traceability
- customer/material specificity

Source:
https://help.sap.com/docs/s4hana-cloud-best-practices/create-sales-pricing-condition-mds-bet/purpose

## Daftra

Current Daftra sales documentation includes:
- POS
- barcode and stock visibility
- price lists
- item/invoice discounts
- offers/promotions
- installments
- sales targets and commissions
- loyalty
- customer purchase history

Relevant contract patterns:
- commercial pricing
- customer segmentation
- installment/collection visibility
- loyalty
- target/commission control

Sources:
https://www.daftra.com/en/sales/
https://www.daftra.com/en/pos/
https://www.daftra.com/en/plans

## Manager.io

Historical project evidence already used official Manager.io documentation for quote/order/invoice separation and sales reporting. No unsupported behavior was copied into RAWAEA.

---

# 11. CURRENT DATA MODEL CAPABILITY — WHAT IS ALREADY AVAILABLE

Production already contains first-class sales contracts for:

### Orders
`orders`
- customer
- branch
- sales rep
- channel/source
- payment type
- amount paid
- tracking
- shipping address
- offline metadata
- operation identity

### Order fulfillment
`order_details`
- ordered/picked/loaded/delivered/refused/returned
- reason fields
- driver liability

### Quotes
`sales_quotes`
- valid until
- customer
- branch
- sales rep
- currency
- subtotal
- discount
- tax
- delivery fee
- status
- source
- terms
- revision/operation fields
- sent/accepted/rejected/cancelled/expired/converted timestamps

### Commercial catalogs
`commercial_catalogs`
- currency
- priority
- default
- validity
- active state

### Catalog rules
`commercial_catalog_rules`
- item/category scope
- minimum quantity
- pricing method
- unit price
- percent value
- extra fee
- rounding
- validity

### Promotions
`promotions`
- promotion type
- stacking
- trigger mode
- coupon
- channel
- customer scope
- priority
- minimum subtotal/qty
- maximum discount
- usage limits
- validity

### Payments
`sales_payment_receipts`
`sales_payment_allocations`
- receipt identity
- customer
- cash box
- operation identity
- amount
- allocated/unallocated
- order allocation

### Returns
`sales_return_reviews`
`sales_return_review_events`
- workflow status
- assignment
- notes
- resolution
- review history

### Targets
`sales_target_plans`
`sales_target_assignments`
`sales_target_runs`
`sales_target_run_lines`
- period
- metric
- sales rep/branch assignment
- target amount/qty/gross profit
- actuals
- achievement ratios
- approval/closure
- run identity

### Loyalty
`loyalty_programs`
`loyalty_rewards`
`loyalty_transactions`
- earning/redemption
- expiry
- customer account
- order linkage
- reversal
- operation identity
- metadata

---

# 12. BUSINESS GAP RESULT

The investigation did NOT prove absence of the competitive fields in the backend.

Instead, it proved a more precise gap:

**The production business contracts already contain a large share of the competitive model. The remaining gap is primarily orchestration/presentation/commercial workflow closure in the Mother surface, plus explicit price/document-state visibility where the existing engine already supports it.**

Therefore:
- Do not add duplicate database columns.
- Do not rebuild existing commercial engines.
- Do not create another pricing engine.
- Do not create another payment engine.
- Do not create another target engine.
- Do not create another loyalty engine.
- Do not create another sales decision engine.

Use the Mother surface to expose the existing contracts coherently.

---

# 13. REMAINING MOTHER SURFACES STILL OPEN

Current main.html still contains the heavy work functions identified in Report258.

Current source locations:
- `RW_TeleSales._showNewCustomerForm()` — line 9452
- `RW_Orders._showDetails(code)` — line 10347
- `RW_SalesQuotes.openEditor(quote)` — line 28668
- `RW_SalesQuotes.detail(code)` — line 28751
- `RW_PriceLists.assign(catalogId)` — line 29061
- `RW_PriceLists.detail(id)` — line 29073
- `RW_Promotions.showDetail(id)` — line 29214
- `RW_Promotions.openEditor(id)` — line 29231
- `RW_LoyaltyMain.newProgram()` — line 4229
- `RW_LoyaltyMain.newReward()` — line 4235

These are not being re-fixed here if the exact full replacements already exist in:
`Report258_SALES_MANAGEMENT_FORENSIC_SURGICAL_COMPLETION_20260919.md`

Current source was rechecked and these functions are still present, so those Owner Changesets remain OPEN.

No Router replacement should be made again:
- `sales-management-center` route already exists.
- icon already exists.
- SMC module already exists.

---

# 14. EDGE FUNCTION / SPEND-CAP DECISION

No new Edge Function was created for this closure.

The existing architecture already provides dedicated sales Edge capabilities including:
- sales invoice
- order confirmation/update
- sales quotes
- commercial catalog
- promotion engine
- sales payment allocation
- installments
- commission engine
- sales target engine/dashboard
- loyalty engine
- sales decision center
- sales return management

The Sales Management Center correctly uses:
`sales_management_center_read(...)`

This avoids introducing another Edge Function solely for an aggregation/read surface.

---

# 15. PRODUCTION DATA REPAIR

No destructive Sales data repair was performed.

Reason:
Current Production contains zero active transactional rows for the tested sales contracts.

Therefore there is no proven current Sales dataset requiring cleanup in this scope.

---

# 16. BROWSER E2E STATUS

**Browser Production E2E = OPEN**

Reason:
No real browser execution facility is available in the current tool environment.

Performed instead:
- source-level parser gate
- current Mother source inspection
- Production authenticated RPC verification
- transactional database E2E
- rollback verification
- current row-count verification

Do not report Browser PASS until the Owner executes the exact Mother patches in the live Mother build.

---

# 17. FINAL SELF-AUDIT

### What was proved
- Exact syntax error at line 1504.
- Exact introducing commit: `2ff692...`.
- Current Mother source still contains the missing comma.
- Current SMC route/module/icon already exist.
- Current SMC permission block has a real permission-state source bug.
- Current Production SMC RPC is working.
- Sales Manager and General Manager can read SMC in Production through the existing RPC.
- Temporary Production E2E produced coherent cross-module analytics.
- Temporary Production E2E left zero rows after rollback.
- No backend Sales infrastructure needs duplication.
- No new Edge Function is required.

### What was not proved
- Real browser click-through after Mother cutover.
- Full visual regression across all Sales subpages after modal→page Owner patches.
- Real-user device/browser performance benchmark.

### What was fixed directly in Production
- No new Sales Management Production DDL was required in this checkpoint.

### What remains an Owner change
- PATCH-259-01 syntax comma.
- PATCH-259-02 Sales Management permission source.
- Unapplied modal→page changesets already documented in Report258.

### Risk remaining
The system cannot be judged fully closed while the Mother source remains syntactically invalid and Browser E2E remains unexecuted.

---

# 18. EXACT NEXT RESUMPTION POINT

## First
Owner applies PATCH-259-01 and PATCH-259-02 to:
`erp-frontend/companies/company-1/main.html`

## Then
Run:
1. full JavaScript syntax gate
2. Mother Assembly Guard
3. login
4. open إدارة المبيعات
5. open مركز إدارة المبيعات
6. verify Sales Manager permission
7. verify General Manager permission
8. verify Owner wildcard behavior
9. verify SMC date filters
10. open each existing Sales subpage
11. verify cross-links
12. execute one browser-level read-only E2E
13. re-read Production
14. update this report
15. update CURRENT_STATE

## Do not do
- Do not create another Sales Management Center.
- Do not create another read RPC.
- Do not create a new Edge Function.
- Do not recreate existing Sales engines.
- Do not touch inventory/field-operation contracts.
- Do not reopen already closed backend Sales contracts without new Production evidence.

---

# 19. CONTINUITY INSTRUCTION TO THE NEXT CTO

Start from the exact current checkpoints:

`System HEAD = 891f77...`
→ `Parent = 759ea...`
→ `Mother HEAD = 95c838...`
→ `Mother parent = 2ff692...`
→ `main.html blob = f7857...`
→ inspect PATCH-259-01 and PATCH-259-02
→ parse
→ browser cutover
→ verify Production again.

The commit `2ff692...` is the critical historical boundary because it introduced the Sales Management Center and the missing comma.

Do not infer current Production from Report258.

Do not re-create anything already proven present.

---

# 20. CLOSURE STATUS

**SALES MANAGEMENT PRODUCTION READ CONTRACT = CLOSED**

**SALES MANAGEMENT RPC AUTH/TENANT GATE = CLOSED**

**SALES MANAGEMENT DATABASE E2E = CLOSED**

**SALES MANAGEMENT CURRENT SOURCE DISCOVERY = CLOSED**

**LOGIN SYNTAX ROOT CAUSE = PROVEN**

**OWNER SYNTAX PATCH = OPEN**

**OWNER SALES PERMISSION PATCH = OPEN**

**REMAINING MODAL→PAGE SALES SURFACES = OPEN AS EXISTING OWNER CHANGESETS**

**BROWSER PRODUCTION E2E = OPEN**

**FULL SALES MANAGEMENT 100% CLOSURE = OPEN UNTIL OWNER CUTOVER + BROWSER E2E**
