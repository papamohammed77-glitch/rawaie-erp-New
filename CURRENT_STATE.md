# RAWAEA ERP — CURRENT STATE

**Last verified:** 2026-09-12
**Current checkpoint:** Report137 completed a fresh forensic recheck against the current published `erp-frontend/companies/company-1/main.html` after changes that occurred after Report136. The published main remains the authoritative Source of Truth. Structural gates pass; JavaScript syntax remains OPEN at the current live failure on line 2278. The owner must apply only the exact remaining surgical repairs documented in Report137 before the next syntax gate.

## CRITICAL GOLD / DIAMOND MISSION

**هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا نتعامل معه كإضافات شكلية. وهذا متسق حرفيًا مع مبدأ الحوكمة: الدراسة أولًا، ثم إعادة بناء العقد التاريخي، ثم تتبع السلوك الحالي، ثم تحديد الفجوة، ثم التعديل الجراحي، ثم الاختبار والتحقق.**

## Current Source of Truth

```text
erp-frontend/companies/company-1/main.html
```

Current verified identity from the latest forensic Action run:

```text
Git HEAD = cfd9801b13b5601fe5d13777a20bf4f2f9a0eff7
SHA256   = 3d60ffd0b85537fcef6e2941081b6b01ea5568f2ae071cdc38c45dd7f02ab885
Lines    = 17,415
Bytes    = 933,483
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
- Current Production/source must be verified before claims.
- No global replacement when surgical repair is possible.
- Owner performs `main.html` edits.
- Assistant performs proven Production DB/Edge changes.
- No closure claim without actual runtime/syntax verification.
- Reports are evidence/search aids, not current truth.

## Report136 vs Current Reality

Report136 recorded a 15-item syntax repair set. A fresh check against the current source proved that two items are already correct:

```text
1971 = correct in current source
9010 = correct in current source
```

They must not be changed again.

The remaining owner repair set is documented in:

`doc/Draft/Reprots/Report137_Published_Main_Current_Forensic_Syntax_20260912.md`

Remaining items:

```text
2278
2283
2311
2316
4806
4904
4908
11142
14457
14572–14574
16221–16223
16569
16574
```

## Latest Live Forensic Result

Latest known `erp-frontend` forensic workflow:

```text
Run        = 34689230824
Commit     = cfd9801b13b5601fe5d13777a20bf4f2f9a0eff7
Conclusion = failure
```

The structural gate passed:

```text
HTML_OPEN/CLOSE   = 1/1
HEAD_OPEN/CLOSE   = 1/1
BODY_OPEN/CLOSE   = 1/1
STYLE_OPEN/CLOSE  = 1/1
SCRIPT_OPEN/CLOSE = 6/6
INCOMPLETE_MARKERS = []
DIRECT_PHYSICAL_WRITERS = []
```

The exact current syntax failure is:

```text
/tmp/main-positioned.js:2278
SyntaxError: Invalid or unexpected token
```

The failure source is the doubled escaping inside the generated `onclick` string at line 2278.

## Assembly governance

`rawaie-erp-New/.github/workflows/forensic_main_assembly.yml` is currently aligned with the correct Source of Truth:

```text
https://raw.githubusercontent.com/papamohammed77-glitch/erp-frontend/main/companies/company-1/main.html
```

It is a verification gate only and does not reconstruct or overwrite the published main from historical fragments.

`erp-frontend/.github/workflows/cto_main_html_forensic_20260912.yml` is the permanent gate that reads and validates the published file itself.

No workflow path change is required at this checkpoint.

## Owner/Main HTML Rule

The assistant must not edit:

```text
erp-frontend/companies/company-1/main.html
```

The owner applies the exact delete/replace instructions from Report137. Each requested replacement is a complete line/block with an identifiable line number and endpoint.

## Helper Files

Do not advance to:

```text
Current/PWA/core.js
Current/PWA/sw.js
Current/PWA/register-sw.js
Current/PWA/manifest.json
```

until the published main passes the original-source syntax gate.

## Functional Completion Status

Still OPEN.

Syntax success is only a gate. Gold/Diamond functional completion still requires integrated validation of:

```text
Inventory
Order lifecycle
Runsheet order-by-order fulfillment
Picking
Loading
Delivery
Refusal / Return
Unloading
Counting / Inventory Count
Field applications
Purchasing
Finance
HR
CRM
Reports
Real-time synchronization
Cross-module consistency
```

The requirement that these modules become functionally complete rather than merely structural remains the ultimate mission and is not satisfied by this syntax checkpoint.

## Production

No Production DB/Edge modification is required for the current `main.html` syntax checkpoint.

Any Production work must continue to use current Production evidence first and must be documented separately.

## Next Exact Checkpoint

```text
OWNER APPLIES Report137 REMAINING REPAIRS
→ RE-READ PUBLISHED main.html FROM FIRST BYTE TO EOF
→ RECOMPUTE SHA256 / BYTES / LINES
→ RUN cto_main_html_forensic_20260912.yml
→ RUN ORIGINAL-SOURCE NODE CHECK
→ IF FAIL: ISSUE NEXT EXACT OWNER CHANGESET
→ IF PASS: START HELPER FILE INTEGRATION
```

## Closure Status

```text
PUBLISHED SOURCE VERIFIED       = PASS
STRUCTURAL VALIDATION            = PASS
INCOMPLETE MARKERS               = PASS
DIRECT PHYSICAL WRITER SCAN      = PASS
JAVASCRIPT SYNTAX                = OPEN
OWNER CHANGESET                  = PENDING
HELPER INTEGRATION               = BLOCKED BY SYNTAX
ASSEMBLY CLOSURE                 = NO
GOLD/DIAMOND FUNCTIONAL CLOSURE  = NO
```

# END CURRENT STATE
