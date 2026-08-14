# 53 — TASK-028 IDEMPOTENCY CORRECTION RESULT

## STATUS
`P0-A CORRECTED IN CURRENT / NOT RUNTIME-VERIFIED`

## ROOT CAUSE
The previous Core generated `inventory_log.log_code` with `gen_random_uuid()` and used only the Runsheet state as the retry guard. That was not event-level idempotency.

## CORRECTION
The final migration now:

1. adds nullable `inventory_log.idempotency_key`;
2. adds a unique partial index on `(company_id, idempotency_key)`;
3. introduces a 10-argument `post_stock_movement` requiring an idempotency key for `Loading` and `Unloading`;
4. keeps a 9-argument compatibility wrapper for legacy movements but explicitly rejects Loading/Unloading without an event key;
5. re-checks the key after stock-row locking to handle concurrent duplicate requests;
6. rejects an idempotency-key conflict when an existing event has a different movement type or quantity;
7. derives Loading keys from Runsheet cycle identity plus the normalized Loading payload hash plus item UUID;
8. derives Unloading keys from Runsheet cycle identity plus the persisted Unloading payload hash plus item UUID.

## PARTIAL LOADING COMPATIBILITY
The key includes the normalized operation payload hash. Therefore:

- retry of the exact same Loading payload => duplicate event;
- a legitimate later partial Loading with a different quantity/payload => new event;
- same item can therefore be loaded in multiple legitimate partial operations without reusing the same idempotency key.

## SAFETY
No Production migration or Edge deployment was performed.

## VERIFICATION LIMIT
This correction is statically represented in Current. Runtime verification requires the Non-Production gate after the lifecycle blocker is resolved.
