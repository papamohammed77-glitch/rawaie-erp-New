// sw.js – إصدار 2.1 محسَّن (إدارة ذكية للكاش)
// متوافق مع دستور الروائع: Network Only لـ HTML و API وRuntime JS، Cache First للموارد الثابتة فقط

var STATIC_CACHE = 'rw-static-v2';
var STATIC_EXTENSIONS = ['.css', '.woff', '.woff2', '.ttf', '.png', '.jpg', '.jpeg', '.svg', '.ico', '.webp'];
var MAX_STATIC_ITEMS = 200;

self.addEventListener('install', function(event) {
    self.skipWaiting();
});

self.addEventListener('activate', function(event) {
    event.waitUntil(
        Promise.all([
            caches.keys().then(function(keys) {
                return Promise.all(keys.map(function(key) {
                    if (key !== STATIC_CACHE) {
                        console.log('[SW] حذف الكاش القديم:', key);
                        return caches.delete(key);
                    }
                }));
            }),
            self.clients.claim()
        ]).then(function() {
            return self.clients.matchAll({ type: 'window' });
        }).then(function(clientsList) {
            for (var i = 0; i < clientsList.length; i++) {
                clientsList[i].postMessage({ type: 'RW_SW_UPDATED', at: Date.now() });
            }
        })
    );
});

function isHTMLRequest(request) {
    if (request.mode === 'navigate') return true;
    var accept = request.headers.get('accept') || '';
    return accept.indexOf('text/html') !== -1;
}

function isAPIRequest(url) {
    if (url.hostname.indexOf('supabase.co') !== -1) return true;
    if (url.pathname.indexOf('/functions/v1/') !== -1) return true;
    return false;
}

function isRuntimeScript(pathname) {
    var lowerPath = pathname.toLowerCase();
    return lowerPath.slice(-3) === '.js' || lowerPath.slice(-4) === '.mjs';
}

function isStaticAsset(pathname) {
    var lowerPath = pathname.toLowerCase();
    for (var i = 0; i < STATIC_EXTENSIONS.length; i++) {
        if (lowerPath.indexOf(STATIC_EXTENSIONS[i]) !== -1) return true;
    }
    return false;
}

function trimCache(cache) {
    return cache.keys().then(function(keys) {
        if (keys.length >= MAX_STATIC_ITEMS) {
            console.warn('[SW] الكاش ممتلئ، جاري حذف أقدم ملف...');
            return cache.delete(keys[0]).then(function() {
                return cache;
            });
        }
        return cache;
    });
}

self.addEventListener('fetch', function(event) {
    var request = event.request;
    var url = new URL(request.url);

    if (request.method !== 'GET') return;

    if (isAPIRequest(url)) {
        event.respondWith(fetch(request));
        return;
    }

    if (isHTMLRequest(request)) {
        event.respondWith(fetch(request));
        return;
    }

    // Runtime application code must never be served from a stale Cache First path.
    if (isRuntimeScript(url.pathname)) {
        event.respondWith(fetch(request));
        return;
    }

    // Static assets only: Cache First with bounded cache.
    if (isStaticAsset(url.pathname)) {
        event.respondWith(
            caches.open(STATIC_CACHE).then(function(cache) {
                return cache.match(request).then(function(cached) {
                    if (cached) return cached;
                    return fetch(request).then(function(networkResponse) {
                        if (!networkResponse || networkResponse.status !== 200) return networkResponse;
                        var copy = networkResponse.clone();
                        trimCache(cache).then(function() {
                            try {
                                return cache.put(request, copy);
                            } catch (e) {
                                console.warn('[SW] تعذر تخزين الملف (تجاوز الحصة):', url.pathname);
                            }
                        });
                        return networkResponse;
                    }).catch(function() {
                        return new Response('غير متصل', { status: 503, statusText: 'Service Unavailable' });
                    });
                });
            })
        );
        return;
    }

    event.respondWith(
        fetch(request).then(function(networkResponse) {
            return networkResponse;
        }).catch(function() {
            return caches.match(request);
        })
    );
});
