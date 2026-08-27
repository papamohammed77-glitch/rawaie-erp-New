# RAWAEA ERP — ACCOUNTANT CONTROL CENTER FORENSIC CLOSURE R3

Date: 2026-08-28
Production evidence snapshot: 2026-08-27 23:11:00+00 (UTC)
Git main after closure: `61fe73b2aec11e6e45b5dc0b81c563c70707cf19`
Target file: `Current/PWA/accountant.html`
Target blob after closure: `faeb2147e430188af4c5fcb024413d4ac7028230`

## Governing method

This closure was executed under the governing principles and Prompt 72:

UNDERSTAND → RECONSTRUCT HISTORICAL CONTRACT → TRACE CURRENT BEHAVIOR → TRACE DATA/AUTH/CONTROL FLOW → COMPARE WITH TARGET → IDENTIFY ACTUAL GAP → MINIMAL SAFE CHANGE → IMPLEMENT → VERIFY.

Historical reports were treated as evidence only. Current Production and current Git were re-read before accepting or rejecting earlier claims.

## Production re-baseline

Current Production contains:

- 1 company
- 24 users
- 2 branches
- 17 items
- 20 stock rows
- 3 inventory_log rows
- 0 stock vouchers
- 1 treasury
- 17 chart-of-accounts rows
- 2 journal entries
- 0 journal lines
- 0 customer ledger rows
- 0 supplier ledger rows
- 0 driver ledger rows
- 0 orders
- 0 purchase orders
- 0 runsheets
- 0 cash_box rows
- 0 erp_operation_registry rows

Production integrity checks at the snapshot:

- negative physical stock: 0
- allocated stock above physical: 0
- posted journals without lines: 0
- unbalanced journals: 0

## Accountant Control Center Production contracts verified

The following Read Models exist in Production and were invoked with exact deployed signatures:

- accountant_audit_feed
- accountant_coa_tree
- accountant_customer_aging
- accountant_exception_center
- accountant_gl_account_activity
- accountant_inventory_control
- accountant_order_center
- accountant_period_readiness
- accountant_reconciliation_summary
- accountant_runsheet_center
- accountant_supplier_aging
- get_trial_balance
- get_profit_loss
- get_balance_sheet
- get_cash_flow
- get_pnl_by_cost_center

Important correction: `accountant_runsheet_center` has a default value for `p_status`; therefore omission of that argument was not itself a defect. The final page passes `p_status:null` explicitly for contract clarity.

Important correction: Production `get_balance_sheet` expects `p_as_of`, not `p_as_of_date`.

## Code changes actually applied

`Current/PWA/accountant.html` was replaced by the R3 production source and contains:

1. Company context resolution through authenticated `users.auth_id → company_id`.
2. Company-scoped treasury and chart-of-accounts reads.
3. Exact deployed RPC argument names.
4. Local-date generation instead of UTC date slicing for accounting UI dates.
5. Correct Balance Sheet call using `p_as_of`.
6. Runsheet call with explicit `p_status:null`.
7. Stale-render protection through render tokens.
8. CSV export with explicit CRLF row separators.
9. Safer G/L account selection using DOM data attributes rather than embedding account labels in executable inline strings.
10. Journal view handling empty result sets before issuing dependent `IN` queries.
11. Receipt/payment writes continue through canonical Edge Functions and existing Core operations; no direct financial-table writes were introduced.
12. Pending cash-operation preservation in `sessionStorage` with the same operation ID for retry.
13. Near-real-time refresh every 15 seconds plus online/visibility-triggered refresh. This is intentionally polling, not Supabase Realtime.
14. Refresh is suppressed while an input is active, while a modal is open, while offline, and while another refresh is already running.
15. Old external certification harness `Current/PWA/accountant-live-certification.html` was removed because Prompt 72 explicitly disallows external test/harness files and it could produce a misleading certification surface.

## Production DB gap fixed

The Accountant Read Models are SECURITY INVOKER and rely on the authenticated user company context. Production had an actual privilege gap:

`authenticated` lacked `SELECT` on `public.erp_operation_registry` while `accountant_period_readiness` and `accountant_exception_center` legitimately read that table under RLS.

Production RLS already restricted `erp_operation_registry` to:

`company_id = app_private.current_user_company_id()`

The fix applied was only:

`GRANT SELECT ON TABLE public.erp_operation_registry TO authenticated;`

No RLS policy was weakened.

## Production Read Model runtime-equivalent verification

A controlled SQL session was run as role `authenticated` with a real existing Owner identity from `public.users` injected into the request JWT claims, then rolled back.

All 15 Accountant Read Model surfaces returned successfully under the same company-context mechanism used by Production:

- reconciliation: returned
- readiness: returned 5 gates
- exceptions: returned 0 rows
- runsheets: returned 0 rows
- orders: returned 0 rows
- customer aging: returned 0 rows
- supplier aging: returned 0 rows
- inventory control: returned 1 aggregate row
- COA tree: returned 17 rows
- audit feed: returned 216 rows
- trial balance: returned 17 rows
- profit & loss: returned successfully
- balance sheet: returned 13 rows
- cash flow: returned successfully
- P&L by cost center: returned successfully

No business mutation was persisted by this verification transaction.

## Realtime boundary

Production `supabase_realtime` publication currently does not contain the Accountant financial/operational tables checked during this investigation. Repository search also found no `postgres_changes` implementation.

Therefore the page must not claim WebSocket/Supabase Realtime synchronization. R3 uses safe polling/visibility/online refresh instead.

## What was explicitly rejected

- No new financial core was invented.
- No duplicate journal/treasury writer was added to the HTML.
- No `LIMIT 1` company selection was introduced into the Accountant page.
- No tenant-blind item/account lookup was added.
- No persistent accounting-period-close contract was invented; Production still exposes readiness as review-only for that gate.
- No unverified report snapshot was promoted to Production truth.

## Self-audit

### Confirmed facts

- Current Git main contains the R3 Accountant source.
- Production has one current company context and clean stock/journal invariants.
- All intended Accountant Read Models exist and return successfully under authenticated company context.
- The missing `erp_operation_registry` SELECT privilege was fixed without weakening RLS.
- The deprecated external certification harness was removed.

### Unknowns / unverified claims

- A live browser session against the externally served PWA was not available in this tool environment; therefore browser-rendering and click-by-click runtime behavior cannot be honestly marked 100% certified.
- The external static hosting layer serving `Current/PWA/accountant.html` was not identifiable from the repository metadata/search performed here; Git main != proof of external hosting deployment.
- Supabase Realtime is not enabled for the Accountant tables; the page therefore provides polling-based near-real-time refresh, not true push realtime.

### Conflicts resolved

- Earlier claim that `accountant_runsheet_center` required three mandatory parameters was corrected: Production defines `p_status DEFAULT NULL`.
- Earlier Balance Sheet parameter usage was corrected to the actual Production signature `p_as_of`.
- Earlier harness-based certification was rejected because it violated the governing test-file boundary.

### Final closure status

**ACCOUNTANT CONTROL CENTER CODE/CONTRACT CLOSURE: CLOSED**

**ACCOUNTANT CONTROL CENTER FORMAL 100% CERTIFICATION: NOT CLAIMED**

The final 100% label is intentionally withheld because Prompt 72 requires actual browser/runtime and served-production verification, and the external hosting/runtime path is not observable from the available execution environment.

This document is a durable record for the next CTO: it distinguishes what was proven from what was not proven and prevents historical false-positive certification from being inherited.
