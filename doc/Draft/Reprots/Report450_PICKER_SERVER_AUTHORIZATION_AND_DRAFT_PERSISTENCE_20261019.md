# Report450 — Picker Server Authorization Hardening and Draft Persistence Follow-up
**Date:** 2026-10-19  
**Scope:** erp-frontend/companies/company-1/warehouse/picker.html integration with RAWAEA Production identity, permissions, picking lifecycle, and derived inventory contracts.  
**Constraint respected:** main.html and the operational picker.html were not edited. No Production business rows were inserted, updated, or deleted. Four existing Production Edge Functions were surgically hardened; no new function was created.

## 1. PRE-CHANGE SELF-AUDIT

- **Business understanding:** Picking assigns a runsheet to a picker, records picked quantities, reserves stock, and prepares the runsheet for Loading. Picking is not physical stock movement.
- **Architecture understanding:** PWA → authenticated Edge Function → service-role client → restricted SECURITY DEFINER core RPC → database. The parent app remains the permission/navigation control plane; the PWA cannot be trusted as the only authorization layer.
- **Database understanding:** public.users.id is the application identity; public.users.auth_id links to auth.users.id. Direct permission arrays and role permission arrays are both supported. The owner wildcard is valid only under the verified owner contract.
- **Historical understanding:** Original picker baseline is blob 7626ba320021a607854bf219f4bacd81fc3d1d92 in both rawaie-erp-review/PWA/warehouse/picker.html and rawaie-erp-New/Original/PWA/warehouse/picker.html. It is a historical baseline, not current truth.
- **Production understanding:** Live Production was read before the change. The four functions were active with JWT verification enabled. Their prior versions were start-picking v34, complete-picking v17, cancel-picking v4, reopen-picking v8.
- **Current understanding:** Operational picker was fetched in full: 925 lines, blob c7ad267d852d415b680aed7716833eea9bcffdf6. The latest picker-specific commit found by GitHub commit search was 703342f4fadb046388bcdeb826b4911167c96b67 (2026-08-17); more recent repository commits were unrelated to picker.
- **Execution confidence before change:** High for the authorization bypass and ignored direct-write defect; medium for browser/runtime behavior because an authenticated E2E fixture was not proven safe.

### Confirmed facts
1. The four Edge Functions use a service-role client, so UI-only permission checks are bypassable by direct HTTP calls unless the Edge layer independently authorizes the user.
2. Before this change, the four Production handlers verified identity/company/status but did not enforce the picker’s warehouse permission and active تحضير role on the server.
3. Production app_private.current_user_has_permission('warehouse') accepts direct user permission or role permission; its owner branch additionally requires auth.users.raw_user_meta_data.isOwner=true, public.users.permissions containing *, and an owner_profile row for that auth user.
4. Production grants authenticated users SELECT but not UPDATE on run_sheet_details. The picker’s line 643 attempts an UPDATE and ignores the result.
5. public.sync_run_sheet_details() is triggered by INSERT/UPDATE/DELETE on order_details and rebuilds the matching run_sheet_details projection from authoritative order-detail values, including qty_picked.
6. complete_runsheet_picking(..., p_operation_id uuid DEFAULT NULL) is the transactional picking completion contract: it validates company/runsheet/items, calls reserve_stock, updates order_details.qty_picked, sets status Picked, and does not write a physical inventory movement log.

### Unknowns / conflicts / unverified claims
- **UNVERIFIED:** Served Cloudflare HTML byte parity with the GitHub picker source.
- **UNVERIFIED:** Authenticated browser E2E for allowed picker, denied non-warehouse user, denied wrong active role, cancel, complete, and reopen after deployment.
- **UNVERIFIED:** End-user draft recovery across browser restart until the owner applies and tests the local Dexie patch below.
- Supabase unified-log query returned a backend error; no log conclusion is drawn from it.
- Production currently has two Open runsheets. They were treated as live business work and were not used as test fixtures.

## 2. Production authorization repair — executed

Applied the same narrow authorization contract to the four existing Edge Functions. No new Edge Function and no database schema change were created.

Server-side checks now:
1. Resolve the authenticated user through auth.users.id → public.users.auth_id.
2. Require the application user to exist in a company and not be inactive.
3. Load role permissions when role_id exists.
4. Accept warehouse only from public.users.permissions, the assigned role’s permissions, or the verified owner contract.
5. For non-owner users, require active_warehouse_role = 'تحضير'.
6. Fail closed if role/owner permission lookup errors occur.

This mirrors the existing application/database permission model instead of trusting client-side metadata alone. The core RPCs remain non-executable by anon/authenticated; the Edge → service_role → core boundary is preserved.

### Live deployment evidence

| Function | Before | After | verify_jwt | Production ezbr_sha256 after deploy |
|---|---:|---:|---|---|
| start-picking | v34 | **v35** | true | fca0377fce2d02d52a17bdbbdd98cfe9cc449d052533df0a3b021be11c79914a |
| complete-picking | v17 | **v18** | true | 14b4d650253e73abc7c7a1b1f25a8674849c11e32d21ae9928701f19705b0537 |
| cancel-picking | v4 | **v5** | true | 218052d71120eeab9f83aff045a14e24173dd15f3dafdb4e91978e7dd7bbda01 |
| reopen-picking | v8 | **v9** | true | ca69477e935cb78b7f9cebe13940e589c58adcf891ee16e26cc15354c735b3ae |

The live function objects were fetched again after deployment. Each reports ACTIVE, the listed version, verify_jwt=true, and the inserted authorization check. Hashes above are Supabase deployment hashes, not Git SHAs.

## 3. Git Current source synchronization

The four rawaie-erp-New/Current/Edge_Functions snapshots were updated to match the deployed Production source. Historical/Original files were left unchanged.

| Current source | New blob SHA | Commit |
|---|---|---|
| Current/Edge_Functions/start-picking | 14188f5d60d70cc4ec214cd27145398979e06403 | 0fd979e756b0994e333fb57405da6a1cee938673 |
| Current/Edge_Functions/complete-picking | be06ac006adc146df46adc893e18105d95c0e9a3 | 8f7ca687750e88c265da0b06c625552ee04abef5 |
| Current/Edge_Functions/cancel-picking | 69005b8c8b73baad5d54a9af9e155d45b621014f | 80ff793ccdc120cdaa90a622ed29789167520fa9 |
| Current/Edge_Functions/reopen-picking | fe7d6f77f1f34ba141f47d6af6e33ac5e8443ac2 | 5a8aea2f545e33adbc541fa0f414cef68c01c340 |

## 4. Operational picker: exact owner-only surgical changes

Do not edit main.html. Do not grant direct UPDATE on run_sheet_details. Do not write directly to order_details from the PWA. The owner applies the following to the exact current picker blob c7ad267d852d415b680aed7716833eea9bcffdf6.

### Patch A — remove the ignored, unauthorized write

- **File:** companies/company-1/warehouse/picker.html
- **Function:** App.editPickedItem(index)
- **Current line:** 643
- **Find this exact statement and replace it with the two comments below:**

~~~js
supabase.from('run_sheet_details').update({ qty_picked: r.value.qty }).eq('runsheet_id', self.session.runsheet_id || null).eq('item_code', it.item_code).then(function(){});
~~~

Replacement:

~~~js
// qty_picked is a derived projection of order_details, maintained by sync_run_sheet_details().
// Persist the final picked quantities only through complete-picking -> complete_runsheet_picking.
~~~

**Effect:** removes a silent no-op and prevents the UI from implying that the derived table is a writable draft store. Final picking quantities continue through the existing transactional core.

### Patch B — persist a local draft in the existing Dexie store

The current file creates db.session with key runsheet_code but never writes a session to it; only db.session.clear() is used. Consequently, quantities held only in self.session.items can be lost on refresh before completion.

- **File:** companies/company-1/warehouse/picker.html
- **Function:** App.openRunsheet(code)
- **Insertion point:** inside the branch if(rs.status === 'Picking' && rs.picker_id === self.pubUserId), after the loop that fills self.session.items and before the existing self.renderActiveSession(); return;.
- **Replace the existing two lines self.renderActiveSession(); return; with:**

~~~js
db.session.get(code).then(function(savedSession){
    var sameSession = savedSession &&
        savedSession.runsheet_id === rs.id &&
        savedSession.start_time === self.session.start_time &&
        Array.isArray(savedSession.items);

    if(sameSession){
        for(var i = 0; i < self.session.items.length; i++){
            var currentItem = self.session.items[i];
            for(var j = 0; j < savedSession.items.length; j++){
                var savedItem = savedSession.items[j];
                if(savedItem.item_code === currentItem.item_code){
                    var savedQty = Number(savedItem.qty_picked);
                    if(isFinite(savedQty) && savedQty >= 0 && savedQty <= currentItem.qty_ordered){
                        currentItem.qty_picked = savedQty;
                    }
                    currentItem.notes = typeof savedItem.notes === 'string' ? savedItem.notes : '';
                    break;
                }
            }
        }
    }

    return db.session.put(self.session);
}).then(function(){
    self.renderActiveSession();
}).catch(function(err){
    console.error('Picker draft restore/save error:', err);
    self.renderActiveSession();
});
return;
~~~

### Patch C — save each local draft edit

- **File:** companies/company-1/warehouse/picker.html
- **Function:** App.editPickedItem(index)
- **Insertion point:** immediately after self.session.items[index].notes = r.value.notes;
- **Insert:**

~~~js
db.session.put(self.session).catch(function(err){
    console.error('Picker draft persistence error:', err);
    toast('تعذر حفظ مسودة التحضير على هذا الجهاز', 'error');
});
~~~

**Scope of this draft:** device-local recovery only; it is not a server-side draft and does not make unsubmitted quantities visible on another device. The session identity check uses both runsheet_id and the server’s picker_start timestamp to avoid restoring a stale draft from an earlier picking cycle. Completion/cancellation already clear the Dexie session.

### Patch D — retain the already-documented Report449 read-error guards

Report449 already specifies the exact guards for resolved PostgREST errors in renderPendingTab() and openRunsheet(). Do not duplicate or replace those patches with a broader rewrite. Apply Report449 patches A–C and these follow-up changes against the same current blob, then re-fetch the file and recalculate all line numbers before any further edits.

## 5. Tests and verification

### Verified now
- Production versions and hashes re-fetched after deployment.
- All four deployed handlers contain the new server-side authorization logic.
- Live SQL confirms the role permission model and the owner helper contract.
- Live SQL confirms run_sheet_details has authenticated SELECT but no authenticated UPDATE grant.
- Live trigger/function definition confirms run_sheet_details is derived from order_details.
- No runsheet, order, stock, or other business row was modified by this session.

### Not yet verified
- No authenticated HTTP E2E was run after deployment; the available tool set did not provide a safe authenticated browser/API session for an isolated picker test.
- Supabase unified-log query failed with a backend error.
- No current open runsheet was mutated for testing.
- Served Cloudflare artifact parity is unverified.
- The owner-only picker patches have not been applied/deployed; local draft recovery therefore remains open.

### Required owner test sequence after applying picker patches
1. Validate JavaScript syntax and reload the served Cloudflare app with cache bypass.
2. Confirm an authorized user with warehouse permission and active role تحضير can start, edit, complete, cancel, and reopen their own runsheet.
3. Confirm a non-warehouse user and a user with a different active warehouse role are denied by the Edge endpoint even when calling it directly.
4. Edit two items, refresh the page before completion, and verify quantities/notes restore on the same device only.
5. Confirm an old local draft is not restored after a new picking cycle with a different picker_start.
6. Complete picking and verify order_details.qty_picked, runsheets.status='Picked', reservation/allocated quantity, and the derived run_sheet_details values agree.
7. Confirm no physical movement log is written by picking; Loading remains the physical stock movement stage.
8. Verify cancel/reopen release reservation according to their existing core contracts.
9. Verify served artifact parity and confirm no fixture/test residue remains.

## 6. Closure status

- **Production server-side authorization hardening:** DEPLOYED / LIVE FUNCTION OBJECTS RE-READ / SOURCE SNAPSHOTS SYNCED.
- **Operational picker integration:** OWNER SURGICAL PATCHES READY / NOT DEPLOYED.
- **HTTP E2E and served artifact parity:** UNVERIFIED.
- **Closure:** PARTIALLY EXECUTED — NOT 100% CLOSED.

## SELF-AUDIT FINAL

- **What I proved:** live Production function versions, JWT setting, deployed authorization checks; authoritative user/role/owner permission contract; no authenticated UPDATE on the derived table; the trigger that syncs the derived table from order_details.
- **What I did not prove:** successful authenticated browser E2E, Cloudflare served HTML parity, device behavior after the owner patches.
- **What I fixed:** server-side permission/active-role enforcement in four existing Production Edge Functions; synchronized the four Current source snapshots with the deployed artifacts.
- **What I initially missed:** the picker’s direct write is not only unauthorized; it targets a derived projection, and the existing Dexie session store is never used to persist draft edits.
- **What could still be wrong:** actual account permission configuration or active-role values may expose an unintended denial; this must be checked with representative authenticated accounts. Local draft recovery needs browser testing.
- **Final confidence:** high for the identified authorization bypass and derived-write defect; medium for the deployment’s end-user impact until authenticated E2E.
- **Final closure status:** PRODUCTION AUTHORIZATION FIX DEPLOYED / PICKER SOURCE PATCHES PENDING OWNER / NOT CLOSED.
