<script lang="ts">
	import { getPreferences } from '#lib/preferences.ts';
	import { onMount, tick } from 'svelte';
	import type { User } from 'firebase/auth';
	import type { AttendanceDay } from '#lib/types/attendance.ts';
	import { watchAttendance } from '#lib/firebase/attendance.ts';
	import { logout, friendlyError } from '#lib/firebase/auth.ts';
	import { dateKey, formatDate, formatTime, durationLabel } from '#lib/utils/date.ts';
	import Brand from './Brand.svelte';
	import Icon from './Icon.svelte';
	import AttendanceForm from './AttendanceForm.svelte';
	import AttendanceHistory from './AttendanceHistory.svelte';
	import PwaInstall from './PwaInstall.svelte';
	import LoadingSkeleton from './LoadingSkeleton.svelte';
	import Preferences from './Preferences.svelte';
	import MobileSettings from './MobileSettings.svelte';

	const preferences = getPreferences();
	const { t } = preferences;
	let { user }: { user: Pick<User, 'uid' | 'displayName' | 'email'> } = $props();
	let days = $state.raw<AttendanceDay[]>([]);
	let loading = $state(true);
	let online = $state(true);
	let now = $state(new Date());
	let error = $state('');
	let loadError = $state('');
	let permissionDenied = $state(false);
	let message = $state('');
	let signingOut = $state(false);
	const today = $derived(days.find((day) => day.dateKey === dateKey(now)));
	const firstName = $derived(
		(user.displayName || user.email?.split('@')[0] || t('Teman')).split(' ')[0]
	);
	const initials = $derived((user.displayName || user.email || 'T').slice(0, 2).toUpperCase());
	const monthDays = $derived(
		days.filter((day) => day.dateKey.startsWith(dateKey(now).slice(0, 6)))
	);
	const nextKind = $derived(today?.checkIn ? 'checkOut' : 'checkIn');
	const formKey = $derived(`${dateKey(now)}-${nextKind}`);
	let activeForm = $state('');
	let stopWatching: (() => void) | undefined;
	function subscribe() {
		stopWatching?.();
		loading = true;
		loadError = '';
		permissionDenied = false;
		stopWatching = watchAttendance(
			user.uid,
			(result) => {
				days = result;
				loading = false;
			},
			(cause) => {
				days = [];
				permissionDenied = cause.code === 'permission-denied';
				loadError = permissionDenied
					? 'Akses data presensi belum diizinkan. Hubungi pengelola aplikasi untuk memperbarui izin akses, lalu muat ulang data.'
					: friendlyError(cause);
				loading = false;
			}
		);
	}
	onMount(() => {
		online = navigator.onLine;
		subscribe();
		const timer = window.setInterval(() => {
			now = new Date();
		}, 1000);
		return () => {
			clearInterval(timer);
			stopWatching?.();
		};
	});
	async function signOut() {
		signingOut = true;
		try {
			await logout();
		} catch (cause) {
			error = friendlyError(cause);
			signingOut = false;
		}
	}
	function submitted() {
		message = 'Presensi berhasil diterima server.';
	}
	async function startAttendance() {
		activeForm = formKey;
		await tick();
		const heading = document.getElementById('attendance-title');
		heading?.focus({ preventScroll: true });
		heading?.scrollIntoView({ block: 'start' });
	}
</script>

<svelte:window
	ononline={() => {
		online = true;
	}}
	onoffline={() => {
		online = false;
	}}
/>
<div class="app-shell">
	<aside class="sidebar">
		<a class="brand-link" href="#ringkasan" aria-label={t('Trakta — ringkasan')}><Brand /></a>
		<div class="workspace-label">{t('RUANG PRIBADI')}</div>
		<nav aria-label={t('Navigasi utama')}>
			<a href="#ringkasan" class="nav-link active"
				><Icon name="grid" size={18} /> {t('Ringkasan')} <span class="nav-dot"></span></a
			><a href="#riwayat" class="nav-link"
				><Icon name="calendar" size={19} /> {t('Riwayat presensi')}</a
			>
		</nav>
		<div class="sidebar-bottom">
			<PwaInstall />
			<div class="sidebar-user">
				<span class="avatar">{initials}</span>
				<div>
					<strong>{user.displayName || firstName}</strong><small>{t('Akun pribadi')}</small>
				</div>
				<button
					type="button"
					class="icon-button"
					aria-label={t('Keluar dari akun')}
					title={t('Keluar')}
					onclick={signOut}
					disabled={signingOut}><Icon name="exit" size={18} /></button
				>
			</div>
		</div>
	</aside>
	<div class="main-shell">
		<header class="topbar mobile-header">
			<div class="desktop-breadcrumb">
				{t('Ruang kerja')} <span>/</span> <strong>{t('Ringkasan')}</strong>
			</div>
			<div class="mobile-logo"><Brand /></div>
			<div class="dashboard-preferences"><Preferences /></div>
			<div class="topbar-right">
				<span class={['connection', { offline: !online }]}>
					<span></span>{online ? t('Terhubung') : t('Offline')}
				</span>
				<span class="topbar-divider"></span>
				<span class="avatar small">{initials}</span>
				<MobileSettings camera>
					{#snippet children(close)}
						<nav aria-label={t('Navigasi utama')}>
							<button
								type="button"
								class="nav-link settings-logout"
								disabled={signingOut}
								onclick={() => {
									close();
									void signOut();
								}}><Icon name="exit" size={18} />{t('Keluar dari akun')}</button
							>
						</nav>
					{/snippet}
				</MobileSettings>
			</div>
		</header>
		<nav class="mobile-navigation" aria-label={t('Navigasi utama')}>
			<a href="#ringkasan"><Icon name="grid" size={20} />{t('Hari ini')}</a>
			{#if !loadError}
				<a href="#riwayat"><Icon name="calendar" size={20} />{t('Riwayat')}</a>
			{/if}
		</nav>
		<main id="main">
			<div id="ringkasan" class="page-heading">
				<div>
					<h1>{t('Halo, {name}', { name: firstName })}<span class="greeting-dot">.</span></h1>
				</div>
			</div>
			{#if message}<div class="notice success status-message" role="status">
					<Icon name="check" size={18} />{t(message)}<button
						type="button"
						class="icon-button"
						aria-label={t('Tutup pemberitahuan')}
						onclick={() => (message = '')}><Icon name="close" size={16} /></button
					>
				</div>{/if}
			{#if error}<div class="notice error status-message" role="alert">
					{t(error)}<button type="button" class="text-button" onclick={subscribe}
						>{t('Coba lagi')}</button
					>
				</div>{/if}
			{#if !online}<div class="notice offline-notice" role="status">
					<Icon name="wifi" size={17} />
					{t('Kamu sedang offline. Presensi baru memerlukan internet.')}
				</div>{/if}
			{#if loading}
				<section class="card daily-panel">
					<LoadingSkeleton label={t('Menyiapkan ruang presensimu…')} />
				</section>
			{:else if loadError}
				<section class="card loading-card" role="alert">
					<Icon name="info" size={28} />
					<h2>
						{t(permissionDenied ? 'Akses presensi belum diizinkan' : 'Data belum dapat dimuat')}
					</h2>
					<p>{t(loadError)}</p>
					<button type="button" class="button secondary" onclick={subscribe}
						>{t('Muat ulang data')}</button
					>
				</section>
			{:else}
				<section class="card daily-panel" aria-labelledby="daily-title">
					<div class="daily-heading">
						<div>
							<h2 id="daily-title">{t('Hari ini')}</h2>
							<p>{formatDate(now, {}, preferences.locale)}</p>
						</div>
						<span class={['daily-status', { recorded: today?.checkIn }]}>
							{t(
								today?.checkOut
									? 'Presensi selesai'
									: today?.checkIn
										? 'Sudah masuk'
										: 'Belum ada presensi masuk'
							)}
						</span>
					</div>
					<dl class="daily-times">
						<div>
							<dt>{t('Jam masuk')}</dt>
							<dd>
								{formatTime(
									today?.checkIn.timestamp?.toDate(),
									preferences.locale
								)}{#if today?.checkIn.timestamp}<span>WIB</span>{/if}
							</dd>
						</div>
						<div>
							<dt>{t('Jam pulang')}</dt>
							<dd>
								{formatTime(
									today?.checkOut?.timestamp?.toDate(),
									preferences.locale
								)}{#if today?.checkOut?.timestamp}<span>WIB</span>{/if}
							</dd>
						</div>
					</dl>
					{#if today?.checkOut}
						<div class="daily-complete">
							<Icon name="check" size={20} />
							<div>
								<h3>{t('Hari ini, tuntas.')}</h3>
								<p>
									{t('Durasi')}
									{durationLabel(
										today.checkIn.timestamp?.toDate(),
										today.checkOut.timestamp?.toDate(),
										preferences.locale
									)}
								</p>
							</div>
						</div>
					{:else}
						<button
							type="button"
							class="button primary daily-action"
							onclick={startAttendance}
							disabled={!online}
							aria-expanded={activeForm === formKey}
							aria-controls={activeForm === formKey ? 'attendance-form' : undefined}
						>
							<Icon name={nextKind === 'checkIn' ? 'enter' : 'exit'} size={20} />
							{t(nextKind === 'checkIn' ? 'Presensi masuk' : 'Presensi pulang')}
							<Icon name="arrow" size={18} />
						</button>
					{/if}
				</section>
				{#if !today?.checkOut && activeForm === formKey}
					{#key formKey}
						<AttendanceForm uid={user.uid} kind={nextKind} {online} onsuccess={submitted} />
					{/key}
				{/if}
				<section class="card monthly-summary" aria-label={t('Kehadiran bulan ini')}>
					<div>
						<h2>{t('Kehadiran bulan ini')}</h2>
						<p>
							{formatDate(
								now,
								{ weekday: undefined, day: undefined, month: 'long' },
								preferences.locale
							)}
						</p>
					</div>
					<strong
						>{monthDays.length}
						<span>{preferences.locale === 'en' && monthDays.length === 1 ? 'day' : t('hari')}</span
						></strong
					>
				</section>
			{/if}
			{#if !loadError}<AttendanceHistory {days} uid={user.uid} {loading} />{/if}
			<div class="mobile-install"><PwaInstall /></div>
			<footer class="page-footer">
				<span>Trakta <span class="muted">{t('Teman setiap hari kerja.')}</span></span><span
					>{t('Zona waktu Asia/Jakarta · WIB')}</span
				>
			</footer>
		</main>
	</div>
</div>

<style>
	.app-shell {
		--shell-gutter: clamp(16px, 5vw, 25px);
		display: flex;
		min-height: 100svh;
	}
	.sidebar {
		width: var(--sidebar-width);
		background: var(--surface);
		border-right: 1px solid var(--border);
		padding: 31px var(--sidebar-gutter) 0;
		position: fixed;
		inset: 0 auto 0 0;
		display: none;
		flex-direction: column;
		z-index: 20;
		overflow-y: auto;
	}
	.brand-link {
		display: inline-block;
		padding: 0 10px;
		text-decoration: none;
	}
	.workspace-label {
		margin: 46px 12px 15px;
		font-size: 9px;
		font-weight: 650;
		letter-spacing: 1.4px;
		color: var(--muted);
	}
	nav {
		display: grid;
		gap: 6px;
	}
	.nav-link {
		display: flex;
		align-items: center;
		gap: 12px;
		min-height: 47px;
		padding: 10px 13px;
		color: var(--muted);
		font-size: 12px;
		text-decoration: none;
		border-radius: 8px;
	}
	.nav-link.active {
		background: var(--primary-soft);
		color: var(--primary);
		font-weight: 600;
	}
	.nav-link:hover {
		background: var(--subtle);
	}
	.settings-logout {
		border: 0;
		background: transparent;
		text-align: start;
	}
	.nav-dot {
		margin-left: auto;
		width: 5px;
		height: 5px;
		border-radius: 50%;
		background: var(--primary);
	}
	.sidebar-bottom {
		margin-top: auto;
		padding-top: 70px;
	}
	.sidebar-user {
		display: flex;
		align-items: center;
		gap: 10px;
		border-top: 1px solid var(--border);
		margin: 25px calc(-1 * var(--sidebar-gutter)) 0;
		padding: 21px 16px;
	}
	.sidebar-user > div {
		flex: 1;
		min-width: 0;
	}
	.sidebar-user strong {
		display: block;
		font-size: 11px;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}
	.sidebar-user small {
		display: block;
		color: var(--muted);
		font-size: 10px;
		margin-top: 4px;
	}
	.avatar {
		width: 37px;
		height: 37px;
		border-radius: 50%;
		display: inline-flex;
		align-items: center;
		justify-content: center;
		font-size: 11px;
		font-weight: 650;
		color: var(--primary);
		background: var(--avatar-surface);
		flex-shrink: 0;
	}
	.avatar.small {
		width: 31px;
		height: 31px;
		font-size: 10px;
	}
	.main-shell {
		width: 100%;
		min-width: 0;
	}
	.topbar {
		border-bottom: 1px solid var(--border);
		padding: calc(8px + env(safe-area-inset-top))
			max(var(--shell-gutter), env(safe-area-inset-right)) 8px
			max(var(--shell-gutter), env(safe-area-inset-left));
		display: flex;
		justify-content: space-between;
		align-items: center;
		gap: 12px;
	}
	.desktop-breadcrumb {
		display: none;
		font-size: 11px;
		color: var(--muted);
	}
	.desktop-breadcrumb span {
		margin: 0 13px;
		color: #9ca7a0;
	}
	.desktop-breadcrumb strong {
		color: var(--ink);
		font-weight: 550;
	}
	.topbar-right {
		display: flex;
		gap: 12px;
		align-items: center;
	}
	.connection {
		font-size: 10px;
		color: var(--muted);
		display: flex;
		align-items: center;
		gap: 7px;
	}
	.connection > span {
		width: 6px;
		height: 6px;
		background: var(--primary);
		border-radius: 50%;
	}
	.connection.offline > span {
		background: var(--warning);
	}
	.topbar-divider {
		display: none;
		width: 1px;
		height: 23px;
		background: var(--border);
	}
	.topbar-right .avatar,
	.dashboard-preferences {
		display: none;
	}
	.mobile-logo :global(.brand) {
		font-size: 26px;
	}
	main {
		padding: 25px max(var(--shell-gutter), env(safe-area-inset-right)) 0
			max(var(--shell-gutter), env(safe-area-inset-left));
		max-width: 1300px;
		margin: 0 auto;
	}
	.page-heading {
		margin-bottom: 16px;
	}
	h1 {
		font-size: clamp(23px, 5vw, 32px);
		font-weight: 700;
		letter-spacing: -0.6px;
		margin: 0;
	}
	.greeting-dot {
		color: var(--primary);
	}
	.daily-panel,
	.monthly-summary {
		padding: clamp(16px, 4vw, 26px);
		margin-bottom: 16px;
	}
	.daily-heading {
		display: flex;
		flex-wrap: wrap;
		justify-content: space-between;
		align-items: start;
		gap: 10px 16px;
	}
	.daily-heading h2 {
		font-size: 23px;
	}
	.daily-heading p,
	.monthly-summary p,
	.daily-complete p {
		margin: 4px 0 0;
		color: var(--muted);
		font-size: 13px;
	}
	.daily-status {
		display: inline-flex;
		padding: 5px 9px;
		border-radius: var(--control-radius);
		background: var(--warning-soft);
		color: var(--warning);
		font-size: 12px;
		font-weight: 650;
	}
	.daily-status.recorded {
		background: var(--primary-soft);
		color: var(--primary);
	}
	.daily-times {
		display: grid;
		grid-template-columns: repeat(2, minmax(0, 1fr));
		gap: 12px;
		margin: 16px 0;
	}
	.daily-times > div {
		padding: 10px 12px;
		background: var(--subtle);
		border: 1px solid var(--border);
		border-radius: var(--control-radius);
	}
	.daily-times dt {
		font-size: 13px;
		color: var(--muted);
	}
	.daily-times dd {
		margin: 2px 0 0;
		font-size: clamp(20px, 5vw, 27px);
		font-weight: 700;
		font-variant-numeric: tabular-nums;
	}
	.daily-times dd span {
		font-size: 11px;
		color: var(--muted);
		margin-inline-start: 5px;
	}
	.daily-action {
		width: 100%;
		min-height: 48px;
		justify-content: start;
		font-size: 15px;
	}
	.daily-action :global(svg:last-child) {
		margin-inline-start: auto;
	}
	.daily-complete,
	.monthly-summary {
		display: flex;
		align-items: center;
		gap: 12px;
	}
	.daily-complete {
		color: var(--primary);
	}
	.daily-complete h3 {
		margin: 0;
		font-size: 16px;
	}
	.monthly-summary {
		justify-content: space-between;
		margin-top: 16px;
	}
	.monthly-summary h2 {
		font-size: 15px;
	}
	.monthly-summary strong {
		white-space: nowrap;
		font-size: 22px;
	}
	.monthly-summary strong span {
		color: var(--muted);
		font-size: 13px;
	}
	.mobile-install {
		margin-top: 18px;
	}
	.mobile-navigation {
		position: fixed;
		inset: auto 0 0;
		z-index: 25;
		display: flex;
		justify-content: center;
		gap: 10px;
		padding: 6px max(12px, env(safe-area-inset-right)) calc(6px + env(safe-area-inset-bottom))
			max(12px, env(safe-area-inset-left));
		background: var(--surface);
		border-top: 1px solid var(--border);
	}
	.mobile-navigation a {
		display: flex;
		flex: 1;
		max-width: 15rem;
		min-height: 48px;
		justify-content: center;
		align-items: center;
		gap: 8px;
		border-radius: var(--control-radius);
		background: var(--subtle);
		color: var(--ink);
		text-decoration: none;
		font-size: 14px;
		font-weight: 650;
	}
	.loading-card {
		min-height: 460px;
		padding: 40px;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		gap: 16px;
		text-align: center;
		color: var(--muted);
		font-size: 13px;
	}
	.loading-card h2 {
		color: var(--ink);
		font-size: 18px;
	}
	.status-message {
		display: flex;
		align-items: center;
		gap: 10px;
		margin-bottom: 20px;
		font-size: 12px;
	}
	.status-message .icon-button {
		margin-left: auto;
	}
	.offline-notice {
		display: flex;
		align-items: center;
		gap: 10px;
		margin-bottom: 20px;
		font-size: 12px;
	}
	.page-footer {
		display: flex;
		flex-direction: column;
		justify-content: space-between;
		gap: 8px;
		padding: 25px 0;
		color: var(--muted);
		font-size: 9px;
	}
	.page-footer > span:first-child {
		color: var(--ink);
		font-weight: 600;
	}
	.page-footer .muted {
		font-weight: 400;
		margin-left: 8px;
	}
	@media (min-width: 641px) {
		main {
			padding-top: 28px;
		}
		.daily-action {
			width: auto;
			min-width: 14rem;
		}
		.page-footer {
			flex-direction: row;
			gap: 15px;
		}
	}
	@media (max-width: 900px) {
		.main-shell {
			padding-bottom: calc(64px + env(safe-area-inset-bottom));
		}
	}
	@media (min-width: 901px) {
		.app-shell {
			--sidebar-width: 210px;
			--sidebar-gutter: 15px;
		}
		.sidebar {
			display: flex;
		}
		.main-shell {
			margin-inline-start: var(--sidebar-width);
			width: calc(100% - var(--sidebar-width));
		}
		.mobile-logo,
		.mobile-install,
		.mobile-navigation {
			display: none;
		}
		.desktop-breadcrumb,
		.dashboard-preferences,
		.topbar-divider {
			display: block;
		}
		.topbar-right .avatar {
			display: inline-flex;
		}
		.topbar {
			min-height: 77px;
			padding: 8px var(--shell-gutter);
		}
	}
	@media (min-width: 1151px) {
		.app-shell {
			--shell-gutter: 38px;
			--sidebar-width: 238px;
			--sidebar-gutter: 21px;
		}
		main {
			padding-top: 35px;
		}
	}
</style>
