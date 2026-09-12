/* MAIN11 OWNER MICRO FIX — apply only after M11-01 replacement
 * File: Current/PWA/main2/main11.md
 * Purpose: avoid hard-coding Egypt UTC+03:00 in datetime-local conversion.
 */

const MAIN11_OWNER_MICRO_FIX_20260912 = {
  file: 'Current/PWA/main2/main11.md',
  element: "var toISO=function(id){var v=byId(id).value;return v?v+':00+03:00':null;};",
  delete_instruction: 'ابحث عن السطر الكامل الذي يبدأ بـ var toISO=function(id){ داخل دالة _addAttendance، واحذفه حتى علامة ; الأخيرة في نفس السطر.',
  replacement: "var toISO=function(id){var v=byId(id).value;return v?new Date(v).toISOString():null;};",
  reason: 'لا تُثبت واجهة datetime-local على منطقة زمنية بعينها؛ تُحوّل القيمة إلى ISO وفق وقت الجهاز ثم تُخزن كتاريخ/وقت صحيح في PostgreSQL.'
};
