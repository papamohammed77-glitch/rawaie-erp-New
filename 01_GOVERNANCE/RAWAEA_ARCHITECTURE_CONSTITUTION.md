# RAWAEA ARCHITECTURE CONSTITUTION
Version: 1.1

Status: ACTIVE

Authority:
Chief Architecture Document

Last Updated:
2026-08-10

MISSION

Rawaea ERP is not a traditional ERP.
Rawaea is a Business Operating System.

CORE PHILOSOPHY

The system is built around ONE BUSINESS CORE.
Applications are only interfaces.
Business logic belongs ONLY to the Core.

ARCHITECTURAL LAW #1 — Single Source Of Truth
Every business entity MUST have exactly ONE source of truth.

ARCHITECTURAL LAW #2 — Business Rules Never Live Inside UI
Business rules belong only inside Core / Edge Functions / Domain Services.

ARCHITECTURAL LAW #3 — Database Is A State Storage
Database stores state; it does not become an excuse to duplicate business logic.

ARCHITECTURAL LAW #4 — Inventory Is A Business Engine
Inventory is NOT quantities. Inventory is an Engine. Stock movement is event-driven.

ARCHITECTURAL LAW #5 — Accounting Never Calculates Inventory
Accounting consumes inventory events.

ARCHITECTURAL LAW #6 — Ledger Never Recalculates Accounting
Ledger is generated; never manually edited.

ARCHITECTURAL LAW #7 — Applications Are Replaceable
PWA, POS, Van Sales, Office and dashboards are interfaces; the Business Core must not depend on them.

ARCHITECTURAL LAW #8 — Edge Functions Are Business Services
Edge Functions represent business capabilities, not UI helpers.

ARCHITECTURAL LAW #9 — No Duplicate Logic
Every business rule exists once. Duplication is a bug.

ARCHITECTURAL LAW #10 — Backward Compatibility
Every migration must preserve production data.

CURRENT DEPLOYMENT MODEL

Single Company + Multi Branch + Multi User.
company_id remains in the model for forward compatibility; it must not be treated as a client-selectable tenant context.

PLATFORM AUTHORITY BOUNDARY

System Owner / Platform Authority is distinct from operational users. Inventory repairs must not weaken or recreate this boundary.

DOMAIN HIERARCHY

Core Engine
↓
Inventory
↓
Accounting
↓
Ledger
↓
Sales
↓
Purchasing
↓
Delivery
↓
Runsheet
↓
Reporting
↓
AI

PROHIBITED ACTIONS

- Create tables without architectural approval.
- Duplicate business logic.
- Mix UI with business logic.
- Write SQL directly inside UI.
- Recalculate ledger manually.
- Recalculate inventory from reports.
- Create hidden dependencies.
- Bypass Source Of Truth.

SOURCE OF TRUTH PRINCIPLE

Inventory owns stock.
Accounting owns journal.
Ledger owns balances.
Sales owns orders.
Purchasing owns purchasing.
Delivery owns delivery execution.
Runsheet owns field execution.
AI owns recommendations only.

REFACTORING POLICY

Rewrite only when Business Rule is wrong, Source of Truth is wrong, Architecture is violated, or Performance is unacceptable.

FINAL PRINCIPLE

Protect the Core.
Everything else can be replaced.
Never replace the Core.
