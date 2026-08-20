# RAWAEA ERP — Forensic Vouchers UI Repair

Date: 2026-08-20

## Source of Truth
- Current Git: `Current/PWA/vouchers.html`
- Production Supabase queried directly.
- Hussin Prompts/Reports 11–29 + Appendix reviewed as historical context only; conflicts were resolved against current Git/Production.

## Confirmed Production Contracts
- Manual Voucher lifecycle RPCs exist:
  - `create_manual_stock_voucher_atomic`
  - `post_manual_stock_voucher_atomic`
  - `send_stock_voucher_atomic`
  - `cancel_manual_stock_voucher_atomic`
  - `complete_manual_stock_voucher_atomic`
- Physical stock mutation remains centralized in `post_stock_movement`.
- `reserve_stock` remains a reservation engine, not a physical movement writer.
- `items.item_code` is globally UNIQUE; item identity is carried by `item_id`.
- `stock_vouchers` has no representative/sales-rep field; no fake representative persistence was introduced.

## Defects Found In Current UI
1. Pending list omitted `Received` state.
2. Draft cards lacked Cancel action.
3. Received cards lacked Complete action.
4. Receive UI was restricted to Transfer in the prior source path.
5. Receive operation identity was deterministic per voucher, risking legitimate subsequent partial receives sharing one operation id.
6. Branch/vehicle/supplier selectors were native `<select>` controls without smart search by code/name.
7. Product catalog stock query was not limited to company branches.
8. Product search/ranking was basic and not normalization-aware.
9. Category highlight was not tied to the active category.
10. Main/workspace scrolling lacked stronger min-height/overscroll boundaries.

## Implemented Changes
- Restored lifecycle controls: SEND / CANCEL / RECEIVE / COMPLETE.
- Pending list now includes `Draft`, `Sent`, `Received`.
- Completed list now contains `Completed`, `Cancelled`.
- Added stable per-receive interaction operation id using `crypto.randomUUID()` with retry retention until success.
- Replaced branch/vehicle/supplier selects with Smart Picker search by code and name.
- Added normalized Arabic/Latin search ranking for products and route entities.
- Scoped `stock_branches` reads to known company branch ids.
- Added active category visual state.
- Hardened scroll containers with `min-height:0`, `overscroll-contain`, and mobile scrolling support.
- Removed redundant voucher header query in details view.
- No direct `stock_branches` or `inventory_log` writes were introduced into the UI.

## Representative Field
Production `stock_vouchers` does not contain a representative/sales-rep field. The UI therefore does not invent or fake persistence for a representative selector.

## Git
- `Current/PWA/vouchers.html` updated in commit `65b3b30f219664f13ce78b0153b06df08d3d936f`.
- Temporary one-shot workflow used during execution was removed in commit `86ab82bb63a332d1d782f8b8af6ca851f6ddcb60`.

## Verification
- Current file re-fetched from Git after write; content SHA verified as `2c25855c46177da6208d9585cf2b9a65cb4d1039`.
- Production RPC existence verified directly.
- Production writer scan found `post_stock_movement` as the Physical Stock + inventory_log writer; `setup_van_stock` is a setup initializer, not a movement engine.
- Browser-level interactive E2E/console verification was not available in the current tool environment and is therefore not claimed as completed.
