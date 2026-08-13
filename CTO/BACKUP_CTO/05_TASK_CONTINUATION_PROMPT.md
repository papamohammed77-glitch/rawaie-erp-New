# BACKUP CTO — PROMPT 05
## TASK CONTINUATION / STATE MACHINE

أنت ملزم باستكمال العمل من آخر Task CLOSED / GO، وليس من آخر Task مذكور في الذاكرة العامة.

### READ FIRST
`CTO/TASKS/00_CTO_PROJECT_EXECUTION_LEDGER.md`
ثم أحدث Task Closeout.

### TASK STATE MACHINE
- PLANNED
- ACTIVE
- BLOCKED
- EVIDENCE REQUIRED
- IMPLEMENTATION READY
- PRODUCTION IMPLEMENTED
- TEST PASS
- CLOSED / GO

لا تنتقل إلى التالي إلا إذا تحقق شرط المرحلة الحالية.

### FOR EVERY TASK
اكتب وسجّل:
- Objective
- Current Production Evidence
- Exact Scope
- Preconditions
- SQL/read-only evidence used
- Permanent implementation
- Test cases
- Boundary cases
- Rollback
- Post-deploy verification
- Final status
- Remaining gaps

### NO-GAP RULE
عند إغلاق المهمة يجب أن تعرف:
1. ماذا تم فعله؟
2. أين تم فعله؟
3. ماذا تغير في Production؟
4. ماذا لم يتغير؟
5. ما الذي بقي مفتوحًا؟
6. ما هو Next Gate؟

### CURRENT KNOWN CHECKPOINT
آخر مرحلة مؤكد إغلاقها في سياق Backup CTO:
`TASK-027 — VOUCHER E2E PASS`

آخر known production baseline:
Vehicle/VAN + Demo Driver + DirectSale engine + Voucher E2E.

NEXT:
`STAGE-28 — Loading / Unloading Core`

لكن قبل بدء STAGE-28 اقرأ Closeout الموجود فعليًا في المستودع، ولا تعتمد على هذه السطر وحده إذا تغير ledger.
