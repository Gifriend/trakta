<script lang="ts">
	import { onMount, untrack } from 'svelte';
	import { getPreferences } from '#lib/preferences.ts';
	import type { CompressedPhoto } from '#lib/types/attendance.ts';
	import { friendlyError } from '#lib/firebase/auth.ts';
	import {
		decodePhoto,
		renderEditedPhoto,
		saveEditedPhoto,
		type PhotoEdits
	} from '#lib/utils/photo-editor.ts';
	import Icon from './Icon.svelte';
	import PhotoFrameSelect from './PhotoFrameSelect.svelte';

	let {
		original,
		initialEdits,
		onapply,
		onclose
	}: {
		original: CompressedPhoto;
		initialEdits: PhotoEdits;
		onapply: (photo: CompressedPhoto, edits: PhotoEdits) => void;
		onclose: () => void;
	} = $props();
	const { t } = getPreferences();
	const id = $props.id();
	let dialog: HTMLDialogElement;
	let preview = $state<HTMLCanvasElement>();
	let source = $state<HTMLImageElement>();
	let edits = $state.raw(untrack(() => initialEdits));
	let showOriginal = $state(false);
	let saving = $state(false);
	let error = $state('');
	let selectedSticker = $state('');
	let customSticker = $state('');
	const sticker = $derived(edits.stickers?.find((item) => item.id === selectedSticker));
	const stickerChoices = [
		'❤️',
		'💕',
		'✨',
		'⭐',
		'🌈',
		'🌸',
		'🌻',
		'🍓',
		'🍒',
		'🎀',
		'🦋',
		'🐱',
		'🐻',
		'🐰',
		'🐼',
		'😎',
		'🥰',
		'😂',
		'🥳',
		'👑',
		'💫',
		'☁️',
		'🌙',
		'🎉'
	];

	function addSticker(text: string) {
		if (!text.trim() || (edits.stickers?.length ?? 0) >= 20) return;
		const item = {
			id: crypto.randomUUID(),
			text: text.trim(),
			x: 50,
			y: 50,
			size: 15,
			rotation: 0
		};
		updateEdits({ stickers: [...(edits.stickers ?? []), item] });
		selectedSticker = item.id;
		customSticker = '';
	}

	function changeSticker(changes: Partial<NonNullable<PhotoEdits['stickers']>[number]>) {
		updateEdits({
			stickers: edits.stickers?.map((item) =>
				item.id === selectedSticker ? { ...item, ...changes } : item
			)
		});
	}

	function placeSticker(event: PointerEvent) {
		if (!preview || !sticker || saving) return;
		const bounds = preview.getBoundingClientRect();
		const scale = Math.min(bounds.width / preview.width, bounds.height / preview.height);
		const width = preview.width * scale;
		const height = preview.height * scale;
		changeSticker({
			x: Math.max(
				5,
				Math.min(95, ((event.clientX - bounds.left - (bounds.width - width) / 2) / width) * 100)
			),
			y: Math.max(
				5,
				Math.min(95, ((event.clientY - bounds.top - (bounds.height - height) / 2) / height) * 100)
			)
		});
	}

	function updateEdits(changes: Partial<PhotoEdits>) {
		edits = { ...edits, ...changes };
		showOriginal = false;
		error = '';
	}

	onMount(() => {
		dialog.showModal();
		void decodePhoto(original.dataUrl).then(
			(image) => (source = image),
			(cause) => (error = friendlyError(cause))
		);
	});

	$effect(() => {
		if (!source || !preview) return;
		try {
			renderEditedPhoto(preview, source, edits, 600);
		} catch (cause) {
			error = friendlyError(cause);
		}
	});

	async function apply() {
		if (!source || saving) return;
		saving = true;
		error = '';
		try {
			let result = original;
			if (
				edits.frame !== 'none' ||
				edits.turns ||
				edits.square ||
				edits.stickers?.length ||
				edits.caption?.trim()
			) {
				result = await saveEditedPhoto(source, edits);
			}
			onapply(result, edits);
			dialog.close();
		} catch (cause) {
			error = friendlyError(cause);
		} finally {
			saving = false;
		}
	}
</script>

<dialog
	bind:this={dialog}
	class="photo-editor"
	aria-labelledby={`${id}-title`}
	{onclose}
	oncancel={(event) => {
		if (saving) event.preventDefault();
	}}
>
	<div class="editor-heading">
		<h2 id={`${id}-title`}>{t('Edit foto')}</h2>
		<button
			type="button"
			class="icon-button"
			aria-label={t('Batal')}
			disabled={saving}
			onclick={() => dialog.close()}><Icon name="close" /></button
		>
	</div>

	<div class="comparison">
		<button
			type="button"
			class="button secondary"
			aria-pressed={showOriginal}
			onclick={() => (showOriginal = true)}>{t('Sebelum')}</button
		>
		<button
			type="button"
			class="button secondary"
			aria-pressed={!showOriginal}
			onclick={() => (showOriginal = false)}>{t('Sesudah')}</button
		>
	</div>
	<div class="editor-preview" aria-busy={!source && !error}>
		{#if showOriginal}<img src={original.dataUrl} alt={t('Foto asli')} />{/if}
		<div
			class="edited-photo"
			hidden={showOriginal || !source}
			role="img"
			aria-label={t('Pratinjau hasil edit')}
		>
			<canvas bind:this={preview} aria-hidden="true"></canvas>
		</div>
		{#if sticker && !showOriginal}
			<button
				type="button"
				class="sticker-position"
				aria-label={t('Geser stiker pada foto atau gunakan tombol panah')}
				disabled={saving}
				onpointerdown={(event) => {
					event.currentTarget.setPointerCapture(event.pointerId);
					placeSticker(event);
				}}
				onpointermove={(event) => {
					if (event.buttons) placeSticker(event);
				}}
				onkeydown={(event) => {
					const offsets: Record<string, [number, number]> = {
						ArrowLeft: [-1, 0],
						ArrowRight: [1, 0],
						ArrowUp: [0, -1],
						ArrowDown: [0, 1]
					};
					const offset = offsets[event.key];
					if (offset && sticker) {
						event.preventDefault();
						changeSticker({
							x: Math.max(5, Math.min(95, sticker.x + offset[0])),
							y: Math.max(5, Math.min(95, sticker.y + offset[1]))
						});
					}
				}}
			></button>
		{/if}
	</div>

	<fieldset class="editor-controls" disabled={!source || saving}>
		<PhotoFrameSelect frame={edits.frame} onchange={(frame) => updateEdits({ frame })} />
		<div class="transforms">
			<button
				type="button"
				class="button secondary"
				onclick={() => updateEdits({ turns: (edits.turns + 1) % 4 })}>{t('Putar 90°')}</button
			>
			<label>
				<input
					type="checkbox"
					checked={edits.square}
					onchange={(event) => updateEdits({ square: event.currentTarget.checked })}
				/>
				{t('Potong persegi')}
			</label>
		</div>
	</fieldset>
	<fieldset class="decorations" disabled={!source || saving}>
		<legend>{t('Stiker dan emoji')}</legend>
		<div class="sticker-palette">
			{#each stickerChoices as emoji (emoji)}
				<button
					type="button"
					class="button secondary"
					aria-label={t('Tambah stiker {emoji}', { emoji })}
					disabled={(edits.stickers?.length ?? 0) >= 20}
					onclick={() => addSticker(emoji)}>{emoji}</button
				>
			{/each}
		</div>
		<label for={`${id}-custom`}>{t('Emoji atau simbol sendiri')}</label>
		<div class="custom-sticker">
			<input id={`${id}-custom`} maxlength="12" bind:value={customSticker} placeholder="☀️ ♡ ✿" />
			<button
				type="button"
				class="button secondary"
				disabled={!customSticker.trim() || (edits.stickers?.length ?? 0) >= 20}
				onclick={() => addSticker(customSticker)}>{t('Tambah')}</button
			>
		</div>
		{#if edits.stickers?.length}
			<label for={`${id}-sticker`}>{t('Stiker yang diedit')}</label>
			<select id={`${id}-sticker`} bind:value={selectedSticker}>
				<option value="">{t('Pilih stiker')}</option>
				{#each edits.stickers as item, index (item.id)}<option value={item.id}
						>{index + 1} · {item.text}</option
					>{/each}
			</select>
		{/if}
		{#if sticker}
			<div class="sticker-sliders">
				{#each [['x', 'Posisi horizontal', 5, 95], ['y', 'Posisi vertikal', 5, 95], ['size', 'Ukuran stiker', 5, 35], ['rotation', 'Rotasi stiker', -180, 180]] as [key, label, min, max] (key)}
					<label
						>{t(String(label))}<input
							type="range"
							min={Number(min)}
							max={Number(max)}
							value={sticker[key as 'x' | 'y' | 'size' | 'rotation']}
							oninput={(event) =>
								changeSticker({ [String(key)]: Number(event.currentTarget.value) })}
						/></label
					>
				{/each}
			</div>
			<button
				type="button"
				class="button secondary"
				onclick={() => {
					updateEdits({ stickers: edits.stickers?.filter((item) => item.id !== selectedSticker) });
					selectedSticker = '';
				}}>{t('Hapus stiker')}</button
			>
		{/if}
		<label for={`${id}-caption`}>{t('Teks pada foto')}</label>
		<input
			id={`${id}-caption`}
			maxlength="60"
			value={edits.caption ?? ''}
			oninput={(event) => updateEdits({ caption: event.currentTarget.value })}
		/>
	</fieldset>

	{#if error}<p class="notice error" role="alert">{t(error)}</p>{/if}
	<button
		type="button"
		class="button primary apply-photo"
		disabled={!source || saving}
		aria-busy={saving}
		onclick={apply}>{t(saving ? 'Menyiapkan foto…' : 'Gunakan foto')}</button
	>
</dialog>

<style>
	.sticker-position {
		position: absolute;
		inset: 0;
		width: 100%;
		height: 100%;
		padding: 0;
		border: 0;
		background: transparent;
		cursor: move;
		touch-action: none;
	}
	.decorations {
		border: 0;
		padding: 0;
		margin: 16px 0;
		min-width: 0;
	}
	.decorations legend {
		font-weight: 600;
		margin-bottom: 10px;
	}
	.decorations label {
		margin-top: 12px;
		font-size: 13px;
	}
	.decorations select {
		width: 100%;
		padding: 10px;
		background: var(--surface);
		color: var(--ink);
		border: 1px solid var(--control-border);
		border-radius: var(--control-radius);
	}
	.sticker-palette {
		display: grid;
		grid-template-columns: repeat(6, minmax(0, 1fr));
		gap: 6px;
	}
	.sticker-palette button {
		padding: 4px;
		min-height: 44px;
		font-size: 22px;
		justify-content: center;
	}
	.custom-sticker {
		display: flex;
		gap: 8px;
	}
	.custom-sticker input {
		min-width: 0;
	}
	.sticker-sliders {
		display: grid;
		grid-template-columns: repeat(2, minmax(0, 1fr));
		gap: 12px;
	}
	.sticker-sliders input {
		padding: 0;
		min-height: 44px;
		accent-color: var(--primary);
	}
	.photo-editor {
		position: fixed;
		inset: 0;
		margin: auto;
		width: min(calc(100% - 24px), 31rem);
		max-height: calc(100dvh - 24px - env(safe-area-inset-top) - env(safe-area-inset-bottom));
		overflow-y: auto;
		overscroll-behavior: contain;
		padding: clamp(14px, 4vw, 24px);
		border: 1px solid var(--border);
		border-radius: calc(var(--control-radius) * 1.6);
		background: var(--surface);
		color: var(--ink);
	}
	.photo-editor::backdrop {
		background: #0c151bb0;
	}
	.editor-heading,
	.transforms {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 12px;
	}
	.editor-heading h2 {
		font-size: 21px;
	}
	.comparison {
		display: grid;
		grid-template-columns: repeat(2, minmax(0, 1fr));
		gap: 6px;
		margin-block: 8px;
	}
	.comparison button {
		justify-content: center;
	}
	.comparison button[aria-pressed='true'] {
		border-color: var(--primary);
		background: var(--primary-soft);
		color: var(--primary);
	}
	.editor-preview {
		position: relative;
		display: grid;
		place-items: center;
		height: clamp(130px, 39dvh, 320px);
		overflow: hidden;
		border-radius: var(--control-radius);
		background: #131718;
	}
	.editor-preview :is(.edited-photo, canvas, img) {
		width: 100%;
		height: 100%;
		min-width: 0;
		min-height: 0;
		object-fit: contain;
	}
	.editor-controls {
		min-width: 0;
		margin: 12px 0;
		padding: 0;
		border: 0;
	}
	.editor-controls :global(.preference-control) {
		display: grid;
		grid-template-columns: minmax(0, 1fr) minmax(0, 1.35fr);
		gap: 12px;
	}
	.editor-controls :global(select) {
		width: 100%;
		font-size: 16px;
	}
	.transforms {
		flex-wrap: wrap;
		margin-top: 8px;
	}
	.transforms label {
		display: inline-flex;
		align-items: center;
		gap: 8px;
		min-height: 44px;
		margin: 0;
		font-size: 14px;
	}
	.transforms input {
		flex: none;
		width: 16px;
		height: 16px;
		margin: 0;
		padding: 0;
		accent-color: var(--primary);
	}
	.apply-photo {
		width: 100%;
		justify-content: center;
	}
</style>
