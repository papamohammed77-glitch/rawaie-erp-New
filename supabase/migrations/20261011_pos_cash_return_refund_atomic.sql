-- RAWAEA ERP — POS cash return core repair
-- Date: 2026-10-11
-- Scope: existing public.complete_return_atomic only; no new Edge Function.
-- The patch is guarded against Production source drift and fails closed if the
-- exact previously verified source fragments are not present.

DO $patch$
DECLARE
  v_def text;
  v_old_decl text := 'v_item_expected_total numeric:=0; v_item_returned_total numeric:=0;';
  v_new_decl text := 'v_item_expected_total numeric:=0; v_item_returned_total numeric:=0; v_refund_treasury_id uuid; v_refund_cash_account uuid; v_refund_sales_account uuid; v_refund_operation_id uuid; v_refund_result jsonb; v_refund_receipt_total numeric:=0; v_prior_refunds numeric:=0; v_pos_gross_total numeric:=0; v_pos_refund_amount numeric:=0; v_receipt_count integer:=0;';
  v_old_block text := $old$
 if p_order_code is not null and v_total_value>0 then
    if v_order.customer_id is null then raise exception 'RETURN_CUSTOMER_REQUIRED_FOR_FINANCIAL_POSTING'; end if;
    v_fin_operation_id:=coalesce(v_fin_operation_id,gen_random_uuid());
    v_customer_ledger:=public.post_customer_ledger_entry(p_company_id,v_fin_operation_id,v_order.customer_id,current_date,p_order_code,'مرتجع – '||p_order_code,0,v_total_value,current_date,p_user_email);
 end if;
$old$;
  v_new_block text := $new$
 if p_order_code is not null and v_total_value>0 then
    IF p_is_pos_return AND lower(coalesce(v_order.source,''))='pos' THEN
      IF lower(btrim(coalesce(v_order.payment_type,''))) <> 'نقدي' THEN
        RAISE EXCEPTION 'POS_RETURN_TENDER_REFUND_NOT_CONFIGURED';
      END IF;

      SELECT count(*), min(cb.treasury_id::text)::uuid, coalesce(sum(cb.amount),0)
        INTO v_receipt_count, v_refund_treasury_id, v_refund_receipt_total
      FROM public.cash_box cb
      WHERE cb.company_id=p_company_id
        AND cb.source_type='POS'
        AND cb.source_id=v_order.id
        AND cb.reference=p_order_code
        AND cb.type='Receipt'
        AND coalesce(cb.status,'Active')='Active';

      IF v_receipt_count <> 1 OR v_refund_treasury_id IS NULL THEN
        RAISE EXCEPTION 'POS_ORIGINAL_CASH_RECEIPT_NOT_UNIQUELY_FOUND';
      END IF;
      IF v_refund_receipt_total + 0.01 < coalesce(v_order.original_total_amount,v_order.total_amount,0) THEN
        RAISE EXCEPTION 'POS_ORIGINAL_CASH_RECEIPT_AMOUNT_MISMATCH';
      END IF;

      SELECT coalesce(sum(greatest(0,coalesce(od.qty,0))*coalesce(od.unit_price,0)),0)
        INTO v_pos_gross_total
      FROM public.order_details od
      WHERE od.order_id=v_order.id;
      IF v_pos_gross_total <= 0 THEN
        RAISE EXCEPTION 'POS_RETURN_GROSS_VALUE_UNAVAILABLE';
      END IF;

      -- Allocate order-level discount proportionally to the returned merchandise.
      -- Delivery fees are not refunded by this merchandise-return contract.
      v_pos_refund_amount := round(
        v_total_value * greatest(0,v_pos_gross_total-coalesce(v_order.discount_amount,0))
        / v_pos_gross_total, 2
      );
      IF v_pos_refund_amount <= 0 THEN
        RAISE EXCEPTION 'POS_RETURN_REFUND_AMOUNT_INVALID';
      END IF;

      SELECT coalesce(sum(cb.amount),0)
        INTO v_prior_refunds
      FROM public.cash_box cb
      WHERE cb.company_id=p_company_id
        AND cb.source_type='POS_RETURN_REFUND'
        AND cb.source_id=v_order.id
        AND cb.type='Payment'
        AND coalesce(cb.status,'Active')='Active';

      IF v_pos_refund_amount > v_refund_receipt_total-v_prior_refunds+0.01 THEN
        RAISE EXCEPTION 'POS_RETURN_EXCEEDS_UNREFUNDED_CASH_TENDER';
      END IF;

      SELECT coa.id INTO v_refund_cash_account
      FROM public.chart_of_accounts coa
      WHERE coa.company_id=p_company_id AND coa.account_code='121'
        AND coalesce(coa.is_active,true)=true
      LIMIT 1;
      SELECT coa.id INTO v_refund_sales_account
      FROM public.chart_of_accounts coa
      WHERE coa.company_id=p_company_id AND coa.account_code='41'
        AND coalesce(coa.is_active,true)=true
      LIMIT 1;
      IF v_refund_cash_account IS NULL OR v_refund_sales_account IS NULL THEN
        RAISE EXCEPTION 'POS_RETURN_CASH_OR_SALES_ACCOUNT_NOT_CONFIGURED';
      END IF;

      -- Stable operation UUID makes retry of the same return idempotent.
      v_refund_operation_id :=
        (substr(md5('POS_RETURN_REFUND|'||p_company_id::text||'|'||v_op_key),1,8)||'-'||
         substr(md5('POS_RETURN_REFUND|'||p_company_id::text||'|'||v_op_key),9,4)||'-'||
         substr(md5('POS_RETURN_REFUND|'||p_company_id::text||'|'||v_op_key),13,4)||'-'||
         substr(md5('POS_RETURN_REFUND|'||p_company_id::text||'|'||v_op_key),17,4)||'-'||
         substr(md5('POS_RETURN_REFUND|'||p_company_id::text||'|'||v_op_key),21,12))::uuid;

      v_refund_result := public.post_cash_payment_atomic(
        p_company_id,
        v_refund_operation_id,
        v_refund_treasury_id,
        v_refund_cash_account,
        v_refund_sales_account,
        v_pos_refund_amount,
        current_date,
        p_order_code,
        'رد نقدي لمرتجع نقطة بيع - '||p_order_code,
        p_user_email,
        coalesce(v_order.customer_name,'عميل نقدي'),
        'POS_RETURN_REFUND',
        v_order.id,
        'POS return operation '||v_op_key,
        NULL
      );
    ELSE
      IF v_order.customer_id IS NULL THEN
        RAISE EXCEPTION 'RETURN_CUSTOMER_REQUIRED_FOR_FINANCIAL_POSTING';
      END IF;
      v_fin_operation_id:=coalesce(v_fin_operation_id,gen_random_uuid());
      v_customer_ledger:=public.post_customer_ledger_entry(
        p_company_id,v_fin_operation_id,v_order.customer_id,current_date,p_order_code,
        'مرتجع – '||p_order_code,0,v_total_value,current_date,p_user_email
      );
    END IF;
 end if;
$new$;
  v_old_result text := $oldresult$v_result:=jsonb_build_object('success',true,'duplicate',false,'msg','تم إنهاء المرتجعات بنجاح','updated_count',v_updated,'skipped_count',v_skipped,'adjusted_count',v_adjusted,'total_returned_value',v_total_value,'new_order_status',v_order_new_status);$oldresult$;
  v_new_result text := $newresult$v_result:=jsonb_build_object('success',true,'duplicate',false,'msg','تم إنهاء المرتجعات بنجاح','updated_count',v_updated,'skipped_count',v_skipped,'adjusted_count',v_adjusted,'total_returned_value',CASE WHEN v_refund_result IS NOT NULL THEN v_pos_refund_amount ELSE v_total_value END,'new_order_status',v_order_new_status,'refund_posted',v_refund_result IS NOT NULL,'refund_amount',CASE WHEN v_refund_result IS NOT NULL THEN v_pos_refund_amount ELSE 0 END,'refund_reference',CASE WHEN v_refund_result IS NOT NULL THEN p_order_code ELSE NULL END,'refund_cash_box_id',v_refund_result->>'cash_box_id','refund_operation_id',v_refund_result->>'operation_id','refund_treasury_id',v_refund_result->>'treasury_id');$newresult$;
BEGIN
  SELECT pg_get_functiondef('public.complete_return_atomic(uuid,text,text,boolean,text,jsonb)'::regprocedure)
    INTO v_def;

  IF position(v_old_decl in v_def)=0 THEN
    RAISE EXCEPTION 'POS_RETURN_PATCH_ABORTED: declaration anchor mismatch';
  END IF;
  IF position(v_old_block in v_def)=0 THEN
    RAISE EXCEPTION 'POS_RETURN_PATCH_ABORTED: financial branch anchor mismatch';
  END IF;
  IF position(v_old_result in v_def)=0 THEN
    RAISE EXCEPTION 'POS_RETURN_PATCH_ABORTED: response anchor mismatch';
  END IF;

  v_def := replace(v_def,v_old_decl,v_new_decl);
  v_def := replace(v_def,v_old_block,v_new_block);
  v_def := replace(v_def,v_old_result,v_new_result);

  IF position('POS_RETURN_TENDER_REFUND_NOT_CONFIGURED' in v_def)=0
     OR position('refund_cash_box_id' in v_def)=0 THEN
    RAISE EXCEPTION 'POS_RETURN_PATCH_ABORTED: post-replacement validation failed';
  END IF;

  EXECUTE v_def;
END
$patch$;

-- Keep the privileged RPC service-only.
REVOKE ALL ON FUNCTION public.complete_return_atomic(uuid,text,text,boolean,text,jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.complete_return_atomic(uuid,text,text,boolean,text,jsonb) TO service_role;
