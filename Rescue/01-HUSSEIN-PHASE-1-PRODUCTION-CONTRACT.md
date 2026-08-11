# Hussein — Phase 1 Production Contract

**Source:** `rawaie-erp-review` / `rescue/manual-vouchers-inventory-core`
**Classification:** CURRENT RESCUE ANALYSIS — not Production schema itself.

## Confirmed by the report
- Production `stock_vouchers` lacks proven `completed_by`.
- Deployed COMPLETE writes `completed_by`.
- Deployed POST is SECURITY DEFINER and is service-role executable in the captured privilege evidence.
- SEND: Draft → Sent; Transfer/DirectSale/SupplierReturn; OUT from source.
- RECEIVE: Sent → Sent/Received; Transfer/DirectReturn; IN to destination; partial receipt supported.
- Voucher/stock rows use `FOR UPDATE` in the reviewed atomic path.
- OUT checks `qty - allocated_qty`.
- Movement writes `inventory_log`.
- RECEIVE updates `received_qty`.

## Unresolved
- completed_by target/audit contract.
- DirectSale target custody semantics.
- DirectReturn target custody semantics.
- Complete deployed CANCEL definition.
- Full production schema across every object referenced by all manual-voucher RPCs.
- Complete audit effects for COMPLETE/CANCEL.

## CTO gate
NO GO until reconciliation is closed.

## Important
This report is not authorization to execute SQL. It explicitly states that no patch was authorized by the report.