-- RAWAEA ERP — Buyer Phase 1 rollback preflight
-- ينفذ بعد إرجاع Buyer وEdge إلى الإصدار السابق، وقبل ملف 06.
-- يوقف التراجع إذا بقيت سجلات idempotency أو عمليات Realtime تعتمد على الدفتر.

BEGIN;

DO $$
DECLARE
  v_ops bigint:=0;
BEGIN
  IF to_regclass('public.erp_operation_registry') IS NOT NULL THEN
    SELECT count(*) INTO v_ops
    FROM public.erp_operation_registry
    WHERE operation_type IN (
      'purchase_update_po_invoice_atomic',
      'purchase_update_quick_market_invoice_atomic'
    );
  END IF;

  IF v_ops>0 THEN
    RAISE EXCEPTION 'BUYER_PHASE1_ROLLBACK_BLOCKED: idempotency registry rows exist (%)',v_ops;
  END IF;

  IF to_regclass('public.buyer_goods_custody_events') IS NOT NULL
     AND EXISTS (SELECT 1 FROM pg_publication WHERE pubname='supabase_realtime')
     AND EXISTS (
       SELECT 1 FROM pg_publication_tables
       WHERE pubname='supabase_realtime'
         AND schemaname='public'
         AND tablename='buyer_goods_custody_events'
     ) THEN
    ALTER PUBLICATION supabase_realtime DROP TABLE public.buyer_goods_custody_events;
  END IF;
END $$;

COMMIT;

-- إذا اجتاز هذا الملف: راجع counts مرة أخرى ثم نفذ 06.
-- إذا فشل: لا تنفذ 06 ولا تحذف سجلًا أو حدثًا يدويًا؛ أجرِ مطابقة الأعمال أولًا.
