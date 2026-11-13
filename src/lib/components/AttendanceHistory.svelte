<script lang="ts">
	import { onDestroy } from 'svelte';
	import { getPreferences } from '#lib/preferences.ts';
	import type { AttendanceDay, AttendanceKind } from '#lib/types/attendance.ts';
	import { WORK_MODES } from '#lib/types/attendance.ts';
	import { dateFromKey, formatDate, formatTime, durationLabel } from '#lib/utils/date.ts';
	import {
		ATTENDANCE_PAGE_SIZE,
		loadAttendanceForExport,
		loadAttendancePage,
		type AttendanceRange
	} from '#lib/firebase/attendance.ts';
	import { friendlyError } from '#lib/firebase/auth.ts';
	import Icon from './Icon.svelte';
	import AttendanceThumbnail from './AttendanceThumbnail.svelte';
	import LoadingSkeleton from './LoadingSkeleton.svelte';
	let { days, uid, loading }: { days: AttendanceDay[]; uid: string; loading: boolean } = $props();
	type HistoryPage = Awaited<ReturnType<typeof loadAttendancePage>>;
	const fieldId = $props.id();
	let from = $state('');
	let to = $state('');
	let appliedFilter = $state.raw<{ range: AttendanceRange; page: HistoryPage }>();
	let navigation = $state.raw<{ firstCursor: string; pages: HistoryPage[]; index: number }>();
	let loadingPage = $state(false);
	let pageError = $state('');
	let photo = $state('');
	let selectedPhoto = $state<{ dateKey: string; kind: AttendanceKind }>();
	let busy = $state(false);
	let error = $state('');
	let exporting = $state(false);
	let exportError = $state('');
	let withPhotos = $state(false);
	let expandedDays = $state<Record<string, boolean>>({});
	let filterOpen = $state(false);
	let filterToggle = $state<HTMLButtonElement>();
	let workbook = $state.raw<{ file: File; url: string; canShare: boolean }>();
	let destroyed = false;
	let photoDialog: HTMLDialogElement;
	let activeRequest = 0;
	const firstPage = $derived.by(() => {
		if (!appliedFilter) {
			return {
				days: days.slice(0, ATTENDANCE_PAGE_SIZE),
				hasNext: days.length > ATTENDANCE_PAGE_SIZE
			};
		}
		const { range, page } = appliedFilter;
		const latest = days[0];
		const latestFetched = page.days[0];
		if (
			!latest ||
			(latestFetched && latest.dateKey < latestFetched.dateKey) ||
			(latestFetched?.dateKey === latest.dateKey && latestFetched.checkOut && !latest.checkOut) ||
			(range.from && latest.dateKey < range.from) ||
			(range.to && latest.dateKey > range.to)
		) {
			return page;
		}
		const records = [latest, ...page.days.filter((day) => day.dateKey !== latest.dateKey)];
		return {
			days: records.slice(0, ATTENDANCE_PAGE_SIZE),
			hasNext: page.hasNext || records.length > ATTENDANCE_PAGE_SIZE
		};
	});
	const firstCursor = $derived(firstPage.days.at(-1)?.dateKey);
	const browsing = $derived(navigation?.firstCursor === firstCursor ? navigation : undefined);
	const pageIndex = $derived(browsing?.index ?? 0);
	const currentPage = $derived(browsing?.pages[pageIndex - 1] ?? firstPage);

	function clearFilter() {
		from = '';
		to = '';
		appliedFilter = undefined;
		navigation = undefined;
		pageError = '';
		exportError = '';
		clearWorkbook();
	}

	async function applyFilter(event: SubmitEvent) {
		event.preventDefault();
		if (loadingPage || exporting) return;
		if (!from && !to) {
			clearFilter();
			return;
		}
		if (from && to && from > to) {
			pageError = 'Tanggal mulai harus sebelum atau sama dengan tanggal sampai.';
			return;
		}
		pageError = '';
		exportError = '';
		loadingPage = true;
		const range = {
			from: from.replaceAll('-', '') || undefined,
			to: to.replaceAll('-', '') || undefined
		};
		try {
			const page = await loadAttendancePage(uid, range);
			appliedFilter = { range, page };
			navigation = undefined;
			clearWorkbook();
			if (filterOpen && filterToggle?.getClientRects().length) {
				filterOpen = false;
				filterToggle.focus();
			}
		} catch {
			pageError = 'Filter tanggal gagal dimuat. Periksa koneksi lalu coba lagi.';
		} finally {
			loadingPage = false;
		}
	}

	function clearWorkbook() {
		if (workbook) URL.revokeObjectURL(workbook.url);
		workbook = undefined;
	}

	onDestroy(() => {
		destroyed = true;
		clearWorkbook();
	});

	async function shareWorkbook() {
		if (!workbook?.canShare) return;
		exportError = '';
		try {
			await navigator.share({ files: [workbook.file] });
		} catch (cause) {
			if (!(cause instanceof DOMException && cause.name === 'AbortError')) {
				exportError = 'Excel belum bisa dibagikan. Gunakan Unduh Excel.';
			}
		}
	}

	function previousPage() {
		if (!browsing || pageIndex === 0 || loadingPage) return;
		pageError = '';
		navigation = { ...browsing, index: pageIndex - 1 };
	}

	async function nextPage() {
		const boundary = firstCursor;
		const after = currentPage.days.at(-1)?.dateKey;
		if (!boundary || !after || !currentPage.hasNext || loadingPage) return;
		pageError = '';
		const pages = browsing?.pages ?? [];
		const index = pageIndex + 1;
		if (pages[index - 1]) {
			navigation = { firstCursor: boundary, pages, index };
			return;
		}
		loadingPage = true;
		try {
			const page = await loadAttendancePage(uid, appliedFilter?.range, after);
			if (firstCursor !== boundary) return;
			if (page.days.length) navigation = { firstCursor: boundary, pages: [...pages, page], index };
			else pageError = 'Tidak ada halaman berikutnya.';
		} catch {
			pageError = 'Halaman berikutnya gagal dimuat. Periksa koneksi lalu coba lagi.';
		} finally {
			loadingPage = false;
		}
	}

	async function exportExcel() {
		if (exporting || loadingPage || !currentPage.days.length) return;
		exportError = '';
		clearWorkbook();
		if (!navigator.onLine) {
			exportError = 'Hubungkan internet untuk mengunduh seluruh riwayat presensi.';
			return;
		}
		exporting = true;
		const { locale } = preferences;
		const includePhotos = withPhotos;
		try {
			const [{ createAttendanceWorkbook }, records] = await Promise.all([
				import('#lib/utils/attendance-excel.ts'),
				loadAttendanceForExport(uid, appliedFilter?.range)
			]);
			if (records.length) {
				const file = await createAttendanceWorkbook(
					records,
					locale,
					includePhotos ? uid : undefined
				);
				if (destroyed) return;
				workbook = {
					file,
					url: URL.createObjectURL(file),
					canShare:
						typeof navigator.share === 'function' &&
						navigator.canShare?.({ files: [file] }) === true
				};
			} else exportError = 'Belum ada data presensi untuk diekspor.';
		} catch {
			exportError = 'Ekspor Excel gagal. Periksa koneksi lalu coba lagi.';
		} finally {
			exporting = false;
		}
	}
	async function openPhoto(day: AttendanceDay, kind: AttendanceKind, source: Promise<string>) {
		const version = ++activeRequest;
		busy = true;
		error = '';
		photo = '';
		selectedPhoto = { dateKey: day.dateKey, kind };
		photoDialog.showModal();
		try {
			const result = await source;
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
	const rangeLabel = $derived.by(() => {
		if (!appliedFilter) return '';
		const { from, to } = appliedFilter.range;
		const label = (key: string) =>
			formatDate(dateFromKey(key), { weekday: undefined, month: 'short' }, preferences.locale);
		if (from && to) return t('Periode {from} – {to}', { from: label(from), to: label(to) });
		return from
			? t('Sejak {date}', { date: label(from) })
			: to
				? t('Sampai {date}', { date: label(to) })
				: '';
	});
	const photoLabel = $derived(
		selectedPhoto
			? `${t(selectedPhoto.kind === 'checkIn' ? 'Foto masuk' : 'Foto pulang')} · ${formatDate(dateFromKey(selectedPhoto.dateKey), {}, preferences.locale)}`
			: ''
	);
</script>

{#snippet photoActions(day: AttendanceDay)}
	<div class="photo-actions">
		<AttendanceThumbnail
			{uid}
			dateKey={day.dateKey}
			kind="checkIn"
			label={t('Lihat foto masuk {date}', { date: day.dateKey })}
			title={t('Foto masuk')}
			onopen={(source) => openPhoto(day, 'checkIn', source)}
		/>
		{#if day.checkOut}
			<AttendanceThumbnail
				{uid}
				dateKey={day.dateKey}
				kind="checkOut"
				label={t('Lihat foto pulang {date}', { date: day.dateKey })}
				title={t('Foto pulang')}
				onopen={(source) => openPhoto(day, 'checkOut', source)}
			/>
		{/if}
	</div>
{/snippet}

{#snippet dayNotes(day: AttendanceDay)}
	{#if day.checkIn.note}<p><strong>{t('Masuk')}</strong> {day.checkIn.note}</p>{/if}
	{#if day.checkOut?.note}<p><strong>{t('Pulang')}</strong> {day.checkOut.note}</p>{/if}
	{#each [day.checkIn.photoLocation, day.checkOut?.photoLocation] as location, index (index)}
		{#if location}
			<p>
				<strong>{t(index === 0 ? 'Lokasi foto masuk' : 'Lokasi foto pulang')}</strong>
				<a
					href={`https://www.google.com/maps?q=${location.latitude},${location.longitude}`}
					target="_blank"
					rel="noopener noreferrer"
					class="location-link"
					title={t('Buka di Google Maps')}
				>
					<Icon name="marker" size={13} />
					<span>{location.latitude.toFixed(6)}, {location.longitude.toFixed(6)}</span>
				</a>
				· ±{Math.round(location.accuracy)} m
				{#if location.source === 'gallery'}· {t('Lokasi saat memilih file')}{/if}
			</p>
		{/if}
	{/each}
{/snippet}

<section id="riwayat" class="card history-card" aria-labelledby="history-title" tabindex="-1">
	<div class="section-heading history-heading">
		<div>
			<h2 id="history-title">{t('Jejak kehadiranmu')}</h2>
			<p class="muted">
				{rangeLabel || t('Riwayat presensi terbaru.')}
			</p>
		</div>
		{#if !loading && currentPage.days.length}
			<div class="history-actions">
				<label class="include-photos">
					<input
						type="checkbox"
						bind:checked={withPhotos}
						disabled={exporting || loadingPage}
						aria-describedby={withPhotos ? `${fieldId}-export-photos` : undefined}
						onchange={clearWorkbook}
					/>
					{t('Sertakan foto')}
				</label>
				<button
					type="button"
					class="button secondary"
					disabled={exporting || loadingPage}
					aria-busy={exporting}
					onclick={exportExcel}
				>
					<Icon name="download" size={16} />
					{exporting ? t('Menyiapkan Excel…') : t('Ekspor Excel')}
				</button>
			</div>
		{/if}
	</div>
	{#if withPhotos && !loading && currentPage.days.length}
		<p id={`${fieldId}-export-photos`} class="muted export-photo-hint">
			{t('Foto masuk dan pulang tampil berdampingan di Excel.')}
		</p>
	{/if}
	{#if workbook}
		<div class="export-ready">
			<p role="status">{t('File Excel siap disimpan.')}</p>
			<div class="history-actions">
				<a class="button primary" href={workbook.url} download={workbook.file.name} rel="external">
					<Icon name="download" size={16} />{t('Unduh Excel')}
				</a>
				{#if workbook.canShare}
					<button type="button" class="button secondary" onclick={shareWorkbook}
						>{t('Bagikan Excel')}</button
					>
				{/if}
			</div>
		</div>
	{/if}
	{#if !loading && days.length}
		<div class="filter-disclosure">
			<button
				type="button"
				class="button secondary"
				aria-expanded={filterOpen}
				aria-controls={`${fieldId}-filter`}
				bind:this={filterToggle}
				onclick={() => (filterOpen = !filterOpen)}
			>
				<Icon name="calendar" size={17} />{t('Filter tanggal')}
				{#if appliedFilter}<span class="filter-status">{t('Aktif')}</span>{/if}
			</button>
		</div>
		<form
			id={`${fieldId}-filter`}
			class={['date-filter', { 'filter-open': filterOpen }]}
			onsubmit={applyFilter}
			aria-label={t('Filter tanggal')}
		>
			<div>
				<label for={`${fieldId}-from`}>{t('Tanggal mulai')}</label>
				<input
					id={`${fieldId}-from`}
					type="date"
					max="9999-12-31"
					bind:value={from}
					disabled={loadingPage || exporting}
				/>
			</div>
			<div>
				<label for={`${fieldId}-to`}>{t('Tanggal sampai')}</label>
				<input
					id={`${fieldId}-to`}
					type="date"
					max="9999-12-31"
					bind:value={to}
					disabled={loadingPage || exporting}
				/>
			</div>
			<div class="filter-actions">
				<button type="submit" class="button secondary" disabled={loadingPage || exporting}>
					{t('Terapkan filter')}
				</button>
				{#if appliedFilter || from || to}
					<button
						type="button"
						class="text-button"
						disabled={loadingPage || exporting}
						onclick={clearFilter}
					>
						{t('Hapus filter')}
					</button>
				{/if}
			</div>
		</form>
	{/if}
	{#if exportError}<p class="notice error export-error" role="alert">{t(exportError)}</p>{/if}
	{#if pageError}<p class="notice error export-error" role="alert">{t(pageError)}</p>{/if}
	{#if !loading && (loadingPage || pageIndex > 0 || currentPage.hasNext)}
		<nav class="pagination" aria-label={t('Halaman riwayat')}>
			<button
				type="button"
				class="button secondary"
				disabled={pageIndex === 0 || loadingPage}
				onclick={previousPage}>{t('Sebelumnya')}</button
			>
			<span role="status"
				>{loadingPage
					? t('Memuat halaman…')
					: t('Halaman {page}', { page: String(pageIndex + 1) })}</span
			>
			<button
				type="button"
				class="button secondary"
				disabled={!currentPage.hasNext || loadingPage}
				onclick={nextPage}>{t('Selanjutnya')}</button
			>
		</nav>
	{/if}
	{#if loading}<LoadingSkeleton
			variant="history"
			label={t('Mengambil riwayat presensi…')}
		/>{:else if !currentPage.days.length}<div class="empty-history">
			<div class="empty-icon"><Icon name="calendar" size={26} /></div>
			{#if appliedFilter}
				<strong>{t('Tidak ada presensi dalam rentang ini.')}</strong>
			{:else}
				<strong>{t('Setiap perjalanan punya awal.')}</strong>
				<p>
					{t('Presensi pertamamu akan muncul di sini.')}<br />{t(
						'Mulai dengan mencatat kehadiran hari ini.'
					)}
				</p>
			{/if}
		</div>{:else}
		<div class="history-cards">
			{#each currentPage.days as day (day.id)}
				<details class="history-day" bind:open={expandedDays[day.id]}>
					<summary>
						<div class="history-day-heading">
							<strong
								>{formatDate(
									dateFromKey(day.dateKey),
									{ weekday: undefined, month: 'short' },
									preferences.locale
								)}</strong
							>
							<span class={['badge', { complete: day.checkOut }]}
								>{day.checkOut ? t('Lengkap') : t('Sudah masuk')}</span
							>
						</div>
						<div class="history-day-times">
							<span
								>{t('Jam masuk')}
								<strong>{formatTime(day.checkIn.timestamp?.toDate(), preferences.locale)}</strong
								></span
							>
							<span
								>{t('Jam pulang')}
								<strong>{formatTime(day.checkOut?.timestamp?.toDate(), preferences.locale)}</strong
								></span
							>
						</div>
						<span class="history-day-toggle"
							>{expandedDays[day.id] ? t('Tutup detail') : t('Lihat foto dan catatan')}</span
						>
					</summary>
					{#if expandedDays[day.id]}
						<div class="history-day-details">
							<p>
								{t(WORK_MODES[day.checkIn.mode])} · {t('Durasi')}
								{durationLabel(
									day.checkIn.timestamp?.toDate(),
									day.checkOut?.timestamp?.toDate(),
									preferences.locale
								)}
							</p>
							{@render photoActions(day)}
							{@render dayNotes(day)}
						</div>
					{/if}
				</details>
			{/each}
		</div>
		<div class="table-scroll">
			<table>
				<thead
					><tr
						><th>{t('Tanggal')}</th><th>{t('Foto')}</th><th>{t('Masuk')}</th><th>{t('Pulang')}</th
						><th>{t('Durasi')}</th><th>{t('Status')}</th><th>{t('Lokasi (Koordinat)')}</th></tr
					></thead
				><tbody
					>{#each currentPage.days as day (day.id)}<tr
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
							><td>
								{@render photoActions(day)}
							</td><td>{formatTime(day.checkIn.timestamp?.toDate(), preferences.locale)}</td><td
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
							><td>
								<div class="table-location-list">
									{#if day.checkIn.photoLocation}
										<div class="table-location-item">
											<span class="location-kind">{t('Masuk')}:</span>
											<a
												href={`https://www.google.com/maps?q=${day.checkIn.photoLocation.latitude},${day.checkIn.photoLocation.longitude}`}
												target="_blank"
												rel="noopener noreferrer"
												class="table-location-link"
												title={t('Buka di Google Maps')}
											>
												<Icon name="marker" size={13} />
												<span>{day.checkIn.photoLocation.latitude.toFixed(5)}, {day.checkIn.photoLocation.longitude.toFixed(5)}</span>
											</a>
											<span class="location-acc">±{Math.round(day.checkIn.photoLocation.accuracy)}m</span>
										</div>
									{/if}
									{#if day.checkOut?.photoLocation}
										<div class="table-location-item">
											<span class="location-kind">{t('Pulang')}:</span>
											<a
												href={`https://www.google.com/maps?q=${day.checkOut.photoLocation.latitude},${day.checkOut.photoLocation.longitude}`}
												target="_blank"
												rel="noopener noreferrer"
												class="table-location-link"
												title={t('Buka di Google Maps')}
											>
												<Icon name="marker" size={13} />
												<span>{day.checkOut.photoLocation.latitude.toFixed(5)}, {day.checkOut.photoLocation.longitude.toFixed(5)}</span>
											</a>
											<span class="location-acc">±{Math.round(day.checkOut.photoLocation.accuracy)}m</span>
										</div>
									{/if}
									{#if !day.checkIn.photoLocation && !day.checkOut?.photoLocation}
										<span class="muted">-</span>
									{/if}
								</div>
							</td></tr
						>{#if day.checkIn.note || day.checkOut?.note || day.checkIn.photoLocation || day.checkOut?.photoLocation}<tr
								class="note-row"><td colspan="7">{@render dayNotes(day)}</td></tr
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
		</p>{:else if photo}<img
			src={photo}
			alt={photoLabel}
			onerror={() => (error = 'Foto tidak ditemukan.')}
		/>{/if}
</dialog>

<style>
	.export-photo-hint {
		font-size: 13px;
		margin-block: 4px 14px;
	}
	.history-card {
		--history-gutter: clamp(16px, 4vw, 27px);
		overflow: hidden;
		scroll-margin-top: 24px;
	}
	.history-heading {
		padding: 22px var(--history-gutter) 18px;
		gap: 14px 18px;
		flex-wrap: wrap;
	}
	.history-actions {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		gap: 8px 14px;
	}
	.export-error {
		margin: 0 var(--history-gutter) 16px;
	}
	.export-ready {
		display: grid;
		gap: 10px;
		margin: 0 var(--history-gutter) 16px;
		padding: 12px;
		border: 1px solid var(--border);
		border-radius: var(--control-radius);
		background: var(--subtle);
	}
	.export-ready p {
		margin: 0;
		font-size: 13px;
	}
	.include-photos {
		display: flex;
		align-items: center;
		gap: 8px;
		min-height: 44px;
		margin: 0;
	}
	.include-photos input {
		width: 16px;
		height: 16px;
		padding: 0;
		accent-color: var(--primary);
	}
	.date-filter {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(min(100%, 10.25rem), 1fr));
		gap: 14px 16px;
		padding: 16px var(--history-gutter) 18px;
		border-top: 1px solid var(--border);
	}
	.filter-disclosure {
		display: none;
	}
	.filter-status {
		color: var(--primary);
		background: var(--primary-soft);
		padding: 2px 7px;
		border-radius: var(--control-radius);
	}
	@media (max-width: 900px) {
		.filter-disclosure {
			display: block;
			padding: 0 var(--history-gutter) 12px;
		}
		.date-filter:not(.filter-open) {
			display: none;
		}
	}
	.date-filter > div {
		min-width: 0;
	}
	.date-filter input {
		min-width: 0;
		max-width: 100%;
		min-height: 48px;
		padding: 10px 12px;
		font-size: 16px;
	}
	.filter-actions {
		grid-column: 1 / -1;
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		gap: 8px 14px;
	}
	@media (min-width: 1000px) {
		.date-filter {
			grid-template-columns: repeat(2, minmax(0, 11rem)) auto;
			align-items: end;
		}
		.filter-actions {
			grid-column: auto;
		}
	}
	.pagination {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		justify-content: space-between;
		gap: 8px;
		padding: 12px var(--history-gutter);
		border-bottom: 1px solid var(--border);
	}
	.pagination span {
		color: var(--muted);
		font-size: 12px;
	}
	h2 {
		font-size: 18px;
		letter-spacing: -0.4px;
	}
	.history-heading p {
		font-size: 11px;
		margin: 7px 0 0;
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
		display: none;
		overflow-x: auto;
	}
	.history-cards {
		display: grid;
		gap: 12px;
		padding: 14px var(--history-gutter) 18px;
	}
	.history-day {
		border: 1px solid var(--border);
		border-radius: var(--control-radius);
		background: var(--subtle);
	}
	.history-day summary {
		display: grid;
		gap: 10px;
		padding: 14px;
		cursor: pointer;
		list-style: none;
	}
	.history-day summary::-webkit-details-marker {
		display: none;
	}
	.history-day summary:focus-visible {
		outline: 2px solid var(--primary);
		outline-offset: 2px;
	}
	.history-day-heading,
	.history-day-times {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		justify-content: space-between;
		gap: 8px 12px;
	}
	.history-day-times span {
		display: grid;
		gap: 3px;
		min-width: 90px;
		color: var(--muted);
		font-size: 13px;
	}
	.history-day-times strong {
		color: var(--ink);
		font-size: 16px;
	}
	.history-day-toggle {
		display: flex;
		align-items: center;
		gap: 8px;
		color: var(--primary);
		font-size: 13px;
		font-weight: 650;
	}
	.history-day-toggle::after {
		content: '';
		width: 7px;
		height: 7px;
		border: solid currentColor;
		border-width: 0 2px 2px 0;
		transform: rotate(45deg);
	}
	.history-day[open] .history-day-toggle::after {
		transform: rotate(225deg);
	}
	.history-day-details {
		display: grid;
		gap: 10px;
		padding: 12px 14px 14px;
		border-top: 1px solid var(--border);
		font-size: 13px;
		overflow-wrap: anywhere;
	}
	.history-day-details p {
		margin: 0;
	}
	@media (min-width: 901px) {
		.history-cards {
			display: none;
		}
		.table-scroll {
			display: block;
		}
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
		font-size: 12px;
		font-weight: 550;
	}
	td {
		padding: 13px 18px;
		border-top: 1px solid var(--border);
	}
	th:first-child,
	td:first-child {
		padding-left: var(--history-gutter);
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
		gap: 8px;
	}
	.table-location-list {
		display: grid;
		gap: 4px;
		font-size: 11px;
	}
	.table-location-item {
		display: flex;
		align-items: center;
		gap: 5px;
	}
	.location-kind {
		font-weight: 600;
		color: var(--muted);
		font-size: 10px;
	}
	.table-location-link,
	.location-link {
		display: inline-flex;
		align-items: center;
		gap: 3px;
		color: var(--primary);
		text-decoration: underline;
		text-underline-offset: 2px;
	}
	.table-location-link:hover,
	.location-link:hover {
		color: var(--primary-hover, var(--primary));
	}
	.location-acc {
		color: var(--muted);
		font-size: 10px;
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
