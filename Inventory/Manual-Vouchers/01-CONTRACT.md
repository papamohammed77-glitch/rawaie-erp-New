# Manual Stock Voucher Contract — Evidence Baseline

## Captured Production schema
`stock_vouchers` proven fields include:
`id, company_id, voucher_code, voucher_date, type, status, from_branch_id, to_branch_id, from_type, from_id, to_type, to_id, reference, notes, created_by, sent_date, received_date, completed_at, created_at, updated_at, source`.

`completed_by` is NOT present in the captured Production schema.

`stock_voucher_details` proven fields include:
`id, voucher_id, item_id, item_code, item_name, unit, qty, unit_price, received_qty, notes, created_at`.

`stock_branches` proven fields include:
`id, branch_id, item_id, qty, allocated_qty, available_qty, updated_at`.

`inventory_log` proven fields include:
`id, company_id, log_code, movement_date, voucher_id, item_id, item_code, item_name, movement_type, qty, reference, user_email, created_at`.

## Captured lifecycle
CREATE → Draft
SEND → Sent
RECEIVE → Sent for partial / Received when all detail quantities are received
COMPLETE → Completed
CANCEL → not fully proven in persisted Production evidence

## Captured movement contract
SEND:
- Transfer → OUT source
- DirectSale → OUT source in the captured current path
- SupplierReturn → OUT source

RECEIVE:
- Transfer → IN destination
- DirectReturn → IN destination in the captured current path

## Safety properties already present in the reviewed atomic path
- voucher row locking with `FOR UPDATE`;
- stock row locking with `FOR UPDATE`;
- OUT availability based on `qty - allocated_qty`;
- CAS-style update predicates;
- inventory log insertion for actual movement;
- cumulative `received_qty` for RECEIVE;
- remaining-quantity protection.

## Unresolved contracts
1. completion actor/audit storage;
2. DirectSale custody target;
3. DirectReturn custody target;
4. deployed CANCEL definition;
5. complete production schema for all RPC dependencies;
6. full audit path;
7. independent idempotency identity for partial RECEIVE.

**Rule:** unresolved contracts cannot be silently decided by an implementer.