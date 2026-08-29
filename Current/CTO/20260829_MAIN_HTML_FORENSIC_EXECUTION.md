# RAWAEA ERP — MAIN PWA Forensic Execution Log

## Event
- Event ID: MAIN-PWA-20260829-001
- Timestamp: 2026-08-29T13:00:00+03:00
- Scope: Current/PWA/main.html forensic execution
- Directive: MANDATORY CTO DIRECTIVE — Prompt 86

## Pre-execution baseline
- main.html SHA: 34b1bd23f99ac08a797625ab2fd359b21bf140b4
- Production project: fiilmooggumokx
- Production latest migration verified: 20260828235117
- Current PWA companion files inspected: core.js, sw.js, register-sw.js
- Historical source inspected: Original/PWA/main.html

## Directly proven findings
1. `main.html` is the Parent ERP Shell and contains authentication, bootstrap, navigation, master data, sales, procurement, warehouse, finance, HR, CRM, audit and routing behavior. A wholesale rewrite was rejected.
2. Tenant context was not explicitly resolved from the authenticated `users` row before shell bootstrap.
3. `app_settings` was read with global `LIMIT 1` semantics in the parent shell.
4. The frontend used `meta.permissions || ['*']`, which can incorrectly grant wildcard permissions when metadata is absent. Production evidence shows wildcard is an OWNER semantic, not a safe generic fallback.
5. Multiple tenant-owned reads in the shell were not explicitly company-scoped. Production RLS is permissive for some operational tables, so the client must not rely on RLS alone.
6. The shell had a fail-open `forceEnterFallback()` path capable of opening the application after bootstrap failure.
7. Production has a canonical Vehicle Master contract: `vehicles` + `create_vehicle_atomic(...)`, with company validation and optional Mobile/Van branch initialization.
8. Direct client-side Physical Stock mutation was not accepted; Physical Stock remains a backend engine responsibility.

## Historical/target constraints preserved
- Parent PWA structure preserved.
- OWNER wildcard semantics preserved only for confirmed owner state.
- Item identity follows Production schema evidence; `items.item_code` is globally UNIQUE, so no speculative company restriction was introduced merely because `items.company_id` exists.
- Vehicle mutation remains delegated to `create_vehicle_atomic`.
- No permanent test vehicle or permanent test inventory was created.

## Execution units
- MAIN-TENANT-001 — authenticated tenant context
- MAIN-AUTH-002 — permission fallback safety
- MAIN-BOOT-003 — fail-closed bootstrap
- MAIN-READ-004 — explicit company scoping for tenant-owned reads
- MAIN-FLEET-005 — native Vehicle Master integration
- MAIN-STOCK-006 — verify no parent-shell Physical Stock writer

## Required verification gates
- Inline JavaScript syntax check
- Static tenant-read invariant check
- No wildcard permission fallback for non-owner users
- Vehicle route/module/export and `create_vehicle_atomic` contract
- No direct `stock_branches` physical mutation from main.html
- No direct `inventory_log` write from main.html
- Git diff integrity

## Status
Execution trigger committed. The governed executor must now perform the surgical source transformation, validate it, record the resulting commit, and remove the temporary executor workflow.
