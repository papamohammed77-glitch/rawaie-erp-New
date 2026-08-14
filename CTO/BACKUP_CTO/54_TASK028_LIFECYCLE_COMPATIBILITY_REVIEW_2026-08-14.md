# 54 — TASK-028 LIFECYCLE COMPATIBILITY REVIEW

## STATUS
`BLOCKER — reopen-loading is incompatible with the approved Loading/VAN stock topology`

## SOURCES OPENED
- Production `start-loading` v3.
- Production `complete-loading` v9.
- Production `cancel-loading` v4.
- Production `unload-runsheet` v4.
- Production `reopen-loading` v1.
- Historical `reopen-loading.ts` from `rawaie-erp-review`.
- Current `complete-loading` / `unload-runsheet` on the active TASK-028 branch.

## CONFIRMED
`start-loading` moves `Picked -> Loading` and assigns `loader_id`/`loader_start`.

`complete-loading` is the legacy distributed implementation and directly mutates stock, logs, order quantities, accounting, and backorder behavior.

`unload-runsheet` is the legacy reverse path for the existing implementation.

`cancel-loading` clears loaded quantities/state but does not perform the physical stock reversal itself.

`reopen-loading` production v1 and its historical counterpart restore MAIN stock directly, do not decrement the Vehicle/VAN stock branch, and preserve the loaded quantities while moving the Runsheet back to `Loading`.

## CONFLICT
The approved TASK-028 target requires:

```text
Loading   = MAIN -> VAN
Unloading = VAN -> MAIN
```

Therefore the current/historical `reopen-loading` behavior is not a valid inverse of the new physical topology.

## WHY THIS BLOCKS RUNTIME
Running TASK-028 without resolving this lifecycle path could produce an inconsistent state in which:

- MAIN is restored;
- VAN still owns the physical quantity;
- the Runsheet becomes Loading again;
- `qty_loaded` remains populated.

That state would make subsequent Loading/Reopen/Unloading behavior unsafe.

## CURRENT DECISION
No Production change is authorized for `reopen-loading` in this gate.

A safe Current implementation must move the physical VAN stock back to MAIN, restore the corresponding MAIN allocation, preserve `qty_loaded` for editing, and return the Runsheet to `Loading` without inventing a new customer sale or COGS event.

## NEXT CONTROLLED CHANGE
Implement a Current-only transactional `reopen_loading` Core capability under the same central stock engine, with its own deterministic lifecycle movement identity, then replace the deployed-style direct stock mutation with a thin wrapper.

No Runtime test should begin until that lifecycle correction is present and statically reviewed.
