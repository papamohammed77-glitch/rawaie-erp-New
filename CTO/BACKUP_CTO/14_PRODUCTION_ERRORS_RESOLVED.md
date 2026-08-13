# BACKUP CTO 14 — PRODUCTION ERRORS & RESOLUTIONS

## 1. `received_by` does not exist
Observed during RECEIVE voucher path.
Lesson: RPC/schema drift must be reconciled against actual Production schema before write.
Resolution: use proven Production columns only; never add fields casually.

## 2. `is_active` does not exist on users
An exploratory query referenced `is_active` and failed.
Resolution: Production users contract uses `status` in the captured evidence.
Lesson: query schema; never assume common naming conventions.

## 3. `referencing_table` ORDER BY query error
A diagnostic UNION query referenced an alias at the wrong query level.
Resolution: corrected the wrapper query rather than changing Production.
Lesson: diagnostics must be syntactically correct and harmless.

## 4. `array_agg` aggregate error
A diagnostic query attempted to treat an aggregate as a scalar.
Resolution: correct diagnostic SQL; do not infer Production defect from a diagnostic syntax error.

## 5. `Transfer` unsupported by central engine
`send_manual_stock_voucher_v2` attempted movement type `Transfer` while the engine accepted a narrower set.
Lesson: movement-type contract must be centrally enumerated and aligned with callers.

## 6. VAN stock row missing
The VAN branch existed but the item stock row was absent.
Discovery: `setup_van_stock(uuid)` existed as the official initialization path.
Resolution: use the official initializer, not a manual INSERT.

## 7. Generated `available_qty`
`setup_van_stock` attempted to INSERT into generated `available_qty`.
Resolution: permanent RPC correction leaves the generated column to PostgreSQL.

## 8. DirectSale source-only
`post_stock_movement` originally deducted from MAIN but did not add to VAN.
Impact: stock-loss-like behavior.
Resolution: DirectSale is now explicitly two-sided source+target in the central engine.

## 9. DirectSale target was NULL
`send_manual_stock_voucher_v2` originally passed NULL as target to the central engine.
Resolution: use `voucher.to_id` for DirectSale/Transfer.

## 10. Fix disappeared after rollback
A `CREATE OR REPLACE FUNCTION` was executed inside a transaction containing the failing test. The failing test rolled back the function replacement.
Resolution: persist permanent fixes in an independent successful transaction, then run tests separately with rollback.

## 11. Vehicle duplication
Multiple experimental vehicle rows existed with the same plate.
Resolution: reference-safety gate; keep one official experimental vehicle.

## 12. Driver account lookup assumption
The driver user schema did not have `is_active`.
Resolution: use existing historical test representatives after schema evidence, because owner confirmed they had no accounting effect.

## Meta-lesson
Every error above is now part of institutional memory. A future CTO should treat the error class as a guardrail, not repeat the experiment.
