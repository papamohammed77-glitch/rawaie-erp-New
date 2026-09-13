BEGIN;
CREATE OR REPLACE FUNCTION public.resolve_promotion_cart(p_company_id uuid,p_customer_id uuid,p_branch_id uuid,p_channel text,p_subtotal numeric,p_items jsonb,p_coupon_code text DEFAULT NULL,p_on_date date DEFAULT CURRENT_DATE)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='public' AS $function$
DECLARE pr record; rr record; line record; eligible_subtotal numeric; eligible_qty numeric; discount numeric; remaining numeric:=greatest(coalesce(p_subtotal,0),0); total_discount numeric:=0; free_items jsonb:='[]'::jsonb; selected jsonb:='[]'::jsonb; candidate_count integer:=0; chosen_exclusive boolean:=false; qty_factor numeric; reward_item_price numeric; reward_item_id uuid; best_line_item uuid; best_line_price numeric; promo_max numeric;
BEGIN
IF NOT EXISTS(select 1 from public.companies where id=p_company_id) then raise exception 'سياق الشركة غير موجود'; end if;
IF p_items is null or jsonb_typeof(p_items)<>'array' or jsonb_array_length(p_items)=0 then raise exception 'لا توجد أصناف للتسعير الترويجي'; end if;
p_channel:=coalesce(nullif(p_channel,''),'all'); p_on_date:=coalesce(p_on_date,current_date);
IF p_customer_id is not null and not exists(select 1 from public.customers where id=p_customer_id and company_id=p_company_id) then raise exception 'العميل غير تابع للشركة'; end if;
IF p_branch_id is not null and not exists(select 1 from public.branches where id=p_branch_id and company_id=p_company_id) then raise exception 'الفرع غير تابع للشركة'; end if;
FOR pr IN SELECT p.* FROM public.promotions p WHERE p.company_id=p_company_id AND p.is_active AND (p.valid_from is null or p.valid_from<=p_on_date) AND (p.valid_until is null or p.valid_until>=p_on_date) AND (p.channel_scope='all' or p.channel_scope=p_channel) AND (p.trigger_mode='automatic' or (p_coupon_code is not null and lower(btrim(p.coupon_code))=lower(btrim(p_coupon_code)))) AND (p.customer_scope='all' or (p_customer_id is not null and exists(select 1 from public.promotion_customers pc where pc.promotion_id=p.id and pc.company_id=p_company_id and pc.customer_id=p_customer_id))) AND (not exists(select 1 from public.promotion_branches pb where pb.promotion_id=p.id and pb.company_id=p_company_id) or (p_branch_id is not null and exists(select 1 from public.promotion_branches pb where pb.promotion_id=p.id and pb.company_id=p_company_id and pb.branch_id=p_branch_id))) AND p.min_subtotal<=greatest(coalesce(p_subtotal,0),0) AND (p.usage_limit_total is null or (select count(*) from public.promotion_redemptions x where x.company_id=p_company_id and x.promotion_id=p.id)<p.usage_limit_total) AND (p.usage_limit_per_customer is null or p_customer_id is null or (select count(*) from public.promotion_redemptions x where x.company_id=p_company_id and x.promotion_id=p.id and x.customer_id=p_customer_id)<p.usage_limit_per_customer) ORDER BY p.priority,p.created_at,p.id LOOP
IF pr.stacking_policy='exclusive' AND chosen_exclusive then continue; end if; IF pr.stacking_policy='stackable' AND chosen_exclusive then continue; end if;
eligible_subtotal:=0; eligible_qty:=0; best_line_item:=null; best_line_price:=null;
FOR line IN SELECT x.item_id,x.qty,x.unit_price,i.category_id FROM jsonb_to_recordset(p_items) x(item_id uuid,qty numeric,unit_price numeric) JOIN public.items i ON i.id=x.item_id WHERE coalesce(x.qty,0)>0 AND coalesce(x.unit_price,0)>=0 AND EXISTS(select 1 from public.promotion_rules r where r.promotion_id=pr.id and r.is_active and r.trigger_qty<=x.qty and (r.valid_from is null or r.valid_from<=p_on_date) and (r.valid_until is null or r.valid_until>=p_on_date) and (r.scope_type='all' or (r.scope_type='item' and r.item_id=x.item_id) or (r.scope_type='category' and r.category_id=i.category_id))) LOOP
eligible_subtotal:=eligible_subtotal+line.qty*line.unit_price; eligible_qty:=eligible_qty+line.qty; IF best_line_price is null or line.unit_price<best_line_price then best_line_price:=line.unit_price; best_line_item:=line.item_id; end if;
END LOOP;
IF eligible_qty<pr.min_qty or eligible_subtotal<=0 then continue; end if;
SELECT r.* INTO rr FROM public.promotion_rules r WHERE r.promotion_id=pr.id and r.is_active and r.trigger_qty<=eligible_qty and (r.valid_from is null or r.valid_from<=p_on_date) and (r.valid_until is null or r.valid_until>=p_on_date) and (r.scope_type='all' or exists(select 1 from jsonb_to_recordset(p_items) x(item_id uuid,qty numeric,unit_price numeric) join public.items i on i.id=x.item_id where coalesce(x.qty,0)>0 and r.trigger_qty<=x.qty and ((r.scope_type='item' and r.item_id=x.item_id) or (r.scope_type='category' and r.category_id=i.category_id))) ) ORDER BY case r.scope_type when 'item' then 1 when 'category' then 2 else 3 end,r.trigger_qty desc,r.sequence,r.id LIMIT 1;
IF rr.id is null then continue; end if;
IF pr.promotion_type='discount' then
  IF rr.reward_type='percent' then discount:=eligible_subtotal*least(greatest(rr.reward_value,0),100)/100; ELSE discount:=least(greatest(rr.reward_value,0),eligible_subtotal); END IF;
  promo_max:=case when pr.max_discount>0 then pr.max_discount else rr.max_discount end; IF promo_max>0 then discount:=least(discount,promo_max); end if;
ELSIF pr.promotion_type='cheapest_item' then
  IF best_line_item is null then continue; end if;
  discount:=case when rr.reward_type='cheapest_percent' then best_line_price*least(greatest(rr.reward_value,0),100)/100 else least(greatest(rr.reward_value,0),best_line_price) end;
  promo_max:=case when pr.max_discount>0 then pr.max_discount else rr.max_discount end; IF promo_max>0 then discount:=least(discount,promo_max); end if;
ELSE
  IF rr.reward_type<>'free_item' or rr.reward_qty<=0 then continue; end if;
  qty_factor:=floor(eligible_qty/rr.trigger_qty); reward_item_id:=coalesce(rr.reward_item_id,best_line_item); IF qty_factor<=0 or reward_item_id is null then continue; end if;
  SELECT coalesce((select x.unit_price from jsonb_to_recordset(p_items) x(item_id uuid,qty numeric,unit_price numeric) where x.item_id=reward_item_id limit 1),i.sales_price,0) INTO reward_item_price FROM public.items i WHERE i.id=reward_item_id;
  discount:=least(remaining,qty_factor*rr.reward_qty*greatest(reward_item_price,0)); free_items:=free_items||jsonb_build_array(jsonb_build_object('item_id',reward_item_id,'qty',qty_factor*rr.reward_qty,'unit_price',0));
END IF;
discount:=least(greatest(coalesce(discount,0),0),remaining); IF discount<=0 and pr.promotion_type<>'buy_x_get_y' then continue; end if;
total_discount:=total_discount+discount; remaining:=greatest(remaining-discount,0); candidate_count:=candidate_count+1; selected:=selected||jsonb_build_array(jsonb_build_object('promotion_id',pr.id,'code',pr.code,'name',pr.name,'type',pr.promotion_type,'priority',pr.priority,'discount_amount',discount)); IF pr.stacking_policy='exclusive' then chosen_exclusive:=true; end if; IF remaining<=0 then exit; end if;
END LOOP;
RETURN jsonb_build_object('success',true,'candidate_count',candidate_count,'discount_total',total_discount,'final_subtotal',remaining,'promotions',selected,'free_items',free_items,'channel',p_channel,'on_date',p_on_date);
END;
$function$;
COMMIT;
