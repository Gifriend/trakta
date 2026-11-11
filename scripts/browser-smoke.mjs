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
const combo = (name) => page.getByRole('combobox', { name, exact: true });
const settings = (name) => page.getByRole('dialog', { name, exact: true });
const settingsButton = (name) => page.getByRole('button', { name, exact: true });
const failures = [];
page.on('pageerror', (error) => failures.push(error.message));
try {
	// Reproduce the default Firebase Console rules and recover after publishing app rules.
	await setEmulatorRules(
		"rules_version = '2'; service cloud.firestore { match /databases/{database}/documents { match /{document=**} { allow read, write: if false; } } }"
	);
	const documentResponse = await page.goto(baseURL);
	assert.match(await documentResponse.text(), /aria-busy="true"/);
	await page.getByRole('heading', { name: 'Selamat datang kembali.' }).waitFor();
	assert.equal(await page.title(), 'Trakta');
	assert.equal(await page.locator('.brand').first().innerText(), 'Trakta');
	assert.equal(await combo('Tampilan').inputValue(), 'light');
	await combo('Tampilan').selectOption('dark');
	assert.equal(
		await page.locator('html').evaluate((root) => getComputedStyle(root).backgroundColor),
		'rgb(17, 29, 25)'
	);
	await combo('Tema').selectOption('neo');
	await combo('Bahasa').selectOption('en');
	await page.getByRole('heading', { name: 'Welcome back.' }).waitFor();
	await page.reload();
	await page.getByRole('heading', { name: 'Welcome back.' }).waitFor();
	assert.equal(await page.locator('html').getAttribute('lang'), 'en');
	assert.equal(await page.locator('html').getAttribute('data-theme'), 'neo');
	assert.equal(await combo('Appearance').inputValue(), 'dark');
	assert.equal(
		await page.locator('html').evaluate((root) => getComputedStyle(root).backgroundColor),
		'rgb(24, 28, 49)'
	);
	await combo('Appearance').selectOption('light');
	assert.equal(await page.locator('html').getAttribute('data-theme'), 'neo');
	assert.equal(await page.locator('html').getAttribute('data-mode'), 'light');
	const themePicker = combo('Theme');
	const appearance = combo('Appearance');
	for (const [theme, light, dark] of [
		['glass', 'rgb(229, 236, 255)', 'rgb(16, 22, 45)'],
		['clay', 'rgb(246, 233, 236)', 'rgb(33, 25, 37)'],
		['swiss', 'rgb(246, 246, 243)', 'rgb(20, 20, 20)'],
		['deco', 'rgb(239, 232, 216)', 'rgb(22, 21, 19)']
	]) {
		await themePicker.selectOption(theme);
		for (const [mode, color] of [
			['light', light],
			['dark', dark]
		]) {
			await appearance.selectOption(mode);
			assert.equal(
				await page.locator('html').evaluate((root) => getComputedStyle(root).backgroundColor),
				color
			);
		}
	}
	await page.reload();
	await page.getByRole('heading', { name: 'Welcome back.' }).waitFor();
	assert.equal(await themePicker.inputValue(), 'deco');
	assert.equal(await appearance.inputValue(), 'dark');
	assert.equal(await page.locator('meta[name="theme-color"]').getAttribute('content'), '#161513');
	await appearance.selectOption('light');
	await combo('Language').selectOption('id');
	await combo('Tema').selectOption('classic');
	await page.screenshot({ path: 'test-results/login-desktop.png', fullPage: true });
	await page.setViewportSize({ width: 375, height: 812 });
	assert.equal(
		await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth),
		true
	);
	await page.screenshot({ path: 'test-results/login-mobile.png', fullPage: true });
	await page.setViewportSize({ width: 320, height: 510 });
	assert.equal(await combo('Tema').count(), 0);
	await page.evaluate(() => window.scrollTo(0, 200));
	assert.ok(await page.evaluate(() => window.scrollY > 0));
	assert.equal(
		await page.locator('.auth-toolbar').evaluate((header) => header.getBoundingClientRect().top),
		0
	);
	await settingsButton('Pengaturan').click();
	await settings('Pengaturan').waitFor();
	assert.equal(await combo('Efek kamera').count(), 0);
	await combo('Tema').selectOption('glass');
	await combo('Bahasa').selectOption('en');
	await settings('Settings').getByRole('button', { name: 'Close settings' }).click();
	assert.equal(await page.locator('html').getAttribute('data-theme'), 'glass');
	await settingsButton('Settings').click();
	await combo('Theme').selectOption('classic');
	await combo('Language').selectOption('id');
	await page.keyboard.press('Escape');
	await settings('Pengaturan').waitFor({ state: 'hidden' });
	await page.evaluate(() => window.scrollTo(0, 0));
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
	// Give the capture test an asymmetric frame whose orientation is easy to verify.
	await page.evaluate(() => {
		window.__realCamera = navigator.mediaDevices.getUserMedia.bind(navigator.mediaDevices);
		navigator.mediaDevices.getUserMedia = async () => {
			const canvas = document.createElement('canvas');
			canvas.width = 320;
			canvas.height = 240;
			const context = canvas.getContext('2d');
			const stream = canvas.captureStream(12);
			const [track] = stream.getVideoTracks();
			const getSettings = track.getSettings.bind(track);
			track.getSettings = () => ({ ...getSettings(), deviceId: 'orientation-test-camera' });
			function render() {
				if (track.readyState === 'ended') return;
				context.fillStyle = '#e6c800';
				context.fillRect(window.__mirroredCamera ? 160 : 0, 0, 160, 240);
				context.fillStyle = '#002db4';
				context.fillRect(window.__mirroredCamera ? 0 : 160, 0, 160, 240);
				requestAnimationFrame(render);
			}
			render();
			return stream;
		};
	});
	await setEmulatorRules(appRules);
	await page.getByRole('button', { name: 'Muat ulang data' }).click();
	await page.getByRole('heading', { name: 'Catat presensi masuk' }).waitFor();
	await combo('Tema').selectOption('neo');
	await combo('Bahasa').selectOption('en');
	await page.getByRole('heading', { name: 'Check in', exact: true }).waitFor();
	const cameraEffect = combo('Camera effect');
	for (const [label, filter] of [
		['Sepia', 'sepia(1)'],
		['Vivid', 'saturate(1.45)'],
		['High contrast', 'contrast(1.3)'],
		['Soft', 'contrast(0.8)']
	]) {
		await cameraEffect.selectOption({ label });
		assert.equal(
			await page.locator('video').evaluate((video) => getComputedStyle(video).filter),
			filter
		);
	}
	await cameraEffect.selectOption('mono');
	assert.equal(
		await page.locator('video').evaluate((video) => getComputedStyle(video).transform),
		'none'
	);
	assert.equal(
		await page.locator('video').evaluate((video) => getComputedStyle(video).filter),
		'grayscale(1)'
	);
	await appearance.selectOption('dark');
	await page.screenshot({ path: 'test-results/trakta-neo-dark-en.png', fullPage: true });
	await page.setViewportSize({ width: 375, height: 812 });
	assert.equal(
		await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth),
		true
	);
	await page.screenshot({ path: 'test-results/trakta-neo-dark-en-mobile.png', fullPage: true });
	assert.equal(await appearance.count(), 0);
	assert.equal(await cameraEffect.count(), 0);
	await page.evaluate(() => window.scrollTo(0, 420));
	assert.ok(await page.evaluate(() => window.scrollY > 0));
	assert.equal(
		await page.locator('.topbar').evaluate((header) => header.getBoundingClientRect().top),
		0
	);
	await settingsButton('Settings').click();
	await cameraEffect.selectOption('soft');
	await page.screenshot({ path: 'test-results/settings-mobile.png' });
	await page.keyboard.press('Escape');
	await settings('Settings').waitFor({ state: 'hidden' });
	assert.equal(
		await settingsButton('Settings').evaluate((button) => button.matches(':focus')),
		true
	);
	assert.equal(
		await page.locator('video').evaluate((video) => getComputedStyle(video).filter),
		'contrast(0.8)'
	);
	await settingsButton('Settings').click();
	await cameraEffect.selectOption('mono');
	await appearance.selectOption('light');
	await settings('Settings').getByRole('link', { name: 'Attendance history' }).click();
	await settings('Settings').waitFor({ state: 'hidden' });
	assert.equal(new URL(page.url()).hash, '#riwayat');
	assert.ok(
		await page.locator('#riwayat').evaluate((history) => {
			const header = document.querySelector('.topbar');
			return history.getBoundingClientRect().top >= header.getBoundingClientRect().bottom;
		})
	);
	await page.evaluate(() => window.scrollTo(0, 0));
	for (const theme of ['glass', 'clay', 'swiss', 'deco']) {
		await settingsButton('Settings').click();
		await themePicker.selectOption(theme);
		await settings('Settings').getByRole('button', { name: 'Close settings' }).click();
		assert.equal(
			await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth),
			true,
			`${theme} fits on a phone screen`
		);
		await page.screenshot({
			path: `test-results/trakta-${theme}-light-mobile.png`,
			fullPage: true
		});
	}
	await page.setViewportSize({ width: 1440, height: 1100 });
	await combo('Language').selectOption('id');
	await combo('Tema').selectOption('classic');
	await combo('Tampilan').selectOption('light');
	await page.getByRole('button', { name: 'Ambil foto', exact: true }).click();
	const captured = page.getByAltText('Pratinjau foto presensi yang akan dikirim');
	await captured.waitFor();
	const originalPhoto = await captured.getAttribute('src');
	const samplePhoto = () =>
		captured.evaluate(async (image) => {
			await image.decode();
			const canvas = document.createElement('canvas');
			canvas.width = image.naturalWidth;
			canvas.height = image.naturalHeight;
			const context = canvas.getContext('2d');
			context.drawImage(image, 0, 0);
			return [0.25, 0.75].map((side) =>
				Array.from(context.getImageData(canvas.width * side, canvas.height / 2, 1, 1).data)
			);
		});
	const [left, right] = await samplePhoto();
	assert.ok(left[0] > right[0] + 80, 'the bright side stays on the left in the saved photo');
	for (const [red, green, blue] of [left, right]) {
		assert.ok(
			Math.abs(red - green) <= 3 && Math.abs(green - blue) <= 3,
			'saved photo is monochrome'
		);
	}
	await page.evaluate(() => {
		window.__mirroredCamera = true;
	});
	await page.getByRole('button', { name: 'Buka kamera', exact: true }).click();
	const correction = page.getByRole('checkbox', { name: 'Koreksi kiri-kanan' });
	await correction.check();
	assert.equal(
		await page.evaluate(() =>
			localStorage.getItem('trakta.cameraCorrection.orientation-test-camera')
		),
		'true'
	);
	await page.getByRole('button', { name: 'Tutup kamera' }).click();
	await page.getByRole('button', { name: 'Buka kamera', exact: true }).click();
	await correction.waitFor();
	assert.equal(await correction.isChecked(), true);
	assert.equal(
		await page.locator('video').evaluate((video) => getComputedStyle(video).transform),
		'matrix(-1, 0, 0, 1, 0, 0)'
	);
	await combo('Efek kamera').selectOption('sepia');
	await page.getByRole('button', { name: 'Ambil foto', exact: true }).click();
	await page.waitForFunction((previousSrc) => {
		const photo = document.querySelector('img[alt="Pratinjau foto presensi yang akan dikirim"]');
		return photo && photo.getAttribute('src') !== previousSrc;
	}, originalPhoto);
	const [correctedLeft, correctedRight] = await samplePhoto();
	assert.ok(
		correctedLeft[0] > correctedRight[0] + 80,
		'the camera correction restores the bright side to the left in the saved photo'
	);
	assert.ok(correctedRight[0] > correctedRight[2] + 12, 'the corrected photo uses sepia');
	await page.evaluate(() => {
		navigator.mediaDevices.getUserMedia = window.__realCamera;
	});
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
	await page.setViewportSize({ width: 375, height: 812 });
	await settingsButton('Pengaturan').click();
	await settings('Pengaturan').getByRole('button', { name: 'Keluar dari akun' }).click();
	await page.getByRole('heading', { name: 'Selamat datang kembali.' }).waitFor();
	await page.getByLabel('Alamat email').fill(email);
	await page.getByLabel('Kata sandi', { exact: true }).fill('TestPresensi123!');
	await page.getByRole('button', { name: 'Masuk ke ruang kerja' }).click();
	await page.getByRole('heading', { name: 'Hari ini, tuntas.' }).waitFor();
	assert.deepEqual(failures, [], 'No browser runtime errors');
	console.log(
		'PASS: sticky mobile headers, settings sheet and navigation, theme and language persistence, camera effects and orientation correction, camera cleanup, gallery fallback, Firestore rules recovery, check-in/out, photo history, offline blocking, and responsive layouts.'
	);
} finally {
	try {
		await setEmulatorRules(appRules);
	} finally {
		await browser.close();
	}
}
