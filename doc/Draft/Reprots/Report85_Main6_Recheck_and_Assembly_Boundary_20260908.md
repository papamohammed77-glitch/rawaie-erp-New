# Report85 — Main6 Recheck and Assembly Boundary — 2026-09-08

## 1. الهدف
إعادة قراءة `Current/PWA/main2/main6.md` من SOF إلى EOF بعد تنفيذ جراحات Report84، والتحقق من اكتمالها وسلامة closures، ثم تحديد المسار الصحيح للدمج الكامل دون خلط مصادر الحقيقة.

## 2. المصادر التي تم الرجوع إليها
- MASTER - RAWAEA ERP FORENSIC CONTINUITY GOVERNANCE v2
- MASTER - RAWAEA ERP - UNIFIED CONTINUITY & MAIN1 EXECUTION
- MASTER - RAWAEA ERP
- CURRENT_STATE.md
- Report84_Main6_M6-Source_Surgical_Execution_20260908.md
- Git HEAD الحالي وتاريخ commit الخاص بـ main6
- `Current/PWA/main2/main1..main11`
- Production Supabase schema / migrations / Edge Functions ذات العلاقة
- workflows الخاصة بإعادة بناء PWA

## 3. Git Reality — لحظة التقرير
- HEAD الحالي: `d16d0262ce50d8e29446533347a1b56d2b38497e`
- `Current/PWA/main2/main6.md` الحالي:
  - blob: `3b20758459c28ab0b6c055f9a0ad3992f1bd07e5`
  - الحجم: 29,172 bytes
- هذا الـHEAD أحدث من الحالة التي كان Report84 يشير إليها، وتم فيه تنفيذ جراحات Main6.

## 4. Main6 — نتيجة المراجعة الكاملة
تمت مراجعة main6 الحالي مباشرة، وليس الاعتماد على Report84 وحده.

الجراحات التسع مطبقة فعليًا:
- M6-01 — Online Store settings أصبح company-scoped.
- M6-02-A/B — Track Order أصبح company-scoped ويستخدم `order_details.order_id` الصحيح، مع اعتماد `code` المحلي.
- M6-03 — Purchase Orders list أصبح company-scoped.
- M6-04 — Open Receive أصبح company-scoped، مع منع تحميل التفاصيل قبل نجاح تحديد الـPO.
- M6-05 — Suppliers أصبح company-scoped.
- M6-06 — Purchase refresh أصبح company-scoped.
- M6-07 — Receive dialog يستخدم remaining quantity ويضع `max=remaining`.
- M6-08 — Track Order item name أصبح escaped باستخدام `esc(...)`.
- M6-09 — savePO أصبح يحتوي token/session guard قبل `fetch`.

### Structural Closure
- بداية الملف صحيحة كوحدة JavaScript مستقلة.
- `RW_OnlineStore` مغلق بصورة صحيحة.
- `RW_Purchases` مغلق بصورة صحيحة.
- نهاية الملف الحالية:
  `window.RW_Purchases = RW_Purchases;`
- لم يظهر في الجزء المقروء أي closure ناقص أو قوس زائد ضمن Main6 نفسه.

## 5. Production Reconciliation
Production الحالية في مشروع `fiilmooggumokxanwiyx` تختلف عن الحالة القديمة في التقارير السابقة:
- Production حالياً تحتوي شركة واحدة فقط.
- جميع الجداول الأساسية ذات الصلة ما زالت RLS مفعلة.
- لا توجد حاليًا Purchase Orders أو Orders أو Stock Vouchers في البيانات التشغيلية الحالية تسمح باختبار دورة أعمال دائمة دون إنشاء fixture.
- `items.item_code` مثبت في Production كـUNIQUE عالميًا.
- `order_details.order_code` غير موجود؛ الرابط المعتمد هو `order_id`.
- `receiving.operation_id` موجود ومقيد UNIQUE.
- Production الحالية تحتوي migrations لاحقة بتاريخ 2026-09-08، أي أن أي تقرير يعتمد الحالة القديمة دون إعادة مزامنة Production سيكون غير صالح.

## 6. Assembly Boundary — اكتشاف حرج
تم التحقق من الآليات الحالية لإعادة بناء PWA.

يوجد مصدر أجزاء طلبه المستخدم في:
`Current/PWA/main2/main1.md ... main11.md`

لكن أداة إعادة البناء الرسمية الحالية:
`tools/run_final_main_reconstruction_20260831.py`
تبني من:
`Current/PWA/main/main1.md ... main11.md`
ثم تنتج:
`Current/PWA/New-main`

كما أن `forensic_main_assembly.yml` يعتمد نفس مسار `Current/PWA/main/`، وليس `Current/PWA/main2/`.

لذلك لا يجوز اعتبار `main2/*` و`main/*` مصدرًا واحدًا، ولا يجوز تشغيل assembly الحالي على `main2` عن طريق الافتراض.

## 7. قرار التنفيذ
- Main6 source surgery: **VERIFIED / CLOSED داخل source scope**.
- Main6 parent/runtime closure: **OPEN**.
- Full `main2` assembly: **NOT EXECUTED** في هذه الجلسة لأن مسار الـassembly canonical الحالي يشير إلى مصدر مختلف، وتشغيله على المصدر الخطأ سيكسر قاعدة Source of Truth.
- لم يتم تعديل `Current/PWA/main2/main6.md` بواسطة المساعد.

## 8. Production changes in this session
لم يتم إدخال Migration جديدة خاصة بـMain6 في هذه الجلسة بعد المراجعة الحالية، لأن الـscope المطلوب كان تحقق المصدر والانتقال الآمن للدمج، ولأن Production الحالية لا تبرر تغييرًا عشوائيًا.

## 9. What is proven
- Main6 الحالي يحتوي التسع جراحات المقررة.
- Git الحالي أحدث من Report84.
- Main6 closures الأساسية صحيحة.
- Production schema الحالي يثبت contracts اللازمة لـM6.
- هناك مساران مختلفان للأجزاء (`main2` و`main`) ويجب الفصل بينهما.

## 10. What is not proven
- لم يتم إثبات أن `Current/PWA/main2/*` هو المصدر الذي يجب أن تستخدمه أداة reconstruction الحالية.
- لم يتم إثبات parent runtime بعد دمج main2 الكامل.
- لم يتم إثبات Production deployment للملف الأم الناتج من main2.

## 11. Final Self-Audit
### Confirmed Facts
- M6-01..M6-09 موجودة في Git الحالي.
- `main6` الحالي blob `3b207584...`.
- HEAD الحالي `d16d0262...`.
- assembly workflow الحالي يعتمد `Current/PWA/main/*`.

### Unknowns / Conflicts
- canonical parent assembly source: `main2` أم `main`.
- لا يجوز حل هذا التعارض بالتخمين.

### Final Closure Status
`MAIN6 SOURCE SURGERY = CLOSED`
`MAIN2 FULL ASSEMBLY = OPEN / SOURCE-OF-TRUTH BOUNDARY UNRESOLVED`
`PARENT GOLD/DIAMOND = NOT CLOSED`
