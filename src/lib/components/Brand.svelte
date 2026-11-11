<script lang="ts">
	let { light = false }: { light?: boolean } = $props();
</script>

<span class={['brand', { light }]}
	><span class="brand-mark" aria-hidden="true"
		><svg width="24" height="24" viewBox="0 0 24 24" fill="none"
			><path
				d="M5 13l4 4L19 7"
				stroke="currentColor"
				stroke-width="3.5"
				stroke-linecap="round"
				stroke-linejoin="round"
			/></svg
		></span
	>Trakta</span
>

<style>
	.brand {
		display: inline-flex;
		align-items: center;
		font-size: 30px;
		font-weight: 750;
		letter-spacing: -1.5px;
		color: var(--ink);
	}
	.brand-mark {
		display: grid;
		place-items: center;
		width: 36px;
		height: 36px;
		margin-right: 9px;
		background: var(--primary);
		border-radius: 11px;
		color: var(--on-primary);
	}
	.light {
		color: white;
	}
	.light .brand-mark {
		background: var(--lime);
		color: var(--forest);
	}
</style>
