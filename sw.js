// Service worker: de app moet ook zonder verbinding werken.
// Bump CACHE bij elke nieuwe versie, dan haalt de app zichzelf op.
const CACHE = 'voedingsschema-v12';
const BESTANDEN = [
  './',
  './index.html',
  './schemaData.js',
  './winkelData.js',
  './manifest.webmanifest',
  './icon-180.png',
  './icon-192.png',
  './icon-512.png',
  './icon-maskable-512.png',
];

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(BESTANDEN)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys()
      .then((k) => Promise.all(k.filter((n) => n !== CACHE).map((n) => caches.delete(n))))
      .then(() => self.clients.claim())
  );
});

// Netwerk eerst, cache als terugval: zo krijg je een nieuwe versie zodra
// je online bent, en blijft de app werken als je dat niet bent.
self.addEventListener('fetch', (e) => {
  if (e.request.method !== 'GET' || new URL(e.request.url).origin !== location.origin) return;
  e.respondWith(
    fetch(e.request)
      .then((r) => {
        const kopie = r.clone();
        caches.open(CACHE).then((c) => c.put(e.request, kopie));
        return r;
      })
      .catch(() => caches.match(e.request).then((r) => r || caches.match('./index.html')))
  );
});
