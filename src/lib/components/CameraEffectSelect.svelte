<script lang="ts">
	import { getPreferences } from '#lib/preferences.ts';
	import { CAMERA_EFFECTS, isCameraEffect } from '#lib/utils/camera.ts';

	let { disabled = false }: { disabled?: boolean } = $props();
	const id = $props.id();
	const preferences = getPreferences();
	const { t } = preferences;
</script>

<div class="preference-control">
	<label for={id}>{t('Efek kamera')}</label>
	<select
		{id}
		value={preferences.cameraEffect}
		{disabled}
		onchange={(event) => {
			const effect = event.currentTarget.value;
			if (isCameraEffect(effect)) preferences.setCameraEffect(effect);
		}}
	>
		{#each Object.entries(CAMERA_EFFECTS) as [value, setting] (value)}
			<option {value}>{t(setting.label)}</option>
		{/each}
	</select>
</div>
