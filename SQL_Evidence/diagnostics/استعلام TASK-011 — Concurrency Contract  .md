SELECT
    p.proname AS function_name,
    pg_get_function_identity_arguments(p.oid) AS arguments,
    CASE WHEN pg_get_functiondef(p.oid) ILIKE '%FOR UPDATE%' THEN 'YES' ELSE 'NO' END AS row_lock,
    CASE
        WHEN pg_get_functiondef(p.oid) ILIKE '%UPDATE stock_branches%'
         AND (
              pg_get_functiondef(p.oid) ILIKE '%WHERE id = v_stock_id%'
              OR pg_get_functiondef(p.oid) ILIKE '%WHERE branch_id =%'
              OR pg_get_functiondef(p.oid) ILIKE '%AND item_id =%'
         )
        THEN 'YES'
        ELSE 'UNKNOWN'
    END AS conditional_stock_update,
    pg_get_functiondef(p.oid) AS function_definition
FROM pg_proc p
JOIN pg_namespace n
  ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN (
      'post_manual_stock_voucher_atomic',
      'send_stock_voucher_atomic',
      'complete_manual_stock_voucher_atomic'
  )
ORDER BY p.proname;