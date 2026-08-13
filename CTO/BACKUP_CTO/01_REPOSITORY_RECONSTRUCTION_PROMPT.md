# BACKUP CTO — PROMPT 01
## REPOSITORY RECONSTRUCTION

أريدك أن تعيد بناء صورة المشروع من GitHub قبل أي تنفيذ.

### REPOSITORY 1 — ACTIVE
`papamohammed77-glitch/rawaie-erp-New`

ابدأ بقراءة:
- `README.md`
- `CTO/`
- `Governance/`
- `Evidence/Production/`
- `Inventory/`
- `Rescue/`
- `Current/`
- `CTO/TASKS/`
- `SQL_Evidence/`
- `Architecture/`

افتح شجرة الملفات الفعلية، لا تفترض أسماء ملفات أخرى.

### REPOSITORY 2 — HISTORICAL / REVIEW
`papamohammed77-glitch/rawaie-erp-review`

استخدمه بعد فهم Active Repository لاستعادة:
- `docs/00_REVIEW_START_HERE.md`
- `docs/01_PROJECT_OVERVIEW.md`
- `docs/06_SYSTEM_ARCHITECTURE.md`
- `docs/09_DATABASE_DOCUMENTATION.md`
- `docs/10_API_CATALOG.md`
- `docs/13_SECURITY_MODEL.md`
- `docs/17_ARCHITECTURAL_DECISIONS.md`
- `docs/18_MODULE_RESPONSIBILITY_MATRIX.md`
- `docs/19_KNOWN_ISSUES_AND_DEBT.md`
- `docs/24_FINAL_CTO_REPORT.md`
- `Architecture/RAWAEA_ARCHITECTURE_CONSTITUTION.md`
- `Architecture/EXECUTION PROTOCOL.md`
- `Architecture/DOMAIN_EXECUTION_ORDER.md`
- `Architecture/الأذونات المخزنية اليدوية.md`
- `PWA/warehouse/vouchers.html`
- `PWA/warehouse/picker.html`
- `PWA/warehouse/returns.html`
- `PWA/sales/van-sales.html`
- `Edge_Functions/original/`
- `Edge_Functions/current/`
- `Edge_Function_Reports/_HISTORICAL/`

### REQUIRED OUTPUT
أنشئ في ذهنك 7 خرائط:
1. Repository Map
2. Runtime Architecture Map
3. Database/Business Core Map
4. Edge Function Map
5. PWA/Application Map
6. Production Evidence Map
7. Historical Knowledge Map

### RECONCILIATION RULE
إذا وجدت اختلافًا بين Active وHistorical:
- لا تخمن.
- سجل الاختلاف.
- استخدم Production Evidence لتحديد الحقيقة الحالية.
- استخدم Historical فقط لفهم لماذا وصل النظام إلى الحالة الحالية.

### SPECIAL RULE
وجود SQL migration أو design في GitHub لا يثبت Production deployment.
وجود تقرير نجاح لا يثبت Production execution إلا إذا حمل Evidence صريحًا.

لا تكتب أي كود قبل اكتمال هذه الخرائط.
