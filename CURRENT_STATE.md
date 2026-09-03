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
Reconstruction source remains `Current/PWA/main/main1.md` through `main11.md`.
No Production database writes are authorized by this execution.
`Original/PWA/main/*` remains immutable evidence.

## CTO EXECUTOR DIAGNOSTICS
- Previous failure: `P163_COMPAT_COUNT:0`; corrected by making P163 compatible with the current de-duplicated eleven-part source contract.
- Previous failure: `P163_ITEMS_OWNER_COUNT:0`; corrected by normalizing the current Main2 owner export before applying the governed closure marker.
- Previous failure: `MAIN1_INLINE_SCRIPT_MISSING`; direct source inspection proved the current `main1.md` keeps the application `<script>` open through EOF. The assembler now supports that contract and only strips an explicit closing tag when one actually exists.

## CURRENT RETRIGGER
This non-workflow state commit deliberately retriggers the installed Gold/Diamond executor against the corrected assembler. The executor must write `Current/PWA/New-main` only after source gates and browser smoke pass.
