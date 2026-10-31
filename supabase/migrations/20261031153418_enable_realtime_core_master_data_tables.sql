-- Reconcile the Production Realtime publication change with the canonical migration history.
-- Applied in SMART ERP Production as migration version 20261031153418.
ALTER PUBLICATION supabase_realtime
ADD TABLE
  public.branches,
  public.customer_ledger,
  public.customers,
  public.daily_settlements,
  public.items,
  public.purchase_order_details,
  public.purchase_orders,
  public.supplier_ledger,
  public.suppliers;
