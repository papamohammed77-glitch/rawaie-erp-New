# RAWAEA ERP — CURRENT STATE PACK

> **Single operational entry point.** Start here before reading historical reports, prompts, or reconstruction notes.
>
> This file is a **state record, not a report**. Historical documents may explain intent or prior events, but they do not override current Git/Production evidence.

---

## STATE ID

- **State Type:** CURRENT PROJECT STATE
- **State Status:** `CURRENT`
- **Initialized:** 2026-08-31
- **State Rule:** Any real execution that changes Git, Production, deployments, schema, or validated application artifacts MUST be followed by an update to this file before the next authorized action.

---

# CURRENT GIT HEAD

- **Repository:** `papamohammed77-glitch/rawaie-erp-New`
- **Active branch:** `main`
- **HEAD SHA:** `854613bda759f50e8d7b7418d35d01fe4046364c`
- **HEAD message:** `Add final clean-room main.html reconstruction command`
- **Previous verified HEAD:** `03f756ac8db60b6b78d1342bb29e6fb4bf6708b0`
- **HEAD significance:** The new execution command has now become part of the current repository state. No historical main1–main11 report chain may supersede this state.

### Current HEAD evidence
- Commit SHA and message verified directly from GitHub after the new command was created.

---

# CURRENT PRODUCTION SNAPSHOT

**Production snapshot timestamp (UTC):** `2026-08-31T04:53:38.97289+00:00`

Direct Production database evidence:

| Entity / invariant | Current value |
|---|---:|
| companies | 1 |
| users | 24 |
| branches | 2 |
| items | 17 |
| stock_branches | 20 |
| inventory_log | 3 |
| stock_vouchers | 0 |
| purchase_orders | 0 |
| orders | 0 |
| runsheets | 0 |
| audit_log | 1866 |
| negative physical qty rows | 0 |
| negative allocated qty rows | 0 |
| available_qty mismatches | 0 |
| cross-company stock rows | 0 |
| cross-company inventory-log rows | 0 |

Additional direct Production facts:

- `items.item_code` has a database-wide `UNIQUE` constraint.
- `stock_branches` has a database `UNIQUE (branch_id, item_id)` constraint.
- `receiving.operation_id` has a database-wide `UNIQUE` constraint.
- `post_stock_movement` exists in two overloads: the legacy 9-argument form and the idempotency-aware 10-argument form.
- Both `post_stock_movement` overloads are `SECURITY DEFINER`.
- Current Production contains `complete_return_atomic` and `complete_order_delivery_atomic`.

**Important:** This snapshot supersedes older Production snapshots in historical reports. It is not automatically renewed by reading a report; it must be refreshed by a direct Production query.

---

# CURRENT DEPLOYMENTS

Key Production Edge/runtime facts verified during the current investigation:

| Edge Function | Current observed state |
|---|---|
| `create-stock-voucher` | ACTIVE, version 8 |
| `send-stock-voucher` | ACTIVE, version 19 |
| `receive-stock-voucher` | ACTIVE, version 21 |
| `receive-purchase` | ACTIVE, version 9 |
| `save-sales-invoice` | ACTIVE, version 14 |
| `complete-return` | ACTIVE, version 23 |
| `complete-order-delivery` | ACTIVE, version 11 |
| `bulk-stock-adjustment` | ACTIVE, version 5 |

Historical/canary endpoints returning HTTP 410 in recent Production logs include dated verification/canary routes such as:

- `complete-picking-picker-http-gate-20260818`
- `owner-recovery-20260818`
- `cp-prod-fixture-canary-20260814`
- `cp-prod-auth-canary-20260814`
- `auth-login-verification-20260818`

A 410 response is treated as runtime evidence of retirement for that dated endpoint, not as proof that every similarly named function is retired.

---

# CURRENT MAIN.HTML STATUS

- **Runtime file:** `Current/PWA/main.html`
- **Current Git blob SHA observed:** `e81ae6fe3e0e473b98927ff5cb2d54ba6ef18d8d`
- **Observed size:** `692676` bytes
- **Current status:** `EXISTING / NOT DECLARED FINAL`
- **Final reconstruction status:** `OPEN`
- **Production runtime parity:** `NOT YET ESTABLISHED`
- **Full clean-room rewrite:** `NOT YET EXECUTED`

Current `Current/PWA/main` directory evidence shows these present files:

- `main.html`
- `picker.html`
- `van-sales.html`
- `vouchers.html`

The historical `MASTER EXECUTION PROMPT` describes `Current/PWA/main/main.1.txt` through `main.11.txt` as physical source parts. The current HEAD does **not** provide direct evidence that those physical files currently exist in `Current/PWA/main`. A repository search for `main.1.txt` did not establish a current source file; therefore those historical parts MUST NOT be treated as current physical inputs without renewed evidence.

---

# ORIGINAL SOURCE STATUS

- Historical Original/Current sources exist in the repository and remain useful for **functional contract reconstruction**.
- Original source is **not current runtime truth**.
- Current Production and current Git outrank Original when establishing what exists now.
- No historical Original file is authorized to overwrite current functionality merely because it looks more complete.
- Original functionality may be restored only after consumer/contract comparison establishes that the functionality is still required or was unintentionally lost.

---

# VALIDATED CHANGESET STATUS

### Directly validated in the latest investigation

- Production currently has centralized stock engine capability via `post_stock_movement`.
- `reserve_stock` / `release_stock_reservation` are separate reservation functions.
- Current manual voucher posting (`post_manual_stock_voucher_atomic`) routes Physical Stock Movement through `post_stock_movement`.
- Current send voucher canonical path routes Physical Stock Movement through `post_stock_movement`.
- `stock_vouchers` audit trigger exists and routes to `fn_audit_trigger()`.
- `order_details` has an AFTER trigger `trg_sync_run_sheet_details` calling `sync_run_sheet_details()`.
- The new clean-room reconstruction command was committed to `main` at HEAD `854613bda759f50e8d7b7418d35d01fe4046364c`.

### Not validated as final

- Global application parity of `Current/PWA/main.html` against all required historical/current functionality.
- Full parity between reconstructed main HTML and current Production runtime.
- Final retirement of every legacy/parallel application path.
- Complete Production runtime verification of all main.html business flows.

### Important caution

Historical reports contain claims of `fixed`, `verified`, `closed`, `Gold`, `Diamond`, or similar. Those claims remain historical until re-proven against current Git and current Production.

---

# KNOWN ACTIVE CONTRACTS

## Application / governance

- `CURRENT_STATE.md` is the single operational entry point for future assistants.
- `LAST VERIFIED EVENT` is the only valid operational recency marker. Do not use `LAST REPORT`.
- Historical reports are evidence of what was attempted or observed then, not proof of current state.

## Identity / tenant

- Authenticated user context must resolve through the current authenticated identity into the applicable company context.
- Company-scoped operational data must be company-scoped.
- `app_settings LIMIT 1` is forbidden where company identity matters.

## Owner semantics

The historical governance contract requires re-verification, not simplification:

`OWNER = isOwner=true + permissions=["*"] + owner_profile + active license state`

Do not replace wildcard semantics with an arbitrary explicit permission list without proof that every dependent guard and contract remains equivalent.

## Inventory core

`PHYSICAL STOCK MOVEMENT → post_stock_movement → stock_branches + inventory_log`

`reserve_stock / release_stock_reservation` are reservation capabilities, not alternative Physical Stock engines.

## Data source-of-truth

- `order_details` is the operational fulfillment detail when that contract is applicable.
- `run_sheet_details` is derived/synchronized data where the existing trigger contract applies.
- Do not introduce an undocumented dual-write source of truth.

## Audit

- Audit trigger on `stock_vouchers` uses `fn_audit_trigger()`.
- Audit actor resolution must preserve the current authentication semantics; absence of JWT claims falls back to `system` in the current function.

---

# KNOWN RETIRED CONTRACTS

The following are retired/expired **dated runtime probes or verification endpoints**, evidenced by current Production HTTP 410 responses:

- `complete-picking-picker-http-gate-20260818`
- `owner-recovery-20260818`
- `cp-prod-fixture-canary-20260814`
- `cp-prod-auth-canary-20260814`
- `auth-login-verification-20260818`

**Retirement rule:** Do not generalize from the retirement of a dated probe to retirement of the underlying business capability without direct evidence.

Historical reconstruction files/reports are also retired as **operational entry points**. They remain historical evidence only.

---

# OPEN BLOCKERS

1. **FINAL MAIN.HTML RECONSTRUCTION IS OPEN.** `Current/PWA/main.html` has not yet been declared final by clean-room reconstruction plus parity plus Production runtime verification.
2. **SOURCE-MATERIAL DRIFT.** Historical prompts reference physical `main.1..main.11` files, while the current repository does not directly establish those files as current inputs. This must not be resolved by assumption.
3. **CURRENT APPLICATION CONTRACT INVENTORY IS NOT YET FROZEN.** The final reconstruction must establish the required current contracts from live consumers, current core companions, current Git, and Production before generating the new file.
4. **PRODUCTION RUNTIME PARITY IS NOT PROVEN.** A successful static build or browser load alone cannot close this blocker.
5. **LEGACY EDGE / RPC SURFACE REQUIRES FINAL CLASSIFICATION.** Presence in Production is not by itself proof of active business use or retirement.

---

# FORBIDDEN ACTIONS

- Do not begin from historical report 1–117.
- Do not treat any report's completion percentage as current truth.
- Do not treat `LAST REPORT` as a state marker.
- Do not declare `main.html` final without current Production verification.
- Do not rewrite functionality by copying Original blindly.
- Do not infer missing files, missing APIs, or missing business rules from memory.
- Do not delete or retire a function because it looks obsolete without consumer/runtime evidence.
- Do not change OWNER semantics.
- Do not use company-unscoped `LIMIT 1` lookups where company identity matters.
- Do not create a second Physical Stock engine inside the PWA.
- Do not write `stock_branches.qty` directly from `main.html`.
- Do not write `inventory_log` directly from `main.html`.
- Do not change RPC/API/database contracts unless the change is explicitly proven necessary and all consumers are reconciled.
- Do not claim Production PASS from staging/static validation.
- Do not use a failed or missing historical lookup as permission to invent a replacement.

---

# LAST VERIFIED EVENT

> This section intentionally uses **EVENT**, not REPORT.

- **Event ID:** `LVE-2026-08-31-002`
- **Event type:** `GIT_GOVERNANCE_ARTIFACT_COMMITTED`
- **UTC:** `2026-08-31` (commit event; repository timestamp is the authoritative commit metadata)
- **Source:** GitHub repository `papamohammed77-glitch/rawaie-erp-New`
- **Git SHA:** `854613bda759f50e8d7b7418d35d01fe4046364c`
- **Action:** Added `FINAL_MAIN_HTML_RECONSTRUCTION_COMMAND.md` as the sole authorized clean-room main.html execution command.
- **Result:** `VERIFIED`
- **Evidence:** Direct GitHub commit verification; file committed on current `main`.
- **Impact:** Future main.html work now has a single operational state entry point plus a single execution contract instead of reopening the historical prompt/report chain.
- **Production state:** Unchanged by this Git-only event; latest verified Production snapshot remains `2026-08-31T04:53:38.97289+00:00` and must be refreshed before any Production-changing action.
- **Next authorized action:** Start `FINAL_MAIN_HTML_RECONSTRUCTION_COMMAND.md`; it MUST begin by reconciling Git + Production again and updating this file before any main.html rewrite.

---

# NEXT AUTHORIZED ACTION

**ONLY:** Execute `FINAL_MAIN_HTML_RECONSTRUCTION_COMMAND.md`.

No historical reconstruction loop may be reopened unless that command's evidence gate identifies a specific unresolved contract that requires historical evidence.

The command must:

1. Start from this file.
2. Re-verify current Git + Production.
3. Build a current contract/evidence set without rewriting history.
4. Reconstruct `Current/PWA/main.html` from scratch only from validated evidence.
5. Prove structural, functional, and change parity.
6. Prove Production runtime compatibility.
7. Update this `CURRENT_STATE.md` after every real state-changing execution.
8. Declare closure only when the evidence gates are satisfied.

---

# CURRENT CLOSURE STATUS

`MAIN.HTML FINAL CLEAN-ROOM RECONSTRUCTION = OPEN`

`PRODUCTION PARITY = OPEN`

`PRODUCTION RUNTIME VERIFICATION = OPEN`

`GLOBAL HISTORICAL RECONSTRUCTION LOOP = CLOSED / DO NOT REOPEN`

`NEXT ACTION = FINAL_MAIN_HTML_RECONSTRUCTION_COMMAND.md`
