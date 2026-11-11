<script lang="ts">
	import { getPreferences, type Theme } from '#lib/preferences.ts';

	const preferences = getPreferences();
</script>

<div class="preferences">
	<label>
		<span>Tema</span>
		<select
			value={preferences.theme}
			onchange={(event) => preferences.setTheme(event.currentTarget.value as Theme)}
		>
			<option value="classic">Trakta</option>
			<option value="neo">Neobrutalism</option>
		</select>
	</label>
</div>

<style>
	.preferences {
		display: flex;
		align-items: center;
		flex-wrap: wrap;
		gap: 10px;
	}
	label {
		display: flex;
		align-items: center;
		gap: 8px;
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
