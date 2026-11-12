<script lang="ts">
	import { onMount } from 'svelte';
	import { getPreferences } from '#lib/preferences.ts';
	import type { CompressedPhoto } from '#lib/types/attendance.ts';
	import { compressPhoto } from '#lib/utils/image.ts';
	import {
		DEFAULT_PHOTO_EDITS,
		decodePhoto,
		saveEditedPhoto,
		type PhotoEdits
	} from '#lib/utils/photo-editor.ts';
	import { composePhotoBooth } from '#lib/utils/photobooth.ts';
	import { friendlyError } from '#lib/firebase/auth.ts';
	import PhotoPicker from './PhotoPicker.svelte';
	import PhotoEditor from './PhotoEditor.svelte';
	import Icon from './Icon.svelte';

	let { onclose }: { onclose: () => void } = $props();
	const { t } = getPreferences();
	const id = $props.id();
	let dialog: HTMLDialogElement;
	let picker = $state<{ openCamera: () => Promise<void>; stopCamera: () => void }>();
	let photos = $state.raw<CompressedPhoto[]>([]);
	let target = $state(3);
	let layout = $state<'strip' | 'grid'>('strip');
	let color = $state('#fff1d8');
	let timer = $state(3);
	let capturing = $state(false);
	let replacing = $state<number | null>(null);
	let processing = $state(false);
	let error = $state('');
	let original = $state.raw<CompressedPhoto | null>(null);
	let result = $state.raw<CompressedPhoto | null>(null);
	let edits = $state.raw(DEFAULT_PHOTO_EDITS);
	let editing = $state(false);

	onMount(() => {
		dialog.showModal();
	});

	function invalidateResult() {
		original = null;
		result = null;
		edits = DEFAULT_PHOTO_EDITS;
	}
	async function selectPhoto(file: File, frame: PhotoEdits['frame'] = 'none') {
		processing = true;
		error = '';
		try {
			let photo = await compressPhoto(file);
			if (frame !== 'none')
				photo = await saveEditedPhoto(await decodePhoto(photo.dataUrl), {
					...DEFAULT_PHOTO_EDITS,
					frame
				});
			photos =
				replacing === null
					? [...photos, photo]
					: photos.map((item, index) => (index === replacing ? photo : item));
			replacing = null;
			capturing = false;
			invalidateResult();
		} catch (cause) {
			error = friendlyError(cause);
		} finally {
			processing = false;
		}
	}
	async function compose() {
		processing = true;
		error = '';
		try {
			original = await composePhotoBooth(photos, layout, color);
			result = original;
			edits = DEFAULT_PHOTO_EDITS;
			editing = true;
		} catch (cause) {
			error = friendlyError(cause);
		} finally {
			processing = false;
		}
	}
	function close() {
		picker?.stopCamera();
		dialog.close();
	}
</script>

<dialog
	bind:this={dialog}
	class="booth"
	aria-labelledby={`${id}-title`}
	{onclose}
	oncancel={(event) => {
		if (processing || editing) event.preventDefault();
		else picker?.stopCamera();
	}}
>
	<div class="heading">
		<div>
			<h2 id={`${id}-title`}>{t('Fotobox')}</h2>
			<p>{t('Ambil beberapa pose, hias, lalu simpan ke perangkatmu.')}</p>
		</div>
		<button
			type="button"
			class="icon-button"
			aria-label={t('Tutup fotobox')}
			disabled={processing || editing}
			onclick={close}><Icon name="close" /></button
		>
	</div>
	{#if !capturing}
		<div class="options">
			<label for={`${id}-count`}
				>{t('Jumlah foto')}<select
					id={`${id}-count`}
					bind:value={target}
					disabled={photos.length > 0 || processing}
					><option value={2}>2</option><option value={3}>3</option><option value={4}>4</option
					></select
				></label
			>
			<label for={`${id}-layout`}
				>{t('Susunan foto')}<select
					id={`${id}-layout`}
					bind:value={layout}
					disabled={processing}
					onchange={invalidateResult}
					><option value="strip">{t('Strip vertikal')}</option><option value="grid"
						>{t('Kolase')}</option
					></select
				></label
			>
			<label for={`${id}-timer`}
				>{t('Timer kamera')}<select id={`${id}-timer`} bind:value={timer} disabled={processing}
					><option value={0}>{t('Tanpa timer')}</option><option value={3}>3 s</option><option
						value={5}>5 s</option
					></select
				></label
			>
			<label for={`${id}-color`}
				>{t('Warna bingkai')}<select
					id={`${id}-color`}
					bind:value={color}
					disabled={processing}
					onchange={invalidateResult}
					><option value="#fff1d8">{t('Krem')}</option><option value="#ffe2ec"
						>{t('Merah muda')}</option
					><option value="#e1e9ff">{t('Lavender')}</option><option value="#d5f3e8"
						>{t('Mint')}</option
					><option value="#ffffff">{t('Putih')}</option></select
				></label
			>
		</div>
		<div class="shots">
			{#each photos as photo, index (photo)}
				<div>
					<img src={photo.dataUrl} alt={t('Pose {number}', { number: String(index + 1) })} /><button
						type="button"
						class="button secondary"
						disabled={processing}
						onclick={() => {
							replacing = index;
							capturing = true;
						}}>{t('Ambil ulang')} {index + 1}</button
					>
				</div>
			{/each}
		</div>
		{#if photos.length < target}
			<p role="status">
				{t('Foto {current} dari {total}', {
					current: String(photos.length),
					total: String(target)
				})}
			</p>
			<button
				type="button"
				class="button primary"
				disabled={processing}
				onclick={() => {
					replacing = null;
					capturing = true;
				}}><Icon name="camera" />{t('Ambil pose berikutnya')}</button
			>
		{:else}
			<button
				type="button"
				class="button primary"
				disabled={processing}
				onclick={() => {
					if (original) editing = true;
					else void compose();
				}}>{t(processing ? 'Menyiapkan foto…' : 'Hias fotobox')}</button
			>
		{/if}
	{:else}
		<p role="status">{t('Pose {number}', { number: String((replacing ?? photos.length) + 1) })}</p>
		<PhotoPicker
			bind:this={picker}
			photo={null}
			{processing}
			disabled={processing}
			countdownSeconds={timer}
			onselect={selectPhoto}
			onactivechange={() => {}}
		/>
		<button
			type="button"
			class="button secondary"
			disabled={processing}
			onclick={() => {
				picker?.stopCamera();
				capturing = false;
			}}>{t('Kembali')}</button
		>
	{/if}
	{#if result && !capturing}
		<img class="result" src={result.dataUrl} alt={t('Hasil fotobox')} />
		<a class="button primary" href={result.dataUrl} download="trakta-fotobox.jpg" rel="external"
			>{t('Unduh fotobox')}</a
		>
	{/if}
	{#if photos.length && !capturing}
		<button
			type="button"
			class="button secondary restart"
			disabled={processing}
			onclick={() => {
				photos = [];
				invalidateResult();
			}}>{t('Mulai sesi baru')}</button
		>
	{/if}
	{#if error}<p role="alert" class="notice error">{t(error)}</p>{/if}
</dialog>
{#if editing && original}
	<PhotoEditor
		{original}
		initialEdits={edits}
		onapply={(photo, nextEdits) => {
			result = photo;
			edits = nextEdits;
		}}
		onclose={() => (editing = false)}
	/>
{/if}

<style>
	.booth {
		position: fixed;
		inset: 0;
		margin: auto;
		width: min(calc(100% - 24px), 640px);
		max-height: calc(100dvh - 32px);
		overflow-y: auto;
		padding: 20px;
		background: var(--surface);
		color: var(--ink);
		border: 1px solid var(--border);
		border-radius: 18px;
		overscroll-behavior: contain;
	}
	.booth::backdrop {
		background: #0c151bb0;
	}
	.heading {
		display: flex;
		align-items: start;
		justify-content: space-between;
		gap: 12px;
	}
	h2 {
		font-size: 24px;
	}
	p {
		font-size: 13px;
		color: var(--muted);
		margin: 8px 0 16px;
	}
	.options {
		display: grid;
		grid-template-columns: repeat(2, minmax(0, 1fr));
		gap: 12px;
		margin-block: 18px;
	}
	label {
		font-size: 13px;
	}
	select {
		display: block;
		width: 100%;
		margin-top: 6px;
		min-height: 44px;
		background: var(--surface);
		color: var(--ink);
		border: 1px solid var(--control-border);
		border-radius: var(--control-radius);
		padding: 8px;
		font-size: 16px;
	}
	.shots {
		display: grid;
		grid-template-columns: repeat(2, minmax(0, 1fr));
		gap: 12px;
		margin-bottom: 16px;
	}
	.shots img {
		width: 100%;
		aspect-ratio: 4 / 3;
		object-fit: cover;
		border-radius: 8px;
		margin-bottom: 8px;
	}
	.shots button {
		width: 100%;
		justify-content: center;
		font-size: 12px;
	}
	.result {
		display: block;
		max-height: 420px;
		max-width: 100%;
		margin: 16px auto;
		object-fit: contain;
	}
	.restart {
		margin-top: 12px;
	}
</style>
