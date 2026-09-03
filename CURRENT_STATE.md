# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Current truth must be reconstructed from direct Git, direct Production/database evidence, active deployments/runtime evidence when available, and verified artifacts.
- Historical reports are evidence of what was done; they are not current truth by themselves.
- `Current/PWA/New-main` is the authorized target for the current PWA reconstruction track.
- `Current/PWA/main.html` is a separate artifact and must not be substituted for `New-main` by filename similarity.
- Historical reports are sacred and are never deleted to simplify continuity.
- `UNKNOWN ≠ BUG`, `UNKNOWN ≠ REMOVE`.
- `Git/source verified ≠ runtime verified`.
- Governing loop: CURRENT_STATE → LAST VERIFIED EVENT → CURRENT GIT → CURRENT PRODUCTION → DEPLOYMENTS/RUNTIME → CURRENT FILES → RECONCILE → SURGICAL CHANGE → VERIFY → CURRENT_STATE.

## CTO EXECUTION — 2026-09-03
Current execution target remains `Current/PWA/New-main`.
Source fragments: `Current/PWA/main/main1.md` through `main11.md`.
No Production database writes are authorized by this execution.
`Original/PWA/main/*` remains evidence-only and unmodified.

## CTO EXECUTOR DIAGNOSTICS — 2026-09-03
- `P163_COMPAT_COUNT:0`: obsolete requirement; current source is already de-duplicated.
- `P163_ITEMS_OWNER_COUNT:0`: solved by normalizing the actual `window.RW_Items = RW_Items;` owner export.
- `MAIN1_INLINE_SCRIPT_MISSING`: solved after direct source inspection proved main1 keeps the application runtime open through EOF.
- `P163_GOLD_GATE_FAIL` on `dashboard_export_one`: solved after direct main2 inspection proved Dashboard is a local owner in the shared runtime rather than a window export.
- Current assembler validates ownership and capability contracts against the present eleven-part source.

## CURRENT RETRIGGER
A new non-workflow push is deliberately issued now to execute the corrected temporary Gold/Diamond target executor. No success is to be recorded until the target file changes and all source/browser gates pass.

## EXECUTION EVENT
Trigger commit created after the executor definition was corrected: `edb549009f39cfaf48fe4d79f45ef101118ad662`.

## P165/P166 CONTINUITY REVALIDATION — 2026-09-03
- Direct Git revalidation confirms the target remains `Current/PWA/New-main` and the file has not yet been changed by the closure executor.
- The temporary executor `.github/workflows/_cto_close_newmain_20260903.yml` is intentionally push-triggered and performs the exact P163 ownership surgery, Node syntax verification, browser smoke, then persists the target and cleans itself up.
- Trigger execution remains the authorized next action; no closure claim is valid before target mutation and Gold/Diamond verification.
- Production remains read-only for this track.

## LIVE CTO EXECUTION — 2026-09-03
- Triggering the corrected existing closure executor from a non-closure commit.
- Target must be changed and verified before any closure status is written.

## CTO LIVE TRIGGER
The corrected existing closure executor is armed on `main`; this state-only commit exists solely to trigger the verified server-side reconstruction path.

## CTO FINAL MERGE TRIGGER
This commit exists solely to make a real GitHub merge event from a clean branch so the existing push-triggered CTO executor is invoked. No product claim is recorded here.
