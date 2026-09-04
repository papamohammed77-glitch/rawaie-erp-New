# RAWAEA ERP — CURRENT STATE PACK

## 0. AUTHORITATIVE UPDATE — 2026-09-04

This file is the continuity checkpoint. Git chronology and direct Production evidence outrank narrative; historical reports are preserved evidence, not truth by themselves.

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
HISTORICAL REPOSITORY = papamohammed77-glitch/rawaie-erp-review
CANONICAL PRODUCT TARGET = Current/PWA/New-main
LATEST FORENSIC REPORT = doc/Draft/Reprots/تقرير51.md
LATEST KNOWLEDGE PACK = doc/Draft/Reprots/MASTER_RAWAEA_SYSTEM_PWA_KNOWLEDGE_PACK_2026-09-04.md
LATEST SUCCESSOR = doc/Draft/medhat/MASTER_CTO_FORENSIC_BRAND_PATCH_SUCCESSOR_V12.md
```

The immediately preceding verified HEAD before this state update was:

```text
0ee91c707aa969b279a98a2c63d59ed3cd63aeb8
```

That commit updated `PROJECT_MEMORY.md` with the knowledge completion. This `CURRENT_STATE.md` update becomes the new continuity commit; do not hard-code a self-referential SHA. Discover the exact current `main` HEAD directly from Git.

---

# 1. LATEST VERIFIED MILESTONE

The latest mission was **knowledge recovery and system/PWA topology completion**, not a product patch.

Created:

```text
Report51
MASTER_RAWAEA_SYSTEM_PWA_KNOWLEDGE_PACK_2026-09-04.md
```

The Knowledge Pack closes the previous assistant's false/obsolete assumptions about the identity of `Current/PWA/New-main`, the location and role of CSS/runtime, the PWA consumer map, and the parent-system boundary.

No Product Patch, Database Patch, or deployment was performed in this milestone.

---

# 2. CRITICAL GIT CHRONOLOGY

Verified recent `main` sequence before this state update:

```text
71c9c3f5682cbadbfbc759392f8e0daa07a95b85
[CTO] Add Report51 verified system and PWA knowledge completion

f66d38575d6e3d8c76e8536e3c63beb23aea43a5
[CTO] Add verified RAWAEA system and PWA consumer knowledge pack

67fd5b327139be15964e4ecaa98218b0b7345ccf
[CTO] Refresh PROJECT_MEMORY with verified GitHub/Supabase review 2026-09-04

4b93e9178397028b6345c3a863d65e659a696331
[CTO] Sync CURRENT_STATE with Report50 and corrected main ancestry

391de3fb38cb63f5c9ea6a3e62a91a5a3727a1a
[CTO] Add Report50 forensic PWA consumer inventory and state reconciliation
```

Historical `Current/PWA/New-main` mutation commits were also found:

```text
2118dff88f25ff09a397211293753898d1d9316a
94ffee68ee6d039661fe8eb0d3b06a15a789b830
6d7291026cf658e4d4c3b0b02f771dbefbe62ad1
```

Their parent chains are independent from the current documentation chain; therefore they are historical/alternate attempts, not proof of current-main state.

Rule:

```text
CURRENT main ancestry > alternate/orphan repair chain
COMMIT MESSAGE != DEPLOYMENT PROOF
GIT SOURCE != BROWSER RUNTIME PROOF
```

---

# 3. CURRENT TARGET — `Current/PWA/New-main`

Direct current-main fetch proves `New-main` is a complete HTML/CSS/JS PWA artifact, not a 56-line descriptive placeholder.

Current target blob previously verified:

```text
22f4ee1a666141be62127159337beffb05e8b146
575336 bytes
```

Known current source values:

```text
rw-login-title = 58px
rw-login-logo = 88 × 88
```

Current login identity includes:

```text
RAWAEA ERP ENTERPRISE
الروائع ERP
منصة إدارة الأعمال الذكية والمتكاملة
```

Current source includes an inline CSS shell, Supabase client, manifest link, and service-worker coordinator.

Historical Original evidence (`Original/PWA/main/main1.md`) proves:

```text
<title>الروائع ERP | نظام متكامل</title>
rw-login-title = 64px
rw-login-logo = 120 × 120
rw-company-name = 34px
```

Difference is confirmed. Regression is NOT proven; do not patch branding/visual dimensions solely from Original comparison.

---

# 4. SYSTEM / PWA ARCHITECTURE CONTRACT

The whole RAWAEA ERP system is not a single HTML file. The verified topology is:

```text
RAWAEA ERP BUSINESS SYSTEM
        |
        +--> PWA / UI CONSUMERS
        |       |
        |       +--> New-main / main.html / role-specific PWAs / store / vouchers
        |
        +--> Shared PWA Runtime
        |       |
        |       +--> core.js
        |       +--> service-worker coordination
        |
        +--> Supabase Edge Functions / RPC contracts
        |
        +--> PostgreSQL / Supabase SSOT
```

PWA is interface/orchestration. Business authority remains in Edge/RPC/DB contracts. Do not create competing business authority inside an HTML consumer.

---

# 5. SHARED RUNTIME — `Current/PWA/core.js`

Direct source inspection proves:

```text
RW_Auth
RW_DB
RW_API
RW_UI
```

`RW_Auth` restores Supabase session, reads Auth metadata, derives `isOwner`/permissions, and implements wildcard semantics:

```text
isOwner=true -> full frontend permission
permissions contains '*' -> full frontend permission
```

`RW_DB` is the shared Dexie/local persistence/sync layer for customers/items/stock/branches/orders/pending updates.

`RW_API` calls `/functions/v1/<function>` using the authenticated bearer token and provides retry behavior.

`register-sw.js` coordinates `sw.js`, update checks, and reload after controller change. Source/deployed/browser cache remain distinct evidence layers.

---

# 6. CURRENT PWA CONSUMER INVENTORY

## Parent / Main
```text
New-main
main.html
```

## Sales / Orders
```text
telesales.html
order-taker.html
van-sales.html
pos.html
```

## Warehouse / Physical Operations
```text
picker.html
loader.html
receiver.html
unloader.html
warehouse.manager.html
warehouse.supervisor
Returns.html
```

## Driver / Delivery
```text
driver.html
driver.supervisor.html
```

## Purchasing / Finance / Management
```text
buyer.html
buyers.supervisor.html
accountant.html
finance-manager.html
general-manager.html
hr.html
sales.manager.html
sales.supervisor.html
```

## Owner / General Entry
```text
owner.html
counter.html
index.html
app.html
```

## Online Store
```text
store.index.html
store.track.html
```

## Vouchers
```text
vouchers.html
```

These are consumer/entry surfaces, not separate business authorities.

---

# 7. SHARED SUPPORT FILES — NOT SEPARATE APPLICATIONS

```text
core.js
sw.js
register-sw.js
New-main.manifest.json
manifest.json
schema-validator.js
vouchers-gold-master-ui.js
New-main-icon.svg
_headers
```

`Current/PWA/main/` contains `main1.md` … `main11.md` plus trigger/history materials. These are Parent PWA contract/history materials, not eleven independent apps.

---

# 8. PRODUCTION SUPABASE — VERIFIED

```text
PROJECT = SMART ERP
REF = fiilmooggumokxanwiyx
STATUS = ACTIVE_HEALTHY
REGION = eu-west-1
POSTGRESQL = 17.6
```

Direct production Edge Function inventory confirms active business functions including sales/orders, runsheet/picking/loading/delivery/returns, stock vouchers, purchasing, accounting/reporting, and audit/supporting workflows.

Examples of observed deployed production versions:

```text
save-sales-invoice       v15
create-runsheet          v26
start-picking            v34
complete-picking         v17
start-loading            v5
complete-loading         v11
start-delivery           v7
complete-delivery        v4
complete-return          v25
unload-runsheet          v6
send-stock-voucher       v20
receive-stock-voucher    v22
receive-purchase         v12
save-journal-entry       v8
```

Most observed business functions use `verify_jwt=true`. A separate active surface of test/recovery/E2E functions uses `verify_jwt=false` and remains an open lifecycle/security classification item.

---

# 9. OWNER / LICENSE CONTRACT — PROTECTED

Fresh direct Production DB query verifies:

```text
owner@alrawae.com
permissions = ["*"]
status = Active
role = مدير النظام
role_id = e8a76adb-8efe-4bc5-b760-0ee660f10e9f
auth_id = 0a6089e6-0c33-4cf9-9aa0-31fc42774b89
owner_profile.auth_user_id = same auth_id
license_status = active
```

Canonical owner contract:

```text
OWNER
=
AUTH OWNER IDENTITY
+
isOwner=true
+
permissions=["*"]
+
VALID owner_profile
+
ACTIVE LICENSE
```

Never replace `*` with role-permission enumeration and never use `role_id` as substitute for owner identity.

---

# 10. LICENSE MANAGEMENT — CURRENT KNOWLEDGE

Current source contract is recorded as:

```text
view = license
label = إدارة الترخيص
perm = owner
route = RW_OwnerLicense.render
owner gate = hasOwner()
```

Together with `core.js` wildcard/owner handling, this proves the authorization design at source level.

Current evidence boundary remains:

```text
SOURCE CONTRACT = VERIFIED
OWNER DB CONTRACT = VERIFIED
FRESH BROWSER TAB VISIBILITY = NOT VERIFIED
DEPLOYED REVISION = NOT VERIFIED
SERVICE WORKER/CACHE = NOT VERIFIED
```

Do not invent a duplicate route before fresh runtime proof.

---

# 11. INVENTORY CONTINUITY — PROTECTED

```text
post_stock_movement = physical stock movement authority
reserve_stock = reservation authority
allocated_qty != physical qty
PWA != stock authority
```

Do not reopen Inventory/Accounting/Ledger/Treasury merely because a historical report references them. Reopen only when the next Closure Unit proves a blocking dependency.

---

# 12. CURRENT RUNTIME / DEPLOYMENT CONFIDENCE

```text
STATIC SOURCE = CONFIRMED
SUPABASE OWNER/DB STATE = CONFIRMED
FRESH BROWSER E2E = UNKNOWN
DEPLOYED REVISION = UNKNOWN
SERVICE WORKER/CACHE = UNKNOWN
FRESH GOLD = NOT PROVEN
FRESH DIAMOND = NOT PROVEN
WHOLE-PROJECT 100% = NOT PROVEN
```

A fresh Edge Function log query during this recovery returned no rows. Prior reports/memory mention repeated HTTP 410 calls to `owner-recovery-20260818`; that historical evidence remains a lead and was not re-presented as fresh log output in this run.

---

# 13. OPEN PRODUCTION RISKS

```text
SECURITY DEFINER EXECUTE exposure was previously observed for:
  public.create_item_with_opening_stock(...)
  public.sync_company_main_branch_projection(...)

Supabase Auth leaked-password protection = previously observed disabled

verify_jwt=false historical/test/recovery/E2E functions remain active

Repeated historical owner-recovery-20260818 HTTP 410 calls remain an unresolved caller/lifecycle lead

Database advisories include unindexed foreign keys, RLS init-plan warnings,
multiple permissive policies, and unused indexes

Empty combined CI status != PASS
```

These are independent Closure Units; they are not evidence that the PWA consumer map is wrong.

---

# 14. HISTORICAL EVIDENCE POLICY

Use historical files to recover intent, architecture, chronology, prior failures, and contracts:

```text
rawaie-erp-review/
Edge_Functions/original/03_loading/
Original/PWA/main/main1.md
Current/PWA/main/main1.md ... main11.md
doc/Draft/Reprots/*
doc/Draft/Hussin/*
doc/Draft/Hytham/*
doc/Draft/Khalid/*
doc/Draft/medhat/*
```

Authority ordering:

```text
CURRENT PRODUCTION REALITY
>
CURRENT main SOURCE
>
CURRENT EVIDENCE / DEPLOYMENT RECORDS
>
HISTORICAL SOURCE / ARCHITECTURE
>
REPORTS / PROMPTS AS SEARCH LEADS
```

If current Production and a historical conclusion conflict, investigate and classify the drift; do not silently revive the historical state.

---

# 15. SUCCESSOR BOOT — MANDATORY

Every Successor CTO must:

```text
1. Read CURRENT_STATE.md to EOF.
2. Read the latest numbered forensic report to EOF.
3. Read MASTER_RAWAEA_SYSTEM_PWA_KNOWLEDGE_PACK_2026-09-04.md to EOF.
4. Discover current `main` HEAD directly.
5. Verify the current `Current/PWA/New-main` blob directly.
6. Check relevant Production version/schema/log evidence.
7. Classify every claim:
   THEORETICAL / CURRENT ONLY / STAGING VERIFIED /
   PRODUCTION DEPLOYED / PRODUCTION RUNTIME VERIFIED / 100% CLOSED
8. Select exactly ONE Closure Unit.
9. READ → VERIFY → RECONCILE → PLAN → PATCH (only if proven)
   → TEST → REVIEW → RECORD → NEXT GATE.
10. Write the next report without deleting historical reports.
11. Update CURRENT_STATE last.
```

Never use:

```text
READ → GUESS → PATCH → DEPLOY
```

---

# 16. KNOWLEDGE GAPS — STATUS AFTER REPORT51

Resolved by direct evidence:

```text
New-main is full source, not placeholder = RESOLVED
Login CSS location = RESOLVED
Shared runtime location/role = RESOLVED
Current PWA consumer inventory = RESOLVED
Mother-system ↔ consumer boundary = RESOLVED
Owner wildcard DB contract = RESOLVED
```

Still open:

```text
Fresh browser E2E
Exact deployed revision/cache identity
Full PR/issue closure history
Lifecycle classification of every verify_jwt=false function
Intent behind all historical/current branding differences
Whole-system Gold/Diamond acceptance
```

---

# 17. KNOWN INVESTIGATOR ERRORS — DO NOT REPEAT

```text
Do not start from zero.
Do not treat stale CURRENT_STATE as current HEAD.
Do not confuse Git history with current branch ancestry.
Do not treat an alternate repair commit as active from its message.
Do not infer file absence from partial/failed reads.
Do not treat Original differences as regressions automatically.
Do not treat source route existence as browser visibility proof.
Do not replace owner ["*"] with role enumeration.
Do not assume schema column names in Production.
Do not treat reports/self-attestation as source truth.
Do not treat Git as deployment proof.
Do not introduce speculative architecture into a narrow defect.
Do not rewrite a whole PWA for a small proven change.
Do not delete historical reports.
```

---

# 18. RAW CONTINUITY PACK

```text
CURRENT_STATE
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/CURRENT_STATE.md

PROJECT_MEMORY
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/PROJECT_MEMORY.md

LATEST FORENSIC REPORT
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/doc/Draft/Reprots/%D8%AA%D9%82%D8%B1%D9%8A%D8%B151.md

SYSTEM + PWA KNOWLEDGE PACK
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/doc/Draft/Reprots/MASTER_RAWAEA_SYSTEM_PWA_KNOWLEDGE_PACK_2026-09-04.md

NEW-MAIN
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/New-main

MAIN.HTML
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/main.html

CORE
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/core.js

REGISTER SW
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/register-sw.js

SERVICE WORKER
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/sw.js

CURRENT MAIN1
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/main/main1.md

ORIGINAL MAIN1
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Original/PWA/main/main1.md
```

## FINAL CONTINUITY RULE

> Inherit evidence trails, not confidence. Reality outranks narrative. Current `main` ancestry outranks alternate history. Production evidence outranks reports. Current PWA consumers are interfaces of one RAWAEA ERP system, not competing business authorities. Owner wildcard semantics are protected.
