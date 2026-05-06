const CACHE = 'coaching-portal-v17'
const ASSETS = [
  './',
  './index.html',
  './reset-password.html',
  './coach4u-tools.html',
  './coach4u-tools/strengths-clifton.html',
  './coach4u-tools/coaching-admin.html',
  './resources.html',
  './resources/feelings-chart.html',
  './resources/smart-goal.html',
  './resources/issue-clarifier.html'
]

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS)))
  self.skipWaiting()
})

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    )
  )
  self.clients.claim()
})

self.addEventListener('fetch', e => {
  if (e.request.url.includes('supabase')) return
  e.respondWith(
    fetch(e.request).catch(() => caches.match(e.request))
  )
})
