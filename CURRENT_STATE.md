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
The existing validated push executor is running the final New-main reconstruction/P163 closure against `Current/PWA/main/main1.md` through `main11.md`.
No Production database writes are authorized by this execution.
`Original/PWA/main/*` remains immutable evidence.

## CTO EXECUTOR DIAGNOSTIC — 2026-09-03
```text
Historical executor failure recorded: P163_COMPAT_COUNT:0 on a prior executor revision. Current tool has been corrected to synthesize the authoritative Main2 boundary when the current main2 fragment has no historical compatibility marker.
```

## CTO EXECUTION RETRIGGER — 2026-09-03
The current execution contract is:
- build the single logical document from `main1.md` through `main11.md`;
- remove only the final application inline-script closure from `main1` before concatenation;
- synthesize the authoritative Main2 ownership boundary where the current `main2.md` lacks the historical marker;
- remove only the two Main1 dashboard/items aliases;
- preserve other exports and MAIN3;
- normalize one governed Main2 closure;
- emit one canonical service-worker registration;
- run source and browser Gold/Diamond gates;
- write `Current/PWA/New-main` only after those gates pass.

## ACTIONS RETRIGGER
This state-only commit deliberately retriggers the already-installed push executor without modifying application source directly.
