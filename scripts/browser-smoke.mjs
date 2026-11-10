import { chromium } from 'playwright';
import { mkdir, readFile } from 'node:fs/promises';
import assert from 'node:assert/strict';

const baseURL = process.env.TEST_URL || 'http://127.0.0.1:5173';
const appRules = await readFile('firestore.rules', 'utf8');
async function setEmulatorRules(content) {
	const response = await fetch(
		'http://127.0.0.1:8085/emulator/v1/projects/demo-presensi:securityRules',
		{
			method: 'PUT',
			body: JSON.stringify({ rules: { files: [{ content }] } })
		}
	);
	if (!response.ok) throw new Error(`Emulator rules update failed: ${await response.text()}`);
}
await mkdir('test-results', { recursive: true });
const browser = await chromium.launch({
	channel: 'chrome',
	headless: true,
	args: ['--use-fake-device-for-media-stream']
});
const context = await browser.newContext({
	viewport: { width: 1440, height: 1100 },
	permissions: ['camera']
});
const page = await context.newPage();
const failures = [];
page.on('pageerror', (error) => failures.push(error.message));
try {
	// Reproduce the default Firebase Console rules and recover after publishing app rules.
	await setEmulatorRules(
		"rules_version = '2'; service cloud.firestore { match /databases/{database}/documents { match /{document=**} { allow read, write: if false; } } }"
	);
	await page.goto(baseURL);
	await page.getByRole('heading', { name: 'Selamat datang kembali.' }).waitFor();
	assert.equal(await page.title(), 'Trakta');
	assert.equal(await page.locator('.brand').first().innerText(), 'Trakta');
	await page.screenshot({ path: 'test-results/login-desktop.png', fullPage: true });
	await page.setViewportSize({ width: 375, height: 812 });
	assert.equal(
		await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth),
		true
	);
	await page.screenshot({ path: 'test-results/login-mobile.png', fullPage: true });
	await page.setViewportSize({ width: 1440, height: 1100 });
	await page.getByRole('button', { name: 'Daftar sekarang' }).click();
	await page.getByLabel('Nama lengkap').fill('Rani QA');
	const email = `qa-${Date.now()}@example.test`;
	await page.getByLabel('Alamat email').fill(email);
	await page.getByLabel('Kata sandi', { exact: true }).fill('TestPresensi123!');
	await page.getByRole('button', { name: 'Buat akun' }).click();
	await page.getByRole('heading', { name: 'Akses presensi belum diizinkan' }).waitFor();
	await page.getByRole('alert').filter({ hasText: 'Hubungi pengelola aplikasi' }).waitFor();
	assert.equal(await page.getByRole('heading', { name: 'Jejak kehadiranmu' }).count(), 0);
	await page.screenshot({ path: 'test-results/firestore-denied.png', fullPage: true });
	await setEmulatorRules(appRules);
	await page.getByRole('button', { name: 'Muat ulang data' }).click();
	await page.getByRole('heading', { name: 'Catat presensi masuk' }).waitFor();
	await page.getByRole('button', { name: 'Ambil foto', exact: true }).click();
	await page.getByAltText('Pratinjau foto presensi yang akan dikirim').waitFor();
	assert.equal(
		await page.getByLabel('Pilih atau ambil foto presensi').getAttribute('capture'),
		null
	);
	await page.getByRole('button', { name: 'Buka kamera', exact: true }).click();
	await page.waitForFunction(() => document.querySelector('video')?.readyState >= 2);
	await page.evaluate(() => {
		window.__cameraTestStream = document.querySelector('video').srcObject;
	});
	await page.evaluate(() => {
		Object.defineProperty(document, 'hidden', { configurable: true, get: () => true });
		document.dispatchEvent(new Event('visibilitychange'));
		delete document.hidden;
	});
	assert.equal(
		await page.evaluate(() =>
			window.__cameraTestStream.getTracks().every((track) => track.readyState === 'ended')
		),
		true
	);
	await page.getByRole('button', { name: 'Buka kamera', exact: true }).click();
	await page.waitForFunction(() => document.querySelector('video')?.readyState >= 2);
	await page.evaluate(() => {
		window.__cameraTestStream = document.querySelector('video').srcObject;
	});
	await page.screenshot({ path: 'test-results/dashboard-desktop.png', fullPage: true });
	await page.setViewportSize({ width: 375, height: 812 });
	assert.equal(
		await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth),
		true
	);
	await page.screenshot({ path: 'test-results/dashboard-mobile.png', fullPage: true });
	await page.setViewportSize({ width: 812, height: 375 });
	assert.equal(
		await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth),
		true
	);
	await page.setViewportSize({ width: 1440, height: 1100 });
	await page
		.getByLabel('Pilih atau ambil foto presensi')
		.setInputFiles({ name: 'invalid.txt', mimeType: 'text/plain', buffer: Buffer.from('invalid') });
	await page.getByRole('alert').filter({ hasText: 'Gunakan foto JPG' }).waitFor();
	assert.equal(
		await page.evaluate(() =>
			window.__cameraTestStream.getTracks().every((track) => track.readyState === 'ended')
		),
		true
	);
	const inputPhoto = await page.evaluate(() => {
		const canvas = document.createElement('canvas');
		canvas.width = 1600;
		canvas.height = 1200;
		const ctx = canvas.getContext('2d');
		const image = ctx.createImageData(canvas.width, canvas.height);
		let seed = 17;
		for (let i = 0; i < image.data.length; i += 4) {
			seed = (seed * 1664525 + 1013904223) >>> 0;
			image.data[i] = seed & 255;
			image.data[i + 1] = (seed >>> 8) & 255;
			image.data[i + 2] = (seed >>> 16) & 255;
			image.data[i + 3] = 255;
		}
		ctx.putImageData(image, 0, 0);
		return canvas.toDataURL('image/png').split(',')[1];
	});
	const buffer = Buffer.from(inputPhoto, 'base64');
	for (const kind of ['masuk', 'pulang']) {
		await page.getByRole('heading', { name: `Catat presensi ${kind}` }).waitFor();
		if (kind === 'masuk') {
			await page.getByRole('button', { name: 'Buka kamera', exact: true }).click();
			await page.waitForFunction(() => document.querySelector('video')?.readyState >= 2);
			await page.evaluate(() => {
				window.__cameraTestStream = document.querySelector('video').srcObject;
			});
			await page.getByRole('button', { name: 'Ambil foto', exact: true }).click();
			await page.getByAltText('Pratinjau foto presensi yang akan dikirim').waitFor();
			assert.equal(
				await page.evaluate(() =>
					window.__cameraTestStream.getTracks().every((track) => track.readyState === 'ended')
				),
				true
			);
		} else {
			await page.getByRole('button', { name: 'Tutup kamera' }).click();
			await page.evaluate(() => {
				window.__originalGetUserMedia = navigator.mediaDevices.getUserMedia.bind(
					navigator.mediaDevices
				);
				navigator.mediaDevices.getUserMedia = async () => {
					throw new DOMException('Denied for test', 'NotAllowedError');
				};
			});
			await page.getByRole('button', { name: 'Buka kamera', exact: true }).click();
			await page.getByRole('alert').filter({ hasText: 'Izin kamera belum diberikan' }).waitFor();
			const chooserPromise = page.waitForEvent('filechooser');
			await page.getByRole('button', { name: 'Pilih galeri/file', exact: true }).click();
			await (await chooserPromise).setFiles({ name: 'daily.png', mimeType: 'image/png', buffer });
			await page.evaluate(() => {
				navigator.mediaDevices.getUserMedia = window.__originalGetUserMedia;
			});
		}
		await page.getByAltText('Pratinjau foto presensi yang akan dikirim').waitFor();
		const bytes = await page
			.getByAltText('Pratinjau foto presensi yang akan dikirim')
			.evaluate((img) => atob(img.src.split(',')[1]).length);
		assert.ok(bytes > 0 && bytes <= 100000, `compressed photo: ${bytes} bytes`);
		console.log(
			`${kind}: ${kind === 'masuk' ? 'camera capture' : `input ${buffer.length} bytes`} -> ${bytes} bytes`
		);
		await page.getByLabel('Catatan').fill(`Catatan ${kind} dari browser test`);
		if (kind === 'masuk') {
			await context.setOffline(true);
			await page.getByRole('status').filter({ hasText: 'Kamu sedang offline' }).first().waitFor();
			assert.equal(await page.getByRole('button', { name: 'Konfirmasi masuk' }).isDisabled(), true);
			await context.setOffline(false);
		}
		await page.getByRole('button', { name: `Konfirmasi ${kind}` }).click();
	}
	await page.getByRole('heading', { name: 'Hari ini, tuntas.' }).waitFor();
	await page.getByRole('button', { name: /Lihat foto masuk/ }).click();
	await page.getByRole('dialog').getByRole('img').waitFor();
	await page.getByRole('button', { name: 'Tutup foto' }).click();
	await page.keyboard.press('Tab');
	await page.screenshot({ path: 'test-results/completed-desktop.png', fullPage: true });
	await page.getByRole('button', { name: 'Keluar dari akun' }).first().click();
	await page.getByRole('heading', { name: 'Selamat datang kembali.' }).waitFor();
	await page.getByLabel('Alamat email').fill(email);
	await page.getByLabel('Kata sandi', { exact: true }).fill('TestPresensi123!');
	await page.getByRole('button', { name: 'Masuk ke ruang kerja' }).click();
	await page.getByRole('heading', { name: 'Hari ini, tuntas.' }).waitFor();
	assert.deepEqual(failures, [], 'No browser runtime errors');
	console.log(
		'PASS: automatic camera, capture and stream cleanup, gallery picker, camera permission fallback, Trakta branding, rules recovery, login, compression, check-in/out, photo history, offline blocking, responsive layouts.'
	);
} finally {
	try {
		await setEmulatorRules(appRules);
	} finally {
		await browser.close();
	}
}
