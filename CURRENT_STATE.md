# RAWAEA ERP — CURRENT STATE

**Last verified:** 2026-09-12
**Current checkpoint:** Main11 post-Owner-Apply forensic recheck completed against current Git and current Production. Main11 is functionally upgraded in HR/CRM, the attendance datetime micro-fix is present, and the remaining confirmed source defect is isolated to leave-status approval actor handling. Production has been corrected with Session-derived actor enforcement. Assembly remains deferred.

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
- Assembly remains deferred until the eleven fragments are owner-verified and the integrated gates pass.

## Gold / Diamond Mission — NON-NEGOTIABLE

**هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا يُتعامل معه كإضافات شكلية.**

وهذا متسق حرفيًا مع مبدأ الحوكمة: **الدراسة أولًا، ثم إعادة بناء العقد التاريخي، ثم تتبع السلوك الحالي، ثم تحديد الفجوة، ثم التعديل الجراحي، ثم الاختبار والتحقق.**

أي تبويب أو وظيفة هيكلية فقط لا يُعتبر مكتملًا.

## Source of Truth

`Current/PWA/main2/main1.md` … `Current/PWA/main2/main11.md`

Historical reference only:
`Original/PWA/main/*`

Forbidden / retired:
`Current/PWA/main/*`
`Current/PWA/New-main/*`

`forensic_main_assembly.yml` verified correct:

```yaml
source_of_truth: Current/PWA/main2
historical_reference: Original/PWA/main
forbidden_sources:
  - Current/PWA/main
  - Current/PWA/New-main
assembly_status: deferred_until_all_fragments_are_owner_verified
```

## Current Fragment Git SHAs — direct reconciliation

- main1 `f68d47c7574c34f678cfba2aafa5ad294aadbfe5`
- main2 `65815e23b03e29c125957e6fe283cc1e253a7f7d`
- main3 `eeb56daf8cd01b31b8a7e5f5ada4f1a09df30bfe`
- main4 `e9f967859aeda729cd0811739a280ceec5266d7c`
- main5 `800ad51c88a2e80d060480990836a3c975c7435a`
- main6 `1dc500849a600e6436c1d319bdc93f3d270f6af9`
- main7 `5839252a9807ae1758939dad754a4f3a4505c76f`
- main8 `f67c0217a804d2cb2388ce48fb7f95176c075fb3`
- main9 `b68e5d8f0f52258080950add12fd7fcecbf8c0d7`
- main10 `a6d078d450f1a2182abff0eaf515b6861e66092b`
- main11 `c4c954e9610c60182358a42665195d05cd3c3405`

## Latest Main11 Records

- `Report134_Main11_Forensic_Recheck_20260912.md` — historical/stale checkpoint for Main11 before current Owner Apply.
- `Report135_Main11_Forensic_Recheck_20260912.md` — current forensic recheck and closure record for this session.
- `MAIN11_OWNER_SURGICAL_REPLACEMENTS_20260912.js` — original full Owner replacement package.
- `MAIN11_OWNER_MICRO_FIX_20260912.js` — datetime-local conversion correction; now present in Current Main11.
- `MAIN11_OWNER_CORRECTION_R2_20260912.js` — exact remaining Owner correction for leave approval.
- `supabase/migrations/20260912000000_main11_hr_crm_gold_capabilities.sql` — Main11 HR/CRM foundation.
- `supabase/migrations/20260912090311_main11_hr_leave_approval_actor_scope_20260912.sql` — Production actor-safe leave approval and HR write hardening.
- `supabase/migrations/20260912090431_main11_hr_employee_list_include_inactive_20260912.sql` — Production employee-total semantics correction.
- `.github/workflows/_cto_forensic_main2_syntax_20260912.yml` — permanent Current/main2 syntax/structural gate.

## Main10

- Current SHA `a6d078d450f1a2182abff0eaf515b6861e66092b`.
- R3 Owner Apply present and rechecked.
- No new Main10 patch required in this cycle.
- Main10 still awaits integrated executable/E2E closure before being called fully closed.

## Main11 — Current Authoritative State

### Direct Git facts

- Path: `Current/PWA/main2/main11.md`
- SHA: `c4c954e9610c60182358a42665195d05cd3c3405`
- Size: `43413 bytes` at direct Git reconciliation time.
- Full content read performed through current EOF.
- Ranges after the closing HTML were empty.
- Current ending is `</script>` → `</body>` → `</html>`.

### Historical comparison

`Original/PWA/main/main11.md` confirms the old HR implementation was a `users.*` browser read and contained inherited salary/document placeholders and inline event patterns. This establishes historical context; it does not justify preserving obsolete implementation details.

### Current HR capability

Current Main11 now uses:

- `hr_list_employees()` safe read model.
- `employee_profiles` for compensation/employee profile data.
- `employee_attendance` for attendance.
- `employee_leave_requests` for leave workflow.
- `employee_documents` + private storage for employee documents.
- Company-scoped reads.
- Explicit error/empty states.
- Direct event binding.
- Current datetime-local conversion:

```js
var toISO=function(id){var v=byId(id).value;return v?new Date(v).toISOString():null;};
```

The previous hard-coded `+03:00` conversion is not present.

### Current CRM capability

Current Main11 now uses:

- `customersData` as the unit-local loaded source.
- Company-scoped customer reads.
- Local search against the same loaded source.
- Direct event binding rather than inline `onclick` for followup actions.
- Followup history.
- `crm_save_customer_followup()` for canonical write.
- `customer_followups.customer_id` verified as `text`; use of `customer_code` is consistent with the current schema.

## Confirmed remaining Main11 source defect

### M11-03 — `_setLeaveStatus` actor is browser-controlled

Current source around line 256 contains:

```js
async function _setLeaveStatus(id,status,emp) {
    var currentUser=(RW_STATE&&RW_STATE.app&&RW_STATE.app.currentUser)||{};
    var res=await supabase.from('employee_leave_requests').update({status:status,approved_by:currentUser.email||'',approved_at:new Date().toISOString()}).eq('id',id).eq('company_id',_companyId());
    if(res.error){showToast('فشل تحديث الإجازة: '+res.error.message,'error');return;}
    showToast(status==='approved'?'تم اعتماد الإجازة':'تم رفض الإجازة','success');
    _openModal(emp.id);
}
```

This is the only confirmed Main11 source correction generated in this cycle after the current Owner Apply.

## Exact Owner Action

File:
`Current/PWA/main2/main11.md`

Search for the element beginning exactly with:

`async function _setLeaveStatus(id,status,emp) {`

Delete the complete function through its closing `}` immediately before:

`async function _uploadDocument(emp) {`

Replace with:

```js
    async function _setLeaveStatus(id,status,emp) {
        var res=await supabase.rpc('hr_set_leave_status',{
            p_leave_request_id:id,
            p_status:status,
            p_notes:null
        });
        if(res.error){showToast('فشل تحديث الإجازة: '+res.error.message,'error');return;}
        showToast(status==='approved'?'تم اعتماد الإجازة':'تم رفض الإجازة','success');
        _openModal(emp.id);
    }
```

Do not delete or modify `async function _uploadDocument(emp) {`.

## Production — verified current changes

Production latest migration sequence relevant to Main11:

```text
20260912090431  main11_hr_employee_list_include_inactive_20260912
20260912090311  main11_hr_leave_approval_actor_scope_20260912
20260912083643  main11_hr_crm_gold_capabilities_20260912
```

Production now contains/uses:

- `employee_profiles`
- `employee_attendance`
- `employee_leave_requests`
- `hr_list_employees()`
- `hr_set_leave_status(...)`
- `hr_save_attendance(...)`
- `hr_upsert_employee_profile(...)`
- `hr_create_leave_request(...)`
- `crm_save_customer_followup(...)`

`hr_set_leave_status` is `SECURITY DEFINER` and derives actor/company from the authenticated Session. It rejects unsupported target statuses and rejects changing a non-pending request.

`hr_save_attendance` and `hr_upsert_employee_profile` were hardened so actor identity is Session/Company-derived and `updated_at` is maintained on update paths.

`hr_list_employees` now returns all company employees; the UI calculates active employees separately, preserving the distinction between total and active counts.

## Production data

No destructive data repair was justified by proven evidence in the Main11 domain.

At latest direct checks, `employee_leave_requests` count = `0`.

Previous established counts remain:

- `users = 24`
- `customers = 3`
- `customer_followups = 0`
- `employee_documents = 0`

No users, customers, documents, or operational records were deleted or rewritten.

## RLS / Audit

RLS for the new HR tables is tied to:

- `app_private.current_user_company_id()`
- `app_private.current_user_has_permission('hr')`

The new HR tables have audit triggers using `fn_audit_trigger()`.

The employee document bucket remains private and Company-scoped.

## Syntax / Validation Infrastructure

Direct Main11 structural verification passed:

- one `RW_HR` declaration.
- one `window.RW_HR = RW_HR;`.
- one `RW_CRM` declaration.
- one `window.RW_CRM = RW_CRM;`.
- current micro-fix present.
- `(قيد التطوير)` absent from current Main11 source.
- current EOF contains ordered `</script>`, `</body>`, `</html>`.

A permanent GitHub Actions workflow was added:

`.github/workflows/_cto_forensic_main2_syntax_20260912.yml`

It assembles `Current/PWA/main2/main1..main11.md` using the source boundary defined for the system and executes `node --check`, plus Main11 structural assertions.

The workflow result itself is not considered PASS until its actual GitHub Actions run has completed; creating the gate is not evidence of execution success.

## Assembly

No Assembly has been performed.

`forensic_main_assembly.yml` remains correct and points only to `Current/PWA/main2`.

## Payroll boundary

No Production Payroll-to-GL contract or Payroll chart-of-account mapping has been proven. No payroll posting logic was invented.

## Validation Status

```text
GOVERNANCE READ = PASS
REPORT133 REVIEW = PASS
REPORT134 REVIEW = PASS (historical checkpoint, not current truth)
MAIN11 CURRENT GIT RECONCILIATION = PASS
MAIN11 FULL SOURCE READ = PASS
MAIN11 EOF = VERIFIED
MAIN11 MICRO FIX = PRESENT
MAIN11 HR CAPABILITY = PRESENT
MAIN11 CRM CAPABILITY = PRESENT
MAIN11 M11-03 SOURCE DEFECT = CONFIRMED
PRODUCTION HR/CRM FOUNDATION = DEPLOYED
PRODUCTION LEAVE APPROVAL ACTOR RPC = DEPLOYED
PRODUCTION EMPLOYEE LIST SEMANTICS = CORRECTED
PRODUCTION RLS = VERIFIED
PRODUCTION AUDIT = VERIFIED
MAIN2 TREE = VERIFIED
ASSEMBLY PATH = VERIFIED
PERMANENT MAIN2 SYNTAX GATE = ADDED
NODE/INTEGRATED RUNTIME PASS = NOT YET CLAIMED
OWNER M11-03 APPLY = PENDING
MAIN11 FULLY CLOSED = NO
ASSEMBLY = DEFERRED
PAYROLL GL CONTRACT = OPEN
GLOBAL GOLD/DIAMOND = OPEN
```

## Exact Next Checkpoint

1. Owner applies only `M11-03` above to `Current/PWA/main2/main11.md`.
2. Re-read Main11 from first byte to EOF.
3. Recompute current Main11 SHA.
4. Run the permanent Main2 syntax gate and capture its actual result.
5. Execute available HR/CRM runtime verification.
6. Refresh Production snapshot immediately before any closure report.
7. Verify data/RLS/audit and cross-module consumers.
8. Only after these gates pass, evaluate Main11 Closure Gate.
9. Assembly stays deferred until Main11 and the remaining fragments satisfy their gates.

# END CURRENT STATE
