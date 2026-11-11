<script lang="ts">
	import { getPreferences, isTheme, THEMES, type DisplayMode } from '#lib/preferences.ts';
	import type { Locale } from '#lib/i18n.ts';

	const preferences = getPreferences();
	const { t } = preferences;
</script>

<div class="preferences">
	<div class="preference-control">
		<label for="trakta-theme">{t('Tema')}</label>
		<select
			id="trakta-theme"
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
		<label for="trakta-mode">{t('Tampilan')}</label>
		<select
			id="trakta-mode"
			value={preferences.mode}
			onchange={(event) => preferences.setMode(event.currentTarget.value as DisplayMode)}
		>
			<option value="light">{t('Cerah')}</option>
			<option value="dark">{t('Gelap')}</option>
		</select>
	</div>
	<div class="preference-control">
		<label for="trakta-language">{t('Bahasa')}</label>
		<select
			id="trakta-language"
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
	.preference-control {
		display: flex;
		align-items: center;
		gap: 8px;
	}
	label {
		margin: 0;
		font-size: 12px;
	}
	select {
		max-width: 100%;
		min-height: 44px;
		padding: 6px 8px;
		border: 1px solid var(--control-border);
		border-radius: var(--control-radius);
		background: var(--surface);
		color: var(--ink);
		font-size: 13px;
	}
	select:focus-visible {
		outline: 3px solid var(--ring);
		outline-offset: 3px;
	}
</style>
