# Report568 — RAWAEA ERP Daily CTO Review
## Parent Realtime channels, authorized refresh APIs, and permission-contract reconciliation
**Date:** 2026-10-31  
**Inspection time:** approximately 21:39 Africa/Cairo  
**Production project:** SMART ERP — `fiilmooggumokxanwiyx`  
**Operational source:** `papamohammed77-glitch/erp-frontend` / `main`  
**Governance repository:** `papamohammed77-glitch/rawaie-erp-New` / `main`

---

## 1. Starting point — CURRENT_STATE first

The canonical governance repository was read first and in full. Its opening checkpoint was **LVE-2026-10-31-567B**, committed at 2026-10-31 16:03:06Z, and it recorded operational source HEAD `8140235b7460401f10abe117ce9358c88c38114a`.

The operational source repository contains a second `CURRENT_STATE.md`. Its complete 472-line handoff was then read. Its current top checkpoint is **Phase 3 — resolve remaining parent Realtime channel incompatibilities and complete freshness classification**, updated by commit `1f190a46d55929a3155ddb225dbb5bc15f40faf2` at 17:20:22Z. It points to:
- `REALTIME_SYNC_EXECUTION_20261031.md`, including section 8;
- `REALTIME_SYNC_PHASE2_PARENT_BOOTSTRAP_20261031.md`;
- `REALTIME_SYNC_PHASE3_INVENTORY_COUNTS_20261031.md`.

The full master governance/continuity protocol and the current Phase 2/Phase 3 execution reports were read before investigation.

**The operational source handoff is newer than the canonical governance checkpoint.** Live Git is newer again: operational `main` is now `65799d282acc79359b17a1a13dcd68f62859e1fb` (2026-10-31 17:23:29Z), 26 commits beyond the SHA recorded in the canonical LVE-567B checkpoint. The last four commits after the operational handoff add deployed Edge Function source snapshots; they do not change Parent `main.html`.

### Today's target
Continue the current Phase 3 objective: determine how the four Parent modules refresh through authenticated server-side read paths without weakening RLS or exposing service-role-only tables. Do not restart the earlier inventory-count remediation or claim all-app Realtime completion.

---

## 2. CONFIRMED

### 2.1 Live GitHub/source state

- Operational repository: `papamohammed77-glitch/erp-frontend`, branch `main`.
- Current HEAD: `65799d282acc79359b17a1a13dcd68f62859e1fb`.
- Parent `companies/company-1/main.html`: blob `53b5a9e9d0433a785c3d5471a9c0d68c25497882`, 33,358 lines.
- Shared `companies/company-1/core.js`: blob `a95ee6b29ff54b4a240ce4b81f9a535aa87686db`, 1,002 lines.
- Current operational handoff blob: `2f7b391c556a0118d418d0d1d4eb83c0e81ebf25`.
- Current canonical governance state blob at start: `c0039234b93d009de67d26123a607472c4921b73`.

Parent source scan found **11 direct `.channel(` call sites**, not the 8 recorded in the operational handoff. The four channels in the active Phase 3 scope are:

| Parent module | Source location | Direct tables subscribed |
|---|---:|---|
| Sales Decision | `main.html:3488–3492` | `sales_decision_policies`, `sales_decision_evaluations`, `sales_decision_approvals` |
| Loyalty | `main.html:4406–4409` | `loyalty_programs`, `loyalty_rewards`, `loyalty_accounts`, `loyalty_transactions` |
| Customer Payments | `main.html:20362–20388` | `sales_payment_receipts`, `sales_payment_allocations` |
| Commission | `main.html:21400–21405` | `commission_plans`, `commission_assignments`, `commission_runs`, `commission_run_lines` |

The Parent file contains no `core.js` script reference, no `RW_Realtime`, and no call to `get_my_effective_profile`. It has no `focus` listener or `visibilitychange` handler. The four modules therefore have no verified focus/visibility fallback when their channel cannot deliver events. Existing timers in other Parent modules do not establish refresh for these four modules.

### 2.2 Production Realtime publication and RLS

Read-only catalog queries against SMART ERP confirmed:

- `supabase_realtime` contains 81 tables.
- Sales Decision tables are **not** members of the publication. Their policies for `anon` and `authenticated` explicitly use `USING (false)` and `WITH CHECK (false)`.
- Loyalty tables are **not** members of the publication. Their policies for `anon` and `authenticated` explicitly use `USING (false)` and `WITH CHECK (false)`.
- Customer Payment tables are members of the publication, but their only table policies are `service_role`-only.
- Commission tables are members of the publication, but their only table policies are `service_role`-only.

Therefore the four browser subscriptions are incompatible with the current Production authorization/publication contract. This does **not** prove the exact browser channel status or event-delivery symptom; those require runtime observation. It does prove that the authenticated Parent client has no authorized row visibility for these four sets of tables. No RLS or publication change is justified.

### 2.3 Existing authenticated server-side read paths

The Parent modules already use Edge Function APIs for their initial data and business operations:

| Module | Existing server-side path | Production status |
|---|---|---|
| Sales Decision | `sales-decision-center` — `GET_POLICY`, `GET_PENDING_APPROVALS`, `VALIDATE_ORDER`, write operations | ACTIVE v1, `verify_jwt=true` |
| Loyalty | `loyalty-engine` — `LIST_PROGRAMS`, `LIST_REWARDS`, `GET_ACCOUNT`, `LIST_TRANSACTIONS`, write operations | ACTIVE v1, `verify_jwt=true` |
| Customer Payments | `sales-payment-allocation` — `catalog`, `open_orders`, `list`, `detail`, `create` | ACTIVE v2, `verify_jwt=true` |
| Commission | `commission-engine` — `LIST_REPS`, `LIST_PLANS`, `LIST_RUNS`, and commission operations | ACTIVE v3, `verify_jwt=true` |

The three Edge Function sources present in the operational Git repository match the corresponding Production `index.ts` source exactly:
- `supabase/functions/sales-decision-center/index.ts` — blob `95dfc768b956d1b58990942cc5031d7359c6f4bf`;
- `supabase/functions/loyalty-engine/index.ts` — blob `076b6f4b9618dfc66f15e8b92051040eeedddfb5`;
- `supabase/functions/sales-payment-allocation/index.ts` — blob `1c6dd356284079e346196b37b1f9813154c535c8`.

**Commission provenance gap:** Production `commission-engine` v3 is ACTIVE with hash `5172830aa0de5bf51ee4b010d6503de675071fca0fc29001e5b6aaab430a3555`, but `supabase/functions` in the operational repository has no `commission-engine` directory. GitHub code search in both the operational and governance repositories found no source snapshot. The active Production function can be inspected, but it is not reproducibly version-controlled in the operational source repository.

### 2.4 Permission-contract mismatch discovered

Production `get_my_effective_profile()` returns the union of:
1. `users.permissions`;
2. `roles.permissions`;
3. `role_permissions.permission_key`.

The operational shared `core.js` calls `supabase.rpc('get_my_effective_profile')` and normalizes the returned effective permissions.

Parent `main.html` does not use that contract:
- Login path (`1268–1298`) reads only `users.permissions`.
- Session-restore path (`33235–33250`) assigns `user_metadata.permissions || ['*']`; it does not re-read the effective profile or the database permissions before building the application state.

The four server-side paths are also inconsistent with the effective-profile resolver:
- `sales-decision-center` checks only `users.permissions`; Production `sales_decision_actor_ok` also checks only `users.permissions`.
- `loyalty_engine_atomic` checks only `actor.permissions` from the direct user row.
- `sales-payment-allocation` combines direct user permissions and `roles.permissions`, but omits `role_permissions`.
- Production `commission-engine` does the same: direct user permissions plus `roles.permissions`, but no `role_permissions`.
- The payment and commission atomic RPCs are executable by `service_role`, not by `authenticated`; their Edge Function authorization is therefore the effective access gate.

Read-only Production aggregation found 21 `role_permissions` rows across 3 roles. At least one active auth-linked user relies on `role_permissions` alone for each of these permission keys: `finance`, `orders`, `pos`, `purchases`, and `warehouse`. No identity data was emitted.

This proves a real permission-contract mismatch: the effective-profile resolver can grant a permission that Parent and some Edge/RPC checks do not recognize. The actual experience of the affected account was not tested. Do not compensate by broadening RLS or granting direct table access.

### 2.5 Inventory-count Phase 3 subtask recheck

The previously completed tenant-boundary change remains present in Production:
- migration `20261031171715` is applied;
- `inventory_counts_select_company_authorized` is the scoped read policy;
- anon direct SELECT/INSERT are false;
- authenticated SELECT is true while direct INSERT/UPDATE/DELETE are false;
- service_role write privileges remain;
- `inventory_counts` currently has zero rows.

Current source `warehouse/counter.html` blob `32d0dc8ca0edb7cc68660f0fbd6246408117498d` contains the corrected null general-count entity payload. Production `save-inventory-count` v5 source matches the Git source exactly. There are currently zero active auth-linked users with `active_warehouse_role='جرد'`, so Counter E2E remains blocked. Production has active auth-linked users for one company only; two-company browser isolation cannot be proved here.

### 2.6 CI

Current HEAD `65799d2` has four successful workflow runs. None is a current authenticated Parent Realtime E2E. The earlier `Warehouse Vouchers Browser E2E` run `41217489614` on commit `8140235` failed; its workflow path filter is focused on `warehouse/vouchers.html`, `core.js`, and `sw.js`, not the four Parent modules. It was not rerun on current HEAD.

---

## 3. UNKNOWN

- Exact browser channel state and whether each invalid subscription reports `CHANNEL_ERROR`, `SUBSCRIBED` without row events, or another runtime symptom.
- Whether any authenticated user is currently viewing these four modules when an external write occurs.
- Whether the role_permissions-only user has attempted Finance/Loyalty operations through the Parent or another consumer.
- Full 30-page freshness classification; it remains open.
- Exact Cloudflare production URL, served artifact bytes, commit/build lineage, cache headers, and runtime behavior.

## 4. CONFLICT

1. **Two checkpoint files diverged:** canonical governance `CURRENT_STATE.md` still recorded LVE-567B and source HEAD `8140235`; operational `erp-frontend/CURRENT_STATE.md` recorded the later Phase 3 handoff at 17:20; live operational Git is `65799d2` at 17:23.
2. **Parent channel count:** operational handoff says 8 direct channels; live Parent blob has 11 `.channel(` call sites.
3. **Permission contract:** shared `core.js`/Production effective profile includes role_permissions; Parent and several Edge/RPC authorization paths do not.
4. **Migration/source provenance:** Production confirms migrations `20261031153418` and `20261031171715` are applied, but the current operational `supabase/migrations` directory contains neither corresponding migration file.

## 5. UNVERIFIED

- No deployed artifact was matched to Git HEAD.
- No authenticated browser E2E or live Realtime event-delivery test was performed.
- No two-company isolation test was performed.
- No role_permissions-only account was used for an authenticated Edge Function test.
- No business transaction or business-data effect was tested in this review.

## 6. Verification matrix

| Layer | Result | Evidence |
|---|---|---|
| GitHub/source | CONFIRMED | HEAD `65799d2`; Parent blob `53b5a9e`; Core blob `a95ee6b`; 11 channel call sites; three exact Edge source matches; Commission source absent |
| Supabase Production | CONFIRMED | Publication membership, RLS policies, RPC execute privileges, Edge versions, role_permissions aggregation, applied migrations |
| Deployed artifact | UNVERIFIED | Direct page fetch was inaccessible; no Cloudflare API connector available |
| Runtime/E2E | UNVERIFIED | No originating browser context; no authenticated channel/event test |
| Business-data effects | CONFIRMED: none in this run | Read-only SQL/catalog inspection only; no writes or fixtures |

## 7. Work performed and mutation ledger

Performed:
- Read canonical `CURRENT_STATE.md` completely before other project actions.
- Read the operational repository's complete `CURRENT_STATE.md`, the governing protocol, and the active Phase 2/Phase 3 reports.
- Re-fetched live operational and governance Git HEADs, compared the operational source against the recorded checkpoint, and re-opened the current Parent/Core/Edge source.
- Queried Production read-only for publication membership, RLS policies, RPC execute privileges, function definitions, migrations, active-user permission sources, and inventory-count state.
- Compared the three version-controlled Edge Function source files byte-for-byte with the active Production versions.
- Attempted to access the known Cloudflare Pages host paths; the web fetch was inaccessible.

Not performed:
- No operational HTML or Edge Function source was changed.
- No RLS, grants, publication, migration, RPC, Edge deployment, or business data was changed.
- No PR, workflow, executor, or parallel architecture was created.
- The operational repository's own `CURRENT_STATE.md` was not committed in this run because a write to the app-source `main` could trigger an uncontrolled Pages deployment; Cloudflare deployment controls were unavailable. The governance checkpoint is updated separately.

## 8. Root cause and next priority

The four channels are not a Realtime-publication problem to solve by opening tables. They are authenticated read-model consumers whose current direct subscriptions contradict the intended service-role-only RLS boundary.

**Next single priority:** reconcile the Parent and Edge Function authorization contract with `get_my_effective_profile` (including `role_permissions`), and version-control the active `commission-engine` v3 source. Only after that permission contract is proven should the owner apply a surgical Parent patch replacing the four invalid direct subscriptions with view-active, visibility/focus and bounded-interval refreshes through the existing authenticated Edge Function read APIs. Keep RLS and publication unchanged.

**Exit decision:** Phase 3 Parent channel compatibility remains OPEN. No fix or production readiness is claimed.
