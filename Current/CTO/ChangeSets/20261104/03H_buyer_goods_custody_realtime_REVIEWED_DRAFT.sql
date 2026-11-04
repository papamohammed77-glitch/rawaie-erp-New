-- RAWAEA ERP — Buyer goods custody Realtime membership
-- يضاف بعد إنشاء الجدول وتفعيل RLS والسياسات. لا ينشئ جدولًا أو Edge Function.

BEGIN;

DO $$
BEGIN
  IF to_regclass('public.buyer_goods_custody_events') IS NULL THEN
    RAISE EXCEPTION 'BUYER_GOODS_CUSTODY_EVENTS_TABLE_MISSING';
  END IF;

  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname='supabase_realtime')
     AND NOT EXISTS (
       SELECT 1 FROM pg_publication_tables
       WHERE pubname='supabase_realtime'
         AND schemaname='public'
         AND tablename='buyer_goods_custody_events'
     ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.buyer_goods_custody_events;
  END IF;
END $$;

COMMIT;

-- لا توسع Realtime إلى جداول أخرى هنا. نطاق الحدث محدود بدفتر الحيازة.
-- تحقق من RLS وسياسة القراءة للشركة/المستخدم قبل اختبار WebSocket المصادق عليه.
-- في التراجع: أزل الجدول من النشر قبل DROP، بعد التحقق من خلوه ومن عدم وجود مستهلك حي.
