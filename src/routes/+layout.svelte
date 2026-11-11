<script lang="ts">
	import './layout.css';
	import { onMount } from 'svelte';
	import { setPreferences, type Theme } from '#lib/preferences.ts';
	import type { LayoutProps } from './$types';

	let { children }: LayoutProps = $props();
	let theme = $state<Theme>('classic');

	setPreferences({
		get theme() {
			return theme;
		},
		setTheme(value) {
			theme = value;
			document.documentElement.dataset.theme = value;
			try {
				localStorage.setItem('trakta.theme', value);
			} catch {
				// The current tab still applies the preference when storage is unavailable.
			}
		}
	});

	onMount(() => {
		if (document.documentElement.dataset.theme === 'neo') theme = 'neo';
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

<a class="skip-link" href="#main">Langsung ke konten</a>
{@render children()}
