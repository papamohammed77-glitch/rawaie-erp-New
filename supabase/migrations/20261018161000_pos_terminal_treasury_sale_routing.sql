-- RAWAEA POS: route each cash POS invoice to the treasury fixed to its open terminal shift.
-- Live defect at 2026-10-18: save_sales_invoice_atomic rejected cash POS sales whenever a company had
-- more than one active treasury, despite pos_shifts/pos_terminals already binding a fixed treasury.
-- Preserve the existing non-POS treasury contract; only POS uses the terminal/shift-bound treasury.
-- Also persist optional shift_id/device_id in orders and validate explicit device/shift identity at the trigger.

CREATE OR REPLACE FUNCTION public.save_sales_invoice_atomic(p_order_header jsonb, p_items jsonb, p_branch_code text, p_user_email text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
 v_company_id uuid; v_customer_uuid uuid; v_branch_uuid uuid; v_settings_id uuid; v_main_branch uuid; v_operation_id uuid; v_existing_order_code text; existing_order public.orders%ROWTYPE;
 last_code text; next_serial integer:=1001; v_order_code text; v_order_id uuid; item record; v_item_id uuid; v_cost_price numeric; v_total numeric; v_order_status text; v_is_van boolean; v_total_cogs numeric:=0;
 v_is_cash boolean; v_cash_account uuid; v_ar_account uuid; v_sales_account uuid; v_cogs_account uuid; v_inventory_account uuid; v_cash_name text; v_ar_name text; v_sales_name text; v_cogs_name text; v_inventory_name text;
 v_treasury_id uuid; v_treasury_count integer:=0; v_cash_result jsonb; v_sales_journal jsonb; v_cogs_journal jsonb; v_customer_ledger jsonb; v_cogs_operation_id uuid; v_customer_ledger_operation_id uuid;
 v_decision jsonb; v_decision_payload jsonb; v_gross_amount numeric:=0; v_discount_amount numeric:=0; v_pricing jsonb; v_effective_items jsonb; v_promo_discount numeric:=0;
BEGIN
 SELECT u.company_id INTO v_company_id FROM public.users u WHERE lower(u.email)=lower(p_user_email) AND coalesce(u.status,'Active')='Active' LIMIT 1;
 IF v_company_id IS NULL THEN RAISE EXCEPTION 'Company context unavailable for authenticated user'; END IF;
 BEGIN v_operation_id:=NULLIF(p_order_header->>'operation_id','')::uuid; EXCEPTION WHEN invalid_text_representation THEN RAISE EXCEPTION 'Invalid operation_id'; END;
 IF v_operation_id IS NULL THEN RAISE EXCEPTION 'Sales operation_id is required'; END IF;
 v_existing_order_code:=NULLIF(btrim(p_order_header->>'existing_order_code'),'');
 IF v_existing_order_code IS NULL THEN
   SELECT * INTO existing_order FROM public.orders WHERE company_id=v_company_id AND operation_id=v_operation_id FOR UPDATE;
   IF FOUND THEN RETURN jsonb_build_object('success',true,'duplicate',true,'orderID',existing_order.order_code,'order_id',existing_order.id,'company_id',v_company_id,'operation_id',v_operation_id); END IF;
 ELSE
   SELECT * INTO existing_order FROM public.orders WHERE company_id=v_company_id AND order_code=v_existing_order_code FOR UPDATE;
   IF NOT FOUND THEN RAISE EXCEPTION 'الأوردر المراد تعديله غير موجود'; END IF;
   IF existing_order.runsheet_id IS NOT NULL THEN RAISE EXCEPTION 'لا يمكن تعديل أوردر مربوط برانشيت'; END IF;
   IF existing_order.order_status NOT IN ('Draft','Confirmed') THEN RAISE EXCEPTION 'لا يمكن تعديل الأوردر في حالته الحالية'; END IF;
   IF lower(coalesce(existing_order.created_by,'')) <> lower(p_user_email) THEN
     IF NOT EXISTS (
       SELECT 1 FROM public.users u
       WHERE lower(u.email)=lower(p_user_email)
         AND u.company_id=v_company_id
         AND coalesce(u.status,'Active')='Active'
         AND (
           coalesce(u.permissions,'[]'::jsonb) ? '*'
           OR coalesce(u.permissions,'[]'::jsonb) ? 'general_manager'
           OR coalesce(u.permissions,'[]'::jsonb) ? 'sales_manager'
           OR coalesce(u.permissions,'[]'::jsonb) ? 'sales_supervisor'
         )
     ) THEN
       RAISE EXCEPTION 'لا تملك صلاحية تعديل أوردر أنشأه مستخدم آخر';
     END IF;
   END IF;
 END IF;
 SELECT a.main_branch_id,a.id INTO v_main_branch,v_settings_id FROM public.app_settings a WHERE a.company_id=v_company_id ORDER BY a.created_at ASC,a.id LIMIT 1;
 IF v_main_branch IS NULL THEN RAISE EXCEPTION 'MAIN branch context unavailable for company'; END IF;
 SELECT coa.id,coa.account_name INTO v_cash_account,v_cash_name FROM public.chart_of_accounts coa WHERE coa.company_id=v_company_id AND coa.account_code='121' AND coalesce(coa.is_active,true)=true LIMIT 1;
 SELECT coa.id,coa.account_name INTO v_ar_account,v_ar_name FROM public.chart_of_accounts coa WHERE coa.company_id=v_company_id AND coa.account_code='123' AND coalesce(coa.is_active,true)=true LIMIT 1;
 SELECT coa.id,coa.account_name INTO v_sales_account,v_sales_name FROM public.chart_of_accounts coa WHERE coa.company_id=v_company_id AND coa.account_code='41' AND coalesce(coa.is_active,true)=true LIMIT 1;
 SELECT coa.id,coa.account_name INTO v_cogs_account,v_cogs_name FROM public.chart_of_accounts coa WHERE coa.company_id=v_company_id AND coa.account_code='51' AND coalesce(coa.is_active,true)=true LIMIT 1;
 SELECT coa.id,coa.account_name INTO v_inventory_account,v_inventory_name FROM public.chart_of_accounts coa WHERE coa.company_id=v_company_id AND coa.account_code='124' AND coalesce(coa.is_active,true)=true LIMIT 1;
 IF v_cash_account IS NULL OR v_ar_account IS NULL OR v_sales_account IS NULL OR v_cogs_account IS NULL OR v_inventory_account IS NULL THEN RAISE EXCEPTION 'Required sales accounts are not configured for company'; END IF;
 SELECT c.id INTO v_customer_uuid FROM public.customers c WHERE c.customer_code=p_order_header->>'customer_code' AND c.company_id=v_company_id LIMIT 1;
 SELECT b.id INTO v_branch_uuid FROM public.branches b WHERE b.branch_code=coalesce(p_branch_code,'MAIN') AND b.company_id=v_company_id LIMIT 1;
 IF v_branch_uuid IS NULL THEN RAISE EXCEPTION 'Branch not found for company'; END IF;
 v_order_status:=coalesce(p_order_header->>'status','Confirmed');
  v_pricing:=public.resolve_sales_pricing_atomic(
    v_company_id,
    v_customer_uuid,
    v_branch_uuid,
    coalesce(p_order_header->>'source',CASE WHEN p_branch_code LIKE 'VAN-%' THEN 'van-sales' ELSE 'pos' END),
    (SELECT coalesce(jsonb_agg(jsonb_build_object('item_code',x.code,'qty',x.qty)),'[]'::jsonb)
     FROM jsonb_to_recordset(p_items) AS x(code text,name text,unit text,price numeric,qty numeric)),
    nullif(p_order_header->>'couponCode',''),
    current_date
  );
  v_promo_discount:=greatest(coalesce((v_pricing->>'promotion_discount')::numeric,0),0);
  v_discount_amount:=greatest(coalesce((p_order_header->>'discountAmount')::numeric,0),0)+v_promo_discount;
  v_total:=greatest(0,coalesce((v_pricing->>'subtotal')::numeric,0)-v_discount_amount+greatest(coalesce((p_order_header->>'deliveryFees')::numeric,0),0));
  v_effective_items:=COALESCE((
    SELECT jsonb_agg(jsonb_build_object(
      'code',t.obj->>'item_code',
      'name',t.obj->>'name',
      'unit',t.obj->>'unit',
      'price',(t.obj->>'unit_price')::numeric,
      'qty',(t.obj->>'qty')::numeric
    ) ORDER BY t.ord)
    FROM jsonb_array_elements(COALESCE(v_pricing->'lines','[]'::jsonb)) WITH ORDINALITY AS t(obj,ord)
  ),'[]'::jsonb)
  ||
  COALESCE((
    SELECT jsonb_agg(jsonb_build_object(
      'code',t.obj->>'item_code',
      'name',t.obj->>'name',
      'unit',t.obj->>'unit',
      'price',0,
      'qty',(t.obj->>'qty')::numeric
    ) ORDER BY t.ord)
    FROM jsonb_array_elements(COALESCE(v_pricing->'free_items','[]'::jsonb)) WITH ORDINALITY AS t(obj,ord)
  ),'[]'::jsonb);
 IF v_total<0 THEN RAISE EXCEPTION 'Sales total cannot be negative'; END IF;
 FOR item IN SELECT * FROM jsonb_to_recordset(v_effective_items) AS x(code text,name text,unit text,price numeric,qty numeric) LOOP
  SELECT i.id,i.cost_price INTO v_item_id,v_cost_price FROM public.items i where i.company_id=v_company_id and i.item_code=item.code AND coalesce(i.is_active,true)=true LIMIT 1;
  IF v_item_id IS NULL THEN RAISE EXCEPTION 'الصنف غير موجود: %',item.code; END IF;
  IF item.qty IS NULL OR item.qty<=0 THEN RAISE EXCEPTION 'كمية الصنف غير صالحة: %',item.code; END IF;
  IF coalesce(item.price,0)<0 THEN RAISE EXCEPTION 'سعر الصنف غير صالح: %',item.code; END IF;
  v_gross_amount:=v_gross_amount+(coalesce(item.price,0)*coalesce(item.qty,0));
 END LOOP;

 IF v_order_status='Invoiced' THEN
  v_decision_payload:=jsonb_build_object('entity_type','ORDER','customer_id',v_customer_uuid,'branch_id',v_branch_uuid,'payment_type',coalesce(p_order_header->>'paymentType','أجل'),'total_amount',v_total,'gross_amount',v_gross_amount,'order_discount_amount',v_discount_amount,
    'items',(SELECT coalesce(jsonb_agg(jsonb_build_object('item_id',i.id,'item_code',i.item_code,'qty',x.qty,'unit_price',x.price,'discount_percent',0)),'[]'::jsonb)
             FROM jsonb_to_recordset(v_effective_items) AS x(code text,name text,unit text,price numeric,qty numeric)
             JOIN public.items i ON i.company_id=v_company_id AND i.item_code=x.code AND coalesce(i.is_active,true)=true));
  v_decision:=public.sales_decision_engine_atomic(v_company_id,'VALIDATE_ORDER',p_user_email,NULL,v_decision_payload,v_operation_id::text);
  IF coalesce(v_decision->>'decision','BLOCK')='BLOCK' THEN
    RETURN jsonb_build_object('success',false,'decision','BLOCK','blocked',true,'operation_id',v_operation_id,'reasons',coalesce(v_decision->'reasons','[]'::jsonb),'policy_id',v_decision->'policy_id','policy_version',v_decision->'policy_version');
  END IF;
  IF coalesce(v_decision->>'decision','BLOCK')='REQUIRE_APPROVAL' THEN
    RETURN jsonb_build_object('success',false,'decision','REQUIRE_APPROVAL','approval_required',true,'operation_id',v_operation_id,'reasons',coalesce(v_decision->'reasons','[]'::jsonb),'policy_id',v_decision->'policy_id','policy_version',v_decision->'policy_version');
  END IF;
 END IF;

 IF v_existing_order_code IS NOT NULL THEN
   IF v_order_status NOT IN ('Draft','Confirmed') THEN RAISE EXCEPTION 'لا يمكن تعديل الأوردر إلى حالة منفذة'; END IF;
   UPDATE public.orders
   SET customer_id=v_customer_uuid,
       customer_name=p_order_header->>'custName',
       area=coalesce(p_order_header->>'area',''),
       total_amount=v_total,
       original_total_amount=v_total,
       delivery_fee=coalesce((p_order_header->>'deliveryFees')::numeric,0),
       order_status=v_order_status,
       payment_type=coalesce(p_order_header->>'paymentType','أجل'),
       branch_id=v_branch_uuid,
       source=coalesce(p_order_header->>'source',existing_order.source),
       customer_phone=p_order_header->>'customerPhone',
       customer_email=p_order_header->>'customerEmail',
       coupon_code=p_order_header->>'couponCode',
       discount_amount=v_discount_amount,
       notes=p_order_header->>'notes',
       updated_at=now()
   WHERE id=existing_order.id AND company_id=v_company_id;

   DELETE FROM public.order_details WHERE order_id=existing_order.id;

   FOR item IN SELECT * FROM jsonb_to_recordset(v_effective_items) AS x(code text,name text,unit text,price numeric,qty numeric) LOOP
     SELECT i.id INTO v_item_id
     FROM public.items i
     WHERE i.company_id=v_company_id AND i.item_code=item.code AND coalesce(i.is_active,true)=true
     LIMIT 1;
     IF v_item_id IS NULL THEN RAISE EXCEPTION 'الصنف غير موجود: %',item.code; END IF;
     INSERT INTO public.order_details(id,order_id,item_id,item_code,item_name,unit,unit_price,qty)
     VALUES(gen_random_uuid(),existing_order.id,v_item_id,item.code,item.name,coalesce(item.unit,'حبة'),item.price,item.qty);
   END LOOP;

   RETURN jsonb_build_object(
     'success',true,
     'duplicate',false,
     'updated',true,
     'orderID',existing_order.order_code,
     'order_id',existing_order.id,
     'company_id',v_company_id,
     'operation_id',v_operation_id,
     'source',coalesce(p_order_header->>'source',existing_order.source)
   );
 END IF;

 PERFORM pg_advisory_xact_lock(hashtext('rawaea:sales-order-code:'||v_company_id::text));
 SELECT o.order_code INTO last_code FROM public.orders o WHERE o.company_id=v_company_id ORDER BY o.created_at DESC,o.id DESC LIMIT 1;
 IF last_code~'^ORD-[0-9]+$' THEN next_serial:=greatest(1001,(regexp_replace(last_code,'^ORD-',''))::integer+1); END IF;
 v_order_code:='ORD-'||next_serial::text;
 INSERT INTO public.orders(id,company_id,operation_id,order_code,order_date,customer_id,customer_name,area,total_amount,original_total_amount,delivery_fee,order_status,payment_type,branch_id,shift_id,device_id,created_by,source,customer_phone,customer_email,coupon_code,discount_amount,notes)
 VALUES(gen_random_uuid(),v_company_id,v_operation_id,v_order_code,current_date,v_customer_uuid,p_order_header->>'custName',coalesce(p_order_header->>'area',''),v_total,v_total,coalesce((p_order_header->>'deliveryFees')::numeric,0),v_order_status,coalesce(p_order_header->>'paymentType','أجل'),v_branch_uuid,NULLIF(p_order_header->>'shift_id','')::uuid,CASE WHEN lower(coalesce(p_order_header->>'source',''))='pos' THEN NULLIF(p_order_header->>'device_id','') ELSE NULL END,p_user_email,coalesce(p_order_header->>'source','pos'),p_order_header->>'customerPhone',p_order_header->>'customerEmail',p_order_header->>'couponCode',v_discount_amount,p_order_header->>'notes') RETURNING id INTO v_order_id;
 FOR item IN SELECT * FROM jsonb_to_recordset(v_effective_items) AS x(code text,name text,unit text,price numeric,qty numeric) LOOP
  SELECT i.id,i.cost_price INTO v_item_id,v_cost_price FROM public.items i where i.company_id=v_company_id and i.item_code=item.code AND coalesce(i.is_active,true)=true LIMIT 1;
  INSERT INTO public.order_details(id,order_id,item_id,item_code,item_name,unit,unit_price,qty) VALUES(gen_random_uuid(),v_order_id,v_item_id,item.code,item.name,coalesce(item.unit,'حبة'),item.price,item.qty);
 END LOOP;
 IF v_order_status='Invoiced' THEN
  v_is_van:=(coalesce(p_branch_code,'MAIN') LIKE 'VAN-%');
  FOR item IN SELECT * FROM jsonb_to_recordset(v_effective_items) AS x(code text,name text,unit text,price numeric,qty numeric) LOOP
   SELECT i.id,i.cost_price INTO v_item_id,v_cost_price FROM public.items i where i.company_id=v_company_id and i.item_code=item.code AND coalesce(i.is_active,true)=true LIMIT 1;
   PERFORM public.post_stock_movement(v_company_id,CASE WHEN v_is_van THEN 'VanSale' ELSE 'POSSale' END,v_branch_uuid,NULL,v_item_id,item.qty,v_order_code,v_order_code,p_user_email,'SalesInvoice:'||v_company_id::text||':'||v_order_id::text||':'||v_item_id::text);
   v_total_cogs:=v_total_cogs+(item.qty*coalesce(v_cost_price,0));
  END LOOP;
 END IF;
 IF v_order_status='Invoiced' THEN
    FOR item IN SELECT value AS promo FROM jsonb_array_elements(COALESCE(v_pricing->'promotions','[]'::jsonb)) LOOP
      PERFORM public.record_promotion_redemption(
        v_company_id,
        (item.promo->>'promotion_id')::uuid,
        v_order_id,
        v_customer_uuid,
        coalesce(p_order_header->>'source',CASE WHEN p_branch_code LIKE 'VAN-%' THEN 'van-sales' ELSE 'pos' END),
        nullif(p_order_header->>'couponCode',''),
        greatest(coalesce((item.promo->>'discount_amount')::numeric,0),0),
        COALESCE(v_pricing->'free_items','[]'::jsonb),
        'SalesPromotion:'||v_operation_id::text||':'||(item.promo->>'promotion_id'),
        p_user_email
      );
    END LOOP;
  END IF;

  IF v_order_status='Invoiced' AND v_total>0 THEN
  v_is_cash:=coalesce(p_order_header->>'paymentType','أجل')='نقدي';
  IF v_is_cash THEN
   IF lower(coalesce(p_order_header->>'source',CASE WHEN p_branch_code LIKE 'VAN-%' THEN 'van-sales' ELSE 'pos' END)) = 'pos' THEN
     SELECT s.treasury_id INTO v_treasury_id
     FROM public.orders o
     JOIN public.pos_shifts s
       ON s.id = o.shift_id
      AND s.company_id = o.company_id
      AND s.branch_id = o.branch_id
      AND s.status = 'open'
     JOIN public.pos_terminals pt
       ON pt.id = s.terminal_id
      AND pt.company_id = s.company_id
      AND pt.branch_id = s.branch_id
      AND pt.treasury_id = s.treasury_id
      AND pt.is_active IS TRUE
      AND (NULLIF(o.device_id, '') IS NULL OR pt.terminal_code = o.device_id)
     JOIN public.treasury tr
       ON tr.id = s.treasury_id
      AND tr.company_id = s.company_id
      AND tr.is_active IS TRUE
     WHERE o.id = v_order_id
       AND o.company_id = v_company_id
       AND lower(coalesce(o.source,'')) = 'pos'
       AND s.cashier_user_id = (
         SELECT u.id FROM public.users u
         WHERE u.company_id = v_company_id
           AND lower(u.email) = lower(p_user_email)
           AND coalesce(u.status,'Active') = 'Active'
         LIMIT 1
       )
     FOR SHARE OF s, pt, tr;
     IF v_treasury_id IS NULL THEN
       RAISE EXCEPTION 'POS_SHIFT_TREASURY_MAPPING_REQUIRED: invoice must use the active terminal shift treasury';
     END IF;
   ELSE
     SELECT count(*),(array_agg(t.id ORDER BY t.id))[1] INTO v_treasury_count,v_treasury_id FROM public.treasury t WHERE t.company_id=v_company_id AND coalesce(t.is_active,true)=true;
     IF v_treasury_count<>1 OR v_treasury_id IS NULL THEN RAISE EXCEPTION 'POS_CASH_TREASURY_MAPPING_REQUIRED: expected exactly one active treasury for company'; END IF;
   END IF;
   v_cash_result:=public.post_cash_receipt_atomic(v_company_id,v_operation_id,v_treasury_id,v_cash_account,v_sales_account,v_total,current_date,v_order_code,'فاتورة نقطة بيع – '||v_order_code||CASE WHEN v_is_van THEN ' (Van Sales)' ELSE '' END,p_user_email,p_order_header->>'custName','POS',v_order_id,p_order_header->>'notes',NULL);
   IF v_total_cogs>0 THEN v_cogs_operation_id:=gen_random_uuid(); v_cogs_journal:=public.post_journal_entry(v_company_id,v_cogs_operation_id,current_date,CASE WHEN v_is_van THEN 'VanSales' ELSE 'POS_Sale_COGS' END,v_order_code,'تكلفة مبيعات نقطة بيع – '||v_order_code,p_user_email,jsonb_build_array(jsonb_build_object('account_id',v_cogs_account,'account_name',v_cogs_name,'debit',v_total_cogs,'credit',0),jsonb_build_object('account_id',v_inventory_account,'account_name',v_inventory_name,'debit',0,'credit',v_total_cogs)),NULL,now(),v_order_id); END IF;
  ELSE
   v_sales_journal:=public.post_journal_entry(v_company_id,v_operation_id,current_date,CASE WHEN v_is_van THEN 'VanSales' ELSE 'POS_Sale' END,v_order_code,'فاتورة نقطة بيع – '||v_order_code||CASE WHEN v_is_van THEN ' (Van Sales)' ELSE '' END,p_user_email,CASE WHEN v_total_cogs>0 THEN jsonb_build_array(jsonb_build_object('account_id',v_ar_account,'account_name',v_ar_name,'debit',v_total,'credit',0),jsonb_build_object('account_id',v_sales_account,'account_name',v_sales_name,'debit',0,'credit',v_total),jsonb_build_object('account_id',v_cogs_account,'account_name',v_cogs_name,'debit',v_total_cogs,'credit',0),jsonb_build_object('account_id',v_inventory_account,'account_name',v_inventory_name,'debit',0,'credit',v_total_cogs)) ELSE jsonb_build_array(jsonb_build_object('account_id',v_ar_account,'account_name',v_ar_name,'debit',v_total,'credit',0),jsonb_build_object('account_id',v_sales_account,'account_name',v_sales_name,'debit',0,'credit',v_total)) END,NULL,now(),v_order_id);
   IF v_customer_uuid IS NOT NULL THEN v_customer_ledger_operation_id:=gen_random_uuid(); v_customer_ledger:=public.post_customer_ledger_entry(v_company_id,v_customer_ledger_operation_id,v_customer_uuid,current_date,v_order_code,'فاتورة نقطة بيع – '||v_order_code,v_total,0,current_date,p_user_email); END IF;
  END IF;
  IF v_is_van AND NOT v_is_cash THEN PERFORM public.post_driver_ledger_entry(v_company_id,v_operation_id,p_user_email,current_date,v_order_code,'بيع آجل – '||v_order_code,v_total,0); END IF;
 END IF;
 UPDATE public.sales_decision_evaluations SET entity_id=v_order_id WHERE company_id=v_company_id AND operation_id=v_operation_id::text::text;
 UPDATE public.app_settings SET order_serial=next_serial WHERE id=v_settings_id AND company_id=v_company_id;
 RETURN jsonb_build_object('success',true,'duplicate',false,'orderID',v_order_code,'order_id',v_order_id,'total_cogs',v_total_cogs,'company_id',v_company_id,'operation_id',v_operation_id,'sales_decision',v_decision,'cash_posted',coalesce(v_is_cash,false),'cash_result',v_cash_result,'sales_journal',v_sales_journal,'cogs_journal',v_cogs_journal,'customer_ledger',v_customer_ledger);
END; $function$


CREATE OR REPLACE FUNCTION public.pos_assign_order_shift()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_cashier_user_id uuid;
  v_shift public.pos_shifts%ROWTYPE;
  v_terminal public.pos_terminals%ROWTYPE;
BEGIN
  IF lower(btrim(COALESCE(NEW.source, ''))) <> 'pos' THEN
    IF NEW.shift_id IS NOT NULL THEN
      RAISE EXCEPTION 'POS_SHIFT_CAN_ONLY_ATTACH_TO_POS_ORDERS';
    END IF;
    RETURN NEW;
  END IF;

  SELECT u.id INTO v_cashier_user_id
  FROM public.users u
  WHERE u.company_id = NEW.company_id
    AND lower(u.email) = lower(COALESCE(NEW.created_by, ''))
    AND COALESCE(u.status, 'Active') = 'Active'
  LIMIT 1;

  IF v_cashier_user_id IS NULL OR NEW.branch_id IS NULL THEN
    RAISE EXCEPTION 'POS_ACTIVE_CASHIER_AND_BRANCH_REQUIRED';
  END IF;

  IF NULLIF(btrim(COALESCE(NEW.device_id, '')), '') IS NOT NULL THEN
    SELECT * INTO v_terminal
    FROM public.pos_terminals t
    WHERE t.company_id = NEW.company_id
      AND t.terminal_code = NEW.device_id
      AND t.branch_id = NEW.branch_id
      AND t.is_active IS TRUE
      AND t.treasury_id IS NOT NULL
    FOR SHARE;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'POS_TERMINAL_NOT_BOUND_TO_BRANCH_TREASURY';
    END IF;
  END IF;

  IF NEW.shift_id IS NOT NULL THEN
    IF v_terminal.id IS NULL THEN
      RAISE EXCEPTION 'POS_TERMINAL_IDENTITY_REQUIRED_FOR_EXPLICIT_SHIFT';
    END IF;
    SELECT * INTO v_shift
    FROM public.pos_shifts s
    WHERE s.id = NEW.shift_id
      AND s.company_id = NEW.company_id
      AND s.branch_id = NEW.branch_id
      AND s.status = 'open'
      AND s.cashier_user_id = v_cashier_user_id
      AND s.terminal_id = v_terminal.id
      AND s.treasury_id = v_terminal.treasury_id
    FOR SHARE;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'POS_SHIFT_INVALID_OR_NOT_OWNED_OR_TERMINAL_MISMATCH';
    END IF;
    RETURN NEW;
  END IF;

  IF v_terminal.id IS NOT NULL THEN
    SELECT s.* INTO v_shift
    FROM public.pos_shifts s
    WHERE s.company_id = NEW.company_id
      AND s.branch_id = NEW.branch_id
      AND s.cashier_user_id = v_cashier_user_id
      AND s.status = 'open'
      AND s.terminal_id = v_terminal.id
      AND s.treasury_id = v_terminal.treasury_id
    ORDER BY s.opened_at DESC
    LIMIT 1
    FOR SHARE;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'POS_OPEN_SHIFT_REQUIRED_FOR_THIS_TERMINAL';
    END IF;
    NEW.shift_id := v_shift.id;
    RETURN NEW;
  END IF;

  -- Backward-compatible path for older POS clients; new clients must send device_id.
  SELECT * INTO v_shift
  FROM public.pos_shifts s
  WHERE s.company_id = NEW.company_id
    AND s.branch_id = NEW.branch_id
    AND s.cashier_user_id = v_cashier_user_id
    AND s.status = 'open'
  ORDER BY s.opened_at DESC
  LIMIT 1
  FOR SHARE;

  IF FOUND THEN NEW.shift_id := v_shift.id; END IF;
  RETURN NEW;
END;
$function$;
