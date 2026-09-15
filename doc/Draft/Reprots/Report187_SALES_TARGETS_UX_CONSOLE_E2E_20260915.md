# Report187 — استكمال Sales Targets Engine: UX + Console + Current Source E2E

**التاريخ:** 2026-09-15
**النطاق:** Sales Targets Engine / Mother Main E2E / Console Refresh Error / Production performance

---

## 1. قاعدة الحوكمة المطبقة

التقارير السابقة استُخدمت كمرجع تاريخي فقط، ولم تُعامل كحالة حالية.

الحالة الحالية بُنيت من:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

ومصدر الحقيقة للنظام الأم بقي:

`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

الملفات التاريخية `Current/PWA/main2/*` و`Original/PWA/main/*` و`New-main` لم تُستخدم كمصدر Current.

المبدأ الحاكم: الدراسة أولًا، ثم تتبع السلوك الحالي، ثم إثبات الفجوة، ثم التعديل الجراحي.

---

## 2. Current Git — التحقق من HEAD وParent

Repository:
`papamohammed77-glitch/erp-frontend`

Branch:
`main`

Current HEAD:
`dddf1aaf5a6e2fe6be7b3d89451dede9c1387258`

Direct parent:
`f46dfc8183068d0dbf52c1b3b3c8cdbfc9f8f914`

Parent of parent:
`8b02f2158021b6ca4ce44ced756459b037fb1ebe`

Current mother blob:
`8bf3ac606cdc2d51c2d705ff5f921e46dbbe6607`

آخر Commit غيّر `main.html` في الجزء الخاص بـSales Targets، وأثبت التغييرات السابقة في:

- `postOperationIds` بدل الهوية العامة الواحدة.
- صلاحية زر `خطة جديدة / تفريغ النموذج`.
- صلاحيات `approvePlan()` و`cancelPlan()`.
- `إعادة ضبط` في محرر التخصيص.
- هوية عملية مستقلة لكل خطة داخل `postRun()`.

لا يوجد سبب لإعادة هذه الإصلاحات.

---

## 3. Current Mother — EOF وAnchors

تم التحقق مباشرة من النسخة الحالية للـblob `8bf3...` ومن مناطق Sales Targets ومناطق EOF.

### Current Sales Targets anchors

- السطر **1309**: بداية `RW_SalesTargetsMain`.
- السطر **1423**: بداية `async function renderDashboard(planId)`.
- السطر **1524**: نهاية `renderDashboard` الحالية.
- السطر **1900**: نهاية `RW_SalesTargetsMain` الحالية، وتأتي مباشرة بعد `    };` ثم `})();`.

### EOF

النسخة الحالية تنتهي عند السطر **40687**، وبترتيب نهائي مثبت:

```text
</script>
</body>
</html>
```

تم أيضًا التحقق من أن `forensic_main_assembly.yml` يشير بالفعل إلى:

`repository: papamohammed77-glitch/erp-frontend`
`path: companies/company-1/main.html`
`ref: main`
`mode: published_main_is_authoritative`

ولا يوجد أساس لتعديل المسار.

### حدود إثبات القراءة

تمت قراءة مناطق الملف المطلوبة جراحيًا كاملة حول Sales Targets وحتى EOF مع تحديد anchors الحالية. تعذر عرض الـblob الكامل سطرًا بسطر في رد واحد بسبب حد عرض الـblob الكبير في GitHub connector؛ لذلك لم يتم اختلاق claim بقراءة بصرية مستقلة لكل 40687 سطرًا.

---

## 4. Console Failure — السبب الحقيقي

المستخدم ظهر له:

```text
Uncaught ReferenceError: RW_SalesTargetsMain is not defined
    at HTMLButtonElement.onclick
```

في Current Source يوجد فعلًا:

```javascript
var RW_SalesTargetsMain = (function(){
```

في السطر **1309** تقريبًا، وجميع أزرار Sales Targets تستخدم الاسم نفسه داخل inline handlers.

لكن Current Source لا يحتوي على:

```javascript
window.RW_SalesTargetsMain = RW_SalesTargetsMain;
```

بعد إغلاق الوحدة في السطر **1900**.

### الاستنتاج

هذا لا يثبت أن منطق Sales Targets مفقود.

بل يثبت أن عقد exposure للواجهة غير مصرح به صراحة، وأن رسالة Console قد تكون أيضًا ناتجة عن نسخة served أقدم من HEAD.

لذلك الحل الآمن هو جعل exposure صريحًا في Current Source، مع الاحتفاظ بمنطق الوحدة كما هو.

---

## 5. Owner Surgery #1 — إصلاح `RW_SalesTargetsMain` global exposure

**الملف:**
`erp-frontend/companies/company-1/main.html`

**الموضع:** السطر **1900** الحالي.

### ابحث عن العنصر التالي حرفيًا:

```javascript
    };
})();
function _rwCompanyId() {
```

### احذف هذا الجزء فقط واستبدله بالكامل بـ:

```javascript
    };
})();
window.RW_SalesTargetsMain = RW_SalesTargetsMain;
function _rwCompanyId() {
```

**آخر سطر للعنصر المطلوب حذفه:**

```javascript
function _rwCompanyId() {
```

**النتيجة:**

- `RW_SalesTargetsMain` تصبح API عامة وصريحة للصفحة.
- جميع `onclick="RW_SalesTargetsMain...."` تبقى كما هي دون إعادة كتابة كل الأزرار.
- لا يتم تغيير أي Business Logic.
- لا يتم إنشاء نسخة ثانية من الوحدة.

بعد الدمج يجب أن يظهر في Console أثناء تحميل الصفحة:

```text
window.RW_SalesTargetsMain === RW_SalesTargetsMain
```

وتصبح القيمة `true` عند التحقق من DevTools.

---

## 6. Owner Surgery #2 — تحسين Sales Targets UX

Current Sales Targets يعمل وظيفيًا، لكنه كان يعرض KPIs أساسية فقط، ثم الجداول والترتيب والاتجاه بصورة أقرب إلى شاشة تشغيلية من مركز إدارة أهداف احترافي.

تم تصميم التحسين ليبقى داخل نفس الـRPC contract الحالي دون إضافة Backend contract جديد.

### الهدف الوظيفي للتصميم المحسن

- KPI واضح للهدف والمحقق والمتبقي.
- نسبة الإنجاز الرئيسية حسب Metric الخطة.
- مقارنة الإنجاز الفعلي بمعدل التقدم المتوقع زمنيًا.
- حالة أداء واضحة: ممتاز / على المسار / تحت الخطة.
- إبراز التخصيصات النشطة والموقوفة.
- Progress bars للمندوبين بدل أرقام منفصلة فقط.
- عرض أفضل النتائج أولًا.
- عرض الاتجاه اليومي بشكل أوضح.
- إبقاء إجراءات الاعتماد والعكس والترحيل مرتبطة بصلاحياتها الحالية.
- عدم تغيير Business Rules أو State transitions.

### العنصر المطلوب استبداله

**الملف:**
`companies/company-1/main.html`

**ابحث عن الدالة الكاملة:**

```javascript
async function renderDashboard(planId){
```

وهي تبدأ حاليًا عند السطر **1423** تقريبًا.

**احذف الدالة كاملة حتى آخر سطر لها قبل:**

```javascript
    function subscribeRealtime(){
```

**آخر سطر في الدالة القديمة المطلوب حذفه:**

```javascript
    }
```

الموجود مباشرة بعد:

```javascript
        }catch(e){
            RW_UI.safeHTML(box,'<div class=\"rw-error\">'+esc(e.message)+'</div>');
        }
    }
```

### البديل الكامل الجاهز

```javascript
    async function renderDashboard(planId){
        var box=byId('rw-sales-target-dashboard');
        if(!box || !planId) return;

        try{
            var j=await call('sales-target-dashboard',{plan_id:planId});
            var t=j.totals||{};
            var a=j.assignments||[];
            var r=j.ranking||[];
            var trend=j.trend||[];
            var runsResult=await op('LIST_RUNS',null,{},null);
            var runs=(runsResult.runs||[]).filter(function(x){return x.plan_id===planId;});
            var p=j.plan||{};
            var editable=canManage() && p.status==='Draft';
            var approvable=canApprove();
            var metric=p.metric||'amount';

            function pct(v){
                return Math.max(0,Math.min(100,Number(v)||0));
            }

            function metricLabel(){
                if(metric==='qty') return 'الكمية';
                if(metric==='gross_profit') return 'مجمل الربح';
                if(metric==='mixed') return 'المؤشر المختلط';
                return 'قيمة المبيعات';
            }

            function primaryPct(){
                if(metric==='qty') return Number(t.qty_pct)||0;
                if(metric==='gross_profit') return Number(t.gp_pct)||0;
                if(metric==='mixed') return ((Number(t.amount_pct)||0)+(Number(t.qty_pct)||0)+(Number(t.gp_pct)||0))/3;
                return Number(t.amount_pct)||0;
            }

            function primaryTarget(){
                if(metric==='qty') return Number(t.target_qty)||0;
                if(metric==='gross_profit') return Number(t.target_gp)||0;
                if(metric==='mixed') return null;
                return Number(t.target_amount)||0;
            }

            function primaryActual(){
                if(metric==='qty') return Number(t.actual_qty)||0;
                if(metric==='gross_profit') return Number(t.actual_gp)||0;
                if(metric==='mixed') return null;
                return Number(t.actual_amount)||0;
            }

            var primary=primaryPct();
            var cappedPrimary=pct(primary);
            var target=primaryTarget();
            var actual=primaryActual();
            var remaining=(target!=null)?Math.max(0,target-actual):0;

            var start=p.period_start?new Date(p.period_start+'T00:00:00'):null;
            var end=p.period_end?new Date(p.period_end+'T23:59:59'):null;
            var now=new Date();
            var expectedPace=0;
            var periodDays=0;
            var elapsedDays=0;
            if(start&&end&&!isNaN(start.getTime())&&!isNaN(end.getTime())){
                periodDays=Math.max(1,Math.ceil((end-start)/86400000));
                var clippedNow=new Date(Math.min(Math.max(now.getTime(),start.getTime()),end.getTime()));
                elapsedDays=Math.max(1,Math.ceil((clippedNow-start)/86400000));
                expectedPace=Math.min(100,(elapsedDays/periodDays)*100);
            }
            var paceDelta=primary-expectedPace;
            var healthLabel=paceDelta>=10?'ممتاز':(paceDelta>=-5?'على المسار':'تحت الخطة');
            var healthClass=paceDelta>=10?'rw-status-success':(paceDelta>=-5?'rw-status-info':'rw-status-danger');

            var h='<div style="display:grid;gap:22px">';

            h+='<div class="rw-card" style="background:linear-gradient(135deg,#0f172a,#1d4ed8);color:#fff;border:none;overflow:hidden;position:relative">';
            h+='<div style="position:relative;z-index:2;display:flex;justify-content:space-between;align-items:flex-start;gap:18px;flex-wrap:wrap">';
            h+='<div><div style="font-size:13px;opacity:.78;font-weight:800">مركز قرار أهداف المبيعات</div>';
            h+='<div style="font-size:26px;font-weight:900;margin-top:6px">'+esc(p.name||p.plan_code||'خطة المبيعات')+'</div>';
            h+='<div style="font-size:13px;opacity:.82;margin-top:6px">'+esc(p.period_start||'')+' → '+esc(p.period_end||'')+' • المؤشر: '+esc(metricLabel())+'</div></div>';
            h+='<div style="display:flex;align-items:center;gap:10px;flex-wrap:wrap">';
            h+='<span style="padding:8px 14px;border-radius:999px;background:rgba(255,255,255,.14);font-weight:900">'+esc(statusLabel(p.status))+'</span>';
            h+='<span style="padding:8px 14px;border-radius:999px;background:rgba(255,255,255,.14);font-weight:900">'+esc(healthLabel)+'</span>';
            h+='</div></div>';
            h+='<div style="position:absolute;inset:auto -40px -80px auto;width:220px;height:220px;border-radius:50%;background:rgba(255,255,255,.08)"></div>';
            h+='</div>';

            h+='<div class="rw-kpi-grid">';
            h+='<div class="rw-kpi-card"><div class="rw-kpi-card-top"><span>'+esc(metricLabel())+'</span></div><div class="rw-kpi-value">'+(metric==='qty'?num(t.target_qty):metric==='gross_profit'?num(t.target_gp)+' ج.م':metric==='mixed'?'متعدد المؤشرات':num(t.target_amount)+' ج.م')+'</div><div style="font-size:12px;color:#64748b;margin-top:6px">الهدف المعتمد</div></div>';
            h+='<div class="rw-kpi-card"><div class="rw-kpi-card-top"><span>المحقق</span></div><div class="rw-kpi-value">'+(metric==='qty'?num(t.actual_qty):metric==='gross_profit'?num(t.actual_gp)+' ج.م':metric==='mixed'?'—':num(t.actual_amount)+' ج.م')+'</div><div style="font-size:12px;color:#64748b;margin-top:6px">من المبيعات المرحّلة</div></div>';
            h+='<div class="rw-kpi-card"><div class="rw-kpi-card-top"><span>الإنجاز</span></div><div class="rw-kpi-value">'+num(primary)+'%</div><div style="margin-top:10px;height:8px;background:#eef2f7;border-radius:999px;overflow:hidden"><div style="height:100%;width:'+cappedPrimary+'%;background:#2563eb;border-radius:999px"></div></div></div>';
            h+='<div class="rw-kpi-card"><div class="rw-kpi-card-top"><span>المتبقي</span></div><div class="rw-kpi-value">'+(metric==='mixed'?'—':metric==='qty'?num(remaining):num(remaining)+' ج.م')+'</div><div style="font-size:12px;color:#64748b;margin-top:6px">للوصول إلى الهدف</div></div>';
            h+='</div>';

            h+='<div class="rw-card">';
            h+='<div style="display:flex;justify-content:space-between;align-items:center;gap:12px;flex-wrap:wrap">';
            h+='<div><h3 style="margin:0">مؤشر التقدم التنفيذي</h3><div style="font-size:12px;color:#64748b;margin-top:4px">مقارنة الإنجاز الحالي بالمسار الزمني للخطة.</div></div>';
            h+='<span class="'+healthClass+'" style="padding:8px 12px;border-radius:999px;font-weight:900">'+esc(healthLabel)+'</span></div>';
            h+='<div style="display:grid;grid-template-columns:1fr auto;gap:14px;align-items:center;margin-top:18px">';
            h+='<div><div style="height:16px;background:#eef2f7;border-radius:999px;overflow:hidden;position:relative"><div style="height:100%;width:'+cappedPrimary+'%;background:linear-gradient(90deg,#2563eb,#06b6d4);border-radius:999px"></div><div style="position:absolute;top:-3px;bottom:-3px;left:'+pct(expectedPace)+'%;width:2px;background:#111827"></div></div>';
            h+='<div style="display:flex;justify-content:space-between;font-size:12px;color:#64748b;margin-top:7px"><span>الإنجاز '+num(primary)+'%</span><span>المسار المتوقع '+num(expectedPace)+'%</span></div></div>';
            h+='<div style="text-align:center;min-width:90px"><div style="font-size:18px;font-weight:900">'+(paceDelta>=0?'+':'')+num(paceDelta)+'%</div><div style="font-size:11px;color:#64748b">فارق الإيقاع</div></div>';
            h+='</div>';
            h+='</div>';

            h+='<div class="rw-card"><div style="display:flex;justify-content:space-between;align-items:center;gap:12px;flex-wrap:wrap"><div><h3>تخصيصات الأهداف</h3><div style="font-size:12px;color:#64748b;margin-top:4px">'+a.length+' تخصيصًا • العناصر النشطة فقط تؤثر على لوحة الأداء.</div></div>';
            if(editable) h+='<button class="rw-btn rw-btn-success" onclick="RW_SalesTargetsMain.openAssignmentEditor(null)">+ إضافة تخصيص</button>';
            h+='</div>';
            if(!a.length){
                h+='<div style="padding:30px;text-align:center;color:#64748b;border:1px dashed #cbd5e1;border-radius:18px;margin-top:16px">لا توجد تخصيصات لهذه الخطة. أضف مندوبًا أو فرعًا أو هدفًا عامًا قبل اعتماد الخطة.</div>';
            }else{
                h+='<div style="overflow:auto;margin-top:12px"><table class="rw-table"><thead><tr><th>المندوب</th><th>الفرع</th><th>هدف القيمة</th><th>هدف الكمية</th><th>هدف الربح</th><th>الوزن</th><th>المحقق</th><th>الإنجاز</th><th>الحالة</th><th>الإجراء</th></tr></thead><tbody>';
                for(var i=0;i<a.length;i++){
                    var z=a[i];
                    var zp=pct(z.achievement_pct);
                    h+='<tr>';
                    h+='<td><b>'+esc(z.sales_rep_name||'هدف عام')+'</b></td>';
                    h+='<td>'+esc(z.branch_name||'كل الفروع')+'</td>';
                    h+='<td>'+num(z.target_amount)+'</td>';
                    h+='<td>'+num(z.target_qty)+'</td>';
                    h+='<td>'+num(z.target_gross_profit)+'</td>';
                    h+='<td>'+num(z.weight)+'%</td>';
                    h+='<td>'+num(z.actual_amount)+'</td>';
                    h+='<td><div style="min-width:150px"><div style="font-weight:900;margin-bottom:5px">'+num(z.achievement_pct)+'%</div><div style="height:7px;background:#eef2f7;border-radius:999px;overflow:hidden"><div style="height:100%;width:'+zp+'%;background:#2563eb;border-radius:999px"></div></div></div></td>';
                    h+='<td>'+(z.active?'<span class="rw-status-success" style="padding:6px 9px;border-radius:999px;font-weight:800">نشط</span>':'<span style="padding:6px 9px;border-radius:999px;background:#f1f5f9;color:#64748b;font-weight:800">موقوف</span>')+'</td>';
                    h+='<td>';
                    if(editable){
                        h+='<button class="rw-btn" onclick="RW_SalesTargetsMain.openAssignmentEditor('+JSON.stringify(z.id)+')">تعديل</button> ';
                        h+='<button class="rw-btn" onclick="RW_SalesTargetsMain.setAssignmentActive('+JSON.stringify(z.id)+','+(z.active?'false':'true')+')">'+(z.active?'إيقاف':'تفعيل')+'</button>';
                    }else{
                        h+='<span style="color:#9ca3af;font-size:12px">قراءة فقط</span>';
                    }
                    h+='</td></tr>';
                }
                h+='</tbody></table></div>';
            }
            h+='</div>';

            h+='<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(320px,1fr));gap:22px">';
            h+='<div class="rw-card"><h3>أفضل المندوبين</h3>';
            if(!r.length){
                h+='<div style="padding:18px;color:#64748b">لا توجد نتائج بعد.</div>';
            }else{
                var topCount=Math.min(5,r.length);
                for(var k=0;k<topCount;k++){
                    var rr=r[k];
                    var rp=pct(rr.achievement_pct);
                    h+='<div style="padding:13px 0;border-bottom:1px solid #eef2f7"><div style="display:flex;justify-content:space-between;gap:10px"><b>'+esc(rr.rep_name||'غير محدد')+'</b><span style="font-weight:900">'+num(rr.actual_amount)+' ج.م</span></div><div style="display:flex;align-items:center;gap:8px;margin-top:7px"><div style="flex:1;height:7px;background:#eef2f7;border-radius:999px;overflow:hidden"><div style="height:100%;width:'+rp+'%;background:#10b981;border-radius:999px"></div></div><span style="font-size:12px;font-weight:900;min-width:52px;text-align:left">'+num(rr.achievement_pct)+'%</span></div></div>';
                }
            }
            h+='</div>';

            h+='<div class="rw-card"><h3>الاتجاه اليومي</h3>';
            if(!trend.length){
                h+='<div style="padding:18px;color:#64748b">لا توجد حركة مبيعات داخل فترة الخطة.</div>';
            }else{
                var maxTrend=0;
                for(var q=0;q<trend.length;q++) maxTrend=Math.max(maxTrend,Number(trend[q].actual_amount)||0);
                for(var q2=0;q2<trend.length;q2++){
                    var tv=Number(trend[q2].actual_amount)||0;
                    var tw=maxTrend>0?Math.max(3,(tv/maxTrend)*100):3;
                    h+='<div style="display:grid;grid-template-columns:86px 1fr 110px;gap:10px;align-items:center;margin:9px 0"><span style="font-size:12px;color:#64748b">'+esc(trend[q2].metric_day||'')+'</span><div style="height:9px;background:#eef2f7;border-radius:999px;overflow:hidden"><div style="height:100%;width:'+tw+'%;background:linear-gradient(90deg,#2563eb,#06b6d4);border-radius:999px"></div></div><b style="text-align:left;font-size:12px">'+num(tv)+' ج.م</b></div>';
                }
            }
            h+='</div>';
            h+='</div>';

            h+='<div class="rw-card"><div style="display:flex;justify-content:space-between;align-items:center;gap:12px"><div><h3>سجل الترحيل</h3><div style="font-size:12px;color:#64748b;margin-top:4px">الحالة المالية/التشغيلية لآخر عمليات الخطة.</div></div></div>';
            if(!runs.length){
                h+='<div style="padding:18px;color:#64748b">لا توجد عمليات ترحيل حتى الآن.</div>';
            }else{
                h+='<div style="overflow:auto"><table class="rw-table"><thead><tr><th>التاريخ</th><th>الحالة</th><th>القيمة</th><th>الكمية</th><th>الإجراء</th></tr></thead><tbody>';
                for(var n=0;n<runs.length;n++){
                    var run=runs[n];
                    h+='<tr><td>'+esc(run.evaluated_at||run.created_at||'')+'</td><td>'+esc(statusLabel(run.status))+'</td><td>'+num(run.total_actual_amount)+'</td><td>'+num(run.total_actual_qty)+'</td><td>';
                    if(approvable && run.status==='Posted') h+='<button class="rw-btn" onclick="RW_SalesTargetsMain.approveRun('+JSON.stringify(run.id)+')">اعتماد</button> ';
                    if(approvable && (run.status==='Posted'||run.status==='Approved')) h+='<button class="rw-btn rw-btn-danger" onclick="RW_SalesTargetsMain.reverseRun('+JSON.stringify(run.id)+')">عكس</button>';
                    if(!approvable || run.status==='Preview' || run.status==='Reversed') h+='<span style="color:#9ca3af;font-size:12px">—</span>';
                    h+='</td></tr>';
                }
                h+='</tbody></table></div>';
            }
            h+='</div></div>';

            RW_UI.safeHTML(box,h);
        }catch(e){
            RW_UI.safeHTML(box,'<div class="rw-error">'+esc(e.message)+'</div>');
        }
    }
```

### Important
هذا الاستبدال لا يغير:

- `sales-target-dashboard` RPC.
- `sales_target_dashboard_atomic`.
- `sales_target_engine_gateway`.
- State transitions.
- صلاحيات الإدارة/الاعتماد.
- Real-time subscriptions.

وهو Frontend presentation upgrade فقط.

---

## 7. Console warnings الأخرى

### Tailwind warning

الرسالة:

```text
cdn.tailwindcss.com should not be used in production
```

هي **warning** من Tailwind CDN وليست سبب `RW_SalesTargetsMain is not defined`.

Current Source ما زال يحتوي على:

```html
<script src="https://cdn.tailwindcss.com"></script>
```

عند السطر المبكر من الملف.

لم تتم إزالته في هذه المهمة لأن إزالة CDN بدون بديل compiled CSS قد تكسر مئات Tailwind utility classes الموجودة في الملف.

قرار الحوكمة: لا نعالج warning بعملية حذف عمياء تؤثر على الواجهة.

هذه تظل مهمة Build/CSS مستقلة.

### favicon 404

الرسالة:

```text
/favicon.ico 404
```

ليست سبب فشل زر Sales Targets.

يمكن إغلاقها لاحقًا بإضافة favicon رسمي، لكن لم تُخلط في نفس Surgery حتى لا تتحول مهمة Console إلى تغيير بصري غير ضروري.

---

## 8. Production — الحالة الحالية

Supabase:
`fiilmooggumokxanwiyx`

### Current Sales Targets tables

`plans = 0`
`assignments = 0`
`runs = 0`
`run_lines = 0`

### Current RPCs

- `sales_target_engine_gateway`
- `sales_target_engine_atomic`
- `sales_target_dashboard_atomic`

كلها موجودة حاليًا في Production.

### Current security behavior

Production تستخدم company-scoped actor validation داخل Gateway/Engine/Dashboard.

### Audit / Integrity

Production تحتوي على:

- assignment integrity triggers.
- run-line integrity trigger.
- audit triggers على plans / assignments / runs / run_lines.
- run totals snapshot trigger.

---

## 9. Production optimization executed

تم إنشاء فهارس أداء آمنة دون تغيير Business Logic:

```sql
CREATE INDEX idx_orders_company_date_sales_targets
  ON public.orders (company_id, order_date);

CREATE INDEX idx_order_details_order_item_sales_targets
  ON public.order_details (order_id, item_id);
```

تم التحقق من وجود الفهرسين في Production بعد التطبيق.

الهدف:

- تسريع قراءة مبيعات الفترة في Dashboard.
- تسريع JOIN بين `orders` و`order_details`.
- منع نمو حجم البيانات من تحويل Dashboard إلى نقطة اختناق.

---

## 10. لماذا لم أعدل Production Sales Targets RPC نفسها؟

تمت مقارنة الـRPCs الحالية مع Current Mother contract.

المحرك يدعم بالفعل:

`LIST_PLANS`
`LIST_ASSIGNMENTS`
`LIST_RUNS`
`SAVE_PLAN`
`SAVE_ASSIGNMENT`
`CLONE_PLAN`
`SET_ASSIGNMENT_ACTIVE`
`APPROVE_PLAN`
`CLOSE_PLAN`
`CANCEL_PLAN`
`PREVIEW`
`POST`
`APPROVE_RUN`
`REVERSE_RUN`

ولا توجد فجوة Production مثبتة في هذه الوظائف تتطلب Rewrite جديدًا.

إضافة Backend سلوك جديد فقط لأجل UX ستكون تغييرًا غير مبرر.

---

## 11. E2E / Runtime status

### ما تم إثباته حاليًا

- Current HEAD صحيح ومطابق للـsource الحالي.
- Parent وParent-of-parent تمت مراجعتهما.
- Current mother blob هو `8bf3...`.
- `RW_SalesTargetsMain` موجود فعليًا في Current Source.
- `renderDashboard` موجود عند الـanchor الحالي.
- الـmodule يغلق عند السطر 1900.
- EOF هو السطر 40687 وبترتيب صحيح.
- `forensic_main_assembly.yml` يشير إلى Published Mother الصحيح.
- Sales Targets RPCs موجودة في Production.
- Production business tables الحالية فارغة بعد الاختبارات السابقة.
- فهارس الأداء الجديدة موجودة في Production.

### ما لم يُثبت حتى الآن

- Browser execution حقيقي من متصفح خفي جديد بعد آخر HEAD.
- Console/Network snapshot من served asset الحالي بعد HEAD `dddf...`.
- أن النسخة التي أطلقت رسالة `RW_SalesTargetsMain is not defined` هي نفسها blob `8bf3...` الحالي.

### السبب

بيئة التنفيذ المتاحة هنا لا توفر browser-incognito session مستقلة مع DevTools/Network capture، كما لا توجد deployment snapshot مستقلة يمكن من خلالها مقارنة served HTML لحظيًا مع blob الحالي.

لذلك لم أُحوّل Console evidence القديمة إلى Production proof جديد.

---

## 12. Required Owner execution order

1. نفّذ **Owner Surgery #1** أولًا: exposure الصريح عند السطر **1900**.
2. نفّذ **Owner Surgery #2** باستبدال `renderDashboard` الحالية عند السطر **1423** حتى قبل `subscribeRealtime()`.
3. ارفع الملف النهائي نفسه إلى:
   `erp-frontend/companies/company-1/main.html`
4. تأكد أن commit يحتوي نفس الملف وأن الـSource of Truth لم يتغير.
5. افتح الصفحة من أحدث deployment.
6. اضغط `تحديث` داخل Sales Targets.
7. يجب ألا يظهر:
   `RW_SalesTargetsMain is not defined`
8. يجب أن يصبح Console بعد الضغط خاليًا من هذا الخطأ تحديدًا.

---

## 13. Final Self-Audit

### What I Proved

- Current Git identity.
- HEAD/Parent/Parent-of-parent.
- Current Mother blob.
- Sales Targets current source structure.
- Exact module anchors.
- Exact EOF.
- Current Production Sales Targets database/RPC structure.
- Production table counts.
- Production performance indexes.
- `forensic_main_assembly.yml` correctness.
- Root diagnostic: current source has module declaration but no explicit window export.

### What I Fixed

**Production:**
- Added `idx_orders_company_date_sales_targets`.
- Added `idx_order_details_order_item_sales_targets`.

**Source instructions prepared for Owner:**
- Explicit `window.RW_SalesTargetsMain` export.
- Full `renderDashboard` UX replacement.

### What I Did Not Fix Directly

- `main.html` نفسه لم يتم تغييره مباشرة احترامًا لملكية النظام الأم.
- Tailwind CDN warning لم يُحذف عشوائيًا.
- Favicon 404 لم يُخلط مع Sales Targets surgery.

### What Could Still Be Wrong

الاحتمال الأهم المتبقي هو أن الـserved asset الذي أصدر الخطأ كان أقدم من Current HEAD، أو لم يكن هو نفس artifact المنشور.

لذلك Browser/Network verification بعد الدمج هي نقطة الإغلاق النهائية.

### Final closure

`Sales Targets Production Engine = VERIFIED`
`Current Git/source = VERIFIED`
`Sales Targets UX enhancement = OWNER SURGERY READY`
`Console root fix = OWNER SURGERY READY`
`Production performance optimization = DEPLOYED + VERIFIED`
`Browser/served-source E2E = OPEN`
`Full Mother UI closure = OPEN until fresh served/browser proof`

---

## 14. Next Session State Contract

لا تُعد فتح إصلاحات Sales Targets السابقة.

ابدأ من:

`HEAD = dddf1aaf5a6e2fe6be7b3d89451dede9c1387258`

و:

`MOTHER = companies/company-1/main.html`

ثم:

`OWNER SURGERY → DEPLOY → BROWSER E2E → CONSOLE/NETWORK PROOF → CLOSE`
