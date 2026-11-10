<script lang="ts">
	import { onMount } from 'svelte';
	import type { User } from 'firebase/auth';
	import { WORK_MODES, type AttendanceDay } from '#lib/types/attendance.ts';
	import { watchAttendance } from '#lib/firebase/attendance.ts';
	import { logout, friendlyError } from '#lib/firebase/auth.ts';
	import { dateKey, formatDate, formatTime, durationLabel } from '#lib/utils/date.ts';
	import Brand from './Brand.svelte';
	import Icon from './Icon.svelte';
	import AttendanceForm from './AttendanceForm.svelte';
	import AttendanceHistory from './AttendanceHistory.svelte';
	import PwaInstall from './PwaInstall.svelte';
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
		(user.displayName || user.email?.split('@')[0] || 'Teman').split(' ')[0]
	);
	const initials = $derived((user.displayName || user.email || 'T').slice(0, 2).toUpperCase());
	const monthDays = $derived(
		days.filter((day) => day.dateKey.startsWith(dateKey(now).slice(0, 6)))
	);
	const nextKind = $derived(today?.checkIn ? 'checkOut' : 'checkIn');
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
		message = 'Presensi berhasil diterima server. Selamat melanjutkan harimu!';
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
		<a class="brand-link" href="#ringkasan" aria-label="Trakta — ringkasan"><Brand /></a>
		<div class="workspace-label">RUANG PRIBADI</div>
		<nav aria-label="Navigasi utama">
			<a href="#ringkasan" class="nav-link active"
				><Icon name="grid" size={18} /> Ringkasan <span class="nav-dot"></span></a
			><a href="#riwayat" class="nav-link"><Icon name="calendar" size={19} /> Riwayat presensi</a>
		</nav>
		<div class="sidebar-bottom">
			<PwaInstall />
			<div class="sidebar-user">
				<span class="avatar">{initials}</span>
				<div><strong>{user.displayName || firstName}</strong><small>Akun pribadi</small></div>
				<button
					type="button"
					class="icon-button"
					aria-label="Keluar dari akun"
					title="Keluar"
					onclick={signOut}
					disabled={signingOut}><Icon name="exit" size={18} /></button
				>
			</div>
		</div>
	</aside>
	<div class="main-shell">
		<header class="topbar">
			<div class="desktop-breadcrumb">Ruang kerja <span>/</span> <strong>Ringkasan</strong></div>
			<div class="mobile-logo"><Brand /></div>
			<div class="topbar-right">
				<span class={['connection', { offline: !online }]}
					><span></span>{online ? 'Terhubung' : 'Offline'}</span
				><span class="topbar-divider"></span><span class="avatar small">{initials}</span><button
					type="button"
					class="mobile-logout icon-button"
					aria-label="Keluar dari akun"
					onclick={signOut}
					disabled={signingOut}><Icon name="exit" size={18} /></button
				>
			</div>
		</header>
		<main id="main">
			<div id="ringkasan" class="page-heading">
				<div>
					<p class="mini-label">HARI BARU, KESEMPATAN BARU</p>
					<h1>Halo, {firstName}<span class="greeting-dot">.</span></h1>
					<p class="muted">Setiap kehadiran adalah awal dari sesuatu yang berarti.</p>
				</div>
				<div class="date-label">
					<Icon name="calendar" size={16} /><span>{formatDate(now)}</span>
				</div>
			</div>
			{#if message}<div class="notice success status-message" role="status">
					<Icon name="check" size={18} />{message}<button
						type="button"
						class="icon-button"
						aria-label="Tutup pemberitahuan"
						onclick={() => (message = '')}><Icon name="close" size={16} /></button
					>
				</div>{/if}
			{#if error}<div class="notice error status-message" role="alert">
					{error}<button type="button" class="text-button" onclick={subscribe}>Coba lagi</button>
				</div>{/if}
			{#if !online}<div class="notice offline-notice" role="status">
					<Icon name="wifi" size={17} /> Kamu sedang offline. Presensi baru memerlukan internet.
				</div>{/if}
			<section class="stats-grid" aria-label="Ringkasan kehadiran">
				<div class="card stat-card">
					<span class="stat-icon green"><Icon name="enter" size={20} /></span>
					<div>
						<p>Jam masuk</p>
						<strong
							>{formatTime(today?.checkIn.timestamp?.toDate())}<small
								>{today?.checkIn ? 'WIB' : ''}</small
							></strong
						><span
							>{loading
								? 'Memuat data…'
								: loadError
									? 'Data belum tersedia'
									: today?.checkIn
										? 'Selamat bekerja hari ini'
										: 'Belum ada presensi masuk'}</span
						>
					</div>
				</div>
				<div class="card stat-card">
					<span class="stat-icon orange"><Icon name="exit" size={20} /></span>
					<div>
						<p>Jam pulang</p>
						<strong
							>{formatTime(today?.checkOut?.timestamp?.toDate())}<small
								>{today?.checkOut ? 'WIB' : ''}</small
							></strong
						><span
							>{loading
								? 'Memuat data…'
								: loadError
									? 'Data belum tersedia'
									: today?.checkOut
										? 'Sampai jumpa esok hari'
										: 'Belum ada presensi pulang'}</span
						>
					</div>
				</div>
				<div class="card stat-card">
					<span class="stat-icon blue"><Icon name="calendar" size={20} /></span>
					<div>
						<p>Kehadiran bulan ini</p>
						<strong>{loading || loadError ? '—' : monthDays.length}<small>hari</small></strong><span
							>{formatDate(now, { weekday: undefined, day: undefined, month: 'long' })}</span
						>
					</div>
				</div>
			</section>
			<div class="dashboard-grid">
				<div class="primary-column">
					{#if loading}<section class="card loading-card" role="status">
							<span class="spinner"></span>
							<p>Menyiapkan ruang presensimu…</p>
						</section>{:else if loadError}<section class="card loading-card" role="alert">
							<Icon name="info" size={28} />
							<h2>
								{permissionDenied ? 'Akses presensi belum diizinkan' : 'Data belum dapat dimuat'}
							</h2>
							<p>{loadError}</p>
							<button type="button" class="button secondary" onclick={subscribe}
								>Muat ulang data</button
							>
						</section>{:else if today?.checkOut}<section class="card completed-card">
							<div class="complete-symbol"><Icon name="check" size={38} /></div>
							<span class="mini-label">TERIMA KASIH SUDAH HADIR</span>
							<h2>Hari ini, tuntas.</h2>
							<p>
								Presensi masuk dan pulangmu sudah tercatat.<br />Saatnya menikmati waktu istirahat.
							</p>
							<div class="completed-duration">
								<Icon name="clock" size={18} /><strong
									>{durationLabel(
										today.checkIn.timestamp?.toDate(),
										today.checkOut.timestamp?.toDate()
									)}</strong
								><span>rentang kehadiran hari ini</span>
							</div>
							<span class="completion-date">{formatDate(now)}</span>
						</section>{:else}{#key `${dateKey(now)}-${nextKind}`}<AttendanceForm
								uid={user.uid}
								kind={nextKind}
								{online}
								onsuccess={submitted}
							/>{/key}{/if}
				</div>
				<aside class="support-column">
					<section class="today-card">
						<div class="section-heading">
							<h2>Harimu, sekilas</h2>
							<span class="today-badge">HARI INI</span>
						</div>
						<div class="live-clock">{formatTime(now)}<span>WIB</span></div>
						<p class="clock-caption">Waktu Indonesia Barat</p>
						<div class="timeline">
							<div class={['timeline-item', { done: today?.checkIn }]}>
								<span class="timeline-marker"
									>{#if today?.checkIn}<Icon name="check" size={12} />{:else}1{/if}</span
								>
								<div>
									<strong>Presensi masuk</strong>
									<p>
										{today?.checkIn
											? `${formatTime(today.checkIn.timestamp?.toDate())} WIB · ${WORK_MODES[today.checkIn.mode]}`
											: 'Mulai hari dengan semangat'}
									</p>
								</div>
							</div>
							<div class={['timeline-item', { done: today?.checkOut }]}>
								<span class="timeline-marker"
									>{#if today?.checkOut}<Icon name="check" size={12} />{:else}2{/if}</span
								>
								<div>
									<strong>Presensi pulang</strong>
									<p>
										{today?.checkOut
											? `${formatTime(today.checkOut.timestamp?.toDate())} WIB · Sudah tercatat`
											: 'Tutup hari dengan pencapaian'}
									</p>
								</div>
							</div>
						</div>
					</section>
					<section class="tip-card">
						<span class="tip-icon"><Icon name="spark" size={20} /></span>
						<h2>Setiap langkah berarti.</h2>
						<p>Setiap hari adalah kesempatan untuk tumbuh dan memberi yang terbaik.</p>
						<div class="tip-line"></div>
						<span>Satu hari. Satu langkah lebih baik.</span>
					</section>
					<div class="privacy-note">
						<Icon name="shield" size={18} />
						<p>Data dan foto presensimu hanya dapat diakses melalui akunmu.</p>
					</div>
					<div class="mobile-install"><PwaInstall /></div>
				</aside>
			</div>
			{#if !loadError}<AttendanceHistory {days} uid={user.uid} {loading} />{/if}
			<footer class="page-footer">
				<span>Trakta <span class="muted">Teman setiap hari kerja.</span></span><span
					>Zona waktu Asia/Jakarta · WIB</span
				>
			</footer>
		</main>
	</div>
</div>

<style>
	.app-shell {
		display: flex;
		min-height: 100svh;
	}
	.sidebar {
		width: 238px;
		background: var(--surface);
		border-right: 1px solid var(--border);
		padding: 31px 21px 0;
		position: fixed;
		inset: 0 auto 0 0;
		display: flex;
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
		margin: 25px -21px 0;
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
		background: #e3eee6;
		flex-shrink: 0;
	}
	.avatar.small {
		width: 31px;
		height: 31px;
		font-size: 10px;
	}
	.main-shell {
		margin-left: 238px;
		width: calc(100% - 238px);
	}
	.topbar {
		height: 77px;
		border-bottom: 1px solid var(--border);
		background: var(--surface);
		padding: 0 38px;
		display: flex;
		justify-content: space-between;
		align-items: center;
	}
	.desktop-breadcrumb {
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
		gap: 20px;
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
		width: 1px;
		height: 23px;
		background: var(--border);
	}
	.mobile-logo,
	.mobile-logout,
	.mobile-install {
		display: none;
	}
	main {
		padding: 35px 38px 0;
		max-width: 1300px;
		margin: 0 auto;
	}
	.page-heading {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 16px;
		margin-bottom: 29px;
		scroll-margin-top: 25px;
	}
	.mini-label {
		font-size: 9px;
		font-weight: 650;
		letter-spacing: 1.4px;
		color: var(--primary);
		margin: 0 0 10px;
	}
	h1 {
		font-size: 34px;
		font-weight: 650;
		letter-spacing: -1.1px;
		margin: 0 0 10px;
	}
	.greeting-dot {
		color: var(--primary);
	}
	.page-heading .muted {
		font-size: 12px;
		line-height: 1.7;
		margin: 0;
	}
	.date-label {
		display: flex;
		align-items: center;
		gap: 8px;
		color: var(--muted);
		font-size: 10px;
		padding: 11px 13px;
		border: 1px solid var(--border);
		border-radius: 7px;
		background: white;
		white-space: nowrap;
	}
	.stats-grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 17px;
		margin-bottom: 26px;
	}
	.stat-card {
		padding: 21px;
		display: flex;
		gap: 15px;
	}
	.stat-icon {
		border-radius: 10px;
		padding: 11px;
		height: 43px;
		display: flex;
		align-items: center;
		justify-content: center;
		flex-shrink: 0;
	}
	.green {
		color: var(--primary);
		background: var(--primary-soft);
	}
	.orange {
		color: #a75a21;
		background: #fff0e3;
	}
	.blue {
		color: #5063a2;
		background: #edf0fd;
	}
	.stat-card p {
		color: var(--muted);
		font-size: 11px;
		margin: 0 0 11px;
	}
	.stat-card strong {
		font-size: 29px;
		line-height: 1;
		letter-spacing: -1px;
		font-weight: 600;
		display: block;
	}
	.stat-card strong small {
		font-size: 10px;
		letter-spacing: 0;
		color: var(--muted);
		margin-left: 7px;
		font-weight: 450;
	}
	.stat-card div > span {
		font-size: 9px;
		color: var(--muted);
		display: block;
		margin-top: 11px;
		line-height: 1.6;
	}
	.dashboard-grid {
		display: grid;
		grid-template-columns: 1.55fr 1fr;
		gap: 24px;
		margin-bottom: 26px;
	}
	.primary-column {
		min-width: 0;
	}
	.support-column {
		display: grid;
		align-content: start;
		gap: 19px;
	}
	.today-card {
		background: var(--forest);
		color: white;
		padding: 25px;
		border-radius: 12px;
	}
	.today-card h2 {
		font-size: 14px;
		font-weight: 500;
	}
	.today-badge {
		font-size: 8px;
		font-weight: 600;
		letter-spacing: 1px;
		background: #ffffff12;
		border: 1px solid #ffffff20;
		padding: 5px 7px;
		border-radius: 4px;
		color: #d3e1dc;
	}
	.live-clock {
		font-size: 54px;
		line-height: 1.2;
		font-weight: 450;
		letter-spacing: -2px;
		margin-top: 26px;
		font-variant-numeric: tabular-nums;
	}
	.live-clock span {
		font-size: 11px;
		color: #b9d1cc;
		letter-spacing: 0;
		margin-left: 10px;
	}
	.clock-caption {
		font-size: 10px;
		margin: 5px 0 26px;
		color: #b9d1cc;
	}
	.timeline {
		border-top: 1px solid #ffffff1c;
		padding-top: 23px;
	}
	.timeline-item {
		display: flex;
		gap: 12px;
		position: relative;
	}
	.timeline-item:first-child {
		padding-bottom: 27px;
	}
	.timeline-item:first-child::after {
		content: '';
		position: absolute;
		left: 11px;
		top: 27px;
		bottom: 5px;
		width: 1px;
		background: #ffffff25;
	}
	.timeline-marker {
		border: 1px solid #ffffff40;
		color: #c2d2cc;
		width: 24px;
		height: 24px;
		border-radius: 50%;
		font-size: 9px;
		display: grid;
		place-items: center;
		flex-shrink: 0;
	}
	.done .timeline-marker {
		background: var(--lime);
		border-color: var(--lime);
		color: var(--forest);
	}
	.timeline-item strong {
		font-size: 11px;
		font-weight: 500;
	}
	.timeline-item p {
		color: #b9d1cc;
		font-size: 9px;
		margin: 7px 0 0;
		line-height: 1.5;
	}
	.tip-card {
		background: #eff0e5;
		border: 1px solid #e3e5d6;
		border-radius: 12px;
		padding: 24px;
	}
	.tip-icon {
		color: var(--forest);
	}
	.tip-card h2 {
		font-size: 18px;
		font-weight: 600;
		letter-spacing: -0.4px;
		margin: 14px 0 10px;
	}
	.tip-card p {
		font-size: 11px;
		line-height: 1.9;
		color: #5b685b;
		margin: 0;
	}
	.tip-line {
		width: 28px;
		height: 2px;
		background: #c2c9aa;
		margin: 19px 0 12px;
	}
	.tip-card > span:last-child {
		font-size: 9px;
		color: #5b685b;
	}
	.privacy-note {
		display: flex;
		gap: 10px;
		color: var(--muted);
		padding: 0 6px;
	}
	.privacy-note :global(svg) {
		flex-shrink: 0;
		margin-top: 1px;
	}
	.privacy-note p {
		font-size: 10px;
		line-height: 1.8;
		margin: 0;
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
	.completed-card {
		min-height: 515px;
		padding: 40px 25px;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		text-align: center;
	}
	.complete-symbol {
		width: 86px;
		height: 86px;
		display: grid;
		place-items: center;
		background: var(--primary-soft);
		color: var(--primary);
		border-radius: 50%;
		margin-bottom: 28px;
	}
	.completed-card h2 {
		font-size: 32px;
		letter-spacing: -1px;
		margin: 8px 0 15px;
	}
	.completed-card > p {
		font-size: 13px;
		line-height: 1.9;
		color: var(--muted);
	}
	.completed-duration {
		display: flex;
		align-items: center;
		flex-wrap: wrap;
		justify-content: center;
		gap: 8px;
		border: 1px solid var(--border);
		border-radius: 9px;
		padding: 17px;
		margin: 20px 0;
		color: var(--primary);
		font-size: 14px;
	}
	.completed-duration span {
		color: var(--muted);
		font-size: 10px;
	}
	.completion-date {
		color: var(--muted);
		font-size: 10px;
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
		justify-content: space-between;
		gap: 15px;
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
	@media (max-width: 1150px) {
		.sidebar {
			width: 210px;
			padding-left: 15px;
			padding-right: 15px;
		}
		.sidebar-user {
			margin-left: -15px;
			margin-right: -15px;
		}
		.main-shell {
			margin-left: 210px;
			width: calc(100% - 210px);
		}
		main {
			padding: 28px 25px 0;
		}
		.topbar {
			padding: 0 25px;
		}
		.stat-card {
			padding: 17px 14px;
			gap: 10px;
		}
		.stat-icon {
			padding: 8px;
			height: 36px;
		}
		.stat-card strong {
			font-size: 25px;
		}
		.date-label {
			display: none;
		}
		.dashboard-grid {
			gap: 18px;
			grid-template-columns: 1.4fr 1fr;
		}
		.today-card,
		.tip-card {
			padding: 21px;
		}
	}
	@media (max-width: 900px) {
		.sidebar {
			display: none;
		}
		.main-shell {
			width: 100%;
			margin: 0;
		}
		.mobile-logo,
		.mobile-install {
			display: block;
		}
		.mobile-logo :global(.brand) {
			font-size: 26px;
		}
		.mobile-logout {
			display: inline-flex;
		}
		.desktop-breadcrumb {
			display: none;
		}
		.topbar {
			height: 70px;
		}
		.topbar-right {
			gap: 12px;
		}
		.page-heading {
			margin-top: 5px;
		}
	}
	@media (max-width: 640px) {
		main {
			padding: 25px 18px 0;
		}
		.topbar {
			padding: 0 19px;
		}
		.topbar-divider,
		.topbar-right .avatar {
			display: none;
		}
		h1 {
			font-size: 30px;
		}
		.page-heading .muted {
			font-size: 11px;
		}
		.stats-grid {
			gap: 9px;
			grid-template-columns: 1fr 1fr;
			margin-bottom: 18px;
		}
		.stat-card {
			padding: 16px 13px;
			gap: 10px;
		}
		.stat-card:last-child {
			grid-column: 1 / -1;
			align-items: center;
			padding: 14px;
		}
		.stat-card:last-child > div {
			display: flex;
			align-items: center;
			flex: 1;
			flex-wrap: wrap;
			gap: 5px 12px;
		}
		.stat-card:last-child p {
			margin: 0;
			flex: 1;
		}
		.stat-card:last-child strong {
			font-size: 22px;
		}
		.stat-card:last-child div > span {
			display: none;
		}
		.stat-card strong {
			font-size: 25px;
		}
		.stat-card div > span {
			font-size: 8px;
		}
		.stat-icon {
			width: 31px;
			height: 33px;
		}
		.stat-card p {
			font-size: 10px;
		}
		.dashboard-grid {
			grid-template-columns: 1fr;
		}
		.support-column {
			grid-template-columns: 1fr;
		}
		.today-card {
			padding: 23px;
		}
		.live-clock {
			margin-top: 18px;
			font-size: 46px;
		}
		.tip-card {
			display: none;
		}
		.page-footer {
			flex-direction: column;
			gap: 8px;
		}
		.completed-card {
			min-height: 390px;
		}
		.page-heading {
			margin-bottom: 22px;
		}
		.privacy-note {
			padding-bottom: 5px;
		}
	}
</style>
