# TASK-003 — VOUCHER DATA CONTRACT

## Scope
Production contract for:
- `public.stock_vouchers`
- `public.stock_voucher_details`
- constraints
- indexes
- foreign-key relationships
- Production RPCs directly coupled to the Voucher lifecycle / Inventory Core

## Evidence Authority
Primary evidence:
- `SQL_Evidence/diagnostics/1-Exact table columns + defaults + generated expressions.csv`
- `SQL_Evidence/diagnostics/2-Primary keys  unique constraints  check constraints  FKs.csv`
- `SQL_Evidence/diagnostics/3-Index definitions — exact Production definitions.csv`
- `SQL_Evidence/diagnostics/4-Foreign-key dependencies in both directions.csv`
- `SQL_Evidence/diagnostics/8-FunctionsRPCs whose stored source references Inventory Core.csv`

Historical documentation and unreleased migrations are not authoritative over these Production facts.

## 1. `stock_vouchers` — Production Columns
Confirmed:

| Column | Type | Null | Default / Generated |
|---|---|---|---|
| id | uuid | NO | `gen_random_uuid()` |
| company_id | uuid | NO | — |
| voucher_code | varchar | NO | — |
| voucher_date | date | NO | `CURRENT_DATE` |
| type | varchar | NO | — |
| status | varchar | YES | `'Draft'` |
| from_branch_id | uuid | YES | — |
| to_branch_id | uuid | YES | — |
| from_type | varchar | YES | — |
| from_id | uuid | YES | — |
| to_type | varchar | YES | — |
| to_id | uuid | YES | — |
| reference | varchar | YES | — |
| notes | text | YES | — |
| created_by | varchar | YES | — |
| sent_date | timestamptz | YES | — |
| received_date | timestamptz | YES | — |
| completed_at | timestamptz | YES | — |
| created_at | timestamptz | YES | `now()` |
| updated_at | timestamptz | YES | `now()` |
| source | text | YES | `'Manual'` |

No `completed_by` column is present in the captured Production schema.

## 2. `stock_voucher_details` — Production Columns
Confirmed:

| Column | Type | Null | Default |
|---|---|---|---|
| id | uuid | NO | `gen_random_uuid()` |
| voucher_id | uuid | NO | — |
| item_id | uuid | NO | — |
| item_code | varchar | YES | — |
| item_name | varchar | YES | — |
| unit | varchar | YES | — |
| qty | numeric | NO | — |
| unit_price | numeric | YES | `0` |
| received_qty | numeric | YES | — |
| notes | text | YES | — |
| created_at | timestamptz | YES | `now()` |

`received_qty` is the Production field used to represent cumulative received quantity at detail level.

## 3. Constraints
### `stock_vouchers`
- Primary key: `id`.
- Unique: `(company_id, voucher_code)`.
- CHECK: `source IN ('Auto','Manual')`.
- `company_id` FK → `companies.id`, ON DELETE CASCADE.
- `from_branch_id` FK → `branches.id`, ON DELETE SET NULL.
- `to_branch_id` FK → `branches.id`, ON DELETE SET NULL.

### `stock_voucher_details`
- Primary key: `id`.
- `voucher_id` FK → `stock_vouchers.id`, ON DELETE CASCADE.
- `item_id` FK → `items.id`, ON DELETE RESTRICT.
- NOT NULL constraints on `id`, `voucher_id`, `item_id`, `qty`.

Important: the captured Production evidence does NOT establish a database CHECK enforcing positive `qty`, valid Voucher `type` values, valid `status` values, or consistency among `from_type/from_id/to_type/to_id`. Those rules may exist in RPCs, but must not be falsely represented as table constraints.

## 4. Indexes
### `stock_vouchers`
- `stock_vouchers_pkey` — UNIQUE `(id)`.
- `stock_vouchers_company_id_voucher_code_key` — UNIQUE `(company_id, voucher_code)`.

### `stock_voucher_details`
- `stock_voucher_details_pkey` — UNIQUE `(id)`.

No additional Production index on `stock_voucher_details.voucher_id` was captured in the index evidence. Do not add one as part of this task.

## 5. Lifecycle Evidence From Production RPCs
The captured Production RPC source references the following manual-voucher lifecycle functions:

- `create_manual_stock_voucher_atomic`
- `post_manual_stock_voucher_atomic`
- `complete_manual_stock_voucher_atomic`
- `cancel_manual_stock_voucher_atomic`

The captured source proves, among other things:

### Create
`create_manual_stock_voucher_atomic`:
- validates company context against `app_settings`;
- supports `Transfer`, `DirectSale`, `DirectReturn`, `SupplierReturn`;
- creates `Draft` vouchers;
- inserts voucher details;
- rejects duplicate item lines within the voucher;
- validates item/company and branch/company consistency.

### Post / SEND / RECEIVE
`post_manual_stock_voucher_atomic`:
- accepts `SEND` or `RECEIVE` operations;
- locks the voucher row with `FOR UPDATE`;
- validates expected lifecycle status;
- validates Inventory effects against voucher details;
- interacts with `stock_branches` and `inventory_log`;
- handles cumulative `received_qty` for receive operations.

### Complete
`complete_manual_stock_voucher_atomic`:
- locks the voucher row;
- expects `Received` for `Transfer` / `DirectReturn`;
- expects `Sent` for `DirectSale` / `SupplierReturn`;
- changes status to `Completed`;
- writes `completed_at` and attempts to write `completed_by`.

**Critical Production Drift:** `completed_by` is not present in the captured Production `stock_vouchers` schema, while the deployed function definition attempts `completed_by=p_user_email`. This is a proven schema/RPC mismatch and must be resolved before relying on Complete.

### Cancel
`cancel_manual_stock_voucher_atomic`:
- locks the voucher row;
- allows cancellation only while status is `Draft`;
- changes status to `Cancelled`.

## 6. RPC Security
The captured lifecycle functions are `SECURITY DEFINER` with `search_path` set to `public`.

RPC privileges remain governed by the dedicated Production privileges evidence and must be treated as part of TASK-004's full RPC contract reconciliation.

## 7. Voucher Contract — Source of Truth

| Concern | Source of Truth |
|---|---|
| Voucher identity | `stock_vouchers.id` |
| Business voucher identity | `(company_id, voucher_code)` |
| Voucher lifecycle state | `stock_vouchers.status` + lifecycle RPC rules |
| Voucher type | `stock_vouchers.type` + lifecycle RPC rules; no DB type CHECK proven |
| Origin / destination branch columns | `from_branch_id`, `to_branch_id` |
| Generic custody metadata | `from_type/from_id`, `to_type/to_id` + RPC validation |
| Ordered item lines | `stock_voucher_details` |
| Requested quantity | `stock_voucher_details.qty` |
| Received quantity | `stock_voucher_details.received_qty` |
| Stock balance | **NOT** Voucher tables; authoritative Inventory balance is `stock_branches.qty` |
| Reserved stock | `stock_branches.allocated_qty` |
| Movement history | `inventory_log` |
| Lifecycle mutation | Production Voucher RPCs, not UI code |

## 8. Findings / Risks
1. `completed_by` schema/RPC drift is a blocking defect for Complete.
2. Voucher type/status semantics are enforced primarily by RPC logic, not by proven table CHECK constraints.
3. `from_branch_id/to_branch_id` are nullable at DB level and use `ON DELETE SET NULL`; therefore application/RPC validation is required to preserve custody semantics.
4. `received_qty` exists at detail level and is therefore part of the Partial Receive contract; its idempotency and replay semantics must be formally tested in later tasks.
5. `stock_voucher_details` has no captured unique index on `(voucher_id,item_id)`; duplicate-line prevention currently appears in RPC logic rather than as a database uniqueness constraint.

## Gate
**TASK-003 STATUS: COMPLETE / GO WITH BLOCKING DRIFT RECORDED**

No schema patch is authorized by this task.

The `completed_by` mismatch is recorded as a blocker for lifecycle completion, not silently corrected here.

## Next Safe Task
`TASK-004 — Production RPC Contract`
