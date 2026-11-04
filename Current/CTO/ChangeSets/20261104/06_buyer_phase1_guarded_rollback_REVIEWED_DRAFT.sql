-- RAWAEA ERP — Buyer Phase 1
-- تراجع محكوم — لا ينفذ إلا بعد إرجاع Buyer وEdge إلى الإصدار السابق أولًا.
-- شغّل 06A أولًا لفك عضوية Realtime وفحص سجلات idempotency.
-- يمنع هذا الملف الإسقاط إذا وُجدت أي حركة حيازة أو فاتورة مصنفة جديدة.
-- لا يلمس الفواتير التاريخية أو قيودها أو المخزون أو دفتر المورد.

BEGIN;

DO $$
DECLARE
  v_event_count bigint:=0;
  v_classified_invoice_count bigint:=0;
BEGIN
  IF to_regclass('public.buyer_goods_custody_events') IS NOT NULL THEN
    EXECUTE 'SELECT count(*) FROM public.buyer_goods_custody_events' INTO v_event_count;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='purchase_invoices'
      AND column_name='purchase_source'
  ) THEN
    EXECUTE $q$
      SELECT count(*) FROM public.purchase_invoices
      WHERE purchase_source IS DISTINCT FROM 'LEGACY_UNCLASSIFIED'
         OR settlement_source IS DISTINCT FROM 'UNSET'
         OR purchaser_user_id IS NOT NULL
         OR cash_custody_id IS NOT NULL
         OR receipt_status IS DISTINCT FROM 'LEGACY_UNVERIFIED'
         OR settlement_status IS DISTINCT FROM 'LEGACY_UNVERIFIED'
         OR source_payload_fingerprint IS NOT NULL
    $q$ INTO v_classified_invoice_count;
  END IF;

  IF v_event_count>0 THEN
    RAISE EXCEPTION 'BUYER_PHASE1_ROLLBACK_BLOCKED: goods custody events exist (%)',v_event_count;
  END IF;

  IF v_classified_invoice_count>0 THEN
    RAISE EXCEPTION 'BUYER_PHASE1_ROLLBACK_BLOCKED: classified purchase invoices exist (%)',v_classified_invoice_count;
  END IF;
END $$;

-- 1. إزالة وظائف Buyer الجديدة بعد إرجاع نسخة Edge السابقة.
DROP FUNCTION IF EXISTS public.purchase_post_buyer_invoice_atomic(uuid,uuid,text);
DROP FUNCTION IF EXISTS public.buyer_goods_custody_get_invoice_handover_progress_atomic(uuid,uuid);
DROP FUNCTION IF EXISTS public.purchase_update_po_invoice_atomic(uuid,uuid,uuid,uuid,uuid,date,text,text,jsonb,text);
DROP FUNCTION IF EXISTS public.purchase_create_po_invoice_atomic(uuid,uuid,uuid,uuid,date,text,text,jsonb,text);
DROP FUNCTION IF EXISTS public.purchase_update_quick_market_invoice_atomic(uuid,uuid,uuid,uuid,date,text,text,jsonb,text,uuid,text);
DROP FUNCTION IF EXISTS public.purchase_delete_quick_market_draft_atomic(uuid,uuid,text,text,text);
DROP FUNCTION IF EXISTS public.buyer_goods_custody_get_balances_atomic(uuid,uuid);
DROP FUNCTION IF EXISTS public.buyer_goods_custody_register_handover_atomic(uuid,uuid,uuid,jsonb,text,text,text);
DROP FUNCTION IF EXISTS public.purchase_create_quick_market_invoice_atomic(uuid,uuid,uuid,date,text,text,jsonb,text,uuid,text);
DROP FUNCTION IF EXISTS public.purchase_update_buyer_legacy_draft_atomic(uuid,uuid,uuid,uuid,uuid,date,text,text,text,text,jsonb,text);
DROP FUNCTION IF EXISTS public.purchase_delete_buyer_draft_invoice_atomic(uuid,uuid,text,text,text);
DROP FUNCTION IF EXISTS app_private.assert_unique_purchase_supplier_invoice(uuid,uuid,text,uuid);

-- 2. إزالة محفز append-only وسياسة القراءة والجدول بعد التأكد أنه فارغ.
DO $$
BEGIN
  IF to_regclass('public.buyer_goods_custody_events') IS NOT NULL THEN
    EXECUTE 'DROP TRIGGER IF EXISTS buyer_goods_custody_events_append_only ON public.buyer_goods_custody_events';
    EXECUTE 'DROP POLICY IF EXISTS buyer_goods_custody_events_select_authorized ON public.buyer_goods_custody_events';
    EXECUTE 'DROP TABLE public.buyer_goods_custody_events';
  END IF;
END $$;

DROP FUNCTION IF EXISTS app_private.reject_buyer_goods_custody_event_mutation();

-- 3. إزالة فهارس وعقود تصنيف الفواتير الجديدة.
DROP INDEX IF EXISTS public.purchase_invoices_buyer_source_idx;
DROP INDEX IF EXISTS public.purchase_invoices_cash_custody_reservation_idx;

ALTER TABLE public.purchase_invoices
  DROP CONSTRAINT IF EXISTS purchase_invoices_purchaser_user_fk,
  DROP CONSTRAINT IF EXISTS purchase_invoices_cash_custody_fk,
  DROP CONSTRAINT IF EXISTS purchase_invoices_purchase_source_ck,
  DROP CONSTRAINT IF EXISTS purchase_invoices_settlement_source_ck,
  DROP CONSTRAINT IF EXISTS purchase_invoices_receipt_status_ck,
  DROP CONSTRAINT IF EXISTS purchase_invoices_settlement_status_ck,
  DROP CONSTRAINT IF EXISTS purchase_invoices_source_relation_ck,
  DROP CONSTRAINT IF EXISTS purchase_invoices_cash_custody_source_ck;

ALTER TABLE public.purchase_invoices
  DROP COLUMN IF EXISTS purchase_source,
  DROP COLUMN IF EXISTS settlement_source,
  DROP COLUMN IF EXISTS purchaser_user_id,
  DROP COLUMN IF EXISTS cash_custody_id,
  DROP COLUMN IF EXISTS receipt_status,
  DROP COLUMN IF EXISTS settlement_status,
  DROP COLUMN IF EXISTS source_payload_fingerprint;

COMMIT;

-- تنبيه:
-- أ. إذا كان جدول buyer_goods_custody_events منشورًا في Realtime، أزل عضويته من
--    supabase_realtime بعد التأكد من عدم وجود مستهلك حي يعتمد عليه.
-- ب. هذا التراجع لا يعكس معاملات مالية أو مخزنية؛ وجود أي حدث أو فاتورة مصنفة
--    يوقف التنفيذ عمدًا. العكس التجاري له مسار مستقل موثق.
-- ج. لا تعِد تحويل أي فاتورة تاريخية أو إسقاط أي بيانات قديمة.
