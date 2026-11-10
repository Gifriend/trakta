<script lang="ts">
	import { onMount } from 'svelte';
	import { onIdTokenChanged, type User } from 'firebase/auth';
	import { firebaseConfigured, getFirebase } from '#lib/firebase/client.ts';
	import { friendlyError } from '#lib/firebase/auth.ts';
	import AuthPanel from '#lib/components/AuthPanel.svelte';
	let user = $state.raw<Pick<User, 'uid' | 'displayName' | 'email'> | null>(null);
	let loading = $state(firebaseConfigured);
	let error = $state('');
	onMount(() => {
		if (!firebaseConfigured) return;
		try {
			return onIdTokenChanged(
				getFirebase().auth,
				(value) => {
					user = value
						? { uid: value.uid, displayName: value.displayName, email: value.email }
						: null;
					loading = false;
				},
				(cause) => {
					error = friendlyError(cause);
					loading = false;
				}
			);
		} catch (cause) {
			error = friendlyError(cause);
			loading = false;
		}
	});
</script>

<svelte:head
	><title>Trakta</title><meta
		name="description"
		content="Catat presensi masuk dan pulang, lengkapi dengan foto, dan simpan jejak kehadiran harianmu dengan Trakta."
	/></svelte:head
>
{#if loading}<main id="main" class="boot-screen" role="status">
		<span class="spinner"></span>
		<p>Menyiapkan harimu…</p>
	</main>{:else if error}<main id="main" class="boot-screen">
		<h1>Belum dapat terhubung</h1>
		<p class="notice error" role="alert">{error}</p>
		<button type="button" class="button primary" onclick={() => window.location.reload()}
			>Coba lagi</button
		>
	</main>{:else if user}{#await import('#lib/components/Dashboard.svelte')}<main
			id="main"
			class="boot-screen"
			role="status"
		>
			<span class="spinner"></span>
			<p>Membuka ruang kerjamu…</p>
		</main>{:then { default: Dashboard }}{#key user.uid}<Dashboard {user} />{/key}{:catch}<main
			id="main"
			class="boot-screen"
		>
			<p>Ruang kerja gagal dimuat. Periksa koneksi internet.</p>
			<button type="button" class="button primary" onclick={() => window.location.reload()}
				>Coba lagi</button
			>
		</main>{/await}{:else}<AuthPanel />{/if}

<style>
	.boot-screen {
		min-height: 100svh;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		padding: 24px;
		gap: 20px;
		color: var(--muted);
		font-size: 14px;
	}
	.boot-screen h1 {
		font-size: 22px;
		color: var(--ink);
	}
</style>
