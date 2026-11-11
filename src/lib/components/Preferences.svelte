<script lang="ts">
	import { getPreferences, isTheme, THEMES, type DisplayMode } from '#lib/preferences.ts';
	import type { Locale } from '#lib/i18n.ts';

	let { stacked = false }: { stacked?: boolean } = $props();
	const id = $props.id();
	const preferences = getPreferences();
	const { t } = preferences;
</script>

<div class={['preferences', { stacked }]}>
	<div class="preference-control">
		<label for={`${id}-theme`}>{t('Tema')}</label>
		<select
			id={`${id}-theme`}
			value={preferences.theme}
			onchange={(event) => {
				const theme = event.currentTarget.value;
				if (isTheme(theme)) preferences.setTheme(theme);
			}}
		>
			{#each Object.entries(THEMES) as [value, theme] (value)}
				<option {value}>{theme.label}</option>
			{/each}
		</select>
	</div>
	<div class="preference-control">
		<label for={`${id}-mode`}>{t('Tampilan')}</label>
		<select
			id={`${id}-mode`}
			value={preferences.mode}
			onchange={(event) => preferences.setMode(event.currentTarget.value as DisplayMode)}
		>
			<option value="light">{t('Cerah')}</option>
			<option value="dark">{t('Gelap')}</option>
		</select>
	</div>
	<div class="preference-control">
		<label for={`${id}-language`}>{t('Bahasa')}</label>
		<select
			id={`${id}-language`}
			value={preferences.locale}
			onchange={(event) => preferences.setLocale(event.currentTarget.value as Locale)}
		>
			<option value="id" lang="id">Indonesia</option>
			<option value="en" lang="en">English</option>
		</select>
	</div>
</div>

<style>
	.preferences {
		display: flex;
		align-items: center;
		flex-wrap: wrap;
		gap: 10px;
	}
	.preferences.stacked {
		display: grid;
		gap: 10px;
	}
</style>
