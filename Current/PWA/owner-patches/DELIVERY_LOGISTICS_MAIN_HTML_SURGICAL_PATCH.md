# RAWAEA ERP — Delivery & Logistics Management
## Surgical Mother Main Patch — Runtime Closure 2026-09-20

> هذا الملف هو تعليمات تعديل النظام الأم فقط.
> لا يتم تعديل companies/company-1/main.html بواسطة هذا المسار.
> Production Supabase تم التحقق منه، ولا توجد حاجة لتغيير قاعدة البيانات أو إنشاء Edge Function لهذه المشكلة.

## 1) Current Mother forensic truth

Mother HEAD at re-check:
56a39bd8324f1c9a8c94bd686544b50fb76dfa56

Mother parent:
87426c6cb6269681ba074c609f0b253721668ccb

Current Mother main.html blob:
313f8dc17f9ece81d94cee19dd798bcc9915e1f4

The Delivery tab integration is already present in the current Mother source. Do not repeat the historical ADD-ONLY sections from Report267.

Confirmed existing elements:
- navigation entry: delivery-logistics-management
- icon: fa-route
- title: إدارة التوصيل والشحن
- access guard inside RW_Views.render(view)
- router hook inside RW_Views.render(view)
- complete RW_DeliveryLogistics module before the RW_Views marker

## 2) Exact defect

Inside the current Delivery module:

~~~js
var RW_DeliveryLogistics = (function() {
~~~

the module creates:

~~~js
var api={render:render,refresh:refresh,handle:handle,openRoute:openRoute};
window.RW_DeliveryLogistics=api;
~~~

but its IIFE terminates without:

~~~js
return api;
~~~

Therefore:
- window.RW_DeliveryLogistics is an object.
- lexical RW_DeliveryLogistics receives undefined.
- the router calls RW_DeliveryLogistics.render().
- browser raises TypeError: Cannot read properties of undefined (reading 'render').
- the Navigation catch then shows: حدث خطأ أثناء فتح التبويب.

## 3) Exact surgical replacement

In the Delivery IIFE only, find this exact final element:

~~~js
  // The field delivery apps remain authoritative for field execution; this module is supervisory/control-plane only.
  window.RW_DeliveryLogistics=api;
})();
~~~

Delete it completely.

Replace it with this complete corrected element:

~~~js
  // The field delivery apps remain authoritative for field execution; this module is supervisory/control-plane only.
  window.RW_DeliveryLogistics=api;
  return api;
})();
~~~

Do not change:
- RW_Views.render(view) router line
- Fleet module
- Runsheet engine
- field Delivery applications
- Inventory / Physical Stock engine
- any Delivery SQL/RPC
- any Edge Function

No other Mother edit is required for this defect.

## 4) Canonical source already corrected

Canonical file:
Current/PWA/owner-patches/RW_DeliveryLogistics.js

Corrected blob SHA:
cab4e9aae0cea0ead9d98210bbd15876df9e5a01

The canonical file now contains the same return api correction.

## 5) Production evidence

Current Production:
- company rows: 1
- delivery_agents: 0
- delivery_route_plans: 0
- delivery_route_stops: 0
- delivery_collection_receipts: 0
- Delivery operation registry rows: 0
- delivery_logistics_command_atomic: exactly 1 deployed signature
- delivery_logistics_query: exactly 1 deployed signature

Production Delivery core is therefore not the source of the reported browser exception.

## 6) Required owner browser gate

After applying only the exact replacement in section 3:
1. Load the current deployed Mother.
2. Hard reload the page.
3. Open مركز التوصيل واللوجستيات.
4. Verify that the JavaScript console no longer reports RW_Navigation.navigate ... undefined (reading 'render').
5. Verify the dashboard loads and the six Delivery tabs appear.
6. Record the deployed Mother HEAD/blob and browser result in the next forensic checkpoint.

Do not claim Browser Gate = PASS until the deployed Mother runtime itself is tested.