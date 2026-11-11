<script lang="ts">
	import type { AttendanceDay, AttendanceKind } from '#lib/types/attendance.ts';
	import { WORK_MODES } from '#lib/types/attendance.ts';
	import { dateFromKey, formatDate, formatTime, durationLabel } from '#lib/utils/date.ts';
	import { loadPhoto } from '#lib/firebase/attendance.ts';
	import { friendlyError } from '#lib/firebase/auth.ts';
	import Icon from './Icon.svelte';
	import LoadingSkeleton from './LoadingSkeleton.svelte';
	let { days, uid, loading }: { days: AttendanceDay[]; uid: string; loading: boolean } = $props();
	let expanded = $state(false);
	let photo = $state('');
	let photoLabel = $state('');
	let busy = $state(false);
	let error = $state('');
	let photoDialog: HTMLDialogElement;
	let activeRequest = 0;
	let shownDays = $derived(expanded ? days : days.slice(0, 5));
	async function openPhoto(day: AttendanceDay, kind: AttendanceKind) {
		const version = ++activeRequest;
		busy = true;
		error = '';
		photo = '';
		photoLabel = `Foto ${kind === 'checkIn' ? 'masuk' : 'pulang'} · ${formatDate(dateFromKey(day.dateKey))}`;
		photoDialog.showModal();
		try {
			const result = await loadPhoto(uid, day.dateKey, kind);
			if (version === activeRequest) photo = result;
		} catch (cause) {
			if (version === activeRequest) error = friendlyError(cause);
		} finally {
			if (version === activeRequest) busy = false;
		}
	}
	function closePhoto() {
		activeRequest++;
		photo = '';
		busy = false;
	}
</script>

<section id="riwayat" class="card history-card" aria-labelledby="history-title">
	<div class="section-heading history-heading">
		<div>
			<h2 id="history-title">Jejak kehadiranmu</h2>
			<p class="muted">Riwayat {expanded ? '31 presensi terakhir' : 'presensi terbaru'}.</p>
		</div>
		{#if days.length > 5}<button
				type="button"
				class="text-button"
				onclick={() => (expanded = !expanded)}
				>{expanded ? 'Ringkas' : 'Lihat semua'} <Icon name="arrow" size={15} /></button
			>{/if}
	</div>
	{#if loading}<LoadingSkeleton
			variant="history"
			label="Mengambil riwayat presensi…"
		/>{:else if !days.length}<div class="empty-history">
			<div class="empty-icon"><Icon name="calendar" size={26} /></div>
			<strong>Setiap perjalanan punya awal.</strong>
			<p>Presensi pertamamu akan muncul di sini.<br />Mulai dengan mencatat kehadiran hari ini.</p>
		</div>{:else}<div class="table-scroll">
			<table>
				<thead
					><tr
						><th>Tanggal</th><th>Masuk</th><th>Pulang</th><th>Durasi</th><th>Status</th><th>Foto</th
						></tr
					></thead
				><tbody
					>{#each shownDays as day (day.id)}<tr
							><td
								><strong
									>{formatDate(dateFromKey(day.dateKey), {
										weekday: undefined,
										month: 'short',
										year: undefined
									})}</strong
								><small>{WORK_MODES[day.checkIn.mode]}</small></td
							><td>{formatTime(day.checkIn.timestamp?.toDate())}</td><td
								>{formatTime(day.checkOut?.timestamp?.toDate())}</td
							><td
								>{durationLabel(
									day.checkIn.timestamp?.toDate(),
									day.checkOut?.timestamp?.toDate()
								)}</td
							><td
								><span class={['badge', { complete: day.checkOut }]}
									>{day.checkOut ? 'Lengkap' : 'Sudah masuk'}</span
								></td
							><td
								><div class="photo-actions">
									<button
										type="button"
										class="icon-button"
										aria-label={`Lihat foto masuk ${day.dateKey}`}
										title="Foto masuk"
										onclick={() => openPhoto(day, 'checkIn')}
										><Icon name="image" size={16} /></button
									>{#if day.checkOut}<button
											type="button"
											class="icon-button"
											aria-label={`Lihat foto pulang ${day.dateKey}`}
											title="Foto pulang"
											onclick={() => openPhoto(day, 'checkOut')}
											><Icon name="image" size={16} /></button
										>{/if}
								</div></td
							></tr
						>{#if day.checkIn.note || day.checkOut?.note}<tr class="note-row"
								><td colspan="6"
									>{#if day.checkIn.note}<p>
											<strong>Masuk:</strong>
											{day.checkIn.note}
										</p>{/if}{#if day.checkOut?.note}<p>
											<strong>Pulang:</strong>
											{day.checkOut.note}
										</p>{/if}</td
								></tr
							>{/if}{/each}</tbody
				>
			</table>
		</div>{/if}
</section>

<dialog bind:this={photoDialog} onclose={closePhoto} class="photo-dialog">
	<div class="section-heading">
		<h2>{photoLabel}</h2>
		<button
			type="button"
			class="icon-button"
			aria-label="Tutup foto"
			onclick={() => photoDialog.close()}><Icon name="close" /></button
		>
	</div>
	{#if busy}<LoadingSkeleton variant="photo" label="Mengambil foto…" />{:else if error}<p
			class="notice error"
			role="alert"
		>
			{error}
		</p>{:else if photo}<img src={photo} alt={photoLabel} />{/if}
</dialog>

<style>
	.history-card {
		overflow: hidden;
		scroll-margin-top: 24px;
	}
	.history-heading {
		padding: 25px 27px;
		gap: 15px;
	}
	h2 {
		font-size: 18px;
		letter-spacing: -0.4px;
	}
	.history-heading p {
		font-size: 11px;
		margin: 7px 0 0;
	}
	.text-button {
		display: flex;
		align-items: center;
		gap: 8px;
		font-size: 11px;
		white-space: nowrap;
	}
	.empty-history {
		min-height: 200px;
		display: flex;
		flex-direction: column;
		justify-content: center;
		align-items: center;
		text-align: center;
		padding: 25px;
		font-size: 12px;
		color: var(--muted);
	}
	.empty-history strong {
		color: var(--ink);
		font-size: 13px;
		margin-top: 14px;
	}
	.empty-history p {
		line-height: 1.8;
	}
	.empty-icon {
		color: var(--primary);
		padding: 15px;
		border-radius: 50%;
		background: var(--subtle);
	}
	.table-scroll {
		overflow-x: auto;
	}
	table {
		border-collapse: collapse;
		width: 100%;
		text-align: left;
		font-size: 12px;
		white-space: nowrap;
	}
	th {
		background: var(--subtle);
		padding: 12px 18px;
		color: var(--muted);
		font-size: 10px;
		font-weight: 550;
	}
	td {
		padding: 13px 18px;
		border-top: 1px solid var(--border);
	}
	th:first-child,
	td:first-child {
		padding-left: 27px;
	}
	td strong {
		font-weight: 600;
	}
	small {
		display: block;
		font-size: 10px;
		margin-top: 5px;
		color: var(--muted);
	}
	.badge {
		font-size: 10px;
		padding: 5px 8px;
		background: var(--warning-soft);
		color: var(--warning);
		border-radius: 5px;
	}
	.badge.complete {
		background: var(--primary-soft);
		color: var(--primary);
	}
	.photo-actions {
		display: flex;
		gap: 3px;
	}
	.photo-actions .icon-button {
		min-width: 34px;
	}
	.note-row td {
		border-top: none;
		padding-top: 0;
		white-space: normal;
		max-width: 600px;
		overflow-wrap: anywhere;
		color: var(--muted);
		font-size: 11px;
	}
	.note-row p {
		margin: 3px 0;
	}
	.photo-dialog {
		max-width: min(640px, calc(100vw - 32px));
		width: 100%;
		border: 1px solid var(--border);
		border-radius: 16px;
		padding: 22px;
		background: white;
		margin: auto;
		color: var(--ink);
	}
	.photo-dialog::backdrop {
		background: #122a24aa;
		backdrop-filter: blur(4px);
	}
	.photo-dialog h2 {
		font-size: 14px;
		line-height: 1.6;
	}
	.photo-dialog img {
		display: block;
		max-width: 100%;
		max-height: 70svh;
		margin: 16px auto 0;
		border-radius: 8px;
	}
</style>
