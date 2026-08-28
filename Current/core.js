/* RAWAEA ERP canonical compatibility entry for PWA pages that resolve ../core.js.
 * The source of truth remains Current/PWA/core.js; this file intentionally loads it
 * rather than duplicating the shared Core and creating a second source of truth.
 */
(function(){
  if (window.RW_Auth && window.RW_UI) return;
  var s=document.createElement('script');
  s.src='../PWA/core.js';
  s.async=false;
  s.onerror=function(){console.error('[RAWAEA] Failed to load canonical PWA core');};
  document.head.appendChild(s);
})();
