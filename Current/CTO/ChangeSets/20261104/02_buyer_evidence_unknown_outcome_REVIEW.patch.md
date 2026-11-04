# Buyer evidence-upload recovery patch
**Base file:** `companies/company-1/purchasing/buyer.html`
**Base blob:** `d9ffb1084a538b7f7baf48391d3048ac5e96bffa`
**Exact replacement:** In `registerQuickMarketHandover` catch block (around lines 1057–1065), replace:

```javascript
                }catch(e){
                    var committed=false;
                    try{var verify=await self.api('GET_QUICK_MARKET_HANDOVER_PROGRESS',{invoice_id:invoiceId});committed=(verify.events||[]).some(function(x){return x.operation_id===operationId;});}catch(checkError){}
                    if(!committed)await supabase.storage.from('employee-documents').remove([evidencePath]);
                    if(committed)return {success:true,duplicate:true};
                    Swal.showValidationMessage(e.message);return false;
                }
```

with:

```javascript
                }catch(e){
                    var committed=false,verification='unknown';
                    try{
                        var verify=await self.api('GET_QUICK_MARKET_HANDOVER_PROGRESS',{invoice_id:invoiceId});
                        verification='confirmed';
                        committed=(verify.events||[]).some(function(x){return x.operation_id===operationId;});
                    }catch(checkError){}
                    if(verification==='confirmed'&&!committed){
                        await supabase.storage.from('employee-documents').remove([evidencePath]);
                    }
                    if(committed)return {success:true,duplicate:true};
                    Swal.showValidationMessage(verification==='unknown'
                        ? 'تعذر التحقق من نتيجة التسجيل. تم الاحتفاظ بملف الإثبات لحين المطابقة؛ أعد تحديث الصفحة قبل إعادة المحاولة.'
                        : e.message);
                    return false;
                }
```

**Reason:** The old catch treats failed verification as confirmed non-commit and deletes the uploaded evidence. The replacement distinguishes `confirmed absent` from `unknown`; it deletes only after a successful verification explicitly confirms no event. If verification is unavailable, the object is retained and the UI tells the operator to reconcile before retrying.
