# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-13

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

Permanent rule:
`NO ASSUMPTION`
`ONE CLOSURE AT A TIME`
`CLOSE -> VERIFY -> DOCUMENT -> NEXT`

## CURRENT GIT — FRONTEND
Repository:
`papamohammed77-glitch/erp-frontend`
Branch: `main`

HEAD:
`edf60227f88eaabec10cf1083d87bb2665990279`
Message:
`Update print statement from 'Hello' to 'Goodbye'`

Direct Parent:
`d0cfb6fefd1af960de336935d8eec6d831c2d101`

Parent of Parent:
`aaebffbdd732b9861d96631f5d01c5a6697bd1e4`

Current main.html blob:
`35ec01656f426d19c675b73ed5c53445f1f12ad1`

## FORENSIC ASSEMBLY
`forensic_main_assembly.yml` verified correct:
`erp-frontend/companies/company-1/main.html`

Mode:
`published_main_is_authoritative`

No historical fragment is Source of Truth.

## CURRENT PRODUCTION DATABASE
Supabase project:
`fiilmooggumokxanwiyx`

Current companies:
`1`

Current core rows:
- items: 17
- customers: 3
- branches: 2
- orders: 0
- purchase_orders: 0
- runsheets: 0
- inventory_log: 3
- audit_log: 1906

## PRICE LIST ENGINE — CURRENT CHECKPOINT

### Production schema deployed
- `commercial_catalogs`
- `commercial_catalog_rules`
- `commercial_customer_links`

Relations:
`commercial_catalogs.company_id -> companies.id`
`commercial_catalog_rules.catalog_id -> commercial_catalogs.id`
`commercial_catalog_rules.item_id -> items.id`
`commercial_catalog_rules.category_id -> categories.id`
`commercial_customer_links.company_id -> companies.id`
`commercial_customer_links.catalog_id -> commercial_catalogs.id`
`commercial_customer_links.customer_id -> customers.id`

Pricing dimensions currently supported:
- catalog
- priority
- default catalog
- active state
- validity dates
- item rule
- category rule
- global rule
- minimum quantity
- fixed price
- discount percentage
- markup percentage
- extra fee
- customer primary assignment
- fallback to `items.sales_price`

### Production security
RLS enabled + FORCE enabled on all three Price List tables.
`anon` and `authenticated` table privileges revoked.
Browser access must use the Edge capability after JWT validation.

### Production Edge
`commercial-catalog`
Status: `ACTIVE`
Version: `1`
`verify_jwt=true`

Capabilities:
`list / catalog / detail / create / update / assign / resolve / delete`

### Production test
Transactional schema/rule creation test passed and was rolled back.
No permanent test Price List data exists.

### Current Price List status
`BACKEND FOUNDATION = DEPLOYED`
`EDGE API = DEPLOYED`
`SECURITY = VERIFIED`
`OWNER UI = MERGE REQUIRED`
`BROWSER E2E = OPEN`
`QUOTE CONSUMER WIRING = NEXT SEPARATE CLOSURE`

Do not mark Price List FULL BUSINESS CAPABILITY as CLOSED until owner merge + browser E2E are proven.

## OWNER PATCH
Exact owner-side patch:
`doc/Draft/Reprots/PRICE_LIST_OWNER_SURGICAL_PATCH_20260913.js`

Owner modifies only:
`erp-frontend/companies/company-1/main.html`

Required insertion points:
- navigation after `quotes`
- permissionMap after `'quotes': 'orders'`
- titles after `'quotes':'عروض الأسعار'`
- render route after `RW_SalesQuotes.render()`
- full `RW_PriceLists` module after `window.RW_SalesQuotes = RW_SalesQuotes;` and before `EVENTS & BOOT`

Do not modify historical fragments.

## GIT BACKEND ARTIFACTS ADDED
- `supabase/migrations/20260913_commercial_catalog_engine.sql`
- `Current/Edge_Functions/commercial-catalog/index.ts`
- `doc/Draft/Reprots/PRICE_LIST_OWNER_SURGICAL_PATCH_20260913.js`
- `doc/Draft/Reprots/Report167_PRICE_LIST_ENGINE_EXECUTION_20260913.md`

## QUOTE STATUS — DO NOT REOPEN WITHOUT CONTRADICTORY CURRENT EVIDENCE
Current main.html already contains Quotes route/module.
Previous Quote backend closure remains valid unless new CURRENT evidence contradicts it.

Quote Edge:
`sales-quotes v2 ACTIVE`
`verify_jwt=true`

## INVENTORY STATUS
Physical stock contract remains:
`Physical Movement -> post_stock_movement -> stock_branches + inventory_log`

Do not introduce any second physical stock engine.
Do not move pricing logic into Physical Stock.

## OPEN CONTRACTS
```text
Price List backend foundation       = DEPLOYED
Price List Edge API                = DEPLOYED
Price List owner UI                = OWNER MERGE REQUIRED
Price List browser E2E             = OPEN
Price List consumer integration    = OPEN / NEXT CLOSURE
Promotion engine                   = OPEN
Multiple/Partial Payment           = OPEN
Installment lifecycle              = OPEN
Commission engine                  = OPEN
Sales Targets engine               = OPEN
Loyalty transaction engine         = OPEN
Sales Decision Center              = OPEN
Full browser E2E                   = OPEN
```

## NEXT CTO / ASSISTANT INSTRUCTIONS
Do not start from reports as state.
Start from:
`CURRENT GIT HEAD`
`-> DIRECT PARENT`
`-> CURRENT SOURCE SHA`
`-> CURRENT DATABASE`
`-> CURRENT DEPLOYMENTS`
`-> CURRENT RUNTIME`
`-> BROWSER E2E`

At every continuation:
`REFRESH PRODUCTION`
`REFRESH DATABASE`
`REFRESH DEPLOYMENTS`
`REFRESH EDGE VERSIONS`
`REFRESH RPC DEFINITIONS`
`REFRESH GIT`

Then:
`historical contract -> current behavior -> target contract -> actual gap -> surgical change -> test -> deploy -> Production verify -> runtime verify -> document -> close`

No false closure:
`COMMIT != DEPLOYMENT`
`DEPLOYMENT != RUNTIME SUCCESS`
`RUNTIME SUCCESS != PRODUCTION VERIFIED`
`PRODUCTION VERIFIED != FULLY CLOSED`

## CURRENT CHECKPOINT
```text
CURRENT GIT                         = VERIFIED
CURRENT PARENT CHAIN               = VERIFIED
CURRENT main.html SOURCE            = VERIFIED
FORENSIC ASSEMBLY AUTHORITY         = VERIFIED / CORRECT
PRICE LIST DB FOUNDATION            = DEPLOYED
PRICE LIST DB SECURITY              = VERIFIED
PRICE LIST EDGE                     = DEPLOYED v1
PRICE LIST TRANSACTIONAL TEST       = PASS / ROLLBACK
PRICE LIST OWNER UI                 = MERGE REQUIRED
PRICE LIST BROWSER E2E              = OPEN
QUOTE BACKEND                       = DO NOT REOPEN WITHOUT CONTRADICTORY EVIDENCE
INVENTORY CORE                      = DO NOT REOPEN WITHOUT CONTRADICTORY EVIDENCE
```
