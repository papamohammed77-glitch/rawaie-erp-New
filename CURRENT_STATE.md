# RAWAEA ERP — CURRENT STATE

**Last verified:** 2026-09-12
**Current checkpoint:** Report136 completed the post-merge forensic review of the published system-parent file. The eleven fragments are no longer the Source of Truth. The published `erp-frontend/companies/company-1/main.html` is the authoritative current target. Structural validation passes, but JavaScript syntax is not yet closed. Owner correction is required before helper-file integration or Gold/Diamond closure.

## CRITICAL GOLD / DIAMOND MISSION

**هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا نتعامل معه كإضافات شكلية. وهذا متسق حرفيًا مع مبدأ الحوكمة: الدراسة أولًا، ثم إعادة بناء العقد التاريخي، ثم تتبع السلوك الحالي، ثم تحديد الفجوة، ثم التعديل الجراحي، ثم الاختبار والتحقق.**

## Current Source of Truth

```text
erp-frontend/companies/company-1/main.html
```

Current verified identity:

```text
Blob SHA = 327e2d966d1520c1391a0b0dc72cc0352f944ca7
SHA256   = 64211035d623a75e17d2452e2c2f5916230dd00b5e9d0e9439b9515188e98294
Lines    = 17,415
Bytes    = 933,355
EOF      = </script> / </body> / </html>
```

Historical/reference only:

```text
rawaie-erp-New/Current/PWA/main2/main1..main11.md
rawaie-erp-New/Original/PWA/main/*
rawaie-erp-New/Current/PWA/main/*
rawaie-erp-New/Current/PWA/New-main/*
```

They must not be used as reconstruction Source of Truth for the published main file.

## Governance

- Study before modification.
- Historical contract before behavioral change.
- Production claims must be checked against current Production.
- No global replacement when surgical repair is possible.
- Owner performs `main.html` edits.
- Assistant performs proven Production DB/Edge changes.
- No closure claim without actual runtime verification.

## Report136 — Published Main Forensic Recheck

`doc/Draft/Reprots/Report136_Published_Main_Forensic_Recheck_20260912.md`

Confirmed full-file results:

```text
HTML_OPEN/CLOSE   = 1/1
HEAD_OPEN/CLOSE   = 1/1
BODY_OPEN/CLOSE   = 1/1
STYLE_OPEN/CLOSE  = 1/1
SCRIPT_OPEN/CLOSE = 6/6
INCOMPLETE_MARKERS = []
DIRECT_PHYSICAL_WRITERS = []
```

JavaScript syntax is still OPEN. Confirmed source repairs:

```text
1971
2278
2283
2311
2316
4806
4904
4908
9010
11142
14457
14572–14574
16221–16223
16569
16574
```

The full current replacement lines/blocks are documented in Report136.

### Important non-global rule

Do not replace all `\\'` or `\'` occurrences. Many are correct. At line 9010, the regex literal `.replace(/'/g, "\\'")` is valid and must remain unchanged; only the malformed generated `onclick` escaping is repaired.

## Validation status

```text
PUBLISHED MAIN SOURCE VERIFIED = PASS
FULL FILE SIZE/EOF VERIFIED = PASS
HTML STRUCTURE = PASS
INCOMPLETE MARKERS = PASS
NODE CHECK ORIGINAL = FAIL
OWNER MAIN.HTML REPAIR = PENDING
MAIN HTML DEPLOYMENT BY ASSISTANT = NONE
PRODUCTION DB/EDGE CHANGE FOR THIS FRONTEND CHECKPOINT = NONE
HELPER FILE INTEGRATION = DEFERRED
ASSEMBLY CLOSURE = NO
GOLD/DIAMOND CLOSURE = NO
```

## Assembly governance

`rawaie-erp-New/.github/workflows/forensic_main_assembly.yml` now performs published-file verification only. It no longer reconstructs the published file from the eleven fragments or `New-main`.

Permanent published-file gate:

`erp-frontend/.github/workflows/cto_main_html_forensic_20260912.yml`

Its contract is to inspect the original published file itself and fail until actual syntax is valid.

## Helper files

Do not advance to:

```text
Current/PWA/core.js
Current/PWA/sw.js
Current/PWA/register-sw.js
Current/PWA/manifest.json
```

until the owner repairs `main.html` and the fresh original-source syntax gate passes.

## Functional closure

Not yet proven. Syntax success will only unlock the next stage. Gold/Diamond functional closure still requires integrated verification of inventory, order lifecycle, runsheet order-by-order fulfillment, loading, delivery, refusal/return, counting, field applications, finance, HR, CRM, reports, and real-time synchronization.

## Next exact checkpoint

1. Apply only the exact Report136 owner repairs to the published `erp-frontend/companies/company-1/main.html`.
2. Re-read the published file from first byte to EOF.
3. Recompute SHA/line count.
4. Run the permanent published-main forensic gate on the original source.
5. Stop again on any remaining syntax error.
6. Only after syntax PASS begin helper-file integration and functional/E2E verification.

# END CURRENT STATE
