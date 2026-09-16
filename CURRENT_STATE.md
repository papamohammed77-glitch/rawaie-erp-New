# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-16

## GOVERNING BASIS
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`
Historical reports are reference-only and must not override current evidence.

## SOURCE OF TRUTH
Mother Finance/UI:
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

Historical/reference only:
`rawaie-erp-New/Current/PWA/main2/*`
`rawaie-erp-New/Original/PWA/main/*`

## CURRENT FRONTEND GIT
Repository: `papamohammed77-glitch/erp-frontend`
Branch: `main`
Latest HEAD verified: `2af93b03a0bc5c46e2126d329154c6d176f0d098`
Latest HEAD message: `forensic: persist current Mother inventory extract`
Relevant parent: `68bbd6e1ed8f17e05d1c11fc1ce33e147f46282d`
Parent message: `Add functions for asset management and tax handling`
Current main.html blob observed: `9008e6cafca23b52d4a7664ca820fe725039331c`

## MOTHER FINANCE FORENSIC
Current source contains real Finance renderer implementations and RW_Finance property bindings. The Console error is caused by the dispatcher calling bare identifiers instead of `RW_Finance._render...` properties.

Reported failing lines: `14535–14542`.

Required owner surgery is recorded in:
`doc/Draft/Reprots/Report216_MOTHER_FINANCE_FORENSIC_EXECUTION_20260916.md`

A second real UI gap is `_goldNewExpense`: `renderExpenses()` calls it, but current source has no matching assignment/implementation. Report216 contains the complete surgical insertion.

**Mother main.html modified by assistant:** NO

## PRODUCTION FINANCE
Supabase Production: `fiilmooggumokxanwiyx`

Verified existing operational finance tables:
`finance_tax_codes`, `finance_tax_settlements`, `finance_tax_transactions`, `finance_bank_statements`, `finance_bank_statement_lines`, `finance_cheques`, `finance_cheque_events`, `finance_expenses`, `finance_expense_lines`, `finance_expense_categories`, `finance_periods`, `recurring_journal_templates`, `recurring_journal_lines`, `finance_recurring_runs`, `fixed_assets`, `fixed_asset_events`.

Core RPC contracts for journals, recurring, expenses, cheques, bank reconciliation, taxes, assets, and periods are present.

## PRODUCTION SECURITY ACTION
Migration applied directly:
`finance_rpc_execute_acl_hardening`

Targeted Finance mutation RPCs no longer grant EXECUTE to `PUBLIC/anon`; `authenticated` and `service_role` remain. Verification after migration confirmed the new ACL.

All inspected Finance operational tables have RLS enabled.

## INVENTORY / FIELD OPS
No field operational redesign in this session.
Contract remains:
`Physical Movement → post_stock_movement → stock_branches + inventory_log`

## OPEN VERIFICATION
```text
Mother Finance Console root cause = IDENTIFIED
Production Finance backend = VERIFIED PRESENT
Production Finance mutation ACL hardening = CLOSED
Mother Finance authenticated Browser E2E = OPEN
Recurring automatic scheduler = OPEN
```

No authenticated browser execution was available in this session, so Browser E2E is not marked closed.

## LATEST REPORT
`doc/Draft/Reprots/Report216_MOTHER_FINANCE_FORENSIC_EXECUTION_20260916.md`

## NEXT SESSION START ORDER
1. Re-fetch current Mother `main.html` and current HEAD/parent.
2. Check whether the owner already merged Report216 surgery; do not reapply completed work.
3. Run authenticated Finance browser E2E with Console + Network.
4. Open all Finance subtabs and test their real action paths.
5. Compare every mutation with same-moment Production.
6. Close Finance E2E before moving to another open management area.

**Production modified by assistant:** YES — Finance RPC EXECUTE ACL hardening
