import { chromium } from 'playwright';
import assert from 'node:assert/strict';
import { mkdir, mkdtemp } from 'node:fs/promises';

await mkdir('test-results', { recursive: true });
const profile = await mkdtemp('test-results/trakta-pwa-');
const context = await chromium.launchPersistentContext(profile, {
	channel: 'chrome',
	headless: true
});
const page = await context.newPage();
const errors = [];
page.on('pageerror', (error) => errors.push(error.message));
page.on('console', (message) => {
	if (message.type() === 'error') console.log('Browser:', message.text());
});
page.on('response', (response) => {
	if (response.status() >= 400) console.log('HTTP:', response.status(), response.url());
});
try {
	const baseURL = process.env.TEST_URL || 'http://127.0.0.1:4173';
	const cacheSeedPage = new URL('/__pwa-cache-seed', baseURL).href;
	await page.route(cacheSeedPage, (route) =>
		route.fulfill({ contentType: 'text/html', body: '<link rel="icon" href="/icon.svg">' })
	);
	await page.goto(cacheSeedPage);
	await page.evaluate(() => caches.open('hadir-shell-upgrade-test'));
	await page.unroute(cacheSeedPage);
	await page.goto(baseURL);
	await page.getByRole('heading', { name: 'Selamat datang kembali.' }).waitFor();
	await page.evaluate(() =>
		Promise.race([
			navigator.serviceWorker.ready,
			new Promise((_, reject) =>
				setTimeout(() => reject(new Error('Service worker did not become ready')), 15000)
			)
		])
	);
	await page.reload();
	const result = await page.evaluate(async () => {
		const registration = await navigator.serviceWorker.ready;
		const keys = await caches.keys();
		const cache = await caches.open(keys.find((key) => key.startsWith('trakta-shell-')));
		return {
			scope: registration.scope,
			controlled: !!navigator.serviceWorker.controller,
			legacyCachePresent: keys.some((key) => key.startsWith('hadir-shell-')),
			cached: (await cache.keys()).map((entry) => entry.url)
		};
	});
	assert.ok(result.controlled);
	assert.equal(result.legacyCachePresent, false);
	assert.ok(result.cached.some((url) => new URL(url).pathname === '/'));
	assert.ok(result.cached.every((url) => new URL(url).origin === new URL(page.url()).origin));
	const cdp = await context.newCDPSession(page);
	await cdp.send('Page.enable');
	const manifest = await cdp.send('Page.getAppManifest');
	assert.deepEqual(manifest.errors, []);
	const appManifest = JSON.parse(manifest.data);
	assert.equal(appManifest.name, 'Trakta');
	assert.equal(appManifest.short_name, 'Trakta');
	assert.equal(await page.title(), 'Trakta');
	const install = await cdp.send('Page.getInstallabilityErrors');
	assert.deepEqual(install.installabilityErrors, []);
	await context.setOffline(true);
	await page.reload();
	await page.getByRole('heading', { name: 'Selamat datang kembali.' }).waitFor();
	assert.deepEqual(errors, []);
	console.log(
		`PASS: valid installable manifest, active worker, ${result.cached.length} same-origin shell assets, offline reload.`
	);
} finally {
	await context.close();
}
