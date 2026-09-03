# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Current truth must be reconstructed from direct Git, direct Production/database evidence, active deployments/runtime evidence when available, and verified artifacts.
- Historical reports are evidence of what was done; they are not current truth by themselves.
- `Current/PWA/New-main` is the authorized target for the current PWA reconstruction track.
- `Current/PWA/main.html` is a separate artifact and must not be substituted for `New-main` by filename similarity.
- Historical reports are sacred and are never deleted to simplify continuity.
- `UNKNOWN ≠ BUG`, `UNKNOWN ≠ REMOVE`.
- `Git/source verified ≠ runtime verified`.
- `Runtime verified ≠ Production data repair`.
- Governing loop: CURRENT_STATE → LAST VERIFIED EVENT → CURRENT GIT → CURRENT PRODUCTION → DEPLOYMENTS/RUNTIME → CURRENT FILES → RECONCILE → SURGICAL CHANGE → VERIFY → CURRENT_STATE.

## CTO EXECUTION — 2026-09-03
The existing validated push executor is running the final New-main reconstruction/P163 closure against `Current/PWA/main/main1.md` through `main11.md`.
No Production database writes are authorized by this execution.
`Original/PWA/main/*` remains immutable evidence.

## CTO EXECUTOR DIAGNOSTIC — 2026-09-03
```text
Traceback (most recent call last):
  File "/home/runner/work/rawaie-erp-New/rawaie-erp-New/tools/run_final_main_reconstruction_20260831.py", line 230, in <module>
    main()
  File "/home/runner/work/rawaie-erp-New/rawaie-erp-New/tools/run_final_main_reconstruction_20260831.py", line 208, in main
    candidate, chunks, runtime_changes, p163_gates = assemble()
                                                     ^^^^^^^^^^
  File "/home/runner/work/rawaie-erp-New/rawaie-erp-New/tools/run_final_main_reconstruction_20260831.py", line 156, in assemble
    candidate, p163_gates = p163_owner_surgery(candidate)
                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/runner/work/rawaie-erp-New/rawaie-erp-New/tools/run_final_main_reconstruction_20260831.py", line 90, in p163_owner_surgery
    raise RuntimeError('P163_COMPAT_COUNT:' + str(s.count(compat)))
RuntimeError: P163_COMPAT_COUNT:0

```
