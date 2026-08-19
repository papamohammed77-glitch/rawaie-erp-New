-- RAWAEA ERP — sales invoice request identity / idempotency closure.
-- Adds a first-class operation identity to orders and makes save_sales_invoice_atomic replay-safe.
-- Physical stock remains exclusively delegated to post_stock_movement.
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS operation_id uuid;
CREATE UNIQUE INDEX IF NOT EXISTS orders_company_operation_id_uq
  ON public.orders(company_id, operation_id)
  WHERE operation_id IS NOT NULL;

CREATE OR REPLACE FUNCTION public.save_sales_invoice_atomic(
  p_order_header jsonb,
  p_items jsonb,
  p_branch_code text,
  p_user_email text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_company_id uuid; v_customer_uuid uuid; v_branch_uuid uuid; v_settings_id uuid; v_main_branch uuid;
  v_operation_id uuid; existing_order public.orders%ROWTYPE;
  last_code text; next_serial integer:=1001; v_order_code text; v_order_id uuid; item record;
  v_item_id uuid; v_cost_price numeric; v_total numeric; v_order_status text; v_is_van boolean;
  v_source_branch uuid; v_movement text; v_total_cogs numeric:=0; v_entry_id uuid; v_is_cash boolean; prev_balance numeric:=0;
  v_cash_account uuid; v_ar_account uuid; v_sales_account uuid; v_cogs_account uuid; v_inventory_account uuid;
  v_cash_name text; v_ar_name text; v_sales_name text; v_cogs_name text; v_inventory_name text;
BEGIN
  SELECT u.company_id INTO v_company_id
  FROM public.users u
  WHERE lower(u.email)=lower(p_user_email) AND coalesce(u.status,'Active')='Active'
  LIMIT 1;
  IF v_company_id IS NULL THEN RAISE EXCEPTION 'Company context unavailable for authenticated user'; END IF;

  BEGIN
    v_operation_id := NULLIF(p_order_header->>'operation_id','')::uuid;
  EXCEPTION WHEN invalid_text_representation THEN
    RAISE EXCEPTION 'Invalid operation_id';
  END;

  IF v_operation_id IS NOT NULL THEN
    SELECT * INTO existing_order
    FROM public.orders
    WHERE company_id=v_company_id AND operation_id=v_operation_id
    FOR UPDATE;
    IF FOUND THEN
      RETURN jsonb_build_object('success',true,'duplicate',true,'orderID',existing_order.order_code,'order_id',existing_order.id,'company_id',v_company_id,'operation_id',v_operation_id);
    END IF;
  END IF;

  SELECT a.main_branch_id,a.id INTO v_main_branch,v_settings_id
  FROM public.app_settings a
  WHERE a.company_id=v_company_id
  ORDER BY a.created_at ASC,a.id
  LIMIT 1;
  IF v_main_branch IS NULL THEN RAISE EXCEPTION 'MAIN branch context unavailable for company'; END IF;

  SELECT coa.id,coa.account_name INTO v_cash_account,v_cash_name FROM public.chart_of_accounts coa WHERE coa.company_id=v_company_id AND coa.account_code='121' AND coa.is_active=true LIMIT 1;
  SELECT coa.id,coa.account_name INTO v_ar_account,v_ar_name FROM public.chart_of_accounts coa WHERE coa.company_id=v_company_id AND coa.account_code='123' AND coa.is_active=true LIMIT 1;
  SELECT coa.id,coa.account_name INTO v_sales_account,v_sales_name FROM public.chart_of_accounts coa WHERE coa.company_id=v_company_id AND coa.account_code='41' AND coa.is_active=true LIMIT 1;
  SELECT coa.id,coa.account_name INTO v_cogs_account,v_cogs_name FROM public.chart_of_accounts coa WHERE coa.company_id=v_company_id AND coa.account_code='51' AND coa.is_active=true LIMIT 1;
  SELECT coa.id,coa.account_name INTO v_inventory_account,v_inventory_name FROM public.chart_of_accounts coa WHERE coa.company_id=v_company_id AND coa.account_code='124' AND coa.is_active=true LIMIT 1;
  IF v_cash_account IS NULL OR v_ar_account IS NULL OR v_sales_account IS NULL OR v_cogs_account IS NULL OR v_inventory_account IS NULL THEN
    RAISE EXCEPTION 'Required sales accounts are not configured for company';
  END IF;

  SELECT c.id INTO v_customer_uuid FROM public.customers c WHERE c.customer_code=p_order_header->>'customer_code' AND c.company_id=v_company_id LIMIT 1;
  SELECT b.id INTO v_branch_uuid FROM public.branches b WHERE b.branch_code=coalesce(p_branch_code,'MAIN') AND b.company_id=v_company_id LIMIT 1;
  IF v_branch_uuid IS NULL THEN RAISE EXCEPTION 'Branch not found for company'; END IF;

  PERFORM pg_advisory_xact_lock(hashtext('rawaea:sales-order-code:'||v_company_id::text));
  SELECT o.order_code INTO last_code FROM public.orders o WHERE o.company_id=v_company_id ORDER BY o.created_at DESC,o.id DESC LIMIT 1;
  IF last_code~'^ORD-[0-9]+$' THEN next_serial:=greatest(1001,(regexp_replace(last_code,'^ORD-',''))::integer+1); END IF;
  v_order_code:='ORD-'||next_serial::text; v_total:=coalesce((p_order_header->>'total')::numeric,0); v_order_status:=coalesce(p_order_header->>'status','Confirmed');

  INSERT INTO public.orders(id,company_id,operation_id,order_code,order_date,customer_id,customer_name,area,total_amount,original_total_amount,delivery_fee,order_status,payment_type,branch_id,created_by,source,customer_phone,customer_email,coupon_code,discount_amount,notes)
  VALUES(gen_random_uuid(),v_company_id,v_operation_id,v_order_code,current_date,v_customer_uuid,p_order_header->>'custName',coalesce(p_order_header->>'area',''),v_total,v_total,coalesce((p_order_header->>'deliveryFees')::numeric,0),v_order_status,coalesce(p_order_header->>'paymentType','أجل'),v_branch_uuid,p_user_email,coalesce(p_order_header->>'source','pos'),p_order_header->>'customerPhone',p_order_header->>'customerEmail',p_order_header->>'couponCode',coalesce((p_order_header->>'discountAmount')::numeric,0),p_order_header->>'notes') RETURNING id INTO v_order_id;

  FOR item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(code text,name text,unit text,price numeric,qty numeric) LOOP
    SELECT i.id,i.cost_price INTO v_item_id,v_cost_price FROM public.items i WHERE i.item_code=item.code LIMIT 1;
    IF v_item_id IS NULL THEN RAISE EXCEPTION 'الصنف غير موجود: %',item.code; END IF;
    INSERT INTO public.order_details(id,order_id,item_id,item_code,item_name,unit,unit_price,qty) VALUES(gen_random_uuid(),v_order_id,v_item_id,item.code,item.name,coalesce(item.unit,'حبة'),item.price,item.qty);
  END LOOP;

  v_is_van:=(p_branch_code LIKE 'VAN-%');
  IF v_order_status='Invoiced' THEN
    v_source_branch:=v_branch_uuid; v_movement:=CASE WHEN v_is_van THEN 'VanSale' ELSE 'POSSale' END;
    FOR item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(code text,name text,unit text,price numeric,qty numeric) LOOP
      SELECT i.id,i.cost_price INTO v_item_id,v_cost_price FROM public.items i WHERE i.item_code=item.code LIMIT 1;
      IF item.qty IS NULL OR item.qty<=0 THEN CONTINUE; END IF;
      PERFORM public.post_stock_movement(v_company_id,v_movement,v_source_branch,NULL,v_item_id,item.qty,v_order_code,v_order_code,p_user_email,'SalesInvoice:'||v_company_id::text||':'||v_order_id::text||':'||v_item_id::text);
      v_total_cogs:=v_total_cogs+(item.qty*coalesce(v_cost_price,0));
    END LOOP;
  END IF;

  IF v_order_status='Invoiced' AND v_total>0 THEN
    v_is_cash:=coalesce(p_order_header->>'paymentType','أجل')='نقدي';
    INSERT INTO public.journal_entries(id,company_id,entry_code,entry_date,reference,description,entry_type,status,created_by,posting_date)
    VALUES(gen_random_uuid(),v_company_id,'JE-POS-'||replace(gen_random_uuid()::text,'-',''),current_date,v_order_code,'فاتورة نقطة بيع – '||v_order_code||CASE WHEN v_is_van THEN ' (Van Sales)' ELSE '' END,CASE WHEN v_is_van THEN 'VanSales' ELSE 'POS_Sale' END,'Posted',p_user_email,now()) RETURNING id INTO v_entry_id;
    INSERT INTO public.journal_lines(entry_id,account_id,account_name,debit,credit)
    VALUES(v_entry_id,CASE WHEN v_is_cash THEN v_cash_account ELSE v_ar_account END,CASE WHEN v_is_cash THEN v_cash_name ELSE v_ar_name END,v_total,0),(v_entry_id,v_sales_account,v_sales_name,0,v_total);
    IF v_total_cogs>0 THEN
      INSERT INTO public.journal_lines(entry_id,account_id,account_name,debit,credit)
      VALUES(v_entry_id,v_cogs_account,v_cogs_name,v_total_cogs,0),(v_entry_id,v_inventory_account,v_inventory_name,0,v_total_cogs);
    END IF;
    IF NOT v_is_cash AND v_customer_uuid IS NOT NULL THEN
      SELECT COALESCE(cl.balance,0) INTO prev_balance FROM public.customer_ledger cl WHERE cl.customer_id=v_customer_uuid ORDER BY cl.created_at DESC LIMIT 1;
      INSERT INTO public.customer_ledger(customer_id,entry_date,reference,description,debit,credit,balance,due_date,user_email)
      VALUES(v_customer_uuid,current_date,v_order_code,'فاتورة نقطة بيع – '||v_order_code,v_total,0,prev_balance+v_total,current_date,p_user_email);
    END IF;
    IF v_is_van AND NOT v_is_cash THEN
      INSERT INTO public.driver_ledger(driver_email,entry_date,description,debit,credit,reference) VALUES(p_user_email,current_date,'بيع آجل – '||v_order_code,v_total,0,v_order_code);
    END IF;
  END IF;

  UPDATE public.app_settings SET order_serial=next_serial WHERE id=v_settings_id AND company_id=v_company_id;
  RETURN jsonb_build_object('success',true,'duplicate',false,'orderID',v_order_code,'order_id',v_order_id,'total_cogs',v_total_cogs,'company_id',v_company_id,'operation_id',v_operation_id);
END;
$function$;
