# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Current truth must be reconstructed from direct Git, direct Production/database evidence, active deployments/runtime evidence when available, and verified artifacts.
- Historical reports are evidence of what was done; they are not current truth by themselves.
- `Current/PWA/New-main` is the authorized target for the current PWA reconstruction/closure track.
- `Current/PWA/main.html` is a separate artifact and must not be substituted for `New-main` by filename similarity.
- Historical reports are sacred and are never deleted to simplify continuity.
- `UNKNOWN ≠ BUG`, `UNKNOWN ≠ REMOVE`.
- `Git/source verified ≠ runtime verified`.
- Governing loop: CURRENT_STATE → LAST VERIFIED EVENT → CURRENT GIT → CURRENT PRODUCTION → DEPLOYMENTS/RUNTIME → CURRENT FILES → RECONCILE → SURGICAL CHANGE → VERIFY → CURRENT_STATE.

## LAST VERIFIED EVENT — 2026-09-03
- Current `main` HEAD at continuity recovery: `cd4e886460b19b238de17a51981a7c8e6c5178b2`.
- Current target `Current/PWA/New-main` remains at blob `fa7c0fcf78a3b217d781fe543b6e5a5ed7411c63` before the new surgical closure execution.
- Direct inspection confirmed `New-main` contains both `RAWAEA MAIN2 COMPATIBILITY` and `RAWAEA MAIN2 AUTHORITATIVE MODULE` ownership surfaces.
- Direct inspection also confirmed target-resident `RAWAEA 122 DIAMOND CONTRACT CLOSURE v1` after MAIN11; this unit is not present in `Current/PWA/main/main11.md` and must not be lost by fragment-only reconstruction.
- Supabase read-only verification confirmed the current owner record uses wildcard permissions `['*']` and `owner_profile.license_status = 'active'`. No Production writes were performed.

## EXECUTION ATTEMPT — TEMPORARY RECONSTRUCTION PATH
- Controlled branch: `cto-new-main-gold-20260903`.
- Pre-trigger archive branch: `archive/cto-new-main-gold-20260903-pretrigger`.
- Controlled PR: `#82` — `CTO closure: reconstruct and verify New-main Gold/Diamond`.
- Executor run: `CTO executor temporary 20260903`, run `33706645190`, job `100497076696`.
- Result: `FAIL` before target persistence.
- Exact error: `SyntaxError: Unexpected end of input` / `FINAL_JS_SYNTAX_FAIL:new-main-final` in the reconstruction-generated runtime around line 6048.
- Direct closure probes showed that adding one `})();` made the syntax probe pass, but this was not accepted as a blind architectural fix.
- Conclusion: fragment-only reconstruction is currently unsafe for persistence until its closure contract is proven and all target-resident contracts are preserved.

## CURRENT CORRECTIVE STRATEGY
- Do not use `tools/run_final_main_reconstruction_20260831.py` as a persistence authority until its boundary defect is resolved and its output is proven not to discard current target-resident modules.
- Prefer direct surgical P163 ownership closure inside the existing `Current/PWA/New-main`.
- Remove duplicate `RAWAEA MAIN2 COMPATIBILITY` ownership only when its duplicate nature is proven; retain `MAIN2 AUTHORITATIVE MODULE`.
- Preserve MAIN1–MAIN11 current content and all target-resident extensions, including `RAWAEA 122 DIAMOND CONTRACT CLOSURE v1`.
- After surgery: run static structure checks, Node syntax, browser smoke, owner/license/permission checks, and only then persist Gold/Diamond status.

## CONTINUITY ARTIFACTS
- Unified execution prompt: `doc/Draft/Reprots/MASTER_CTO_UNIFIED_CONTINUITY_EXECUTION_GOLD_DIAMOND.md`.
- Latest forensic report: `doc/Draft/Reprots/تقرير26.md`.
- Historical reports 1–25 remain untouched.

## GOLD / DIAMOND STATUS
```text
GOLD    = NOT PROVEN
DIAMOND = NOT PROVEN
CLOSED  = NO
```

## NEXT EXACT ACTION
Modify the existing closure executor to perform **direct surgical P163 closure on the current target without fragment-only reconstruction**, preserving all current target-resident extensions; then run Node syntax + browser smoke + owner/license/permission gates. Only a fully passing result may update this file to Gold/Diamond/Closed.

## PRODUCTION SAFETY
- Production database writes are NOT authorized in this New-main closure track.
- Production reads may be used for contract verification.
- No historical report may be deleted as part of continuity work.
