BEGIN;

DO $do$
DECLARE
  v_def text;
  v_old text;
  v_new text;
BEGIN
  SELECT pg_get_functiondef(p.oid) INTO v_def
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.proname = 'hr_command_atomic'
    AND pg_get_function_identity_arguments(p.oid) = 'p_command text, p_payload jsonb, p_operation_id text, p_actor_user_id uuid, p_actor_email text';

  IF v_def IS NULL THEN RAISE EXCEPTION 'hr_command_atomic not found'; END IF;

  v_old := $$    'request.approve','request.reject','leave.request.approve'$$;
  v_new := $$    'leave.request.approve'$$;
  IF strpos(v_def, v_old) = 0 THEN RAISE EXCEPTION 'Expected HR command permission list was not found'; END IF;
  v_def := replace(v_def, v_old, v_new);

  v_old := $$  ELSIF p_command IN ('request.approve','request.reject') THEN
$$;
  v_new := $$  ELSIF p_command IN ('request.approve','request.reject') THEN
    IF NOT v_actor_hr AND NOT EXISTS (
      SELECT 1
      FROM public.hr_requests r
      JOIN public.hr_request_approvals a
        ON a.request_id = r.id
       AND a.company_id = v_company_id
       AND a.step_no = r.current_step
      WHERE r.id = (p_payload->>'request_id')::uuid
        AND r.company_id = v_company_id
        AND r.status = 'pending_approval'
        AND a.status = 'pending'
        AND (
          a.approver_employee_id = v_actor.id
          OR (
            a.approver_employee_id IS NULL
            AND NULLIF(btrim(a.approver_role), '') IS NOT NULL
            AND lower(btrim(a.approver_role)) = lower(btrim(coalesce(v_actor.role, '')))
          )
        )
    ) THEN
      v_result := jsonb_build_object(
        'success', false,
        'code', 'REQUEST_APPROVER_SCOPE',
        'msg', 'المستخدم الحالي ليس المعتمد المعيّن لهذه الخطوة'
      );
      UPDATE public.hr_command_log
         SET status = 'completed', result = v_result, completed_at = now()
       WHERE id = v_log.id;
      RETURN v_result;
    END IF;
$$;
  IF strpos(v_def, v_old) = 0 THEN RAISE EXCEPTION 'Expected request approval branch was not found'; END IF;
  v_def := replace(v_def, v_old, v_new);

  EXECUTE v_def;
END;
$do$;

DO $do$
DECLARE
  v_def text;
  v_old text;
  v_new text;
BEGIN
  SELECT pg_get_functiondef(p.oid) INTO v_def
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.proname = 'hr_query'
    AND pg_get_function_identity_arguments(p.oid) = 'p_view text, p_payload jsonb';

  IF v_def IS NULL THEN RAISE EXCEPTION 'hr_query not found'; END IF;

  v_old := $$      WHERE r.company_id=v_company AND (v_hr OR r.employee_id=v_uid) ORDER BY r.requested_at DESC LIMIT 100$$;
  v_new := $$      WHERE r.company_id=v_company
        AND (
          v_hr
          OR r.employee_id=v_uid
          OR EXISTS (
            SELECT 1
            FROM hr_request_approvals aa
            WHERE aa.request_id=r.id
              AND aa.company_id=v_company
              AND aa.step_no=r.current_step
              AND aa.status='pending'
              AND (
                aa.approver_employee_id=v_uid
                OR (
                  aa.approver_employee_id IS NULL
                  AND NULLIF(btrim(aa.approver_role),'') IS NOT NULL
                  AND lower(btrim(aa.approver_role))=lower(btrim(coalesce((SELECT u.role FROM users u WHERE u.id=v_uid AND u.company_id=v_company LIMIT 1),'')))
                )
              )
          )
        )
      ORDER BY r.requested_at DESC LIMIT 100$$;
  IF strpos(v_def, v_old) = 0 THEN RAISE EXCEPTION 'Expected requests query predicate was not found'; END IF;
  v_def := replace(v_def, v_old, v_new);

  v_old := $$      WHERE a.company_id=v_company AND (v_hr OR r.employee_id=v_uid)
      ORDER BY r.requested_at DESC,a.step_no$$;
  v_new := $$      WHERE a.company_id=v_company
        AND (
          v_hr
          OR r.employee_id=v_uid
          OR a.approver_employee_id=v_uid
          OR (
            a.approver_employee_id IS NULL
            AND NULLIF(btrim(a.approver_role),'') IS NOT NULL
            AND lower(btrim(a.approver_role))=lower(btrim(coalesce((SELECT u.role FROM users u WHERE u.id=v_uid AND u.company_id=v_company LIMIT 1),'')))
          )
        )
      ORDER BY r.requested_at DESC,a.step_no$$;
  IF strpos(v_def, v_old) = 0 THEN RAISE EXCEPTION 'Expected request_approvals query predicate was not found'; END IF;
  v_def := replace(v_def, v_old, v_new);

  EXECUTE v_def;
END;
$do$;

COMMIT;
