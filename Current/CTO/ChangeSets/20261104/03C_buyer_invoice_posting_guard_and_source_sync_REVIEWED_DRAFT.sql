-- RAWAEA ERP — Buyer phase 1 companion
-- حراسة ترحيل فاتورة Buyer ومزامنة مصدر الفاتورة بعد ترحيل PO.
-- لا ينفذ على Production قبل مراجعة الحزمة الكاملة وموافقة التغيير.

BEGIN;

CREATE OR REPLACE FUNCTION public.purchase_post_buyer_invoice_atomic(
  p_company_id uuid,
  p_invoice_id uuid,
  p_actor text
)
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

  IF NOT app_private.current_user_has_effective_permission('purchases')
     OR NOT app_private.current_user_has_effective_permission('finance') THEN
    RAISE EXCEPTION 'PURCHASE_POST_REQUIRES_PURCHASES_AND_FINANCE';
  END IF;

  SELECT * INTO v_invoice
  FROM public.purchase_invoices
  WHERE id=p_invoice_id AND company_id=p_company_id
  FOR UPDATE;

  IF NOT FOUND THEN RAISE EXCEPTION 'PURCHASE_INVOICE_NOT_FOUND'; END IF;

  IF v_invoice.purchase_source='QUICK_MARKET' THEN
    RAISE EXCEPTION 'PURCHASE_QUICK_MARKET_RECEIPT_REQUIRED: لا يرحل Quick Market من Buyer؛ يجب اعتماده في Receiver أولًا.';
  END IF;

  v_result:=public.purchase_post_invoice_atomic(p_company_id,p_invoice_id,v_actor.email);

  IF v_invoice.purchase_source='PURCHASE_ORDER'
     AND COALESCE((v_result->>'success')::boolean,false)
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
    'purchase_source',v_invoice.purchase_source,
    'stock_posted_by_invoice',false,
    'supplier_liability_posted_by_invoice',false
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.purchase_post_buyer_invoice_atomic(uuid,uuid,text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.purchase_post_buyer_invoice_atomic(uuid,uuid,text)
  TO authenticated, service_role;

COMMIT;

-- على Edge save-purchase-order:
-- استبدل استدعاء POST_INVOICE الحالي باستدعاء profileClient.rpc لهذا الغلاف.
-- لا تغير purchase_post_invoice_atomic نفسه ولا وظيفة استلام PO.
