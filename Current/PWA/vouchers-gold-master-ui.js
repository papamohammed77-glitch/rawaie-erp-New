/* RAWAEA VOUCHERS — UI GOLD MASTER CAPABILITY PATCH 2026-08-20+
 * UI-only capability layer. No stock mutation and no inventory_log writes.
 * DirectSale contract: Representative -> Vehicle; vehicle.driver_id is authoritative.
 */
(function(){
  'use strict';
  if(location.pathname.indexOf('/vouchers.html')===-1)return;
  if(typeof App==='undefined'){console.error('[VOUCHERS] capability patch loaded before App');return;}

  function esc(v){return App.esc?App.esc(v):String(v==null?'':v).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/\"/g,'&quot;').replace(/'/g,'&#39;')}
  function label(x,type){if(!x)return '';if(type==='rep')return x.name||x.email||'';if(type==='supplier')return x.name||x.supplier_code||'';if(type==='vehicle')return x.vehicle_code||'';return x.name||x.branch_code||''}
  function code(x,type){if(!x)return '';if(type==='rep')return x.email||'';if(type==='supplier')return x.supplier_code||x.phone||'';if(type==='vehicle')return x.vehicle_code||'';return x.branch_code||''}
  function scoreRow(x,z,type){if(!z)return 1;var a=App.norm(label(x,type)),b=App.norm(code(x,type));return a===z||b===z?140:a.indexOf(z)===0?110:b.indexOf(z)===0?105:a.indexOf(z)>=0?70:b.indexOf(z)>=0?60:0}
  function hydrateRefs(s){
    if(!s || !s.company)return Promise.resolve();
    return Promise.all([
      supabase.from('users').select('id,name,email,role,status').eq('company_id',s.company).eq('status','Active').eq('role','مندوب بيع مباشر').order('name'),
      supabase.from('suppliers').select('id,supplier_code,name,phone').eq('company_id',s.company).eq('is_active',true).order('name')
    ]).then(function(r){
      if(r[0].error)throw r[0].error;
      if(r[1].error)throw r[1].error;
      s.refs=s.refs||{};
      s.refs.reps=r[0].data||[];
      s.refs.suppliers=r[1].data||s.refs.suppliers||[];
    });
  }

  var originalLoadRefs=App.loadRefs;
  App.loadRefs=function(){
    var s=this;
    return Promise.resolve(originalLoadRefs.call(this)).then(function(){return hydrateRefs(s)});
  };

  var originalPickArr=App.pickArr;
  App.pickArr=function(key){
    if(key==='wsRep')return this.refs&&this.refs.reps||[];
    if(key==='wsTo' && this.type==='DirectSale'){
      var repId=(document.getElementById('wsRep')||{}).value||'';
      return (this.refs&&this.refs.vehicles||[]).filter(function(v){return !!repId&&v.driver_id===repId&&v.status==='Active'});
    }
    return originalPickArr.call(this,key);
  };

  var originalPickSearch=App.pickSearch;
  App.pickSearch=function(key,q){
    var type=key==='wsRep'?'rep':key==='wsTo'&&this.type==='DirectSale'?'vehicle':key==='wsTo'&&this.type==='SupplierReturn'?'supplier':key==='wsFrom'&&this.type==='DirectReturn'?'vehicle':key==='wsFrom'?'branch':null;
    if(!type)return originalPickSearch.call(this,key,q);
    var s=this,arr=this.pickArr(key)||[],z=this.norm(q),box=RW_UI.byId(key+'Menu');
    if(!box)return;
    var scored=arr.map(function(x){return{x:x,score:scoreRow(x,z,type)}}).filter(function(o){return o.score>0}).sort(function(a,b){return b.score-a.score}).slice(0,12);
    box.innerHTML=scored.length?scored.map(function(o){var x=o.x;return '<div class="smart-row" onclick="App.pickSelect(\''+key+'\',\''+s.esc(x.id)+'\')"><div><b class="text-xs text-white">'+s.esc(label(x,type))+'</b><div class="smart-code">'+s.esc(code(x,type))+'</div></div><span class="text-[9px] text-emerald-400">اختيار</span></div>'}).join(''):'<div class="smart-empty">لا توجد نتائج</div>';
    box.classList.remove('hidden');
  };

  var originalPickSelect=App.pickSelect;
  App.pickSelect=function(key,id){
    if(key==='wsRep'){
      var reps=this.refs&&this.refs.reps||[],rep=reps.find(function(x){return x.id===id});
      if(!rep)return;
      RW_UI.byId('wsRep').value=id;
      RW_UI.byId('wsRepSearch').value=label(rep,'rep');
      RW_UI.byId('wsRepMenu').classList.add('hidden');
      var to=RW_UI.byId('wsTo'),toSearch=RW_UI.byId('wsToSearch'),toMenu=RW_UI.byId('wsToMenu');
      if(to)to.value='';if(toSearch)toSearch.value='';if(toMenu)toMenu.classList.add('hidden');
      this.updateSource();
      return;
    }
    if(key==='wsTo' && this.type==='DirectSale'){
      var repId=(RW_UI.byId('wsRep')||{}).value||'',vehicles=this.pickArr('wsTo'),vehicle=vehicles.find(function(x){return x.id===id});
      if(!repId){RW_UI.toast('اختر مندوب البيع المباشر أولاً','warning');return;}
      if(!vehicle){RW_UI.toast('المركبة لا تتبع المندوب المختار','error');return;}
      RW_UI.byId('wsTo').value=id;
      RW_UI.byId('wsToSearch').value=label(vehicle,'vehicle');
      RW_UI.byId('wsToMenu').classList.add('hidden');
      this.summary();
      return;
    }
    return originalPickSelect.call(this,key,id);
  };

  var originalRouteHtml=App.routeHtml;
  App.routeHtml=function(){
    var s=this,t=this.type;
    if(t!=='DirectSale')return originalRouteHtml.call(this);
    function picker(key,labelText,disabled){return '<div class="smart-field"><input type="hidden" id="'+key+'" value=""><input id="'+key+'Search" class="smart-input" autocomplete="off" placeholder="'+labelText+' — ابحث بالاسم أو الكود" '+(disabled?'disabled ':'')+'onfocus="App.pickShow(\''+key+'\')" oninput="App.pickSearch(\''+key+'\',this.value)"><div id="'+key+'Menu" class="smart-menu hidden"></div></div>'}
    return '<div class="grid grid-cols-1 sm:grid-cols-3 gap-2">'+picker('wsFrom','الفرع المصدر',false)+picker('wsRep','مندوب البيع المباشر',false)+picker('wsTo','المركبة — اختر المندوب أولاً',false)+'</div>';
  };

  var originalSummary=App.summary;
  App.summary=function(){
    if(this.type!=='DirectSale'){
      var r=originalSummary.call(this);
      if(this.type==='DirectReturn'){
        var to=RW_UI.byId('wsFrom'),v=to&&to.value?(this.refs.vehicles||[]).find(function(x){return x.id===to.value}):null,rep=v&&v.driver_id?(this.refs.reps||[]).find(function(x){return x.id===v.driver_id}):null;
        if(rep)RW_UI.safeText(RW_UI.byId('routeSummary'),(RW_UI.byId('routeSummary').textContent||'')+' · المندوب: '+label(rep,'rep'));
      }
      return r;
    }
    var fr=RW_UI.byId('wsFrom'),repEl=RW_UI.byId('wsRep'),to=RW_UI.byId('wsTo'),t='';
    if(fr&&fr.value)t+='المصدر: '+this.loc(fr.value,'Branch');
    if(repEl&&repEl.value){var rep=(this.refs.reps||[]).find(function(x){return x.id===repEl.value});if(rep)t+=(t?' · ':'')+'المندوب: '+label(rep,'rep')}
    if(to&&to.value)t+=(t?' · ':'')+'المركبة: '+this.loc(to.value,'Vehicle');
    RW_UI.safeText(RW_UI.byId('routeSummary'),t||'اختر المندوب ثم المركبة');
    RW_UI.safeText(RW_UI.byId('stockHint'),fr&&fr.value?'المتاح محسوب من المصدر المحدد':'اختر المصدر لمعرفة المتاح');
  };

  var originalSubmit=App.submit;
  App.submit=function(){
    if(this.type==='DirectSale'){
      var repId=(RW_UI.byId('wsRep')||{}).value||'',vehicleId=(RW_UI.byId('wsTo')||{}).value||'';
      if(!repId){RW_UI.toast('مندوب البيع المباشر مطلوب','warning');return;}
      if(!vehicleId){RW_UI.toast('المركبة مطلوبة بعد اختيار المندوب','warning');return;}
      var vehicle=(this.refs.vehicles||[]).find(function(x){return x.id===vehicleId});
      if(!vehicle||vehicle.driver_id!==repId){RW_UI.toast('المركبة المختارة غير مرتبطة بالمندوب المحدد','error');return;}
    }
    return originalSubmit.apply(this,arguments);
  };

  var originalRenderWorkspace=App.renderWorkspace;
  App.renderWorkspace=function(){
    originalRenderWorkspace.call(this);
    if(this.type==='DirectSale'){
      this.summary();
    }
  };

  Promise.resolve().then(function(){return hydrateRefs(App)}).catch(function(e){console.error('[VOUCHERS] reference hydration failed',e)});
  console.info('[VOUCHERS] direct-sale representative workflow + lookup hardening loaded');
})();