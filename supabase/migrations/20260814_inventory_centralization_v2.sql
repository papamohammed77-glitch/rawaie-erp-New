-- RAWAEA ERP — Inventory Centralization v2
-- Purpose: ensure every physical stock movement routes through post_stock_movement.
-- Reservation/initialization remain separate responsibilities.

-- post_inventory_adjustment_atomic
-- receive_purchase_atomic
-- save_sales_invoice_atomic
-- complete_return_atomic
-- complete_order_delivery_atomic
-- Canonical definitions are maintained in the branch as the forward state applied to staging/production.

-- The exact function bodies are intentionally committed alongside this migration in the same branch.
-- Production definitions MUST match these orchestrators before inventory rescue closeout.
