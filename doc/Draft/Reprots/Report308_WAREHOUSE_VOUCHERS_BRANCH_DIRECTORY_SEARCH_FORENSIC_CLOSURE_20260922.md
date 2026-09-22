# Report308 — التحقيق الجنائي لإصلاح دليل الفروع والبحث الذكي في تطبيق الأذونات المخزنية
## RAWAEA ERP — 2026-09-22

### 1. نطاق الجلسة والحالة المعتمدة

هذه الجلسة أوقفت أي مسار سابق وانتقلت فقط إلى closure الخاص بتطبيق:

`companies/company-1/warehouse/vouchers.html`

مع عدم تعديل:
- `companies/company-1/main.html`
- `companies/company-1/warehouse/vouchers.html`
- `companies/company-1/sales/van-sales.html`

التعديل على `vouchers.html` بقي **Owner-Applied Surgical Patch** حسب ملكية الملف المطلوبة.

مصادر الحقيقة التي تمت قراءتها حتى EOF:
- `doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`
- `CURRENT_STATE.md`
- `Report306_WAREHOUSE_VOUCHERS_FORENSIC_E2E_COMPETITIVE_CLOSURE_20260922.md`
- `Report307_WAREHOUSE_VOUCHERS_CURRENT_FORENSIC_PATCH_20260922.md`

التحقق:
- Governance: 2606 lines، EOF مثبت.
- CURRENT_STATE قبل هذا التقرير: 11429 lines، EOF مثبت.
- Report306: 1328 lines، EOF مثبت.
- Report307: 619 lines، EOF مثبت.

### 2. Current Git قبل التعديل

System repository:
- HEAD: `6eef18229baf6983cca11f3a698ebf7fd74f80e3`
- Parent: `3c083b9ead654314edbc3f6323c39f6260ebf23e`
- آخر تغيير: تسجيل checkpoint لحالة vouchers.

Frontend repository:
- HEAD: `d928651db9225eec3a5ab75e34a1f0e33b46020b`
- Parent: `d0796cd96c58e6f7b108d406b0e28f69fc4f06b2`
- `vouchers.html` current blob: `7afa218e478109e90c945f0c608f072f20129eb6`
- `main.html` current blob المثبت في الحالة: `8c3d6b05fd6a94a6b488f12b29da85ae888f70bc`
- `van-sales.html` current blob: `8d61382a8e0025a0d079e71dd94f33d106d9088e`

Commit `d928651...` أصلح بالفعل ربط زر التصدير إلى `exportVoucherList()` وأغلق `listType` قبل `listStatus`، لكنه ترك إغلاق `</select>` زائدًا بعد `listStatus`.

### 3. إعادة بناء الدور المعماري

تطبيق الأذونات المخزنية ليس امتدادًا لدورة Order/Runsheet؛ بل هو surface تشغيلي مستقل للحركات المخزنية غير المرتبطة بالأوردرات والرانشيتات:

- Transfer
- DirectSale / عهدة مركبة
- DirectReturn / إرجاع عهدة
- SupplierReturn
- Adjustment / Scrap

العقد المركزي الذي لم يتغير:

`Physical Stock Movement → post_stock_movement → stock_branches + inventory_log`

تطبيق Van Sales بقي surface ميدانيًا مستقلًا لبيع المركبة، ويستخدم:
- vehicle branch
- `stock_branches`
- `save-sales-invoice`
- `save-inventory-count`

ولا توجد إحالة من `van-sales.html` إلى `vouchers.html` أو `stock_vouchers` في المصدر الحالي.

### 4. Production Reality

Snapshot النهائي في:

`2026-09-22 17:24:57.934528+00`

العدادات:
- stock_vouchers = 23
- stock_voucher_details = 25
- stock_voucher_operations = 24
- inventory_log = 26
- audit_log = 2106

بيانات الفروع الحالية للشركة الرئيسية:
- BR-01 — الفرع الرئيسي
- BR-2 — فرع إسكندرية
- VAN-VEH-TEST-260921 — سيارة VEH-TEST-260921 - س ن ر 6021

### 5. التحقيق الجنائي — سبب العطل الأول: Branch Scope

المصدر الحالي لـ`vouchers.html` يحمل جميع فروع الشركة من Production بصورة صحيحة:

`branches`
- company-scoped
- active only
- ordered by name

لكن commit:

`fedd7138f7c8b266ae820f2c914f33298715d0e8`

غيّر سلوك `pickArr()` من:
- إرجاع `refs.branches` مباشرة

إلى:
- بناء `userBranches`
- ثم إرجاع `userBranches`

وبالتالي أصبح العرض في الحقل خاضعًا لـ`allowed_branch_ids`.

Production الحالي يثبت:
- `vouchers@rawaea.com` → `BR-01`
- `warehouse.manager@rawaea.com` → `BR-01`
- `warehouse.supervisor@rawaea.com` → `BR-01`
- OWNER → `["*"]`

وفي الوقت نفسه RLS الحالي على `branches` يسمح لمستخدم الشركة الذي يحمل صلاحية `warehouse` أو `branches` بقراءة فروع الشركة كلها.

النتيجة:
**الواجهة كانت تضيق القراءة أكثر من عقد القراءة في Production، رغم أن عقد التنفيذ المخزني نفسه يجب أن يظل مقيدًا بالنطاق.**

### 6. التحقيق الجنائي — سبب العطل الثاني: Arabic Normalization

الدالة الحالية:

`norm:function(v){...`

تستخدم:
- `normalize('NFD')`
- إزالة نطاق Unicode اللاتيني `U+0300–U+036F`
- ثم تحويل الحروف العربية

لكن `NFD` يفكك بعض الحروف العربية إلى base character + combining mark.

Production-like reproduction أثبت:
- `norm("إسكندرية")` الحالي = `إسكندريه`
- `norm("اسكندرية")` الحالي = `اسكندريه`
- `"إسكندريه".includes("اسكندريه")` = false

لذلك حتى لو كان الفرع موجودًا في قائمة البحث، يمكن أن يفشل البحث بجزء الاسم بسبب علامة الجمع `U+0654`.

هذه هي العلة المباشرة لفشل البحث الذكي العربي.

### 7. لماذا لم نفتح الصلاحيات في Production

الـRPCs الحالية للحركات المخزنية تطبق branch-scope server-side.

Migration الحاكم:

`supabase/migrations/20260920_voucher_branch_scope_and_core_acl.sql`

يثبت:
- Transfer: المصدر والوجهة يجب أن يكونا ضمن نطاق المستخدم.
- DirectSale/SupplierReturn: المصدر يجب أن يكون ضمن النطاق.
- DirectReturn: وجهة المرتجع يجب أن تكون ضمن النطاق.
- OWNER wildcard / `["*"]` يبقى bypass شرعي.
- أي فرع غير مصرح به لا يجوز أن يصبح صالحًا للحركة بمجرد ظهوره في الـUI.

لذلك لم يتم تعديل `allowed_branch_ids` لأي مستخدم ولم يتم إلغاء أي server-side guard.

### 8. الحل المعماري

الحل ليس إخفاء الفروع، وليس فتح الصلاحية.

تم اعتماد فصل واضح:

**Visibility**
- جميع الفروع النشطة ضمن شركة المستخدم تصبح قابلة للرؤية والبحث في دليل الفرع.

**Authorization**
- الفرع غير الموجود في `allowed_branch_ids` يظهر كـ:
  - `غير مصرح`
  - disabled
  - بدون click handler
- ويعاد التحقق أيضًا داخل `pickSelect()`.

بهذا:
- يستطيع المخزن رؤية دليل الشركة كاملًا.
- يستطيع البحث باسم الفرع أو جزء منه.
- لا يستطيع تجاوز branch scope.
- يظل الـRPC هو الحارس النهائي.
- لا توجد ثغرة أمنية ناتجة عن إصلاح الواجهة.

### 9. Surgical Patch — OWNER APPLICATION ONLY

الملف المطلوب تعديله:

`companies/company-1/warehouse/vouchers.html`

لا تعدل `main.html`.

#### PATCH-V308-01 — إصلاح Arabic Normalization

**ابحث عن هذا العنصر تحديدًا داخل `var App={...}`:**

`norm:function(v){return String(v==null?'':v).toLowerCase().normalize('NFD').replace(/[\\u0300-\\u036f]/g,'').replace(/[إأآا]/g,'ا').replace(/ى/g,'ي').replace(/ة/g,'ه').replace(/ؤ/g,'و').replace(/ئ/g,'ي').replace(/\\s+/g,' ').trim()},`

**احذفه بالكامل واستبدله بهذا:**

```javascript
norm:function(v){
    return String(v==null?'':v)
        .toLowerCase()
        .normalize('NFD')
        .replace(/[\u0300-\u036f\u0610-\u061a\u064b-\u065f\u0670\u06d6-\u06ed]/g,'')
        .replace(/[ٱإأآا]/g,'ا')
        .replace(/ى/g,'ي')
        .replace(/ة/g,'ه')
        .replace(/ؤ/g,'و')
        .replace(/ئ/g,'ي')
        .replace(/ـ/g,'')
        .replace(/\s+/g,' ')
        .trim()
},
```

#### PATCH-V308-02 — إصلاح قائمة الفروع

**ابحث عن:**

`pickArr:function(key){`

**واحذف الدالة كاملة حتى الفاصلة التي تسبق:**

`pickShow:function(key){`

**واستبدلها بالكامل بهذا:**

```javascript
pickArr:function(key){
    var s=this,
        bid=(RW_UI.byId('wsFrom')||{}).value||'',
        b=(s.refs.branches||[]).find(function(x){
            return x.id===bid;
        }),
        allBranches=s.refs.branches||[],
        userBranches=allBranches.filter(function(x){
            return s.allowedBranch(s.user,x);
        });

    if(key==='wsFrom'){
        if(s.type==='DirectReturn'){
            return (s.refs.vehicles||[]).filter(function(v){
                var vb=s.vehicleBranch(v),
                    rep=(s.refs.reps||[]).find(function(r){
                        return r.id===v.driver_id;
                    });

                return v.status==='Active' &&
                       !!vb &&
                       s.allowedBranch(s.user,vb) &&
                       (!rep||s.allowedBranch(rep,vb));
            });
        }

        return allBranches;
    }

    if(key==='wsRep'){
        return (s.refs.reps||[]).filter(function(r){
            return !!b &&
                   s.allowedBranch(s.user,b) &&
                   s.allowedBranch(r,b);
        });
    }

    if(key==='wsTo'&&s.type==='Transfer'){
        return allBranches;
    }

    if(key==='wsTo'&&s.type==='DirectSale'){
        var rid=(RW_UI.byId('wsRep')||{}).value||'';

        return (s.refs.vehicles||[]).filter(function(v){
            var vb=s.vehicleBranch(v),
                rep=(s.refs.reps||[]).find(function(r){
                    return r.id===v.driver_id;
                });

            return v.status==='Active' &&
                   !!vb &&
                   !!b &&
                   rid &&
                   v.driver_id===rid &&
                   s.allowedBranch(s.user,b) &&
                   (!rep||s.allowedBranch(rep,b)) &&
                   s.allowedBranch(s.user,vb);
        });
    }

    if(key==='wsTo'&&s.type==='DirectReturn'){
        var vid=(RW_UI.byId('wsFrom')||{}).value||'',
            vv=(s.refs.vehicles||[]).find(function(x){
                return x.id===vid;
            }),
            rp=vv&&(s.refs.reps||[]).find(function(x){
                return x.id===vv.driver_id;
            });

        return userBranches.filter(function(x){
            return !rp||s.allowedBranch(rp,x);
        });
    }

    if(key==='wsTo'&&s.type==='SupplierReturn'){
        var m=(s.refs.supplierBranchMap||{})[bid];

        if(m&&Object.keys(m).length){
            return (s.refs.suppliers||[]).filter(function(x){
                return !!m[x.id];
            });
        }

        return [];
    }

    return allBranches;
},
```

#### PATCH-V308-03 — إصلاح البحث الذكي وعرض حالة الصلاحية

**ابحث عن:**

`pickSearch:function(key,q){`

**واحذف الدالة كاملة حتى الفاصلة التي تسبق:**

`pickSelect:function(key,id){`

**واستبدلها بالكامل بهذا:**

```javascript
pickSearch:function(key,q){
    var s=this,
        arr=this.pickArr(key)||[],
        z=this.norm(q),
        box=RW_UI.byId(key+'Menu');

    if(!box)return;

    var type=key==='wsRep'
        ?'rep'
        :(s.type==='DirectSale'&&key==='wsTo')
            ?'vehicle'
            :(s.type==='DirectReturn'&&key==='wsFrom')
                ?'vehicle'
                :(key==='wsTo'&&s.type==='SupplierReturn')
                    ?'supplier'
                    :'branch';

    var rows=arr.map(function(x){
        var a=type==='rep'
                ?(x.name||x.email||'')
                :type==='vehicle'
                    ?(x.vehicle_code||x.license_plate||x.model||'')
                    :(x.name||x.supplier_code||x.branch_code||''),
            b=type==='rep'
                ?(x.email||x.phone||'')
                :type==='vehicle'
                    ?(x.license_plate||x.vehicle_code||'')
                    :(x.supplier_code||x.phone||x.branch_code||''),
            na=s.norm(a),
            nb=s.norm(b),
            sc=!z?1:(na===z||nb===z?150:(na.indexOf(z)===0||nb.indexOf(z)===0?115:(na.indexOf(z)>=0||nb.indexOf(z)>=0?70:0))),
            allowed=type!=='branch'||s.allowedBranch(s.user,x);

        return {
            x:x,
            score:sc,
            allowed:allowed
        };
    })
    .filter(function(o){
        return o.score>0;
    })
    .sort(function(a,b){
        return b.score-a.score;
    })
    .slice(0,15);

    box.innerHTML=rows.length
        ?rows.map(function(o){
            var x=o.x,
                label=type==='rep'
                    ?(x.name||x.email)
                    :type==='vehicle'
                        ?(x.vehicle_code||x.license_plate||x.model)
                        :(x.name||x.supplier_code||x.branch_code),
                code=type==='rep'
                    ?(x.email||'')
                    :type==='vehicle'
                        ?(x.license_plate||x.vehicle_code||'')
                        :(x.supplier_code||x.branch_code||'');

            var action=o.allowed
                ? ' onclick="App.pickSelect(&quot;'+
                    s.esc(key)+
                    '&quot;,&quot;'+
                    s.esc(x.id)+
                    '&quot;)"'
                : ' aria-disabled="true" title="هذا الفرع ظاهر للبحث لكنه خارج نطاق تنفيذ المستخدم"';

            return '<div class="smart-row '+
                (o.allowed
                    ?'cursor-pointer'
                    :'opacity-60 cursor-not-allowed')+
                '"'+
                action+
                '>'+
                '<div>'+
                '<b class="text-xs text-white">'+
                s.esc(label)+
                '</b>'+
                '<div class="smart-code">'+
                s.esc(code)+
                '</div>'+
                '</div>'+
                '<span class="text-[9px] '+
                (o.allowed
                    ?'text-emerald-400'
                    :'text-amber-400')+
                '">'+
                (o.allowed?'اختيار':'غير مصرح')+
                '</span>'+
                '</div>';
        }).join('')
        :
        '<div class="smart-empty">لا توجد نتائج ضمن دليل الفروع/الكيانات الحالي</div>';

    box.classList.remove('hidden');
},
```

#### PATCH-V308-04 — حماية الاختيار نفسه

**ابحث عن:**

`pickSelect:function(key,id){`

**واحذف الدالة كاملة حتى الفاصلة التي تسبق:**

`routeHtml:function(){`

**واستبدلها بالكامل بهذا:**

```javascript
pickSelect:function(key,id){
    var s=this,
        arr=this.pickArr(key)||[],
        x=arr.find(function(z){
            return z.id===id;
        });

    if(!x){
        return;
    }

    var branchSelection=
        (key==='wsFrom'&&s.type!=='DirectReturn') ||
        (key==='wsTo'&&(
            s.type==='Transfer' ||
            s.type==='DirectReturn'
        ));

    if(branchSelection){
        var selectedBranch=
            (s.refs.branches||[]).find(function(branch){
                return branch.id===id;
            });

        if(
            !selectedBranch ||
            !s.allowedBranch(s.user,selectedBranch)
        ){
            RW_UI.toast(
                'هذا الفرع ظاهر للبحث، لكنه خارج نطاق فروع المستخدم المسموح بها',
                'error'
            );
            return;
        }
    }

    if(key==='wsFrom'&&s.type==='DirectReturn'){
        var vb=s.vehicleBranch(x);

        if(!vb){
            RW_UI.toast(
                'المركبة لا تملك مخزنًا متنقلًا صالحًا',
                'error'
            );
            return;
        }

        RW_UI.byId('wsFrom').value=x.id;
        RW_UI.byId('wsFromSearch').value=
            x.vehicle_code||x.license_plate;

        RW_UI.byId('wsFromMenu').classList.add('hidden');

        var r=
            s.refs.reps.find(function(rp){
                return rp.id===x.driver_id;
            });

        RW_UI.byId('wsRep').value=r?r.id:'';
        RW_UI.byId('wsRepSearch').value=
            r?(r.name||r.email):'';

        if(r){
            RW_UI.byId('wsRepSearch').setAttribute(
                'readonly',
                'readonly'
            );
        }else{
            RW_UI.byId('wsRepSearch').removeAttribute(
                'readonly'
            );
        }

        s.summary();
        s.renderProducts();

        return;
    }

    RW_UI.byId(key).value=x.id;

    if(key==='wsRep'){
        RW_UI.byId(key+'Search').value=
            x.name||x.email;

    }else if(
        key==='wsTo' &&
        s.type==='DirectSale'
    ){
        RW_UI.byId(key+'Search').value=
            x.vehicle_code||
            x.license_plate||
            x.model||
            '';

        var vehicleRep=
            (s.refs.reps||[]).find(function(rp){
                return rp.id===x.driver_id;
            });

        var sourceBranch=
            (s.refs.branches||[]).find(function(bb){
                return bb.id===(
                    (RW_UI.byId('wsFrom')||{}).value
                );
            });

        if(
            !vehicleRep ||
            !sourceBranch ||
            !s.allowedBranch(vehicleRep,sourceBranch)
        ){
            RW_UI.toast(
                'المركبة لا تملك مندوب بيع مباشر صالحًا لهذا الفرع',
                'error'
            );

            RW_UI.byId(key).value='';
            RW_UI.byId(key+'Search').value='';

            return;
        }

        RW_UI.byId('wsRep').value=vehicleRep.id;
        RW_UI.byId('wsRepSearch').value=
            vehicleRep.name||
            vehicleRep.email||
            '';

        RW_UI.byId('wsRepSearch').setAttribute(
            'readonly',
            'readonly'
        );

    }else if(
        key==='wsTo' &&
        s.type==='SupplierReturn'
    ){
        RW_UI.byId(key+'Search').value=
            x.name||
            x.supplier_code||
            '';

    }else{
        RW_UI.byId(key+'Search').value=
            x.name||
            x.vehicle_code||
            x.supplier_code||
            x.branch_code||
            '';
    }

    RW_UI.byId(key+'Menu').classList.add('hidden');

    if(
        key==='wsFrom' &&
        s.type==='DirectSale'
    ){
        var selectedRepId=
            (RW_UI.byId('wsRep')||{}).value||'';

        var selectedRep=
            (s.refs.reps||[]).find(function(rp){
                return rp.id===selectedRepId;
            });

        var keepRep=
            !!selectedRep &&
            s.allowedBranch(selectedRep,x);

        if(!keepRep){
            RW_UI.byId('wsRep').value='';
            RW_UI.byId('wsRepSearch').value='';
        }

        RW_UI.byId('wsRepSearch').removeAttribute(
            'readonly'
        );

        RW_UI.byId('wsTo').value='';
        RW_UI.byId('wsToSearch').value='';
    }

    if(
        key==='wsRep' &&
        s.type==='DirectSale'
    ){
        RW_UI.byId('wsTo').value='';
        RW_UI.byId('wsToSearch').value='';
        RW_UI.byId('wsRepSearch').removeAttribute(
            'readonly'
        );
    }

    s.updateSource();
},
```

### 10. PATCH-V308-05 — إصلاح HTML parser residue الحالي

الـHEAD الحالي بعد commit `d928651...` يحتوي على إغلاق زائد:

```text
'<option value="Cancelled">ملغى</option>'+
'</select>'+
'</select>'+
```

**ابحث عن هذا المقطع حرفيًا واستبدله بهذا:**

```text
'<option value="Cancelled">ملغى</option>'+
'</select>'+
```

لا تعدل زر التصدير؛ تم إصلاحه بالفعل إلى `App.exportVoucherList()`.

### 11. Production action executed

لم تكن هناك حاجة إلى:
- Migration schema جديدة.
- Edge Function جديدة.
- Edge Function replacement.
- تعديل RLS.
- تعديل `allowed_branch_ids`.

تم تنفيذ إجراء Production الوحيد المطلوب لاختبار الهدف بدون تلويث الرصيد:

#### Persistent QA
تم إنشاء:
- Voucher: `IN-23`
- Type: Transfer
- From: BR-01
- To: BR-2
- Status: Draft
- Reference: `QA-VOUCHERS-BRANCH-SEARCH-20260922`
- Details: 1
- Inventory movements: 0

هذا السجل **مقصود أن يبقى** ولا يتم حذفه.

### 12. Production Authorization E2E

اختبار إنشاء نفس التحويل بواسطة:

`vouchers@rawaea.com`

النتيجة:
- **REJECTED**

السبب: BR-2 خارج `allowed_branch_ids=BR-01`.

اختبار الإنشاء بواسطة OWNER:
- **SUCCESS**
- تم إنشاء `IN-23` ثم الاحتفاظ به كـDraft.

هذا أثبت أن:
- BR-2 فرع صالح في Production.
- عدم ظهور BR-2 في UI ليس دليلًا أن الفرع غير صالح.
- صلاحية الحركة نفسها ما زالت server-side enforced.

### 13. Static + Behavioral Verification

Current source:
- `vouchers.html`: 2980 lines / 124407 chars.
- 6 inline scripts: كل scripts الحالية اجتازت compile.

الجراحة المقترحة:
- الأربع دوال معًا: compile PASS.
- Arabic normalization:
  - `إسكندرية` → `اسكندريه`
  - `اسكندرية` → `اسكندريه`
  - partial match = PASS
- Branch directory:
  - company branches = 3
- Standard restricted user:
  - sees all company branch records = PASS after patch
  - search partial name = PASS
  - unauthorized selection blocked = PASS
- OWNER:
  - wildcard search = PASS
  - selection of BR-2 = PASS

### 14. E2E status

Functional backend E2E:
**PASS**

Frontend logic E2E simulation against Production branch identities:
**PASS**

Authenticated real-browser E2E:
**OPEN**

لم يتم الادعاء بإغلاق browser E2E لأن الجلسة الحالية لا توفر runtime متصفح authenticated يمكنه تسجيل الدخول إلى التطبيق المنشور واختبار DOM الحقيقي.

هذا لا يحول الاختبار البرمجي إلى browser PASS.

### 15. Competitive fit

الهدف المقارن ليس نسخ واجهات المنافسين، بل إغلاق capability gaps المهمة.

#### Odoo
Odoo يربط Inventory Adjustments وScrap بحركات مخزون موثقة، ويقدم أيضًا Barcode-assisted inventory adjustments. RAWAEA لديه Adjustment/Scrap engine ومسار ميداني للجرد؛ التحسين المتبقي هو توسيع audit UX والجرد المحمول تدريجيًا دون كسر العقد المركزي.
Official:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/inventory_management/scrap_inventory.html
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/inventory_management/count_products.html

#### Microsoft Dynamics 365
Dynamics يوضح From/To dimensions، posting ثم Inventory Transactions، ويعالج transfer كعملية موثقة قابلة للتتبع. RAWAEA يحقق المقابل عبر voucher lifecycle + movement ledger + source/target branch checks.
Official:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/tasks/transfer-physical-inventory-within-warehouse

#### SAP
SAP Goods Movement يغطي receipts/issues/transfers، ويُنشئ مستند حركة ويعطي إجراءات one-step/two-step مع إمكانية تتبع stock in transfer. RAWAEA يحتفظ حاليًا بمفهوم Draft/Sent/Received/Completed مع authoritative movement engine موحد.
Official:
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/742e46e570984d9aa74e468838f6e1ff.html
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/9e64bd534f22b44ce10000000a174cb4.html

#### Daftra
Daftra يوفر detailed inventory transactions مع warehouse/type/date/product filters، وطباعة وتصدير CSV/Excel/PDF. RAWAEA أصبح لديه تفاصيل حركة وstock-before/after في voucher context، والمتبقي المقارن هو توسيع reporting UX تدريجيًا.
Official:
https://docs.daftra.com/en/tutorial/inventory-detailed-transactions-report/
https://docs.daftra.com/en/tutorial/inventory-transactions-summary-report/

#### Manager.io
Manager يدعم Inventory Locations وInventory Transfers، ويعرض location selector/search ويغير المخزون تلقائيًا عند التحويل، مع تقارير location-aware. RAWAEA أقوى في workflow field execution، بينما المتبقي هو زيادة location/custody analytics وليس إعادة بناء engine.
Official:
https://www2.manager.io/guides/10677
https://www2.manager.io/guides/10707

### 16. ما لم نلمسه عمدًا

لم يتم:
- تعديل main.html.
- تعديل van-sales.html.
- فتح branch permissions للمستخدمين.
- إنشاء Edge Function جديدة.
- إنشاء stock engine جديد.
- حذف أي QA data.
- إعادة إصلاح register-sw.js.
- إعادة إصلاح export button.
- إعادة فتح closed Production voucher engine.

### 17. Final Closure Matrix

| العنصر | Current | Production | الإجراء | الحالة |
|---|---|---|---|---|
| Company branch directory query | all active company branches | 3 active branches | لا تغيير | PASS |
| Branch visibility UX | user-scoped فقط | RLS company-scoped read | فصل visibility عن authorization | PATCH READY |
| Arabic branch search | NFD + Latin-only mark removal | Production names include Arabic | Arabic combining marks fix | PATCH READY |
| Unauthorized branch execution | server guard موجود | REJECT proven | الحفاظ عليه | PASS |
| OWNER wildcard | `["*"]` | موجود | لم يمس | PASS |
| Persistent QA | IN-23 | retained | no delete | PASS |
| Physical stock engine | post_stock_movement | Production | لم يمس | PASS |
| main.html | untouched | blob unchanged | no change | PASS |
| van-sales.html | untouched | blob unchanged | no change | PASS |
| New Edge Function | none | limit respected | no new function | PASS |
| Browser E2E | not authenticated | not claimed | owner must execute after patch | OPEN |

### 18. تعليمات المساعد التالي

ابدأ دائمًا من:
1. System current HEAD after this session + parent.
2. Current frontend `vouchers.html` blob after owner application of PATCH-V308.
3. Production snapshot after owner application.
4. Do not repeat QA creation unless current reference is absent.
5. Verify `norm("إسكندرية") == norm("اسكندرية")`.
6. Verify `pickArr('wsFrom')` returns all active company branches for the display directory.
7. Verify unauthorized branch rows are disabled and `pickSelect()` rejects them.
8. Verify server RPC still rejects the same unauthorized branch.
9. Run real authenticated browser E2E.
10. Re-snapshot Production at the same report moment before any KPI/percentage claim.
11. Only then close Browser E2E.
12. Do not modify `main.html` or repeat any closed Production voucher migration.

### 19. FINAL ROOT CAUSE — في نهاية التقرير

الخطأ لم يكن سببًا واحدًا:

**السبب الأول — Branch Scope UI mismatch**
commit `fedd7138...` غيّر `pickArr()` ليعرض `userBranches` بدل `refs.branches`، فتم حذف BR-2 من دليل العرض للمستخدم الذي scope الخاص به `BR-01`.

**السبب الثاني — Arabic normalization bug**
`norm()` نفذ NFD لكنه لم يحذف Arabic combining marks، فنتج:
`إسكندرية → إسكندريه`
مقابل:
`اسكندرية → اسكندريه`
فشل `indexOf()` وأصبح البحث الذكي العربي غير موثوق.

**الإصلاح الصحيح**
إظهار دليل الفروع الكامل على مستوى الشركة مع بقاء branch authorization منفصلًا ومحكومًا في `pickSelect()` والـRPC، مع إصلاح Unicode normalization للعربية.

**Production integrity**
لم يتم فتح صلاحية غير مصرح بها، ولم يتم إنشاء Physical Stock engine جديد، ولم يتم إنشاء Edge Function جديدة.

# END REPORT308
