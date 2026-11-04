-- RAWAEA ERP — Buyer Phase 1
-- حراسة ملكية مسودات PO/Legacy قبل استدعاء وظائف التعديل والحذف المركزية القديمة.
-- لا يغير الدوال المركزية الأساسية؛ يضيف غلافًا خاصًا بمدخل Buyer الحالي.

BEGIN;

CREATE OR REPLACE FUNCTION public.purchase_update_buyer_legacy_draft_atomic(
  p_company_id uuid,
  p_invoice_id uuid,
  p_supplier_id uuid,
  p_purchase_order_id uuid,
  p_branch_id uuid,
  p_due_date date,
  p_currency text,
  p_actor text,
  p_supplier_invoice_no text,
  p_notes text,
  p_items jsonb,
  p_operation_id text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_actor public.users%ROWTYPE;
  v_invoice public.purchase_invoices%ROWTYPE;
  v_is_owner boolean:=COALESCE((public.get_my_effective_profile()->>'isOwner')::boolean,false);
BEGIN
  SELECT * INTO v_actor
  FROM public.users
  WHERE auth.uid()=users.auth_id
    AND company_id=p_company_id
    AND COALESCE(status,'Active')='Active';

  IF NOT FOUND OR lower(v_actor.email)<>lower(COALESCE(p_actor,'')) THEN
    RAISE EXCEPTION 'BUYER_ACTOR_AUTH_MISMATCH';
  END IF;

  IF NOT (
    app_private.current_user_has_effective_permission('purchases')
    OR v_is_owner
  ) THEN
    RAISE EXCEPTION 'BUYER_PURCHASE_PERMISSION_REQUIRED';
  END IF;

  IF NULLIF(btrim(p_operation_id),'') IS NULL THEN
    RAISE EXCEPTION 'PURCHASE_OPERATION_ID_REQUIRED';
  END IF;

  SELECT * INTO v_invoice
  FROM public.purchase_invoices
  WHERE id=p_invoice_id AND company_id=p_company_id
  FOR UPDATE;

  IF NOT FOUND OR v_invoice.purchase_source<>'LEGACY_UNCLASSIFIED' THEN
    RAISE EXCEPTION 'BUYER_LEGACY_INVOICE_NOT_FOUND_OR_WRONG_SOURCE';
  END IF;

  IF lower(COALESCE(v_invoice.created_by,''))<>lower(v_actor.email)
     AND NOT (COALESCE(v_actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb) THEN
    RAISE EXCEPTION 'BUYER_INVOICE_NOT_OWNED_BY_CURRENT_USER';
  END IF;

  IF p_purchase_order_id IS DISTINCT FROM v_invoice.purchase_order_id THEN
    RAISE EXCEPTION 'BUYER_LEGACY_INVOICE_SOURCE_CONVERSION_FORBIDDEN';
  END IF;

  RETURN public.purchase_update_draft_invoice_atomic(
    p_company_id,p_invoice_id,p_supplier_id,p_purchase_order_id,p_branch_id,
    p_due_date,p_currency,v_actor.email,p_supplier_invoice_no,p_notes,p_items,p_operation_id
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.purchase_delete_buyer_draft_invoice_atomic(
  p_company_id uuid,
  p_invoice_id uuid,
  p_actor text,
  p_reason text,
  p_operation_id text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_actor public.users%ROWTYPE;
  v_invoice public.purchase_invoices%ROWTYPE;
  v_owner boolean:=COALESCE((public.get_my_effective_profile()->>'isOwner')::boolean,false);
BEGIN
  SELECT * INTO v_actor
  FROM public.users
  WHERE auth.uid()=users.auth_id
    AND company_id=p_company_id
    AND COALESCE(status,'Active')='Active';

  IF NOT FOUND OR lower(v_actor.email)<>lower(COALESCE(p_actor,'')) THEN
    RAISE EXCEPTION 'BUYER_ACTOR_AUTH_MISMATCH';
  END IF;

  IF NOT (
    app_private.current_user_has_effective_permission('purchases')
    OR COALESCE(v_actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb
  ) THEN
    RAISE EXCEPTION 'BUYER_PURCHASE_PERMISSION_REQUIRED';
  END IF;

  SELECT * INTO v_invoice
  FROM public.purchase_invoices
  WHERE id=p_invoice_id AND company_id=p_company_id
  FOR UPDATE;

  IF NOT FOUND OR v_invoice.purchase_source NOT IN ('PURCHASE_ORDER','LEGACY_UNCLASSIFIED') THEN
    RAISE EXCEPTION 'BUYER_DRAFT_INVOICE_NOT_FOUND_OR_WRONG_SOURCE';
  END IF;

  IF NOT v_owner THEN
    IF v_invoice.purchase_source='PURCHASE_ORDER'
       AND v_invoice.purchaser_user_id IS DISTINCT FROM v_actor.id THEN
      RAISE EXCEPTION 'BUYER_INVOICE_NOT_OWNED_BY_CURRENT_USER';
    END IF;

    IF v_invoice.purchase_source='LEGACY_UNCLASSIFIED'
       AND lower(COALESCE(v_invoice.created_by,''))<>lower(v_actor.email) THEN
      RAISE EXCEPTION 'BUYER_INVOICE_NOT_OWNED_BY_CURRENT_USER';
    END IF;
  END IF;

  RETURN public.purchase_delete_draft_invoice_atomic(
    p_company_id,p_invoice_id,v_actor.email,p_reason,p_operation_id
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.purchase_update_buyer_legacy_draft_atomic(uuid,uuid,uuid,uuid,uuid,date,text,text,text,text,jsonb,text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.purchase_update_buyer_legacy_draft_atomic(uuid,uuid,uuid,uuid,uuid,date,text,text,text,text,jsonb,text)
  TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.purchase_delete_buyer_draft_invoice_atomic(uuid,uuid,text,text,text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.purchase_delete_buyer_draft_invoice_atomic(uuid,uuid,text,text,text)
  TO authenticated, service_role;

COMMIT;
