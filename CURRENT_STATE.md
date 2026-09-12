# RAWAEA ERP — CURRENT STATE

**Last verified:** 2026-09-12
**Current checkpoint:** Main11 forensic recheck completed from current Git, historical Main11 reviewed, Production HR/CRM schema and RPC foundation deployed, and exact owner replacement package prepared. Main10 R3 is already applied and rechecked. Assembly remains deferred.

## Governing Rules

- Production must be rechecked at report time for every Production-dependent claim.
- Reports are evidence/clues, not current truth.
- `NO EVIDENCE = NO CLAIM`.
- `NO EOF = NO FULL READ`.
- `NO FUNCTIONAL TEST = NO FUNCTIONAL VERIFICATION`.
- `NO PRODUCTION CHECK = NO PRODUCTION VERIFICATION`.
- `NO CROSS-MODULE TRACE = NO BUSINESS COMPLETION`.
- `NO DATA CHECK = NO DATA CLOSURE`.
- Historical reconstruction precedes surgical change.
- Owner edits `Current/PWA/main2/main1..main11.md` source fragments.
- Assistant performs proven Production DB/Edge changes.
- Assembly remains deferred until all eleven fragments are owner-verified and integrated.

## Gold / Diamond Mission

**هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا يُتعامل معه كإضافات شكلية.**

وهذا متسق حرفيًا مع مبدأ الحوكمة: الدراسة أولًا، ثم إعادة بناء العقد التاريخي، ثم تتبع السلوك الحالي، ثم تحديد الفجوة، ثم التعديل الجراحي، ثم الاختبار والتحقق.

## Source of Truth

`Current/PWA/main2/main1.md` … `Current/PWA/main2/main11.md`

Historical reference only:
`Original/PWA/main/*`

Forbidden / retired:
`Current/PWA/main/*`
`Current/PWA/New-main/*`

`forensic_main_assembly.yml` is verified correct and points to `Current/PWA/main2`.

## Current Fragment Git SHAs — direct reconciliation

- main1: `f68d47c7574c34f678cfba2aafa5ad294aadbfe5`
- main2: `65815e23b03e29c125957e6fe283cc1e253a7f7d`
- main3: `eeb56daf8cd01b31b8a7e5f5ada4f1a09df30bfe`
- main4: `e9f967859aeda729cd0811739a280ceec5266d7c`
- main5: `800ad51c88a2e80d060480990836a3c975c7435a`
- main6: `1dc500849a600e6436c1d319bdc93f3d270f6af9`
- main7: `5839252a9807ae1758939dad754a4f3a4505c76f`
- main8: `f67c0217a804d2cb2388ce48fb7f95176c075fb3`
- main9: `b68e5d8f0f52258080950add12fd7fcecbf8c0d7`
- main10: `a6d078d450f1a2182abff0eaf515b6861e66092b`
- main11: `2adfc787c3e5f0ca56abfcc85232e7a971773c3b`

## Latest Reports / Packages

- Report133: `doc/Draft/Reprots/Report133_Main10_Forensic_Recheck_R3_20260912.md`
- Report134: `doc/Draft/Reprots/Report134_Main11_Forensic_Recheck_20260912.md`
- Main10 R3 owner package: `doc/Draft/Reprots/MAIN10_OWNER_SURGICAL_REPLACEMENTS_R3_20260912.js`
- Main11 owner package: `doc/Draft/Reprots/MAIN11_OWNER_SURGICAL_REPLACEMENTS_20260912.js`
- Main11 micro fix: `doc/Draft/Reprots/MAIN11_OWNER_MICRO_FIX_20260912.js`
- Production migration source: `supabase/migrations/20260912000000_main11_hr_crm_gold_capabilities.sql`

## Main10 — authoritative current state

- Current SHA: `a6d078d450f1a2182abff0eaf515b6861e66092b`
- R3 owner apply is present.
- Main10 re-read after Owner Apply = PASS.
- Current EOF remains `window.RW_Views = RW_Views;`.
- No new Main10 patch was required in this cycle.
- Main10 remains not fully closed until executable syntax/E2E/integrated runtime gates are satisfied.

## Main11 — current authoritative state

### Source

- Path: `Current/PWA/main2/main11.md`
- SHA: `2adfc787c3e5f0ca56abfcc85232e7a971773c3b`
- Size: `23532 bytes`
- Full sequential read completed through EOF.
- EOF reconciled after line 540; subsequent requested range was empty.

### Historical reconstruction

`Original/PWA/main/main11.md` was opened and compared. The HR salary placeholders and employee document placeholders are historical/inherited, not a newly introduced defect in the current Main11 edits.

### Proven Main11 defects

1. `RW_HR` used `users.*`, which includes `password_hash` in Production schema.
2. HR UI read `emp.salary`, `emp.allowances`, `emp.deductions` although those fields do not exist in `users` schema.
3. Employee ID/contract document UI literally contained `(قيد التطوير)` although Production already had an employee document table and private Storage bucket.
4. No attendance table/capability existed.
5. No leave request table/capability existed.
6. CRM followup INSERT omitted required `company_id`, so current Production schema/RLS would reject it.
7. CRM filtering used a potentially stale `RW_STATE.data.customers` source after loading.
8. CRM used inline `onclick` with insufficient context-safe escaping.
9. Several Main11 read/write paths converted DB failures into empty/partial UI instead of explicit errors.

## Production changes executed for Main11

Migration actually applied in Production:

`main11_hr_crm_gold_capabilities_20260912`

Recorded Production version:

`20260912083643`

Created tables:

- `employee_profiles`
- `employee_attendance`
- `employee_leave_requests`

Created RPCs:

- `hr_list_employees()`
- `hr_upsert_employee_profile(...)`
- `hr_save_attendance(...)`
- `hr_create_leave_request(...)`
- `crm_save_customer_followup(...)`

Security:

- New HR tables use RLS tied to `app_private.current_user_company_id()` and `app_private.current_user_has_permission('hr')`.
- New HR writes use SECURITY DEFINER RPCs with Session-derived company context.
- CRM write derives company context from authenticated user and validates customer ownership.
- New HR tables have audit triggers using the existing `fn_audit_trigger()`.
- Employee document Storage remains private and Company-scoped.

No destructive Production data repair was required.

Current related counts:

- `users = 24`
- `customers = 3`
- `customer_followups = 0`
- `employee_documents = 0`

## Owner source package — pending application

`doc/Draft/Reprots/MAIN11_OWNER_SURGICAL_REPLACEMENTS_20260912.js`

Contains full-element replacements for:

- `RW_HR` block in current Main11.
- `RW_CRM` block in current Main11.

The package removes the HR `users.*` read, removes salary fakes, uses actual employee profiles, activates attendance/leave/document capabilities, and moves CRM followup writes to the canonical Production RPC.

`doc/Draft/Reprots/MAIN11_OWNER_MICRO_FIX_20260912.js` removes a fixed `+03:00` conversion from the attendance datetime helper.

## Payroll boundary

Production currently contains no proven Payroll/Salary accounting contract or Payroll GL accounts. Therefore no payroll posting logic or chart-of-accounts values were invented.

Payroll-to-GL remains an explicit open domain requiring a separate historical/Finance contract before implementation.

## Assembly

`forensic_main_assembly.yml` is correct:

```yaml
source_of_truth: Current/PWA/main2
historical_reference: Original/PWA/main
forbidden_sources:
  - Current/PWA/main
  - Current/PWA/New-main
assembly_status: deferred_until_all_fragments_are_owner_verified
```

No Assembly has been performed.

## Validation status

```text
GOVERNANCE FULL READ = PASS
REPORT133 FULL READ = PASS
MAIN10 POST-APPLY RECHECK = PASS
MAIN11 FULL SOURCE READ = PASS
MAIN11 EOF = VERIFIED
MAIN11 STATIC STRUCTURAL VALIDATION = PASS
MAIN11 EXECUTABLE NODE CHECK = NOT CLAIMED
MAIN2 TREE RECONCILIATION = PASS
ASSEMBLY PATH = VERIFIED
PRODUCTION HR/CRM FOUNDATION = DEPLOYED
PRODUCTION SCHEMA = VERIFIED
PRODUCTION RPC DEFINITIONS = VERIFIED
PRODUCTION RLS = VERIFIED
PRODUCTION AUDIT TRIGGERS = VERIFIED
PRODUCTION DATA REPAIR = NONE REQUIRED
MAIN11 OWNER APPLY = PENDING
MAIN11 POST-APPLY FULL READ = PENDING
MAIN11 POST-APPLY RUNTIME = PENDING
PAYROLL GL CONTRACT = OPEN
GLOBAL GOLD/DIAMOND = OPEN
```

## Exact next checkpoint

Owner applies the Main11 full replacement package and micro fix to `Current/PWA/main2/main11.md`.

Then re-read Main11 from line 1 to EOF, recompute SHA, run executable syntax validation when the actual file artifact is available, run HR/CRM runtime checks, refresh Production, and only then evaluate Main11 closure.

No Assembly before Main11 post-apply verification and no global Gold/Diamond declaration before all required business capabilities are proven complete.
