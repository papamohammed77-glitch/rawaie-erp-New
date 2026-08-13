# TASK-027 — CLOSEOUT
## Runtime Gold Gate — Manual Voucher / DirectSale / VAN Custody

Status: **CLOSED / GO**

## 1. Production baseline used

Company:
`da4ef704-88ac-4120-aa0e-65b92b2aa2bc`

MAIN branch:
`151e5cd7-ac4a-4fc3-b703-d73a0dbb0dc6`

Vehicle:
`VEH-92yrzb`

Vehicle ID:
`70e5d809-0505-4e60-b317-feff6e799127`

Mobile branch:
`VAN-VEH-92yrzb`

Mobile branch ID:
`dbdef0b7-0909-4f71-a367-30c61d021286`

Representative:
`van-sales@rawaea.com`

Driver ID:
`a86726d9-d687-4113-a9e2-5f90f4bdb4fa`

## 2. Owner contract

Vehicle is the mobile stock container.
Representative is the accountable custodian and financial-responsibility holder.
Vehicle identity is independent from representative identity.

DirectSale:
`MAIN -> VAN(vehicle)`

DirectReturn:
`VAN(vehicle) -> MAIN`

SupplierReturn:
`MAIN/Branch -> Supplier`

## 3. Permanent Production defects corrected

### 3.1 `setup_van_stock`
Original defect: attempted to insert into generated `available_qty`.

Permanent correction:
- insert `qty` and `allocated_qty` only;
- allow PostgreSQL to generate `available_qty`.

Production evidence after correction:
`MISSING_FROM_VAN = 0`

### 3.2 `post_stock_movement`
Original defect: `DirectSale` was effectively source-only.

Permanent correction:
- source stock decreases;
- target stock increases;
- source and target are locked atomically;
- one movement log is written for the business movement.

### 3.3 `send_manual_stock_voucher_v2`
Original defect: target was not passed to the central engine.

Permanent correction:
- `Transfer` and `DirectSale` pass `voucher.to_id` as target branch;
- `SupplierReturn` remains source-only.

## 4. Runtime evidence

Central engine test:
`TASK-027 — CENTRAL DIRECTSALE ENGINE PASS`

Voucher end-to-end test:
`TASK-027 — VOUCHER E2E PASS`

Successful path:

`CREATE`
`-> DirectSale`
`-> SEND`
`-> MAIN -1`
`-> VAN +1`
`-> inventory_log = 1`
`-> Sent`
`-> Complete`
`-> Completed`

## 5. Test-data hygiene

The E2E test data was rolled back.
Permanent RPC corrections were committed separately and were not rolled back with the test data.

## 6. Important lesson

Never place a permanent Production function correction in the same transaction that is intentionally rolled back for test data. A later failure would erase the correction and create the illusion that the defect had been fixed.

## 7. Application gate status

This task closes the **Production business/RPC runtime gate** for DirectSale.
It does not authorize final publication of the application UI unless the UI feature-parity and application-release gate is separately closed.

## 8. Next phase

**STAGE-28 — Loading / Unloading Core**

Next CTO must start from:
`CTO/00_MASTER_CONTEXT.md`
`CTO/TASKS/00_CTO_PROJECT_EXECUTION_LEDGER.md`
`CTO/TASKS/00_SOURCE_MIGRATION_NOTICE.md`

Do not repeat closed Discovery or DirectSale engine diagnostics unless fresh Production evidence contradicts this closeout.
