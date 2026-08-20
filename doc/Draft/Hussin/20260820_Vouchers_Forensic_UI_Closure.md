# RAWAEA ERP — Vouchers Forensic UI Closure — 2026-08-20

## Scope
Current `Current/PWA/vouchers.html` and its runtime capability layer were reviewed from GitHub and Production sources after Hussin prompts 11–37 plus Appendix 29.

## Confirmed current contracts

- `stock_vouchers` remains the manual-voucher state machine; no Representative column was invented.
- DirectSale is `Branch -> Vehicle`.
- The authoritative vehicle-to-representative relationship is `vehicles.driver_id -> users.id`.
- The active Direct Sales representative set is loaded from `users` using the current Production role contract `role='مندوب بيع مباشر'` and `status='Active'`, scoped by `company_id`.
- Vehicle selection for DirectSale is filtered by the selected representative's `users.id`, matched to `vehicles.driver_id`.
- The server RPC remains authoritative for stock movement and validates company/vehicle/VAN-branch context.
- Supplier lookup remains company-scoped; supplier search was hardened to support code/name/phone.
- `vouchers.html` performs no direct `stock_branches.qty` mutation and no direct `inventory_log` write.
- No `LIMIT 1` lookup was found in the current `vouchers.html` source path.

## Production evidence

### Active Direct Sales Representatives

Company `00000000-0000-0000-0000-000000000001`:
- `111b0730-a977-4d11-bcd0-2427b178a9e5` — مندوب مبيعات بيع مباشر — vansales@rawaea.com

Company `da4ef704-88ac-4120-aa0e-65b92b2aa2bc`:
- `a86726d9-d687-4113-a9e2-5f90f4bdb4fa` — مندوب بيع مباشر — van-sales@rawaea.com

### Current Production Vehicle Relationship

- Vehicle `70e5d809-0505-4e60-b317-feff6e799127` / `VEH-92yrzb`
- Company `da4ef704-88ac-4120-aa0e-65b92b2aa2bc`
- `driver_id = a86726d9-d687-4113-a9e2-5f90f4bdb4fa`
- Status `Active`

### Production smoke test

A real-schema transactional DirectSale was created and sent:

`create_manual_stock_voucher_atomic`
-> `send_stock_voucher_atomic`
-> `post_stock_movement`

Result:

- success = true
- duplicate = false
- movement_count = 1
- voucher status = Completed
- transaction rolled back after verification

No permanent fixture was left in Production.

## Code change

Commit:
`0ed3abae2379a312c0e45a7b79ff67dc1be8908e`

File:
`Current/PWA/vouchers-gold-master-ui.js`

Change:
- Added DirectSale Representative-first workflow.
- Vehicle list is constrained to the selected representative.
- Submission refuses missing representative, missing vehicle, or mismatched representative/vehicle identity.
- Added active representative reference hydration.
- Hardened supplier lookup/search.
- No stock mutation or inventory-log writer was added.

## Important non-changes

- No new Representative column was added to `stock_vouchers`.
- No change was made to the canonical stock engine.
- The historical "target stock row missing" Transfer defect was reproduced against the current Production core and is already closed by the current RPC implementation; it was not re-patched.

## Closure status

Vouchers UI DirectSale representative/vehicle selection: CLOSED in source.

Production stock-engine contract: VERIFIED.

Browser-level interactive visual verification: not available in this execution environment; the deployed source and its Production RPC contract were verified directly.
