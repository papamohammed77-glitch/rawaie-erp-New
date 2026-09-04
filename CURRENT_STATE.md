# RAWAEA ERP — CURRENT STATE PACK

## 0. AUTHORITATIVE UPDATE — 2026-09-04

This file is the continuity checkpoint, but Git chronology and Production evidence remain higher authority than narrative. Historical reports are preserved evidence, not truth by themselves.

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
HISTORICAL REPOSITORY = papamohammed77-glitch/rawaie-erp-review
CANONICAL PRODUCT TARGET = Current/PWA/New-main
LATEST FORENSIC REPORT = doc/Draft/Reprots/تقرير50.md
LATEST SUCCESSOR = doc/Draft/medhat/MASTER_CTO_FORENSIC_BRAND_PATCH_SUCCESSOR_V12.md
```

Important chronology correction:

```text
PREVIOUS DOCUMENTATION HEAD = cbdd90797629f6410290583efdbbb68011274f98
REPORT50 COMMIT = 391de3fb38cb63f5c9ea6a3e62a91a5a3727a1a
CURRENT_STATE UPDATE = THIS COMMIT
```

After this state update, discover the exact latest `main` HEAD directly from Git; do not hard-code a self-referential SHA.

---

# 1. CRITICAL GIT RECONCILIATION

The stale checkpoint previously recorded `cbdd...` as current HEAD and claimed no New-main mutation after `282cce...`.

Direct Git history now proves that several 2026-09-03 commits touched `Current/PWA/New-main`, including:

```text
2118dff88f25ff09a397211293753898d1d9316a
94ffee68ee6d039661fe8eb0d3b06a15a789b830
6d7291026cf658e4d4c3b0b02f771dbefbe62ad1
```

However their direct parent chains are not the same as the current `main` documentation chain:

```text
8d64... → 901861... → e45da... → cbdd...
```

while the above New-main mutation commits have independent parent chains. Therefore they are historical/alternate attempts, not proof that their intermediate artifacts are the current `main` artifact.

Direct Current/PWA tree inspection still identifies:

```text
TARGET = Current/PWA/New-main
TARGET BLOB = 22f4ee1a666141be62127159337beffb05e8b146
TARGET SIZE = 575336 bytes
```

Rule:

```text
Current main artifact > orphan/alternate repair branch
Commit message != deployment proof
Git source != browser runtime proof
```

---

# 2. CURRENT TARGET REALITY

`Current/PWA/New-main` is a full HTML/CSS/JS PWA artifact, not a tiny descriptive placeholder.

Known source values:

```text
rw-login-title = 58px
rw-login-logo = 88 × 88
```

Current Login identity includes:

```text
RAWAEA ERP ENTERPRISE
الروائع ERP
منصة إدارة الأعمال الذكية والمتكاملة
Clean-room MAIN1 contract surface
```

Historical Original evidence remains:

```text
<title>الروائع ERP | نظام متكامل</title>
rw-login-title = 64px
rw-login-logo = 120 × 120
rw-company-name = 34px
```

Difference is confirmed; regression is not proven.

---

# 3. OWNER / LICENSE CONTRACT — PROTECTED

Fresh direct Production DB verification confirms:

```text
public.users.permissions = ["*"]
status = Active
role = مدير النظام
role_id = e8a76adb-8efe-4bc5-b760-0ee660f10e9f
auth_id = 0a6089e6-0c33-4cf9-9aa0-31fc42774b89
owner_profile linked
license_status = active
```

Owner contract:

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

Never replace `*` with a role-permission enumeration, and never use `role_id` as a substitute for owner identity.

Current source also contains the License route contract:

```text
view = license
label = إدارة الترخيص
perm = owner
route = RW_OwnerLicense.render
owner gate = hasOwner()
```

But:

```text
SOURCE = CONFIRMED
BROWSER VISIBILITY = UNKNOWN
DEPLOYED REVISION = UNKNOWN
SERVICE WORKER/CACHE = UNKNOWN
```

Therefore do not add a duplicate license route without fresh runtime evidence.

---

# 4. SHARED PWA RUNTIME CONTRACT

`Current/PWA/core.js` is the shared runtime loaded by PWA applications. It provides at least:

```text
RW_Auth
RW_DB
RW_API
RW_UI
```

`RW_Auth` restores Supabase Auth session and derives `isOwner`/permissions from Auth metadata. `checkPermission()` treats Owner or `*` as full frontend permission.

`RW_DB` provides the shared Dexie/local-storage layer and local schemas for customers, items, stock, branches, orders and pending updates.

`RW_API` calls Supabase Edge Functions with the authenticated session token.

`register-sw.js` registers `./sw.js`, performs periodic update checks, and reloads after `controllerchange`; therefore cache/service-worker state is part of runtime troubleshooting.

---

# 5. COMPLETE CURRENT/PWA APPLICATION CONSUMER INVENTORY

These are current application/entry surfaces in `Current/PWA`. They are Consumers of the RAWAEA ERP system; they are not separate business authorities.

## Parent / main

```text
New-main
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/New-main

main.html
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/main.html
```

## Sales / Orders

```text
telesales.html
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/telesales.html

order-taker.html
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/order-taker.html

van-sales.html
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/van-sales.html

pos.html
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/pos.html
```

## Warehouse / Physical Operations

```text
picker.html
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/picker.html

loader.html
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/loader.html

receiver.html
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/receiver.html

unloader.html
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/unloader.html

warehouse.manager.html
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/warehouse.manager.html

warehouse.supervisor
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/warehouse.supervisor

Returns.html
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/Returns.html
```

## Driver / Delivery

```text
driver.html
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/driver.html

driver.supervisor.html
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/driver.supervisor.html
```

## Purchasing / Finance / Management

```text
buyer.html
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/buyer.html

buyers.supervisor.html
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/buyers.supervisor.html

accountant.html
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/accountant.html

finance-manager.html
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/finance-manager.html

general-manager.html
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/general-manager.html

hr.html
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/hr.html

sales.manager.html
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/sales.manager.html

sales.supervisor.html
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/sales.supervisor.html
```

## Owner / General Entry Surfaces

```text
owner.html
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/owner.html

counter.html
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/counter.html

index.html
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/index.html

app.html
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/app.html
```

These are entry surfaces within the package; their presence does not make them replacements for `New-main`.

## Online Store

```text
store.index.html
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/store.index.html

store.track.html
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/store.track.html
```

## Vouchers

```text
vouchers.html
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/vouchers.html
```

---

# 6. SHARED SUPPORT FILES — NOT SEPARATE APPLICATIONS

```text
core.js
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/core.js

sw.js
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/sw.js

register-sw.js
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/register-sw.js

New-main.manifest.json
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/New-main.manifest.json

manifest.json
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/manifest.json

schema-validator.js
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/schema-validator.js

vouchers-gold-master-ui.js
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/vouchers-gold-master-ui.js

New-main-icon.svg
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/New-main-icon.svg

_headers
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/_headers
```

---

# 7. CURRENT/PWA/main DIRECTORY

`Current/PWA/main/` contains `main1.md`…`main11.md` plus trigger files. These are Parent PWA contract/history/clean-room materials, not eleven independent applications.

Raw example:

```text
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/main/main1.md
```

---

# 8. PARENT ↔ CONSUMER MODEL

```text
PWA Consumer
   ↓
Shared Runtime / Application Boundary
   ↓
Edge Functions / RPC / Core Contracts
   ↓
PostgreSQL SSOT
```

The PWA layer must remain an interface/orchestration layer. Do not move business authority into individual HTML consumers.

Concrete cross-app evidence: historical source identifies `orders` as a central sales contract consumed by `main.html`, `telesales.html`, `pos.html`, `order-taker.html`, `van-sales.html`, `driver.html`, `store.index.html`, and `store.track.html`.

---

# 9. INVENTORY / BUSINESS AUTHORITY CONTINUITY

The architectural rescue remains:

```text
post_stock_movement = physical stock movement authority
reserve_stock = reservation authority
allocated_qty != physical qty
PWA != stock authority
```

The current task does not reopen Inventory, Accounting, Ledger, or Treasury unless a new Closure Unit proves a blocking dependency.

---

# 10. RUNTIME / DEPLOYMENT STATUS

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

---

# 11. NO-PATCH STATUS FOR REPORT50

```text
PRODUCT PATCH = NONE
DATABASE PATCH = NONE
DEPLOYMENT PATCH = NONE
```

This station was a forensic state reconciliation + knowledge-pack/documentation closure, not a Product Patch.

---

# 12. KNOWN INVESTIGATOR ERRORS — DO NOT REPEAT

```text
Do not start from zero.
Do not treat stale CURRENT_STATE as current HEAD.
Do not confuse Git history with current branch ancestry.
Do not treat an alternate repair commit as active merely from its message.
Do not treat Original differences as regressions automatically.
Do not treat source route existence as browser visibility proof.
Do not replace owner ["*"] with enumerated role permissions.
Do not assume schema column names in Production.
Do not treat reports or self-attestation ledgers as source truth.
Do not treat Git as deployment proof.
Do not introduce speculative architecture into a narrow defect.
Do not rewrite whole PWA files for a small proven change.
```

---

# 13. NEXT SUCCESSOR BOOT

The next assistant must:

```text
1. Read this file to EOF.
2. Read doc/Draft/Reprots/تقرير50.md to EOF.
3. Re-check current Git main HEAD directly.
4. Re-check New-main blob directly.
5. Reconfirm whether target-affecting commits are in current main ancestry.
6. Use the RAW PWA Consumer Pack in Report50 as the application map.
7. Select exactly ONE Closure Unit.
8. Separate source proof from runtime proof.
9. Patch only the smallest proven window, or NO-PATCH.
```

---

# 14. FINAL RAW PACK

Use only raw file URLs when passing source links to a successor:

```text
CURRENT_STATE
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/CURRENT_STATE.md

REPORT50
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/doc/Draft/Reprots/%D8%AA%D9%82%D8%B1%D9%8A%D8%B150.md

NEW-MAIN
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/New-main

MAIN.HTML
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/main.html

CORE
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/core.js

SW COORDINATOR
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/register-sw.js

SERVICE WORKER
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/sw.js

HISTORICAL MAIN1
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/main/main1.md

ORIGINAL MAIN1
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Original/PWA/main/main1.md
```

## FINAL CONTINUITY RULE

> Inherit evidence trails, not confidence. Reality outranks narrative. Current main ancestry outranks alternate repair history. EOF outranks partial visibility. Production/runtime outranks source where they conflict. The PWA consumes the core; it does not become the core.
