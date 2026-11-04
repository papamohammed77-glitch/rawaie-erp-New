-- REVIEW DRAFT ONLY — DO NOT APPLY WITHOUT OWNER APPROVAL
-- Source: live Production SMART ERP at 2026-11-04; exact existing signatures preserved.
-- 1) Prevent cash-custody settlement while employee-funded Quick Market invoices remain reserved.
CREATE OR REPLACE FUNCTION public.buyer_custody_settle_atomic(p_company_id uuid, p_custody_id uuid, p_treasury_id uuid, p_cash_returned numeric, p_finance_reference text, p_notes text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
 v_actor public.users%rowtype; v_custody public.buyer_custodies%rowtype; v_employee public.users%rowtype;
 v_approved numeric(14,2); v_pending integer; v_expected_return numeric(14,2); v_unacknowledged integer; v_open_qmp integer;
 v_settlement public.buyer_custody_settlements%rowtype; v_cash_account uuid; v_custody_account uuid; v_cash_result jsonb;
begin
 select * into v_actor from public.users where auth_id=auth.uid() and company_id=p_company_id and coalesce(status,'Active')='Active';
 if not found then raise exception 'CUSTODY_AUTH_REQUIRED'; end if;
 if not (app_private.current_user_has_effective_permission('finance') or app_private.current_user_has_effective_permission('finance_manager')) then raise exception 'CUSTODY_FINANCE_PERMISSION_REQUIRED'; end if;
 select * into v_custody from public.buyer_custodies where id=p_custody_id and company_id=p_company_id for update;
 if not found or v_custody.status not in ('Issued','UnderReview') then raise exception 'CUSTODY_NOT_SETTLEABLE'; end if;
 if v_custody.employee_id=v_actor.id then raise exception 'CUSTODY_SELF_SETTLEMENT_FORBIDDEN'; end if;
 select * into v_employee from public.users where id=v_custody.employee_id and company_id=p_company_id;
 select count(*) into v_pending from public.buyer_custody_expenses where custody_id=p_custody_id and company_id=p_company_id and status='Submitted';
 if v_pending>0 then raise exception 'CUSTODY_EXPENSES_PENDING_REVIEW'; end if;
 select count(*) into v_unacknowledged from public.buyer_custody_advances where custody_id=p_custody_id and company_id=p_company_id and acknowledged_at is null;
 if v_unacknowledged>0 then raise exception 'CUSTODY_ADVANCES_NOT_ACKNOWLEDGED'; end if;
 select count(*) into v_open_qmp
 from public.purchase_invoices
 where company_id=p_company_id
   and cash_custody_id=p_custody_id
   and purchase_source='QUICK_MARKET'
   and settlement_source='EMPLOYEE_CUSTODY'
   and status in ('Draft','Posted','PartiallyPaid')
   and settlement_status in ('UNSETTLED','PENDING_FINANCE','AP_OPEN','PARTIALLY_SETTLED');
 if v_open_qmp>0 then
   raise exception 'CUSTODY_QUICK_MARKET_RESERVATIONS_OPEN:%',v_open_qmp;
 end if;
 select coalesce(sum(amount),0) into v_approved from public.buyer_custody_expenses where custody_id=p_custody_id and company_id=p_company_id and status='Approved';
 v_expected_return:=greatest(v_custody.issued_amount-v_approved,0);
 if coalesce(p_cash_returned,0)<>v_expected_return then raise exception 'CUSTODY_CASH_RETURN_MUST_RECONCILE'; end if;
 if v_expected_return>0 then
  if p_treasury_id is null then raise exception 'CUSTODY_RETURN_TREASURY_REQUIRED'; end if;
  select id into v_cash_account from public.chart_of_accounts where company_id=p_company_id and account_code='121' and is_active;
  select id into v_custody_account from public.chart_of_accounts where company_id=p_company_id and account_code='127' and is_active;
  if v_cash_account is null or v_custody_account is null then raise exception 'CUSTODY_ACCOUNT_MAPPING_MISSING'; end if;
  v_cash_result:=public.post_cash_receipt_atomic(p_company_id,gen_random_uuid(),p_treasury_id,v_cash_account,v_custody_account,v_expected_return,
   current_date,coalesce(nullif(btrim(p_finance_reference),''),v_custody.custody_code),'رد نقدية متبقية من عهدة مشتريات',
   v_actor.email,v_employee.name,'BuyerCustodySettlement',v_custody.id,nullif(btrim(p_notes),''),null);
 end if;
 insert into public.buyer_custody_settlements(company_id,custody_id,approved_expense_total,cash_returned,amount_due_employee,balance_due_company,finance_reference,notes,recorded_by,treasury_id,cash_box_id,journal_entry_id)
 values(p_company_id,p_custody_id,v_approved,v_expected_return,greatest(v_approved-v_custody.issued_amount,0),0,
 nullif(btrim(p_finance_reference),''),nullif(btrim(p_notes),''),v_actor.id,p_treasury_id,
 nullif(v_cash_result->>'cash_box_id','')::uuid,nullif(v_cash_result->>'entry_id','')::uuid)
 returning * into v_settlement;
 update public.buyer_custodies set status='Settled',updated_at=now() where id=p_custody_id and company_id=p_company_id;
 return to_jsonb(v_settlement);
end;
$function$
;

-- 2) Defense-in-depth: prohibit generic draft deletion after any goods-custody event.
CREATE OR REPLACE FUNCTION public.purchase_delete_draft_invoice_atomic(p_company_id uuid, p_invoice_id uuid, p_actor text, p_reason text, p_operation_id text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_invoice public.purchase_invoices%rowtype;
  v_note text;
BEGIN
  IF NULLIF(btrim(p_operation_id), '') IS NULL THEN
    RAISE EXCEPTION 'PURCHASE_OPERATION_ID_REQUIRED';
  END IF;

  IF NULLIF(btrim(p_actor), '') IS NULL OR NOT EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.company_id = p_company_id
      AND lower(u.email) = lower(btrim(p_actor))
      AND u.status = 'Active'
  ) THEN
    RAISE EXCEPTION 'PURCHASE_ACTOR_INVALID';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.purchase_status_history h
    WHERE h.company_id = p_company_id
      AND h.document_type = 'PurchaseInvoice'
      AND h.document_id = p_invoice_id
      AND h.action = 'DELETED_DRAFT'
      AND h.note LIKE 'operation_id=' || p_operation_id || ';%'
  ) THEN
    RETURN jsonb_build_object(
      'success', true, 'duplicate', true,
      'id', p_invoice_id, 'status', 'Deleted'
    );
  END IF;

  SELECT *
    INTO v_invoice
  FROM public.purchase_invoices
  WHERE id = p_invoice_id
    AND company_id = p_company_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'PURCHASE_INVOICE_NOT_FOUND';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.buyer_goods_custody_events e
    WHERE e.company_id=p_company_id
      AND e.source_document_type='PurchaseInvoice'
      AND e.source_document_id=p_invoice_id
  ) THEN
    RAISE EXCEPTION 'INVOICE_HAS_GOODS_CUSTODY_EVENTS';
  END IF;

  IF v_invoice.status <> 'Draft'
     OR COALESCE(v_invoice.is_received, false)
     OR COALESCE(v_invoice.paid_amount, 0) <> 0
     OR v_invoice.received_date IS NOT NULL
     OR v_invoice.posted_at IS NOT NULL THEN
    RAISE EXCEPTION 'ONLY_UNRECEIVED_UNPOSTED_DRAFT_INVOICES_CAN_BE_DELETED';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.purchase_invoice_details d
    WHERE d.invoice_id = p_invoice_id
      AND COALESCE(d.received_qty, 0) > 0
  ) THEN
    RAISE EXCEPTION 'INVOICE_HAS_RECEIVED_QUANTITY';
  END IF;

  IF EXISTS (SELECT 1 FROM public.buyer_custody_expenses e WHERE e.purchase_invoice_id = p_invoice_id)
     OR EXISTS (SELECT 1 FROM public.purchase_payment_allocations a WHERE a.invoice_id = p_invoice_id)
     OR EXISTS (SELECT 1 FROM public.purchase_returns r WHERE r.purchase_invoice_id = p_invoice_id)
     OR EXISTS (SELECT 1 FROM public.stock_vouchers v WHERE v.purchase_invoice_id = p_invoice_id) THEN
    RAISE EXCEPTION 'INVOICE_HAS_DOWNSTREAM_FINANCIAL_OR_STOCK_REFERENCES';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.purchase_attachments a
    WHERE a.company_id = p_company_id
      AND a.document_id = p_invoice_id
      AND a.document_type IN ('PurchaseInvoice', 'purchase_invoice', 'invoice')
  ) OR EXISTS (
    SELECT 1 FROM public.purchase_document_links l
    WHERE l.company_id = p_company_id
      AND (
        (l.source_id = p_invoice_id AND l.source_type IN ('PurchaseInvoice', 'purchase_invoice', 'invoice'))
        OR
        (l.target_id = p_invoice_id AND l.target_type IN ('PurchaseInvoice', 'purchase_invoice', 'invoice'))
      )
  ) THEN
    RAISE EXCEPTION 'INVOICE_HAS_DOCUMENT_OR_ATTACHMENT_LINKS';
  END IF;

  v_note := 'operation_id=' || p_operation_id || '; reason=' || COALESCE(NULLIF(btrim(p_reason), ''), 'Draft deleted by authorized Buyer user');

  INSERT INTO public.purchase_status_history(
    company_id, document_type, document_id, from_status, to_status,
    action, actor_email, note
  )
  VALUES(
    p_company_id, 'PurchaseInvoice', p_invoice_id, 'Draft', 'Deleted',
    'DELETED_DRAFT', p_actor, v_note
  );

  DELETE FROM public.purchase_invoices
  WHERE id = p_invoice_id
    AND company_id = p_company_id
    AND status = 'Draft';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'PURCHASE_INVOICE_DRAFT_DELETE_FAILED';
  END IF;

  RETURN jsonb_build_object(
    'success', true, 'id', p_invoice_id,
    'code', v_invoice.invoice_code, 'status', 'Deleted'
  );
END;
$function$
;
