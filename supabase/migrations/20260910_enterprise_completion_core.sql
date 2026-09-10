BEGIN;

CREATE TABLE IF NOT EXISTS public.employee_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  employee_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  document_type text NOT NULL,
  storage_path text,
  document_name text,
  mime_type text,
  expires_at date,
  status text NOT NULL DEFAULT 'active',
  notes text,
  created_by text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_employee_documents_company_employee ON public.employee_documents(company_id, employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_documents_expiry ON public.employee_documents(company_id, expires_at);
ALTER TABLE public.employee_documents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS employee_documents_same_company_select ON public.employee_documents;
CREATE POLICY employee_documents_same_company_select ON public.employee_documents FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.users u WHERE u.auth_id=auth.uid() AND u.company_id=employee_documents.company_id AND coalesce(u.status,'Active')='Active'));
DROP POLICY IF EXISTS employee_documents_same_company_write ON public.employee_documents;
CREATE POLICY employee_documents_same_company_write ON public.employee_documents FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM public.users u WHERE u.auth_id=auth.uid() AND u.company_id=employee_documents.company_id AND coalesce(u.status,'Active')='Active'));
DROP POLICY IF EXISTS employee_documents_same_company_update ON public.employee_documents;
CREATE POLICY employee_documents_same_company_update ON public.employee_documents FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM public.users u WHERE u.auth_id=auth.uid() AND u.company_id=employee_documents.company_id AND coalesce(u.status,'Active')='Active')) WITH CHECK (EXISTS (SELECT 1 FROM public.users u WHERE u.auth_id=auth.uid() AND u.company_id=employee_documents.company_id AND coalesce(u.status,'Active')='Active'));
INSERT INTO storage.buckets(id,name,public) VALUES('employee-documents','employee-documents',false) ON CONFLICT(id) DO UPDATE SET public=false;
DROP POLICY IF EXISTS employee_docs_storage_select ON storage.objects;
CREATE POLICY employee_docs_storage_select ON storage.objects FOR SELECT TO authenticated USING (bucket_id='employee-documents' AND EXISTS (SELECT 1 FROM public.users u WHERE u.auth_id=auth.uid() AND u.company_id=(storage.foldername(name))[1]::uuid AND coalesce(u.status,'Active')='Active'));
DROP POLICY IF EXISTS employee_docs_storage_insert ON storage.objects;
CREATE POLICY employee_docs_storage_insert ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id='employee-documents' AND EXISTS (SELECT 1 FROM public.users u WHERE u.auth_id=auth.uid() AND u.company_id=(storage.foldername(name))[1]::uuid AND coalesce(u.status,'Active')='Active'));
DROP POLICY IF EXISTS employee_docs_storage_update ON storage.objects;
CREATE POLICY employee_docs_storage_update ON storage.objects FOR UPDATE TO authenticated USING (bucket_id='employee-documents' AND EXISTS (SELECT 1 FROM public.users u WHERE u.auth_id=auth.uid() AND u.company_id=(storage.foldername(name))[1]::uuid AND coalesce(u.status,'Active')='Active')) WITH CHECK (bucket_id='employee-documents' AND EXISTS (SELECT 1 FROM public.users u WHERE u.auth_id=auth.uid() AND u.company_id=(storage.foldername(name))[1]::uuid AND coalesce(u.status,'Active')='Active'));

CREATE OR REPLACE FUNCTION public.post_financial_entry_atomic(p_company_id uuid,p_entry_date date,p_reference text,p_description text,p_entry_type text,p_created_by text,p_lines jsonb,p_operation_id text DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='public' AS $function$
DECLARE v_entry_id uuid; v_entry_code text; v_debit numeric:=0; v_credit numeric:=0; l record; r public.erp_operation_registry%ROWTYPE;
BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.companies WHERE id=p_company_id) THEN RAISE EXCEPTION 'سياق الشركة غير موجود'; END IF;
 IF p_lines IS NULL OR jsonb_typeof(p_lines)<>'array' OR jsonb_array_length(p_lines)<2 THEN RAISE EXCEPTION 'سطور القيد غير مكتملة'; END IF;
 IF NULLIF(btrim(p_created_by),'') IS NULL THEN RAISE EXCEPTION 'منشئ القيد مطلوب'; END IF;
 IF NULLIF(btrim(p_operation_id),'') IS NOT NULL THEN
   SELECT * INTO r FROM public.erp_operation_registry WHERE company_id=p_company_id AND operation_key=p_operation_id FOR UPDATE;
   IF FOUND THEN IF r.response_payload IS NOT NULL THEN RETURN r.response_payload; END IF; RAISE EXCEPTION 'العملية المالية قيد التنفيذ: %',p_operation_id; END IF;
   INSERT INTO public.erp_operation_registry(company_id,operation_type,operation_key,request_payload,status) VALUES(p_company_id,'FINANCIAL_ENTRY',p_operation_id,jsonb_build_object('reference',p_reference,'description',p_description,'lines',p_lines),'processing');
 END IF;
 FOR l IN SELECT * FROM jsonb_to_recordset(p_lines) x(account_id uuid,debit numeric,credit numeric,notes text,cost_center_id uuid) LOOP
   IF l.account_id IS NULL THEN RAISE EXCEPTION 'الحساب مطلوب لكل سطر'; END IF;
   IF coalesce(l.debit,0)<0 OR coalesce(l.credit,0)<0 THEN RAISE EXCEPTION 'المبالغ لا تقبل القيم السالبة'; END IF;
   IF coalesce(l.debit,0)>0 AND coalesce(l.credit,0)>0 THEN RAISE EXCEPTION 'السطر لا يمكن أن يكون مدينًا ودائنًا معًا'; END IF;
   IF coalesce(l.debit,0)=0 AND coalesce(l.credit,0)=0 THEN RAISE EXCEPTION 'السطر المالي لا يحتوي قيمة'; END IF;
   IF NOT EXISTS(SELECT 1 FROM public.chart_of_accounts WHERE id=l.account_id AND company_id=p_company_id AND is_active=true) THEN RAISE EXCEPTION 'الحساب لا يتبع الشركة أو غير نشط'; END IF;
   IF l.cost_center_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.cost_centers WHERE id=l.cost_center_id AND is_active=true) THEN RAISE EXCEPTION 'مركز التكلفة غير صالح'; END IF;
   v_debit:=v_debit+coalesce(l.debit,0); v_credit:=v_credit+coalesce(l.credit,0);
 END LOOP;
 IF v_debit<=0 OR abs(v_debit-v_credit)>=0.01 THEN RAISE EXCEPTION 'القيد غير متوازن'; END IF;
 v_entry_id:=gen_random_uuid(); v_entry_code:='JE-'||replace(gen_random_uuid()::text,'-','');
 INSERT INTO public.journal_entries(id,company_id,entry_code,entry_date,reference,description,entry_type,status,created_by,posting_date) VALUES(v_entry_id,p_company_id,v_entry_code,coalesce(p_entry_date,current_date),p_reference,p_description,coalesce(p_entry_type,'Manual'),'Posted',p_created_by,now());
 FOR l IN SELECT * FROM jsonb_to_recordset(p_lines) x(account_id uuid,debit numeric,credit numeric,notes text,cost_center_id uuid) LOOP INSERT INTO public.journal_lines(entry_id,account_id,account_name,debit,credit,notes,cost_center_id) SELECT v_entry_id,a.id,a.account_name,coalesce(l.debit,0),coalesce(l.credit,0),l.notes,l.cost_center_id FROM public.chart_of_accounts a WHERE a.id=l.account_id AND a.company_id=p_company_id; END LOOP;
 IF NULLIF(btrim(p_operation_id),'') IS NOT NULL THEN UPDATE public.erp_operation_registry SET status='completed',response_payload=jsonb_build_object('success',true,'entry_id',v_entry_id,'entry_code',v_entry_code),completed_at=now() WHERE company_id=p_company_id AND operation_key=p_operation_id; END IF;
 RETURN jsonb_build_object('success',true,'entry_id',v_entry_id,'entry_code',v_entry_code,'debit',v_debit,'credit',v_credit);
END;$function$;
REVOKE ALL ON FUNCTION public.post_financial_entry_atomic(uuid,date,text,text,text,text,jsonb,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.post_financial_entry_atomic(uuid,date,text,text,text,text,jsonb,text) TO authenticated,service_role;

CREATE OR REPLACE FUNCTION public.get_enterprise_decision_center(p_company_id uuid,p_from_date date,p_to_date date)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='public' AS $function$
DECLARE sales numeric:=0; orders_n bigint:=0; ar numeric:=0; ap numeric:=0; cash numeric:=0; stock_value numeric:=0; low_n bigint:=0; dormant_n bigint:=0; budget numeric:=0; actual numeric:=0;
BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.companies WHERE id=p_company_id) THEN RAISE EXCEPTION 'سياق الشركة غير موجود'; END IF;
 SELECT coalesce(sum(o.total_amount),0),count(*) INTO sales,orders_n FROM public.orders o WHERE o.company_id=p_company_id AND o.order_date BETWEEN p_from_date AND p_to_date AND o.order_status<>'Cancelled';
 SELECT coalesce(sum(cl.debit-cl.credit),0) INTO ar FROM public.customer_ledger cl WHERE EXISTS(SELECT 1 FROM public.customers c WHERE c.id=cl.customer_id AND c.company_id=p_company_id) AND cl.entry_date<=p_to_date;
 SELECT coalesce(sum(sl.credit-sl.debit),0) INTO ap FROM public.supplier_ledger sl WHERE EXISTS(SELECT 1 FROM public.suppliers s WHERE s.id=sl.supplier_id AND s.company_id=p_company_id) AND sl.entry_date<=p_to_date;
 SELECT coalesce(sum(t.current_balance),0) INTO cash FROM public.treasury t WHERE t.company_id=p_company_id AND t.is_active=true;
 SELECT coalesce(sum(sb.qty*coalesce(i.cost_price,0)),0) INTO stock_value FROM public.stock_branches sb JOIN public.branches b ON b.id=sb.branch_id AND b.company_id=p_company_id JOIN public.items i ON i.id=sb.item_id;
 SELECT count(*) INTO low_n FROM public.stock_branches sb JOIN public.branches b ON b.id=sb.branch_id AND b.company_id=p_company_id JOIN public.items i ON i.id=sb.item_id WHERE greatest(sb.qty-coalesce(sb.allocated_qty,0),0)<=coalesce(i.reorder_point,5);
 SELECT count(*) INTO dormant_n FROM public.stock_branches sb JOIN public.branches b ON b.id=sb.branch_id AND b.company_id=p_company_id JOIN public.items i ON i.id=sb.item_id WHERE sb.qty>0 AND NOT EXISTS(SELECT 1 FROM public.order_details od JOIN public.orders o ON o.id=od.order_id WHERE od.item_id=i.id AND o.company_id=p_company_id AND o.order_date>=p_from_date-interval '60 days');
 SELECT coalesce(sum(bg.budgeted_amount),0) INTO budget FROM public.budgets bg WHERE bg.budget_year=extract(year from p_to_date)::int AND bg.budget_month BETWEEN extract(month from p_from_date)::int AND extract(month from p_to_date)::int AND (bg.account_id IS NULL OR EXISTS(SELECT 1 FROM public.chart_of_accounts a WHERE a.id=bg.account_id AND a.company_id=p_company_id));
 SELECT coalesce(sum(jl.debit-jl.credit),0) INTO actual FROM public.journal_lines jl JOIN public.journal_entries je ON je.id=jl.entry_id AND je.company_id=p_company_id WHERE je.entry_date BETWEEN p_from_date AND p_to_date;
 RETURN jsonb_build_object('company_id',p_company_id,'from_date',p_from_date,'to_date',p_to_date,'sales',sales,'orders',orders_n,'average_order',case when orders_n>0 then round(sales/orders_n,2) else 0 end,'accounts_receivable',ar,'accounts_payable',ap,'cash_position',cash,'stock_value_at_cost',stock_value,'low_stock_items',low_n,'dormant_items',dormant_n,'budget',budget,'actual_net',actual,'budget_variance',budget-actual,'risk_flags',jsonb_build_object('low_stock',low_n>0,'dormant_stock',dormant_n>0,'receivable_pressure',ar>0,'payable_pressure',ap>0,'negative_cash',cash<0,'budget_overrun',budget>0 AND actual>budget));
END;$function$;
REVOKE ALL ON FUNCTION public.get_enterprise_decision_center(uuid,date,date) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_enterprise_decision_center(uuid,date,date) TO authenticated,service_role;
COMMIT;