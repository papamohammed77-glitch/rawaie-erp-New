BEGIN;

CREATE OR REPLACE FUNCTION public.purchase_create_quotation_atomic(p_company_id uuid, p_supplier_id uuid, p_rfq_id uuid, p_valid_until date, p_currency text, p_created_by text, p_items jsonb, p_operation_id text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE qid uuid; code text; x jsonb; im items%rowtype; q purchase_quotations%rowtype; rfq purchase_rfqs%rowtype; sub numeric:=0; disc numeric:=0; tax numeric:=0; tot numeric:=0;
BEGIN
  IF NULLIF(btrim(p_operation_id),'') IS NULL THEN RAISE EXCEPTION 'PURCHASE_OPERATION_ID_REQUIRED'; END IF;
  SELECT * INTO q FROM purchase_quotations WHERE company_id=p_company_id AND operation_id=p_operation_id FOR UPDATE;
  IF FOUND THEN RETURN jsonb_build_object('success',true,'duplicate',true,'id',q.id,'code',q.quotation_code,'status',q.status); END IF;
  IF NOT EXISTS(SELECT 1 FROM suppliers WHERE id=p_supplier_id AND company_id=p_company_id AND is_active) THEN RAISE EXCEPTION 'PURCHASE_SUPPLIER_INVALID'; END IF;
  IF p_rfq_id IS NOT NULL THEN
    SELECT * INTO rfq FROM purchase_rfqs WHERE id=p_rfq_id AND company_id=p_company_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'PURCHASE_RFQ_NOT_FOUND'; END IF;
    IF NOT EXISTS(SELECT 1 FROM purchase_rfq_suppliers rs WHERE rs.rfq_id=p_rfq_id AND rs.supplier_id=p_supplier_id) THEN RAISE EXCEPTION 'PURCHASE_SUPPLIER_NOT_INVITED_TO_RFQ'; END IF;
  END IF;
  code:=purchase_next_code(p_company_id,'quotation');
  INSERT INTO purchase_quotations(company_id,quotation_code,supplier_id,rfq_id,valid_until,currency,status,created_by,operation_id) VALUES(p_company_id,code,p_supplier_id,p_rfq_id,p_valid_until,COALESCE(p_currency,'SAR'),'Submitted',p_created_by,p_operation_id) RETURNING id INTO qid;
  FOR x IN SELECT value FROM jsonb_array_elements(COALESCE(p_items,'[]'::jsonb)) LOOP
    SELECT * INTO im FROM items WHERE item_code=btrim(x->>'item_code');
    IF NOT FOUND OR COALESCE((x->>'qty')::numeric,0)<=0 OR COALESCE((x->>'unit_price')::numeric,0)<0 THEN RAISE EXCEPTION 'PURCHASE_QUOTATION_ITEM_INVALID:%',x->>'item_code'; END IF;
    sub:=sub+((x->>'qty')::numeric*(x->>'unit_price')::numeric); disc:=disc+((x->>'qty')::numeric*(x->>'unit_price')::numeric*COALESCE((x->>'discount_percent')::numeric,0)/100); tax:=tax+((((x->>'qty')::numeric*(x->>'unit_price')::numeric)-((x->>'qty')::numeric*(x->>'unit_price')::numeric*COALESCE((x->>'discount_percent')::numeric,0)/100))*COALESCE((x->>'tax_rate')::numeric,0)/100); tot:=tot+((((x->>'qty')::numeric*(x->>'unit_price')::numeric)-((x->>'qty')::numeric*(x->>'unit_price')::numeric*COALESCE((x->>'discount_percent')::numeric,0)/100))*(1+COALESCE((x->>'tax_rate')::numeric,0)/100));
    INSERT INTO purchase_quotation_details(quotation_id,item_id,item_code,item_name,unit,qty,unit_price,discount_percent,discount_amount,tax_rate,tax_amount,line_total) VALUES(qid,im.id,im.item_code,im.name,im.unit,(x->>'qty')::numeric,(x->>'unit_price')::numeric,COALESCE((x->>'discount_percent')::numeric,0),((x->>'qty')::numeric*(x->>'unit_price')::numeric*COALESCE((x->>'discount_percent')::numeric,0)/100),COALESCE((x->>'tax_rate')::numeric,0),((((x->>'qty')::numeric*(x->>'unit_price')::numeric)-((x->>'qty')::numeric*(x->>'unit_price')::numeric*COALESCE((x->>'discount_percent')::numeric,0)/100))*COALESCE((x->>'tax_rate')::numeric,0)/100),(((x->>'qty')::numeric*(x->>'unit_price')::numeric)-((x->>'qty')::numeric*(x->>'unit_price')::numeric*COALESCE((x->>'discount_percent')::numeric,0)/100))*(1+COALESCE((x->>'tax_rate')::numeric,0)/100));
  END LOOP;
  UPDATE purchase_quotations SET subtotal=sub,discount_amount=disc,tax_amount=tax,total_amount=tot WHERE id=qid;
  RETURN jsonb_build_object('success',true,'id',qid,'code',code,'status','Submitted','total_amount',tot);
END
$function$;

CREATE OR REPLACE FUNCTION public.purchase_create_invoice_atomic(p_company_id uuid, p_supplier_id uuid, p_purchase_order_id uuid, p_branch_id uuid, p_due_date date, p_currency text, p_created_by text, p_items jsonb, p_operation_id text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE iid uuid; code text; x jsonb; im items%rowtype; inv purchase_invoices%rowtype; po purchase_orders%rowtype; total numeric:=0; require_receiving boolean:=false;
BEGIN
  IF NULLIF(btrim(p_operation_id),'') IS NULL THEN RAISE EXCEPTION 'PURCHASE_OPERATION_ID_REQUIRED'; END IF;
  SELECT * INTO inv FROM purchase_invoices WHERE company_id=p_company_id AND operation_id=p_operation_id FOR UPDATE;
  IF FOUND THEN RETURN jsonb_build_object('success',true,'duplicate',true,'id',inv.id,'code',inv.invoice_code,'status',inv.status); END IF;
  IF NOT EXISTS(SELECT 1 FROM suppliers WHERE id=p_supplier_id AND company_id=p_company_id AND is_active) THEN RAISE EXCEPTION 'PURCHASE_SUPPLIER_INVALID'; END IF;
  IF p_branch_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM branches WHERE id=p_branch_id AND company_id=p_company_id) THEN RAISE EXCEPTION 'PURCHASE_BRANCH_INVALID'; END IF;
  SELECT COALESCE(require_receiving_before_invoice,false) INTO require_receiving FROM purchase_settings WHERE company_id=p_company_id;
  IF p_purchase_order_id IS NOT NULL THEN
    SELECT * INTO po FROM purchase_orders WHERE id=p_purchase_order_id AND company_id=p_company_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'PURCHASE_PO_NOT_FOUND'; END IF;
    IF po.supplier_id IS DISTINCT FROM p_supplier_id THEN RAISE EXCEPTION 'PURCHASE_PO_SUPPLIER_MISMATCH'; END IF;
    IF require_receiving AND po.status NOT IN ('Partially Received','Received') THEN RAISE EXCEPTION 'PURCHASE_RECEIVING_REQUIRED_BEFORE_INVOICE'; END IF;
  END IF;
  code:=purchase_next_code(p_company_id,'invoice');
  INSERT INTO purchase_invoices(company_id,invoice_code,supplier_id,purchase_order_id,branch_id,due_date,currency,status,created_by,operation_id) VALUES(p_company_id,code,p_supplier_id,p_purchase_order_id,p_branch_id,p_due_date,COALESCE(p_currency,'SAR'),'Draft',p_created_by,p_operation_id) RETURNING id INTO iid;
  FOR x IN SELECT value FROM jsonb_array_elements(COALESCE(p_items,'[]'::jsonb)) LOOP
    SELECT * INTO im FROM items WHERE item_code=btrim(x->>'item_code');
    IF NOT FOUND OR COALESCE((x->>'qty')::numeric,0)<=0 OR COALESCE((x->>'unit_price')::numeric,0)<0 THEN RAISE EXCEPTION 'PURCHASE_INVOICE_ITEM_INVALID:%',x->>'item_code'; END IF;
    INSERT INTO purchase_invoice_details(invoice_id,item_id,item_code,item_name,unit,qty,unit_price,discount_percent,discount_amount,tax_rate,tax_amount,line_total) VALUES(iid,im.id,im.item_code,im.name,im.unit,(x->>'qty')::numeric,(x->>'unit_price')::numeric,COALESCE((x->>'discount_percent')::numeric,0),((x->>'qty')::numeric*(x->>'unit_price')::numeric*COALESCE((x->>'discount_percent')::numeric,0)/100),COALESCE((x->>'tax_rate')::numeric,0),((((x->>'qty')::numeric*(x->>'unit_price')::numeric)*(1-COALESCE((x->>'discount_percent')::numeric,0)/100))*COALESCE((x->>'tax_rate')::numeric,0)/100),(((x->>'qty')::numeric*(x->>'unit_price')::numeric)*(1-COALESCE((x->>'discount_percent')::numeric,0)/100))*(1+COALESCE((x->>'tax_rate')::numeric,0)/100));
    total:=total+(((x->>'qty')::numeric*(x->>'unit_price')::numeric)*(1-COALESCE((x->>'discount_percent')::numeric,0)/100))*(1+COALESCE((x->>'tax_rate')::numeric,0)/100);
  END LOOP;
  UPDATE purchase_invoices SET subtotal=(SELECT COALESCE(SUM(qty*unit_price),0) FROM purchase_invoice_details WHERE invoice_id=iid),discount_amount=(SELECT COALESCE(SUM(discount_amount),0) FROM purchase_invoice_details WHERE invoice_id=iid),tax_amount=(SELECT COALESCE(SUM(tax_amount),0) FROM purchase_invoice_details WHERE invoice_id=iid),total_amount=total WHERE id=iid;
  RETURN jsonb_build_object('success',true,'id',iid,'code',code,'status','Draft','total_amount',total);
END
$function$;

CREATE OR REPLACE FUNCTION public.purchase_post_payment_atomic(p_company_id uuid, p_supplier_id uuid, p_treasury_id uuid, p_amount numeric, p_entry_date date, p_reference text, p_actor text, p_invoice_ids jsonb, p_operation_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE cash_acc uuid; sup_acc uuid; paycode text; cash_result jsonb; pay_id uuid; x record; remaining numeric; prev numeric; require_invoice boolean:=true;
BEGIN
  IF p_operation_id IS NULL OR p_amount IS NULL OR p_amount<=0 THEN RAISE EXCEPTION 'PURCHASE_PAYMENT_INVALID'; END IF;
  IF NOT EXISTS(SELECT 1 FROM suppliers WHERE id=p_supplier_id AND company_id=p_company_id) THEN RAISE EXCEPTION 'PURCHASE_SUPPLIER_INVALID'; END IF;
  IF NOT EXISTS(SELECT 1 FROM treasury WHERE id=p_treasury_id AND company_id=p_company_id AND is_active) THEN RAISE EXCEPTION 'PURCHASE_TREASURY_INVALID'; END IF;
  SELECT COALESCE(require_invoice_before_payment,true) INTO require_invoice FROM purchase_settings WHERE company_id=p_company_id;
  IF require_invoice AND (p_invoice_ids IS NULL OR jsonb_typeof(p_invoice_ids)<>'array' OR jsonb_array_length(p_invoice_ids)=0) THEN RAISE EXCEPTION 'PURCHASE_INVOICE_REQUIRED_BEFORE_PAYMENT'; END IF;
  IF EXISTS(SELECT 1 FROM purchase_payments WHERE company_id=p_company_id AND operation_id=p_operation_id) THEN SELECT id,payment_code INTO pay_id,paycode FROM purchase_payments WHERE company_id=p_company_id AND operation_id=p_operation_id; RETURN jsonb_build_object('success',true,'duplicate',true,'id',pay_id,'code',paycode,'status','Posted'); END IF;
  SELECT id INTO cash_acc FROM chart_of_accounts WHERE company_id=p_company_id AND account_code='121' AND is_active LIMIT 1;
  SELECT id INTO sup_acc FROM chart_of_accounts WHERE company_id=p_company_id AND account_code='211' AND is_active LIMIT 1;
  IF cash_acc IS NULL OR sup_acc IS NULL THEN RAISE EXCEPTION 'PURCHASE_ACCOUNTS_NOT_CONFIGURED'; END IF;
  IF COALESCE((SELECT SUM((z->>'allocated_amount')::numeric) FROM jsonb_array_elements(COALESCE(p_invoice_ids,'[]'::jsonb)) z),0)>p_amount THEN RAISE EXCEPTION 'PURCHASE_PAYMENT_ALLOCATIONS_EXCEED_PAYMENT'; END IF;
  paycode:=purchase_next_code(p_company_id,'payment');
  cash_result:=post_cash_payment_atomic(p_company_id,p_operation_id,p_treasury_id,cash_acc,sup_acc,p_amount,p_entry_date,p_reference,'سداد مشتريات',p_actor,(SELECT name FROM suppliers WHERE id=p_supplier_id),'PurchasePayment',NULL,NULL,paycode);
  pay_id:=gen_random_uuid();
  INSERT INTO purchase_payments(id,company_id,payment_code,supplier_id,treasury_id,payment_date,amount,status,reference,created_by,operation_id,cash_box_id) VALUES(pay_id,p_company_id,paycode,p_supplier_id,p_treasury_id,p_entry_date,p_amount,'Posted',p_reference,p_actor,p_operation_id,(cash_result->>'cash_box_id')::uuid);
  FOR x IN SELECT * FROM jsonb_to_recordset(COALESCE(p_invoice_ids,'[]'::jsonb)) z(invoice_id uuid,allocated_amount numeric) LOOP
    SELECT GREATEST(total_amount-paid_amount,0) INTO remaining FROM purchase_invoices WHERE id=x.invoice_id AND company_id=p_company_id AND supplier_id=p_supplier_id AND status<>'Cancelled' FOR UPDATE;
    IF remaining IS NULL OR x.allocated_amount<=0 OR x.allocated_amount>remaining THEN RAISE EXCEPTION 'PURCHASE_PAYMENT_ALLOCATION_INVALID'; END IF;
    INSERT INTO purchase_payment_allocations(company_id,payment_id,invoice_id,allocated_amount) VALUES(p_company_id,pay_id,x.invoice_id,x.allocated_amount);
    UPDATE purchase_invoices SET paid_amount=paid_amount+x.allocated_amount,status=CASE WHEN paid_amount+x.allocated_amount>=total_amount THEN 'Paid' ELSE 'PartiallyPaid' END WHERE id=x.invoice_id;
  END LOOP;
  SELECT COALESCE(balance,0) INTO prev FROM supplier_ledger WHERE supplier_id=p_supplier_id ORDER BY created_at DESC LIMIT 1;
  INSERT INTO supplier_ledger(supplier_id,entry_date,reference,description,debit,credit,balance,user_email) VALUES(p_supplier_id,p_entry_date,paycode,'سداد مشتريات - '||COALESCE(p_reference,paycode),p_amount,0,prev-p_amount,p_actor);
  RETURN jsonb_build_object('success',true,'id',pay_id,'code',paycode,'status','Posted','cash_box_id',cash_result->'cash_box_id');
END
$function$;

COMMIT;
