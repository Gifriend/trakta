<script lang="ts">
	import { loadPhoto } from '#lib/firebase/attendance.ts';
	import type { AttendanceKind } from '#lib/types/attendance.ts';
	import Icon from './Icon.svelte';

	let {
		uid,
		dateKey,
		kind,
		label,
		title,
		onopen
	}: {
		uid: string;
		dateKey: string;
		kind: AttendanceKind;
		label: string;
		title: string;
		onopen: (source: Promise<string>) => void;
	} = $props();
	let src = $state('');
	let request: Promise<string> | undefined;

	function getPhoto() {
		return (request ??= loadPhoto(uid, dateKey, kind).then(
			(source) => (src = source),
			(cause: unknown) => {
				request = undefined;
				throw cause;
			}
		));
	}

	function observe(node: HTMLButtonElement) {
		const observer = new IntersectionObserver(([entry]) => {
			if (!entry.isIntersecting) return;
			observer.disconnect();
			void getPhoto().catch(() => {
				// Keep the placeholder available so the user can retry from the dialog.
			});
		});
		observer.observe(node);
		return () => observer.disconnect();
	}
</script>

<button
	type="button"
	class="thumbnail"
	aria-label={label}
	{title}
	{@attach observe}
	onclick={() => onopen(getPhoto())}
>
	{#if src}
		<img {src} alt="" width="48" height="48" decoding="async" onerror={() => (src = '')} />
	{:else}
		<Icon name="image" size={17} />
	{/if}
</button>

<style>
	.thumbnail {
		display: grid;
		place-items: center;
		flex: 0 0 auto;
		width: 48px;
		height: 48px;
		padding: 0;
		overflow: hidden;
		border: 1px solid var(--control-border);
		border-radius: var(--control-radius);
		background: var(--subtle);
		color: var(--muted);
	}
	.thumbnail:hover {
		border-color: var(--primary);
	}
	img {
		display: block;
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
</style>
