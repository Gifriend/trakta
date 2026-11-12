<script lang="ts">
	let { light = false }: { light?: boolean } = $props();
</script>

<span class={['brand', { light }]}
	><img class="brand-mark" src="/icon.svg" alt="" width="36" height="36" />Trakta</span
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
		flex: none;
		width: 36px;
		height: 36px;
		margin-right: 9px;
	}
	.light {
		color: white;
	}
</style>
