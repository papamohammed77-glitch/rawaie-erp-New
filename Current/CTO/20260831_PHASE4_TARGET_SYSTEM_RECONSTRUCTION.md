# RAWAEA ERP — PHASE 4 TARGET SYSTEM RECONSTRUCTION

**Date:** 2026-08-31  
**Phase:** 4 — Target System Reconstruction  
**Status:** CLOSED  
**Production mutation:** None.

## TARGETS IDENTIFIED

### Production application currently present
`Current/PWA/main.html`

The current tracked production-oriented shell is a mature full ERP UI with its own visual system, responsive layout, authentication UI, and legacy/full-feature implementation. Its current Git blob SHA observed during this investigation is `34b1bd23f99ac08a797625ab2fd359b21bf140b4`.

### Candidate reconstruction target
`Current/PWA/New-main`

The repository contains a clean-room reconstructed ERP shell that explicitly identifies itself as `New-main — clean-room current ERP shell`. It uses the current Production Supabase project ref in its client configuration and establishes an authenticated company context from `public.users.auth_id` before loading company-scoped state.

### Replacement prohibition
The candidate is **not** treated as a replacement for `Current/PWA/main.html` at this phase. This is corroborated by the open Golden New-main verification PR, whose stated purpose is verification and whose body explicitly says no `main.html` replacement. The PR is open, unmerged, and currently non-mergeable. fileciteturn55file0L2-L15

## TARGET SYSTEM CONTRACT

The candidate target is not merely a visual rewrite. Its inspected source establishes explicit shell-level contracts for:

- authentication/session handling;
- authenticated user → `public.users.auth_id` resolution;
- company/tenant context;
- owner semantics and permissions;
- license state;
- navigation;
- search;
- online/offline status;
- delegation to specialized sales, warehouse, delivery, purchasing, voucher, and accounting modules;
- read-model access for current-state information.

The candidate source also includes a machine-readable `MAIN_HTML_CURRENT_CONTRACT_LEDGER` describing these shell responsibilities and marking several domains as delegated to specialized applications rather than duplicated inside the main shell.

## CANDIDATE vs CURRENT MAIN

| Dimension | Current `main.html` | New-main candidate | Decision |
|---|---|---|---|
| Role | Existing current application | Reconstruction candidate | Keep both until gates close |
| Production replacement | Existing tracked artifact | Not authorized | Do not replace |
| Auth | Present | Present with explicit auth/company-context resolver | Candidate behavior requires runtime proof |
| Company context | Present in mature app | Explicit `users.auth_id` → `company_id` contract | Candidate contract identified |
| UI system | Full legacy/mature UI | New clean-room shell styling | Visual parity not assumed |
| Specialized modules | Existing integration | Explicit delegation ledger | Needs consumer/runtime verification |
| Stock mutation | Application integrations exist | Shell does not become stock writer | Confirmed architectural direction |
| Accounting mutation | Application integrations exist | Shell is read/delegation oriented | Confirmed architectural direction |
| Deployment status | Current tracked artifact | Candidate verification branch/PR | Candidate not certified |

## TARGET SYSTEM NON-NEGOTIABLES

1. `main.html` remains untouched until the protocol's parity, runtime, deployment-lineage, and replacement gates are independently proven.
2. `New-main` cannot be certified from static source alone.
3. Historical/original source fragments are evidence for reconstruction, not permission to overwrite the current application.
4. No business-data migration is part of the target-system reconstruction phase.
5. Production financial or stock behavior must remain behind the established canonical writers and specialized operational functions.

## CURRENT EVIDENCE ALIGNMENT

Current Production code and database definitions already show the target architecture moving toward clear boundaries:

- stock movement through `post_stock_movement`;
- loading orchestration through `complete_runsheet_loading`;
- sales transaction orchestration through `save_sales_invoice_atomic`;
- purchase receiving through `receive_purchase_atomic`;
- voucher sending through `send_stock_voucher_atomic`.

Therefore the candidate shell should be evaluated against these Production contracts rather than against an older monolithic-page assumption.

## UNPROVEN TARGET GATES

The following remain open and are intentionally not marked PASS:

- exact functional parity against the intended canonical historical/current contract;
- all UI event handlers and module routes;
- browser-level authentication/session behavior;
- offline/service-worker behavior where claimed;
- active consumer attribution for every delegated module;
- exact Git-to-Cloudflare deployment lineage;
- production deployment equivalence;
- regression safety under real authenticated workflows.

## EXIT GATE

`PHASE 4 CLOSED`

The system target has been identified and separated into: current application, reconstruction candidate, historical source, and deployment verification target. The candidate is explicitly kept behind verification gates and no replacement action is authorized by this phase.
