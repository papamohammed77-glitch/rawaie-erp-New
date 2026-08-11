# RAWAEA ERP — DOMAIN EXECUTION ORDER

**Status:** ACTIVE
**Phase:** 3 — Immediate Domain Execution

## Mandatory order

```text
1. INVENTORY
2. ACCOUNTING
3. LEDGER
4. SALES
5. PURCHASING
6. DELIVERY / RUNSHEET
7. AI LAYER
```

## Inventory internal order

```text
INV-001 Reality Map
↓
INV-002 Source of Truth
↓
INV-003 Movement Model
↓
INV-004 Six Quantities
↓
INV-005 Cost Layer
↓
INV-006 Inventory Engine
↓
INV-007 Consumer Migration
```

## Rules

- لا نعيد بناء ERP من الصفر.
- Inventory أولًا لأنه أساس COGS/Accounting/Sales/Purchasing/Delivery/AI.
- كل Domain له Gate قبل الانتقال.
- لا يتم العمل على عدة Domains في الوقت نفسه دون قرار معماري صريح.
- لا يبدأ Refactor قبل تحديد Source of Truth والـWriters والـReaders والمخاطر.
- لا Mass Rewrite.
- كل تغيير صغير وقابل للتحقق والتراجع.

## Inventory completion gate

لا يغلق Inventory إلا بعد إثبات:

- مصدر حقيقة واحد لحركة المخزون.
- جميع stock-changing events عبر authority المعتمدة.
- عدم وجود مسارات سرية لتعديل الكميات.
- صحة Purchase/Sales/Returns/Transfers/Adjustments/Loading/Unloading/Van flows.
- Company/Branch isolation.
- Duplicate posting protection.
- حفظ التاريخ التشغيلي.
- Consumer compatibility.
- Regression tests.
- عدم وجود UNKNOWN حرج.
- عدم وجود Architectural Drift.
