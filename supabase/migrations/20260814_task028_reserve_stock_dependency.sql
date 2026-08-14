BEGIN;
CREATE OR REPLACE FUNCTION public.reserve_stock(p_company_id uuid,p_branch_id uuid,p_item_id uuid,p_qty numeric)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path=public
AS $$
DECLARE s public.stock_branches%ROWTYPE; bc uuid;
BEGIN
 IF p_company_id IS NULL OR p_branch_id IS NULL OR p_item_id IS NULL OR p_qty IS NULL OR p_qty<=0 THEN RAISE EXCEPTION 'invalid reservation request'; END IF;
 SELECT company_id INTO bc FROM public.branches WHERE id=p_branch_id; IF bc IS NULL OR bc<>p_company_id THEN RAISE EXCEPTION 'branch context invalid'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.items WHERE id=p_item_id AND company_id=p_company_id) THEN RAISE EXCEPTION 'item context invalid'; END IF;
 SELECT * INTO s FROM public.stock_branches WHERE branch_id=p_branch_id AND item_id=p_item_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'stock balance not found'; END IF;
 IF COALESCE(s.qty,0)-COALESCE(s.allocated_qty,0) < p_qty THEN RAISE EXCEPTION 'insufficient available stock for reservation'; END IF;
 UPDATE public.stock_branches SET allocated_qty=s.allocated_qty+p_qty,updated_at=now() WHERE id=s.id AND qty=s.qty AND allocated_qty=s.allocated_qty;
 IF NOT FOUND THEN RAISE EXCEPTION 'stock changed during reservation'; END IF;
 RETURN true;
END;
$$;
REVOKE ALL ON FUNCTION public.reserve_stock(uuid,uuid,uuid,numeric) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.reserve_stock(uuid,uuid,uuid,numeric) TO service_role;
COMMIT;