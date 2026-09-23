
# RAWAEA ERP — تقرير تحقيق جنائي وإغلاق جراحي
## Mother Main — Branch Save / Session Failure
## 2026-09-23

### 1. نطاق التنفيذ
Closure Unit: Mother ERP → المخازن والفروع → إضافة/تعديل فرع → حفظ.

تمت مطابقة التقارير التاريخية مع:
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

لا تعديل للمصدر المملوك للمالك داخل main.html من المساعد.

### 2. آخر حالة مثبتة
System repository:
- HEAD: 69e4b647b929efdd2834cf26273af01e7ee0fe45
- Parent: 1e93304504056cb30809e165db78685b3c66e104

Mother frontend:
- Repository: papamohammed77-glitch/erp-frontend
- HEAD: 6fdcebc551d8eef9a9fd3a8fe8c200d0d4ce90c2
- Parent: 5c4fd658e6046d93ca80db18fb15f2521cc9e4b1
- main.html blob: 7e9e49895bddd1369ac6ead8c00cfcbc172d3603

Relevant main.html update:
- 5c4fd658e6046d93ca80db18fb15f2521cc9e4b1
- Parent: 029aba96b9b6138ee9b388249be2ae723eee4b0b
- restored missing openModal declarations in Customers/Suppliers.
- do not repeat this repair.

### 3. Current Mother Source
RW_Data.loadBranches reads public.branches with company_id = RW_STATE.app.company.id.

RW_Branches.openModal(code):
- line 7055
- save handler line 7079
- getSession line 7084
- POST line 7087

Current modal:
- branch_code readonly
- name
- location
- manager
- phone
- status

No Physical Stock mutation exists in this tab.

### 4. Production Reality
save-branch:
- Version 5
- ACTIVE
- verify_jwt = true
- deployment id: b289cefd-6875-4c2b-8970-395f223a14cb
- deployment evidence: 2026-09-23 14:23:35 UTC

Current Production actor:
- auth_id = 0a6089e6-0c33-4cf9-9aa0-31fc42774b89
- email = owner@alrawae.com
- company_id = 00000000-0000-0000-0000-000000000001
- status = Active
- permissions = ["*"]

Current public.users schema has no is_owner.

Version 5:
- Authorization validation
- auth user validation
- users.auth_id lookup
- company_id resolution
- Inactive rejection
- * / branches permission guard
- company-scoped Branch reads/writes

### 5. Runtime Forensics
Observed POST 400s were all on Version 4:
- 2026-09-23 13:09:04 UTC
- 2026-09-23 13:09:29 UTC
- 2026-09-23 13:22:07 UTC
- 2026-09-23 13:22:42 UTC
- 2026-09-23 13:24:05 UTC

After Version 5, current runtime evidence contains no new POST 400 of this same pattern; the available Version 5 evidence is OPTIONS 200.

Classification:
- Historical Version 4 defect = CLOSED / PROVEN
- Current Production Version 5 defect = NOT PROVEN

### 6. Current Source Defect
Current Branch Save obtains an access token with getSession and immediately sends it.

That path does not:
- inspect expires_at
- refresh an expiring token
- retry once on auth rejection
- distinguish missing/expired session from business/server errors

Real current-source failure mode:
stale/expired access token
→ save-branch
→ db.auth.getUser(token)
→ جلسة غير صالحة

Console text "Session restored" proves presence of a session object only; it does not prove token validity at the moment of Save.

The exact latest user click cannot be independently classified as a Version 5 runtime failure because that POST is not present in the available Version 5 log window.

### 7. Production Decision
No save-branch Production change was necessary in this cycle.

No new Edge Function.
No new RPC.
No Branch schema change.
No Branch data repair.

### 8. Production Database Test
Transaction test:
CREATE → UPDATE → DELETE → ROLLBACK

QA code:
QA-BR-923

Result:
PASS

After rollback:
- QA rows = 0
- branches = 3

### 9. Owner Surgical Patch
File:
papamohammed77-glitch/erp-frontend/companies/company-1/main.html

Current SHA:
7e9e49895bddd1369ac6ead8c00cfcbc172d3603

Function:
RW_Branches.openModal(code)

Exact element:
lines 7083–7092

Search exactly for:
~~~javascript
showLoader('جاري الحفظ...');
const { data: { session } } = await supabase.auth.getSession();
const token = session?.access_token;
try {
    const res = await fetch(RW_SUPABASE_URL + '/functions/v1/save-branch', { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + token }, body: JSON.stringify({ branch: payload, isEdit, branch_code: b?.branch_code }) });
    const json = await res.json();
    hideLoader();
    if (json.success) { showToast(isEdit ? 'تم التعديل' : 'تمت الإضافة', 'success'); Swal.close(); data = await RW_Data.loadBranches(); renderTable(data); }
    else { showToast(json.error || 'فشل الحفظ', 'error'); }
} catch(e) { hideLoader(); showToast('فشل الاتصال بـ Edge Function', 'error'); console.error(e); }
~~~

Delete that block completely.

Replace it completely with:
~~~javascript
showLoader('جاري الحفظ...');
try {
    let sessionRes = await supabase.auth.getSession();
    let session = sessionRes && sessionRes.data
        ? sessionRes.data.session
        : null;

    const nowSec = Math.floor(Date.now() / 1000);
    const expiresAt = session && session.expires_at
        ? Number(session.expires_at)
        : 0;

    if (
        !session ||
        !session.access_token ||
        (expiresAt && expiresAt <= nowSec + 60)
    ) {
        const refreshRes = await supabase.auth.refreshSession();

        if (refreshRes.error) {
            throw refreshRes.error;
        }

        session = refreshRes && refreshRes.data
            ? refreshRes.data.session
            : null;
    }

    if (!session || !session.access_token) {
        hideLoader();
        showToast(
            'انتهت جلسة الدخول، يرجى تسجيل الدخول مرة أخرى',
            'error'
        );
        return;
    }

    const doSaveRequest = async function(accessToken) {
        const response = await fetch(
            RW_SUPABASE_URL + '/functions/v1/save-branch',
            {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    Authorization: 'Bearer ' + accessToken
                },
                body: JSON.stringify({
                    branch: payload,
                    isEdit,
                    branch_code: b?.branch_code
                })
            }
        );

        const body = await response.json().catch(function() {
            return {};
        });

        return {
            response: response,
            body: body
        };
    };

    let result = await doSaveRequest(session.access_token);
    let json = result.body;

    const authMessage = String(
        json?.error ||
        json?.msg ||
        ''
    ).trim();

    const authFailure =
        !result.response.ok &&
        (
            authMessage === 'جلسة غير صالحة' ||
            authMessage === 'غير مصرح'
        );

    if (authFailure) {
        const refreshRes = await supabase.auth.refreshSession();

        if (
            refreshRes.error ||
            !refreshRes.data ||
            !refreshRes.data.session ||
            !refreshRes.data.session.access_token
        ) {
            hideLoader();
            showToast(
                'انتهت جلسة الدخول، يرجى تسجيل الدخول مرة أخرى',
                'error'
            );
            return;
        }

        session = refreshRes.data.session;

        result = await doSaveRequest(session.access_token);
        json = result.body;
    }

    hideLoader();

    if (json && json.success) {
        showToast(
            isEdit ? 'تم التعديل' : 'تمت الإضافة',
            'success'
        );

        Swal.close();

        data = await RW_Data.loadBranches();
        renderTable(data);
    } else {
        showToast(
            (json && (json.error || json.msg)) ||
            'فشل الحفظ',
            'error'
        );
    }
} catch(e) {
    hideLoader();

    const message = String(
        e?.message || ''
    ).trim();

    if (
        message === 'Auth session missing!' ||
        message === 'Invalid Refresh Token: Refresh Token Not Found'
    ) {
        showToast(
            'انتهت جلسة الدخول، يرجى تسجيل الدخول مرة أخرى',
            'error'
        );
    } else {
        showToast(
            message || 'فشل الاتصال بـ Edge Function',
            'error'
        );
    }

    console.error(e);
}
~~~

Do not modify:
- modal fields
- nextBranchCodePreview
- renderTable
- RW_Data.loadBranches
- delete-branch
- Customers/Suppliers openModal
- Fleet/Vehicle semantics

### 10. Static Verification
Current exact main.html blob:
7e9e49895bddd1369ac6ead8c00cfcbc172d3603

Full current inline script parse:
PASS

INLINE_SCRIPT_1 = PASS
chars = 1705047

Current syntax closure:
- Customer openModal line 6772
- Supplier openModal line 6917
- Branch openModal line 7055

### 11. Mother Integration
Mother Auth
→ RW_STATE.app.company.id
→ RW_Data.loadBranches
→ RW_Branches
→ save-branch
→ public.branches
→ Orders / Runsheets / Inventory / Vouchers / Finance / HR / Vehicle Contexts

Branch remains master/control data.
Operational PWAs remain consumers/executors.
No second Branch Master introduced.

### 12. Competitive Forensic Study
Odoo 19:
- hierarchical locations
- parent location
- location type
- company
- barcode
- replenishment
- inventory frequency
- removal strategy
- location/movement reporting

Official:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/inventory_management/use_locations.html
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/reporting/locations.html
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/reporting/moves_history.html

Microsoft Dynamics 365 Business Central:
- Location Card
- warehouse policies
- bins/zones
- default dimensions
- location/transfer processing

Official:
https://learn.microsoft.com/en-ca/dynamics365/business-central/inventory-how-setup-locations

SAP S/4HANA:
- Storage Location differentiates stock inside a plant.
- storage-location-specific master data is supported.

Official:
https://help.sap.com/docs/SAP_S4HANA_CLOUD/f86dc2eb1f8b48c880a7607213104b27/a914c453f57eb44ce10000000a174cb4.html

Manager.io:
- inventory locations
- inactivation
- use in sales/purchases
- inventory transfers

Official:
https://www2.manager.io/guides/10677

### 13. Future Branch Master 2.0 — NOT IMPLEMENTED
Candidate future features:
- branch type
- region
- GPS
- operating hours
- contact email
- location barcode
- capacity
- warehouse capability profile
- replenishment policy
- receiving/picking profile
- default financial dimension/cost center
- transfer policy
- operational calendar

Not implemented because the current business contract does not yet prove they are required in this closure.

### 14. E2E Classification

PASS:
- System Git HEAD/Parent
- Frontend HEAD/Parent
- main.html SHA
- full inline-script parse
- Production save-branch v5 inspection
- users schema
- current actor
- branch trigger
- transactional Branch CREATE/UPDATE/DELETE/ROLLBACK
- QA residue

OPEN:
- authenticated live Browser E2E
- served artifact identity after owner-side publication

Reason:
No authenticated browser tool is available in this session.

### 15. Closure
Historical Version 4 save-branch defect:
CLOSED

Production Version 5:
VERIFIED CURRENT

Current Mother Branch Save auth-freshness defect:
FOUND / OWNER PATCH READY

Production data:
VERIFIED

Branch integration:
PRESERVED

Browser runtime:
OPEN pending owner patch + publish + authenticated E2E

No 100% runtime claim is made before browser evidence.

### 16. NEXT SESSION — ابدأ من هنا
1. Read this report.
2. Verify frontend HEAD 6fdcebc551d8eef9a9fd3a8fe8c200d0d4ce90c2.
3. Verify main.html SHA 7e9e49895bddd1369ac6ead8c00cfcbc172d3603.
4. Search RW_Branches.openModal for the Section 9 block.
5. Delete that block only.
6. Paste the replacement block completely.
7. Parse full main.html.
8. Commit frontend.
9. Publish.
10. Verify served artifact identity.
11. Login with a fresh session.
12. Mother → المخازن والفروع → إضافة فرع → حفظ.
13. Verify successful save-branch POST.
14. Verify branch data refresh.
15. Test Edit.
16. Test Inactive status.
17. Inspect save-branch logs.
18. If a new failure appears, record timestamp + deployment version + auth subject + exact response before any new decision.
19. Update CURRENT_STATE.
20. Do not reopen Report320/321 closures without contradictory evidence.

### 17. FINAL SELF-AUDIT
What I Proved:
- current source syntactically valid.
- prior syntax closure already applied.
- Production save-branch v5 is current and schema-compatible.
- historical 400s were Version 4.
- current Branch save handler lacks token freshness/retry protection.
- Branch database contract is healthy.

What I Did Not Prove:
- exact latest user click produced a Version 5 400.
- authenticated live browser E2E.
- served artifact after owner-side publication.

What I Fixed:
- no unnecessary Production change.
- exact surgical owner patch prepared.

What Could Still Be Wrong:
- stale served frontend.
- stale browser session.
- new Version 5 runtime defect not yet captured.

Final:
MOTHER BRANCH SAVE = PARTIALLY CLOSED
