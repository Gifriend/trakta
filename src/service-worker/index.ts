/// <reference lib="webworker" />
import { immutable, assets } from '$app/manifest';
import { version } from '$app/env';

const worker = self as unknown as ServiceWorkerGlobalScope;
const CACHE = `trakta-shell-${version}`;
const ASSETS = [...immutable, ...assets].map(
	({ path }) => new URL(path, worker.registration.scope).pathname
);
ASSETS.push('/');

worker.addEventListener('install', (event) => {
	event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(ASSETS)));
});

worker.addEventListener('activate', (event) => {
	event.waitUntil(
		(async () => {
			for (const key of await caches.keys()) {
				// Remove caches from the previous app name when the new worker activates.
				if ((key.startsWith('trakta-shell-') || key.startsWith('hadir-shell-')) && key !== CACHE) {
					await caches.delete(key);
				}
			}
			await worker.clients.claim();
		})()
	);
});

worker.addEventListener('fetch', (event) => {
	const url = new URL(event.request.url);
	// Cache only the public application shell, never Auth/Firestore responses or photos.
	if (event.request.method !== 'GET' || url.origin !== worker.location.origin) return;
	if (event.request.mode === 'navigate' && url.pathname === '/') {
		event.respondWith(
			(async () => {
				try {
					return await fetch(event.request);
				} catch {
					return (await (await caches.open(CACHE)).match('/')) || Response.error();
				}
			})()
		);
	} else if (ASSETS.includes(url.pathname)) {
		event.respondWith(
			(async () => {
				const cache = await caches.open(CACHE);
				return (await cache.match(url.pathname)) || fetch(event.request);
			})()
		);
	}
});
