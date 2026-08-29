# RAWAEA ERP — MAIN PWA Forensic Execution Log

## Event
- Event ID: MAIN-PWA-20260829-001
- Timestamp: 2026-08-29T10:00:00+03:00
- Scope: Current/PWA/main.html + dependency-proven P0 only
- Directive: MASTER CTO CONTINUITY & EXECUTION DIRECTIVE

## Pre-execution baseline
- Git main HEAD: 6c98074e08fb842a21c3eface6f7a508420b2268
- main.html SHA: 34b1bd23f99ac08a797625ab2fd359b21bf140b4
- Production latest migration: 20260828235117
- Production project: fiilmooggumokxanwiyx

## Proven findings before change
- main.html creates an independent Supabase client instead of relying solely on Current/PWA/core.js.
- main.html contains a global app_settings LIMIT 1 bootstrap read.
- Production schema has global UNIQUE(items.item_code); item identity is therefore not inferred to be company-owned by items.company_id alone.
- Production vehicle master is represented by vehicles + create_vehicle_atomic and mobile branch/stock integration.
- No physical stock writer outside post_stock_movement has been accepted merely by name; candidates require responsibility classification.

## Execution rule
This file intentionally acts as the permanent execution record and is also the push that activates the existing governed P0 executor. The executor must fail closed if required anchors or syntax invariants are absent.

## P0 target
- Authenticated company context from users.company_id.
- Company-scoped tenant-owned reads.
- Integrated Vehicle Master view inside main.html using create_vehicle_atomic.
- No client-side Physical Stock mutation.
- Preserve existing Parent PWA behavior; no wholesale rewrite.

## Status
P0 executor triggered; awaiting its own verified commit and production/source reconciliation.
