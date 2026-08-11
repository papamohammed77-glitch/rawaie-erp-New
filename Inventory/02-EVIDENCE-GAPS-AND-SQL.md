# Remaining Evidence Required Before Any Patch

These are the only gaps currently material enough to block implementation. Do not request evidence already present in `Evidence/Production/`.

## EVIDENCE-015 — full Production schema for the Manual Voucher dependency closure

```sql
select table_name, ordinal_position, column_name, data_type,
       is_nullable, column_default
from information_schema.columns
where table_schema = 'public'
  and table_name in (
    'stock_vouchers',
    'stock_voucher_details',
    'stock_branches',
    'inventory_log',
    'branches',
    'items',
    'app_settings',
    'audit_log'
  )
order by table_name, ordinal_position;
```

## EVIDENCE-016 — complete deployed Manual Voucher RPC definitions

```sql
select p.proname as function_name,
       pg_get_function_identity_arguments(p.oid) as identity_arguments,
       p.prosecdef as security_definer,
       pg_get_functiondef(p.oid) as function_definition
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'create_manual_stock_voucher_atomic',
    'post_manual_stock_voucher_atomic',
    'complete_manual_stock_voucher_atomic',
    'cancel_manual_stock_voucher_atomic'
  )
order by p.proname;
```

## EVIDENCE-017 — audit trigger path

```sql
select event_object_schema,
       event_object_table,
       trigger_name,
       event_manipulation,
       action_timing,
       action_statement
from information_schema.triggers
where event_object_schema = 'public'
  and event_object_table in (
    'stock_vouchers',
    'stock_voucher_details',
    'inventory_log',
    'audit_log'
  )
order by event_object_table, trigger_name;
```

Then retrieve trigger-function definitions if any trigger writes audit records.

## Important
These queries are evidence collection only. They are not migrations and must not modify Production.

## Why these three remain
They close exactly the unresolved boundaries:
- schema/RPC drift;
- CANCEL behavior;
- authoritative audit actor/history path.

Partial RECEIVE idempotency must then be solved against the actual schema rather than inventing a new column before knowing whether an existing operation identity mechanism already exists.