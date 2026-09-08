# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-08

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
PRODUCTION = SMART ERP / fiilmooggumokxanwiyx
LATEST FORENSIC REPORT = doc/Draft/Reprots/Report82_Main5_M5-20_Historical_Contract_Reconciliation_20260908.md
```

## GOVERNANCE

```text
CURRENT REALITY > CURRENT GIT > CURRENT PRODUCTION > CURRENT DEPLOYMENTS > CURRENT DATABASE CONTRACTS > VERIFIED ARTIFACTS > HISTORY > REPORTS > MEMORY > ASSUMPTIONS
UNKNOWN != BUG
UNKNOWN != REMOVE
ONE CLOSURE UNIT AT A TIME
SOURCE != RUNTIME PROOF
GIT != PRODUCTION PROOF
NO CLOSURE CLAIM WITHOUT CURRENT EVIDENCE
```

## MAIN4

```text
SOURCE = CLOSED
RUNTIME = OPEN
BLOB = e89d29e4164c68784c109292f27d4d77df240557
```

## MAIN5 — CURRENT TARGET

```text
PATH = Current/PWA/main2/main5.md
BLOB = 9f9926511c47f0295019daaf09ff4b5a1a2efc50
FULL SOURCE READ = REVERIFIED 2026-09-08 THROUGH EOF
EOF = window.RW_Runsheets = RW_Runsheets;
SOURCE = OPEN
RUNTIME = OPEN
```

`main5.md` was not modified during this session.

## MAIN5 — VERIFIED CLOSED ITEMS

```text
M5-15 = CLOSED BY SOURCE
M5-16 = CLOSED BY SOURCE
M5-17-A = CLOSED BY SOURCE
M5-17-B = CLOSED BY SOURCE
M5-18 = CLOSED BY SOURCE + PRODUCTION REALTIME FOUNDATION
M5-19 = CLOSED BY SOURCE + PRODUCTION REALTIME FOUNDATION
M5-13-A = SOURCE VERIFIED / APPLIED
M5-13-B = SOURCE VERIFIED / APPLIED
M5-13-C = SOURCE VERIFIED / APPLIED
```

## M5-13 — BACKEND + SOURCE ROUTING

```text
RPC = public.manage_runsheet_atomic
OPERATIONS = UPDATE / CANCEL / DELETE
SECURITY = SECURITY DEFINER
EDGE = manage-runsheet v1 ACTIVE
VERIFY_JWT = true
```

M5-13 remains closed and was not reopened.

## M5-20 — CURRENT RECONCILED STATE

The previous Report81 conclusion that `Invoiced` must be removed from main5 is superseded by newly re-opened historical evidence and the owner’s explicit historical contract.

### Historical Contract

The original `rawaie-erp-review/Edge_Functions/original/01_order_lifecycle/delete-order.ts` proves that the historical parent system supported deletion of executed orders after reversal of stock/accounting effects.

The current owner clarification confirms the specific business rule:

```text
Cashier POS may create the invoice.
Cashier must NOT receive the authority to modify/delete an executed POS invoice.
Parent system / authorized manager / authorized supervisor may delete it.
Deleting an Invoiced POS order returns the system to the pre-order state by reversing effects and hard-deleting the order.
```

### Current Target Contract

`Invoiced` deletion is preserved, but is now owned by the Production Core capability rather than by UI logic alone.

```text
Invoiced
+
source = pos
+
no runsheet_id
+
privileged effective permission
→ delete_order_atomic
→ reverse stock/accounting/ledgers
→ audit
→ hard delete
```

### Privileged effective permissions verified in Production

```text
*
general_manager
sales_manager
sales_supervisor
```

Current active user population matching these authorities = 4.

Current active non-privileged users = 20.

The current cashier record has:

```text
role = كاشير
permissions = ["pos"]
role_id = NULL
```

and does not match the privileged authority set.

## M5-20 — PRODUCTION IMPLEMENTATION

### Database Core

Created/updated:

```text
public.delete_order_atomic(uuid,text,text)
```

Properties:

```text
SECURITY DEFINER = true
anon EXECUTE = false
authenticated EXECUTE = false
service_role EXECUTE = true
```

The function:

```text
preserves Draft / Confirmed / Pending deletion
restricts Invoiced deletion to POS-origin invoices
requires privileged effective permission
requires no runsheet linkage
reverses Physical Stock through post_stock_movement
reverses Journal through post_journal_entry
reverses Customer Ledger through post_customer_ledger_entry when applicable
reverses Driver Ledger through post_driver_ledger_entry when applicable
records delete operation in erp_operation_registry
writes audit_log
then deletes order_details and orders
```

### Inventory Ownership

The Physical Stock contract remains immutable:

```text
PHYSICAL STOCK MOVEMENT
→ post_stock_movement
→ stock_branches + inventory_log
```

The new order deletion capability contains no direct `stock_branches.qty` mutation.

### Edge Function

`delete-order` was updated and deployed:

```text
VERSION = 9
STATUS = ACTIVE
VERIFY_JWT = true
DEPLOYMENT ID = cd9b6859-725b-4286-8a7d-e7d503da0280
DEPLOYMENT UTC = 2026-09-08 03:12:17.477000+
```

Git source was updated at:

```text
Current/Edge_Functions/delete-order
```

Source update commit:

```text
a4c26d7c5e1a0ebfb0d394b04810126c497b18a4
```

Canonical migration recorded in Git:

```text
supabase/migrations/20260908_close_parent_pos_invoiced_order_deletion.sql
```

Migration commit:

```text
9c2dab4cb7a5f04a36472ae92324f90f1c2380fe
```

## M5-20 — SOURCE INSTRUCTIONS FOR MAIN5

`main5.md` is owned by the user for surgical source editing. Do not modify it through tools.

Do NOT apply Report81's old instruction to remove `Invoiced` entirely.

Apply exactly these source changes:

### M5-20-A — RW_Orders._renderTable

Find this complete block:

```js
// ✅ تعديل: إضافة Invoiced للحالات التي يمكن حذفها (طالما لا يوجد runsheet_id)
console.log('DEBUG_DELETE:', o.order_code, o.order_status, o.runsheet_id);
var canDelete = (o.order_status === 'Draft' || o.order_status === 'Confirmed' || o.order_status === 'Invoiced') && !o.runsheet_id;
```

Delete the complete block through the line ending:

```text
!o.runsheet_id;
```

Replace it with:

```js
var currentUser = (typeof RW_STATE !== 'undefined' && RW_STATE.app) ? RW_STATE.app.currentUser : null;
var permissions = (currentUser && Array.isArray(currentUser.permissions)) ? currentUser.permissions : [];
var canDeleteInvoiced = !!(currentUser && (currentUser.isOwner === true || permissions.indexOf('*') !== -1 || permissions.indexOf('general_manager') !== -1 || permissions.indexOf('sales_manager') !== -1 || permissions.indexOf('sales_supervisor') !== -1));
var canDelete = (o.order_status === 'Draft' || o.order_status === 'Confirmed' || o.order_status === 'Pending' || (o.order_status === 'Invoiced' && canDeleteInvoiced)) && !o.runsheet_id;
```

### M5-20-B — Debug removal

Find this complete line:

```js
console.log('DEBUG_DELETE:', o.order_code, o.order_status, o.runsheet_id);
```

Delete the complete line, including `);`.

### M5-20-C — RW_Orders._showDetails

Find this complete five-line block:

```js
// ✅ زر حذف الأوردر – يظهر لـ Draft، Pending، Confirmed غير المرتبطة برانشيت
// ✅ تعديل: إضافة Invoiced واستبعاد Returned/Partially Returned
var cannotDeleteStatuses = ['Returned', 'Partially Returned', 'Cancelled'];
var isDeletable = (order.order_status === 'Draft' || order.order_status === 'Pending' || order.order_status === 'Confirmed' || order.order_status === 'Invoiced');
var canDelete = isDeletable && !order.runsheet_id && cannotDeleteStatuses.indexOf(order.order_status) === -1;
```

Delete the complete block through the line ending:

```text
cannotDeleteStatuses.indexOf(order.order_status) === -1;
```

Replace it with:

```js
// ✅ حذف Invoiced من النظام الأم متاح فقط للمستخدم المصرح له تاريخيًا.
var currentUser = (typeof RW_STATE !== 'undefined' && RW_STATE.app) ? RW_STATE.app.currentUser : null;
var permissions = (currentUser && Array.isArray(currentUser.permissions)) ? currentUser.permissions : [];
var canDeleteInvoiced = !!(currentUser && (currentUser.isOwner === true || permissions.indexOf('*') !== -1 || permissions.indexOf('general_manager') !== -1 || permissions.indexOf('sales_manager') !== -1 || permissions.indexOf('sales_supervisor') !== -1));
var isDeletable = (order.order_status === 'Draft' || order.order_status === 'Pending' || order.order_status === 'Confirmed' || (order.order_status === 'Invoiced' && canDeleteInvoiced));
var canDelete = isDeletable && !order.runsheet_id;
```

No other main5 edits are authorized in M5-20.

## TESTING / EVIDENCE

### Production current data

Fresh SQL verification:

```text
UTC = 2026-09-08 03:10:41.530622+
orders = 0
invoiced_orders = 0
pos_origin_orders = 0
```

Therefore no live operational Invoiced POS order existed to execute a destructive reversal test.

### Production database verification

Verified:

```text
post_stock_movement exists and remains canonical
post_journal_entry exists
post_customer_ledger_entry exists
post_driver_ledger_entry exists
delete_order_atomic exists
```

### Runtime limitations

Full live success path for deleting an actual Invoiced POS order remains unproven because the current Production database contains no eligible order and the safe fixture injection path was blocked by execution safety controls.

No permanent test data was inserted.

No Production business order was modified or deleted in this closure.

## FAILED ATTEMPTS / FAILURE MEMORY

### Test harness failure 1
A Transaction test was initially written with `DECLARE` outside a PL/pgSQL block.

Result: test did not reach business execution.

### Test harness failure 2
A test fixture attempted to write `order_details.line_amount` directly.

Production schema proved it is a generated column.

Result: test method corrected; production schema was not changed.

### Test harness failure 3
Direct fixture DML for a full Invoiced-order runtime test was blocked by tool safety.

Result: no persistent test pollution and no bypass of safety controls.

### Important reconciliation failure avoided
Report81's previous recommendation to remove Invoiced from main5 was NOT reapplied. Historical contract evidence was reopened before source modification and changed the decision.

## DATA REPAIR

No Production data repair was required in this closure because current Production contains no Orders and no Invoiced POS orders.

No permanent fixture data was introduced.

## CURRENT GIT STATE

Main5 source remains:

```text
9f9926511c47f0295019daaf09ff4b5a1a2efc50
```

The current main branch now also contains:

```text
Edge source update commit = a4c26d7c5e1a0ebfb0d394b04810126c497b18a4
Canonical migration commit = 9c2dab4cb7a5f04a36472ae92324f90f1c2380fe
Report82 commit = be610db2fdafe4f959581bc107dcff2e1f6f507a
```

The state file update is the current administrative continuity update; the Main5 source blob itself is unchanged.

## REPORT HISTORY

```text
Report79 = M5-13 backend closure + source instructions
Report80 = M5-13 source reconciliation + M5-20 discovery
Report81 = M5-20 previous consumer-drift conclusion
Report82 = M5-20 historical contract reconciliation + Production capability restoration
```

No report was deleted.

## WHAT CHANGED THIS SESSION

```text
Current/PWA/main2/main5.md = NOT MODIFIED
Current/Edge_Functions/delete-order = UPDATED
Production delete_order_atomic = CREATED / HARDENED
Production delete-order = DEPLOYED v9
Canonical migration = ADDED TO GIT
Report82 = CREATED
CURRENT_STATE.md = UPDATED
Production business data = NOT MODIFIED
```

## WHAT WAS PROVEN

```text
main5 was read from SOF through EOF
Historical delete-order contract supports executed-order reversal/delete
The owner’s historical POS Invoiced deletion rule is consistent with the historical implementation
Current Production had dropped that capability
The capability is now rebuilt in the current Core architecture
Physical Stock reversal is delegated to post_stock_movement
Accounting reversal is delegated to post_journal_entry
Customer/Driver reversal uses their current ledger engines
Backend grants do not expose delete_order_atomic to authenticated/anon
Edge delete-order v9 is ACTIVE and verify_jwt=true
main5 remains untouched
```

## WHAT WAS NOT PROVEN

```text
Live successful deletion of an actual Invoiced POS order in current Production
Live browser E2E for M5-20
Post-delete realtime browser behavior
Final parent release closure
```

## FINAL STATUS

```text
HISTORICAL CONTRACT = RECONCILED
PRODUCTION DB CAPABILITY = IMPLEMENTED
PRODUCTION DEPLOYMENT = CLOSED
GIT EDGE SOURCE = ALIGNED
CANONICAL MIGRATION = RECORDED
MAIN5 SOURCE = OPEN / USER PATCH REQUIRED
MAIN5 RUNTIME = OPEN
LIVE INVOICED REVERSAL TEST = OPEN
BROWSER E2E = OPEN
MAIN5 FINAL RELEASE GATE = OPEN
```

## NEXT AUTHORIZED ACTION

The user applies only M5-20-A, M5-20-B, and M5-20-C above to `Current/PWA/main2/main5.md`.

Then the next session must:

```text
READ main5 FROM SOF TO EOF
VERIFY THE THREE SURGERIES
RUN SYNTAX / STRUCTURE CHECK
VERIFY DELETE-ORDER CONSUMER PATH
VERIFY CURRENT PRODUCTION AGAIN
VERIFY EDGE v9 AGAIN
WHEN AN ACTUAL Invoiced POS ORDER EXISTS:
RUN LIVE REVERSAL TEST
VERIFY STOCK
VERIFY INVENTORY LOG
VERIFY JOURNAL REVERSAL
VERIFY CUSTOMER / DRIVER LEDGERS
VERIFY AUDIT
VERIFY REALTIME UI
```

## FORBIDDEN ACTIONS

```text
Do not remove Invoiced support from main5.
Do not revert delete-order to the old v8 guard.
Do not expose delete_order_atomic to authenticated/anon.
Do not copy Original delete-order directly into Production.
Do not add direct stock writes to main5 or Edge.
Do not grant the cashier Invoiced deletion authority.
Do not apply Report81 blindly.
Do not modify main5 anywhere except the exact three surgery windows above.
Do not declare M5-20 Fully Closed before live/runtime evidence exists.
```

## LAST VERIFIED EVENT

```text
EVENT = Main5 M5-20 historical contract reconciliation + Production capability restoration
UTC = 2026-09-08 03:12:17.477000+
PRODUCTION = fiilmooggumokxanwiyx
GIT SOURCE EVENT = a4c26d7c5e1a0ebfb0d394b04810126c497b18a4
PRODUCTION EDGE = delete-order v9 ACTIVE
PRODUCTION RPC = public.delete_order_atomic
MAIN5 BLOB = 9f9926511c47f0295019daaf09ff4b5a1a2efc50
REPORT = doc/Draft/Reprots/Report82_Main5_M5-20_Historical_Contract_Reconciliation_20260908.md
RESULT = Historical contract reconciled; backend capability restored; main5 source surgery still open; live Invoiced runtime closure not yet proven
```

This state intentionally distinguishes Production/backend closure from Main5 source and runtime closure so the next CTO does not reopen or repeat the superseded Report81 decision.