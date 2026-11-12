<script lang="ts">
	import { getPreferences } from '#lib/preferences.ts';
	import { isPhotoFrame, PHOTO_FRAMES, type PhotoEdits } from '#lib/utils/photo-editor.ts';

	let {
		frame,
		onchange,
		disabled = false
	}: {
		frame: PhotoEdits['frame'];
		onchange: (value: PhotoEdits['frame']) => void;
		disabled?: boolean;
	} = $props();
	const { t } = getPreferences();
	const id = $props.id();
</script>

<div class="preference-control">
	<label for={id}>{t('Bingkai fotobox')}</label>
	<select
		{id}
		value={frame}
		{disabled}
		onchange={(event) => {
			const value = event.currentTarget.value;
			if (isPhotoFrame(value)) onchange(value);
		}}
	>
		{#each Object.entries(PHOTO_FRAMES) as [value, label] (value)}
			<option {value}>{t(label)}</option>
		{/each}
	</select>
</div>
