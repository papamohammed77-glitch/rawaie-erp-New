# RAWAEA ERP — 2026-08-25 Forensic Review and Closure Corrections

## Authority

This record is based on direct inspection of current Production Supabase, current Edge Function deployments, current Git, current migrations, and the governing memory/phase directives. Historical reports are evidence only and are not treated as current truth without revalidation.

## Current Production Baseline at Review

- Supabase project: `fiilmooggumokxanwiyx`
- Current Git main at review start: `dd6735cf7efb07c8471fe9a0c4ae952e4ff612d7`
- PostgreSQL: 17.6.1.121
- Companies: 1
- Users: 24
- Branches: 2
- Items: 17
- Stock rows: 20
- Inventory log rows: 3
- Treasury rows: 1
- Chart of Accounts rows: 17
- Journal entries: 2
- Journal lines: 0
- Receiving rows: 0
- Purchase Orders: 0
- Orders: 0
- Runsheets: 0

## Findings

### Confirmed correct

1. The Inventory architectural contract remains valid: physical stock mutation is centralized through `post_stock_movement`; `reserve_stock` and `release_stock_reservation` are reservation engines, not independent physical movement engines.
2. `post_manual_stock_voucher_atomic`, `post_inventory_adjustment_atomic`, `receive_purchase_atomic`, `complete_return_atomic`, `post_cash_receipt_atomic`, `post_cash_payment_atomic`, `post_journal_entry`, `post_driver_ledger_entry`, `post_driver_liability_entry`, and `post_daily_settlement_atomic` are real Production cores with operation/idempotency controls in their current definitions.
3. Hytham's receive-purchase JSONB-to-UUID correction is deployed in the latest Production migration chain (`20260825192133_fix_receive_purchase_journal_result_cast`).
4. Khalid's historical 87-COA source-exhaustion decision remains valid: historical recovery must stop when authoritative sources are exhausted; current COA rows are current master data, not fabricated historical recovery.

### Corrections required

1. `update-driver-ledger` was still a live direct writer to `driver_ledger`, outside the canonical `post_driver_ledger_entry` core. This violated Financial Zero-Debt.
2. Production grants still exposed `post_daily_settlement_atomic` and `post_driver_liability_entry` to `PUBLIC`, `anon`, and `authenticated`, despite the intended core-only execution boundary. Related SECURITY DEFINER functions also remained directly callable by authenticated clients.
3. `save-transfer-voucher` remains a live legacy financial writer that directly modifies `cash_box`, `journal_entries`, `journal_lines`, and `treasury`, with a historical hard-coded company id. No current canonical transfer core was found in Production. This is therefore an OPEN financial writer closure unit, not silently reclassified as closed.
4. Current PWA financial proposals from Khalid/Hytham must not be copied verbatim. PWA account lookup must use authenticated company context, company-scoped master-data queries, UUID-based selections, and must not invent/default offset accounts.

## Production Changes Executed

### A. Financial Core Execute Surface

Migration applied:
`20260825224500_close_financial_core_execute_surface.sql`

Effect:
- revoked `PUBLIC`, `anon`, and `authenticated` EXECUTE on the identified SECURITY DEFINER financial/control functions;
- granted EXECUTE only to `service_role`.

Post-change Security Advisor result:
- the previous SECURITY DEFINER EXECUTE warnings disappeared;
- remaining warnings are unrelated to this closure (`auth_leaked_password_protection`), plus the informational RLS-no-policy state on `erp_operation_registry`.

### B. `update-driver-ledger`

Production Edge Function advanced from v1 to v2.

New behavior:
- validates authenticated user and company context from `public.users.auth_id`;
- generates or accepts a deterministic/supplied operation id;
- calls `post_driver_ledger_entry`;
- no direct `driver_ledger` DML remains in the Edge Function.

Git synchronized:
`Current/Edge_Functions/update-driver-ledger`

## What remains OPEN

### Financial Writer Closure

- `save-transfer-voucher` — OPEN. Requires a canonical treasury-transfer core or proven retirement after runtime consumer verification. No speculative replacement was deployed.
- `save-journal-entry` — currently uses canonical `post_journal_entry`; runtime/E2E proof remains open.
- receipt/payment/daily settlement — core boundaries corrected, but authenticated runtime and concurrency evidence remain open.
- full Financial Writer Matrix and direct-DML re-scan remain mandatory before Phase 3 closure.

### PWA

No speculative PWA production mutation was made in this review. The proposed functions from Khalid/Hytham are design candidates only until company-scoped runtime validation and current Production contract checks are complete.

### Inventory

Global Inventory Zero-Debt is not declared closed merely because the central core exists. Writer-by-writer runtime verification remains required, including loading/unloading and actual HTTP concurrency evidence.

## Self-Audit

### Confirmed facts

- Current Production exposes 17 COA rows.
- Current Production has 1 Treasury row.
- Current Security Advisor no longer reports the reviewed SECURITY DEFINER execution warnings after the grant correction.
- `update-driver-ledger` v2 is deployed and calls the canonical driver ledger core.
- `save-transfer-voucher` is still a legacy direct financial writer and remains OPEN.

### Unknowns

- Real browser/PWA runtime coverage for the financial screens after backend convergence.
- Live concurrency proof for all current financial and inventory endpoints.
- Whether any external/non-repository consumer still invokes `save-transfer-voucher`.

### Final closure status

**NOT 100% CLOSED.**

The correct state is: core architecture substantially converged, selected production security/direct-writer defects corrected, remaining closure units explicitly registered rather than hidden.
