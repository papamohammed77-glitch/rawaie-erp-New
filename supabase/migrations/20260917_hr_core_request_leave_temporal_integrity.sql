-- RAWAEA ERP — HR Core request/leave/temporal integrity closure
-- Applied to Production 2026-09-17 as migration hr_core_request_leave_temporal_integrity_20260917_v3.
-- This canonical file preserves the exact surgical strategy used in Production:
-- modify the existing hr_command_atomic implementation in-place, without creating
-- another overload or duplicating the HR command engine.
--
-- Scope:
--   request.create
--   leave.request.approve/reject/cancel
--   request rejection/final-step semantics
--   effective-dated assignment/schedule overlap guards
--   active contract overlap and non-negative compensation guards
--
-- IMPORTANT:
-- This migration is intentionally anchored to the existing Production function
-- signature. It is not a standalone replacement of the whole HR command engine.

BEGIN;

DO $do$
DECLARE
  v_def text;
  v_old text;
  v_new text;
BEGIN
  SELECT pg_get_functiondef(p.oid) INTO v_def
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public'
    AND p.proname='hr_command_atomic'
    AND pg_get_function_identity_arguments(p.oid)='p_command text, p_payload jsonb, p_operation_id text, p_actor_user_id uuid, p_actor_email text';

  IF v_def IS NULL THEN
    RAISE EXCEPTION 'hr_command_atomic not found';
  END IF;

  v_old := $$  v_contract public.hr_contracts%ROWTYPE;
  v_leave_type public.hr_leave_types%ROWTYPE;$$;
  v_new := $$  v_contract public.hr_contracts%ROWTYPE;
  v_leave_type public.hr_leave_types%ROWTYPE;
  v_step_count integer:=0;
  v_step_no integer:=0;
  v_leave_year integer;
  v_slice_start date;
  v_slice_end date;
  v_slice_days numeric:=0;$$;

  IF strpos(v_def,v_old)=0 THEN
    RAISE EXCEPTION 'Declaration anchor missing';
  END IF;
  v_def:=replace(v_def,v_old,v_new);

  v_old := $$
 ELSIF p_command IN ('request.approve','request.reject') THEN
$$;
  v_new := $$
  ELSIF p_command='request.create' THEN
    IF NOT EXISTS(
      SELECT 1 FROM public.users u
      WHERE u.id=coalesce(NULLIF(p_payload->>'employee_id','')::uuid,v_actor.id)
        AND u.company_id=v_company_id
        AND u.status IS DISTINCT FROM 'Inactive'
    ) THEN
      RAISE EXCEPTION 'الموظف لا يتبع الشركة أو غير نشط';
    END IF;
    IF NULLIF(btrim(p_payload->>'request_type'),'') IS NULL THEN
      RAISE EXCEPTION 'نوع الطلب مطلوب';
    END IF;
    IF NULLIF(btrim(p_payload->>'subject'),'') IS NULL THEN
      RAISE EXCEPTION 'موضوع الطلب مطلوب';
    END IF;
    IF jsonb_typeof(p_payload->'approval_steps')<>'array'
       OR jsonb_array_length(p_payload->'approval_steps')=0 THEN
      RAISE EXCEPTION 'يجب تعريف خطوة اعتماد واحدة على الأقل';
    END IF;
    v_step_count:=jsonb_array_length(p_payload->'approval_steps');
    v_step_no:=0;
    FOR e IN SELECT value FROM jsonb_array_elements(p_payload->'approval_steps') LOOP
      v_step_no:=v_step_no+1;
      IF coalesce((e->>'step_no')::integer,v_step_no)<>v_step_no THEN
        RAISE EXCEPTION 'خطوات الاعتماد يجب أن تكون متسلسلة';
      END IF;
      IF NULLIF(btrim(e->>'approver_employee_id'),'') IS NULL
         AND NULLIF(btrim(e->>'approver_role'),'') IS NULL THEN
        RAISE EXCEPTION 'كل خطوة اعتماد يجب أن تحتوي معتمدًا محددًا أو دورًا';
      END IF;
      IF NULLIF(btrim(e->>'approver_employee_id'),'') IS NOT NULL
         AND NOT EXISTS(
           SELECT 1 FROM public.users u
           WHERE u.id=(e->>'approver_employee_id')::uuid
             AND u.company_id=v_company_id
             AND u.status IS DISTINCT FROM 'Inactive'
         ) THEN
        RAISE EXCEPTION 'المعتمد لا يتبع الشركة أو غير نشط';
      END IF;
    END LOOP;
    v_code:='HRQ-'||to_char(clock_timestamp(),'YYYYMMDDHH24MISSMS')||'-'||substr(replace(gen_random_uuid()::text,'-',''),1,6);
    INSERT INTO public.hr_requests(
      company_id,employee_id,request_no,request_type,subject,payload,status,
      current_step,total_steps,requested_at,operation_id,created_by
    )
    VALUES(
      v_company_id,coalesce(NULLIF(p_payload->>'employee_id','')::uuid,v_actor.id),
      v_code,btrim(p_payload->>'request_type'),btrim(p_payload->>'subject'),
      coalesce(p_payload->'payload','{}'::jsonb),'pending_approval',1,v_step_count,
      now(),p_operation_id,v_actor.email
    )
    RETURNING id INTO v_id;

    v_step_no:=0;
    FOR e IN SELECT value FROM jsonb_array_elements(p_payload->'approval_steps') LOOP
      v_step_no:=v_step_no+1;
      INSERT INTO public.hr_request_approvals(
        company_id,request_id,step_no,approver_employee_id,approver_role,status
      )
      VALUES(
        v_company_id,v_id,v_step_no,
        NULLIF(e->>'approver_employee_id','')::uuid,
        NULLIF(btrim(e->>'approver_role'),''),'pending'
      );
    END LOOP;

    v_result:=jsonb_build_object(
      'success',true,'request_id',v_id,'request_no',v_code,
      'status','pending_approval','current_step',1,
      'total_steps',v_step_count,'operation_id',p_operation_id
    );

  ELSIF p_command IN ('leave.request.approve','leave.request.reject','leave.request.cancel') THEN
    SELECT * INTO v_leave_status_before
    FROM public.employee_leave_requests
    WHERE id=(p_payload->>'leave_request_id')::uuid
      AND company_id=v_company_id
    FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'طلب الإجازة غير موجود ضمن الشركة الحالية';
    END IF;

    IF p_command='leave.request.approve' THEN
      IF v_leave_status_before.status<>'pending' THEN
        RAISE EXCEPTION 'لا يمكن اعتماد طلب إجازة غير معلق';
      END IF;

      v_leave_employee_id:=v_leave_status_before.employee_id;
      v_leave_type_id:=v_leave_status_before.leave_type_id;

      IF v_leave_type_id IS NULL THEN
        SELECT count(*),min(id) INTO v_step_count,v_leave_type_id
        FROM public.hr_leave_types
        WHERE company_id=v_company_id
          AND is_active=true
          AND (
            lower(code)=lower(btrim(v_leave_status_before.leave_type))
            OR lower(name)=lower(btrim(v_leave_status_before.leave_type))
          );
        IF v_step_count<>1 THEN
          RAISE EXCEPTION 'نوع الإجازة غير قابل للحسم بشكل فريد';
        END IF;
      END IF;

      SELECT * INTO v_leave_type
      FROM public.hr_leave_types
      WHERE id=v_leave_type_id
        AND company_id=v_company_id
        AND is_active=true
      FOR UPDATE;

      IF NOT FOUND THEN
        RAISE EXCEPTION 'نوع الإجازة غير موجود أو غير فعال';
      END IF;

      IF EXISTS(
        SELECT 1
        FROM public.employee_leave_requests l
        WHERE l.company_id=v_company_id
          AND l.employee_id=v_leave_employee_id
          AND l.id<>v_leave_status_before.id
          AND l.status IN('pending','approved')
          AND l.start_date<=v_leave_status_before.end_date
          AND l.end_date>=v_leave_status_before.start_date
      ) THEN
        RAISE EXCEPTION 'توجد إجازة قائمة متداخلة مع هذه الفترة';
      END IF;

      IF v_leave_type.paid THEN
        FOR v_leave_year IN
          extract(year from v_leave_status_before.start_date)::integer..
          extract(year from v_leave_status_before.end_date)::integer
        LOOP
          v_slice_start:=greatest(v_leave_status_before.start_date,make_date(v_leave_year,1,1));
          v_slice_end:=least(v_leave_status_before.end_date,make_date(v_leave_year,12,31));
          v_slice_days:=(v_slice_end-v_slice_start)+1;

          SELECT * INTO v_balance
          FROM public.hr_leave_balances
          WHERE company_id=v_company_id
            AND employee_id=v_leave_employee_id
            AND leave_type_id=v_leave_type.id
            AND year=v_leave_year
          FOR UPDATE;

          IF NOT FOUND THEN
            RAISE EXCEPTION 'رصيد الإجازة غير مهيأ للسنة %',v_leave_year;
          END IF;

          IF (
            coalesce(v_balance.opening_balance,0)
            +coalesce(v_balance.accrued,0)
            +coalesce(v_balance.adjusted,0)
            -coalesce(v_balance.used,0)
          ) < v_slice_days THEN
            RAISE EXCEPTION 'رصيد الإجازة غير كافٍ للسنة %',v_leave_year;
          END IF;

          UPDATE public.hr_leave_balances
          SET used=coalesce(used,0)+v_slice_days,
              updated_at=now()
          WHERE id=v_balance.id
            AND company_id=v_company_id;
        END LOOP;
      END IF;

      UPDATE public.employee_leave_requests
      SET status='approved',
          leave_type_id=v_leave_type.id,
          approved_by=v_actor.email,
          approved_at=now(),
          notes=coalesce(p_payload->>'notes',notes),
          updated_at=now()
      WHERE id=v_leave_status_before.id
        AND company_id=v_company_id
        AND status='pending';

      IF NOT FOUND THEN
        RAISE EXCEPTION 'فشل اعتماد طلب الإجازة';
      END IF;

      v_result:=jsonb_build_object(
        'success',true,
        'leave_request_id',v_leave_status_before.id,
        'status','approved',
        'leave_type_id',v_leave_type.id
      );

    ELSIF p_command='leave.request.reject' THEN
      IF v_leave_status_before.status<>'pending' THEN
        RAISE EXCEPTION 'لا يمكن رفض طلب إجازة غير معلق';
      END IF;

      UPDATE public.employee_leave_requests
      SET status='rejected',
          approved_by=NULL,
          approved_at=NULL,
          notes=coalesce(p_payload->>'reason',p_payload->>'notes',notes),
          updated_at=now()
      WHERE id=v_leave_status_before.id
        AND company_id=v_company_id
        AND status='pending';

      IF NOT FOUND THEN
        RAISE EXCEPTION 'فشل رفض طلب الإجازة';
      END IF;

      v_result:=jsonb_build_object(
        'success',true,
        'leave_request_id',v_leave_status_before.id,
        'status','rejected'
      );

    ELSE
      IF v_leave_status_before.status NOT IN('pending','approved') THEN
        RAISE EXCEPTION 'لا يمكن إلغاء طلب الإجازة في حالته الحالية';
      END IF;

      IF v_leave_status_before.status='approved'
         AND v_leave_status_before.leave_type_id IS NOT NULL THEN
        v_leave_employee_id:=v_leave_status_before.employee_id;
        v_leave_type_id:=v_leave_status_before.leave_type_id;

        SELECT * INTO v_leave_type
        FROM public.hr_leave_types
        WHERE id=v_leave_type_id
          AND company_id=v_company_id
        FOR UPDATE;

        IF FOUND AND v_leave_type.paid THEN
          FOR v_leave_year IN
            extract(year from v_leave_status_before.start_date)::integer..
            extract(year from v_leave_status_before.end_date)::integer
          LOOP
            v_slice_start:=greatest(v_leave_status_before.start_date,make_date(v_leave_year,1,1));
            v_slice_end:=least(v_leave_status_before.end_date,make_date(v_leave_year,12,31));
            v_slice_days:=(v_slice_end-v_slice_start)+1;

            SELECT * INTO v_balance
            FROM public.hr_leave_balances
            WHERE company_id=v_company_id
              AND employee_id=v_leave_employee_id
              AND leave_type_id=v_leave_type.id
              AND year=v_leave_year
            FOR UPDATE;

            IF NOT FOUND THEN
              RAISE EXCEPTION 'رصيد الإجازة غير مهيأ للسنة %',v_leave_year;
            END IF;

            IF coalesce(v_balance.used,0)<v_slice_days THEN
              RAISE EXCEPTION 'بيانات رصيد الإجازة لا تسمح بعكس الإجازة للسنة %',v_leave_year;
            END IF;

            UPDATE public.hr_leave_balances
            SET used=used-v_slice_days,
                updated_at=now()
            WHERE id=v_balance.id
              AND company_id=v_company_id;
          END LOOP;
        END IF;
      END IF;

      UPDATE public.employee_leave_requests
      SET status='cancelled',
          cancelled_at=now(),
          cancelled_by=v_actor.email,
          notes=coalesce(p_payload->>'reason',p_payload->>'notes',notes),
          updated_at=now()
      WHERE id=v_leave_status_before.id
        AND company_id=v_company_id
        AND status IN('pending','approved');

      IF NOT FOUND THEN
        RAISE EXCEPTION 'فشل إلغاء طلب الإجازة';
      END IF;

      v_result:=jsonb_build_object(
        'success',true,
        'leave_request_id',v_leave_status_before.id,
        'status','cancelled'
      );
    END IF;

  ELSIF p_command IN ('request.approve','request.reject') THEN

  v_old := $$UPDATE public.hr_requests SET status='rejected',rejected_reason=p_payload->>'reason',approved_by=v_actor.email,approved_at=now(),updated_at=now()$$;
  v_new := $$UPDATE public.hr_requests SET status='rejected',rejected_reason=p_payload->>'reason',approved_by=NULL,approved_at=NULL,updated_at=now()$$;
  IF strpos(v_def,v_old)>0 THEN
    v_def:=replace(v_def,v_old,v_new);
  END IF;

  v_old := $$UPDATE public.hr_requests SET current_step=current_step+1,
          status=CASE WHEN current_step>=total_steps THEN 'approved' ELSE 'pending_approval' END,$$;
  v_new := $$UPDATE public.hr_requests SET current_step=CASE WHEN current_step>=total_steps THEN total_steps ELSE current_step+1 END,
          status=CASE WHEN current_step>=total_steps THEN 'approved' ELSE 'pending_approval' END,$$;
  IF strpos(v_def,v_old)>0 THEN
    v_def:=replace(v_def,v_old,v_new);
  END IF;

  v_old := $$    INSERT INTO public.hr_employee_assignments(company_id,employee_id$$;
  v_new := $$    IF NULLIF(p_payload->>'effective_from','') IS NULL THEN RAISE EXCEPTION 'تاريخ بداية التعيين مطلوب'; END IF;
    IF NULLIF(p_payload->>'effective_to','') IS NOT NULL AND (p_payload->>'effective_to')::date<(p_payload->>'effective_from')::date THEN RAISE EXCEPTION 'نطاق التعيين الزمني غير صالح'; END IF;
    IF coalesce((p_payload->>'is_primary')::boolean,true) AND EXISTS(
      SELECT 1 FROM public.hr_employee_assignments a
      WHERE a.company_id=v_company_id
        AND a.employee_id=(p_payload->>'employee_id')::uuid
        AND a.is_primary=true
        AND coalesce(a.effective_to,'9999-12-31'::date)>=(p_payload->>'effective_from')::date
        AND coalesce(NULLIF(p_payload->>'effective_to','')::date,'9999-12-31'::date)>=a.effective_from
    ) THEN RAISE EXCEPTION 'يوجد تعيين أساسي متداخل للموظف في نفس الفترة'; END IF;
    INSERT INTO public.hr_employee_assignments(company_id,employee_id$$;
  IF strpos(v_def,v_old)=0 THEN RAISE EXCEPTION 'Assignment insert anchor missing'; END IF;
  v_def:=replace(v_def,v_old,v_new);

  v_old := $$    INSERT INTO public.hr_employee_schedule_assignments(company_id,employee_id$$;
  v_new := $$    IF NULLIF(p_payload->>'effective_from','') IS NULL THEN RAISE EXCEPTION 'تاريخ بداية الجدول مطلوب'; END IF;
    IF NULLIF(p_payload->>'effective_to','') IS NOT NULL AND (p_payload->>'effective_to')::date<(p_payload->>'effective_from')::date THEN RAISE EXCEPTION 'نطاق الجدول الزمني غير صالح'; END IF;
    IF EXISTS(
      SELECT 1 FROM public.hr_employee_schedule_assignments a
      WHERE a.company_id=v_company_id
        AND a.employee_id=(p_payload->>'employee_id')::uuid
        AND coalesce(a.effective_to,'9999-12-31'::date)>=(p_payload->>'effective_from')::date
        AND coalesce(NULLIF(p_payload->>'effective_to','')::date,'9999-12-31'::date)>=a.effective_from
    ) THEN RAISE EXCEPTION 'يوجد جدول عمل متداخل للموظف في نفس الفترة'; END IF;
    INSERT INTO public.hr_employee_schedule_assignments(company_id,employee_id$$;
  IF strpos(v_def,v_old)=0 THEN RAISE EXCEPTION 'Schedule assignment insert anchor missing'; END IF;
  v_def:=replace(v_def,v_old,v_new);

  v_old := $$    INSERT INTO public.hr_contracts(company_id,employee_id$$;
  v_new := $$    IF coalesce((p_payload->>'basic_salary')::numeric,0)<0 OR coalesce((p_payload->>'housing_allowance')::numeric,0)<0 OR coalesce((p_payload->>'transport_allowance')::numeric,0)<0 OR coalesce((p_payload->>'other_allowance')::numeric,0)<0 OR coalesce((p_payload->>'default_deduction')::numeric,0)<0 THEN RAISE EXCEPTION 'قيم العقد المالية لا يمكن أن تكون سالبة'; END IF;
    IF NULLIF(p_payload->>'start_date','') IS NULL THEN RAISE EXCEPTION 'تاريخ بداية العقد مطلوب'; END IF;
    IF NULLIF(p_payload->>'end_date','') IS NOT NULL AND (p_payload->>'end_date')::date<(p_payload->>'start_date')::date THEN RAISE EXCEPTION 'نطاق العقد الزمني غير صالح'; END IF;
    IF coalesce(NULLIF(p_payload->>'status',''),'active')='active' AND EXISTS(
      SELECT 1 FROM public.hr_contracts c
      WHERE c.company_id=v_company_id
        AND c.employee_id=(p_payload->>'employee_id')::uuid
        AND c.status='active'
        AND c.contract_no<>btrim(p_payload->>'contract_no')
        AND coalesce(c.end_date,'9999-12-31'::date)>=(p_payload->>'start_date')::date
        AND coalesce(NULLIF(p_payload->>'end_date','')::date,'9999-12-31'::date)>=c.start_date
    ) THEN RAISE EXCEPTION 'يوجد عقد فعال متداخل للموظف في نفس الفترة'; END IF;
    INSERT INTO public.hr_contracts(company_id,employee_id$$;
  IF strpos(v_def,v_old)=0 THEN RAISE EXCEPTION 'Contract insert anchor missing'; END IF;
  v_def:=replace(v_def,v_old,v_new);

  EXECUTE v_def;
END;
$do$;

COMMIT;
