# Report479 — إعادة التحقق الجنائي لمعاينة Picker مقابل Loader

**التاريخ:** 2026-10-23  
**المساعد:** Medhat  
**النطاق الوحيد:** استعراض الرانشيت وأصنافه في `companies/company-1/warehouse/picker.html` ليطابق الوظيفة والمستوى المعلوماتي والبصري الحالي في `loader.html` دون تغيير دورة المخزون أو تطبيق Loader.

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** مؤكد من المصدرين أن Picker مسؤول عن المعاينة والتحضير وحفظ مسودة Dexie، بينما Loader يعرض ملخص التحميل ولا ينفذ حركة المخزون بمجرد المعاينة.
- **Architecture Understanding:** مؤكد أن Loader يستخدم `core.js`، بينما Picker الحالي يستخدم Supabase client وDexie مستقلين. لا نعيد هيكلة المصادقة أو دورة التحضير ضمن إصلاح العرض.
- **Database Understanding:** تحقق مباشر للقراءة فقط من Production.
- **Historical Understanding:** Report477 هو changeset الموحّد الذي يحتوي الرقع الكاملة A/A2/B/C/D/E؛ تقارير ما قبله قرائن تاريخية وليست تعليمات متنافسة.
- **Production Understanding:** تم فحص قاعدة Production في نفس دورة العمل؛ لا يوجد سبب مثبت لتغيير Schema/RPC/Edge أو بيانات الأعمال.
- **Current Understanding:** جُلب ملفا Loader وPicker من الفرع الافتراضي، وبصماتهما مطابقة لآخر checkpoint.
- **Execution Confidence:** مرتفع في تشخيص نقص المصدر وعقد البيانات؛ غير مثبت في النشر والمتصفح لأن رقعة المالك لم تُطبق بعد.

### Confirmed Facts

- Application HEAD: `152e5b1d22aab94d2cf01070778b357df4701aff`; parent: `e69c9af4b56d99ba29a4fa74282f78438b9f7010`.
- Loader `companies/company-1/warehouse/loader.html`: blob SHA `97b83d68a683df77c1e0557838c24a1b4fb65169`, 332 lines.
- Picker `companies/company-1/warehouse/picker.html`: blob SHA `d483bd15b36585b975b63c2ef641481a01d5d084`, 1,058 lines.
- Latest operative complete changeset: [Report477 — Picker Preview Parity Master CTO Re-execution](Report477_PICKER_PREVIEW_PARITY_MASTER_CTO_REEXECUTION_20261023.md), blob SHA `1707a3dbbcac68728817aa2b67609f982159ece3`.
- Fresh Production SQL at `2026-10-23 15:01:23.895825+00`, PostgreSQL 17.6: `items=18`, `run_sheet_details=12`, `runsheets=2`; status count `Picked=2` only.
- `items.description` and `items.image_url` exist. `run_sheet_details.description` does not exist.
- FK `run_sheet_details_item_id_fkey`: `run_sheet_details.item_id → items.id`; FK `run_sheet_details_runsheet_id_fkey`: `run_sheet_details.runsheet_id → runsheets.id`.

### Unknowns / Conflicts / Unverified

- **Unknown:** Cloudflare-served HTML parity with current Git blob.
- **Unverified:** owner patch application, Staging runtime, authenticated browser E2E, deployment and served artifact identity.
- **Conflict resolved:** do not apply earlier partial variants from reports 470–476. Report477 remains the sole authoritative owner changeset.
- **No Production defect established:** do not add schema columns or change RPC/Edge just to fix the Picker presentation/query shape.

## Finding

The Loader currently provides a richer runsheet preview: runsheet code/date/status, item count, total prepared quantity, estimated total value, and responsive item cards with item code/name/unit, ordered/prepared quantities, unit price and line value. Its event handlers are attached through JavaScript listeners.

Picker still uses an abbreviated preview block in `App.openRunsheet(code)`: item cards are wired through inline `onclick`, description is read from a nonexistent `run_sheet_details.description` property, and the screen omits visible description and aggregate requested quantity/value. The image renderer and item detail view interpolate values/URLs into HTML without sufficient escaping and URL validation.

## Required surgical change — owner applies it

**Target file:** `erp-frontend/companies/company-1/warehouse/picker.html`  
**Do not edit:** `loader.html`, `main.html`, `core.js`, Production schema/RLS/RPC/Edge or Production business data.

Re-fetch Picker immediately before editing. Apply only the complete changeset in Report477 in this order:

1. **A — App.openRunsheet(code), detail query:** replace `.select('*')` with `.select('*, items!run_sheet_details_item_id_fkey(description)')` in the `run_sheet_details` query, preserving the existing `company_id` scope and surrounding control flow.
2. **A2 — active session mapping:** replace `description: items[i].description || ''` with `description: (items[i].items && items[i].items.description) || ''`.
3. **B — inactive preview block only:** replace the block from its `var html = '';` after the active-session branch through `safeHTML(byId('mainContent'), html);` before the existing promise closures. Use the complete replacement from Report477. It adds escaped content, accurate status labels, item description, responsive details and aggregate quantities/values; uses event listeners instead of inline handlers; and only exposes Start Picking for `Open` or `Confirmed`.
4. **C — App._img(code) only:** use Report477's full safe replacement with URL validation and no inline `onerror`.
5. **D — App.showItemDetail(code, name, unit, qty, desc) only:** use Report477's full replacement with escaped fields and validated image URL.
6. **E — renderActiveSession():** add Report477's specified JavaScript image-error listener after the existing render call, preserving session state and timer behavior.

The complete, copy-ready source and replacements are in Report477; do not reconstruct them from older reports or replace the whole `App.openRunsheet` function. If the Picker SHA has changed or a patch is already present, stop applying that old patch and re-diff the current source first.

## Verification required after owner application

- Static parse of the full script and all replacement blocks.
- Staging cases: `Open`, `Confirmed`, `Picking`, `Picked`, `Loading`; Start Picking only for permitted states.
- Correct item description through `items!run_sheet_details_item_id_fkey(description)`.
- Responsive parity for status/date, item count, ordered/prepared quantities, unit price, line totals and summary totals.
- HTML-like strings, quotes and malformed image URLs render as inert text; broken images degrade safely.
- Back/start actions, empty runsheet, authenticated user, company isolation and Dexie session recovery.
- Before/after proof that `stock_branches.qty`, `allocated_qty` and `inventory_log` do not change during preview.
- Verify Cloudflare-served HTML and run authenticated browser E2E before closure.

## Production changes

**NONE.** The current defect is in the Picker query/presentation layer. Production has no confirmed schema/core defect requiring a write. No test data was created or deleted.

## SELF-AUDIT FINAL

- **What I Proved:** current Git blobs and HEAD/parent; current Production column/FK contract and counts; exact preview mismatch and incorrect description source.
- **What I Did Not Prove:** Cloudflare artifact parity, patch application, Staging behavior, authenticated browser E2E or deployment.
- **What I Fixed:** no operational source was edited, respecting the owner's explicit source-edit responsibility; this report records the current findings and exact authorized surgical path.
- **What I Initially Missed:** prior checkpoints already contained the authoritative complete changeset; re-use Report477 instead of generating competing partial patches.
- **What Could Still Be Wrong:** served HTML may differ from Git; current data lacks Open/Confirmed runsheets for a safe Production start test.
- **Final Confidence:** high for source/database diagnosis; runtime closure remains unverified.
- **Final Closure Status:** `ROOT CAUSE RECONFIRMED / OWNER PATCH READY / NOT APPLIED / DEPLOYMENT UNKNOWN / NOT CLOSED`.
