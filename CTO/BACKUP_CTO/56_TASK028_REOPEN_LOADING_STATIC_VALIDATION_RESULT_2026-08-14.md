# 56 — TASK-028 REOPEN-LOADING STATIC VALIDATION RESULT

## STATUS
`STATIC PASS — NON-PRODUCTION EXECUTION AUTHORIZED`

## CHANGESET
- Repository: `papamohammed77-glitch/rawaie-erp-New`
- Branch: `task-028-loading-unloading-refactor`
- PR: `#3`
- Original: untouched
- Production: untouched

## RESPONSIBILITY REVIEW
`reopen-loading` is classified as a CONTROLLED REFACTOR because physical reversal moved into the central PostgreSQL stock boundary. The pre-change responsibility matrix is recorded in Report 52.

| Responsibility | Original/Production | Current Target | Result |
|---|---|---|---|
| Authentication | Edge | Edge wrapper | PRESERVED |
| Runsheet lookup/company context | Edge | Edge + Core validation | PRESERVED/HARDENED |
| Physical stock reversal | direct MAIN mutation | `post_stock_movement(Unloading)` VAN→MAIN | MOVED |
| Inventory log | direct insert | central stock engine | MOVED |
| MAIN allocated restoration | absent/incomplete | central Unloading semantics | CORRECTED |
| `qty_loaded` | preserved | preserved by Reopen | PRESERVED |
| Runsheet state | Loaded→Loading | transactional Core | PRESERVED |
| COGS | none in Reopen target | none | PRESERVED |
| Event idempotency | absent | deterministic `operation_id` + unique movement key | ADDED |

## STATIC CHECKS
- Edge wrapper contains no direct stock mutation.
- Edge wrapper contains no direct inventory-log mutation.
- Reopen calls only the Core capability.
- Core is `SECURITY DEFINER` with `search_path=public`.
- Reopen requires a deterministic `operation_id`.
- Retry checks the persisted movement identity before the Loaded-state gate.
- Physical reversal uses persisted `run_sheet_details.qty_loaded`.
- Reopen preserves `qty_loaded` and returns the Runsheet to `Loading`.
- Reopen restores MAIN `allocated_qty` through the central Unloading movement.
- No COGS operation is present.
- Loading was corrected to treat a reopened cycle as an edit: requested quantity replaces prior `qty_loaded` rather than being added to it.
- Multi-item Loading execution order is explicitly `ORDER BY item_code` to make rollback behavior deterministic.

## STAGING PREPARATION
Staging required two schema-parity corrections discovered during controlled execution:
1. `run_sheet_details.id` needed the same UUID default expected by the production schema.
2. `inventory_log.id` needed the same UUID default expected by the production schema.

These are staging-environment parity corrections, not Production mutations.

## PROTECTED ASSETS
`Original/` was not modified. Production database and Production Edge Functions were not modified or deployed.

## GATE
Static validation passed. Runtime testing proceeded only against `rawaea-staging`.
