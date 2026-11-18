-- CS-PRPO-P0-731-A — PROPOSED ONLY; NOT APPLIED TO PRODUCTION

-- Prepared from live Production function definitions on 2026-11-18.

-- Apply only after owner approval and after a complete caller/dependency review.

-- This is a transactional two-sided change: GRN/stock-only receiving + Finance invoice AP posting.



CREATE OR REPLACE FUNCTION public.receive_purchase_atomic(p_company_id uuid, p_po_code text, p_user_email text, p_items jsonb, p_operation_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  po public.purchase_orders%ROWTYPE;
  e record;
  pd public.purchase_order_details%ROWTYPE;
  item_master public.items%ROWTYPE;
  main_branch uuid;
  receiving_branch uuid;
  op text;
  existing public.receiving%ROWTYPE;
  total_value numeric:=0;
  total_received_qty numeric:=0;
  all_received boolean:=true;
  requested_fp text;
  existing_fp text;
  actor public.users%ROWTYPE;
  actor_permissions jsonb := '[]'::jsonb;
  actor_is_owner boolean := false;
  receiving_branch_code text;
  branch_allowed boolean := false;
  allowed_branch_value text;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.companies WHERE id=p_company_id AND COALESCE(is_active,true)) THEN
    RAISE EXCEPTION 'سياق الشركة غير موجود أو غير نشط';
  END IF;
  SELECT u.* INTO actor
  FROM public.users u
  WHERE u.company_id = p_company_id
    AND lower(u.email) = lower(coalesce(p_user_email,''))
    AND coalesce(u.status,'Active') = 'Active'
  FOR SHARE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'المستخدم لا ينتمي إلى الشركة أو غير نشط';
  END IF;

  SELECT coalesce(jsonb_agg(DISTINCT source.permission), '[]'::jsonb)
    INTO actor_permissions
  FROM (
    SELECT jsonb_array_elements_text(
      CASE WHEN jsonb_typeof(actor.permissions) = 'array'
        THEN actor.permissions ELSE '[]'::jsonb END
    ) AS permission
    UNION ALL
    SELECT jsonb_array_elements_text(
      CASE WHEN jsonb_typeof(r.permissions) = 'array'
        THEN r.permissions ELSE '[]'::jsonb END
    ) AS permission
    FROM public.roles r
    WHERE r.id = actor.role_id
      AND r.company_id = p_company_id
    UNION ALL
    SELECT rp.permission_key
    FROM public.role_permissions rp
    WHERE rp.role_id = actor.role_id
  ) source
  WHERE nullif(btrim(source.permission), '') IS NOT NULL;

  SELECT EXISTS (
    SELECT 1
    FROM auth.users au
    JOIN public.owner_profile op ON op.auth_user_id = au.id
    WHERE au.id = actor.auth_id
      AND coalesce(au.raw_user_meta_data->>'isOwner', 'false') = 'true'
      AND jsonb_typeof(actor.permissions) = 'array'
      AND actor.permissions ? '*'
  ) INTO actor_is_owner;

  -- RECEIVE_PERMISSION_GUARD:
  -- Receiver UI allows only Owner or the active warehouse role "استلام".
  IF NOT actor_is_owner
     AND NOT (
       (
         actor.active_warehouse_role = 'استلام'
         AND (
           actor_permissions ? '*'
           OR actor_permissions ? 'warehouse'
           OR actor_permissions ? 'receiving'
         )
       )
       OR (
         actor.active_warehouse_role = 'مخزن شامل'
         AND (actor_permissions ? '*' OR actor_permissions ? 'warehouse')
       )
     ) THEN
    RAISE EXCEPTION 'لا تملك صلاحية استلام أوامر الشراء';
  END IF;
  IF p_operation_id IS NULL THEN RAISE EXCEPTION 'operation_id مطلوب لاستلام الشراء'; END IF;
  IF p_items IS NULL OR jsonb_typeof(p_items)<>'array' OR jsonb_array_length(p_items)=0 THEN RAISE EXCEPTION 'لا توجد أصناف للاستلام'; END IF;

  SELECT * INTO po FROM public.purchase_orders WHERE company_id=p_company_id AND po_code=p_po_code FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'أمر الشراء غير موجود'; END IF;

  op:='PO-RECEIVE:'||p_company_id::text||':'||po.id::text||':'||p_operation_id::text;
  SELECT md5(coalesce(string_agg(
      btrim(x.item_code)||':'||COALESCE(x.sent_qty,x.received_qty,0)::numeric(30,4)::text||':'||
      COALESCE(x.received_qty,0)::numeric(30,4)::text||':'||COALESCE(NULLIF(btrim(x.reason),''),''),
      '|' ORDER BY btrim(x.item_code)
    ),''))
    INTO requested_fp
  FROM jsonb_to_recordset(p_items)
    x(item_code text,sent_qty numeric,received_qty numeric,item_name text,unit text,reason text)
  WHERE COALESCE(x.sent_qty,x.received_qty,0)>0;

  SELECT * INTO existing FROM public.receiving WHERE company_id=p_company_id AND operation_id=op FOR UPDATE;
  IF FOUND THEN
    SELECT md5(coalesce(string_agg(
        btrim(rd.item_code)||':'||COALESCE(rd.qty_expected,0)::numeric(30,4)::text||':'||
        COALESCE(rd.qty_received,0)::numeric(30,4)::text||':'||COALESCE(NULLIF(btrim(rd.reason),''),''),
        '|' ORDER BY btrim(rd.item_code)
      ),''))
      INTO existing_fp
    FROM public.receiving_details rd WHERE rd.operation_id=op;
    IF coalesce(existing_fp,'') IS DISTINCT FROM coalesce(requested_fp,'') THEN
      RAISE EXCEPTION 'idempotency key conflict: نفس operation_id استُخدم مع استلام مختلف';
    END IF;
    RETURN jsonb_build_object('success',true,'duplicate',true,'operation_id',p_operation_id,'po_code',p_po_code,'status',(SELECT status FROM public.purchase_orders WHERE id=po.id));
  END IF;

  SELECT main_branch_id INTO STRICT main_branch FROM public.app_settings WHERE company_id=p_company_id ORDER BY created_at ASC,id LIMIT 1;
  receiving_branch:=coalesce(po.branch_id,main_branch);
  SELECT b.branch_code INTO receiving_branch_code
  FROM public.branches b
  WHERE b.id = receiving_branch
    AND b.company_id = p_company_id
    AND coalesce(b.is_active,true);

  IF NOT FOUND THEN
    RAISE EXCEPTION 'فرع الاستلام غير صالح للشركة';
  END IF;

  -- RECEIVE_BRANCH_SCOPE_GUARD:
  -- allowed_branch_ids may be an array of UUIDs/codes or a legacy scalar branch code.
  IF NOT actor_is_owner THEN
    branch_allowed := actor.default_branch_id = receiving_branch;

    IF jsonb_typeof(actor.allowed_branch_ids) = 'array' THEN
      branch_allowed := branch_allowed
        OR actor.allowed_branch_ids ? '*'
        OR actor.allowed_branch_ids ? receiving_branch::text
        OR actor.allowed_branch_ids ? coalesce(receiving_branch_code,'');
    ELSIF jsonb_typeof(actor.allowed_branch_ids) = 'string' THEN
      allowed_branch_value := actor.allowed_branch_ids #>> '{}';
      branch_allowed := branch_allowed
        OR allowed_branch_value IN ('*', receiving_branch::text, receiving_branch_code);
    END IF;

    IF NOT branch_allowed THEN
      RAISE EXCEPTION 'لا تملك صلاحية الاستلام في فرع أمر الشراء';
    END IF;
  END IF;
  IF EXISTS (SELECT 1 FROM jsonb_to_recordset(p_items) AS x(item_code text,received_qty numeric,item_name text,unit text,reason text) GROUP BY x.item_code HAVING count(*)>1) THEN
    RAISE EXCEPTION 'لا يجوز تكرار الصنف داخل نفس عملية الاستلام';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM jsonb_to_recordset(p_items)
      x(item_code text,sent_qty numeric,received_qty numeric,item_name text,unit text,reason text)
    WHERE COALESCE(x.sent_qty,x.received_qty,0)>0
  ) THEN RAISE EXCEPTION 'يجب تسجيل كمية مرسلة موجبة واحدة على الأقل'; END IF;

  FOR e IN SELECT * FROM jsonb_to_recordset(p_items)
    x(item_code text,sent_qty numeric,received_qty numeric,item_name text,unit text,reason text)
  LOOP
    IF NULLIF(btrim(e.item_code),'') IS NULL
       OR e.received_qty IS NULL
       OR COALESCE(e.sent_qty,e.received_qty) IS NULL
       OR e.received_qty::text IN ('NaN','Infinity','-Infinity')
       OR COALESCE(e.sent_qty,e.received_qty)::text IN ('NaN','Infinity','-Infinity') THEN
      RAISE EXCEPTION 'كود الصنف وكميتا الشحنة والاستلام مطلوبة';
    END IF;
    IF COALESCE(e.sent_qty,e.received_qty)<=0
       OR e.received_qty<0
       OR e.received_qty>COALESCE(e.sent_qty,e.received_qty)
       OR round(COALESCE(e.sent_qty,e.received_qty),4)<>COALESCE(e.sent_qty,e.received_qty)
       OR round(e.received_qty,4)<>e.received_qty THEN
      RAISE EXCEPTION 'كميات الشحنة والاستلام غير صالحة للصنف: %',e.item_code;
    END IF;
    IF e.received_qty<>COALESCE(e.sent_qty,e.received_qty)
       AND NULLIF(btrim(COALESCE(e.reason,'')),'') IS NULL THEN
      RAISE EXCEPTION 'سبب اختلاف الكمية المرسلة والمقبولة مطلوب للصنف: %',e.item_code;
    END IF;
    SELECT * INTO pd FROM public.purchase_order_details d
    WHERE d.po_id=po.id AND d.item_code=e.item_code FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'الصنف غير موجود داخل أمر الشراء: %',e.item_code; END IF;
    SELECT * INTO item_master FROM public.items i
    WHERE i.id=pd.item_id AND i.company_id=p_company_id AND i.item_code=e.item_code;
    IF NOT FOUND THEN RAISE EXCEPTION 'هوية الصنف غير متسقة مع دليل الأصناف: %',e.item_code; END IF;
    IF COALESCE(e.sent_qty,e.received_qty) >
       GREATEST(0,COALESCE(pd.qty_ordered,0)-COALESCE(pd.qty_received,0))+0.0001 THEN
      RAISE EXCEPTION 'الكمية المرسلة تتجاوز المتبقي في أمر الشراء للصنف: %',e.item_code;
    END IF;
  END LOOP;

  INSERT INTO public.receiving(id,operation_id,date,po_number,responsible,start_time,end_time,status,company_id)
  VALUES(gen_random_uuid(),op,current_date,p_po_code,p_user_email,now(),now(),'مكتمل',p_company_id);

  FOR e IN SELECT * FROM jsonb_to_recordset(p_items)
    x(item_code text,sent_qty numeric,received_qty numeric,item_name text,unit text,reason text)
  LOOP
    SELECT * INTO pd FROM public.purchase_order_details d
    WHERE d.po_id=po.id AND d.item_code=e.item_code FOR UPDATE;
    IF COALESCE(e.received_qty,0)>0 THEN
      SELECT * INTO item_master FROM public.items i
      WHERE i.id=pd.item_id AND i.company_id=p_company_id AND i.item_code=e.item_code;
      PERFORM public.post_stock_movement(
        p_company_id,'PurchaseIn',NULL,receiving_branch,item_master.id,e.received_qty,
        p_po_code,p_po_code,p_user_email,
        'PurchaseReceipt:'||op||':'||item_master.id::text
      );
      UPDATE public.purchase_order_details
      SET qty_received=COALESCE(pd.qty_received,0)+e.received_qty
      WHERE id=pd.id;
      total_value:=total_value+(e.received_qty*COALESCE(pd.unit_price,0));
      total_received_qty:=total_received_qty+e.received_qty;
    END IF;
    INSERT INTO public.receiving_details(
      id,operation_id,item_code,item_name,unit,qty_expected,qty_received,difference,reason
    )
    VALUES(
      gen_random_uuid(),op,e.item_code,COALESCE(pd.item_name,e.item_code),COALESCE(pd.unit,'حبة'),
      COALESCE(e.sent_qty,e.received_qty),e.received_qty,
      e.received_qty-COALESCE(e.sent_qty,e.received_qty),
      NULLIF(btrim(COALESCE(e.reason,'')),'')
    );
  END LOOP;

  FOR pd IN SELECT * FROM public.purchase_order_details WHERE po_id=po.id LOOP
    IF coalesce(pd.qty_received,0)<coalesce(pd.qty_ordered,0) THEN all_received:=false; EXIT; END IF;
  END LOOP;
  IF total_received_qty>0 THEN
    PERFORM set_config('rawaea.purchase_actor',p_user_email,true);
    UPDATE public.purchase_orders
    SET status=CASE WHEN all_received THEN 'Received' ELSE 'Partially Received' END,updated_at=now()
    WHERE id=po.id AND company_id=p_company_id;
  END IF;

  -- FINANCIAL BOUNDARY: Receiver records the accepted stock quantity and GRN only.
  -- Supplier AP / GL recognition is deferred until Finance posts the matched invoice.


  INSERT INTO public.audit_log(user_email,action,table_name,record_id,new_data)
  VALUES(p_user_email,'receive','purchase_orders',po.id::text,jsonb_build_object('po_code',p_po_code,'operation_id',p_operation_id,'status',(SELECT status FROM public.purchase_orders WHERE id=po.id),'total_received_value',total_value,'total_received_qty',total_received_qty));

  RETURN jsonb_build_object('success',true,'duplicate',false,'operation_id',p_operation_id,'po_code',p_po_code,'status',(SELECT status FROM public.purchase_orders WHERE id=po.id),'total_received_value',total_value,'total_received_qty',total_received_qty,'journal_posted',false,'supplier_balance_changed',false);
END;
$function$;



CREATE OR REPLACE FUNCTION public.purchase_post_invoice_atomic(p_company_id uuid, p_invoice_id uuid, p_actor text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  i public.purchase_invoices%rowtype;
  d public.purchase_invoice_details%rowtype;
  po public.purchase_orders%rowtype;
  pd public.purchase_order_details%rowtype;
  branch_id uuid;
  inv_acc uuid;
  sup_acc uuid;
  je jsonb;
  v_supplier_ledger jsonb;
  v_journal_operation uuid;
  v_ledger_operation uuid;
  v_operation_hash text;
  v_previous_invoiced numeric(14,3);
  v_po_invoice_total numeric(14,2) := 0;
  v_system_currency text;
  v_item public.items%ROWTYPE;
  v_invoice_unit_factor numeric(14,4);
  v_po_unit_factor numeric(14,4);
BEGIN
  SELECT * INTO i
  FROM public.purchase_invoices
  WHERE id = p_invoice_id AND company_id = p_company_id
  FOR UPDATE;

  IF NOT FOUND THEN RAISE EXCEPTION 'PURCHASE_INVOICE_NOT_FOUND'; END IF;
  IF i.status <> 'Draft' THEN
    RETURN jsonb_build_object('success', true, 'duplicate', true,
      'id', i.id, 'code', i.invoice_code, 'status', i.status);
  END IF;

  SELECT upper(nullif(btrim(s.currency), ''))
    INTO v_system_currency
  FROM public.app_settings s
  WHERE s.company_id = p_company_id
  ORDER BY s.created_at, s.id
  LIMIT 1;

  IF v_system_currency IS NULL THEN
    RAISE EXCEPTION 'PURCHASE_SYSTEM_CURRENCY_NOT_CONFIGURED';
  END IF;
  IF upper(COALESCE(i.currency, '')) <> v_system_currency THEN
    RAISE EXCEPTION 'PURCHASE_INVOICE_SYSTEM_CURRENCY_MISMATCH:%', v_system_currency;
  END IF;

  IF i.purchase_order_id IS NOT NULL THEN
    SELECT * INTO po
    FROM public.purchase_orders
    WHERE id = i.purchase_order_id AND company_id = p_company_id
      AND supplier_id = i.supplier_id
    FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'PURCHASE_PO_SUPPLIER_MISMATCH'; END IF;
    IF upper(COALESCE(po.currency, '')) <> v_system_currency THEN
      RAISE EXCEPTION 'PURCHASE_PO_SYSTEM_CURRENCY_MISMATCH:%', v_system_currency;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM public.receiving r
      WHERE r.company_id = p_company_id
        AND r.po_number = po.po_code
        AND r.status IN ('مكتمل', 'Completed')
    ) THEN
      RAISE EXCEPTION 'PURCHASE_RECEIVING_REQUIRED_BEFORE_POSTING_PO_INVOICE';
    END IF;

    FOR d IN
      SELECT * FROM public.purchase_invoice_details
      WHERE invoice_id = i.id
    LOOP
      SELECT * INTO pd
      FROM public.purchase_order_details x
      WHERE x.po_id = po.id
        AND x.item_id = d.item_id
        AND x.item_code = d.item_code
      FOR UPDATE;

      IF NOT FOUND THEN
        RAISE EXCEPTION 'PURCHASE_INVOICE_ITEM_NOT_IN_PO:%', d.item_code;
      END IF;

      SELECT * INTO v_item
      FROM public.items
      WHERE id=d.item_id AND company_id=p_company_id;
      IF NOT FOUND THEN RAISE EXCEPTION 'PURCHASE_INVOICE_ITEM_INVALID:%',d.item_code; END IF;

      v_invoice_unit_factor:=COALESCE(d.unit_conversion_factor,1);
      v_po_unit_factor:=CASE
        WHEN btrim(pd.unit)=NULLIF(btrim(v_item.alt_unit),'')
          THEN COALESCE(v_item.alt_unit_qty,0)
        ELSE 1
      END;
      IF v_invoice_unit_factor<=0 OR v_po_unit_factor<=0 THEN
        RAISE EXCEPTION 'PURCHASE_INVOICE_UNIT_CONVERSION_INVALID:%',d.item_code;
      END IF;

      SELECT COALESCE(SUM(other_detail.qty*COALESCE(other_detail.unit_conversion_factor,1)),0)
        INTO v_previous_invoiced
      FROM public.purchase_invoice_details other_detail
      JOIN public.purchase_invoices other_invoice
        ON other_invoice.id=other_detail.invoice_id
      WHERE other_invoice.company_id=p_company_id
        AND other_invoice.purchase_order_id=po.id
        AND other_invoice.id<>i.id
        AND other_invoice.status<>'Cancelled'
        AND other_detail.item_code=d.item_code;

      IF COALESCE(d.qty,0)<=0
         OR COALESCE(pd.qty_received,0)*v_po_unit_factor <
            COALESCE(d.qty,0)*v_invoice_unit_factor+COALESCE(v_previous_invoiced,0) THEN
        RAISE EXCEPTION 'PURCHASE_INVOICE_QTY_EXCEEDS_RECEIVED:%',d.item_code;
      END IF;

      IF abs(
           COALESCE(d.unit_price,0)/v_invoice_unit_factor
           -COALESCE(pd.unit_price,0)/v_po_unit_factor
         )>0.01
         OR COALESCE(d.discount_percent,0)<>0
         OR COALESCE(d.tax_rate,0)<>0 THEN
        RAISE EXCEPTION 'PURCHASE_INVOICE_PO_PRICE_OR_TAX_MISMATCH:%',d.item_code;
      END IF;

      v_po_invoice_total:=v_po_invoice_total+(d.qty*d.unit_price);
    END LOOP;

    IF abs(v_po_invoice_total - COALESCE(i.total_amount, 0)) > 0.01 THEN
      RAISE EXCEPTION 'PURCHASE_INVOICE_PO_TOTAL_MISMATCH';
    END IF;


    -- Legacy guard: do not duplicate AP already recognized by the old
    -- PurchaseReceiving path. Such documents require a separate finance reconciliation.
    IF EXISTS (
      SELECT 1 FROM public.journal_entries je
      WHERE je.company_id=p_company_id
        AND je.entry_type='PurchaseReceiving'
        AND je.reference=po.po_code
        AND je.status='Posted'
    ) OR EXISTS (
      SELECT 1 FROM public.supplier_ledger sl
      WHERE sl.supplier_id=i.supplier_id
        AND sl.reference=po.po_code
        AND sl.description='استلام بضاعة - '||po.po_code
        AND COALESCE(sl.credit,0)>0
    ) THEN
      RAISE EXCEPTION 'PURCHASE_LEGACY_RECEIVING_AP_REQUIRES_RECONCILIATION';
    END IF;

    IF COALESCE(i.total_amount,0)<=0 THEN
      RAISE EXCEPTION 'PURCHASE_INVOICE_TOTAL_INVALID';
    END IF;

    SELECT id INTO inv_acc
    FROM public.chart_of_accounts
    WHERE company_id=p_company_id AND account_code='124' AND is_active=true
    LIMIT 1;
    SELECT id INTO sup_acc
    FROM public.chart_of_accounts
    WHERE company_id=p_company_id AND account_code='211' AND is_active=true
    LIMIT 1;
    IF inv_acc IS NULL OR sup_acc IS NULL THEN
      RAISE EXCEPTION 'PURCHASE_ACCOUNTS_NOT_CONFIGURED';
    END IF;

    v_operation_hash:=md5('RAWAEA:PO-INVOICE-JE:'||p_company_id::text||':'||i.id::text);
    v_journal_operation:=(
      substr(v_operation_hash,1,8)||'-'||substr(v_operation_hash,9,4)||'-'||
      substr(v_operation_hash,13,4)||'-'||substr(v_operation_hash,17,4)||'-'||
      substr(v_operation_hash,21,12)
    )::uuid;


    je := public.post_journal_entry(
      p_company_id,
      v_journal_operation,
      i.invoice_date,
      'PurchaseInvoice',
      i.invoice_code,
      'فاتورة شراء معتمدة بعد مطابقة الاستلام - '||i.invoice_code,
      p_actor,
      jsonb_build_array(
        jsonb_build_object(
          'account_id',inv_acc,
          'account_name',(SELECT account_name FROM public.chart_of_accounts WHERE id=inv_acc),
          'debit',i.total_amount,'credit',0,
          'notes','إثبات قيمة البضاعة المقبولة بمستند فاتورة المورد'
        ),
        jsonb_build_object(
          'account_id',sup_acc,
          'account_name',(SELECT account_name FROM public.chart_of_accounts WHERE id=sup_acc),
          'debit',0,'credit',i.total_amount,
          'notes','إثبات ذمة المورد بعد مراجعة الحسابات'
        )
      ),
      NULL,
      now(),
      NULL
    );

    v_operation_hash:=md5('RAWAEA:PO-INVOICE-AP:'||p_company_id::text||':'||i.id::text);
    v_ledger_operation:=(
      substr(v_operation_hash,1,8)||'-'||substr(v_operation_hash,9,4)||'-'||
      substr(v_operation_hash,13,4)||'-'||substr(v_operation_hash,17,4)||'-'||
      substr(v_operation_hash,21,12)
    )::uuid;

    v_supplier_ledger:=public.post_supplier_ledger_entry(
      p_company_id,
      v_ledger_operation,
      i.supplier_id,
      i.invoice_date,
      i.invoice_code,
      'فاتورة شراء - '||i.invoice_code,
      0,
      i.total_amount,
      i.due_date,
      p_actor
    );

    UPDATE public.purchase_invoices
    SET status = 'Posted',
        is_received = true,
        received_date = COALESCE(received_date, current_date),
        posted_by = p_actor,
        posted_at = now(),
        updated_at = now()
    WHERE id = i.id AND company_id = p_company_id;

    RETURN jsonb_build_object(
      'success', true, 'id', i.id, 'code', i.invoice_code, 'status', 'Posted',
      'accounting_source', 'PurchaseInvoice',
      'stock_posted_by_invoice', false,
      'supplier_liability_posted_by_invoice', true,
      'journal', je,
      'supplier_ledger', v_supplier_ledger
    );
  END IF;

  IF i.purchase_order_id IS NULL THEN
    RAISE EXCEPTION 'PURCHASE_QUICK_INVOICE_RECEIPT_REQUIRED: لا يمكن ترحيل فاتورة شراء سريعة غير مرتبطة بأمر شراء قبل تسجيل الاستلام الفعلي واعتماده من المخزن.';
  END IF;

  branch_id := COALESCE(
    i.branch_id,
    (SELECT a.main_branch_id
     FROM public.app_settings a
     WHERE a.company_id = p_company_id
     ORDER BY a.created_at, a.id
     LIMIT 1)
  );

  IF branch_id IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.branches
    WHERE id = branch_id AND company_id = p_company_id
  ) THEN
    RAISE EXCEPTION 'PURCHASE_BRANCH_INVALID';
  END IF;

  SELECT id INTO inv_acc
  FROM public.chart_of_accounts
  WHERE company_id = p_company_id AND account_code = '124' AND is_active
  LIMIT 1;
  SELECT id INTO sup_acc
  FROM public.chart_of_accounts
  WHERE company_id = p_company_id AND account_code = '211' AND is_active
  LIMIT 1;

  IF inv_acc IS NULL OR sup_acc IS NULL THEN
    RAISE EXCEPTION 'PURCHASE_ACCOUNTS_NOT_CONFIGURED';
  END IF;

  FOR d IN
    SELECT * FROM public.purchase_invoice_details
    WHERE invoice_id = i.id
  LOOP
    PERFORM public.post_stock_movement(
      p_company_id, 'PurchaseIn', NULL, branch_id, d.item_id, d.qty,
      i.invoice_code, i.invoice_code, p_actor,
      'PurchaseInvoice:' || i.id::text || ':' || d.id::text
    );
    UPDATE public.purchase_invoice_details
    SET received_qty = d.qty
    WHERE id = d.id;
  END LOOP;

  je := public.post_journal_entry(
    p_company_id, gen_random_uuid(), i.invoice_date, 'PurchaseInvoice',
    i.invoice_code, 'فاتورة شراء ' || i.invoice_code, p_actor,
    jsonb_build_array(
      jsonb_build_object('account_id', inv_acc,
        'account_name', (SELECT account_name FROM public.chart_of_accounts WHERE id = inv_acc),
        'debit', i.total_amount, 'credit', 0),
      jsonb_build_object('account_id', sup_acc,
        'account_name', (SELECT account_name FROM public.chart_of_accounts WHERE id = sup_acc),
        'debit', 0, 'credit', i.total_amount)
    ), NULL, now(), NULL
  );

  INSERT INTO public.supplier_ledger(
    supplier_id, entry_date, reference, description,
    debit, credit, balance, due_date, user_email
  )
  VALUES(
    i.supplier_id, i.invoice_date, i.invoice_code,
    'فاتورة شراء - ' || i.invoice_code, 0, i.total_amount,
    COALESCE((
      SELECT balance FROM public.supplier_ledger
      WHERE supplier_id = i.supplier_id
      ORDER BY created_at DESC LIMIT 1
    ), 0) + i.total_amount,
    i.due_date, p_actor
  );

  UPDATE public.purchase_invoices
  SET status = 'Posted',
      is_received = true,
      received_date = current_date,
      posted_by = p_actor,
      posted_at = now(),
      updated_at = now()
  WHERE id = i.id AND company_id = p_company_id;

  RETURN jsonb_build_object(
    'success', true, 'id', i.id, 'code', i.invoice_code,
    'status', 'Posted', 'journal', je
  );
END;
$function$;



CREATE OR REPLACE FUNCTION public.purchase_post_buyer_invoice_atomic(p_company_id uuid, p_invoice_id uuid, p_actor text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_actor public.users%ROWTYPE;
  v_invoice public.purchase_invoices%ROWTYPE;
  v_result jsonb;
BEGIN
  SELECT * INTO v_actor
  FROM public.users
  WHERE auth.uid()=users.auth_id
    AND company_id=p_company_id
    AND COALESCE(status,'Active')='Active';

  IF NOT FOUND OR lower(v_actor.email)<>lower(COALESCE(p_actor,'')) THEN
    RAISE EXCEPTION 'PURCHASE_ACTOR_AUTH_MISMATCH';
  END IF;

  IF NOT (
    (app_private.current_user_has_effective_permission('purchases')
      AND app_private.current_user_has_effective_permission('finance'))
  ) THEN
    RAISE EXCEPTION 'PURCHASE_POST_REQUIRES_PURCHASES_AND_FINANCE';
  END IF;

  SELECT * INTO v_invoice
  FROM public.purchase_invoices
  WHERE id=p_invoice_id AND company_id=p_company_id
  FOR UPDATE;

  IF NOT FOUND THEN RAISE EXCEPTION 'PURCHASE_INVOICE_NOT_FOUND'; END IF;

  IF v_invoice.purchase_source='QUICK_MARKET' THEN
    RAISE EXCEPTION 'PURCHASE_QUICK_MARKET_RECEIPT_REQUIRED: يجب اعتماد استلام المخزن في Receiver قبل الترحيل.';
  END IF;

  -- تاريخ الفواتير القديمة يبقى على السلوك الأصلي، دون وسم زائف أو حقول مصدر جديدة.
  IF v_invoice.purchase_source IS DISTINCT FROM 'PURCHASE_ORDER' THEN
    RETURN public.purchase_post_invoice_atomic(p_company_id,p_invoice_id,v_actor.email);
  END IF;

  v_result:=public.purchase_post_invoice_atomic(p_company_id,p_invoice_id,v_actor.email);

  IF COALESCE((v_result->>'success')::boolean,false)
     AND v_result->>'status' IN ('Posted','Paid') THEN
    UPDATE public.purchase_invoices
    SET receipt_status='RECEIVED',
        settlement_status=CASE
          WHEN COALESCE(paid_amount,0)>=COALESCE(total_amount,0) THEN 'PAID'
          ELSE 'AP_OPEN'
        END,
        updated_at=now()
    WHERE id=p_invoice_id AND company_id=p_company_id;
  END IF;

  RETURN v_result||jsonb_build_object(
    'purchase_source','PURCHASE_ORDER',
    'stock_posted_by_invoice',false,
    'supplier_liability_posted_by_invoice',true
  );
END;
$function$;