-- RAWAEA ERP — Buyer Phase 1 validation cleanup
-- تم إعداد هذا الملف لإزالة أثر اختبار DDL الذي أثبت أن execute_sql لا يضمن
-- rollback جماعيًا عبر الحزمة؛ لا يحتوي على حذف لأي معاملات أعمال.
-- شروط التحقق قبل التنفيذ في 2026-11-04:
-- buyer_goods_custody_events=0
-- invoices classified by purchase_source=0
-- new Buyer operation-registry rows=0
-- لا يوجد نشر UI/Edge متصل بهذه الوظائف بعد.

-- 1) سحب تنفيذ الوظائف الجديدة ثم إسقاطها
REVOKE ALL ON FUNCTION public.purchase_post_buyer_invoice_atomic(uuid,uuid,text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.buyer_goods_custody_get_invoice_handover_progress_atomic(uuid,uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.purchase_update_po_invoice_atomic(uuid,uuid,uuid,uuid,uuid,date,text,text,jsonb,text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.purchase_create_po_invoice_atomic(uuid,uuid,uuid,uuid,date,text,text,jsonb,text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.purchase_update_quick_market_invoice_atomic(uuid,uuid,uuid,uuid,date,text,text,jsonb,text,uuid,text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.purchase_delete_quick_market_draft_atomic(uuid,uuid,text,text,text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.buyer_goods_custody_get_balances_atomic(uuid,uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.buyer_goods_custody_register_handover_atomic(uuid,uuid,uuid,jsonb,text,text,text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.purchase_create_quick_market_invoice_atomic(uuid,uuid,uuid,date,text,text,jsonb,text,uuid,text) FROM PUBLIC, anon, authenticated;

DROP FUNCTION IF EXISTS public.purchase_post_buyer_invoice_atomic(uuid,uuid,text);
DROP FUNCTION IF EXISTS public.buyer_goods_custody_get_invoice_handover_progress_atomic(uuid,uuid);
DROP FUNCTION IF EXISTS public.purchase_update_po_invoice_atomic(uuid,uuid,uuid,uuid,uuid,date,text,text,jsonb,text);
DROP FUNCTION IF EXISTS public.purchase_create_po_invoice_atomic(uuid,uuid,uuid,uuid,date,text,text,jsonb,text);
DROP FUNCTION IF EXISTS public.purchase_update_quick_market_invoice_atomic(uuid,uuid,uuid,uuid,date,text,text,jsonb,text,uuid,text);
DROP FUNCTION IF EXISTS public.purchase_delete_quick_market_draft_atomic(uuid,uuid,text,text,text);
DROP FUNCTION IF EXISTS public.buyer_goods_custody_get_balances_atomic(uuid,uuid);
DROP FUNCTION IF EXISTS public.buyer_goods_custody_register_handover_atomic(uuid,uuid,uuid,jsonb,text,text,text);
DROP FUNCTION IF EXISTS public.purchase_create_quick_market_invoice_atomic(uuid,uuid,uuid,date,text,text,jsonb,text,uuid,text);

-- 2) فك عضوية Realtime، ثم إسقاط trigger/policy والجدول الفارغ
ALTER PUBLICATION supabase_realtime DROP TABLE public.buyer_goods_custody_events;
DROP TRIGGER IF EXISTS buyer_goods_custody_events_append_only ON public.buyer_goods_custody_events;
DROP POLICY IF EXISTS buyer_goods_custody_events_select_authorized ON public.buyer_goods_custody_events;
DROP TABLE public.buyer_goods_custody_events;
DROP FUNCTION IF EXISTS app_private.reject_buyer_goods_custody_event_mutation();

-- 3) إزالة indexes والقيود المضافة
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

-- لا يلمس الفواتير التاريخية، دفتر المورد، المخزون، الأستاذ العام أو الخزينة.
-- لا يحذف buyer_custodies أو المصروفات/السلف القائمة؛ فهي موجودة أصلًا قبل الاختبار.
