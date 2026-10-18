-- Production migration already applied to project fiilmooggumokxanwiyx.
-- Fix Storage RLS policy evaluation by using the current-user scoped helper.
-- Do NOT grant authenticated/anon EXECUTE on public.hr_user_has_permission(uuid,text).

ALTER POLICY employee_docs_storage_select
ON storage.objects
USING (
  bucket_id = 'employee-documents'
  AND EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.auth_id = auth.uid()
      AND COALESCE(u.status, 'Active') = 'Active'
      AND u.company_id = public.employee_document_storage_company_id(u.name)
      AND (
        app_private.current_user_has_permission('hr')
        OR u.id = public.employee_document_storage_employee_id(u.name)
      )
  )
);

ALTER POLICY employee_docs_storage_insert
ON storage.objects
WITH CHECK (
  bucket_id = 'employee-documents'
  AND EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.auth_id = auth.uid()
      AND COALESCE(u.status, 'Active') = 'Active'
      AND u.company_id = public.employee_document_storage_company_id(u.name)
      AND (
        app_private.current_user_has_permission('hr')
        OR u.id = public.employee_document_storage_employee_id(u.name)
      )
  )
);

ALTER POLICY employee_docs_storage_update
ON storage.objects
USING (
  bucket_id = 'employee-documents'
  AND EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.auth_id = auth.uid()
      AND COALESCE(u.status, 'Active') = 'Active'
      AND u.company_id = public.employee_document_storage_company_id(u.name)
      AND (
        app_private.current_user_has_permission('hr')
        OR u.id = public.employee_document_storage_employee_id(u.name)
      )
  )
)
WITH CHECK (
  bucket_id = 'employee-documents'
  AND EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.auth_id = auth.uid()
      AND COALESCE(u.status, 'Active') = 'Active'
      AND u.company_id = public.employee_document_storage_company_id(u.name)
      AND (
        app_private.current_user_has_permission('hr')
        OR u.id = public.employee_document_storage_employee_id(u.name)
      )
  )
);

ALTER POLICY employee_docs_storage_delete
ON storage.objects
USING (
  bucket_id = 'employee-documents'
  AND EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.auth_id = auth.uid()
      AND COALESCE(u.status, 'Active') = 'Active'
      AND u.company_id = public.employee_document_storage_company_id(u.name)
      AND (
        app_private.current_user_has_permission('hr')
        OR u.id = public.employee_document_storage_employee_id(u.name)
      )
  )
);
