BEGIN;

DO $$
DECLARE
  v_id uuid := '78612239-6028-4192-bae8-7750d8b575cb';
  b_id uuid := '62397742-f502-47c6-bae2-95dca72141b3';
  v_company uuid := '00000000-0000-0000-0000-000000000001';
  v_refs integer;
  b_refs integer;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.vehicles
    WHERE id=v_id
      AND company_id=v_company
      AND vehicle_code='FRD-2025-02 TEST'
      AND mobile_branch_id=b_id
  ) THEN
    RAISE EXCEPTION 'Expected QA vehicle fixture was not found exactly';
  END IF;

  SELECT count(*) INTO v_refs
  FROM (
    SELECT 1 FROM public.daily_settlements WHERE vehicle_id=v_id
    UNION ALL SELECT 1 FROM public.fleet_driver_performance_events WHERE vehicle_id=v_id
    UNION ALL SELECT 1 FROM public.fleet_expenses WHERE vehicle_id=v_id
    UNION ALL SELECT 1 FROM public.fleet_fuel_transactions WHERE vehicle_id=v_id
    UNION ALL SELECT 1 FROM public.fleet_incidents WHERE vehicle_id=v_id
    UNION ALL SELECT 1 FROM public.fleet_maintenance_plans WHERE vehicle_id=v_id
    UNION ALL SELECT 1 FROM public.fleet_vehicle_assignments WHERE vehicle_id=v_id
    UNION ALL SELECT 1 FROM public.fleet_vehicle_contracts WHERE vehicle_id=v_id
    UNION ALL SELECT 1 FROM public.fleet_vehicle_sales_rep_assignments WHERE vehicle_id=v_id
    UNION ALL SELECT 1 FROM public.runsheets WHERE vehicle_id=v_id
    UNION ALL SELECT 1 FROM public.stock_vouchers WHERE vehicle_id=v_id
    UNION ALL SELECT 1 FROM public.vehicle_documents WHERE vehicle_id=v_id
    UNION ALL SELECT 1 FROM public.vehicle_maintenance WHERE vehicle_id=v_id
  ) q;
  IF v_refs<>0 THEN
    RAISE EXCEPTION 'QA vehicle has unexpected operational references: %',v_refs;
  END IF;

  SELECT count(*) INTO b_refs
  FROM (
    SELECT 1 FROM public.finance_expenses WHERE branch_id=b_id
    UNION ALL SELECT 1 FROM public.finance_revenues WHERE branch_id=b_id
    UNION ALL SELECT 1 FROM public.hr_employee_assignments WHERE branch_id=b_id
    UNION ALL SELECT 1 FROM public.inventory_count_details WHERE branch_id=b_id
    UNION ALL SELECT 1 FROM public.inventory_counts WHERE branch_id=b_id
    UNION ALL SELECT 1 FROM public.inventory_log WHERE source_branch_id=b_id
    UNION ALL SELECT 1 FROM public.inventory_log WHERE target_branch_id=b_id
    UNION ALL SELECT 1 FROM public.inventory_stock_requests WHERE source_branch_id=b_id
    UNION ALL SELECT 1 FROM public.inventory_stock_requests WHERE target_branch_id=b_id
    UNION ALL SELECT 1 FROM public.orders WHERE branch_id=b_id
    UNION ALL SELECT 1 FROM public.promotion_branches WHERE branch_id=b_id
    UNION ALL SELECT 1 FROM public.purchase_invoices WHERE branch_id=b_id
    UNION ALL SELECT 1 FROM public.purchase_orders WHERE branch_id=b_id
    UNION ALL SELECT 1 FROM public.purchase_returns WHERE branch_id=b_id
    UNION ALL SELECT 1 FROM public.purchase_settings WHERE default_branch_id=b_id
    UNION ALL SELECT 1 FROM public.sales_quotes WHERE branch_id=b_id
    UNION ALL SELECT 1 FROM public.sales_target_assignments WHERE branch_id=b_id
    UNION ALL SELECT 1 FROM public.sales_target_run_lines WHERE branch_id=b_id
    UNION ALL SELECT 1 FROM public.stock_vouchers WHERE from_branch_id=b_id
    UNION ALL SELECT 1 FROM public.stock_vouchers WHERE to_branch_id=b_id
    UNION ALL SELECT 1 FROM public.users WHERE default_branch_id=b_id
  ) q;
  IF b_refs<>0 THEN
    RAISE EXCEPTION 'QA branch has unexpected operational references: %',b_refs;
  END IF;

  DELETE FROM public.vehicle_status_history WHERE vehicle_id=v_id;
  DELETE FROM public.stock_branches WHERE branch_id=b_id;
  DELETE FROM public.vehicles WHERE id=v_id AND company_id=v_company;
  DELETE FROM public.branches WHERE id=b_id AND company_id=v_company;

  DELETE FROM public.audit_log
   WHERE record_id IN (v_id::text,b_id::text)
      OR old_data->>'vehicle_code'='FRD-2025-02 TEST'
      OR new_data->>'vehicle_code'='FRD-2025-02 TEST'
      OR old_data->>'branch_code'='VAN-FRD-2025-02 TEST'
      OR new_data->>'branch_code'='VAN-FRD-2025-02 TEST';
END $$;

COMMIT;