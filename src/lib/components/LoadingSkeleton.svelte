<script lang="ts">
	let {
		label,
		variant = 'form'
	}: { label: string; variant?: 'page' | 'form' | 'history' | 'photo' } = $props();
</script>

<div class={['skeleton-layout', variant]} role="status" aria-label={label} aria-busy="true">
	<div aria-hidden="true" class="shapes">
		{#if variant === 'page'}
			<div class="skeleton heading"></div>
			<div class="skeleton short"></div>
			<div class="tiles">
				{#each ['masuk', 'pulang', 'bulan'] as item (item)}
					<div class="card tile">
						<div class="skeleton short"></div>
						<div class="skeleton heading"></div>
					</div>
				{/each}
			</div>
			<div class="card tile">
				<div class="skeleton heading"></div>
				<div class="skeleton panel"></div>
			</div>
		{:else if variant === 'form'}
			<div class="skeleton heading"></div>
			<div class="skeleton short"></div>
			<div class="tiles">
				{#each ['kantor', 'rumah', 'luar'] as item (item)}
					<div class="skeleton field"></div>
				{/each}
			</div>
			<div class="skeleton panel"></div>
			<div class="skeleton field"></div>
		{:else if variant === 'history'}
			<div class="skeleton field"></div>
			<div class="skeleton field"></div>
			<div class="skeleton field"></div>
		{:else}
			<div class="skeleton panel"></div>
		{/if}
	</div>
</div>

<style>
	.skeleton-layout {
		width: 100%;
	}
	.page {
		max-width: 1080px;
		margin: 0 auto;
		padding: clamp(20px, 5vw, 64px);
	}
	.form,
	.history {
		padding: 24px;
	}
	.shapes,
	.tile {
		display: grid;
		gap: 14px;
	}
	.tiles {
		display: grid;
		grid-template-columns: repeat(3, minmax(0, 1fr));
		gap: 8px;
	}
	.tile {
		padding: 16px;
	}
	.heading {
		width: 48%;
		height: 24px;
	}
	.short {
		width: 66%;
		height: 12px;
	}
	.field {
		height: 44px;
	}
	.panel {
		min-height: var(--skeleton-panel-height, 180px);
	}
</style>
