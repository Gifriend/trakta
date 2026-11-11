<script lang="ts">
	import { getPreferences } from '#lib/preferences.ts';
	import type { AttendanceDay, AttendanceKind } from '#lib/types/attendance.ts';
	import { WORK_MODES } from '#lib/types/attendance.ts';
	import { dateFromKey, formatDate, formatTime, durationLabel } from '#lib/utils/date.ts';
	import { loadAttendanceForExport, loadPhoto } from '#lib/firebase/attendance.ts';
	import { friendlyError } from '#lib/firebase/auth.ts';
	import Icon from './Icon.svelte';
	import LoadingSkeleton from './LoadingSkeleton.svelte';
	let { days, uid, loading }: { days: AttendanceDay[]; uid: string; loading: boolean } = $props();
	let expanded = $state(false);
	let photo = $state('');
	let selectedPhoto = $state<{ dateKey: string; kind: AttendanceKind }>();
	let busy = $state(false);
	let error = $state('');
	let exporting = $state(false);
	let exportError = $state('');
	let photoDialog: HTMLDialogElement;
	let activeRequest = 0;
	let shownDays = $derived(expanded ? days : days.slice(0, 5));
	async function exportExcel() {
		if (exporting || !days.length) return;
		exportError = '';
		if (!navigator.onLine) {
			exportError = 'Hubungkan internet untuk mengunduh seluruh riwayat presensi.';
			return;
		}
		exporting = true;
		const { locale } = preferences;
		try {
			const [{ downloadAttendanceWorkbook }, records] = await Promise.all([
				import('#lib/utils/attendance-excel.ts'),
				loadAttendanceForExport(uid)
			]);
			if (records.length) await downloadAttendanceWorkbook(records, locale);
			else exportError = 'Belum ada data presensi untuk diekspor.';
		} catch {
			exportError = 'Ekspor Excel gagal. Periksa koneksi lalu coba lagi.';
		} finally {
			exporting = false;
		}
	}
	async function openPhoto(day: AttendanceDay, kind: AttendanceKind) {
		const version = ++activeRequest;
		busy = true;
		error = '';
		photo = '';
		selectedPhoto = { dateKey: day.dateKey, kind };
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
	const preferences = getPreferences();
	const { t } = preferences;
	const photoLabel = $derived(
		selectedPhoto
			? `${t(selectedPhoto.kind === 'checkIn' ? 'Foto masuk' : 'Foto pulang')} · ${formatDate(dateFromKey(selectedPhoto.dateKey), {}, preferences.locale)}`
			: ''
	);
</script>

<section id="riwayat" class="card history-card" aria-labelledby="history-title">
	<div class="section-heading history-heading">
		<div>
			<h2 id="history-title">{t('Jejak kehadiranmu')}</h2>
			<p class="muted">
				{t(expanded ? 'Riwayat 31 presensi terakhir.' : 'Riwayat presensi terbaru.')}
			</p>
		</div>
		{#if !loading && days.length}
			<div class="history-actions">
				{#if days.length > 5}
					<button type="button" class="text-button" onclick={() => (expanded = !expanded)}>
						{expanded ? t('Ringkas') : t('Lihat semua')}
						<Icon name="arrow" size={15} />
					</button>
				{/if}
				<button
					type="button"
					class="button secondary"
					disabled={exporting}
					aria-busy={exporting}
					onclick={exportExcel}
				>
					<Icon name="download" size={16} />
					{exporting ? t('Menyiapkan Excel…') : t('Ekspor Excel')}
				</button>
			</div>
		{/if}
	</div>
	{#if exportError}<p class="notice error export-error" role="alert">{t(exportError)}</p>{/if}
	{#if loading}<LoadingSkeleton
			variant="history"
			label={t('Mengambil riwayat presensi…')}
		/>{:else if !days.length}<div class="empty-history">
			<div class="empty-icon"><Icon name="calendar" size={26} /></div>
			<strong>{t('Setiap perjalanan punya awal.')}</strong>
			<p>
				{t('Presensi pertamamu akan muncul di sini.')}<br />{t(
					'Mulai dengan mencatat kehadiran hari ini.'
				)}
			</p>
		</div>{:else}<div class="table-scroll">
			<table>
				<thead
					><tr
						><th>{t('Tanggal')}</th><th>{t('Masuk')}</th><th>{t('Pulang')}</th><th>{t('Durasi')}</th
						><th>{t('Status')}</th><th>{t('Foto')}</th></tr
					></thead
				><tbody
					>{#each shownDays as day (day.id)}<tr
							><td
								><strong
									>{formatDate(
										dateFromKey(day.dateKey),
										{
											weekday: undefined,
											month: 'short',
											year: undefined
										},
										preferences.locale
									)}</strong
								><small>{t(WORK_MODES[day.checkIn.mode])}</small></td
							><td>{formatTime(day.checkIn.timestamp?.toDate(), preferences.locale)}</td><td
								>{formatTime(day.checkOut?.timestamp?.toDate(), preferences.locale)}</td
							><td
								>{durationLabel(
									day.checkIn.timestamp?.toDate(),
									day.checkOut?.timestamp?.toDate(),
									preferences.locale
								)}</td
							><td
								><span class={['badge', { complete: day.checkOut }]}
									>{day.checkOut ? t('Lengkap') : t('Sudah masuk')}</span
								></td
							><td
								><div class="photo-actions">
									<button
										type="button"
										class="icon-button"
										aria-label={t('Lihat foto masuk {date}', { date: day.dateKey })}
										title={t('Foto masuk')}
										onclick={() => openPhoto(day, 'checkIn')}
										><Icon name="image" size={16} /></button
									>{#if day.checkOut}<button
											type="button"
											class="icon-button"
											aria-label={t('Lihat foto pulang {date}', { date: day.dateKey })}
											title={t('Foto pulang')}
											onclick={() => openPhoto(day, 'checkOut')}
											><Icon name="image" size={16} /></button
										>{/if}
								</div></td
							></tr
						>{#if day.checkIn.note || day.checkOut?.note}<tr class="note-row"
								><td colspan="6"
									>{#if day.checkIn.note}<p>
											<strong>{t('Masuk')}:</strong>
											{day.checkIn.note}
										</p>{/if}{#if day.checkOut?.note}<p>
											<strong>{t('Pulang')}:</strong>
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
			aria-label={t('Tutup foto')}
			onclick={() => photoDialog.close()}><Icon name="close" /></button
		>
	</div>
	{#if busy}<LoadingSkeleton variant="photo" label={t('Mengambil foto…')} />{:else if error}<p
			class="notice error"
			role="alert"
		>
			{t(error)}
		</p>{:else if photo}<img src={photo} alt={photoLabel} />{/if}
</dialog>

<style>
	.history-card {
		overflow: hidden;
		scroll-margin-top: 24px;
	}
	.history-heading {
		padding: 25px 27px;
		gap: 12px;
		flex-wrap: wrap;
	}
	.history-actions {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		gap: 8px 14px;
	}
	.export-error {
		margin: 0 27px 16px;
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
		background: var(--surface);
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
