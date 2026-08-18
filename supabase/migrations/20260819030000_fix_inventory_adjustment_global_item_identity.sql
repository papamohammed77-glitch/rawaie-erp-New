BEGIN;
CREATE OR REPLACE FUNCTION public.post_inventory_adjustment_atomic(p_company_id uuid,p_branch_id uuid,p_adjustment_type text,p_voucher_code text,p_reason text,p_user_email text,p_items jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $function$
DECLARE e record;s public.stock_branches%ROWTYPE;current_qty numeric;diff numeric;movement text;source_branch uuid;target_branch uuid;key text;moved integer:=0;
BEGIN
IF p_adjustment_type NOT IN('replace','add','deduct') THEN RAISE EXCEPTION 'Unsupported adjustment type'; END IF;
IF NOT EXISTS(SELECT 1 FROM public.branches b WHERE b.id=p_branch_id AND b.company_id=p_company_id) THEN RAISE EXCEPTION 'Branch context invalid'; END IF;
FOR e IN SELECT * FROM jsonb_to_recordset(p_items) AS x(item_id uuid,item_code text,qty numeric) LOOP
IF e.item_id IS NULL OR e.item_code IS NULL OR e.qty IS NULL THEN RAISE EXCEPTION 'Invalid adjustment item'; END IF;
IF NOT EXISTS(SELECT 1 FROM public.items i WHERE i.id=e.item_id AND i.item_code=e.item_code) THEN RAISE EXCEPTION 'Item identity invalid: %',e.item_code; END IF;
SELECT * INTO s FROM public.stock_branches WHERE branch_id=p_branch_id AND item_id=e.item_id FOR UPDATE;
current_qty:=COALESCE(s.qty,0);
IF p_adjustment_type='add' THEN diff:=e.qty;movement:='InventoryIncrease';source_branch:=NULL;target_branch:=p_branch_id;
ELSIF p_adjustment_type='deduct' THEN diff:=-e.qty;movement:='InventoryDecrease';source_branch:=p_branch_id;target_branch:=NULL;
ELSE diff:=e.qty-current_qty;IF diff=0 THEN CONTINUE;END IF;movement:=CASE WHEN diff>0 THEN 'InventoryIncrease' ELSE 'InventoryDecrease' END;source_branch:=CASE WHEN diff<0 THEN p_branch_id ELSE NULL END;target_branch:=CASE WHEN diff>0 THEN p_branch_id ELSE NULL END;END IF;
key:='InventoryAdjustment:'||p_company_id::text||':'||p_voucher_code||':'||e.item_id::text;
PERFORM public.post_stock_movement(p_company_id,movement,source_branch,target_branch,e.item_id,abs(diff),p_voucher_code,p_reason,p_user_email,key);moved:=moved+1;
END LOOP;
RETURN jsonb_build_object('success',true,'movement_count',moved,'voucher_code',p_voucher_code);
END;$function$;
COMMIT;
