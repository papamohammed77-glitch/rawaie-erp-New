    async function _startBarcodeScanner(prefix) {
        var input = byId(prefix + '-item-search');
        if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia || typeof window.BarcodeDetector === 'undefined') {
            if (input) {
                input.focus();
                input.select();
            }
            showToast('مسح الباركود بالكاميرا غير مدعوم في هذا المتصفح. استخدم البحث أو قارئ الباركود المتصل.', 'warning');
            return;
        }

        var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
        if (!companyId) {
            showToast('سياق الشركة غير محدد', 'error');
            return;
        }

        var stream = null;
        var timer = null;
        var stopped = false;
        var videoId = 'rw-barcode-video-' + Date.now();

        try {
            var formats = ['ean_13', 'ean_8', 'code_128', 'code_39', 'upc_a', 'upc_e', 'qr_code'];
            try {
                if (BarcodeDetector.getSupportedFormats) {
                    var supported = await BarcodeDetector.getSupportedFormats();
                    formats = formats.filter(function(f) { return supported.indexOf(f) !== -1; });
                }
            } catch (_) {}

            var detector = formats.length ? new BarcodeDetector({ formats: formats }) : new BarcodeDetector();

            var result = await Swal.fire({
                title: 'مسح الباركود',
                html: '<div class="text-center"><div class="mb-3 text-sm text-slate-500">وجّه الكاميرا إلى باركود الصنف</div><div class="relative overflow-hidden rounded-2xl bg-black"><video id="' + videoId + '" autoplay muted playsinline style="width:100%;max-height:420px;object-fit:cover"></video><div class="absolute inset-6 border-2 border-emerald-400 rounded-xl pointer-events-none"></div></div></div>',
                width: '650px',
                showCancelButton: true,
                confirmButtonText: 'إغلاق',
                cancelButtonText: 'إلغاء',
                showConfirmButton: false,
                allowOutsideClick: false,
                didOpen: async function() {
                    try {
                        stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: { ideal: 'environment' } }, audio: false });
                        var video = document.getElementById(videoId);
                        if (!video) throw new Error('تعذر تشغيل كاميرا المسح');
                        video.srcObject = stream;
                        await video.play();

                        var lastRaw = '';
                        var lastToastAt = 0;
                        var scan = async function() {
                            if (stopped) return;
                            try {
                                if (video.readyState >= 2) {
                                    var codes = await detector.detect(video);
                                    if (codes && codes.length) {
                                        var raw = String(codes[0].rawValue || '').trim();
                                        if (raw && raw !== lastRaw) {
                                            lastRaw = raw;
                                            var items = (RW_STATE.data && RW_STATE.data.items) || [];
                                            var matched = null;
                                            for (var i = 0; i < items.length; i++) {
                                                var item = items[i];
                                                if (String(item.barcode || '').trim() === raw || String(item.item_code || '').trim() === raw) {
                                                    matched = item;
                                                    break;
                                                }
                                            }

                                            if (!matched) {
                                                var now = Date.now();
                                                if (now - lastToastAt > 1500) {
                                                    showToast('لم يتم العثور على صنف لهذا الباركود: ' + raw, 'warning');
                                                    lastToastAt = now;
                                                }
                                            } else {
                                                _addToInvCart(prefix, matched.item_code);
                                                if (input) {
                                                    input.value = '';
                                                    input.focus();
                                                }
                                                Swal.close();
                                                return;
                                            }
                                        }
                                    }
                                }
                            } catch (e) {
                                console.warn('BarcodeDetector scan error', e);
                            }
                            timer = setTimeout(function() { lastRaw = ''; scan(); }, 350);
                        };
                        scan();
                    } catch (e) {
                        showToast('تعذر الوصول إلى الكاميرا: ' + (e.message || ''), 'error');
                        if (input) {
                            input.focus();
                            input.select();
                        }
                        Swal.close();
                    }
                },
                willClose: function() {
                    stopped = true;
                    if (timer) {
                        clearTimeout(timer);
                        timer = null;
                    }
                    if (stream) {
                        var tracks = stream.getTracks ? stream.getTracks() : [];
                        for (var i = 0; i < tracks.length; i++) tracks[i].stop();
                        stream = null;
                    }
                }
            });

            return result;
        } catch (e) {
            stopped = true;
            if (timer) clearTimeout(timer);
            if (stream) {
                var tracks = stream.getTracks ? stream.getTracks() : [];
                for (var j = 0; j < tracks.length; j++) tracks[j].stop();
            }
            if (input) {
                input.focus();
                input.select();
            }
            showToast(e.message || 'فشل تشغيل قارئ الباركود', 'error');
            return null;
        }
    }

    async function _saveInvCount(type, entityId, reference) {
        if (!window._invCart || window._invCart.length === 0) {
            showToast('أضف أصنافاً', 'warning');
            return;
        }
        if (!entityId) {
            showToast('الكيان المستهدف للجرد غير محدد', 'warning');
            return;
        }

        var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
        if (!companyId) {
            showToast('سياق الشركة غير محدد', 'error');
            return;
        }

        var items = [];
        for (var i = 0; i < window._invCart.length; i++) {
            var q = parseInt(window._invCart[i].qty, 10) || 0;
            if (q < 0) {
                showToast('كمية الجرد لا يمكن أن تكون سالبة', 'warning');
                return;
            }
            items.push({
                itemCode: window._invCart[i].code,
                itemName: window._invCart[i].name,
                unit: window._invCart[i].unit,
                qty: q,
                unitPrice: 0,
                notes: ''
            });
        }

        var prefix = type === 'vehicle' ? 'vc' : (type === 'branch' ? 'bc' : 'gc');
        showLoader('جاري حفظ الجرد...');
        try {
            var ses = await supabase.auth.getSession();
            var token = ses.data.session ? ses.data.session.access_token : null;
            if (!token) throw new Error('انتهت الجلسة. يرجى إعادة تسجيل الدخول.');

            var res = await fetch(RW_SUPABASE_URL + '/functions/v1/save-inventory-count', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer ' + token
                },
                body: JSON.stringify({
                    type: type,
                    entityId: entityId,
                    reference: reference,
                    items: items
                })
            });

            var json = await res.json().catch(function() { return {}; });
            if (!res.ok || !json || !json.success) {
                throw new Error((json && (json.msg || json.error)) || 'فشل حفظ الجرد');
            }

            hideLoader();
            window._invCart = [];
            _renderInvCart(prefix);
            showToast(json.msg || ('تم حفظ الجرد ' + (json.count_id || '')), 'success');
        } catch (e) {
            hideLoader();
            showToast(e.message || 'فشل الاتصال', 'error');
        }
    }
