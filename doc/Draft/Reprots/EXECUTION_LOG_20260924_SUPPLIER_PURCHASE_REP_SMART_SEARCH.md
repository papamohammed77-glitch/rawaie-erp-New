# EXECUTION LOG — Supplier Purchase Representative Smart Search — 2026-09-24

## Closure
Mother ERP → Suppliers → New Supplier → مسؤول المشتريات

## Current Truth
System HEAD at closure start:
85ad9d2b1a195e5b8845a6550beec5fd85fdfc41

Mother HEAD:
897d40c47b27544fb8a5515a7f7dcce528c4563e

Mother main.html blob:
f4e707060a3f0ff68b993bf57616e4e861ac54e6

## Historical delta
Previous supplier-code Preview was applied by Owner in commit:
3520240a57f2124bbcf96c3007f67a9c36890fcb

This cycle does not reopen that fix.

## Current defect
RW_Suppliers.openModal(code), current line 6935:
plain text input id=supp-rep.

## Root Cause
1. No smart search UI.
2. public.users RLS prevents universal direct employee-directory reads for supplier editors.
3. suppliers.purchase_rep is currently text-based; no purchase_rep_id FK exists.

## Production action
Created/deployed:
public.get_supplier_purchase_reps(text)

Security:
- SECURITY DEFINER
- auth.uid required
- suppliers permission required
- company derived from current user
- Active users only
- Role Master = مسئول مشتريات
- anon execute revoked
- authenticated execute granted

Hardened:
public.save_supplier_atomic(...)

Validation:
- CREATE/UPDATE resolves purchase rep by active company purchaser name or email.
- Canonical stored value = users.name.
- Invalid rep rejected.
- Existing financial balance remains authoritative.

No new Edge Function.
No new table.
No new column.
No inventory/accounting rewrite.

## Duplicate history check
Earlier public.supplier_purchase_rep_search(text) was formally retired by:
20260924083623_remove_duplicate_supplier_rep_search_rpc.sql

Current Production contains only:
public.get_supplier_purchase_reps(text)

## Search tests
Authenticated buyer:
- blank search → 1 row, exact buyer.
- buyer1 search → exact buyer.
- Arabic multi-token search → exact buyer.

Unauthorized direct-sales user:
- RPC rejected with permission error.

## Save tests
Valid email:
- CREATE = PASS
- supplier code generated = SUPP-1003 in transient transaction.

Valid canonical name:
- CREATE = PASS.

Invalid name:
- rejected as invalid/inactive purchaser.

All QA supplier transactions rolled back.

## Purchase integration E2E
Supplier CREATE
→ Purchase Invoice CREATE
→ POST
→ Stock
→ inventory_log
→ Supplier Ledger
→ Journal
→ POST replay

Measured:
stock 2 → 3
inventory_log 6 → 7
supplier_ledger 0 → 1
journal_entries 8 → 9
journal_lines 12 → 14
POST replay → duplicate=true

Full rollback completed.
Production returned to baseline:
suppliers 2
purchase_invoices 0
inventory_log 6
supplier_ledger 0
journal_entries 8
item1001 BR-01 stock 2

## Source surgical verification
Target occurrence = 1
Replacement occurrence = 1
Current main.html line count = 32068
Inline script blocks inspected = 2
JavaScript parse = PASS
main.html repository write = NO

## Owner Surgical Patch
File:
erp-frontend/companies/company-1/main.html

Function:
RW_Suppliers.openModal(code)

Current line:
6935

Replace only the exact old supp-rep element with the full replacement documented in Report326.

Do not modify _handleSave.

## Browser
Authenticated Browser E2E:
OPEN / UNVERIFIED

Reason:
No authenticated browser runtime was available.

## Final status
Production capability = CLOSED / VERIFIED
Source target = VERIFIED / READY
Owner frontend patch = PENDING
Published artifact = OPEN
Browser E2E = OPEN

## Exact next step
Owner applies only the Report326 supp-rep surgical replacement, then:
Full parse → commit → publish → served artifact identity → authenticated browser E2E → fresh Production snapshot → CURRENT_STATE update.
