# CTO Closure Unit — complete-picking — 2026-08-16

## Status

**NOT 100% CLOSED**

Reason: the executable Core/security portions are verified in Production, but two governance/runtime evidence items cannot be completed from the available tools:

1. authenticated HTTP E2E against the deployed `complete-picking` endpoint requires a real user JWT;
2. retired Production canary functions remain present in the Edge registry and the available Supabase toolset exposes no Edge-function deletion operation.

No Production fixture was permanently changed by the canaries in this unit; all data-path canaries used `ROLLBACK`.

## Production identity

### complete-picking
- Version: 13
- Status: ACTIVE
- verify_jwt: true
- Runtime artifact hash: `ca595c1ffabaebfe996b6f573a26201f15f1ef3b6735e9341e665afe429ca036`

### start-picking
The currently available direct Supabase inspection returns:
- Version: 29
- Status: ACTIVE
- verify_jwt: false
- Runtime artifact hash: `f630a32fbf9887b8ea28e63864d46f7bfe6cbea46123c5b20e704697ffabc3ed`
- Deployed source uses `public.users.auth_id = auth.users.id`.

An independent owner-side observation reported v14 / verify_jwt=true. This remains recorded as an external observation conflict; it was not used as runtime truth for this closure unit.

## Core verification

Production `complete_runsheet_picking` is:
- SECURITY DEFINER
- `search_path=public`
- executable by `service_role`
- not executable by `anon` / `authenticated`

The Core:
- locks the runsheet;
- resolves the application user by company + email;
- uses `reserve_stock` for physical reservation;
- updates `order_details.qty_picked`;
- transitions `Picking → Picked`;
- does NOT call `post_stock_movement`.

## Runtime canary

A real Production transaction was used with the existing `RS-2` record. Inside the transaction:
- company/picker context was temporarily normalized to the current Production `app_settings` company;
- a temporary order/detail for item `1002`, qty 1, was added;
- `complete_runsheet_picking` was executed using the Production Core;
- result: `success=true`, `runsheet_status=Picked`, one line `qty_picked=1`;
- physical stock `qty` remained unchanged at `201`;
- `allocated_qty` became `1` inside the canary;
- transaction was rolled back.

Therefore the Core's key invariant is directly verified:

`Picking → reservation only; no physical stock deduction.`

## Failure / rollback canary

A second Production transaction attempted to pick qty 2 against an ordered qty 1.

Observed:
- error: `picked quantity exceeds ordered quantity for 1002`
- runsheet remained `Picking`
- `qty_picked` remained `0`
- physical `qty` remained `201`
- `allocated_qty` remained `0`

Transaction rolled back.

This verifies atomic failure behavior for the tested Core path.

## Security repair executed

Production ACLs were corrected for:
- `post_inventory_adjustment_atomic`
- `post_manual_stock_voucher_atomic`
- `setup_van_stock`

The initial revoke against `anon/authenticated` was insufficient because `PUBLIC` still inherited EXECUTE. The final repair revoked from `PUBLIC, anon, authenticated`.

Final effective privileges:

- PUBLIC: denied
- anon: denied
- authenticated: denied
- service_role: allowed

The same repair was committed to Current migrations as:

`supabase/migrations/20260816_reconcile_inventory_core_execute_grants.sql`

Git commit:

`99d5f48063903700d43ddf9b13ce2a4372a5577a`

## Writer sweep result relevant to this unit

Production PostgreSQL source inspection classified:

- `post_stock_movement` — Central Physical Movement
- `reserve_stock` / `release_stock_reservation` — Reservation
- `post_inventory_adjustment_atomic` — Orchestrator
- `post_manual_stock_voucher_atomic` — Orchestrator
- `complete_runsheet_reopen_loading` — Orchestrator
- `setup_van_stock` — Initialization

No Production trigger directly attached to `stock_branches` / `inventory_log` was found in the inspected trigger catalog.

## Consumer evidence

Historical Picker PWA uses authenticated Supabase sessions and calls:
- `start-picking`
- `complete-picking`
- `cancel-picking`
- `reopen-picking`

`complete-picking` payload is:

```json
{
  "runsheet_code": "...",
  "items": [
    {"itemCode":"...","pickedQty":1,"notes":"..."}
  ]
}
```

## What is proven

- Production `complete-picking` is active v13.
- The deployed Edge is an adapter to `complete_runsheet_picking`.
- The Core is transactional and reservation-driven.
- Physical stock is unchanged by Picking in the tested canary.
- Invalid over-pick is rejected atomically.
- Core security boundary is correct for `complete_runsheet_picking`.
- Related central/orchestrator RPC ACL debt was corrected and verified.
- Current migration provenance now contains the ACL correction.

## What is not proven

- authenticated HTTP E2E through the real `complete-picking` Gateway/Edge with a live user JWT;
- real concurrent two-session race test from separate DB sessions;
- deletion of the retired complete-picking Production canary functions;
- absolute system-wide zero-writer proof beyond the inspected stored functions and reviewed Edge sources.

## Manual owner action required for final 100% close

Provide one valid authenticated picker JWT (or execute one authenticated Production HTTP request to `complete-picking` using the existing canary fixture) so the final HTTP E2E can be verified; the retired Production canary functions must also be removed from the Edge registry before Governance can be marked closed.

## Final Closure Status

**IMPLEMENTED + PRODUCTION CORE VERIFIED + SECURITY VERIFIED + ROLLBACK VERIFIED**

**NOT 100% CLOSED** because HTTP E2E, concurrent-session proof, and runtime canary deletion are not yet evidenced.
