# RAWAEA ERP — MAIN Tenant/CRUD Forensic Repair — 2026-08-20

## Scope
Forensic review of `Current/PWA/main.html` against current Production Supabase and the execution history Prompts 11–25.

## Proven root cause
`main.html` delegates creation/modification of users, items, branches, customers, suppliers, roles, settings and journal entries to Edge Functions, but the deployed functions had hard-coded company context (`00000000-0000-0000-0000-000000000001`) and several unscoped update/lookups.

This caused a multi-company CRUD defect: a user operating company B could create a record in company A, and some edits could target records outside the caller's company.

Additional direct-write defect: the Finance/Chart of Accounts section in `main.html` writes directly to `chart_of_accounts`, whose Production contract is `UNIQUE(company_id, account_code)` with `company_id NOT NULL`; its prior public-all RLS policy had no tenant boundary.

## Production evidence
Current Production has 3 companies. Core master entities currently have zero NULL company IDs: users 26, items 50, branches 4, customers 13, suppliers 10, vehicles 1, chart_of_accounts 87.

Current schema contracts include:
- users -> company_id FK, unique email/auth_id
- branches -> unique(company_id, branch_code)
- customers -> unique(company_id, customer_code)
- suppliers -> unique(company_id, supplier_code)
- vehicles -> unique(company_id, vehicle_code)
- chart_of_accounts -> unique(company_id, account_code), company_id NOT NULL
- items -> globally UNIQUE item_code, plus company_id FK

## Production repairs deployed
- save-employee v7
- save-item v8
- save-branch v3
- save-customer v3
- save-supplier v3
- save-role v6
- save-settings v12
- save-journal-entry v6

All now derive tenant context from authenticated `auth_id -> public.users.company_id`; updates are company-scoped; item opening-stock branch resolution is company-scoped; role resolution is company-scoped; journal entry account IDs are validated against the same company.

`save-employee` also validates allowed branches against the caller company and removes a just-created Auth user if insertion into `public.users` fails, preventing orphaned Auth accounts.

## Chart of Accounts repair
Production migration `20260820_tenant_safe_main_crud`:
- sets `chart_of_accounts.company_id` default to `app_private.current_user_company_id()`;
- removes the public-all policy;
- adds authenticated company-scoped SELECT/INSERT/UPDATE/DELETE policies.

This repairs direct CRUD paths used by `main.html` without weakening tenant boundaries.

## Important distinction
The defect was NOT that `main.html` universally forbids creating new accounts/entities. The actual defect was that backend writers and one direct financial writer were not consistently honoring the current tenant contract.

## Remaining evidence status
Production runtime versions are deployed and retrievable. Existing Git source layout does not contain the deployed `save-*` files under the expected `Current/Edge_Functions/<slug>` paths, which was itself detected as source/Production drift. This document records the Production closure and the exact version identifiers for subsequent canonical source synchronization.
