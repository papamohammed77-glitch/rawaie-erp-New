# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-14

## GOVERNANCE
التقارير السابقة Historical/Reference فقط وليست الحالة الحالية.

الحالة المعتمدة:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

Source of Truth للنظام الأم:
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

Historical reference only:
`Current/PWA/main2/*`
`Original/PWA/main/*`
`New-main`

Permanent rules:
`NO ASSUMPTION`
`ONE CLOSURE AT A TIME`
`REPORTS ARE CLUES — NEVER CURRENT STATE`
`CLOSE -> VERIFY -> DOCUMENT -> NEXT`

## CURRENT GIT — FRONTEND
Repository:
`papamohammed77-glitch/erp-frontend`
Branch: `main`

HEAD:
`2ad8da6057cf9c7f1e0ddb8374a7b220d21ee28b`
Message:
`Update main.html`

Direct Parent:
`edf60227f88eaabec10cf1083d87bb2665990279`

Parent of Parent:
`aaebffbdd732b9861d96631f5d01c5a6697bd1e4`

Current main.html blob:
`0519117415390d6721c977fafab1a413d72bf52c`

Current main.html remains Owner Source of Truth. It was not modified directly by the assistant in this cycle.

## CURRENT GIT — BACKEND / FORENSIC REPO
Repository:
`papamohammed77-glitch/rawaie-erp-New`

Latest continuity commits created this cycle include:
- `9f88bcf3fd3581fecfb4de3dd545a4b32d64b366` — Promotion Engine core migration
- `ba54a062167ac782373f5a502ec274aa30030677` — Promotion Edge canonical source
- `d89dacd7b8548222d291952f2b254ba88beccd50` — Promotion Owner surgical patch
- `389812aca135c8c32124a606bfe4d7ce4c9c5384` — Resolver hardening migration
- `0359669c0135fdb9cb4394af643f1966e49df2fe` — Report168

## FORENSIC ASSEMBLY
`forensic_main_assembly.yml` remains correct and points to:
`erp-frontend/companies/company-1/main.html`

Mode:
`published_main_is_authoritative`

No historical fragment is Source of Truth.

## CURRENT PRODUCTION DATABASE
Supabase project:
`fiilmooggumokxanwiyx`

Current database clock evidence during this cycle returned `current_database=postgres` and `current_date=2026-09-13` from the production session.

Current companies count verified:
`1`

No permanent Promotion test data remains:
`promotions = 0`
`promotion_rules = 0`

## PROMOTION ENGINE — CURRENT CHECKPOINT

### Production schema deployed
- `promotions`
- `promotion_rules`
- `promotion_customers`
- `promotion_branches`
- `promotion_redemptions`

Relations:
- `promotions.company_id -> companies.id`
- `promotion_rules.promotion_id -> promotions.id`
- `promotion_rules.item_id -> items.id`
- `promotion_rules.category_id -> categories.id`
- `promotion_customers.company_id -> companies.id`
- `promotion_customers.promotion_id -> promotions.id`
- `promotion_customers.customer_id -> customers.id`
- `promotion_branches.company_id -> companies.id`
- `promotion_branches.promotion_id -> promotions.id`
- `promotion_branches.branch_id -> branches.id`
- `promotion_redemptions.company_id -> companies.id`
- `promotion_redemptions.promotion_id -> promotions.id`
- `promotion_redemptions.order_id -> orders.id`
- `promotion_redemptions.customer_id -> customers.id`

### Promotion capabilities
- percentage discount
- fixed discount
- cheapest-item discount
- Buy X Get Y / free-item reward
- automatic trigger
- coupon-code trigger
- exclusive / stackable policy
- channel scope
- customer scope
- branch scope
- minimum subtotal
- minimum quantity
- priority
- date validity
- usage limits
- redemption record
- idempotent redemption
- idempotent create via `promotions.operation_id`

### Security
RLS enabled + FORCE enabled on Promotion tables.
`anon` and `authenticated` table access revoked.
Backend capability uses authenticated JWT -> `public.users.auth_id` -> `company_id`.
No tenant resolution from `app_settings LIMIT 1` exists in `promotion-engine`.

### Production RPCs
- `resolve_promotion_cart`
- `record_promotion_redemption`
- `set_promotion_active_atomic`

### Production Edge
`promotion-engine`
Status: `ACTIVE`
Version: `2`
`verify_jwt=true`
Deployment SHA:
`a7d1614391c61080e81df71a36fce1272eff01580f7747f8a45a82b7755016ef`

Capabilities:
`catalog / list / detail / create / update / set_active / resolve / redeem`

### Production tests
Resolver transactional test:
`PASS`

Result:
`subtotal=100`
`discount=10`
`final_subtotal=90`
`candidate_count=1`

Redemption retry test:
`FIRST = duplicate:false`
`RETRY = duplicate:true`
`same redemption_id`

All test transactions were rolled back.

## PROMOTION OWNER PATCH
Owner-side patch:
`doc/Draft/Reprots/PROMOTION_OWNER_SURGICAL_PATCH_20260914.js`

Target only:
`erp-frontend/companies/company-1/main.html`

Exact changes prepared:
- navigation after `price-lists`
- permissionMap after `'price-lists': 'orders'`
- titles after `'price-lists':'قوائم الأسعار'`
- render route after `RW_PriceLists.render()`
- complete `RW_Promotions` module after `window.RW_PriceLists = RW_PriceLists;` and before `EVENTS & BOOT`

The assistant must NOT modify the Owner master file directly.

## PROMOTION GIT BACKEND ARTIFACTS
- `supabase/migrations/20260914_promotion_engine_core.sql`
- `supabase/migrations/20260914_promotion_engine_hardening.sql`
- `supabase/migrations/20260914_promotion_engine_resolver_hardening.sql`
- `Current/Edge_Functions/promotion-engine/index.ts`
- `doc/Draft/Reprots/PROMOTION_OWNER_SURGICAL_PATCH_20260914.js`
- `doc/Draft/Reprots/Report168_PROMOTION_ENGINE_EXECUTION_20260914.md`

## PRICE LIST STATUS
Price List backend remains deployed.
Price List Owner UI requires Owner merge.
Price List browser E2E remains open.
Price List -> consumer integration remains a separate closure.
Do not reopen Price List backend without contradictory CURRENT evidence.

## INVENTORY STATUS
Physical stock contract remains:
`Physical Movement -> post_stock_movement -> stock_branches + inventory_log`

Promotion Engine does not write physical stock.
Do not introduce a second physical stock engine.

## OPEN CONTRACTS
```text
Price List backend foundation       = DEPLOYED
Price List Edge API                = DEPLOYED
Price List owner UI                = OWNER MERGE REQUIRED
Price List browser E2E              = OPEN
Price List consumer integration    = OPEN / NEXT CLOSURE
Promotion backend                  = PRODUCTION DEPLOYED
Promotion Edge                     = PRODUCTION DEPLOYED v2
Promotion owner UI                 = OWNER MERGE REQUIRED
Promotion browser E2E               = OPEN
Promotion consumer integration     = OPEN / NEXT CLOSURE
Multiple/Partial Payment           = OPEN
Installment lifecycle              = OPEN
Commission engine                  = OPEN
Sales Targets engine               = OPEN
Loyalty transaction engine         = OPEN
Sales Decision Center              = OPEN
Full browser E2E                   = OPEN
```

## CURRENT CHECKPOINT
```text
CURRENT FRONTEND HEAD              = VERIFIED
CURRENT DIRECT PARENT              = VERIFIED
CURRENT main.html SOURCE            = VERIFIED
FORENSIC ASSEMBLY AUTHORITY         = VERIFIED / CORRECT
PROMOTION DB CORE                   = PRODUCTION DEPLOYED
PROMOTION SECURITY                  = VERIFIED
PROMOTION RESOLVER                  = PRODUCTION DEPLOYED / HARDENED
PROMOTION REDEMPTION                = PRODUCTION DEPLOYED / RETRY VERIFIED
PROMOTION EDGE                      = ACTIVE v2
PROMOTION OWNER UI                  = OWNER MERGE REQUIRED
PROMOTION BROWSER E2E               = OPEN
PROMOTION CONSUMER WIRING           = OPEN
PRICE LIST                          = DO NOT REOPEN WITHOUT CONTRADICTORY EVIDENCE
INVENTORY                           = DO NOT REOPEN WITHOUT CONTRADICTORY EVIDENCE
```

## NEXT CTO / ASSISTANT RESUMPTION RULE

لا تبدأ من Report168 أو أي تقرير آخر كحالة حالية.
ابدأ دائمًا من:

`CURRENT GIT HEAD`
`-> DIRECT PARENT`
`-> CURRENT SOURCE SHA`
`-> CURRENT DATABASE`
`-> CURRENT RPC DEFINITIONS`
`-> CURRENT EDGE DEPLOYMENT`
`-> CURRENT RUNTIME`
`-> OWNER MERGE`
`-> BROWSER E2E`

ثم:

`historical contract -> current behavior -> target contract -> actual gap -> surgical change -> test -> deploy -> Production verify -> runtime verify -> document -> close`

No false closure:
`COMMIT != DEPLOYMENT`
`DEPLOYMENT != RUNTIME SUCCESS`
`RUNTIME SUCCESS != PRODUCTION VERIFIED`
`PRODUCTION VERIFIED != FULLY CLOSED`
