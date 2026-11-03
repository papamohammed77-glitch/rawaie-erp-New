# RAWAEA ERP — مراجعة المتجر الإلكتروني والطلب العام والتسعير

**Checkpoint:** LVE-2026-11-03-596  
**التاريخ:** 2026-11-03  
**الحالة:** PUBLIC CHECKOUT CONTRACT REVIEW / CUSTOMER IDENTITY RISK / PRICING CONTROL CONFIRMED  
**نقطة البداية:** LVE-595.

---

## 1. نطاق الفحص

تم تتبع:
- companies/company-1/store/index.html.
- submit-online-order Edge Function v11.
- submit_online_order_atomic.
- resolve_sales_pricing_atomic.
- آلية operation_id في واجهة المتجر.
- علاقة المتجر المنشور بـapp_settings.storefront_key وstorefront_enabled.

لم يتم إنشاء طلب فعلي أو تعديل بيانات عميل.

---

## 2. ضوابط جيدة — CONFIRMED

### 2.1 تقييد المتجر المنشور

- submit-online-order v11 يعمل verify_jwt=false لدعم Guest Checkout، لكن لا يقبل أي شركة عشوائية.
- عند عدم وجود JWT مستخدم، يبحث عن app_settings.storefront_enabled=true.
- إذا لم يوجد متجر منشور يرفض الطلب.
- إذا وجد أكثر من متجر منشور يشترط storefront_key.
- المفتاح يحدد company_id المنشورة.
- إذا أرسل مستخدم JWT حقيقي، يربط الشركة بملف المستخدم ويتحقق أن storefront_key يخص الشركة نفسها.

إذًا verify_jwt=false هنا تصميم مقصود للمتجر العام، وليس وحده دليل ثغرة.

### 2.2 منع التلاعب بالسعر — CONFIRMED

- واجهة المتجر ترسل price ضمن cartItems، لكن submit_online_order_atomic لا يعتمد هذا السعر النهائي.
- يستدعي resolve_sales_pricing_atomic باستخدام company/customer/branch/channel/item_code/qty.
- resolve_sales_pricing_atomic يقرأ items.sales_price ويطبق commercial pricing rules وpromotion resolver.
- submit_online_order_atomic يبني v_effective_items من نتيجة pricing engine ويستخدم unit_price المعاد من الخادم.
- السعر النهائي والخصومات والضريبة ورسوم التوصيل يعاد حسابها داخل PostgreSQL.

**الحكم:** تعديل price في طلب HTTP لا يكفي لفرض سعر العميل؛ الخادم يعيد التسعير من بيانات الشركة. لم يُنفذ اختبار تلاعب HTTP، لكن عقد المصدر يثبت إعادة التسعير.

### 2.3 Idempotency في واجهة المتجر — CONFIRMED

- store/index.html يحسب fingerprint للطلب.
- يخزن operation_id في localStorage مع fingerprint قبل إرسال الطلب.
- يعيد استخدام نفس operation_id عند إعادة محاولة نفس payload.
- ينشئ مفتاحًا جديدًا عندما يتغير fingerprint.
- يرسل operation_id في body وIdempotency-Key header.
- بعد النجاح يمسح المفتاح المعلق.

هذا نمط جيد يجب الحفاظ عليه.

### 2.4 ضوابط السلة والطلب

submit_online_order_atomic:
- يشترط customer name/phone/area.
- يشترط سلة غير فارغة.
- يمنع أكثر من 100 سطر.
- يرفض item غير موجود أو غير فعال أو غير معروض في المتجر.
- يمنع تكرار item code داخل السلة.
- يتحقق من qty أكبر من صفر.
- يطبق max_qty_per_order.
- يطبق store_display_qty quota.
- ينشئ الطلب Pending وبمصدر online_store.
- لا يخصم المخزون عند إنشاء الطلب؛ وهذا متسق مع كون الطلب Pending ويحتاج تأكيدًا وتشغيلًا لاحقًا.

---

## 3. مخاطر هوية العميل — CONFIRMED SOURCE CONTRACT

### 3.1 تحديث عميل موجود برقم هاتف فقط

في submit_online_order_atomic:
- يبحث عن customer داخل الشركة باستخدام phone.
- إذا وجد سجلًا، يستخدم customer_id الحالي.
- ثم يحدث customers.name وcustomers.area مباشرة من بيانات Guest Checkout.
- لا يظهر تحقق OTP أو إثبات ملكية رقم الهاتف قبل تعديل بيانات العميل.

### 3.2 أثر ذلك على التسعير التجاري

بعد تحديد customer_id، يمرره إلى resolve_sales_pricing_atomic.
وهذه الدالة قد تطبق commercial_customer_links وقواعد تسعير مرتبطة بالعميل.

لذلك يستطيع زائر غير مصادق، إذا أدخل رقم هاتف عميل موجود:
- إنشاء طلب باستخدام هوية customer_id لذلك السجل.
- تعديل الاسم والمنطقة المسجلين.
- الاستفادة من pricing rules المرتبطة بذلك العميل إذا كانت القواعد تعتمد customer_id.

هذا لا يثبت أن الطلب سيُقبل دائمًا أو أن العميل سيحصل على خصم معين؛ لكنه يثبت أن رقم الهاتف وحده هو مفتاح ربط العميل وأنه لا توجد مصادقة ملكية هاتف في المسار الحالي.

**التصنيف:** Customer identity/master-data integrity risk CONFIRMED at source contract. Actual misuse/financial loss UNVERIFIED.

### 3.3 التوصية المعمارية

لا تحدّث بيانات العميل الرئيسي من Guest Checkout غير الموثق:
- إما إنشاء/استخدام سجل Online Guest منفصل.
- أو إنشاء طلب Pending دون تعديل customer master.
- أو اشتراط OTP/تحقق هاتف قبل ربط الطلب بعميل تجاري موجود وتطبيق أسعار تعاقدية خاصة.
- لا تغيّر ذلك قبل قرار المالك؛ قد تكون هناك سياسة تجارية مقصودة لربط الهاتف.

---

## 4. المخزون والتوافر — UNKNOWN / POLICY DECISION

- الدالة تفحص store_display_qty وmax_qty_per_order.
- لا يظهر في المسار فحص مباشر لـstock_branches.available_qty أو حجز allocated_qty.
- الطلب يُنشأ Pending دون خصم مخزون.

هذا قد يكون مقصودًا لأن الطلب العام لا يحجز المخزون حتى تأكيده/إضافته إلى Runsheet، لكنه قد يسمح بطلب كمية أكبر من المتاح فعليًا إذا كانت store_display_qty أعلى من المخزون الحقيقي.

لا يمكن تصنيفه كعيب قبل حسم سياسة المالك:
- هل المتجر يعرض طلبًا أوليًا Pending يسمح بالتأكيد اليدوي لاحقًا؟
- أم يجب منع قبول طلب يفوق available stock عند الإرسال؟

لا توجد عملية بيع/حجز فعلية تم اختبارها.

---

## 5. Idempotency contract

- Edge يولد crypto.randomUUID() إذا لم يرسل العميل operation_id أو Idempotency-Key.
- هذا fallback لا يضمن ثبات المفتاح عند retry؛ كل request جديد قد يحصل على مفتاح جديد.
- واجهة store الحالية ترسل مفتاحًا ثابتًا وتحتفظ به في localStorage، لذلك الاستخدام الحالي الذي فُحص جيد.
- RPC يعيد الطلب السابق إذا وجد نفس operation_id، لكنه لا يقارن payload hash للطلب السابق بالـpayload الجديد.
- العميل الحالي يحمي ذلك عبر fingerprint، لكن عميلًا آخر قد يعيد استخدام المفتاح نفسه مع payload مختلف ويحصل على نتيجة الطلب القديم بدل conflict واضح.

التوصية: حفظ payload_hash على سجل العملية أو استخدام operation registry موحد يرفض إعادة استخدام المفتاح مع payload مختلف.

---

## 6. مصفوفة الأدلة

| الطبقة | النتيجة |
|---|---|
| Store source | operation_id ثابت عبر fingerprint، وإرسال store key واضح — CONFIRMED |
| Edge v11 | Guest checkout محصور في published storefront key — CONFIRMED |
| Pricing RPC | السعر يعاد حسابه من item master والقواعد التجارية — CONFIRMED |
| Customer master | تحديث name/area من phone دون OTP — CONFIRMED |
| Stock reservation | لا خصم/حجز مباشر في submit path — CONFIRMED |
| Intended availability policy | UNKNOWN |
| Runtime/Browser E2E | UNVERIFIED |
| Actual customer misuse | UNVERIFIED |

---

## 7. ما تم وما لم يتم

**تم:**
- قراءة store/index.html كاملًا (651 سطرًا).
- قراءة submit-online-order v11.
- قراءة submit_online_order_atomic (177 سطرًا).
- قراءة resolve_sales_pricing_atomic (184 سطرًا).
- تتبع operation_id من الواجهة حتى RPC.
- مطابقة guest checkout مع app_settings storefront key.

**لم يتم:**
- لم يُنشأ طلب.
- لم يُعدّل customer master.
- لم يُختبر تلاعب بالسعر عبر HTTP.
- لم يُختبر OTP لأن المسار الحالي لا يطلبه.
- لم يُجر Browser E2E أو فحص artifact منشور.

---

## 8. الأولوية التالية

قرار المالك المطلوب قبل أي تعديل:
1. هل Guest Checkout يسمح بإنشاء طلب باستخدام رقم هاتف عميل موجود دون OTP؟
2. هل يسمح بتعديل customer master من Guest Checkout؟
3. هل الأسعار التجارية الخاصة تُطبق على Guest Checkout أم على العميل المصادق فقط؟
4. هل قبول الطلب Pending يتطلب فحص available stock أم يكفي store_display_qty؟

بعد القرار، صمم أصغر تغيير يحفظ تجربة المتجر ولا يغير دورة Pending → Confirmed → Runsheet → Loading دون حاجة.

**الحالة:** PRICING CONTROL CONFIRMED / CUSTOMER IDENTITY RISK CONFIRMED / STOCK POLICY UNKNOWN / RUNTIME UNVERIFIED / NOT CLOSED.
