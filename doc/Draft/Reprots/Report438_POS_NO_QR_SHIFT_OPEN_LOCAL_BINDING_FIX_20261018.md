# Report438 — POS بدون QR: إصلاح حفظ هوية الجهاز بعد فتح الوردية — 2026-10-18

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** المطلوب أن يفتح الكاشير الوردية دون مسح QR، مع بقاء كل وردية مرتبطة بجهازها وخزينتها الثابتة، وعدم السماح بإعادة استخدام وردية جهاز آخر.
- **Architecture Understanding:** POS يستدعي RPC المصادق عليه `pos_open_shift`. RPC ينشئ أو يستعيد ربط الجهاز والخزينة ويرجع `terminal_id` و`treasury_id`. الواجهة تقرأ الوردية عبر `pos_get_shift_summary` وتتحقق من تطابق هوية الجهاز قبل تفعيل الوردية.
- **Database Understanding:** Production يحتوي `pos_terminals`, `pos_shifts`, `pos_shift_events`, `pos_shift_cash_counts`, `treasury`, و`cash_box`. قيد الخزينة على الجهاز والوردية موجود، ولا يلزم إنشاء جداول جديدة لهذه المشكلة.
- **Historical Understanding:** تمت مراجعة CURRENT_STATE الحالي وReport436 وReport437 وMigration `20261018182808_pos_terminal_auto_treasury_on_shift_open.sql`، مع فحص آخر commit ومصدر POS الفعلي. Report437 أصلح شرط QR في Production بالفعل؛ لا أعيد تطبيق إصلاحه.
- **Production Understanding:** فحص Production الحالي يؤكد أن `pos_open_shift(uuid,text,numeric,uuid,uuid,text)` يحتوي مسار تهيئة خزينة الجهاز تلقائيًا، ولا يحتوي النص القديم `SHIFT_TREASURY_SELECTION_REQUIRED`، وأن `anon EXECUTE=false` و`authenticated EXECUTE=true`.
- **Current Understanding:** مصدر POS الحالي SHA `962dc6474a9c2692c1072631bd9d09d359d7d982`، وعدد أسطره 2,278. آخر commit ذي صلة `e4876b012f9a00ce785b2d8c899e740102c842e7`. ما زال يحتوي فحصًا محليًا صارمًا لهوية الوردية، لكن نجاح `startShift` لا يحفظ معرفي الجهاز والخزينة اللذين أعادهما RPC قبل استدعاء `loadShiftState`.
- **Execution Confidence:** مرتفع لتشخيص المصدر وعقد Production؛ لا أدعي اختبار متصفح حي أو نشر واجهة لم يحدثا في هذه الجلسة.

## CURRENT FACTS VERIFIED

1. Report437 نشر إصلاح Production لفتح الوردية دون QR، وسجل Migration `20261018182808`، ووثق اختبار SQL معزولًا وRollback وإعادة خط الأساس.
2. قراءة تعريف Production الحي الآن تؤكد وجود مسار التهيئة التلقائية وعدم وجود `SHIFT_TREASURY_SELECTION_REQUIRED` في تعريف RPC الحالي.
3. RPC يرجع `terminal_id` و`treasury_id` في نتيجة الفتح الناجح وكذلك في نتيجة إعادة الطلب المكرر.
4. واجهة POS في `self.startShift` تستدعي `self.loadShiftState` بعد النجاح، لكنها لا تحفظ المعرفين العائدين من RPC في:
   - `rawaea_pos_terminal_id`
   - `rawaea_pos_terminal_treasury_id`
5. `self.loadShiftState` يعتبر الوردية تابعة لجهاز آخر إذا غاب أي من المعرفين المحليين، حتى عندما يكون `terminal_code` الخاص بالوردية هو رمز هذا الجهاز. هذا يجعل مسار فتح الوردية دون QR غير مكتمل وظيفيًا في الواجهة بعد نجاح RPC.
6. يوجد سجل وردية مغلق واحد في Production مرتبط بأمر بيع واحد، وسجلين في `cash_box`، وحدثي وردية، وثمانية صفوف عدّ نقد. فرق الإغلاق المسجل `-135.00`. **لم أحذف هذه البيانات**: ارتباطها ببيع وآثار مالية يجعل حذفها دون إثبات مستقل أنها بيانات اختبار معزولة إجراءً غير آمن ويُفسد أثر التدقيق.

## ROOT CAUSE

الإصلاح الخلفي في Report437 صحيح ويُبقي الخزينة والجهاز مربوطين داخل المعاملة، لكن واجهة POS لا تحفظ معرفي الجهاز والخزينة اللذين أعادهما الخادم بعد نجاح فتح الوردية. بعد ذلك، يفشل الفحص المحلي الصارم في `loadShiftState` ويعرض حالة «الوردية مفتوحة على جهاز آخر» رغم أن RPC فتحها على رمز الجهاز الحالي.

هذه فجوة مزامنة بين نتيجة Production الموثوقة وذاكرة الجهاز، وليست سببًا لإعادة تعديل RPC أو إضعاف تحقق الشركة/الفرع/الجهاز.

## OWNER-ONLY SURGICAL PATCH C

**الملف:** `papamohammed77-glitch/erp-frontend/companies/company-1/sales/pos.html`  
**SHA الحالي:** `962dc6474a9c2692c1072631bd9d09d359d7d982`  
**الدالة:** `self.startShift`، تبدأ قرب السطر 590.  
**موضع التعديل:** بعد نجاح التحقق من `res.data.success` مباشرة وقبل `self.loadShiftState(function(ok)` قرب السطر 633.

### محدد البحث — ابحث عن الكتلة التالية كاملة

```javascript
        self.loadShiftState(function(ok) {
            if (ok) {
                RW_UI.toast(
                    res.data.duplicate ? 'الوردية موجودة بالفعل' : 'تم فتح الوردية على الجهاز والخزينة المرتبطين',
                    'success'
                );
            }
        });
```

### احذف الكتلة أعلاه واستبدلها بهذه الكتلة كاملة

```javascript
        // Persist server-authoritative terminal/treasury IDs before the strict local shift check.
        try {
            if (res.data.terminal_id) {
                localStorage.setItem('rawaea_pos_terminal_id', String(res.data.terminal_id));
            }
            if (res.data.treasury_id) {
                localStorage.setItem('rawaea_pos_terminal_treasury_id', String(res.data.treasury_id));
            }
        } catch (storageError) {
            console.warn(
                'POS terminal binding cache could not be persisted; server-side binding remains authoritative.',
                storageError
            );
        }

        self.loadShiftState(function(ok) {
            if (ok) {
                RW_UI.toast(
                    res.data.duplicate ? 'الوردية موجودة بالفعل' : 'تم فتح الوردية على الجهاز والخزينة المرتبطين',
                    'success'
                );
            }
        });
```

**طريقة التطبيق:** استبدل الكتلة المحددة فقط. لا تستبدل الدالة كاملة، ولا تعدل `main.html` أو `core.js`، ولا تحذف دالة `bindTerminalTreasuryQR` في هذه الخطوة.

**الأثر المتوقع:** بعد نجاح `pos_open_shift`، تحفظ الواجهة المعرفين اللذين أعادهما Production قبل فحص حالة الوردية. وبذلك يبقى فحص تطابق `terminal_id` و`treasury_id` و`terminal_code` فعالًا دون فرض QR. لا يغيّر هذا التعديل أي حركة مالية أو صلاحية أو ربط قائم في قاعدة البيانات.

## PREVIOUS OWNER PATCHES — DO NOT REPEAT

تظل Patch A وPatch B من Report437 مطلوبة ولم أعد كتابتهما هنا:
- Patch A: استبدال نص/زر QR داخل `#posShiftOpenPanel` برسالة توضّح أن خزينة الجهاز تُهيأ تلقائيًا عند أول فتح وردية.
- Patch B: إزالة رسالة الخطأ القديمة التي تطلب QR، واستبدالها برسالة تهيئة عامة لا توحي بأن QR شرط للفتح.

الرابط: [Report437_POS_AUTO_DEVICE_TREASURY_NO_QR_20261018.md](Report437_POS_AUTO_DEVICE_TREASURY_NO_QR_20261018.md).

## VERIFICATION MATRIX

| البند | الحالة |
|---|---|
| Current POS SHA + latest relevant commit | VERIFIED |
| Production RPC auto-treasury path + current ACL | VERIFIED |
| Report437 migration and isolated SQL E2E evidence | VERIFIED FROM PRIOR REPORT; current RPC rechecked |
| Root cause in current POS caller | VERIFIED |
| Patch C source change | READY FOR OWNER; not applied by assistant |
| Production database change required | NONE identified |
| Historical closed shift and financial rows | PRESERVED |
| Actual browser/HTTP E2E after owner patch | OPEN / UNVERIFIED |
| Cloudflare served artifact parity | OPEN / UNVERIFIED |

## SELF-AUDIT FINAL

- **What I Proved:** Production already supports no-QR first-use setup; successful RPC responses include the terminal and treasury IDs; current POS fails to persist those IDs before its strict terminal identity check; the existing closed shift has linked financial records.
- **What I Did Not Prove:** The owner has applied Report437 Patch A/B or this Patch C; the served Cloudflare artifact matches Git; the post-patch browser flow succeeds.
- **What I Fixed:** No source or Production mutation was performed in this session. I isolated the next required surgical fix without repeating the completed Production migration.
- **What I Initially Missed:** Report437’s correct backend repair is not enough by itself; the client must persist the server-returned binding before it re-reads the shift.
- **What Could Still Be Wrong:** Browser storage failure may prevent the local cache from being saved; this must be observed in the real browser. No evidence supports deleting the historical shift/financial rows.
- **Final Confidence:** High for the source-level root cause and proposed surgical patch; runtime closure remains unverified.
- **Final Closure Status:** `PRODUCTION NO-QR RPC VERIFIED / OWNER PATCHES A–C PENDING / BROWSER E2E OPEN / NOT 100% CLOSED`.
