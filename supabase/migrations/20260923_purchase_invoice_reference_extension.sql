BEGIN;

CREATE OR REPLACE FUNCTION public.purchase_create_invoice_atomic_v2(
  p_company_id uuid,
  p_supplier_id uuid,
  p_purchase_order_id uuid,
  p_branch_id uuid,
  p_due_date date,
  p_currency text,
  p_created_by text,
  p_supplier_invoice_no text,
  p_notes text,
  p_items jsonb,
  p_operation_id text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_result jsonb;
  v_invoice_id uuid;
  v_supplier_invoice_no text;
  v_notes text;
BEGIN
  IF NULLIF(btrim(p_operation_id), '') IS NULL THEN
    RAISE EXCEPTION 'PURCHASE_OPERATION_ID_REQUIRED';
  END IF;

  SELECT public.purchase_create_invoice_atomic(
    p_company_id,
    p_supplier_id,
    p_purchase_order_id,
    p_branch_id,
    p_due_date,
    p_currency,
    p_created_by,
    p_items,
    p_operation_id
  )
  INTO v_result;

  IF COALESCE((v_result->>'duplicate')::boolean, false) THEN
    RETURN v_result;
  END IF;

  v_invoice_id := NULLIF(v_result->>'id', '')::uuid;
  v_supplier_invoice_no := NULLIF(btrim(p_supplier_invoice_no), '');
  v_notes := NULLIF(btrim(p_notes), '');

  UPDATE public.purchase_invoices
  SET supplier_invoice_no = v_supplier_invoice_no,
      notes = v_notes
  WHERE id = v_invoice_id
    AND company_id = p_company_id
    AND status = 'Draft';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'PURCHASE_INVOICE_REFERENCE_UPDATE_FAILED';
  END IF;

  RETURN v_result
    || jsonb_build_object(
      'supplier_invoice_no', v_supplier_invoice_no,
      'notes', v_notes
    );
END;
$function$;

REVOKE ALL ON FUNCTION public.purchase_create_invoice_atomic_v2(
  uuid,uuid,uuid,uuid,date,text,text,text,text,jsonb,text
) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.purchase_create_invoice_atomic_v2(
  uuid,uuid,uuid,uuid,date,text,text,text,text,jsonb,text
) TO service_role;

COMMIT;
