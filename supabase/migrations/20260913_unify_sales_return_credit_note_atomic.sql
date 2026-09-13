BEGIN;

ALTER TABLE public.credit_notes
  ADD COLUMN IF NOT EXISTS operation_key text;

CREATE UNIQUE INDEX IF NOT EXISTS credit_notes_company_operation_key_uidx
  ON public.credit_notes(company_id, operation_key)
  WHERE operation_key IS NOT NULL;

CREATE OR REPLACE FUNCTION public.complete_sales_return_credit_note_atomic(
  p_company_id uuid,
  p_runsheet_code text,
  p_order_code text,
  p_is_pos_return boolean,
  p_user_email text,
  p_items jsonb,
  p_reason text DEFAULT 'مرتجع بضاعة'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_fingerprint text;
  v_operation_key text;
  v_return_result jsonb;
  v_existing public.credit_notes%ROWTYPE;
  v_order public.orders%ROWTYPE;
  v_runsheet public.runsheets%ROWTYPE;
  v_total numeric := 0;
  v_cn_id uuid;
  v_cn_code text;
BEGIN
  IF p_company_id IS NULL OR NULLIF(btrim(p_user_email),'') IS NULL THEN
    RAISE EXCEPTION 'سياق الشركة/المستخدم غير صالح';
  END IF;
  IF p_items IS NULL OR jsonb_typeof(p_items) <> 'array' OR jsonb_array_length(p_items)=0 THEN
    RAISE EXCEPTION 'بيانات المرتجع غير مكتملة';
  END IF;

  v_fingerprint := md5(
    p_company_id::text || '|' ||
    COALESCE(p_runsheet_code,'') || '|' ||
    COALESCE(p_order_code,'') || '|' ||
    COALESCE(p_is_pos_return,false)::text || '|' ||
    p_items::text
  );
  v_operation_key := md5(p_company_id::text || '|sales-return-credit-note|' || v_fingerprint);

  SELECT * INTO v_existing
  FROM public.credit_notes
  WHERE company_id = p_company_id
    AND operation_key = v_operation_key
  FOR UPDATE;

  IF FOUND THEN
    RETURN jsonb_build_object(
      'success', true,
      'duplicate', true,
      'creditNoteId', v_existing.id,
      'creditNoteCode', v_existing.cn_code,
      'totalAmount', COALESCE(v_existing.total_amount,0),
      'operation_key', v_operation_key
    );
  END IF;

  v_return_result := public.complete_return_atomic(
    p_company_id,
    p_runsheet_code,
    p_order_code,
    p_is_pos_return,
    p_user_email,
    p_items
  );

  IF COALESCE((v_return_result->>'success')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'فشل تنفيذ المرتجع قبل إنشاء الإشعار الدائن';
  END IF;

  IF p_order_code IS NOT NULL THEN
    SELECT * INTO v_order
    FROM public.orders
    WHERE company_id = p_company_id
      AND order_code = p_order_code;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'الأوردر غير موجود بعد إتمام المرتجع';
    END IF;
  END IF;

  IF p_runsheet_code IS NOT NULL THEN
    SELECT * INTO v_runsheet
    FROM public.runsheets
    WHERE company_id = p_company_id
      AND runsheet_code = p_runsheet_code;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'الرانشيت غير موجود بعد إتمام المرتجع';
    END IF;
  END IF;

  SELECT COALESCE((v_return_result->>'total_returned_value')::numeric,0) INTO v_total;
  v_cn_code := 'CN-' || replace(v_operation_key,'-','');

  INSERT INTO public.credit_notes(
    cn_code, cn_date, company_id, order_id, runsheet_id,
    customer_id, customer_name, total_amount, reason, status,
    created_by, operation_key
  )
  VALUES(
    v_cn_code, CURRENT_DATE, p_company_id,
    CASE WHEN p_order_code IS NOT NULL THEN v_order.id ELSE NULL END,
    CASE WHEN p_runsheet_code IS NOT NULL THEN v_runsheet.id ELSE NULL END,
    CASE WHEN p_order_code IS NOT NULL THEN v_order.customer_id ELSE NULL END,
    CASE WHEN p_order_code IS NOT NULL THEN v_order.customer_name ELSE NULL END,
    v_total, COALESCE(NULLIF(btrim(p_reason),''),'مرتجع بضاعة'),
    'Posted', p_user_email, v_operation_key
  )
  RETURNING id INTO v_cn_id;

  INSERT INTO public.audit_log(user_email,action,table_name,record_id,new_data)
  VALUES(
    p_user_email,'create','credit_notes',v_cn_id::text,
    jsonb_build_object(
      'credit_note_code', v_cn_code,
      'operation_key', v_operation_key,
      'return_result', v_return_result
    )
  );

  RETURN v_return_result || jsonb_build_object(
    'creditNoteId', v_cn_id,
    'creditNoteCode', v_cn_code,
    'creditNoteAmount', v_total,
    'operation_key', v_operation_key
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.complete_sales_return_credit_note_atomic(uuid,text,text,boolean,text,jsonb,text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.complete_sales_return_credit_note_atomic(uuid,text,text,boolean,text,jsonb,text)
  TO service_role;

DROP INDEX IF EXISTS public.orders_company_operation_id_unique;

COMMIT;
