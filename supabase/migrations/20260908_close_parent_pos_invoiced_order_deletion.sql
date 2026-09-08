BEGIN;

CREATE OR REPLACE FUNCTION public.delete_order_atomic(
  p_company_id uuid,
  p_order_code text,
  p_user_email text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public','pg_temp'
AS $function$
DECLARE
  v_order public.orders%ROWTYPE;
  v_actor public.users%ROWTYPE;
  v_permissions jsonb := '[]'::jsonb;
  v_role_permissions jsonb := '[]'::jsonb;
  v_role_exists boolean := false;
  v_is_privileged boolean := false;
  v_branch_id uuid;
  v_detail record;
  v_original_entry public.journal_entries%ROWTYPE;
  v_original_lines jsonb := '[]'::jsonb;
  v_customer_debit numeric := 0;
  v_driver_row public.driver_ledger%ROWTYPE;
  v_result jsonb;
BEGIN
  IF p_company_id IS NULL THEN RAISE EXCEPTION 'DELETE_ORDER_COMPANY_REQUIRED'; END IF;
  IF NULLIF(btrim(p_order_code),'') IS NULL THEN RAISE EXCEPTION 'DELETE_ORDER_CODE_REQUIRED'; END IF;
  IF NULLIF(btrim(p_user_email),'') IS NULL THEN RAISE EXCEPTION 'DELETE_ORDER_ACTOR_REQUIRED'; END IF;

  SELECT * INTO v_actor
  FROM public.users
  WHERE lower(email)=lower(p_user_email)
    AND company_id=p_company_id
    AND coalesce(status,'Active')='Active'
  LIMIT 1;
  IF NOT FOUND THEN RAISE EXCEPTION 'DELETE_ORDER_ACTOR_NOT_FOUND_OR_WRONG_COMPANY'; END IF;

  v_permissions := coalesce(v_actor.permissions,'[]'::jsonb);
  SELECT coalesce(r.permissions,'[]'::jsonb),true
    INTO v_role_permissions,v_role_exists
  FROM public.roles r
  WHERE r.id=v_actor.role_id
    AND r.company_id=p_company_id;

  IF v_role_exists THEN
    v_permissions := v_permissions || coalesce(v_role_permissions,'[]'::jsonb);
    SELECT coalesce(jsonb_agg(rp.permission_key),'[]'::jsonb)
      INTO v_role_permissions
    FROM public.role_permissions rp
    WHERE rp.role_id=v_actor.role_id;
    v_permissions := v_permissions || coalesce(v_role_permissions,'[]'::jsonb);
  END IF;

  v_is_privileged :=
    v_permissions @> '["*"]'::jsonb
    OR v_permissions @> '["general_manager"]'::jsonb
    OR v_permissions @> '["sales_manager"]'::jsonb
    OR v_permissions @> '["sales_supervisor"]'::jsonb;

  SELECT * INTO v_order
  FROM public.orders
  WHERE company_id=p_company_id
    AND order_code=p_order_code
  FOR UPDATE;

  IF NOT FOUND THEN
    IF EXISTS (
      SELECT 1 FROM public.erp_operation_registry
      WHERE company_id=p_company_id
        AND operation_type='delete_order'
        AND operation_key=p_order_code
        AND status='completed'
        AND response_payload IS NOT NULL
    ) THEN
      RETURN (
        SELECT response_payload
        FROM public.erp_operation_registry
        WHERE company_id=p_company_id
          AND operation_type='delete_order'
          AND operation_key=p_order_code
          AND status='completed'
        ORDER BY completed_at DESC
        LIMIT 1
      ) || jsonb_build_object('duplicate',true);
    END IF;
    RAISE EXCEPTION 'الأوردر غير موجود';
  END IF;

  IF v_order.runsheet_id IS NOT NULL THEN RAISE EXCEPTION 'لا يمكن حذف أوردر مربوط برانشيت'; END IF;
  IF v_order.order_status IN ('Returned','Partially Returned','Cancelled') THEN
    RAISE EXCEPTION 'لا يمكن حذف الأوردر في حالته الحالية';
  END IF;

  IF v_order.order_status='Invoiced' THEN
    IF lower(coalesce(v_order.source,'')) <> 'pos' THEN
      RAISE EXCEPTION 'حذف فاتورة Invoiced مسموح فقط لفواتير POS المنشأة من تطبيق الكاشير';
    END IF;
    IF NOT v_is_privileged THEN
      RAISE EXCEPTION 'لا تملك صلاحية حذف فاتورة POS منفذة';
    END IF;

    v_branch_id := v_order.branch_id;
    IF v_branch_id IS NULL THEN
      SELECT a.main_branch_id INTO v_branch_id
      FROM public.app_settings a
      WHERE a.company_id=p_company_id
      ORDER BY a.created_at ASC,a.id
      LIMIT 1;
    END IF;
    IF v_branch_id IS NULL OR NOT EXISTS (
      SELECT 1 FROM public.branches b
      WHERE b.id=v_branch_id AND b.company_id=p_company_id
    ) THEN
      RAISE EXCEPTION 'فرع الفاتورة غير صالح';
    END IF;

    FOR v_detail IN
      SELECT d.item_id,d.item_code,d.qty
      FROM public.order_details d
      WHERE d.order_id=v_order.id
      ORDER BY d.item_id
    LOOP
      IF coalesce(v_detail.qty,0)<=0 THEN CONTINUE; END IF;
      IF v_detail.item_id IS NULL THEN
        RAISE EXCEPTION 'هوية الصنف مفقودة في الفاتورة: %',v_detail.item_code;
      END IF;
      PERFORM public.post_stock_movement(
        p_company_id,'InventoryIncrease',NULL,v_branch_id,v_detail.item_id,v_detail.qty,
        v_order.order_code,'VOID-'||v_order.order_code,p_user_email,
        'VoidInvoice:'||p_company_id::text||':'||v_order.id::text||':'||v_detail.item_id::text
      );
    END LOOP;

    SELECT * INTO v_original_entry
    FROM public.journal_entries
    WHERE company_id=p_company_id
      AND reference=v_order.order_code
      AND entry_type IN ('POS_Sale','VanSales')
      AND status='Posted'
    ORDER BY created_at DESC,id DESC
    LIMIT 1;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'القيد الأصلي للفاتورة غير موجود؛ تم إيقاف الحذف للحفاظ على سلامة المحاسبة';
    END IF;

    SELECT coalesce(jsonb_agg(jsonb_build_object(
      'account_id',jl.account_id,
      'account_name',jl.account_name,
      'debit',coalesce(jl.credit,0),
      'credit',coalesce(jl.debit,0),
      'notes','عكس حذف الفاتورة '||v_order.order_code,
      'cost_center_id',jl.cost_center_id
    ) ORDER BY jl.id),'[]'::jsonb)
    INTO v_original_lines
    FROM public.journal_lines jl
    WHERE jl.entry_id=v_original_entry.id;

    PERFORM public.post_journal_entry(
      p_company_id,v_order.id,current_date,'VoidInvoice','VOID-'||v_order.order_code,
      'عكس حذف فاتورة POS – '||v_order.order_code,p_user_email,v_original_lines,
      'JE-VOID-'||replace(gen_random_uuid()::text,'-',''),now(),NULL
    );

    IF v_order.customer_id IS NOT NULL THEN
      SELECT coalesce(cl.debit,0) INTO v_customer_debit
      FROM public.customer_ledger cl
      WHERE cl.customer_id=v_order.customer_id
        AND cl.reference=v_order.order_code
      ORDER BY cl.created_at DESC,cl.id DESC
      LIMIT 1;
      IF v_customer_debit>0 THEN
        PERFORM public.post_customer_ledger_entry(
          p_company_id,v_order.id,v_order.customer_id,current_date,'VOID-'||v_order.order_code,
          'عكس حذف فاتورة POS – '||v_order.order_code,0,v_customer_debit,current_date,p_user_email
        );
      END IF;
    END IF;

    SELECT dl.* INTO v_driver_row
    FROM public.driver_ledger dl
    WHERE dl.reference=v_order.order_code
      AND dl.debit>0
    ORDER BY dl.created_at DESC,dl.id DESC
    LIMIT 1;
    IF FOUND THEN
      PERFORM public.post_driver_ledger_entry(
        p_company_id,v_order.id,v_driver_row.driver_email,current_date,'VOID-'||v_order.order_code,
        'عكس حذف فاتورة POS – '||v_order.order_code,0,coalesce(v_driver_row.debit,0)
      );
    END IF;
  END IF;

  INSERT INTO public.erp_operation_registry(company_id,operation_type,operation_key,request_payload,status)
  VALUES(
    p_company_id,'delete_order',v_order.order_code,
    jsonb_build_object('order_id',v_order.id,'status',v_order.order_status,'source',v_order.source),
    'processing'
  )
  ON CONFLICT(company_id,operation_type,operation_key) DO UPDATE
  SET request_payload=excluded.request_payload,status='processing';

  DELETE FROM public.order_details WHERE order_id=v_order.id;
  DELETE FROM public.orders WHERE id=v_order.id AND company_id=p_company_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'فشل حذف الأوردر'; END IF;

  v_result:=jsonb_build_object(
    'success',true,
    'duplicate',false,
    'order_code',v_order.order_code,
    'deleted_order_id',v_order.id,
    'previous_status',v_order.order_status,
    'reversed_invoiced',v_order.order_status='Invoiced',
    'reversed_customer_ledger',v_customer_debit>0,
    'reversed_driver_ledger',found
  );

  UPDATE public.erp_operation_registry
  SET status='completed',response_payload=v_result,completed_at=now()
  WHERE company_id=p_company_id
    AND operation_type='delete_order'
    AND operation_key=v_order.order_code;

  INSERT INTO public.audit_log(id,user_email,action,table_name,record_id,old_data,new_data,created_at)
  VALUES(gen_random_uuid(),p_user_email,'hard_delete_order','orders',v_order.order_code,to_jsonb(v_order),v_result,now());

  RETURN v_result;
EXCEPTION WHEN others THEN
  UPDATE public.erp_operation_registry
  SET status='failed',response_payload=jsonb_build_object('success',false,'error',sqlerrm),completed_at=now()
  WHERE company_id=p_company_id
    AND operation_type='delete_order'
    AND operation_key=p_order_code
    AND status<>'completed';
  RAISE;
END;
$function$;

COMMENT ON FUNCTION public.delete_order_atomic(uuid,text,text) IS
'Parent-system order deletion capability. Draft/Confirmed/Pending remain supported. Invoiced deletion is restricted to POS-origin invoices and privileged effective permissions (*, general_manager, sales_manager, sales_supervisor). Invoice effects are reversed through canonical stock, journal, customer-ledger and driver-ledger engines before the order is deleted.';

REVOKE ALL ON FUNCTION public.delete_order_atomic(uuid,text,text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.delete_order_atomic(uuid,text,text) TO service_role;

COMMIT;
