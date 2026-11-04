-- RAWAEA ERP — Buyer Phase 1
-- منع تكرار رقم فاتورة المورد على مستوى الشركة/المورد، مع حماية التزامن.
-- يُستدعى من wrappers الخاصة بـ Buyer. لا ينشئ Edge Function ولا يغير بيانات قائمة.

BEGIN;

CREATE OR REPLACE FUNCTION app_private.assert_unique_purchase_supplier_invoice(
  p_company_id uuid,
  p_supplier_id uuid,
  p_supplier_invoice_no text,
  p_exclude_invoice_id uuid DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SET search_path TO ''
AS $function$
DECLARE
  v_number text:=NULLIF(upper(btrim(p_supplier_invoice_no)),'');
BEGIN
  IF v_number IS NULL THEN
    RETURN;
  END IF;

  PERFORM pg_advisory_xact_lock(
    hashtextextended(
      'RAWAEA:SUPPLIER-INVOICE:'||p_company_id::text||':'||
      p_supplier_id::text||':'||v_number,
      0
    )
  );

  IF EXISTS (
    SELECT 1
    FROM public.purchase_invoices i
    WHERE i.company_id=p_company_id
      AND i.supplier_id=p_supplier_id
      AND upper(btrim(i.supplier_invoice_no))=v_number
      AND i.status<>'Cancelled'
      AND (p_exclude_invoice_id IS NULL OR i.id<>p_exclude_invoice_id)
  ) THEN
    RAISE EXCEPTION 'PURCHASE_SUPPLIER_INVOICE_DUPLICATE:%',v_number;
  END IF;
END;
$function$;

REVOKE ALL ON FUNCTION app_private.assert_unique_purchase_supplier_invoice(uuid,uuid,text,uuid)
  FROM PUBLIC, anon, authenticated;

COMMIT;

-- استدعاء الدالة قبل create/update في:
-- purchase_create_po_invoice_atomic(..., p_invoice_id = NULL)
-- purchase_update_po_invoice_atomic(..., p_invoice_id)
-- purchase_create_quick_market_invoice_atomic(..., p_invoice_id = NULL)
-- purchase_update_quick_market_invoice_atomic(..., p_invoice_id)
--
-- Quick Market يظل ملزمًا برقم فاتورة المورد غير الفارغ.
-- PO يسمح برقم فارغ إن كانت سياسة المستند تسمح، لكن عند إدخاله يمنع تكراره.
-- لا يطبق هذا القيد على الفواتير التاريخية عند الترحيل أو أي تحديث لا يغير الرقم.
