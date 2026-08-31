# RAWAEA ERP — HYTHAM NEW-MAIN CLEAN-ROOM VERIFICATION

Date: 2026-08-31
Role: Hytham
Authority: Production SMART ERP > current Git main > current application files > historical evidence

## Scope
This evidence records execution of `FINAL_MAIN_HTML_RECONSTRUCTION_COMMAND.md` against the explicitly required target:

`Current/PWA/New-main`

The existing `Current/PWA/main.html` was not a write target and was not modified by the reconstruction commit.

## Memory / Continuity
- `doc/Draft/medhat/تقرير +برومبت 117-02` was read.
- `CURRENT_STATE.md` was read before reconstruction.
- `FINAL_MAIN_HTML_RECONSTRUCTION_COMMAND.md` was read through its closure rules.
- Historical reports were treated as context only, not as current runtime proof.

## Current Production Facts Used
- SMART ERP Production project: `fiilmooggumokxanwiyx`.
- One active company is currently the operational tenant baseline.
- Current Production contracts used by the artifact were rechecked directly: `users.auth_id` -> `users.company_id`, Physical Stock owned by `post_stock_movement`, reservations owned by `reserve_stock` / `release_stock_reservation`, financial writes delegated to canonical Edge/Core paths.

## Clean-room Candidate
Target:
`Current/PWA/New-main`

Final blob SHA:
`2f252390b56cc408a8db62523edf303f3e24a3ad`

Final reconstruction commit:
`7b913fb48374e390a0fc1bb5edc640b95fefe1d7`

## Candidate Design
- Supabase Auth sign-in/session bootstrap is present.
- Tenant identity is resolved from `public.users.auth_id` and `users.company_id`.
- Owner/license state is exposed without replacing the current wildcard semantics with a guessed permission model.
- Operational read models are company-scoped.
- Specialized business modules are delegated to existing functional PWAs instead of duplicating their business engines.
- New-main contains no direct Physical Stock or financial table DML.
- Service Worker registration targets the shared PWA root using `../sw.js` from the nested `New-main` path.
- Required reconstruction globals are present: `RW_ShellContext`, `RW_OwnerLicense`, `RW_Views`, `RW_Dashboard`, `RW_Items`, `RW_POS`, `RW_Orders`, `RW_Runsheets`, `RW_Purchases`, `RW_Warehouse`, `RW_Finance`, `RW_Reports`, `RW_HR`, `RW_CRM`.

## Self-Audit
The previous New-main candidate did not satisfy the reconstruction gate contract because required reconstruction globals were absent and its Service Worker path was wrong for a nested target. The new artifact corrects those defects.

## Static Checks Performed From Persisted Source
- HTML document opens with `<!doctype html>` and closes correctly.
- Required shell identifiers are present.
- Required reconstruction globals are present.
- `user_metadata.company_id` is not used as tenant authority.
- No hard-coded financial account UUID exists.
- No direct stock mutation calls are present.
- No direct financial DML calls are present.
- Company-scoped `app_settings` access is used.
- Only `Current/PWA/New-main` was written by the reconstruction commit.

## Evidence Boundary
The current artifact is a concrete Git reconstruction and its static contract boundary is verified by source inspection.

Not claimed because the corresponding runtime evidence has not yet been produced:
- Browser smoke PASS.
- Service Worker runtime PASS.
- Authenticated Production HTTP E2E PASS.
- Full feature parity PASS against every historical/current Main contract.
- Full logical-fragment parity PASS against all `main1..main11` contracts.
- Production runtime certification of New-main as the deployed application.
- Authorization to replace `Current/PWA/main.html`.

## Current Closure
`NEW-MAIN ARTIFACT = VERIFIED`
`STATIC CONTRACT = VERIFIED`
`PRODUCTION COMPATIBILITY BY CONTRACT = VERIFIED`
`STRUCTURAL PARITY = OPEN`
`FUNCTIONAL PARITY = OPEN`
`RUNTIME = OPEN`
`REPLACEMENT OF main.html = NOT AUTHORIZED`
