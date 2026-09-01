# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Operational truth: current Git main HEAD, Production Supabase, deployed Edge Functions, and runtime verification.
- Historical reports/prompts are evidence only.
- Authorized product target: `Current/PWA/New-main`.
- `Current/PWA/main.html` is protected.
- Prompt 124+ / master governance requires direct evidence, explicit state logging, preservation of historical reports, and no false closure.
- Historical Hany reports are preserved and must not be deleted or overwritten.
- Gold/Diamond is never inferred from workflow success alone; runtime/product evidence is required.

## P131 — FORENSIC CONTINUATION — 2026-09-01
### P131-06 — TARGET_MUTATION_EXECUTED
- Product mutation commit: `bdb74d365839c87e61fe4f1df5c4f4f940c76a41`.
- Target blob after mutation: `765e812efa17662d8630c50fa3ecd3f8ed496bf3`.
- Specialized report navigation routes were corrected and persisted.
- Node syntax verification passed in the target-mutating Job.
- `Current/PWA/main.html` and Supabase production were not mutated.

### P131-14 — GOLD_DIAMOND_STATUS
- Specialized report navigation defect is closed at static source level.
- Gold/Diamond remained UNPROVEN because browser/runtime verification was not completed.

## P132 — MEMORY RECOVERY + FORENSIC RECONCILIATION — 2026-09-01
### P132-01 — STATE_RECONCILIATION
- `CURRENT_STATE.md` was read before any new action.
- Entry `main` HEAD was `c0fc7907c7c59194285bc4051f032c9ee6b0d8e3`.
- No change to `Current/PWA/New-main` occurred after the P131 target mutation.
- Later governance/report commits did not mutate the product target.

### P132-02 — MASTER_AND_MEMORY_RECOVERY
- `MASTER - RAWAEA ERP.md` was read from beginning through its execution/governance rules.
- Governing constraints reconfirmed: current truth outranks reports/memory; unknowns are not bugs; no artificial workflow/executor/reconstruction; target must be proven before patch; production/runtime evidence is mandatory for closure; `CURRENT_STATE.md` must be updated after real events.
- The requested `doc/Draft/medhat/برومبت 124+ ملحق تقرير` path returned `404 Not Found`; no content was fabricated.

### P132-03 — HANY_LATEST_REPORT_RECONCILIATION
- `doc/Draft/Hany/تقرير تنفيذي 13.md` was the latest numbered Hany report at that point.
- Browser/runtime and Gold/Diamond remained unproven.

### P132-04 — TARGET_RECHECK
- `Current/PWA/New-main` was fetched directly from current `main`.
- Target remained the P131-repaired artifact; no new target patch was authorized by P132 itself.

### P132-05 — PRODUCTION_RECHECK
- Production Supabase project `fiilmooggumokxanwiyx` was read directly.
- Observed baseline: `users=24`, `companies=1`, `owner_profile=1`, `app_settings=1`, `notifications=0`.
- No Supabase mutation was executed.

### P132-06 — DEPLOYMENT_RUNTIME_STATUS
- Cloudflare Pages deployment lineage and exact production application artifact were still UNPROVEN.
- Browser/runtime certification of New-main remained UNPROVEN.
- Gold/Diamond remained UNPROVEN.

## P133 — RUNTIME DEFECT FORENSIC + REPAIR PREPARATION — 2026-09-01
### P133-01 — MEMORY_AND_LATEST_HISTORY_RECONCILIATION
- `MASTER - RAWAEA ERP.md` was re-read completely before product modification.
- Current `CURRENT_STATE.md` was read before acting.
- Hany directory was inspected directly; numbered reports 1–13 exist, with `تقرير تنفيذي 13.md` the latest numbered report.
- A later Git commit exists for `doc/Draft/Hany/تقرير تنفيذي 6` (`ad4072fe24ae106ebfcd340038a9ccb117a977a4`), proving report chronology is not reliably represented by filename number alone; reports are preserved as historical evidence.
- Prompt 124 exact requested path remains unavailable as a current Git blob and was not fabricated.

### P133-02 — DIRECT_RUNTIME_DEFECT_FORENSICS
- User-provided production browser evidence reports HTTP 401 `AuthApiError: Invalid API key` from Supabase Auth and a Service Worker 404 at `/companies/sw.js`.
- Direct target inspection of `Current/PWA/New-main` found a current Supabase URL for project `fiilmooggumokxanwiyx`.
- Direct target inspection also found two assignments to `RW_SUPABASE_ANON_KEY`: an obsolete malformed placeholder followed by a hard-coded legacy anon key.
- The hard-coded key in target does not exactly match the currently published Supabase legacy anon key returned by the Production project connector.
- Direct target inspection found the boot check `if (!window.supabase || !window.supabase.auth)` and subsequent use of `window.supabase.auth.getSession()` even though the created client is stored in the local variable `supabase`; this is a real object-reference defect and is consistent with `MAIN11_SUPABASE_UNAVAILABLE`.
- Direct target inspection found Service Worker registration as `navigator.serviceWorker.register('../sw.js',{scope:'../'})`, which resolves differently from the user-observed `/companies/sw.js`. The target repository contains the canonical `Current/PWA/sw.js`. This discrepancy is evidence that the deployed artifact/lineage may differ from the current target, and must not be ignored.

### P133-03 — SUPABASE_CREDENTIAL_RECONCILIATION
- Production project `SMART ERP`, ref `fiilmooggumokxanwiyx`, is directly reachable and healthy.
- Current published keys were retrieved directly from Supabase; the current legacy anon key was compared to the target hard-coded key.
- Credential defect is therefore source-proven, not an assumption.
- No Supabase data, schema, auth configuration, or Edge Function was mutated in P133-03.

### P133-04 — AUTHORIZED_NEXT_OPERATION
- Perform one surgical mutation in `Current/PWA/New-main` only:
  1. remove the obsolete malformed placeholder assignment;
  2. replace the hard-coded legacy anon key with the current published legacy anon key exactly;
  3. change boot/session calls from `window.supabase.auth` to the created client `supabase.auth`.
- Then verify the target artifact, commit identity, and runtime/deployment lineage before any further product changes.
- Service Worker 404 will be handled as a separate evidence-gated defect after the authentication path is repaired; do not change `Current/PWA/sw.js` merely because the deployed URL disagrees with the current target registration path.

## CURRENT SURVIVING STATE AFTER P133 PREPARATION
- Last known product mutation before this round: `bdb74d365839c87e61fe4f1df5c4f4f940c76a41`.
- Last previously verified target blob: `765e812efa17662d8630c50fa3ecd3f8ed496bf3`.
- `Current/PWA/main.html`: protected / untouched.
- Production Supabase: healthy and read-only reconciled; no P133-03 mutation.
- Current runtime defect: invalid target Supabase credential + incorrect client object check are proven at source level; deployed artifact identity remains a separate open question.
- Service Worker deployment path mismatch remains open.
- Browser/runtime post-fix: UNVERIFIED.
- Gold: UNPROVEN.
- Diamond: UNPROVEN.
- Closed 100%: NO.

## NEXT AUTHORIZED ACTION
- Execute the single surgical target mutation defined by P133-04.
- Verify exact persisted source, then establish whether the deployed `/companies/` artifact is the same target before declaring runtime closure.
- Preserve every historical Hany report; do not delete or overwrite.
