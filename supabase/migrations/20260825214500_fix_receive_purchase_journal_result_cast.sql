-- Surgical Phase-2 production fix.
-- post_journal_entry returns jsonb; receive_purchase_atomic previously assigned that JSONB directly to uuid.
-- The business contract is unchanged; only entry_id extraction is corrected.
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
  receiving_id uuid;
  now_ts timestamptz := now();
  total_value numeric := 0;
  all_received boolean := true;
  supplier_account uuid;
  inventory_account uuid;
  entry_id uuid;
  existing_receiving public.receiving%ROWTYPE;
  req_count integer;
  existing_count integer;
  payload_mismatch boolean;
BEGIN
  IF p_operation_id IS NULL THEN RAISE EXCEPTION 'RECEIVE_PURCHASE_OPERATION_ID_REQUIRED'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.companies c WHERE c.id=p_company_id) THEN RAISE EXCEPTION 'سياق الشركة غير موجود'; END IF;
  IF p_items IS NULL OR jsonb_typeof(p_items)<>'array' OR jsonb_array_length(p_items)=0 THEN RAISE EXCEPTION 'لا توجد أصناف للاستلام'; END IF;
  SELECT * INTO po FROM public.purchase_orders WHERE company_id=p_company_id AND po_code=p_po_code FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'أمر الشراء غير موجود'; END IF;
  SELECT r.* INTO existing_receiving FROM public.receiving r WHERE r.operation_id=p_operation_id::text FOR UPDATE;
  IF FOUND THEN
    IF existing_receiving.company_id<>p_company_id OR existing_receiving.po_number<>p_po_code THEN RAISE EXCEPTION 'RECEIVE_PURCHASE_OPERATION_ID_REUSE_CONFLICT'; END IF;
    SELECT count(*) INTO req_count FROM jsonb_to_recordset(p_items) AS x(item_code text,received_qty numeric,item_name text,unit text,reason text) WHERE coalesce(x.received_qty,0)>0;
    SELECT count(*) INTO existing_count FROM public.receiving_details rd WHERE rd.operation_id=p_operation_id::text;
    SELECT EXISTS (SELECT 1 FROM jsonb_to_recordset(p_items) AS x(item_code text,received_qty numeric,item_name text,unit text,reason text) WHERE coalesce(x.received_qty,0)>0 AND NOT EXISTS (SELECT 1 FROM public.receiving_details rd WHERE rd.operation_id=p_operation_id::text AND rd.item_code=x.item_code AND rd.qty_received=x.received_qty)) OR EXISTS (SELECT 1 FROM public.receiving_details rd WHERE rd.operation_id=p_operation_id::text AND NOT EXISTS (SELECT 1 FROM jsonb_to_recordset(p_items) AS x(item_code text,received_qty numeric,item_name text,unit text,reason text) WHERE coalesce(x.received_qty,0)>0 AND x.item_code=rd.item_code AND x.received_qty=rd.qty_received)) INTO payload_mismatch;
    IF payload_mismatch OR req_count<>existing_count THEN RAISE EXCEPTION 'RECEIVE_PURCHASE_OPERATION_PAYLOAD_CONFLICT'; END IF;
    RETURN jsonb_build_object('success',true,'duplicate',true,'operation_id',p_operation_id,'po_code',p_po_code,'status',(SELECT status FROM public.purchase_orders WHERE id=po.id));
  END IF;
  SELECT main_branch_id INTO STRICT main_branch FROM public.app_settings WHERE company_id=p_company_id ORDER BY created_at ASC,id LIMIT 1;
  receiving_branch:=COALESCE(po.branch_id,main_branch);
  IF NOT EXISTS (SELECT 1 FROM public.branches b WHERE b.id=receiving_branch AND b.company_id=p_company_id) THEN RAISE EXCEPTION 'فرع الاستلام غير صالح للشركة'; END IF;
  IF EXISTS (SELECT 1 FROM jsonb_to_recordset(p_items) AS x(item_code text,received_qty numeric,item_name text,unit text,reason text) GROUP BY x.item_code HAVING count(*)>1) THEN RAISE EXCEPTION 'لا يجوز تكرار الصنف داخل نفس عملية الاستلام'; END IF;
  FOR e IN SELECT * FROM jsonb_to_recordset(p_items) AS x(item_code text,received_qty numeric,item_name text,unit text,reason text) LOOP
    IF COALESCE(e.received_qty,0)<=0 THEN CONTINUE; END IF;
    IF NULLIF(btrim(e.item_code),'') IS NULL THEN RAISE EXCEPTION 'كود الصنف مطلوب'; END IF;
    SELECT * INTO pd FROM public.purchase_order_details d WHERE d.po_id=po.id AND d.item_code=e.item_code FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'الصنف غير موجود داخل أمر الشراء: %',e.item_code; END IF;
    SELECT * INTO item_master FROM public.items i WHERE i.id=pd.item_id AND i.item_code=e.item_code;
    IF NOT FOUND THEN RAISE EXCEPTION 'هوية الصنف غير متسقة مع دليل الأصناف: %',e.item_code; END IF;
    IF e.received_qty>GREATEST(0,COALESCE(pd.qty_ordered,0)-COALESCE(pd.qty_received,0)) THEN RAISE EXCEPTION 'الكمية المستلمة تتجاوز المتبقي للصنف: %',e.item_code; END IF;
  END LOOP;
  receiving_id:=gen_random_uuid();
  INSERT INTO public.receiving(id,operation_id,date,po_number,responsible,start_time,end_time,status,company_id) VALUES(receiving_id,p_operation_id::text,current_date,p_po_code,p_user_email,now_ts,now_ts,'مكتمل',p_company_id);
  FOR e IN SELECT * FROM jsonb_to_recordset(p_items) AS x(item_code text,received_qty numeric,item_name text,unit text,reason text) LOOP
    IF COALESCE(e.received_qty,0)<=0 THEN CONTINUE; END IF;
    SELECT * INTO pd FROM public.purchase_order_details d WHERE d.po_id=po.id AND d.item_code=e.item_code FOR UPDATE;
    SELECT * INTO item_master FROM public.items i WHERE i.id=pd.item_id AND i.item_code=e.item_code;
    PERFORM public.post_stock_movement(p_company_id,'PurchaseIn',NULL,receiving_branch,item_master.id,e.received_qty,p_po_code,p_po_code,p_user_email,'PurchaseReceipt:'||p_operation_id::text||':'||item_master.id::text);
    UPDATE public.purchase_order_details SET qty_received=COALESCE(pd.qty_received,0)+e.received_qty WHERE id=pd.id;
    INSERT INTO public.receiving_details(id,operation_id,item_code,item_name,unit,qty_expected,qty_received,difference,reason) VALUES(gen_random_uuid(),p_operation_id::text,e.item_code,COALESCE(e.item_name,e.item_code),COALESCE(e.unit,'حبة'),pd.qty_ordered,e.received_qty,e.received_qty-pd.qty_ordered,CASE WHEN e.reason IS NOT NULL THEN e.reason WHEN e.received_qty<pd.qty_ordered THEN 'نقص في الاستلام' WHEN e.received_qty>pd.qty_ordered THEN 'زيادة في الاستلام' ELSE NULL END);
    total_value:=total_value+(e.received_qty*COALESCE(pd.unit_price,0));
  END LOOP;
  FOR pd IN SELECT * FROM public.purchase_order_details d WHERE d.po_id=po.id LOOP
    IF COALESCE(pd.qty_received,0)<COALESCE(pd.qty_ordered,0) THEN all_received:=false; EXIT; END IF;
  END LOOP;
  UPDATE public.purchase_orders SET status=CASE WHEN all_received THEN 'Received' ELSE 'Partially Received' END,updated_at=now() WHERE id=po.id AND company_id=p_company_id;
  IF total_value>0 THEN
    SELECT id INTO supplier_account FROM public.chart_of_accounts WHERE company_id=p_company_id AND account_code='211' AND is_active=true LIMIT 1;
    SELECT id INTO inventory_account FROM public.chart_of_accounts WHERE company_id=p_company_id AND account_code='124' AND is_active=true LIMIT 1;
    IF supplier_account IS NULL OR inventory_account IS NULL THEN RAISE EXCEPTION 'حسابات الاستلام غير مكتملة'; END IF;
    IF po.supplier_id IS NULL THEN RAISE EXCEPTION 'PURCHASE_SUPPLIER_REQUIRED_FOR_FINANCIAL_POSTING'; END IF;
    SELECT (public.post_journal_entry(p_company_id,p_operation_id,current_date,'PurchaseReceiving',p_po_code,'استلام بضاعة – أمر الشراء '||p_po_code,p_user_email,jsonb_build_array(jsonb_build_object('account_id',inventory_account,'account_name','المخزون السلعي','debit',total_value,'credit',0),jsonb_build_object('account_id',supplier_account,'account_name','الموردون (ذمم دائنة)','debit',0,'credit',total_value)),NULL,now(),NULL)->>'entry_id')::uuid INTO entry_id;
    PERFORM public.post_supplier_ledger_entry(p_company_id,p_operation_id,po.supplier_id,current_date,p_po_code,'استلام بضاعة - '||p_po_code,0,total_value,current_date,p_user_email);
  END IF;
  RETURN jsonb_build_object('success',true,'duplicate',false,'operation_id',p_operation_id,'po_code',p_po_code,'status',(SELECT status FROM public.purchase_orders WHERE id=po.id),'total_received_value',total_value,'branch_id',receiving_branch);
END;
$function$;
