
-- RAWAEA ERP — SupplierReturn business-contract / accounting closure
-- Applied in Production: close_supplier_return_contract_accounting_20260927
-- No new Edge Function. Authenticated RPC path only.

ALTER TABLE public.stock_vouchers
  ADD COLUMN IF NOT EXISTS return_reason_id uuid,
  ADD COLUMN IF NOT EXISTS supplier_credit_note_ref text,
  ADD COLUMN IF NOT EXISTS supplier_rma_ref text,
  ADD COLUMN IF NOT EXISTS purchase_invoice_id uuid,
  ADD COLUMN IF NOT EXISTS purchase_order_id uuid,
  ADD COLUMN IF NOT EXISTS return_to_address text,
  ADD COLUMN IF NOT EXISTS inspection_status text NOT NULL DEFAULT 'not_required',
  ADD COLUMN IF NOT EXISTS disposition text NOT NULL DEFAULT 'return_to_supplier',
  ADD COLUMN IF NOT EXISTS return_currency text NOT NULL DEFAULT 'SAR',
  ADD COLUMN IF NOT EXISTS return_subtotal numeric(14,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS return_discount_amount numeric(14,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS return_tax_amount numeric(14,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS return_total_amount numeric(14,2) NOT NULL DEFAULT 0;

ALTER TABLE public.stock_voucher_details
  ADD COLUMN IF NOT EXISTS gross_amount numeric(14,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS discount_percent numeric(8,4) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS discount_amount numeric(14,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS taxable_amount numeric(14,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS tax_code_id uuid,
  ADD COLUMN IF NOT EXISTS tax_rate numeric(8,4) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS tax_amount numeric(14,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS net_amount numeric(14,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS line_total numeric(14,2) NOT NULL DEFAULT 0;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='stock_vouchers_return_reason_fk') THEN
    ALTER TABLE public.stock_vouchers ADD CONSTRAINT stock_vouchers_return_reason_fk FOREIGN KEY (return_reason_id) REFERENCES public.return_reasons(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='stock_vouchers_purchase_invoice_fk') THEN
    ALTER TABLE public.stock_vouchers ADD CONSTRAINT stock_vouchers_purchase_invoice_fk FOREIGN KEY (purchase_invoice_id) REFERENCES public.purchase_invoices(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='stock_vouchers_purchase_order_fk') THEN
    ALTER TABLE public.stock_vouchers ADD CONSTRAINT stock_vouchers_purchase_order_fk FOREIGN KEY (purchase_order_id) REFERENCES public.purchase_orders(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='stock_vouchers_inspection_status_ck') THEN
    ALTER TABLE public.stock_vouchers ADD CONSTRAINT stock_vouchers_inspection_status_ck CHECK (inspection_status IN ('not_required','pending','passed','failed'));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='stock_vouchers_disposition_ck') THEN
    ALTER TABLE public.stock_vouchers ADD CONSTRAINT stock_vouchers_disposition_ck CHECK (disposition IN ('return_to_supplier','replacement_requested','credit_requested','rejected'));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='stock_vouchers_return_amounts_ck') THEN
    ALTER TABLE public.stock_vouchers ADD CONSTRAINT stock_vouchers_return_amounts_ck CHECK (return_subtotal >= 0 AND return_discount_amount >= 0 AND return_tax_amount >= 0 AND return_total_amount >= 0);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='stock_voucher_details_return_amounts_ck') THEN
    ALTER TABLE public.stock_voucher_details ADD CONSTRAINT stock_voucher_details_return_amounts_ck CHECK (gross_amount >= 0 AND discount_percent >= 0 AND discount_amount >= 0 AND taxable_amount >= 0 AND tax_rate >= 0 AND tax_amount >= 0 AND net_amount >= 0 AND line_total >= 0);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_stock_vouchers_purchase_invoice_id ON public.stock_vouchers(company_id,purchase_invoice_id) WHERE purchase_invoice_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_stock_vouchers_purchase_order_id ON public.stock_vouchers(company_id,purchase_order_id) WHERE purchase_order_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_stock_vouchers_return_reason_id ON public.stock_vouchers(company_id,return_reason_id) WHERE return_reason_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_finance_tax_transactions_supplier_return
  ON public.finance_tax_transactions(company_id,operation_id,tax_code_id,source_type)
  WHERE source_type='SupplierReturn';

INSERT INTO public.return_reasons(company_id,reason_code,reason_name,reason_category,is_active)
SELECT '00000000-0000-0000-0000-000000000001',x.code,x.name,x.category,true
FROM (VALUES
 ('SR001','تالف / جودة غير مطابقة','damaged'),
 ('SR002','صنف أو كمية غير مطابقة','wrong_item'),
 ('SR003','منتهي أو قريب انتهاء الصلاحية','expired'),
 ('SR004','فائض / شراء غير مطلوب','excess'),
 ('SR005','رفض المورد / اتفاق تجاري','commercial')
) x(code,name,category)
WHERE NOT EXISTS (
  SELECT 1 FROM public.return_reasons r
  WHERE r.company_id='00000000-0000-0000-0000-000000000001' AND r.reason_code=x.code
);

INSERT INTO public.chart_of_accounts
  (company_id,account_code,account_name,account_type,parent_account_id,normal_balance,is_active,notes)
SELECT '00000000-0000-0000-0000-000000000001','126','ضريبة القيمة المضافة القابلة للاسترداد','asset','5ed325b4-4a81-4907-be64-e35b534a82cb','debit',true,'حساب ضريبة مشتريات قابل للعكس عند مرتجع المورد'
WHERE NOT EXISTS (
  SELECT 1 FROM public.chart_of_accounts WHERE company_id='00000000-0000-0000-0000-000000000001' AND account_code='126'
);

INSERT INTO public.finance_tax_codes(company_id,code,name,rate,purchase_account_id,is_active)
SELECT '00000000-0000-0000-0000-000000000001','VAT15-PURCHASE','ضريبة مشتريات 15%',15,coa.id,true
FROM public.chart_of_accounts coa
WHERE coa.company_id='00000000-0000-0000-0000-000000000001' AND coa.account_code='126' AND coa.is_active=true
AND NOT EXISTS (
  SELECT 1 FROM public.finance_tax_codes tc WHERE tc.company_id='00000000-0000-0000-0000-000000000001' AND tc.code='VAT15-PURCHASE'
);

CREATE OR REPLACE FUNCTION public.sync_supplier_accounts_payable_from_ledger()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='public'
AS $function$
DECLARE
  v_supplier_id uuid:=COALESCE(NEW.supplier_id,OLD.supplier_id);
  v_balance numeric:=0;
BEGIN
  IF v_supplier_id IS NULL THEN RETURN COALESCE(NEW,OLD); END IF;
  PERFORM 1 FROM public.suppliers s WHERE s.id=v_supplier_id FOR UPDATE;
  SELECT COALESCE(sl.balance,0) INTO v_balance
  FROM public.supplier_ledger sl
  WHERE sl.supplier_id=v_supplier_id
  ORDER BY sl.created_at DESC,sl.id DESC LIMIT 1;
  UPDATE public.suppliers SET accounts_payable=COALESCE(v_balance,0),updated_at=now() WHERE id=v_supplier_id;
  RETURN COALESCE(NEW,OLD);
END;
$function$;

DROP TRIGGER IF EXISTS trg_sync_supplier_accounts_payable ON public.supplier_ledger;
CREATE TRIGGER trg_sync_supplier_accounts_payable
AFTER INSERT OR UPDATE OR DELETE ON public.supplier_ledger
FOR EACH ROW EXECUTE FUNCTION public.sync_supplier_accounts_payable_from_ledger();

UPDATE public.suppliers s
SET accounts_payable=COALESCE((
  SELECT sl.balance FROM public.supplier_ledger sl
  WHERE sl.supplier_id=s.id ORDER BY sl.created_at DESC,sl.id DESC LIMIT 1
),0),updated_at=now()
WHERE s.accounts_payable IS DISTINCT FROM COALESCE((
  SELECT sl.balance FROM public.supplier_ledger sl
  WHERE sl.supplier_id=s.id ORDER BY sl.created_at DESC,sl.id DESC LIMIT 1
),0);

CREATE OR REPLACE FUNCTION public.assert_supplier_return_contract(p_company_id uuid,p_voucher_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='public'
AS $function$
DECLARE
  v public.stock_vouchers%ROWTYPE;
  v_supplier public.suppliers%ROWTYPE;
  v_bad_count bigint;
  v_total numeric;
BEGIN
  SELECT * INTO v FROM public.stock_vouchers WHERE id=p_voucher_id AND company_id=p_company_id FOR UPDATE;
  IF NOT FOUND OR v.type<>'SupplierReturn' THEN RAISE EXCEPTION 'SupplierReturn document not found'; END IF;
  IF v.to_type<>'Supplier' OR v.to_id IS NULL THEN RAISE EXCEPTION 'مرتجع المورد يفتقد هوية المورد'; END IF;

  SELECT * INTO v_supplier FROM public.suppliers s
  WHERE s.id=v.to_id AND s.company_id=p_company_id AND COALESCE(s.is_active,true) FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'المورد غير موجود أو غير نشط'; END IF;

  IF v.return_reason_id IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.return_reasons r
    WHERE r.id=v.return_reason_id AND (r.company_id=p_company_id OR r.company_id IS NULL) AND r.is_active=true
  ) THEN RAISE EXCEPTION 'سبب المرتجع مطلوب و/أو غير صالح'; END IF;

  IF NULLIF(BTRIM(COALESCE(v.return_to_address,'')),'') IS NULL THEN RAISE EXCEPTION 'عنوان إعادة التوريد للمورد مطلوب'; END IF;
  IF v.inspection_status IN ('pending','failed') THEN RAISE EXCEPTION 'حالة الفحص لا تسمح بإرسال مرتجع المورد'; END IF;
  IF v.disposition='rejected' THEN RAISE EXCEPTION 'قرار disposition يرفض مرتجع المورد؛ لا يمكن إرساله'; END IF;

  SELECT count(*) INTO v_bad_count
  FROM public.stock_voucher_details d JOIN public.items i ON i.id=d.item_id
  WHERE d.voucher_id=v.id
    AND (COALESCE(NULLIF(d.unit_price,0),i.cost_price,0)<=0 OR COALESCE(d.qty,0)<=0 OR COALESCE(d.gross_amount,0)<=0 OR COALESCE(d.net_amount,0)<=0);
  IF v_bad_count>0 THEN RAISE EXCEPTION 'قيمة أحد بنود المرتجع غير مكتملة أو صفرية'; END IF;

  SELECT COALESCE(sum(d.net_amount),0) INTO v_total FROM public.stock_voucher_details d WHERE d.voucher_id=v.id;
  IF v_total<=0 OR COALESCE(v.return_total_amount,0)<=0 THEN RAISE EXCEPTION 'إجمالي مرتجع المورد يجب أن يكون موجبًا'; END IF;

  IF v.purchase_invoice_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.purchase_invoices pi
    WHERE pi.id=v.purchase_invoice_id AND pi.company_id=p_company_id AND pi.supplier_id=v.to_id AND pi.status<>'Cancelled'
  ) THEN RAISE EXCEPTION 'مرجع فاتورة الشراء غير صالح لهذا المورد'; END IF;

  IF v.purchase_order_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.purchase_orders po
    WHERE po.id=v.purchase_order_id AND po.company_id=p_company_id AND po.supplier_id=v.to_id AND po.status<>'Cancelled'
  ) THEN RAISE EXCEPTION 'مرجع أمر الشراء غير صالح لهذا المورد'; END IF;

  IF v.purchase_invoice_id IS NOT NULL AND v.purchase_order_id IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.purchase_invoices pi
    WHERE pi.id=v.purchase_invoice_id AND pi.purchase_order_id IS NOT NULL AND pi.purchase_order_id<>v.purchase_order_id
  ) THEN RAISE EXCEPTION 'فاتورة الشراء لا تتبع أمر الشراء المحدد'; END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION public.save_supplier_return_contract(
  p_company_id uuid,p_voucher_code text,p_contract jsonb,p_operation_id text
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='public','pg_temp'
AS $function$
DECLARE
  v_actor public.users%ROWTYPE;
  v public.stock_vouchers%ROWTYPE;
  v_supplier public.suppliers%ROWTYPE;
  v_invoice public.purchase_invoices%ROWTYPE;
  v_po public.purchase_orders%ROWTYPE;
  v_reason public.return_reasons%ROWTYPE;
  v_op public.erp_operation_registry%ROWTYPE;
  v_item record;
  v_line jsonb;
  v_line_cfg jsonb;
  v_unit_price numeric;
  v_gross numeric;
  v_discount_pct numeric;
  v_discount numeric;
  v_taxable numeric;
  v_tax_rate numeric;
  v_tax numeric;
  v_net numeric;
  v_tax_code_id uuid;
  v_tax_account uuid;
  v_return_reason_id uuid;
  v_purchase_invoice_id uuid;
  v_purchase_order_id uuid;
  v_return_address text;
  v_inspection_status text;
  v_disposition text;
  v_currency text;
  v_subtotal numeric:=0;
  v_discount_total numeric:=0;
  v_tax_total numeric:=0;
  v_total numeric:=0;
  v_existing_payload jsonb;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'غير مصرح'; END IF;
  SELECT * INTO v_actor
  FROM public.users u
  WHERE u.auth_id=auth.uid() AND u.company_id=p_company_id AND COALESCE(u.status,'Active')='Active'
  LIMIT 1;
  IF NOT FOUND THEN RAISE EXCEPTION 'المستخدم الحالي غير صالح ضمن الشركة'; END IF;

  IF NOT (
    COALESCE(v_actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb
    OR COALESCE(v_actor.active_warehouse_role,'')='أذونات'
    OR v_actor.role IN ('مدير مخازن','مشرف مخازن','مدير عام')
  ) THEN RAISE EXCEPTION 'المستخدم غير مخول بإدارة عقد مرتجع المورد'; END IF;

  SELECT * INTO v FROM public.stock_vouchers
  WHERE company_id=p_company_id AND voucher_code=TRIM(p_voucher_code) FOR UPDATE;
  IF NOT FOUND OR v.source<>'Manual' OR v.type<>'SupplierReturn' THEN RAISE EXCEPTION 'إذن SupplierReturn اليدوي غير موجود'; END IF;
  IF v.status<>'Draft' THEN RAISE EXCEPTION 'لا يمكن تعديل عقد مرتجع بعد الإرسال'; END IF;
  IF NULLIF(BTRIM(p_operation_id),'') IS NULL THEN RAISE EXCEPTION 'operation_id مطلوب'; END IF;

  INSERT INTO public.erp_operation_registry(company_id,operation_type,operation_key,request_payload,status)
  VALUES(p_company_id,'save_supplier_return_contract',BTRIM(p_operation_id),COALESCE(p_contract,'{}'::jsonb),'processing')
  ON CONFLICT(company_id,operation_type,operation_key) DO NOTHING;

  SELECT * INTO v_op FROM public.erp_operation_registry
  WHERE company_id=p_company_id AND operation_type='save_supplier_return_contract' AND operation_key=BTRIM(p_operation_id)
  FOR UPDATE;

  IF v_op.status='completed' AND v_op.response_payload IS NOT NULL THEN
    RETURN v_op.response_payload||jsonb_build_object('duplicate',true);
  END IF;

  IF v_op.request_payload IS DISTINCT FROM COALESCE(p_contract,'{}'::jsonb) AND v_op.status='processing' THEN
    RAISE EXCEPTION 'operation_id مستخدم مع عقد مختلف'; END IF;

  v_return_reason_id:=NULLIF(BTRIM(p_contract->>'return_reason_id'),'')::uuid;
  v_purchase_invoice_id:=NULLIF(BTRIM(p_contract->>'purchase_invoice_id'),'')::uuid;
  v_purchase_order_id:=NULLIF(BTRIM(p_contract->>'purchase_order_id'),'')::uuid;
  v_return_address:=NULLIF(BTRIM(p_contract->>'return_to_address'),'');
  v_inspection_status:=COALESCE(NULLIF(BTRIM(p_contract->>'inspection_status'),''),'not_required');
  v_disposition:=COALESCE(NULLIF(BTRIM(p_contract->>'disposition'),''),'return_to_supplier');

  SELECT * INTO v_supplier FROM public.suppliers s
  WHERE s.id=v.to_id AND s.company_id=p_company_id AND COALESCE(s.is_active,true) FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'المورد غير صالح'; END IF;

  SELECT * INTO v_reason FROM public.return_reasons r
  WHERE r.id=v_return_reason_id AND (r.company_id=p_company_id OR r.company_id IS NULL) AND r.is_active=true LIMIT 1;
  IF NOT FOUND THEN RAISE EXCEPTION 'سبب المرتجع مطلوب'; END IF;

  IF v_return_address IS NULL THEN v_return_address:=NULLIF(BTRIM(COALESCE(v_supplier.address,'')),''); END IF;
  IF v_return_address IS NULL THEN RAISE EXCEPTION 'عنوان إعادة التوريد للمورد مطلوب'; END IF;

  IF v_inspection_status NOT IN ('not_required','pending','passed','failed') THEN RAISE EXCEPTION 'حالة الفحص غير صالحة'; END IF;
  IF v_disposition NOT IN ('return_to_supplier','replacement_requested','credit_requested','rejected') THEN RAISE EXCEPTION 'قرار disposition غير صالح'; END IF;

  IF v_purchase_invoice_id IS NOT NULL THEN
    SELECT * INTO v_invoice FROM public.purchase_invoices pi
    WHERE pi.id=v_purchase_invoice_id AND pi.company_id=p_company_id AND pi.supplier_id=v.to_id AND pi.status<>'Cancelled' FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'فاتورة الشراء المرجعية غير صالحة'; END IF;
  END IF;

  IF v_purchase_order_id IS NOT NULL THEN
    SELECT * INTO v_po FROM public.purchase_orders po
    WHERE po.id=v_purchase_order_id AND po.company_id=p_company_id AND po.supplier_id=v.to_id AND po.status<>'Cancelled' FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'أمر الشراء المرجعي غير صالح'; END IF;
  END IF;

  IF v_invoice.id IS NOT NULL AND v_po.id IS NOT NULL AND v_invoice.purchase_order_id IS NOT NULL AND v_invoice.purchase_order_id<>v_po.id THEN
    RAISE EXCEPTION 'فاتورة الشراء لا تتبع أمر الشراء المحدد'; END IF;

  v_currency:=UPPER(COALESCE(NULLIF(BTRIM(p_contract->>'currency'),''),v_invoice.currency,'SAR'));

  FOR v_item IN
    SELECT d.id,d.item_code,d.item_id,d.qty,d.unit_price
    FROM public.stock_voucher_details d
    WHERE d.voucher_id=v.id
    ORDER BY d.item_code,d.id
  LOOP
    v_line_cfg:='{}'::jsonb;
    SELECT z.value INTO v_line_cfg
    FROM jsonb_array_elements(CASE WHEN jsonb_typeof(p_contract->'lines')='array' THEN p_contract->'lines' ELSE '[]'::jsonb END) z(value)
    WHERE BTRIM(z.value->>'item_code')=BTRIM(v_item.item_code)
    LIMIT 1;

    v_unit_price:=COALESCE(NULLIF(v_line_cfg->>'unit_price','')::numeric,NULLIF(v_item.unit_price,0),(SELECT cost_price FROM public.items i WHERE i.id=v_item.item_id),0);
    IF v_unit_price<=0 THEN RAISE EXCEPTION 'لا توجد تكلفة موجبة للصنف %',v_item.item_code; END IF;

    v_gross:=ROUND(COALESCE(v_item.qty,0)*v_unit_price,2);
    v_discount_pct:=GREATEST(0,COALESCE(NULLIF(v_line_cfg->>'discount_percent','')::numeric,0));
    v_discount:=ROUND(COALESCE(NULLIF(v_line_cfg->>'discount_amount','')::numeric,(v_gross*v_discount_pct/100)),2);

    IF v_discount<0 OR v_discount>v_gross OR v_discount_pct>100 THEN RAISE EXCEPTION 'خصم الصنف % غير صالح',v_item.item_code; END IF;
    IF NULLIF(v_line_cfg->>'discount_amount','') IS NOT NULL AND NULLIF(v_line_cfg->>'discount_percent','') IS NOT NULL
       AND ABS(v_discount-ROUND(v_gross*v_discount_pct/100,2))>0.01 THEN
      RAISE EXCEPTION 'خصم الصنف % غير متسق',v_item.item_code;
    END IF;

    v_tax_code_id:=NULLIF(BTRIM(v_line_cfg->>'tax_code_id'),'')::uuid;
    v_tax_rate:=0; v_tax:=0; v_tax_account:=NULL;

    IF v_tax_code_id IS NOT NULL THEN
      SELECT tc.rate,tc.purchase_account_id INTO v_tax_rate,v_tax_account
      FROM public.finance_tax_codes tc
      WHERE tc.id=v_tax_code_id AND tc.company_id=p_company_id AND tc.is_active=true LIMIT 1;
      IF NOT FOUND THEN RAISE EXCEPTION 'رمز الضريبة للصنف % غير صالح',v_item.item_code; END IF;
      IF v_tax_account IS NULL OR NOT EXISTS(
        SELECT 1 FROM public.chart_of_accounts coa
        WHERE coa.id=v_tax_account AND coa.company_id=p_company_id AND coa.is_active=true
      ) THEN RAISE EXCEPTION 'حساب ضريبة المشتريات غير مهيأ للصنف %',v_item.item_code; END IF;
      v_taxable:=ROUND(v_gross-v_discount,2);
      v_tax:=ROUND(v_taxable*v_tax_rate/100,2);
      IF NULLIF(v_line_cfg->>'tax_amount','') IS NOT NULL AND ABS(v_tax-((v_line_cfg->>'tax_amount')::numeric))>0.02 THEN
        RAISE EXCEPTION 'قيمة الضريبة للصنف % لا تطابق رمز الضريبة',v_item.item_code;
      END IF;
    ELSE
      v_taxable:=ROUND(v_gross-v_discount,2);
      IF COALESCE(NULLIF(v_line_cfg->>'tax_amount','')::numeric,0)<>0 OR COALESCE(NULLIF(v_line_cfg->>'tax_rate','')::numeric,0)<>0 THEN
        RAISE EXCEPTION 'يجب اختيار رمز ضريبة قبل إدخال ضريبة للصنف %',v_item.item_code;
      END IF;
    END IF;

    v_net:=ROUND(v_taxable+v_tax,2);

    UPDATE public.stock_voucher_details
    SET unit_price=ROUND(v_unit_price,2),gross_amount=v_gross,discount_percent=ROUND(v_discount_pct,4),discount_amount=v_discount,
        taxable_amount=v_taxable,tax_code_id=v_tax_code_id,tax_rate=ROUND(v_tax_rate,4),tax_amount=v_tax,net_amount=v_net,line_total=v_net
    WHERE id=v_item.id AND voucher_id=v.id;

    v_subtotal:=v_subtotal+v_gross;
    v_discount_total:=v_discount_total+v_discount;
    v_tax_total:=v_tax_total+v_tax;
    v_total:=v_total+v_net;
  END LOOP;

  IF v_total<=0 THEN RAISE EXCEPTION 'إجمالي المرتجع يجب أن يكون موجبًا'; END IF;

  UPDATE public.stock_vouchers
  SET return_reason_id=v_return_reason_id,
      supplier_credit_note_ref=NULLIF(BTRIM(p_contract->>'supplier_credit_note_ref'),''),
      supplier_rma_ref=NULLIF(BTRIM(p_contract->>'supplier_rma_ref'),''),
      purchase_invoice_id=v_purchase_invoice_id,purchase_order_id=v_purchase_order_id,return_to_address=v_return_address,
      inspection_status=v_inspection_status,disposition=v_disposition,return_currency=v_currency,
      return_subtotal=ROUND(v_subtotal,2),return_discount_amount=ROUND(v_discount_total,2),return_tax_amount=ROUND(v_tax_total,2),
      return_total_amount=ROUND(v_total,2),updated_at=now()
  WHERE id=v.id AND company_id=p_company_id AND status='Draft';

  IF NOT FOUND THEN RAISE EXCEPTION 'فشل حفظ عقد مرتجع المورد'; END IF;

  DELETE FROM public.purchase_document_links
  WHERE company_id=p_company_id AND source_type='stock_voucher' AND source_id=v.id AND relation_type='references';

  IF v_purchase_invoice_id IS NOT NULL THEN
    INSERT INTO public.purchase_document_links(company_id,source_type,source_id,target_type,target_id,relation_type,created_by)
    VALUES(p_company_id,'stock_voucher',v.id,'purchase_invoice',v_purchase_invoice_id,'references',v_actor.email);
  END IF;

  IF v_purchase_order_id IS NOT NULL THEN
    INSERT INTO public.purchase_document_links(company_id,source_type,source_id,target_type,target_id,relation_type,created_by)
    VALUES(p_company_id,'stock_voucher',v.id,'purchase_order',v_purchase_order_id,'references',v_actor.email);
  END IF;

  v_existing_payload:=jsonb_build_object('success',true,'duplicate',false,'voucher_id',v.id,'voucher_code',v.voucher_code,
    'return_reason_id',v_return_reason_id,'purchase_invoice_id',v_purchase_invoice_id,'purchase_order_id',v_purchase_order_id,
    'return_subtotal',ROUND(v_subtotal,2),'return_discount_amount',ROUND(v_discount_total,2),'return_tax_amount',ROUND(v_tax_total,2),
    'return_total_amount',ROUND(v_total,2));

  UPDATE public.erp_operation_registry
  SET status='completed',response_payload=v_existing_payload,completed_at=now()
  WHERE company_id=p_company_id AND operation_type='save_supplier_return_contract' AND operation_key=BTRIM(p_operation_id);

  INSERT INTO public.audit_log(id,user_email,action,table_name,record_id,new_data,created_at)
  VALUES(gen_random_uuid(),v_actor.email,'update','stock_vouchers',v.id::text,v_existing_payload,now());

  RETURN v_existing_payload;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_supplier_return_contract(p_company_id uuid,p_voucher_code text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='public'
AS $function$
DECLARE v_actor public.users%ROWTYPE; v public.stock_vouchers%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'غير مصرح'; END IF;
  SELECT * INTO v_actor FROM public.users u
  WHERE u.auth_id=auth.uid() AND u.company_id=p_company_id AND COALESCE(u.status,'Active')='Active' LIMIT 1;
  IF NOT FOUND THEN RAISE EXCEPTION 'المستخدم الحالي غير صالح ضمن الشركة'; END IF;
  IF NOT (COALESCE(v_actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb OR COALESCE(v_actor.active_warehouse_role,'')='أذونات' OR v_actor.role IN ('مدير مخازن','مشرف مخازن','مدير عام')) THEN
    RAISE EXCEPTION 'المستخدم غير مخول بقراءة عقد مرتجع المورد'; END IF;
  SELECT * INTO v FROM public.stock_vouchers WHERE company_id=p_company_id AND voucher_code=BTRIM(p_voucher_code);
  IF NOT FOUND OR v.type<>'SupplierReturn' THEN RAISE EXCEPTION 'SupplierReturn document not found'; END IF;
  RETURN jsonb_build_object(
    'success',true,
    'voucher',jsonb_build_object('id',v.id,'voucher_code',v.voucher_code,'return_reason_id',v.return_reason_id,
      'supplier_credit_note_ref',v.supplier_credit_note_ref,'supplier_rma_ref',v.supplier_rma_ref,'purchase_invoice_id',v.purchase_invoice_id,
      'purchase_order_id',v.purchase_order_id,'return_to_address',v.return_to_address,'inspection_status',v.inspection_status,
      'disposition',v.disposition,'return_currency',v.return_currency,'return_subtotal',v.return_subtotal,
      'return_discount_amount',v.return_discount_amount,'return_tax_amount',v.return_tax_amount,'return_total_amount',v.return_total_amount),
    'lines',COALESCE((
      SELECT jsonb_agg(jsonb_build_object('id',d.id,'item_code',d.item_code,'qty',d.qty,'unit_price',d.unit_price,'gross_amount',d.gross_amount,
        'discount_percent',d.discount_percent,'discount_amount',d.discount_amount,'taxable_amount',d.taxable_amount,'tax_code_id',d.tax_code_id,
        'tax_rate',d.tax_rate,'tax_amount',d.tax_amount,'net_amount',d.net_amount,'line_total',d.line_total) ORDER BY d.item_code,d.id)
      FROM public.stock_voucher_details d WHERE d.voucher_id=v.id
    ),'[]'::jsonb)
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.save_supplier_return_contract(uuid,text,jsonb,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.save_supplier_return_contract(uuid,text,jsonb,text) TO authenticated;
REVOKE ALL ON FUNCTION public.get_supplier_return_contract(uuid,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_supplier_return_contract(uuid,text) TO authenticated;

CREATE OR REPLACE FUNCTION public.complete_manual_stock_voucher_atomic_core_20260828(
  p_company_id uuid,p_voucher_code text,p_user_email text
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='public'
AS $function$
DECLARE
  v public.stock_vouchers%ROWTYPE;
  expected text;
  v_company_id uuid;
  v_supplier_id uuid;
  v_supplier_name text;
  v_return_subtotal numeric:=0;
  v_discount_total numeric:=0;
  v_taxable_total numeric:=0;
  v_tax_total numeric:=0;
  v_return_total numeric:=0;
  v_inventory_account uuid;
  v_supplier_account uuid;
  v_financial jsonb:='{}'::jsonb;
  v_journal jsonb;
  v_supplier_ledger jsonb;
  v_tax_lines jsonb:='[]'::jsonb;
  v_tax_count bigint:=0;
BEGIN
  SELECT u.company_id INTO v_company_id FROM public.users u
  WHERE u.company_id=p_company_id AND lower(u.email)=lower(p_user_email) AND COALESCE(u.status,'Active')='Active'
  ORDER BY u.id LIMIT 1;
  IF v_company_id IS NULL OR v_company_id<>p_company_id THEN RAISE EXCEPTION 'سياق الشركة غير متسق مع المستخدم المنفذ'; END IF;

  SELECT * INTO v FROM public.stock_vouchers WHERE company_id=v_company_id AND voucher_code=p_voucher_code FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'الإذن غير موجود'; END IF;

  IF v.status='Completed' THEN
    SELECT jsonb_build_object(
      'supplier_ledger',COALESCE((SELECT response_payload FROM public.erp_operation_registry WHERE company_id=v_company_id AND operation_type='post_supplier_ledger_entry' AND operation_key=v.id::text AND status='completed'),'{}'::jsonb),
      'journal',COALESCE((SELECT response_payload FROM public.erp_operation_registry WHERE company_id=v_company_id AND operation_type='post_journal_entry' AND operation_key=v.id::text AND status='completed'),'{}'::jsonb)
    ) INTO v_financial;
    RETURN jsonb_build_object('success',true,'duplicate',true,'voucher_code',p_voucher_code,'status',v.status,'financial',v_financial);
  END IF;

  expected:=CASE WHEN v.type IN('Transfer','DirectReturn') THEN 'Received' WHEN v.type IN('DirectSale','SupplierReturn') THEN 'Sent' ELSE NULL END;
  IF expected IS NULL OR v.status<>expected THEN RAISE EXCEPTION 'حالة الإذن لا تسمح بالإكمال'; END IF;

  IF v.type='SupplierReturn' THEN
    PERFORM public.assert_supplier_return_contract(v_company_id,v.id);

    SELECT s.id,s.name INTO v_supplier_id,v_supplier_name
    FROM public.suppliers s WHERE s.id=v.to_id AND s.company_id=v_company_id AND COALESCE(s.is_active,true) FOR UPDATE;

    SELECT COALESCE(SUM(d.gross_amount),0),COALESCE(SUM(d.discount_amount),0),COALESCE(SUM(d.taxable_amount),0),
           COALESCE(SUM(d.tax_amount),0),COALESCE(SUM(d.net_amount),0)
    INTO v_return_subtotal,v_discount_total,v_taxable_total,v_tax_total,v_return_total
    FROM public.stock_voucher_details d WHERE d.voucher_id=v.id;
    IF v_return_total<=0 THEN RAISE EXCEPTION 'إجمالي مرتجع المورد غير صالح'; END IF;

    SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'account_id',q.purchase_account_id,'account_name',q.account_name,'debit',0,'credit',q.tax_amount,
      'notes','عكس ضريبة المشتريات بسبب مرتجع المورد'
    ) ORDER BY q.tax_code),'[]'::jsonb)
    INTO v_tax_lines
    FROM (
      SELECT d.tax_code_id,tc.code tax_code,tc.purchase_account_id,coa.account_name,ROUND(SUM(d.tax_amount),2) tax_amount
      FROM public.stock_voucher_details d
      JOIN public.finance_tax_codes tc ON tc.id=d.tax_code_id AND tc.company_id=v_company_id AND tc.is_active=true
      JOIN public.chart_of_accounts coa ON coa.id=tc.purchase_account_id AND coa.company_id=v_company_id AND coa.is_active=true
      WHERE d.voucher_id=v.id AND d.tax_amount>0
      GROUP BY d.tax_code_id,tc.code,tc.purchase_account_id,coa.account_name
    ) q;

    SELECT count(*) INTO v_tax_count FROM public.stock_voucher_details d WHERE d.voucher_id=v.id AND d.tax_amount>0;
    IF v_tax_count>0 AND jsonb_array_length(v_tax_lines)=0 THEN RAISE EXCEPTION 'تم احتساب ضريبة دون حساب ضريبة صالح'; END IF;

    SELECT id INTO v_inventory_account FROM public.chart_of_accounts WHERE company_id=v_company_id AND account_code='124' AND is_active=true LIMIT 1;
    SELECT id INTO v_supplier_account FROM public.chart_of_accounts WHERE company_id=v_company_id AND account_code='211' AND is_active=true LIMIT 1;
    IF v_inventory_account IS NULL OR v_supplier_account IS NULL THEN RAISE EXCEPTION 'حسابات مرتجع المورد غير مكتملة للشركة'; END IF;

    UPDATE public.stock_vouchers
    SET return_subtotal=ROUND(v_return_subtotal,2),return_discount_amount=ROUND(v_discount_total,2),
        return_tax_amount=ROUND(v_tax_total,2),return_total_amount=ROUND(v_return_total,2),updated_at=now()
    WHERE id=v.id AND company_id=v_company_id;

    SELECT public.post_supplier_ledger_entry(
      v_company_id,v.id,v_supplier_id,v.voucher_date,p_voucher_code,
      'مرتجع مورد – '||p_voucher_code||CASE WHEN NULLIF(v_supplier_name,'') IS NOT NULL THEN ' – '||v_supplier_name ELSE '' END,
      v_return_total,0,v.voucher_date,p_user_email
    ) INTO v_supplier_ledger;

    SELECT public.post_journal_entry(
      v_company_id,v.id,v.voucher_date,'SupplierReturn',p_voucher_code,
      'مرتجع مورد – '||p_voucher_code||CASE WHEN NULLIF(v_supplier_name,'') IS NOT NULL THEN ' – '||v_supplier_name ELSE '' END,
      p_user_email,
      jsonb_build_array(
        jsonb_build_object('account_id',v_supplier_account,'account_name','الموردون (ذمم دائنة)','debit',v_return_total,'credit',0,'notes','خفض التزام المورد بسبب مرتجع البضاعة'),
        jsonb_build_object('account_id',v_inventory_account,'account_name','المخزون السلعي','debit',0,'credit',v_taxable_total,'notes','خفض قيمة المخزون بسبب مرتجع المورد بعد الخصم')
      ) || v_tax_lines,
      'JE-SVR-'||p_voucher_code,now(),NULL
    ) INTO v_journal;

    INSERT INTO public.finance_tax_transactions(
      company_id,tax_code_id,transaction_date,direction,taxable_amount,tax_amount,source_type,source_id,journal_entry_id,
      operation_id,notes,created_by,source_reference
    )
    SELECT v_company_id,d.tax_code_id,v.voucher_date,'OTHER',ROUND(SUM(d.taxable_amount),2),ROUND(SUM(d.tax_amount),2),
           'SupplierReturn',v.id,(v_journal->>'entry_id')::uuid,v.id,'عكس ضريبة مشتريات من مرتجع مورد',p_user_email,p_voucher_code
    FROM public.stock_voucher_details d
    WHERE d.voucher_id=v.id AND d.tax_code_id IS NOT NULL AND d.tax_amount>0
    GROUP BY d.tax_code_id;

    v_financial:=jsonb_build_object(
      'supplier_id',v_supplier_id,'supplier_name',v_supplier_name,'return_subtotal',v_return_subtotal,
      'discount_amount',v_discount_total,'taxable_amount',v_taxable_total,'tax_amount',v_tax_total,'return_value',v_return_total,
      'supplier_ledger',v_supplier_ledger,'journal',v_journal
    );
  END IF;

  UPDATE public.stock_vouchers SET status='Completed',completed_at=now(),completed_by=p_user_email,updated_at=now()
  WHERE id=v.id AND company_id=v_company_id AND status=expected;
  IF NOT FOUND THEN RAISE EXCEPTION 'فشل إكمال الإذن'; END IF;

  RETURN jsonb_build_object('success',true,'duplicate',false,'voucher_code',p_voucher_code,'status','Completed','financial',v_financial);
END;
$function$;

CREATE OR REPLACE FUNCTION public.send_stock_voucher_atomic(p_company_id uuid,p_voucher_code text,p_user_email text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='public'
AS $function$
DECLARE
  v_actor public.users%ROWTYPE;
  v public.stock_vouchers%ROWTYPE;
  v_source uuid; v_auth_branch uuid; v_allowed boolean; v_result jsonb; v_custodian_email text; v_custody_value numeric:=0;
BEGIN
  PERFORM set_config('app.user_email',COALESCE(p_user_email,''),true);
  PERFORM set_config('app.operation_id','VoucherSend:'||p_company_id::text||':'||COALESCE(BTRIM(p_voucher_code),''),true);

  SELECT * INTO v_actor FROM public.users u WHERE u.company_id=p_company_id AND lower(u.email)=lower(p_user_email) AND COALESCE(u.status,'Active')='Active' LIMIT 1;
  IF NOT FOUND THEN RAISE EXCEPTION 'سياق الشركة غير متسق مع المستخدم المنفذ'; END IF;
  SELECT * INTO v FROM public.stock_vouchers WHERE company_id=p_company_id AND voucher_code=p_voucher_code FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'الإذن غير موجود'; END IF;

  IF v.type='SupplierReturn' THEN PERFORM public.assert_supplier_return_contract(p_company_id,v.id); END IF;

  IF v.from_type='Branch' THEN
    v_source:=v.from_id;
  ELSIF v.from_type='Vehicle' THEN
    SELECT COALESCE(
      (SELECT mb.id FROM public.branches mb WHERE mb.id=v_vehicle.mobile_branch_id AND mb.company_id=p_company_id AND mb.is_active=true),
      (SELECT lb.id FROM public.branches lb WHERE lb.company_id=p_company_id AND upper(lb.branch_code)=upper('VAN-'||v_vehicle.vehicle_code) AND lb.is_active=true)
    ) INTO v_source
    FROM public.vehicles v_vehicle
    WHERE v_vehicle.id=v.from_id AND v_vehicle.company_id=p_company_id AND COALESCE(v_vehicle.status,'Active')='Active' AND COALESCE(v_vehicle.mobile_stock_enabled,true)=true;
  END IF;

  IF v.type='DirectReturn' AND v.to_type='Branch' THEN v_auth_branch:=v.to_id; ELSE v_auth_branch:=v_source; END IF;
  IF v_auth_branch IS NULL OR NOT EXISTS(
    SELECT 1 FROM public.branches b WHERE b.id=v_auth_branch AND b.company_id=p_company_id AND b.is_active=true
  ) THEN RAISE EXCEPTION 'سياق الفرع التشغيلي للإذن غير صالح'; END IF;

  IF NOT (
    COALESCE(v_actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb
    OR v_actor.allowed_branch_ids IS NULL OR v_actor.allowed_branch_ids='[]'::jsonb
    OR COALESCE(TRIM(BOTH '"' FROM v_actor.allowed_branch_ids::text),'')='*'
    OR (v.type='Transfer' AND v_actor.role='مخزني' AND COALESCE(v_actor.active_warehouse_role,'')='أذونات')
  ) THEN
    SELECT EXISTS(
      SELECT 1 FROM public.branches b WHERE b.id=v_auth_branch AND b.company_id=p_company_id AND b.is_active=true
      AND (
        (jsonb_typeof(v_actor.allowed_branch_ids)='array' AND (
          v_actor.allowed_branch_ids @> jsonb_build_array(b.branch_code) OR v_actor.allowed_branch_ids @> jsonb_build_array(b.id::text)
        ))
        OR (jsonb_typeof(v_actor.allowed_branch_ids)='string' AND TRIM(BOTH '"' FROM v_actor.allowed_branch_ids::text) IN(b.branch_code,b.id::text,'*'))
      )
    ) INTO v_allowed;
    IF NOT v_allowed THEN RAISE EXCEPTION 'الفرع التشغيلي للإذن خارج نطاق فروع المستخدم المسموح بها'; END IF;
  END IF;

  v_result:=public.send_stock_voucher_atomic_core_20260828(p_company_id,p_voucher_code,p_user_email);
  IF COALESCE((v_result->>'duplicate')::boolean,false) THEN RETURN v_result; END IF;

  IF v.type='DirectSale' THEN
    IF v.custodian_user_id IS NULL THEN RAISE EXCEPTION 'DirectSale custodian context missing'; END IF;
    SELECT u.email INTO v_custodian_email FROM public.users u
    WHERE u.id=v.custodian_user_id AND u.company_id=p_company_id AND COALESCE(u.status,'Active')='Active' AND u.role='مندوب بيع مباشر';
    IF v_custodian_email IS NULL THEN RAISE EXCEPTION 'مندوب عهدة DirectSale غير صالح'; END IF;
    SELECT COALESCE(SUM(svd.qty*COALESCE(NULLIF(svd.unit_price,0),i.sales_price,i.cost_price,0)),0) INTO v_custody_value
    FROM public.stock_voucher_details svd JOIN public.items i ON i.id=svd.item_id WHERE svd.voucher_id=v.id;
    IF v_custody_value>0 THEN
      PERFORM public.post_driver_ledger_entry(p_company_id,v.id,v_custodian_email,current_date,p_voucher_code,'تحميل عهدة مبيعات مباشرة – '||p_voucher_code,v_custody_value,0);
      v_result:=v_result||jsonb_build_object('custody_ledger',true,'custodian_user_id',v.custodian_user_id,'custody_value',v_custody_value);
    ELSE
      v_result:=v_result||jsonb_build_object('custody_ledger',false,'custody_value',0);
    END IF;
  END IF;
  RETURN v_result;
END;
$function$;
