# Report561 — تدقيق أهلية المرتجعات وإغلاق عقد الخادم
التاريخ: 2026-10-29  
الحالة: **PRODUCTION START/COMPLETE/CANCEL GUARDS DEPLOYED + SOURCE SNAPSHOTS SYNCED / UI OWNER PATCH REQUIRED / REOPEN + ZERO-QTY CORE AUDIT OPEN / NOT CLOSED**

## 1. الخلاصة التنفيذية

- **CONFIRMED:** المالك سبق أن عدّل استعلام البحث في التزام GitHub رقم \`2e9777a23f44e1b009810c0936513a76e64cc741\` ليضيف \`return_handler_id\` إلى \`select\`. لذلك لا يجوز إعادة اقتراح هذا التغيير وكأنه جديد. قصور المراجعة السابق نتج عن الاعتماد على بصمة قديمة للملف.
- **CONFIRMED:** ذلك التغيير وحده لا يصلح الأهلية؛ استعلام البحث الحالي لا يجلب \`id\`، ولا يقيّد نتائج \`Returning\` بالمستخدم المسند إليه، ولا يفحص رصيد المرتجع المتبقي، ولا يعالج خطأ الاستعلام.
- **CONFIRMED:** القائمة الرئيسية والمعاينة في \`main\` لا تزالان تسمحان بظهور رانشيتات \`Delivered\` بلا كمية مرتجعة متبقية، لأنهما لا يخصمان \`qty_returned\` في كل مسار.
- **PRODUCTION CHANGE APPLIED:** جرى تحصين الدوال الموجودة \`start-return\` و\`complete-return\` و\`cancel-return\`؛ لم تُنشأ Edge Function جديدة. أعيدت قراءة النسخ المنشورة بعد النشر.
- **NOT CLOSED:** ملف HTML التشغيلي لا يزال يحتاج Owner Patch؛ لم يتم تغييره مباشرة. كما أن أزرار الإلغاء وإعادة الفتح ومنطق العجز بصفر كمية كشفوا عقودًا إضافية تتطلب إصلاحًا ذريًا خاصًا بها قبل اعتبار دورة المرتجعات مغلقة.

## 2. التاريخ والمصادر التي تمت مراجعتها

1. الدستور التشغيلي الدائم: \`doc/Draft/Reprots/الدستور التشغيلي الدائم.md\`، blob SHA \`365a5178810d8da37f55dba64bf422f328a966bd\`.
2. سجل الحالة السابق: \`CURRENT_STATE.md\`، تمت قراءته قبل هذه الدورة من blob SHA \`fd672c1aac4727bf7ae10e5dce02f4d23a63a50f\`، وكان آخر checkpoint هو Report560.
3. تقارير المرتجعات السابقة التي أُعيدت قراءتها: Report560 وReport559 وReport557 وReport552. استُخدمت لتتبع سبب إنشاء PR #8 وحدود Owner Patch، مع إعادة التحقق من المصدر الحي بدل التسليم بصحة التقرير.
4. الملف التشغيلي الحالي: \`erp-frontend/companies/company-1/warehouse/returns.html\` في \`main\`، blob SHA الحالي \`c284f88ba0c7d4c0373b66f826f8a3c8c11599b7\`، 1,123 سطرًا.
5. الالتزام الذي أضاف \`return_handler_id\` لاستعلام البحث: [2e9777a23f44e1b009810c0936513a76e64cc741](https://github.com/papamohammed77-glitch/erp-frontend/commit/2e9777a23f44e1b009810c0936513a76e64cc741). تغييره في هذا الملف هو إضافة الحقل إلى الإسقاط، وليس إصلاح الأهلية بالكامل.
6. PR #8 ما زال Draft/Open/Unmerged، وHead \`3ad370c83f8f3c7880d7ace9ac24eabb5833f9cf\`. فرع الإصلاح متباعد عن \`main\`: ahead by 2 / behind by 1، والالتزام الجديد على \`main\` لم يُدمج إلى فرع PR. لا يُدمج PR اعتمادًا على حالته القديمة.

## 3. العقد التشغيلي الصحيح

### أهلية ظهور الرانشيت
المعيار المستخدم يجب أن يكون موحدًا في القائمة والبحث والمعاينة:

\`\`\`text
pending_qty = max(qty_loaded - qty_delivered - qty_returned, 0)
\`\`\`

- \`Delivered\`: يظهر فقط إذا كان هناك صنف واحد على الأقل لديه \`pending_qty > 0\`.
- \`Returning\`: يظهر في المهام النشطة للمستخدم المسند إليه فقط.
- \`return_handler_id\` في قاعدة البيانات من النوع UUID؛ دالة البدء تكتب \`users.id\`، و\`RW_Auth\` يعرّف \`currentUser.id\` من ملف المستخدم. لذلك يكون التطابق على \`currentUser.id\`، لا على البريد الإلكتروني.
- يجب أن تبقى تفاصيل عدد الأصناف متوافقة مع \`renderSearchDropdown()\` التي تقرأ \`run_sheet_details[0].count\`. لا تُحوّل شكل بيانات البحث إلى \`detail_count\` من دون تعديل المستهلك في نفس الرقعة.

### إثبات Production للبيانات الحالية
استعلام SQL للقراءة فقط أعاد:
- \`RS-1\`: الحالة \`Delivered\`، 5 مجموعات أصناف، الوحدات المتبقية المؤهلة = 0؛ يجب ألا يظهر في قائمة المتاح.
- \`RS-2\`: الحالة \`Delivered\`، 7 مجموعات أصناف، الوحدات المتبقية = 5، ومجموعات الأصناف ذات الكمية المتبقية = 5؛ يجب أن يظهر.
- مقارنة التجميع بين الإسقاط \`run_sheet_details\` والمصدر \`order_details\` نجحت في 12/12 مجموعة صنف/رانشيت ولم يظهر اختلاف في قيم التحميل أو التسليم أو المرتجع.

## 4. إصلاحات Production المنفذة

### \`start-return\`
- قبل الإصلاح: النسخة 4، hash \`dfbf2100038af2df8e45f8c0b0860c98b3d7f6d6f2c7048aa1be42d82bf3cb9f\`.
- بعد الإصلاح: **version 5**, \`ACTIVE\`, \`verify_jwt=true\`, hash \`47e92999e1585956bf9f25fcf6ec80921ceef71316a59a7b5a1c2b1d6290d493\`.
- الإصلاح: ربط المستخدم عبر \`users.auth_id\`؛ فحص صلاحية \`warehouse\` في الصلاحيات المباشرة أو صلاحيات الدور؛ تحقق مالك مبني على سجل \`owner_profile\` مع صلاحية \`*\` في قاعدة البيانات، دون اتخاذ \`user_metadata\` وحده مصدرًا للتفويض؛ فرض الدور المخزني \`مرتجعات\` لغير المالك؛ تحديد الشركة في قراءات/تحديث الرانشيت؛ رفض بدء أي رانشيت لا يحتوي كمية متبقية موجبة؛ والتحقق من أن تحديث حالة \`Delivered\` أصاب صفًا واحدًا.
- أعيد جلب المصدر المنشور بعد التحديث وتم التأكد من وجود الحراس المطلوبة.

### \`complete-return\`
- قبل الإصلاح: النسخة 26، hash \`801e390b195522caedfcf68bae8262bb91da06e909c1d43e9344490e3a81f34d\`.
- بعد الإصلاح: **version 27**, \`ACTIVE\`, \`verify_jwt=true\`, hash \`3b4d7ff8053ca35813ad24639093549e7aec622d784a3d18bbfa9ef3d54f9da1\`.
- في مسار الرانشيت فقط: يحمّل المستخدم المرتبط بجلسة المصادقة، يتحقق من صلاحية المخازن والدور \`مرتجعات\`، ويقرأ الرانشيت ضمن شركة المستخدم، ويشترط \`status = Returning\` وأن يساوي \`return_handler_id\` معرّف المستخدم المسند إليه.
- مسار POS/الأوردر الذي لا يرسل \`runsheet_code\` بقي خارج شرط تعيين الرانشيت؛ لم تُغيّر أسماء معاملات RPC الخاصة به.
- أثناء النشر تعذر تحميل اعتماد JSR الخاص بتعريفات الأنواع بسبب مهلة خارجية. أزيل استيراد تعريفات الأنواع فقط؛ نجح النشر اللاحق وأُعيد جلب النسخة 27 والتحقق من الحراس ومسار POS.
- صلاحيات SQL الحية التي فُحصت: RPC المركزي \`complete_sales_return_credit_note_atomic\` و\`complete_return_atomic\` لا يملك \`authenticated\` حق \`EXECUTE\` عليهما، بينما \`service_role\` يملكه؛ بقي حد الثقة بين Edge والخادم المركزي قائمًا.

### مزامنة مصدر المشروع
تمت مزامنة ملفات المصدر في \`rawaie-erp-New/Current/Edge_Functions/\` بعد إعادة قراءة Production:
- \`start-return\`: blob \`34c05bef9dc8aaf38f0b61813f1674b3a738bafb\`، مطابق بايتًا لنسخة Production 5.
- \`complete-return\`: blob \`ecd2681a84fdeaee6bcb31a63abd31e0fef0858d\`، مطابق بايتًا لنسخة Production 27.
- \`cancel-return\`: snapshot الإصدار 4، blob \`6434e7506ec32c59c4863ae5a79dd753e841a1fd\`، مطابق بايتًا لنسخة Production الحالية.
- \`reopen-return\`: أُضيف snapshot مطابق للنسخة الحالية 1، blob \`fb9a0f2e4dbbfec9c8ef24e847d27b800280030a\`.
تلك الملفات سجلات مصدر حالي وليست Edge Functions جديدة.

## 5. الاختبارات المنفذة

### SQL معزول — أهلية الكمية
نفّذ استعلام CTE للقراءة فقط 6 حالات: تسليم كامل بلا مرتجع، تسليم جزئي، مرتجع جزئي مع بقاء رصيد، استنفاد كامل للكمية المتبقية، كميات NULL، وناتج سالب يُخفض إلى صفر. **6/6 PASS**. لم تُدرج أو تُعدّل أو تُحذف أي بيانات أعمال.

### SQL معزول — عقد التفويض
نفّذ استعلام CTE للقراءة فقط 7 حالات: المستخدم المخوّل، دور مخزني خاطئ، غياب صلاحية المخازن، مالك موثق، مستخدم غير مسند إليه، اختلاف الشركة، ورانشيت بلا كمية متبقية. **7/7 PASS** لشروط البدء والإكمال كلٌ على حدة. هذا اختبار لمنطق السياسة وليس اختبار HTTP حقيقيًا للدالة.

### حدود التحقق
- لا توجد فروع Supabase staging متاحة في المشروع.
- قرأت لوحة Cloudflare الحالية: نشر Production لالتزام \`2e9777a23f44e1b009810c0936513a76e64cc741\` ما زال \`Queued\` في آخر مشاهدة؛ صف Production ما زال يشير إلى \`416de1c1d829c48b7c82442242a2a039e3d7e48c\`. لذلك لم يثبت بعد أن آخر مصدر HTML وصل إلى ملف Pages المنشور.
- لا توجد حاليًا رانشيتات \`Returning\` أو \`Returned\` في Production؛ الموجودان اللذان تم فحصهما كلاهما \`Delivered\`. لم أستخدم سجلًا تشغيليًا حيًا لتجربة بدء/إكمال/إلغاء.
- لم يُثبت تطابق ملف HTML المنشور على Cloudflare مع blob الحالي، ولم يُنفّذ اختبار متصفح مصادق عليه End-to-End. لذلك لا يُعلن إغلاق المهمة بالكامل.

## 6. Owner Patch المتبقي — البحث

الهدف هو \`erp-frontend/companies/company-1/warehouse/returns.html\`، فرع \`main\`، blob SHA \`c284f88ba0c7d4c0373b66f826f8a3c8c11599b7\`. هذه الرقعة **لم تُطبّق** لأن قواعد المشروع تجعل التعديل في HTML التشغيلي Owner-only. المقطع الحالي يتضمن بالفعل \`return_handler_id\`، لكنه لا يحتوي \`id\` ولا فلترة الأهلية:

~~~javascript
        this.searchTimer = setTimeout(function() {
            supabase.from('runsheets').select('runsheet_code, status, run_date, driver_id, return_handler_id, run_sheet_details(count)').in('status', ['Delivered', 'Returning']).ilike('runsheet_code', '%' + query.trim() + '%').limit(10).then(function(res) {
                self.searchResults = res.data || [];
                self.renderSearchDropdown();
            });
        }, 300);
~~~

استبدال **دالة onSearchInput كاملة** بالكتلة التالية، مع إبقاء \`renderSearchDropdown()\` الحالية كما هي لأنها ما زالت تقرأ علاقة \`run_sheet_details(count)\`:

~~~javascript
    onSearchInput: function(query){
        var self = this;
        var searchText = String(query || '').trim();
        if (this.searchTimer) clearTimeout(this.searchTimer);

        if (!searchText) {
            this.searchResults = [];
            var dd = RW_UI.byId('searchDropdown');
            if (dd) dd.classList.add('hidden');
            return;
        }

        var showSearchError = function(message, error) {
            console.error('[RW_Returns] ' + message, error || '');
            self.searchResults = [];
            var dropdown = RW_UI.byId('searchDropdown');
            if (dropdown) {
                RW_UI.safeHTML(dropdown, '<div class="p-4 text-center text-red-500 text-sm">تعذر البحث عن الرانشيت. تحقق من الاتصال والصلاحيات ثم حاول مرة أخرى.</div>');
                dropdown.classList.remove('hidden');
            }
        };

        this.searchTimer = setTimeout(function() {
            supabase.from('runsheets')
                .select('id, runsheet_code, status, run_date, driver_id, return_handler_id, run_sheet_details(count)')
                .in('status', ['Delivered', 'Returning'])
                .ilike('runsheet_code', '%' + searchText + '%')
                .order('run_date', { ascending: false })
                .limit(50)
                .then(function(res) {
                    if (res.error) {
                        showSearchError('runsheet search query failed:', res.error);
                        return;
                    }

                    var rows = res.data || [];
                    if (!rows.length) {
                        self.searchResults = [];
                        self.renderSearchDropdown();
                        return;
                    }

                    var rowIds = rows.map(function(rs) { return rs.id; }).filter(Boolean);
                    if (!rowIds.length) {
                        self.searchResults = [];
                        self.renderSearchDropdown();
                        return;
                    }

                    return supabase.from('run_sheet_details')
                        .select('runsheet_id, qty_loaded, qty_delivered, qty_returned')
                        .in('runsheet_id', rowIds)
                        .then(function(detailsRes) {
                            if (detailsRes.error) {
                                showSearchError('runsheet search details query failed:', detailsRes.error);
                                return;
                            }

                            var pending = {};
                            (detailsRes.data || []).forEach(function(det) {
                                var remaining = (Number(det.qty_loaded) || 0)
                                    - (Number(det.qty_delivered) || 0)
                                    - (Number(det.qty_returned) || 0);
                                if (remaining > 0) pending[det.runsheet_id] = true;
                            });

                            self.searchResults = rows.filter(function(rs) {
                                if (rs.status === 'Delivered') return pending[rs.id] === true;
                                if (rs.status === 'Returning') {
                                    return !!self.currentUser && !!self.currentUser.id
                                        && rs.return_handler_id === self.currentUser.id;
                                }
                                return false;
                            }).slice(0, 10);

                            self.renderSearchDropdown();
                        });
                })
                .catch(function(error) {
                    showSearchError('unexpected runsheet search failure:', error);
                });
        }, 300);
    },
~~~

هذه الرقعة تحفظ عدد الأصناف من العلاقة المتداخلة، وتضيف المفتاح الذي تحتاجه تفاصيل الكميات، وتوحد أهلية البحث مع العقد المعتمد، وتُعيد وعد استعلام التفاصيل حتى يصل خطأ الرفض إلى المعالجة الخارجية. لا تُكرر إضافة \`return_handler_id\` وحدها؛ فهي موجودة بالفعل في المصدر الحالي.

### حدود pagination في Owner Patch
استعلام البحث يفلتر أهلية الكميات بعد جلب دفعة مرشحين؛ لذلك فإن أي \`limit(50)\` قبل التصفية قد يخفي نتيجة مؤهلة إذا احتوت الدفعة على 50 نتيجة غير مؤهلة. وكذلك قائمة \`loadRunsheets()\` الحالية تقطع \`Delivered\` عند 50 قبل حساب الأهلية. في البيانات الحالية يوجد رانشيتان فقط، لذا لم يظهر أثر هذا الحد في العدّ الحالي؛ لكنه قيد توسع مؤكد من ترتيب العمليات. قبل اعتماد استخدام واسع، يجب أن تكون القراءة paginated بترتيب ثابت وتستمر حتى استنفاد الصفحات أو جلب العدد المطلوب من النتائج المؤهلة، أو يُعاد استخدام عقد قراءة مركزي موجود بعد التحقق من صلاحياته؛ لا تُضف RPC/Edge جديدًا لمجرد تجميل الفلترة.

## 7. تصحيحات واجهة مترابطة مطلوبة قبل الإغلاق

1. في \`loadRunsheets()\`: استخدام \`qty_returned\` في استعلام التفاصيل، وعدم عرض \`Delivered\` إلا إذا كان مجموع/أي صنف يملك كمية متبقية موجبة؛ مع إبقاء معالجة أخطاء الاستعلامين. منطق ذلك موجود في PR #8 لكنه لم يُدمج، وفرع PR يحتاج أولًا إلى مزامنة التزام \`2e9777a\`.
2. في \`renderPreview()\`: التعبير الحالي هو تحميل ناقص تسليم؛ يجب أن يخصم \`qty_returned\` أيضًا. هذا مطلوب لتجنب اختلاف المعاينة عن القائمة والبحث.
3. في \`openReturn()\`: شرط المستخدم النشط ما زال يقارن \`return_handler_id\` بالـ ID أو البريد. عقد العمود UUID، لذلك يوحّد إلى ID فقط.
4. في \`loadRunsheets()\`: لا حاجة إلى \`this.currentUser.id || this.currentUser.email\` لعمود UUID؛ استخدم ID المعتمد في الملف المشترك.
5. في \`saveReturnItem()\`، الأسطر 885–888، توجد محاولة UPDATE مباشرة على \`run_sheet_details\` ثم تجاهل النتيجة. Production يؤكد أن \`authenticated\` لا يملك UPDATE على هذا الإسقاط ولا توجد له سياسة كتابة. تبقى نسخة المسودة المحلية في Dexie؛ يجب إزالة الكتابة الشبكية غير المصرح بها ضمن Owner Patch.
6. في \`cancelReturn()\`، الأسطر 445–455، لا تُحذف مسودات \`db.localChanges\` بعد نجاح الإلغاء، بينما \`_loadLocalChanges()\` يعيد تحميلها. يجب مسح تغييرات الرانشيت محليًا بعد نجاح الإلغاء حتى لا تعود بيانات مسودة ملغاة عند فتحه لاحقًا.

## 8. فجوات إضافية في دورة المرتجعات — مؤكدة وتحتاج مهمة إصلاح ذرية مستقلة

لا أعدّ هذه النقاط مغلقة بمجرد تحصين start/complete:

- **\`cancel-return\` v4 — تصحيح آمن جزئيًا:** أصبح يربط المستخدم عبر \`auth_id\`، ويتحقق من صلاحية المخازن والدور، ويقيّد الرانشيت بالشركة والمسند إليه، ويشترط تحديثًا مشروطًا أصاب صفًا واحدًا. أزيل تصفير \`run_sheet_details\` لأنه إسقاط مشتق؛ إلغاء الجلسة الجديدة لا يعدّل كميات المصدر أو المخزون. ولأن \`reopen-return\` الحالي يخصم مخزونًا دون عكس موثق، تمنع الدالة إلغاء جلسة إعادة فتح تحمل \`return_end\` سابقًا بدل تحويلها خطأً إلى \`Delivered\`. هذا يحمي المسار الجديد، لكنه لا يصلح بعد عقد إعادة الفتح ذاته.
- **\`reopen-return\` v1:** يختار \`app_settings\` باستخدام \`limit(1)\` بلا \`company_id\`، ويعدّل \`stock_branches.qty\` مباشرة باستخدام \`Math.max(0, ...)\`، دون المرور عبر \`post_stock_movement\` ودون سجل حركة مخزون موحد أو فحص أخطاء التحديث؛ وهذا قد يخفي عجزًا أو يخلّف أثرًا مخزنيًا غير قابل للتتبع. كما أنه لا يصفّر الكمية المرتجعة في المصدر \`order_details\` قبل إعادة فتح الرانشيت.
- **\`complete_return_atomic\`، SQL المركزي:** يمر على \`if v_returned <= 0 then ... continue\` قبل معالجة باقي سياق الصنف. واجهة الإكمال تسمح بكمية عائدة صفر مع ملاحظات لنقص/عجز، لكن هذا المسار المركزي قد يتجاوز تسجيل العجز/المسؤولية للخط الذي قيمته صفر. لا أعدل هذه الدالة المحاسبية في رقعة واجهة؛ يلزم تحديد دلالة كميات السليم/التالف/المفقود ثم اختبار معاملات معزولة تشمل المخزون، مسؤولية السائق، الإشعار الدائن وسجل العملية، قبل النشر.
  
هذه النقاط تستحق فصلًا واعتمادًا واختبارات مستقلة؛ إصلاحها بتعديلات نصية صغيرة من دون عقد معاملات واضح يعرض المخزون والدفاتر لخطر التباين.

## 9. المقارنة المرجعية مع أنظمة المؤسسات

المرجعان الرسميان المتحقق منهما يميزان بين استرجاع مادي للبضاعة وبين إشعار دائن فقط، ويفصلان استلام المرتجع وفحص الجودة وتحديد المصير اللوجستي عن التعويض المالي:
- Microsoft Dynamics 365 Supply Chain Management — Sales returns: https://learn.microsoft.com/en-us/dynamics365/supply-chain/sales-marketing/sales-returns
- SAP S/4HANA — Customer Returns Processing: https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/7b24a64d9d0941bda1afa753263d9e39/ef17554b70b946e588cf4fb378fa4622.html

هذا يدعم اتجاه الروائع نحو عقد واحد يربط المستخدم والشركة والرانشيت والكميات والمخزون والتسوية والإشعار الدائن، لا مسارات مستقلة. ولا يعني أن كل مراحل المرجعين غائبة في الروائع؛ المطلوب هو استكمال التحقق من دورة الإلغاء وإعادة الفتح والمفقود قبل تحديد أي تطوير أوسع.

## 10. حكم الإغلاق

**CONFIRMED:** تم تحصين \`start-return\` v5 و\`complete-return\` v27 و\`cancel-return\` v4 على Production وإعادة قراءة مصادرها المنشورة. اختبارات SQL المعزولة: الكمية 6/6، وسياسة التفويض 7/7، ومقارنة projection/source 12/12. فُحصت حراس cancel-return بعد النشر (auth_id، صلاحية/دور المرتجعات، الشركة، المسند إليه، منع الإلغاء بعد إعادة فتح مرتجع مكتمل، وعدم تصفير الإسقاط)، لكن هذا فحص مصدر وليس HTTP E2E. لم تتغير بيانات أعمال ولم تُعدّل جداول/RLS/ACL أو RPC مركزي.

**UNVERIFIED / OPEN:** Owner Patch للـ HTML لم يطبق؛ Cloudflare لا يزال يعرض نشر commit \`2e9777a\` على \`Queued\` والمصدر المباشر المنشور لم يُثبت بعد؛ لم ينفذ HTTP/browser E2E مصادق عليه لعدم وجود staging أو رانشيت \`Returning\` مناسب للاختبار. \`reopen-return\` v1 ما زال غير ذري ويعدّل المخزون خارج \`post_stock_movement\`؛ كما أن العجز عند كمية مرتجعة صفر ما زال يحتاج عقدًا ذريًا واختبارات محاسبية/مخزنية.

**STATUS: START/COMPLETE/CANCEL EDGE GUARDS DEPLOYED / LIVE SOURCE MIRRORED / CLOUDFLARE HTML DEPLOYMENT QUEUED / OWNER UI PATCH REQUIRED / REOPEN + ZERO-QTY CORE CONTRACT OPEN / NOT CLOSED.**
