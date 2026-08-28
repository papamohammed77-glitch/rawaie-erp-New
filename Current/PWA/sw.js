// sw.js – إصدار 2.1 (إدارة ذكية للكاش دون تجميد runtime)
// Network Only لـ HTML و API و runtime JS؛ Cache First للموارد الثابتة غير التنفيذية.

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
                    if (key !== STATIC_CACHE) return caches.delete(key);
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

function isRuntimeRequest(url) {
    var lowerPath = url.pathname.toLowerCase();
    return lowerPath.indexOf('.js') !== -1 || lowerPath.indexOf('.mjs') !== -1 || lowerPath.indexOf('.ts') !== -1;
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
            return cache.delete(keys[0]).then(function() { return cache; });
        }
        return cache;
    });
}

self.addEventListener('fetch', function(event) {
    var request = event.request;
    var url = new URL(request.url);

    if (request.method !== 'GET') return;

    if (isAPIRequest(url) || isHTMLRequest(request) || isRuntimeRequest(url)) {
        event.respondWith(fetch(request));
        return;
    }

    if (isStaticAsset(url.pathname)) {
        event.respondWith(
            caches.open(STATIC_CACHE).then(function(cache) {
                return cache.match(request).then(function(cached) {
                    if (cached) return cached;
                    return fetch(request).then(function(networkResponse) {
                        if (!networkResponse || networkResponse.status !== 200) return networkResponse;
                        var copy = networkResponse.clone();
                        trimCache(cache).then(function() {
                            try { return cache.put(request, copy); }
                            catch (e) { console.warn('[SW] تعذر تخزين المورد:', url.pathname); }
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
        fetch(request).catch(function() {
            return caches.match(request);
        })
    );
});