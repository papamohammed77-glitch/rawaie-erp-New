BEGIN;

CREATE TABLE IF NOT EXISTS public.commercial_catalogs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  code text NOT NULL,
  name text NOT NULL,
  currency text NOT NULL DEFAULT 'SAR',
  priority integer NOT NULL DEFAULT 100,
  is_default boolean NOT NULL DEFAULT false,
  is_active boolean NOT NULL DEFAULT true,
  valid_from date,
  valid_until date,
  notes text,
  created_by text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT commercial_catalogs_valid_range CHECK (valid_until IS NULL OR valid_from IS NULL OR valid_until >= valid_from),
  CONSTRAINT commercial_catalogs_company_code_key UNIQUE (company_id,code)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_commercial_catalogs_one_default
ON public.commercial_catalogs(company_id) WHERE is_default=true;

CREATE INDEX IF NOT EXISTS ix_commercial_catalogs_lookup
ON public.commercial_catalogs(company_id,is_active,priority,id);

CREATE TABLE IF NOT EXISTS public.commercial_catalog_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  catalog_id uuid NOT NULL REFERENCES public.commercial_catalogs(id) ON DELETE CASCADE,
  sequence integer NOT NULL DEFAULT 100,
  scope_type text NOT NULL,
  item_id uuid REFERENCES public.items(id) ON DELETE RESTRICT,
  category_id uuid REFERENCES public.categories(id) ON DELETE RESTRICT,
  min_qty numeric NOT NULL DEFAULT 1,
  pricing_method text NOT NULL,
  unit_price numeric NOT NULL DEFAULT 0,
  percent_value numeric NOT NULL DEFAULT 0,
  extra_fee numeric NOT NULL DEFAULT 0,
  rounding_multiple numeric NOT NULL DEFAULT 0,
  valid_from date,
  valid_until date,
  is_active boolean NOT NULL DEFAULT true,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT commercial_catalog_rules_scope_ck CHECK ((scope_type='all' AND item_id IS NULL AND category_id IS NULL) OR (scope_type='category' AND item_id IS NULL AND category_id IS NOT NULL) OR (scope_type='item' AND item_id IS NOT NULL AND category_id IS NULL)),
  CONSTRAINT commercial_catalog_rules_method_ck CHECK (pricing_method IN ('fixed','discount_percent','markup_percent')),
  CONSTRAINT commercial_catalog_rules_valid_range CHECK (valid_until IS NULL OR valid_from IS NULL OR valid_until >= valid_from),
  CONSTRAINT commercial_catalog_rules_min_qty_ck CHECK (min_qty > 0),
  CONSTRAINT commercial_catalog_rules_unit_price_ck CHECK (unit_price >= 0),
  CONSTRAINT commercial_catalog_rules_percent_ck CHECK (percent_value >= 0 AND percent_value <= 100),
  CONSTRAINT commercial_catalog_rules_rounding_ck CHECK (rounding_multiple >= 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_commercial_catalog_rules_item_tier
ON public.commercial_catalog_rules(catalog_id,item_id,min_qty) WHERE item_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS ux_commercial_catalog_rules_category_tier
ON public.commercial_catalog_rules(catalog_id,category_id,min_qty) WHERE category_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS ux_commercial_catalog_rules_all_tier
ON public.commercial_catalog_rules(catalog_id,min_qty) WHERE scope_type='all';
CREATE INDEX IF NOT EXISTS ix_commercial_catalog_rules_lookup
ON public.commercial_catalog_rules(catalog_id,min_qty DESC,sequence);

CREATE TABLE IF NOT EXISTS public.commercial_customer_links (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  catalog_id uuid NOT NULL REFERENCES public.commercial_catalogs(id) ON DELETE CASCADE,
  customer_id uuid NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  is_primary boolean NOT NULL DEFAULT false,
  created_by text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT commercial_customer_links_unique UNIQUE(catalog_id,customer_id)
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_commercial_customer_primary
ON public.commercial_customer_links(customer_id) WHERE is_primary=true;
CREATE INDEX IF NOT EXISTS ix_commercial_customer_lookup
ON public.commercial_customer_links(company_id,customer_id,is_primary);

ALTER TABLE public.commercial_catalogs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commercial_catalogs FORCE ROW LEVEL SECURITY;
ALTER TABLE public.commercial_catalog_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commercial_catalog_rules FORCE ROW LEVEL SECURITY;
ALTER TABLE public.commercial_customer_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commercial_customer_links FORCE ROW LEVEL SECURITY;
REVOKE ALL PRIVILEGES ON TABLE public.commercial_catalogs FROM anon,authenticated;
REVOKE ALL PRIVILEGES ON TABLE public.commercial_catalog_rules FROM anon,authenticated;
REVOKE ALL PRIVILEGES ON TABLE public.commercial_customer_links FROM anon,authenticated;

COMMIT;
