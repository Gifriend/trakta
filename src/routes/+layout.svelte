<script lang="ts">
	import './layout.css';
	import type { LayoutProps } from './$types';

	let { children }: LayoutProps = $props();
</script>

<svelte:head>
	<link rel="icon" href="/icon.svg" type="image/svg+xml" />
	<link rel="manifest" href="/manifest.webmanifest" />
	<link rel="apple-touch-icon" href="/icons/icon-192.png" />
	<meta name="theme-color" content="#124e43" />
	<meta name="apple-mobile-web-app-capable" content="yes" />
	<meta name="apple-mobile-web-app-title" content="Trakta" />
	<meta name="apple-mobile-web-app-status-bar-style" content="default" />
</svelte:head>

<a class="skip-link" href="#main">Langsung ke konten</a>
{@render children()}
