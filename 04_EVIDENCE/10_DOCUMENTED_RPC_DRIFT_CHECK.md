# Documented RPC Column Drift Check

**Latest captured result:** `Success. No rows returned`

This file preserves the exact result of the diagnostic query captured on the rescue branch.

It does NOT override the separate confirmed Production evidence showing that `complete_manual_stock_voucher_atomic` attempts to write `stock_vouchers.completed_by` while the captured Production schema lacks that column.
