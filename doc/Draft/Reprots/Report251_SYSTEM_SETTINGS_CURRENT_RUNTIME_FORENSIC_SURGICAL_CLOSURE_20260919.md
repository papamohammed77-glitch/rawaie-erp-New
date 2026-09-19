# تقرير 251 — إعدادات النظام
## التحقيق الجنائي الحالي + التعديل الجراحي + مطابقة Production
**التاريخ:** 2026-09-19  
**النطاق:** تبويب «إعدادات النظام» فقط  
**قاعدة التنفيذ:** لا تعديل على Mother \`main.html\` بواسطة CTO؛ Owner Change Set فقط.  
**Production:** أي بنية لازمة تُنفذ مباشرة، ولا توجد بنية Production جديدة مطلوبة في هذه الدورة بعد المطابقة.

---

## 1. نقطة الاستئناف المثبتة

### System Repository
- المستودع: \`papamohammed77-glitch/rawaie-erp-New\`
- CURRENT HEAD: \`e652d0af323fad0f3dea5b32115a6af6cd17e58b\`
- Parent: \`36d9b482962be256a5456d0fd77c3ddb23f1c3b9\`
- أحدث commit:
  \`docs: correct final settings checkpoint git head in CURRENT_STATE\`
- الـparent السابق:
  \`docs: update CURRENT_STATE with system settings checkpoint\`

### Mother Repository
- المستودع: \`papamohammed77-glitch/erp-frontend\`
- CURRENT HEAD: \`5c1e10d805a499594ec14d653f466cd05e7204dc\`
- Parent: \`cfc63ad204f8af0faec3fbfafd75dfe0aee80d0b\`
- commit الـparent هو آخر تغيير جوهري أدخل نسخة Settings الحالية:
  \`Update print statement from 'Hello' to 'Goodbye'\`
- أحدث commit نفسه أضاف ملف forensic extract ولا يغيّر \`main.html\`.
- Current \`companies/company-1/main.html\` blob:
  \`6241363f7f54bcff0356cd39f9253d1930b5fd68\`
- GitHub forensic extraction:
  - 27031 logical source lines في فحص CI.
  - 1556105 bytes.
  - SHA256: \`8c6f63881a834c307c1d548b7b4e38d285bc89acbf9554917949caaf92fff11e\`

### Latest settings report
- Report250 موجود ومحفوظ ولا يُعاد تحريره.
- استخدم كمرجع تاريخي فقط.
- هذه الوثيقة تصحح الحالة الحالية عند وجود تعارض بين Report250 وCurrent Git/Production.

---

## 2. Governance التي تحكم هذه الدورة

تمت قراءة ملف:
\`doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md\`
حتى EOF، وليس Preview أو Snippet.

القواعد المستخدمة هنا:
- Report = Evidence/Clue وليس Current Truth.
- Current State = Living Execution Control Plane.
- Production + Database + Deployment + Current Git + Current Source هي الحالة المرجعية.
- لا Guessing.
- لا تغيير على سلوك تاريخي دون إثبات Contract.
- كل Closure يجب أن تُثبت وظيفيًا وبيانيًا وأمنيًا وفي Production.
- Source الموجود في Mother الذي يقع ضمن Owner Change Set لا يحرره CTO؛ يُعطى للمالك كجراحة كاملة قابلة للتطبيق.
- لا يُعاد إصلاح شيء ثبت أنه صحيح إلا بدليل Regression حالي.

---

# 3. إعادة بناء دور Settings داخل النظام

## الدور التاريخي والفعلي

\`RW_Settings\` ليس تبويبًا منفصلًا عن النظام، بل نقطة تحكم مركزية لقيم تقرأها أجزاء متعددة:

### الهوية
- company_name
- company_phone
- company_logo

### المتجر
- store_name
- store_logo
- store_primary_color
- store_secondary_color

### التشغيل التجاري
- payment_method
- currency
- delivery_fee
- min_invoice_amount
- tax_rate
- free_shipping_threshold
- main_branch_id

### التشغيل المرجعي
- order_serial
- runsheet_serial

### حالة الاشتراك
- status
- trial_end_date
- subscription_end_date

Current Mother يقرأ هوية الشركة من \`app_settings\` بعد تثبيت \`company_id\`:
- \`main.html:981–985\`
- Scope القراءة: \`company_id\`
- لا يوجد lookup عالمي للشركة في هذه الجزئية.

Router الحالي يحوّل Settings إلى Page مباشرة:
- \`main.html:24935\`
- \`if (view === 'settings') { RW_Settings.render(); return; }\`

إذن **تحويل Modal → Page موجود فعليًا بالفعل** في Current Source، ولا توجد جراحة إضافية مطلوبة في Router لهذا الغرض.

---

# 4. Current Settings Source — ما تم فعله بالفعل

الـMother current يحتوي بالفعل على صفحة Settings الكاملة التي كانت هدف Report250:
- Navigation داخل الصفحة:
  - هوية الشركة
  - هوية المتجر
  - المبيعات
  - التشغيل
- Save All.
- Company logo preview/upload.
- Store logo preview/upload.
- Colors.
- Delivery fee.
- Minimum invoice.
- Tax rate.
- Free-shipping threshold.
- Currency.
- Main Branch.
- Read-only operational summary.
- Save عبر \`save-settings\` Edge Function.

**لا يجب استبدال RW_Settings بالكامل الآن.**
إعادة تسليم البلوك الكامل ستعيد لمس أجزاء سليمة وتفتح بابًا لظهور Drift جديد.

---

# 5. سبب الخطأ — إثبات جنائي

## الخطأ غير المسبب
رسالة:

\`cdn.tailwindcss.com should not be used in production\`

هي Warning خاصة باستخدام CDN، وليست سبب توقف JavaScript في \`RW_Settings\`.

## الخطأ المسبب

Current Source يحتوي في \`RW_Settings.build()\` على اقتباس JavaScript غير مهرب داخل string HTML.

### occurrence #1
**الملف:** \`companies/company-1/main.html\`  
**SHA:** \`6241363f7f54bcff0356cd39f9253d1930b5fd68\`  
**الدالة:** \`RW_Settings.build()\`  
**السطر:** \`5362\`

العنصر الحالي المعيب هو السطر الكامل الذي يحتوي:
\`settings-company-logo-preview\`

والجزء المعيب تحديدًا:
\`onerror="this.src='' + imageFallback() + ''"\`

### occurrence #2
**السطر:** \`5374\`

والجزء المعيب نفسه مع:
\`settings-store-logo-preview\`

### لماذا هذا هو Root Cause المؤكد؟

GitHub CI شغّل بالفعل:
- \`RAWAEA CTO — published main.html full forensic gate\`
- Run ID: \`35436461898\`
- Job: \`105879844362\`
- Step:
  \`Exact JavaScript syntax gate — original published source\`

والنتيجة:

\`/tmp/main-positioned.js:5362\`
\`SyntaxError: Unexpected string\`

أي أن الخطأ الذي ظهر في Console للمستخدم ليس تخمينًا، بل مُثبت من نفس Source الحالي عبر Syntax Gate مستقل.

كما فشلت:
- \`RAWAEA — Forensic Mother Assembly Guard\`
- Run ID: \`35436461833\`

عند:
\`Validate Mother inline JavaScript syntax\`

---

# 6. تحقق Parser مستقل قبل الجراحة

تم استخراج الـinline JavaScript القياسي الوحيد من Current \`main.html\`.

### قبل الجراحة
- inline JS parse: **FAIL**
- error: \`SyntaxError: Unexpected string\`
- malformed occurrences: **2**

### بعد استبدال occurrence #1 + #2 فقط داخل نسخة اختبارية غير منشورة
- RW_Settings full module parse: **PASS**
- inline JS parse: **PASS**
- malformed occurrences: **0**

هذا يثبت أن الجراحة المقترحة كافية لإزالة SyntaxError المحدد، دون إعادة بناء الصفحة.

---

# 7. OWNER SURGICAL CHANGE SET

## الجراحة 1 — Company Logo

### ابحث تحديدًا عن:
\`function build()\`

ثم عن **السطر الكامل 5362** الذي يحتوي:
\`settings-company-logo-preview\`

### احذف السطر الحالي بالكامل.

### استبدله بالسطر الكامل التالي:

    '<div class="lg:col-span-2 rounded-2xl border border-slate-200 p-5 bg-slate-50/70"><div class="flex items-center justify-between mb-4"><div><div class="font-black text-slate-800">شعار الشركة</div><div class="text-[11px] text-slate-500">يظهر في واجهات ومستندات النظام التي تستخدم company_logo.</div></div></div><div class="flex flex-col md:flex-row items-start md:items-center gap-5"><img id="settings-company-logo-preview" src="' + escapeHtml(currentSettings.company_logo || imageFallback()) + '" onerror="this.src=\'' + imageFallback() + '\'" class="w-24 h-24 rounded-2xl border border-slate-200 bg-white object-contain p-2"><div><input type="file" id="settings-company-logo-file" accept="image/*" class="text-xs file:py-2 file:px-4 file:rounded-xl file:border-0 file:bg-blue-50 file:text-blue-700"><div class="text-[11px] text-slate-500 mt-2">PNG/JPG/WebP — بحد أقصى 3MB.</div></div></div></div>' +

### الفرق الجوهري
الـHTML الناتج يصبح:
\`onerror="this.src='[fallback]'"\`
بدل إغلاق JavaScript string مبكرًا.

---

## الجراحة 2 — Store Logo

### ابحث تحديدًا عن:
\`settings-store-logo-preview\`

داخل نفس:
\`RW_Settings.build()\`

### احذف السطر الكامل الحالي \`5374\`.

### استبدله بالسطر الكامل التالي:

    '<div class="lg:col-span-2 rounded-2xl border border-slate-200 p-5 bg-slate-50/70"><div class="font-black text-slate-800 mb-4">شعار المتجر</div><div class="flex flex-col md:flex-row items-start md:items-center gap-5"><img id="settings-store-logo-preview" src="' + escapeHtml(currentSettings.store_logo || imageFallback()) + '" onerror="this.src=\'' + imageFallback() + '\'" class="w-24 h-24 rounded-2xl border border-slate-200 bg-white object-contain p-2"><div><input type="file" id="settings-store-logo-file" accept="image/*" class="text-xs file:py-2 file:px-4 file:rounded-xl file:border-0 file:bg-emerald-50 file:text-emerald-700"><div class="text-[11px] text-slate-500 mt-2">يُحفظ في نفس مخزن الشعارات المستخدم حاليًا.</div></div></div></div>' +

---

# 8. ما لا يتم تعديله

لا تُعدل:
- \`RW_Settings.loadData()\`
- \`RW_Settings.readPayload()\`
- \`RW_Settings.save()\`
- \`RW_Settings._saveSettings()\`
- \`RW_Settings.render()\`
- Router Settings.
- uploadLogo.
- save-settings Edge.
- \`save_system_settings_atomic\`.

لا تُنشئ:
- \`RW_Settings_v2\`
- \`buildFixed()\`
- دالة بديلة.
- نسخة ثانية من Settings.

السبب: هذه العناصر ثبت أنها ضمن البناء الحالي العامل وظيفيًا، والخطأ محصور في quote escaping في occurrence عدد 2.

---

# 9. Production — الحالة الحالية

تم إجراء مطابقة حية في Production في:
**2026-09-19 10:24:48.269488+00 UTC**

### app_settings
- rows: 1
- company_id:
  \`00000000-0000-0000-0000-000000000001\`
- company_name:
  \`الشيخ للتجارة والتوزيع\`
- company_logo:
  موجود فعليًا في Storage
- store_name:
  \`الروائع\`
- store_logo:
  null
- primary:
  \`#2563eb\`
- secondary:
  \`#1e40af\`
- payment_method:
  \`both\`
- currency:
  \`SAR\`
- delivery_fee:
  0
- min_invoice_amount:
  0
- tax_rate:
  0
- free_shipping_threshold:
  0
- main_branch_id:
  \`a38332b6-6cea-480a-ada1-6eb6ab0590db\`
- order_serial:
  1
- runsheet_serial:
  1
- status:
  \`trial\`

### companies projection
Current \`companies.main_branch_id\` يساوي:
\`a38332b6-6cea-480a-ada1-6eb6ab0590db\`

والـ\`main_branch_code\`:
\`BR-01\`

### Projection trigger
Production تحتوي:
\`trg_sync_company_main_branch_projection\`

وتستدعي:
\`sync_company_main_branch_projection()\`

والدالة تتحقق من:
- branch.id
- branch.company_id

ثم تحدّث:
- companies.main_branch_id
- companies.main_branch_code

لذلك لا توجد حاجة لإنشاء writer ثانٍ من Settings إلى companies.

---

# 10. Production Settings Writer

Production contains:

\`public.save_system_settings_atomic\`

Signature:
\`(uuid, uuid, text, boolean, jsonb)\`

- SECURITY DEFINER: true
- current definition hash:
  \`324e96f901210c963ce6a39db02e5ee2\`

والـWriter:
- يتحقق من company.
- يتحقق من actor/user/company.
- يتحقق من permissions.
- يحافظ على OWNER semantics.
- يرفض fields غير المعرفة.
- يتحقق من main branch/company relationship.
- يحقق no-op semantics.
- يكتب audit record.
- لا ينشئ Physical/Inventory side effects.

---

# 11. save-settings Edge

Current Production:
- Function: \`save-settings\`
- Version: 14
- ACTIVE
- verify_jwt: true
- Deployment hash:
  \`68a3434f3ff13e44695518cb4297df66ff316664bbf3cb6dfc4e125618296a34\`

Current canonical Git source:
- \`Current/Edge_Functions/save-settings\`
- blob SHA:
  \`ca38d90be5d53ccbf8ba58869bbf784b109e0bd9\`

Current source وProduction deployment متطابقان وظيفيًا في هذا الـclosure:
- auth user
- users.company_id
- Active user
- owner verification عند license settings
- save_system_settings_atomic

---

# 12. Permissions / Direct DML

Current Production grants على \`app_settings\`:

### anon
- SELECT فقط

### authenticated
- SELECT فقط

### service_role
- write permissions

إذن لا يوجد مسار DML عادي للمستخدم من browser إلى \`app_settings\`.

والـaudit:
- \`app_settings_audit = 0\` عند snapshot الحالي، لأن آخر اختبار no-op تم داخل Transaction ثم rollback.
- تم اختبار no-op بالقيم الفعلية الحالية وكانت النتيجة:
  - success=true
  - changed=false
  - created=false

لا توجد data repair مطلوبة لهذا الـclosure.

---

# 13. لماذا لم نضف حقولًا جديدة الآن؟

تمت مقارنة Settings الحالية مع الوثائق الرسمية الحالية للأنظمة المنافسة.

## Odoo
Odoo يدعم:
- multi-company
- company-specific values
- Default Company للمستخدم
- فصل البيانات بين الشركات حسب الـCompany scope.

المصدر:
https://www.odoo.com/documentation/19.0/applications/general/companies/multi_company.html

## Microsoft Dynamics 365 Business Central
صفحة Company Information تعرض مجموعات:
- General
- Communication
- Payments
- Shipping
- Tax

المصدر:
https://learn.microsoft.com/en-us/dynamics365/business-central/quick-start-company-information

## SAP S/4HANA
يوفر:
- Official Document Numbering
- sequential/chronological document identity
- Business Place في السيناريوهات التي تتطلبه
- tax/TIN/address/number-range semantics حسب localization.

المصادر:
https://help.sap.com/docs/SAP_S4HANA_CLOUD/4603118feda9495892abadbe8f8c3d14/b15cfc3e56404640af4458ff9a16eb38.html
https://help.sap.com/docs/SAP_S4HANA_CLOUD/88520ff2932b479090ed3b7b116b2e91/4062d2ffd1c1424b93874bf2a330d44c.html

## Daftra
يدعم:
- Default Tax
- Tax Type/Inclusive/Exclusive
- Branch Settings
- Main Branch
- مشاركة العملاء/المنتجات والفروع
- Default Warehouse
- Default Price List
- Numbering of stock requisitions.

المصادر:
https://docs.daftra.com/en/tutorial/default-tax-in-sales-settings/
https://docs.daftra.com/en/tutorial/branches-settings/
https://docs.daftra.com/en/user_manual/inventory-and-products-settings-comprehensive-guide/

## Manager.io
يدعم:
- Business Details
- Address
- Country / localization
- Business Logo
- Custom Fields
- Form Defaults
- Themes

المصادر:
https://www2.manager.io/guides/9835
https://www2.manager.io/guides/8941
https://www2.manager.io/guides/14059
https://www2.manager.io/guides/10366

---

# 14. نتائج المقارنة بالنسبة إلى RAWAEA

## الموجود فعليًا الآن
Settings في RAWAEA يملك بالفعل قاعدة قوية:
- identity
- branding
- currency
- sales defaults
- delivery defaults
- free shipping
- main branch
- numbering visibility
- license summary
- central save writer
- tenant guards
- audit.

## حقول حقيقية موجودة في DB لكن لم يتم إدخالها في Settings
Production \`companies\` يحتوي:
- company_code
- name
- logo_url
- tax_id
- phone
- email
- address
- website
- main_branch_id
- main_branch_code

لكن التحقيق الحالي لم يثبت وجود Contract مكتمل يجعل Settings الحالي هو الـauthoritative writer لهذه الحقول، كما أن Current Mother لا يقرأ \`companies\` مباشرة لهذا الغرض.

**لذلك لا تُدمج هذه الحقول في هذه الجراحة.**
إدخالها الآن سيخلق Contract جديدًا وازدواجية مصدر قبل إثبات المستهلكين والـdocuments والـlocalization.

## حقول منافسة أخرى
- Bank/payment details
- fiscal/tax scheme
- official document numbering ranges
- branch sharing policies
- default warehouse / price list
- form defaults / templates / custom settings

هذه ليست مجرد fields؛ معظمها Business Contracts مستقلة تحتاج:
- schema
- consumers
- validation
- permissions
- audit
- downstream behavior

لذلك لم يتم اختراعها داخل \`app_settings\`.

---

# 15. Field / Contract Classification

| المجال | حالة RAWAEA الحالية | القرار |
|---|---|---|
| Company identity | موجود ويعمل | لا تغيير |
| Store identity | موجود ويعمل | لا تغيير |
| Branding | موجود ويعمل | إصلاح quote فقط |
| Currency | موجود ويُتحقق منه | لا تغيير |
| Delivery defaults | موجود | لا تغيير |
| Free shipping | موجود | لا تغيير |
| Main branch | موجود + projection trigger | لا تغيير |
| Number visibility | موجودة | لا تجعل raw serial editable |
| Payment mode | موجود، لكن value dictionary غير مثبت كاملًا | Read-only حتى يثبت contract |
| Tax rate | موجود | لا تغيير |
| Legal identity fields | موجودة في companies | Contract منفصل لاحق |
| Bank details | غير مثبت كـSettings contract | لا اختراع |
| Fiscal localization | غير مكتمل | لا اختراع |
| Official numbering | غير مكتمل كـSettings contract | لا اختراع |
| Form defaults | غير موجودة كـSettings contract | لا اختراع |
| Themes | موجودة جزئيًا على مستوى UI | لا تدخل ضمن هذه الوحدة |

---

# 16. Modal → Page

النتيجة الجنائية:
- Settings الحالية ليست Modal.
- Router يفتح:
  \`RW_Settings.render()\`
- \`RW_Settings.render()\` يضع UI داخل:
  \`rw-page-container\`
- لا يوجد Settings modal wrapper داخل وحدة Settings الحالية.

**القرار:**
لا تُجرى جراحة Modal → Page جديدة.
الـPage migration مثبتة بالفعل في Current Source.

---

# 17. E2E / Verification Matrix

## الذي تم إثباته الآن
### Source forensic
- Current blob verified.
- Exact malformed occurrences = 2.
- Current module before patch = SyntaxError.
- Same module after proposed patch = Syntax PASS.

### Git CI
- Current Source Gate = FAIL at 5362 before patch.
- Mother Assembly Guard = FAIL at inline syntax before patch.

### Production
- app_settings current data verified.
- main branch projection verified.
- save_system_settings_atomic verified.
- save-settings v14 verified.
- permissions verified.
- current no-op with exact current values = changed=false.
- test transaction rolled back.

## الذي لا يمكن إغلاقه قبل Owner Source Change
Browser E2E الكامل على Mother cannot be marked PASS before the two source lines are actually changed.

والسبب ليس نقصًا في Production:
بل أن current published Source نفسه يحتوي SyntaxError.

Workflow الموجود:
\`RAWAEA — Mother System Browser E2E\`

Run:
\`35436461845\`

في آخر تشغيل على commit \`cfc63ad...\` لم يصل إلى Playwright execution لأن pre-browser assertion failed.

**لا تُسجل Browser E2E = PASS قبل إعادة التشغيل بعد Owner patch.**

---

# 18. OWNER VERIFICATION — التسلسل الإلزامي

بعد تنفيذ الجراحتين فقط:

1. Commit التعديل على Mother.
2. شغّل:
   \`RAWAEA CTO — published main.html full forensic gate\`
3. يجب أن:
   - يختفي \`SyntaxError: Unexpected string\`
   - يمر Exact JavaScript syntax gate.
4. شغّل:
   \`RAWAEA — Forensic Mother Assembly Guard\`
5. شغّل:
   \`RAWAEA — Mother System Browser E2E\`
6. في المتصفح:
   - Login.
   - الانتقال إلى إعدادات النظام.
   - ظهور الصفحة كاملة.
   - ظهور Company Logo.
   - ظهور Store section.
   - عدم وجود Console SyntaxError.
   - تنفيذ no-op save.
   - تغيير قابل للعكس على حقل عرضي ثم Save/Reload للتحقق من consumer flow، ثم إعادة القيمة الأصلية.
7. طابق Production:
   - app_settings
   - audit_log
   - companies.main_branch projection إن تغير main branch.
8. لا تعتمد نجاح Browser E2E على SQL PASS فقط.

---

# 19. Production Changes This Cycle

**لا توجد DDL أو Data Changes Production جديدة في هذه الدورة.**

السبب:
- Settings backend closure مثبت مسبقًا.
- save-settings v14 active ومتطابق وظيفيًا مع Git.
- save_system_settings_atomic current.
- main branch projection trigger current.
- no-op verified with the actual current logo and current settings.
- لا يوجد Business Contract جديد مثبت يسمح بتوسيع schema بأمان في هذه اللحظة.

وهذا أفضل من اختراع إصلاح بنية لا يحتاجه الـcurrent defect.

---

# 20. Data / History Reconciliation

ظهر أثناء التحقيق تعارض بين Snapshot أقدم في Report250 وقيمة \`company_logo\` الحالية.

Current Production أثبتت الآن:
- \`company_logo\` موجود فعليًا.
- updated_at بقي عند:
  \`2026-09-13 06:10:00.144+00\`

وبالتالي لا يتم حذف أو تصفير الشعار.
الاختبار الصحيح للـNo-Op استخدم القيمة الحالية الفعلية وأثبت:
\`changed=false\`

وهذا يغلق التضارب على مستوى Current Reality دون تعديل البيانات الصحيحة.

---

# 21. FINAL SELF-AUDIT

## What I Proved
- Current System HEAD and parent.
- Current Mother HEAD and parent.
- Current main.html blob.
- Current Settings implementation already Page.
- Exact root cause of SyntaxError.
- Exactly 2 malformed logo onerror occurrences.
- Production Settings writer and Edge state.
- Current app_settings data.
- Main-branch projection synchronization.
- Current no-op behavior.
- Competitive Settings patterns from current official documentation.

## What I Fixed
- No Mother source change by CTO, by Owner Source Rule.
- No unnecessary Production DDL/Data change.
- This cycle produced the exact surgical source correction required for the browser syntax defect.
- The existing Production Settings foundation remains untouched because it is currently correct.

## What I Initially Missed During This Cycle
- The prior no-op anomaly was caused by comparing against an outdated \`company_logo=null\` snapshot instead of the current actual logo value. After using the actual current value, no-op returned \`changed=false\`.

## What Could Still Be Wrong
- Browser runtime cannot be declared PASS until Owner applies the two exact lines and the CI/browser workflows rerun.
- The broader competitor-level legal/payment/localization settings are not yet an opened Business Contract and must not be created by assumption.

## Final status
**SETTINGS BACKEND / PRODUCTION CONTRACT = PRODUCTION VERIFIED**

**SETTINGS CURRENT SOURCE = FORENSIC ROOT CAUSE PROVEN**

**SETTINGS OWNER SOURCE PATCH = READY**

**BROWSER E2E = OPEN UNTIL OWNER PATCH + CI**

**MODAL → PAGE = ALREADY CLOSED IN CURRENT SOURCE**

**PRODUCTION DATA REPAIR = NOT REQUIRED**

---

# 22. NEXT EXACT RESUMPTION POINT FOR THE NEXT CTO

ابدأ من هذا التقرير ولا تعد إلى Report250 لإعادة بناء الحالة.

### Step 1
Verify:
\`e652d0af323fad0f3dea5b32115a6af6cd17e58b\`

### Step 2
Verify Mother:
- HEAD \`5c1e10d805a499594ec14d653f466cd05e7204dc\`
- parent \`cfc63ad204f8af0faec3fbfafd75dfe0aee80d0b\`
- main.html blob \`6241363f7f54bcff0356cd39f9253d1930b5fd68\`

### Step 3
Verify exactly two occurrences:
- \`settings-company-logo-preview\` malformed onerror at line 5362.
- \`settings-store-logo-preview\` malformed onerror at line 5374.

### Step 4
Owner applies the two full-line replacements in this report.

### Step 5
Run:
- published main.html forensic gate
- Mother Assembly Guard
- Mother Browser E2E

### Step 6
Only after Browser E2E passes:
- update this closure from OPEN to CLOSED.
- update CURRENT_STATE.
- do not re-open Production Settings backend unless new evidence shows Regression.

### Do not do
- Do not recreate RW_Settings.
- Do not change save-settings.
- Do not create a second settings writer.
- Do not add arbitrary app_settings fields.
- Do not alter inventory/field operational apps.
- Do not touch reports-comprehensive or other tabs in this closure.

**Exact continuation target:** Owner Source Patch → CI Syntax PASS → Mother Browser E2E PASS → Production recheck → Settings Closure.
