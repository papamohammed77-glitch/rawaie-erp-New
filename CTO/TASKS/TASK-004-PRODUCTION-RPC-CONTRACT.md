# TASK-004 — Production RPC Contract

## Objective
Establish the actual Production RPC contract for Inventory / Manual Vouchers before any implementation decision.

## Evidence Reviewed
- Production schema / dependency evidence.
- Production index evidence.
- Production FK evidence.
- Production RPC source evidence: `SQL_Evidence/diagnostics/8-FunctionsRPCs whose stored source references Inventory Core.csv`.
- Prior RPC privilege evidence captured during the rescue, where available.

## Proven Production RPCs referencing Inventory Core
The captured Production routine source explicitly contains at least:

1. `cancel_manual_stock_voucher_atomic(p_company_id uuid, p_voucher_code text, p_user_email text)`
2. `complete_manual_stock_voucher_atomic(p_company_id uuid, p_voucher_code text, p_user_email text)`
3. `create_manual_stock_voucher_atomic(p_company_id uuid, p_type text, p_reference text, p_from_type text, p_from_id uuid, p_to_type text, p_to_id uuid, p_notes text, p_created_by text, p_items jsonb)`

The Production source shows these routines are `SECURITY DEFINER` and set `search_path` to `public`.

## Important RPC ↔ Schema Drift
`complete_manual_stock_voucher_atomic` attempts to execute:
`completed_by = p_user_email`

But the captured Production `stock_vouchers` schema does not contain `completed_by`.

Therefore this is a **PROVEN production contract mismatch** and must not be patched by assumption. It must be reconciled explicitly before relying on the COMPLETE RPC.

## Proven Dependencies
The captured RPC source references:
- `stock_vouchers`
- `stock_voucher_details` through the voucher creation path
- `app_settings.company_id`
- branch/company context
- voucher status/type values

The COMPLETE RPC determines expected status from voucher type:
- `Transfer` / `DirectReturn` → `Received`
- `DirectSale` / `SupplierReturn` → `Sent`

The CANCEL RPC permits cancellation only from `Draft` and changes status to `Cancelled`.

Both COMPLETE and CANCEL use row locking on the selected voucher.

## Privileges
The captured RPC source proves `SECURITY DEFINER`, but the complete current privilege matrix must remain tied to the dedicated Production RPC privilege evidence. No privilege is inferred from function source alone.

## Contract Status
| Area | Status |
|---|---|
| RPC identities | PROVEN for captured routines |
| Function definitions | PROVEN for captured routines |
| SECURITY DEFINER | PROVEN |
| search_path | PROVEN (`public`) |
| Voucher dependencies | PROVEN for captured routines |
| RPC ↔ table names | PROVEN |
| RPC ↔ column compatibility | **BLOCKED by `completed_by` drift** |
| Complete privilege matrix | **Evidence-dependent** |
| All Inventory/Voucher RPCs | **Must remain limited to captured Production evidence** |

## CTO Decision
**NO PATCH / NO MIGRATION.**

The Production RPC layer contains a proven schema/function mismatch. Any attempt to modify the schema or RPC before reconciliation would recreate the previous failure mode.

## Gate
**TASK-004 STATUS: BLOCKED**

Reason: `completed_by` schema/RPC drift plus incomplete privilege evidence in the curated repository.

## Required Next Evidence
A fresh Production RPC privilege query is required only if the existing privilege evidence cannot be located/verified in the repository.

After privilege closure, reconcile the `completed_by` decision and then proceed to the next task.
