const CACHE = 'business-coach4u-v1';
const ASSETS = [
  '/',
  '/index.html',
  '/login.html',
  '/forgot-password.html',
  '/reset-password.html',
  '/inactive.html',
  '/manifest.json'
];

self.addEventListener('install', e =>
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS)))
);

self.addEventListener('fetch', e =>
  e.respondWith(caches.match(e.request).then(r => r || fetch(e.request)))
);
