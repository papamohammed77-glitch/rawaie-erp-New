BEGIN;

CREATE TABLE IF NOT EXISTS public.promotions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  code text NOT NULL,
  name text NOT NULL,
  description text,
  promotion_type text NOT NULL CHECK (promotion_type IN ('discount','cheapest_item','buy_x_get_y')),
  stacking_policy text NOT NULL DEFAULT 'exclusive' CHECK (stacking_policy IN ('exclusive','stackable')),
  trigger_mode text NOT NULL DEFAULT 'automatic' CHECK (trigger_mode IN ('automatic','code')),
  coupon_code text,
  channel_scope text NOT NULL DEFAULT 'all' CHECK (channel_scope IN ('all','pos','telesales','order-taker','van-sales','online-store')),
  customer_scope text NOT NULL DEFAULT 'all' CHECK (customer_scope IN ('all','specific')),
  priority integer NOT NULL DEFAULT 100 CHECK (priority >= 0),
  min_subtotal numeric NOT NULL DEFAULT 0 CHECK (min_subtotal >= 0),
  min_qty numeric NOT NULL DEFAULT 0 CHECK (min_qty >= 0),
  max_discount numeric NOT NULL DEFAULT 0 CHECK (max_discount >= 0),
  usage_limit_total integer CHECK (usage_limit_total IS NULL OR usage_limit_total > 0),
  usage_limit_per_customer integer CHECK (usage_limit_per_customer IS NULL OR usage_limit_per_customer > 0),
  valid_from date,
  valid_until date,
  is_active boolean NOT NULL DEFAULT true,
  created_by text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT promotions_validity_chk CHECK (valid_until IS NULL OR valid_from IS NULL OR valid_until >= valid_from)
);

CREATE UNIQUE INDEX IF NOT EXISTS promotions_company_code_uq ON public.promotions(company_id, code);
CREATE UNIQUE INDEX IF NOT EXISTS promotions_company_coupon_uq ON public.promotions(company_id, lower(coupon_code)) WHERE coupon_code IS NOT NULL AND btrim(coupon_code) <> '';
CREATE INDEX IF NOT EXISTS promotions_active_idx ON public.promotions(company_id, is_active, priority, valid_from, valid_until);

CREATE TABLE IF NOT EXISTS public.promotion_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  promotion_id uuid NOT NULL REFERENCES public.promotions(id) ON DELETE CASCADE,
  sequence integer NOT NULL DEFAULT 100,
  scope_type text NOT NULL CHECK (scope_type IN ('all','item','category')),
  item_id uuid REFERENCES public.items(id) ON DELETE RESTRICT,
  category_id uuid REFERENCES public.categories(id) ON DELETE RESTRICT,
  trigger_qty numeric NOT NULL DEFAULT 1 CHECK (trigger_qty > 0),
  reward_type text NOT NULL CHECK (reward_type IN ('percent','fixed','cheapest_percent','cheapest_fixed','free_item')),
  reward_value numeric NOT NULL DEFAULT 0 CHECK (reward_value >= 0),
  reward_qty numeric NOT NULL DEFAULT 0 CHECK (reward_qty >= 0),
  reward_item_id uuid REFERENCES public.items(id) ON DELETE RESTRICT,
  max_discount numeric NOT NULL DEFAULT 0 CHECK (max_discount >= 0),
  valid_from date,
  valid_until date,
  is_active boolean NOT NULL DEFAULT true,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT promotion_rule_scope_chk CHECK ((scope_type='all' AND item_id IS NULL AND category_id IS NULL) OR (scope_type='item' AND item_id IS NOT NULL AND category_id IS NULL) OR (scope_type='category' AND category_id IS NOT NULL AND item_id IS NULL)),
  CONSTRAINT promotion_rule_validity_chk CHECK (valid_until IS NULL OR valid_from IS NULL OR valid_until >= valid_from),
  CONSTRAINT promotion_rule_free_item_chk CHECK ((reward_type='free_item' AND reward_item_id IS NOT NULL AND reward_qty > 0) OR (reward_type<>'free_item'))
);

CREATE INDEX IF NOT EXISTS promotion_rules_lookup_idx ON public.promotion_rules(promotion_id, is_active, sequence, trigger_qty);

CREATE TABLE IF NOT EXISTS public.promotion_customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  promotion_id uuid NOT NULL REFERENCES public.promotions(id) ON DELETE CASCADE,
  customer_id uuid NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  created_by text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS promotion_customers_uq ON public.promotion_customers(promotion_id, customer_id);
CREATE INDEX IF NOT EXISTS promotion_customers_company_idx ON public.promotion_customers(company_id, customer_id, promotion_id);

CREATE TABLE IF NOT EXISTS public.promotion_branches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  promotion_id uuid NOT NULL REFERENCES public.promotions(id) ON DELETE CASCADE,
  branch_id uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  created_by text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS promotion_branches_uq ON public.promotion_branches(promotion_id, branch_id);
CREATE INDEX IF NOT EXISTS promotion_branches_company_idx ON public.promotion_branches(company_id, branch_id, promotion_id);

CREATE TABLE IF NOT EXISTS public.promotion_redemptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  promotion_id uuid NOT NULL REFERENCES public.promotions(id) ON DELETE RESTRICT,
  order_id uuid REFERENCES public.orders(id) ON DELETE SET NULL,
  customer_id uuid REFERENCES public.customers(id) ON DELETE SET NULL,
  channel_scope text NOT NULL DEFAULT 'all',
  coupon_code text,
  discount_amount numeric NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
  free_items jsonb NOT NULL DEFAULT '[]'::jsonb,
  operation_id text NOT NULL,
  created_by text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS promotion_redemptions_operation_uq ON public.promotion_redemptions(company_id, operation_id);
CREATE INDEX IF NOT EXISTS promotion_redemptions_promo_idx ON public.promotion_redemptions(company_id, promotion_id, created_at);
CREATE INDEX IF NOT EXISTS promotion_redemptions_customer_idx ON public.promotion_redemptions(company_id, customer_id, promotion_id, created_at);

ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotions FORCE ROW LEVEL SECURITY;
ALTER TABLE public.promotion_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotion_rules FORCE ROW LEVEL SECURITY;
ALTER TABLE public.promotion_customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotion_customers FORCE ROW LEVEL SECURITY;
ALTER TABLE public.promotion_branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotion_branches FORCE ROW LEVEL SECURITY;
ALTER TABLE public.promotion_redemptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotion_redemptions FORCE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.promotions FROM anon, authenticated;
REVOKE ALL ON TABLE public.promotion_rules FROM anon, authenticated;
REVOKE ALL ON TABLE public.promotion_customers FROM anon, authenticated;
REVOKE ALL ON TABLE public.promotion_branches FROM anon, authenticated;
REVOKE ALL ON TABLE public.promotion_redemptions FROM anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.promotions TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.promotion_rules TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.promotion_customers TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.promotion_branches TO service_role;
GRANT SELECT, INSERT, UPDATE ON public.promotion_redemptions TO service_role;

CREATE OR REPLACE FUNCTION public.resolve_promotion_cart(
  p_company_id uuid,
  p_customer_id uuid,
  p_branch_id uuid,
  p_channel text,
  p_subtotal numeric,
  p_items jsonb,
  p_coupon_code text DEFAULT NULL,
  p_on_date date DEFAULT CURRENT_DATE
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  pr record;
  rr record;
  line record;
  eligible_subtotal numeric;
  eligible_qty numeric;
  discount numeric;
  remaining numeric := GREATEST(COALESCE(p_subtotal,0),0);
  total_discount numeric := 0;
  free_items jsonb := '[]'::jsonb;
  selected jsonb := '[]'::jsonb;
  candidate_count integer := 0;
  chosen_exclusive boolean := false;
  qty_factor numeric;
  reward_item_price numeric;
  reward_item_id uuid;
  best_line_item uuid;
  best_line_price numeric;
  promo_max numeric;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.companies WHERE id=p_company_id) THEN RAISE EXCEPTION 'سياق الشركة غير موجود'; END IF;
  IF p_items IS NULL OR jsonb_typeof(p_items)<>'array' OR jsonb_array_length(p_items)=0 THEN RAISE EXCEPTION 'لا توجد أصناف للتسعير الترويجي'; END IF;
  p_channel:=COALESCE(NULLIF(p_channel,''),'all');
  p_on_date:=COALESCE(p_on_date,CURRENT_DATE);
  IF p_customer_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.customers WHERE id=p_customer_id AND company_id=p_company_id) THEN RAISE EXCEPTION 'العميل غير تابع للشركة'; END IF;
  IF p_branch_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.branches WHERE id=p_branch_id AND company_id=p_company_id) THEN RAISE EXCEPTION 'الفرع غير تابع للشركة'; END IF;

  FOR pr IN SELECT p.* FROM public.promotions p
    WHERE p.company_id=p_company_id AND p.is_active
      AND (p.valid_from IS NULL OR p.valid_from<=p_on_date) AND (p.valid_until IS NULL OR p.valid_until>=p_on_date)
      AND (p.channel_scope='all' OR p.channel_scope=p_channel)
      AND (p.trigger_mode='automatic' OR (p_coupon_code IS NOT NULL AND lower(btrim(p.coupon_code))=lower(btrim(p_coupon_code))))
      AND (p.customer_scope='all' OR (p_customer_id IS NOT NULL AND EXISTS(SELECT 1 FROM public.promotion_customers pc WHERE pc.promotion_id=p.id AND pc.company_id=p_company_id AND pc.customer_id=p_customer_id)))
      AND (NOT EXISTS(SELECT 1 FROM public.promotion_branches pb WHERE pb.promotion_id=p.id AND pb.company_id=p_company_id) OR (p_branch_id IS NOT NULL AND EXISTS(SELECT 1 FROM public.promotion_branches pb WHERE pb.promotion_id=p.id AND pb.company_id=p_company_id AND pb.branch_id=p_branch_id)))
      AND p.min_subtotal<=GREATEST(COALESCE(p_subtotal,0),0)
      AND (p.usage_limit_total IS NULL OR (SELECT count(*) FROM public.promotion_redemptions x WHERE x.company_id=p_company_id AND x.promotion_id=p.id)<p.usage_limit_total)
      AND (p.usage_limit_per_customer IS NULL OR p_customer_id IS NULL OR (SELECT count(*) FROM public.promotion_redemptions x WHERE x.company_id=p_company_id AND x.promotion_id=p.id AND x.customer_id=p_customer_id)<p.usage_limit_per_customer)
    ORDER BY p.priority ASC,p.created_at ASC,p.id
  LOOP
    IF pr.stacking_policy='exclusive' AND chosen_exclusive THEN CONTINUE; END IF;
    IF pr.stacking_policy='stackable' AND chosen_exclusive THEN CONTINUE; END IF;
    eligible_subtotal:=0; eligible_qty:=0; best_line_item:=NULL; best_line_price:=NULL;
    FOR line IN SELECT x.item_id,x.qty,x.unit_price,i.category_id FROM jsonb_to_recordset(p_items) x(item_id uuid,qty numeric,unit_price numeric) JOIN public.items i ON i.id=x.item_id
      WHERE COALESCE(x.qty,0)>0 AND COALESCE(x.unit_price,0)>=0 AND EXISTS(SELECT 1 FROM public.promotion_rules r WHERE r.promotion_id=pr.id AND r.is_active AND r.trigger_qty<=x.qty AND ((r.scope_type='all') OR (r.scope_type='item' AND r.item_id=x.item_id) OR (r.scope_type='category' AND r.category_id=i.category_id)))
    LOOP
      eligible_subtotal:=eligible_subtotal+line.qty*line.unit_price; eligible_qty:=eligible_qty+line.qty;
      IF best_line_price IS NULL OR line.unit_price<best_line_price THEN best_line_price:=line.unit_price; best_line_item:=line.item_id; END IF;
    END LOOP;
    IF eligible_qty<pr.min_qty OR eligible_subtotal<=0 THEN CONTINUE; END IF;
    SELECT r.* INTO rr FROM public.promotion_rules r WHERE r.promotion_id=pr.id AND r.is_active AND r.trigger_qty<=eligible_qty ORDER BY CASE r.scope_type WHEN 'item' THEN 1 WHEN 'category' THEN 2 ELSE 3 END,r.trigger_qty DESC,r.sequence,r.id LIMIT 1;
    IF pr.promotion_type='discount' THEN
      discount:=CASE WHEN rr.reward_type='percent' THEN eligible_subtotal*LEAST(GREATEST(rr.reward_value,0),100)/100 ELSE LEAST(GREATEST(rr.reward_value,0),eligible_subtotal) END;
      promo_max:=CASE WHEN pr.max_discount>0 THEN pr.max_discount ELSE rr.max_discount END; IF promo_max>0 THEN discount:=LEAST(discount,promo_max); END IF;
    ELSIF pr.promotion_type='cheapest_item' THEN
      IF best_line_item IS NULL THEN CONTINUE; END IF;
      discount:=CASE WHEN rr.reward_type='cheapest_percent' THEN best_line_price*LEAST(GREATEST(rr.reward_value,0),100)/100 ELSE LEAST(GREATEST(rr.reward_value,0),best_line_price) END;
      promo_max:=CASE WHEN pr.max_discount>0 THEN pr.max_discount ELSE rr.max_discount END; IF promo_max>0 THEN discount:=LEAST(discount,promo_max); END IF;
    ELSE
      IF rr.reward_type<>'free_item' OR rr.trigger_qty<=0 OR rr.reward_qty<=0 THEN CONTINUE; END IF;
      qty_factor:=floor(eligible_qty/rr.trigger_qty); reward_item_id:=COALESCE(rr.reward_item_id,best_line_item); IF reward_item_id IS NULL OR qty_factor<=0 THEN CONTINUE; END IF;
      SELECT COALESCE((SELECT x.unit_price FROM jsonb_to_recordset(p_items) x(item_id uuid,qty numeric,unit_price numeric) WHERE x.item_id=reward_item_id LIMIT 1),i.sales_price,0) INTO reward_item_price FROM public.items i WHERE i.id=reward_item_id;
      discount:=LEAST(remaining,qty_factor*rr.reward_qty*GREATEST(reward_item_price,0));
      free_items:=free_items||jsonb_build_array(jsonb_build_object('item_id',reward_item_id,'qty',qty_factor*rr.reward_qty,'unit_price',0));
    END IF;
    discount:=LEAST(GREATEST(COALESCE(discount,0),0),remaining);
    IF discount<=0 AND pr.promotion_type<>'buy_x_get_y' THEN CONTINUE; END IF;
    total_discount:=total_discount+discount; remaining:=GREATEST(remaining-discount,0); candidate_count:=candidate_count+1;
    selected:=selected||jsonb_build_array(jsonb_build_object('promotion_id',pr.id,'code',pr.code,'name',pr.name,'type',pr.promotion_type,'priority',pr.priority,'discount_amount',discount,'free_items',CASE WHEN pr.promotion_type='buy_x_get_y' THEN jsonb_build_array(jsonb_build_object('item_id',reward_item_id,'qty',qty_factor*rr.reward_qty,'unit_price',0)) ELSE '[]'::jsonb END));
    IF pr.stacking_policy='exclusive' THEN chosen_exclusive:=true; END IF; IF remaining<=0 THEN EXIT; END IF;
  END LOOP;
  RETURN jsonb_build_object('success',true,'candidate_count',candidate_count,'discount_total',total_discount,'final_subtotal',remaining,'promotions',selected,'free_items',free_items,'channel',p_channel,'on_date',p_on_date);
END;
$function$;

CREATE OR REPLACE FUNCTION public.record_promotion_redemption(
  p_company_id uuid,p_promotion_id uuid,p_order_id uuid,p_customer_id uuid,p_channel_scope text,p_coupon_code text,p_discount_amount numeric,p_free_items jsonb,p_operation_id text,p_user_email text
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='public' AS $function$
DECLARE v public.promotion_redemptions%ROWTYPE; p public.promotions%ROWTYPE;
BEGIN
  IF NULLIF(btrim(p_operation_id),'') IS NULL THEN RAISE EXCEPTION 'operation_id مطلوب'; END IF;
  SELECT * INTO p FROM public.promotions WHERE id=p_promotion_id AND company_id=p_company_id FOR UPDATE; IF NOT FOUND THEN RAISE EXCEPTION 'العرض غير موجود'; END IF;
  SELECT * INTO v FROM public.promotion_redemptions WHERE company_id=p_company_id AND operation_id=p_operation_id; IF FOUND THEN RETURN jsonb_build_object('success',true,'duplicate',true,'redemption_id',v.id,'promotion_id',v.promotion_id,'discount_amount',v.discount_amount,'operation_id',v.operation_id); END IF;
  IF p.usage_limit_total IS NOT NULL AND (SELECT count(*) FROM public.promotion_redemptions WHERE company_id=p_company_id AND promotion_id=p.id)>=p.usage_limit_total THEN RAISE EXCEPTION 'تم استنفاد الحد الإجمالي للعرض'; END IF;
  IF p_customer_id IS NOT NULL AND p.usage_limit_per_customer IS NOT NULL AND (SELECT count(*) FROM public.promotion_redemptions WHERE company_id=p_company_id AND promotion_id=p.id AND customer_id=p_customer_id)>=p.usage_limit_per_customer THEN RAISE EXCEPTION 'تم استنفاد حد استخدام العميل لهذا العرض'; END IF;
  INSERT INTO public.promotion_redemptions(company_id,promotion_id,order_id,customer_id,channel_scope,coupon_code,discount_amount,free_items,operation_id,created_by) VALUES(p_company_id,p.id,p_order_id,p_customer_id,COALESCE(p_channel_scope,'all'),p_coupon_code,GREATEST(COALESCE(p_discount_amount,0),0),COALESCE(p_free_items,'[]'::jsonb),p_operation_id,p_user_email) RETURNING * INTO v;
  RETURN jsonb_build_object('success',true,'duplicate',false,'redemption_id',v.id,'promotion_id',v.promotion_id,'discount_amount',v.discount_amount,'operation_id',v.operation_id);
END;
$function$;

REVOKE ALL ON FUNCTION public.resolve_promotion_cart(uuid,uuid,uuid,text,numeric,jsonb,text,date) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.record_promotion_redemption(uuid,uuid,uuid,uuid,text,text,numeric,jsonb,text,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.resolve_promotion_cart(uuid,uuid,uuid,text,numeric,jsonb,text,date) TO service_role;
GRANT EXECUTE ON FUNCTION public.record_promotion_redemption(uuid,uuid,uuid,uuid,text,text,numeric,jsonb,text,text) TO service_role;

COMMIT;
