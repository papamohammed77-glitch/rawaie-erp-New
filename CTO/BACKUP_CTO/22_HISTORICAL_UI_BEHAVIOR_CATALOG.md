# 22 — HISTORICAL UI BEHAVIOR CATALOG

## Status
Historical reconstruction record. No Production implication.

## Authority
- Current authority: `rawaie-erp-New`
- Historical source: `rawaie-erp-review`
- Production evidence outranks both when available.
- Historical UI behavior is not deployment evidence.

## Evidence inspected
- `PWA/warehouse/vouchers.html`
- `PWA/warehouse/picker.html`
- `PWA/warehouse/returns.html`
- `PWA/sales/van-sales.html`
- `docs/11_BUSINESS_WORKFLOWS.md`
- `docs/18_MODULE_RESPONSIBILITY_MATRIX.md`
- `docs/19_KNOWN_ISSUES_AND_DEBT.md`

## 1. vouchers.html — ORIGINAL BEHAVIOR

### Identity / Access
- Dedicated warehouse voucher application.
- Login through shared `RW_Auth`/`RW_UI` layer.
- Active warehouse role must be `أذونات` unless owner.

### Screens
- Pending vouchers: Draft/Sent.
- Completed vouchers: Received/Completed.
- Account tab.
- New voucher action.
- Search/filter.
- Voucher detail view.

### Status behavior observed
- Draft → Send action.
- Sent → Receive action.
- Received/Completed shown in completed list.
- Voucher details are loaded from `stock_voucher_details`.

### Backend consumers observed
- `send-stock-voucher`
- `receive-stock-voucher`

### Historical implementation characteristic
The original application performs direct PostgREST reads of `stock_vouchers` and `stock_voucher_details`, while business transitions are delegated to Edge Functions.

### Historical classification
`HISTORICAL BEHAVIOR`

### Current parity status
`UNKNOWN` — behavioral parity must be established by a complete Original/Current/Production feature matrix before declaring preservation.

---

## 2. picker.html — ORIGINAL BEHAVIOR

### Identity / Access
- Warehouse permission required.
- Active warehouse role must be `تحضير` unless owner.

### Local behavior
- Dedicated Dexie database `RW_Picker`.
- Local stores include runsheets, details and session.
- Historical local image cache `ITEMS_IMAGE_CACHE`.

### Screens / controls
- Pending preparation.
- Completed preparation.
- Account.
- Search/dropdown behavior.
- Runsheet cards.
- Preparation quantity entry.
- Completion/cancel/reopen paths are represented in the application workflow.

### Dependencies
- `supabase-js`
- Dexie
- SweetAlert2
- direct Supabase access

### Important historical architecture fact
The original picker predates full `core.js` consolidation and was explicitly recorded as a migration-tier exception in the historical responsibility matrix.

### Classification
`HISTORICAL BEHAVIOR`

### Current parity
`CONFLICT / UNKNOWN` until the current picker and deployed consumer are compared behaviorally.

---

## 3. returns.html — ORIGINAL BEHAVIOR

### Identity / Access
- Warehouse permission required.
- Active role must be `مرتجعات` unless owner.

### Screens
- Pending returns.
- Completed returns.
- Account.

### Data dependencies
- `runsheets`
- `run_sheet_details`
- `users`
- `items`
- `return_reasons`

### Return semantics represented in UI
- Active runsheets in `Returning` assigned to the return handler.
- Available delivered runsheets are also presented for return processing.
- Remaining loaded/delivered quantities are calculated for return work.
- Return condition categories include good/damaged/missing.
- Return reasons are loaded from `return_reasons`.

### Local/offline characteristics
- Dexie `RW_Returns`.
- Local changes queue.
- Session metadata.

### Classification
`HISTORICAL BEHAVIOR`

### Current parity
`UNKNOWN`.

---

## 4. van-sales.html — ORIGINAL BEHAVIOR

### Identity / Access
- Owner or `van-sales` / `orders` permission.

### Core user experience
- Vehicle/mobile-sales home.
- Vehicle view.
- Map view.
- Account view.
- Synchronization control.
- Customer/product cart.
- Floating cart.
- Order review modal.
- Direct order submission.

### Local/offline behavior
- Uses `RW_DB`/Dexie for customers, items, stock and branches.
- Synchronizes master data down from Supabase.
- Connection status is visible.
- Designed for field operation.

### Business significance
The original UI treats the van as a mobile operating context with local stock/customer data. It does not by itself establish the final Production custody contract.

### Classification
`HISTORICAL BEHAVIOR`

### Current parity
`CONFLICT / UNKNOWN` until all vehicle/custody behavior and deployed consumers are reconciled.

---

## Feature Parity Matrix

| Application | Historical behavior | Current equivalent | Production evidence | Status |
|---|---|---|---|---|
| vouchers.html | Draft/Sent/Received/Completed voucher workflow | Current voucher UI/Edge path | TASK-018..027 evidence for selected flows | CONFLICT/UNKNOWN |
| picker.html | Runsheet preparation + local cache/session | Current picker | Not fully mapped | UNKNOWN |
| returns.html | Return workflow with condition/reason handling | Current returns | Not fully mapped | UNKNOWN |
| van-sales.html | Mobile stock/customer/cart/order workflow | Current van-sales | Custody slice partially evidenced | CONFLICT |

## Gold behavior rule
Visual similarity is not parity. `PRESERVED` requires behavioral equivalence in controls, validation, transitions, API/RPC consumers, side effects and error handling.
