import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';

const logo = await readFile(new URL('../static/icon.svg', import.meta.url), 'utf8');
const browser = await chromium.launch({ channel: 'chrome' });
try {
	const page = await browser.newPage();
	for (const [size, name, maskable] of [
		[192, 'icon-192.png', false],
		[512, 'icon-512.png', false],
		[512, 'maskable-512.png', true]
	]) {
		const svg = maskable ? logo.replace('rx="120"', 'rx="0"') : logo;
		await page.setContent(
			`<style>body { margin: 0 } svg { display: block; width: ${size}px; height: ${size}px }</style>${svg}`
		);
		await page.locator('svg').screenshot({
			path: fileURLToPath(new URL(`../static/icons/${name}`, import.meta.url)),
			omitBackground: true
		});
	}
} finally {
	await browser.close();
}
