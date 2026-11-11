<script lang="ts">
	import './layout.css';
	import { onMount } from 'svelte';
	import { setPreferences, type Theme } from '#lib/preferences.ts';
	import { translate, type Locale } from '#lib/i18n.ts';
	import type { LayoutProps } from './$types';

	let { children }: LayoutProps = $props();
	let theme = $state<Theme>('classic');
	let locale = $state<Locale>('id');

	function savePreference(key: string, value: string) {
		try {
			localStorage.setItem(key, value);
		} catch {
			// The preference still applies for the current tab.
		}
	}

	const t = (message: string, values?: Record<string, string>) =>
		translate(locale, message, values);

	setPreferences({
		get theme() {
			return theme;
		},
		setTheme(value) {
			theme = value;
			document.documentElement.dataset.theme = value;
			savePreference('trakta.theme', value);
		},
		get locale() {
			return locale;
		},
		setLocale(value) {
			locale = value;
			document.documentElement.lang = value;
			savePreference('trakta.locale', value);
		},
		t
	});

	onMount(() => {
		if (document.documentElement.dataset.theme === 'neo') theme = 'neo';
		if (document.documentElement.lang === 'en') locale = 'en';
	});
</script>

<svelte:head>
	<link rel="icon" href="/icon.svg" type="image/svg+xml" />
	<link rel="manifest" href="/manifest.webmanifest" />
	<link rel="apple-touch-icon" href="/icons/icon-192.png" />
	<meta name="theme-color" content={theme === 'neo' ? '#ffdf66' : '#124e43'} />
	<meta name="apple-mobile-web-app-capable" content="yes" />
	<meta name="apple-mobile-web-app-title" content="Trakta" />
	<meta name="apple-mobile-web-app-status-bar-style" content="default" />
</svelte:head>

<a class="skip-link" href="#main">{t('Langsung ke konten')}</a>
{@render children()}
