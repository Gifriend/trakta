<script lang="ts">
	import type { Snippet } from 'svelte';
	import { getPreferences } from '#lib/preferences.ts';
	import Preferences from './Preferences.svelte';
	import CameraEffectSelect from './CameraEffectSelect.svelte';
	import Icon from './Icon.svelte';

	let { camera = false, children }: { camera?: boolean; children?: Snippet<[close: () => void]> } =
		$props();
	let dialog: HTMLDialogElement;
	const id = $props.id();
	const { t } = getPreferences();

	function close() {
		dialog.close();
	}
</script>

<button
	type="button"
	class="settings-trigger icon-button"
	aria-label={t('Pengaturan')}
	aria-haspopup="dialog"
	aria-controls={id}
	onclick={() => dialog.showModal()}><Icon name="menu" size={23} /></button
>

<dialog {id} bind:this={dialog} class="settings-sheet" aria-labelledby={`${id}-title`}>
	<div class="sheet-heading">
		<h2 id={`${id}-title`}>{t('Pengaturan')}</h2>
		<button type="button" class="icon-button" aria-label={t('Tutup pengaturan')} onclick={close}
			><Icon name="close" /></button
		>
	</div>
	<div class="sheet-controls">
		<Preferences stacked />
		{#if camera}<CameraEffectSelect />{/if}
	</div>
	{#if children}
		<div class="sheet-actions">{@render children(close)}</div>
	{/if}
</dialog>

<style>
	.settings-trigger {
		background: var(--subtle);
		border: 1px solid var(--control-border);
		border-radius: var(--control-radius);
		color: var(--ink);
	}
	.settings-sheet {
		position: fixed;
		inset: auto 0 0;
		margin: 0 auto;
		width: min(100%, 460px);
		max-width: none;
		max-height: min(88dvh, 36rem);
		overflow-y: auto;
		overscroll-behavior: contain;
		padding: 16px max(20px, env(safe-area-inset-right)) calc(20px + env(safe-area-inset-bottom))
			max(20px, env(safe-area-inset-left));
		border: 1px solid var(--border);
		border-radius: calc(var(--control-radius) * 2) calc(var(--control-radius) * 2) 0 0;
		background: var(--surface);
		color: var(--ink);
	}
	.settings-sheet::backdrop {
		background: #0c151b88;
	}
	.sheet-heading {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 12px;
		margin-bottom: 12px;
	}
	.sheet-heading h2 {
		font-size: 21px;
	}
	.sheet-controls {
		display: grid;
		gap: 10px;
	}
	.sheet-actions {
		margin-top: 16px;
		padding-top: 10px;
		border-top: 1px solid var(--border);
	}
	@media (min-width: 901px) {
		.settings-trigger {
			display: none;
		}
	}
</style>
