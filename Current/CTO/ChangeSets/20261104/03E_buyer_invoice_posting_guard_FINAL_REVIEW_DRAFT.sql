-- RAWAEA ERP — Buyer Phase 1
-- حراسة ترحيل الفواتير مع الحفاظ على الكاتب المحاسبي/المخزني الحالي.
-- QUICK_MARKET لا يرحل مباشرة من Buyer؛ يجب أن يمر باستلام Receiver لاحقًا.
-- PO يستدعي الكاتب الحالي فقط؛ هذا الغلاف لا ينشئ حركة مخزون أو AP إضافية.

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
    'supplier_liability_posted_by_invoice',false
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.purchase_post_buyer_invoice_atomic(uuid,uuid,text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.purchase_post_buyer_invoice_atomic(uuid,uuid,text)
  TO authenticated, service_role;

COMMIT;

-- Edge patch:
-- في save-purchase-order استبدل POST_INVOICE الحالي باستدعاء profileClient.rpc:
--
-- } else if (op === "POST_INVOICE") {
--   ({ data, error } = await profileClient.rpc("purchase_post_buyer_invoice_atomic", {
--     p_company_id: companyId,
--     p_invoice_id: p.id,
--     p_actor: user.email
--   }));
--
-- لا تنفذ هذا الملف منفردًا قبل اعتماد تغيير Edge/UI المتصل به.
