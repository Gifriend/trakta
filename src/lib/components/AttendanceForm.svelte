<script lang="ts">
	import { getPreferences } from '#lib/preferences.ts';
	import type {
		AttendanceKind,
		CompressedPhoto,
		PhotoLocation,
		WorkMode
	} from '#lib/types/attendance.ts';
	import { WORK_MODES } from '#lib/types/attendance.ts';
	import { compressPhoto } from '#lib/utils/image.ts';
	import {
		locatePhoto,
		OFFICE_RADIUS_METERS,
		photoLocationIssue
	} from '#lib/utils/photo-location.ts';
	import {
		DEFAULT_PHOTO_EDITS,
		decodePhoto,
		saveEditedPhoto,
		type PhotoEdits
	} from '#lib/utils/photo-editor.ts';
	import { submitAttendance } from '#lib/firebase/attendance.ts';
	import { friendlyError } from '#lib/firebase/auth.ts';
	import Icon from './Icon.svelte';
	import PhotoPicker from './PhotoPicker.svelte';
	import PhotoEditor from './PhotoEditor.svelte';
	let {
		uid,
		kind,
		online,
		onsuccess
	}: { uid: string; kind: AttendanceKind; online: boolean; onsuccess: () => void } = $props();
	let mode = $state<WorkMode>('office');
	let note = $state('');
	let photo = $state.raw<CompressedPhoto | null>(null);
	let photoLocation = $state.raw<PhotoLocation | null>(null);
	const locationIssue = $derived(photoLocation ? photoLocationIssue(photoLocation, mode) : '');
	let originalPhoto = $state.raw<CompressedPhoto | null>(null);
	let photoEdits = $state.raw(DEFAULT_PHOTO_EDITS);
	let editing = $state(false);
	let processing = $state(false);
	let submitting = $state(false);
	let locating = $state(false);
	let error = $state('');
	let cameraActive = $state(false);
	let picker: { openCamera: () => Promise<void>; stopCamera: () => void };
	let selectionVersion = 0;

	async function refreshLocation(): Promise<boolean> {
		if (locating || submitting) return false;
		locating = true;
		error = '';
		try {
			const location = await locatePhoto(mode === 'office' ? 'camera' : 'gallery');
			const issue = photoLocationIssue(location, mode);
			photoLocation = location;
			if (issue) {
				error = issue;
				return false;
			}
			return true;
		} catch (cause) {
			error = friendlyError(cause);
			return false;
		} finally {
			locating = false;
		}
	}

	async function locateCapture() {
		const location = await locatePhoto('camera');
		const issue = photoLocationIssue(location, mode);
		if (issue) throw new Error(issue);
		return location;
	}

	async function choosePhoto(
		file: File,
		frame: PhotoEdits['frame'] = 'none',
		captureLocation?: PhotoLocation
	) {
		const version = ++selectionVersion;
		error = '';
		processing = true;
		try {
			const location = captureLocation ?? (await locatePhoto('gallery'));
			const issue = photoLocationIssue(location, mode);
			if (issue) throw new Error(issue);
			const result = await compressPhoto(file);
			if (version !== selectionVersion) return;
			originalPhoto = result;
			photo = result;
			photoLocation = location;
			photoEdits = DEFAULT_PHOTO_EDITS;
			if (frame !== 'none') {
				const edits = { ...DEFAULT_PHOTO_EDITS, frame };
				const edited = await saveEditedPhoto(await decodePhoto(result.dataUrl), edits);
				if (version === selectionVersion) applyPhoto(edited, edits);
			}
		} catch (cause) {
			if (version === selectionVersion) error = friendlyError(cause);
		} finally {
			if (version === selectionVersion) processing = false;
		}
	}
	async function submit(event: SubmitEvent) {
		event.preventDefault();
		if (!online || submitting || processing || cameraActive || editing || locating) return;
		if (!photo) {
			error = 'Tambahkan foto untuk melengkapi presensimu.';
			return;
		}
		if (!photoLocation || locationIssue) {
			const success = await refreshLocation();
			if (!success || !photoLocation || locationIssue) return;
		}
		submitting = true;
		error = '';
		try {
			await submitAttendance({ uid, kind, mode, note, photo, photoLocation });
			photo = null;
			photoLocation = null;
			originalPhoto = null;
			note = '';
			onsuccess();
		} catch (cause) {
			error = friendlyError(cause);
		} finally {
			submitting = false;
		}
	}
	function applyPhoto(edited: CompressedPhoto, edits: PhotoEdits) {
		photo = edited;
		photoEdits = edits;
		error = '';
	}
	function retake() {
		void picker.openCamera();
		document.getElementById('photo-step')?.scrollIntoView({ block: 'start' });
	}
	export function pauseCamera() {
		picker?.stopCamera();
	}
	const preferences = getPreferences();
	const { t } = preferences;
</script>

<section id="attendance-form" class="card attendance-form" aria-labelledby="attendance-title">
	<div class="section-heading">
		<div>
			<h2 id="attendance-title" tabindex="-1">
				{t(kind === 'checkIn' ? 'Catat presensi masuk' : 'Catat presensi pulang')}
			</h2>
		</div>
		<span class="icon-tile"><Icon name={kind === 'checkIn' ? 'enter' : 'exit'} size={22} /></span>
	</div>
	<form onsubmit={submit}>
		<fieldset disabled={submitting || processing}>
			<legend>{t('Lokasi kerja')}</legend>
			<div class="mode-options">
				{#each Object.entries(WORK_MODES) as [value, text] (value)}<label
						class={{ selected: mode === value }}
						><input type="radio" name="work-mode" {value} bind:group={mode} />{t(text)}</label
					>{/each}
			</div>
		</fieldset>
		<p class="timestamp-note">
			{t(
				mode === 'office'
					? 'Ambil foto langsung dalam radius {radius} m dari Graha Sucofindo.'
					: 'Lokasi perangkat dicatat saat foto diambil atau dipilih.',
				{ radius: String(OFFICE_RADIUS_METERS) }
			)}
		</p>
		<div id="photo-step" class="photo-step">
			<label for="photo">
				{t(photo && !cameraActive ? 'Cek foto presensi' : 'Foto presensi')}
				<span class="required">*</span>
			</label>
			<PhotoPicker
				bind:this={picker}
				{photo}
				{processing}
				disabled={submitting}
				beforeCapture={locateCapture}
				allowGallery={mode !== 'office'}
				onselect={choosePhoto}
				onactivechange={(active) => {
					cameraActive = active;
				}}
			/>
			{#if photo && !cameraActive && !processing}
				<div class="photo-actions">
					<p class="photo-ready" role="status">
						<Icon name="check" size={16} />{t(
							locationIssue
								? 'Lokasi foto tercatat.'
								: !photoLocation
									? 'Foto siap, lokasi belum ada.'
									: 'Foto dan lokasi siap dikirim.'
						)}
					</p>
					<button
						type="button"
						class="button secondary"
						aria-haspopup="dialog"
						disabled={submitting}
						onclick={() => (editing = true)}>{t('Edit foto')}</button
					>
				</div>
			{/if}
			{#if locationIssue || (photo && !photoLocation && !cameraActive)}
				<div class="location-warning-box">
					<p class="notice error" role="alert">
						{t(
							locationIssue || 'Lokasi presensi belum diperoleh.',
							{ radius: String(OFFICE_RADIUS_METERS) }
						)}
					</p>
					<button
						type="button"
						class="button secondary retry-location-btn"
						disabled={locating || submitting}
						onclick={refreshLocation}
					>
						<Icon name="marker" size={16} />
						{t(locating ? 'Memeriksa lokasi…' : 'Minta izin / perbarui lokasi')}
					</button>
				</div>
			{/if}
		</div>
		<label for="note">{t('Catatan')} <span class="optional">{t('(opsional)')}</span></label
		><textarea
			id="note"
			rows="2"
			maxlength="300"
			bind:value={note}
			disabled={submitting}
			placeholder={kind === 'checkIn'
				? t('Apa yang akan kamu kerjakan hari ini?')
				: t('Ada pencapaian yang ingin dicatat?')}></textarea>
		<div class="character-count">{note.length}/300</div>
		{#if error}<p class="notice error" role="alert">
				{t(error, { radius: String(OFFICE_RADIUS_METERS) })}
				{#if photo}{t('Foto dan catatan masih tersedia di formulir ini.')}{/if}
			</p>{/if}
		{#if !online}<p class="notice" role="status">
				{t('Kamu sedang offline. Hubungkan internet untuk mengirim presensi.')}
				{#if photo}{t('Foto dan catatan masih tersedia di formulir ini.')}{/if}
			</p>{/if}
		<div class="confirm-actions">
			{#if photo && !cameraActive}
				<button
					type="button"
					class="button secondary"
					disabled={processing || submitting}
					onclick={retake}
				>
					<Icon name="camera" size={17} />{t('Ambil ulang')}
				</button>
			{/if}
			<button
				type="submit"
				class="button primary submit-attendance"
				disabled={!online ||
					processing ||
					submitting ||
					locating ||
					cameraActive ||
					!photo}
				>{t(
					submitting
						? 'Mengirim presensi…'
						: locating
							? 'Memeriksa lokasi…'
							: kind === 'checkIn'
								? 'Konfirmasi masuk'
								: 'Konfirmasi pulang'
				)}<Icon name="arrow" size={18} /></button
			>
		</div>
		<p class="timestamp-note">
			<Icon name="shield" size={13} />
			{t('Waktu tercatat otomatis saat presensi diterima server.')}
		</p>
	</form>
</section>

{#if editing && originalPhoto}
	<PhotoEditor
		original={originalPhoto}
		initialEdits={photoEdits}
		onapply={applyPhoto}
		onclose={() => (editing = false)}
	/>
{/if}

<style>
	.attendance-form {
		padding: 27px;
	}
	h2 {
		font-size: 21px;
		letter-spacing: -0.5px;
	}
	.photo-step {
		margin: 18px 0 22px;
	}
	.photo-actions {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		justify-content: space-between;
		gap: 8px;
		margin-top: 8px;
	}
	.photo-ready {
		display: flex;
		align-items: center;
		gap: 6px;
		margin: 0;
		color: var(--primary);
		font-size: 13px;
	}
	.photo-step > label,
	label[for='note'] {
		font-size: 14px;
	}
	.icon-tile {
		background: var(--primary-soft);
		color: var(--primary);
		border-radius: 12px;
		padding: 12px;
	}
	fieldset {
		border: 0;
		padding: 0;
		margin: 0 0 24px;
		min-width: 0;
	}
	legend {
		font-weight: 600;
		font-size: 14px;
		margin-bottom: 10px;
	}
	.mode-options {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 8px;
	}
	.mode-options label {
		margin: 0;
		border: 1px solid var(--border);
		border-radius: 7px;
		padding: 12px 8px;
		text-align: center;
		font-size: 13px;
		cursor: pointer;
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 6px;
		min-height: 44px;
	}
	.mode-options label.selected {
		border-color: var(--primary);
		color: var(--primary);
		background: var(--primary-soft);
	}
	.mode-options input {
		width: 12px;
		height: 12px;
		padding: 0;
		margin: 0;
		box-shadow: none;
		accent-color: var(--primary);
	}
	.required {
		color: var(--danger);
	}
	.optional {
		color: var(--muted);
		font-weight: 400;
	}
	textarea {
		resize: vertical;
		min-height: 72px;
		font-size: 12px;
	}
	.location-warning-box {
		display: grid;
		gap: 8px;
		margin-top: 10px;
	}
	.location-warning-box .notice {
		margin: 0;
	}
	.retry-location-btn {
		width: 100%;
		justify-content: center;
		gap: 8px;
		font-size: 13px;
	}
	.character-count {
		text-align: right;
		color: var(--muted);
		font-size: 10px;
		margin-top: 4px;
	}
	.confirm-actions {
		display: flex;
		flex-wrap: wrap;
		gap: 10px;
		margin-top: 15px;
	}
	.confirm-actions .button {
		min-height: 48px;
		font-size: 13px;
	}
	.submit-attendance {
		flex: 1 1 9rem;
		justify-content: space-between;
	}
	.timestamp-note {
		display: flex;
		justify-content: center;
		align-items: center;
		gap: 5px;
		font-size: 12px;
		color: var(--muted);
		margin: 13px 0 0;
		text-align: center;
	}
	@media (max-width: 640px) {
		textarea {
			font-size: 16px;
		}
	}
	@media (max-width: 460px) {
		.attendance-form {
			padding: 20px;
		}
		.mode-options label {
			flex-wrap: wrap;
			padding-inline: 5px;
		}
	}
</style>
