# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-13
**Checkpoint:** Report158 — CTO Forensic E2E للنظام الأم ومطابقة الحالة الحالية.

## GOVERNANCE
التقارير السابقة Historical/Reference فقط وليست حالة حالية.
الحالة المعتمدة هي فقط:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`.

**الهدف الحاكم — يُقرأ بعناية:** ملف النظام الأم الحالي المنشور هو Source of Truth، والمهمة هي التحقق الجنائي من حالته الحالية وإكماله وظيفيًا دون إعادة إصلاح ما ثبت إغلاقه.

## SOURCE OF TRUTH
Repository: `papamohammed77-glitch/erp-frontend`
Path: `companies/company-1/main.html`
Ref: `main`

`Current/PWA/main2/*` و`Original/PWA/main/*` وNew-main = Historical/Reference فقط.

## CURRENT GIT
HEAD:
`3573c92026557cb56a7782babe6f6cf690243072`

Direct parent:
`28f39b351bb44a4cd885ba784d505aadaeb13cf1`

HEAD message: `Update main.html`

HEAD current main.html contains the already-fixed Transfer query:
`.select('id, branch_code, name')`

The previous `branch_name` Transfer defect is therefore **CLOSED in CURRENT GIT**. Do not re-patch it unless fresh served-browser evidence proves an older asset is being served.

Current `main.html` was read through EOF; last line = `35521`.

## FORENSIC ASSEMBLY
`rawaie-erp-New/forensic_main_assembly.yml` is correct and requires no change:
```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status: reference_only; published_main_is_authoritative
```

## CURRENT PRODUCTION / DATABASE
Project: `fiilmooggumokxanwiyx`
Company: `00000000-0000-0000-0000-000000000001`

Current relevant facts:
- active branches: 2 (`BR-01`, `BR-2`)
- active direct-sales reps: 1
- active vehicles: 0
- items: 17
- stock vouchers: 0
- orders: 0
- runsheets: 0

For item `1001` (`جو كيك 5ج`):
- BR-01 qty = 2
- BR-2 qty = 1

`public.branches` has `name`, not `branch_name`.

## INVENTORY CORE
Physical Stock contract:
`Physical Movement → post_stock_movement → stock_branches + inventory_log`

Production discovery proves:
`Physical Writers outside post_stock_movement = 0`

`reserve_stock` and `release_stock_reservation` are reservation-only.
`setup_van_stock` / `create_vehicle_atomic` initialize stock rows and are not movement writers.

**Inventory Physical Writer Zero-Debt = CLOSED.**

## TRANSFER E2E
Production transactional test:
`BR-01 → BR-2 → item 1001 → create_manual_stock_voucher_atomic → send_stock_voucher_atomic`

Result:
`create=success`
`send=success`
`status=Sent`
`movement_count=1`

Second SEND returned `duplicate=true`.
Test transaction was rolled back and post-test verification confirmed no permanent test voucher/log.

**Transfer backend = CLOSED / PRODUCTION VERIFIED.**

## FRONTEND TRANSFER STATUS
Current Source of Truth has the historical `branch_name` defect removed.
No assistant modification was made to `erp-frontend/companies/company-1/main.html` this session; frontend remains owner-managed.

Browser click-by-click E2E is **NOT VERIFIED** in this environment because no Browser Automation channel is available.

## PRODUCTION SECURITY CHANGE
Applied migration this session:
`20260913101126_main_cto_security_surface_hardening`

Actions:
- revoked anonymous/authenticated EXECUTE on selected SECURITY DEFINER functions not required directly by browser clients;
- set explicit Search Path for `employee_document_storage_company_id(text)`.

No permanent business-data changes were made.

Remaining security/performance items must be treated as independent Closure Units, not bulk-cleaned.

## GOLD / DIAMOND FUNCTIONAL GAPS
Current main contains functional operations, sales, inventory, core finance, reports, HR, and CRM capabilities.

Current database also contains foundations for some advanced areas, but no proven complete transactional/UI contracts were established in this session for:
- cheques;
- installments;
- loyalty points;
- work orders/workflow;
- fixed assets;
- standalone expense management;
- independent cost-center management UI.

Do not invent backend contracts from table names alone.
Do not call the system Gold/Diamond complete while these business capabilities remain unverified or incomplete.

## DATA FORENSICS
Earlier cross-company stock rows were observed in Production. No destructive cleanup was performed because current schema semantics make Item Master identity globally unique and there is not yet sufficient proof that the rows are disposable fixtures.

**Do not delete, rewrite, or reassign those rows without historical/source evidence.**

## SESSION ARTIFACTS
Primary report:
`doc/Draft/Reprots/Report158_CTO_E2E_Main_Forensic_20260913.md`

Report commit:
`ca941e3cbd9a51d1b499620b48b541e8a1a9779d`

CURRENT_STATE update commit will be the commit containing this file update.

## FINAL NEXT-CTO START SEQUENCE
ابدأ دائمًا من الواقع وليس من التقارير:

`CURRENT GIT HEAD`
`→ DIRECT PARENT`
`→ PARENT OF PARENT when material`
`→ CURRENT SOURCE OF TRUTH`
`→ CURRENT DB SCHEMA`
`→ CURRENT DB DATA`
`→ CURRENT EDGE DEPLOYMENTS / SOURCE / VERSION`
`→ CURRENT RUNTIME / LOG EVIDENCE`
`→ REPRODUCE EXACT SYMPTOM`
`→ IDENTIFY EXACT FUNCTION / LINE / QUERY`
`→ HISTORICAL RECONSTRUCTION TO EXPLAIN CONTRACT`
`→ IDENTIFY ACTUAL GAP`
`→ ONE SURGICAL CLOSURE UNIT`
`→ REREAD CURRENT SOURCE`
`→ PRODUCTION TRANSACTIONAL VERIFY`
`→ RUNTIME VERIFY`
`→ AUDIT / SECURITY VERIFY`
`→ REPORT + CURRENT_STATE`
`→ NEXT UNIT ONLY AFTER CLOSURE`

### لا تكسر هذه القواعد
- لا تعتبر أي تقرير قديم حالة حالية.
- لا تستخدم `main2` كمصدر حقيقة.
- لا تعيد إصلاح شيء مثبت أنه مغلق.
- لا تخترع Production data لإنجاح الاختبار.
- لا تحول Backend PASS إلى Browser PASS.
- لا تجمع عدة Writer/Function closures في دفعة واحدة.
- لا تبني UI فوق جدول أو اسم function دون إثبات Consumer/transaction contract.
- لا تستخدم نسبة اكتمال قبل مطابقة Production الحالية في نفس التحقيق.

**الحقيقة الحالية أولًا، ثم العقد، ثم الفجوة المثبتة، ثم الإصلاح الجراحي، ثم التحقق، ثم الإغلاق.**
