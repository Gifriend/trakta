<script lang="ts">
	import { onMount } from 'svelte';
	import Icon from './Icon.svelte';
	interface InstallEvent extends Event {
		prompt(): Promise<void>;
		userChoice: Promise<{ outcome: string }>;
	}
	let prompt = $state<InstallEvent | null>(null);
	let installed = $state(false);
	let help = $state(false);
	let error = $state('');
	onMount(() => {
		installed = window.matchMedia('(display-mode: standalone)').matches;
	});
	function ready(event: Event) {
		event.preventDefault();
		prompt = event as InstallEvent;
	}
	async function install() {
		error = '';
		if (!prompt) {
			help = !help;
			return;
		}
		try {
			await prompt.prompt();
			const result = await prompt.userChoice;
			installed = result.outcome === 'accepted';
			prompt = null;
		} catch {
			error = 'Pemasangan belum berhasil. Coba melalui menu browser.';
		}
	}
</script>

<svelte:window
	onbeforeinstallprompt={ready}
	onappinstalled={() => {
		installed = true;
		prompt = null;
	}}
/>
{#if !installed}<div class="install-card">
		<div class="install-icon"><Icon name="download" size={20} /></div>
		<strong>Selalu dekat,<br />di perangkatmu.</strong>
		<p>Pasang Trakta untuk akses lebih praktis.</p>
		<button type="button" class="button secondary" onclick={install}
			>Pasang aplikasi <Icon name="arrow" size={15} /></button
		>{#if help}<p class="install-help">
				Android/desktop: menu browser → Instal aplikasi. iPhone: Safari → Bagikan → Tambahkan ke
				Layar Utama. Gunakan HTTPS atau localhost.
			</p>{/if}{#if error}<p role="alert">{error}</p>{/if}
	</div>{/if}

<style>
	.install-card {
		background: var(--subtle);
		padding: 19px;
		border: 1px solid var(--border);
		border-radius: 12px;
	}
	.install-icon {
		margin-bottom: 12px;
		color: var(--primary);
	}
	strong {
		font-size: 14px;
		line-height: 1.5;
	}
	p {
		font-size: 11px;
		line-height: 1.7;
		color: var(--muted);
		margin: 8px 0 15px;
	}
	.button {
		width: 100%;
		min-height: 40px;
		font-size: 11px;
		justify-content: space-between;
		padding: 8px 11px;
	}
	.install-help {
		margin: 12px 0 0;
	}
</style>
