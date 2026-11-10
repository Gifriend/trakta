<script lang="ts">
	import type { AttendanceKind, CompressedPhoto, WorkMode } from '#lib/types/attendance.ts';
	import { WORK_MODES } from '#lib/types/attendance.ts';
	import { compressPhoto } from '#lib/utils/image.ts';
	import { submitAttendance } from '#lib/firebase/attendance.ts';
	import { friendlyError } from '#lib/firebase/auth.ts';
	import Icon from './Icon.svelte';
	import PhotoPicker from './PhotoPicker.svelte';
	let {
		uid,
		kind,
		online,
		onsuccess
	}: { uid: string; kind: AttendanceKind; online: boolean; onsuccess: () => void } = $props();
	let mode = $state<WorkMode>('office');
	let note = $state('');
	let photo = $state.raw<CompressedPhoto | null>(null);
	let processing = $state(false);
	let submitting = $state(false);
	let error = $state('');
	let cameraActive = $state(false);
	let selectionVersion = 0;
	const label = $derived(kind === 'checkIn' ? 'masuk' : 'pulang');

	async function choosePhoto(file: File) {
		const version = ++selectionVersion;
		error = '';
		processing = true;
		try {
			const result = await compressPhoto(file);
			if (version === selectionVersion) photo = result;
		} catch (cause) {
			if (version === selectionVersion) error = friendlyError(cause);
		} finally {
			if (version === selectionVersion) processing = false;
		}
	}
	async function submit(event: SubmitEvent) {
		event.preventDefault();
		if (submitting || processing || cameraActive) return;
		if (!photo) {
			error = 'Tambahkan foto untuk melengkapi presensimu.';
			return;
		}
		submitting = true;
		error = '';
		try {
			await submitAttendance({ uid, kind, mode, note, photo });
			photo = null;
			note = '';
			onsuccess();
		} catch (cause) {
			error = friendlyError(cause);
		} finally {
			submitting = false;
		}
	}
</script>

<section class="card attendance-form" aria-labelledby="attendance-title">
	<div class="section-heading">
		<div>
			<div class="section-kicker">LANGKAH KECIL, KOMITMEN BESAR</div>
			<h2 id="attendance-title">Catat presensi {label}</h2>
		</div>
		<span class="icon-tile"><Icon name={kind === 'checkIn' ? 'enter' : 'exit'} size={22} /></span>
	</div>
	<p class="section-description">
		{kind === 'checkIn'
			? 'Siap memulai hari? Lengkapi presensimu di bawah ini.'
			: 'Terima kasih untuk hari ini. Catat waktu pulangmu.'}
	</p>
	<form onsubmit={submit}>
		<fieldset disabled={submitting || processing}>
			<legend>Lokasi kerja</legend>
			<div class="mode-options">
				{#each Object.entries(WORK_MODES) as [value, text] (value)}<label
						class={{ selected: mode === value }}
						><input type="radio" name="work-mode" {value} bind:group={mode} />{text}</label
					>{/each}
			</div>
		</fieldset>
		<label for="photo">Foto presensi <span class="required">*</span></label>
		<PhotoPicker
			{photo}
			{processing}
			disabled={submitting}
			onselect={choosePhoto}
			onactivechange={(active) => {
				cameraActive = active;
			}}
		/>
		<label for="note">Catatan <span class="optional">(opsional)</span></label><textarea
			id="note"
			rows="2"
			maxlength="300"
			bind:value={note}
			disabled={submitting}
			placeholder={kind === 'checkIn'
				? 'Apa yang akan kamu kerjakan hari ini?'
				: 'Ada pencapaian yang ingin dicatat?'}></textarea>
		<div class="character-count">{note.length}/300</div>
		{#if error}<p class="notice error" role="alert">{error}</p>{/if}
		{#if !online}<p class="notice" role="status">
				Kamu sedang offline. Hubungkan internet untuk mengirim presensi.
			</p>{/if}
		<button
			type="submit"
			class="button primary submit-attendance"
			disabled={!online || processing || submitting || cameraActive || !photo}
			>{submitting ? 'Mengirim presensi…' : `Konfirmasi ${label}`}<Icon
				name="arrow"
				size={18}
			/></button
		>
		<p class="timestamp-note">
			<Icon name="shield" size={13} /> Waktu tercatat otomatis saat presensi diterima server.
		</p>
	</form>
</section>

<style>
	.attendance-form {
		padding: 27px;
	}
	.section-kicker {
		font-size: 9px;
		font-weight: 700;
		letter-spacing: 1.2px;
		color: var(--muted);
		margin-bottom: 9px;
	}
	h2 {
		font-size: 21px;
		letter-spacing: -0.5px;
	}
	.section-description {
		font-size: 12px;
		color: var(--muted);
		margin: 10px 0 24px;
		line-height: 1.7;
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
		font-size: 12px;
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
		font-size: 11px;
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
	.character-count {
		text-align: right;
		color: var(--muted);
		font-size: 10px;
		margin-top: 4px;
	}
	.submit-attendance {
		justify-content: space-between;
		width: 100%;
		margin-top: 15px;
	}
	.timestamp-note {
		display: flex;
		justify-content: center;
		align-items: center;
		gap: 5px;
		font-size: 10px;
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
		.mode-options {
			gap: 5px;
		}
		.mode-options label {
			font-size: 10px;
		}
		.timestamp-note {
			font-size: 9px;
		}
	}
</style>
