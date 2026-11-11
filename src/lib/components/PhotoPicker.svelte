<script lang="ts">
	import { getPreferences } from '#lib/preferences.ts';
	import { onMount, tick } from 'svelte';
	import type { CompressedPhoto } from '#lib/types/attendance.ts';
	import { CAMERA_EFFECTS, drawCameraFrame, type CameraEffect } from '#lib/utils/camera.ts';
	import Icon from './Icon.svelte';
	import LoadingSkeleton from './LoadingSkeleton.svelte';

	let {
		photo,
		processing,
		disabled,
		onselect,
		onactivechange
	}: {
		photo: CompressedPhoto | null;
		processing: boolean;
		disabled: boolean;
		onselect: (file: File) => Promise<void>;
		onactivechange: (active: boolean) => void;
	} = $props();

	let cameraState = $state<'closed' | 'starting' | 'live'>('closed');
	let cameraError = $state('');
	let frameReady = $state(false);
	let taking = $state(false);
	let effect = $state<CameraEffect>('natural');
	let correctMirroring = $state(false);
	let video = $state<HTMLVideoElement>();
	let fileInput: HTMLInputElement;
	let stream: MediaStream | undefined;
	let correctionKey = 'trakta.cameraCorrection';
	let requestVersion = 0;
	let destroyed = false;

	function stopCamera() {
		requestVersion++;
		stream?.getTracks().forEach((track) => track.stop());
		stream = undefined;
		if (video) video.srcObject = null;
		cameraState = 'closed';
		frameReady = false;
		onactivechange(false);
	}

	function cameraMessage(cause: unknown): string {
		const name = cause instanceof DOMException ? cause.name : '';
		if (name === 'NotAllowedError' || name === 'SecurityError') {
			return 'Izin kamera belum diberikan. Izinkan kamera melalui pengaturan browser atau pilih foto dari galeri/file.';
		}
		if (name === 'NotFoundError' || name === 'OverconstrainedError') {
			return 'Kamera tidak ditemukan. Hubungkan kamera atau pilih foto dari galeri/file.';
		}
		if (name === 'NotReadableError' || name === 'AbortError') {
			return 'Kamera belum dapat dibuka. Tutup aplikasi lain yang memakai kamera, lalu coba lagi atau pilih galeri/file.';
		}
		return 'Kamera belum dapat digunakan. Coba buka kembali atau pilih foto dari galeri/file.';
	}

	async function openCamera() {
		if (disabled || processing || taking || destroyed || document.hidden) return;
		stopCamera();
		cameraError = '';
		if (!window.isSecureContext || !navigator.mediaDevices?.getUserMedia) {
			cameraError =
				'Kamera langsung memerlukan browser yang mendukung dan koneksi HTTPS atau localhost. Kamu tetap bisa memilih foto dari galeri/file.';
			return;
		}
		const version = requestVersion;
		cameraState = 'starting';
		onactivechange(true);
		try {
			const nextStream = await navigator.mediaDevices.getUserMedia({
				audio: false,
				video: {
					facingMode: { ideal: 'user' },
					width: { ideal: 1280, max: 1920 },
					height: { ideal: 960, max: 1920 }
				}
			});
			if (version !== requestVersion || destroyed || document.hidden) {
				nextStream.getTracks().forEach((track) => track.stop());
				if (version === requestVersion && !destroyed) stopCamera();
				return;
			}
			stream = nextStream;
			const deviceId = stream.getVideoTracks()[0]?.getSettings().deviceId;
			correctionKey = deviceId ? `trakta.cameraCorrection.${deviceId}` : 'trakta.cameraCorrection';
			correctMirroring = false;
			try {
				correctMirroring = localStorage.getItem(correctionKey) === 'true';
			} catch {
				// Use the original camera frame when storage is unavailable.
			}
			await tick();
			if (version !== requestVersion || !video) return;
			video.srcObject = nextStream;
			await video.play();
			if (version !== requestVersion) return;
			cameraState = 'live';
			frameReady = video.videoWidth > 0 && video.videoHeight > 0;
		} catch (cause) {
			if (version !== requestVersion || destroyed) return;
			stopCamera();
			cameraError = cameraMessage(cause);
		}
	}

	function changeOrientation(corrected: boolean) {
		correctMirroring = corrected;
		try {
			localStorage.setItem(correctionKey, String(corrected));
		} catch {
			// The correction still applies to this capture.
		}
	}

	async function takePhoto() {
		if (!video || !frameReady || disabled || processing || taking) return;
		taking = true;
		cameraError = '';
		const version = requestVersion;
		try {
			const canvas = document.createElement('canvas');
			canvas.width = video.videoWidth;
			canvas.height = video.videoHeight;
			const context = canvas.getContext('2d');
			if (!context) throw new Error('Canvas unavailable');
			drawCameraFrame(context, video, effect, correctMirroring);
			const blob = await new Promise<Blob>((resolve, reject) => {
				canvas.toBlob(
					(value) => (value ? resolve(value) : reject(new Error('Capture failed'))),
					'image/jpeg',
					0.95
				);
			});
			if (version !== requestVersion || destroyed) return;
			stopCamera();
			await onselect(new File([blob], `presensi-kamera-${Date.now()}.jpg`, { type: 'image/jpeg' }));
		} catch {
			if (!destroyed && version === requestVersion)
				cameraError = 'Foto belum berhasil diambil. Coba lagi atau pilih galeri/file.';
		} finally {
			taking = false;
		}
	}

	function openGallery() {
		stopCamera();
		cameraError = '';
		fileInput.click();
	}

	async function chooseFile(event: Event) {
		const input = event.currentTarget as HTMLInputElement;
		const file = input.files?.[0];
		if (!file) return;
		stopCamera();
		cameraError = '';
		try {
			await onselect(file);
		} finally {
			input.value = '';
		}
	}

	onMount(() => {
		void openCamera();
		return () => {
			destroyed = true;
			stopCamera();
		};
	});
	const preferences = getPreferences();
	const { t } = preferences;
</script>

<svelte:document
	onvisibilitychange={() => {
		if (document.hidden) stopCamera();
	}}
/>

<div class="photo-picker">
	<div
		class={[
			'photo-frame',
			{ 'has-photo': photo && cameraState === 'closed', 'camera-open': cameraState !== 'closed' }
		]}
	>
		{#if cameraState !== 'closed'}
			<video
				bind:this={video}
				autoplay
				playsinline
				muted
				class:corrected={correctMirroring}
				style:filter={CAMERA_EFFECTS[effect].filter}
				aria-label={t('Pratinjau kamera presensi')}
				onloadeddata={(event) => {
					frameReady = event.currentTarget.videoWidth > 0 && event.currentTarget.videoHeight > 0;
				}}
			></video>
			<button
				type="button"
				class="icon-button close-camera"
				aria-label={t('Tutup kamera')}
				onclick={stopCamera}><Icon name="close" /></button
			>
			{#if cameraState === 'starting'}<div class="camera-loading">
					<LoadingSkeleton
						variant="photo"
						label={t('Membuka kamera… Izinkan akses jika diminta.')}
					/>
					<span aria-hidden="true">{t('Membuka kamera… Izinkan akses jika diminta.')}</span>
				</div>{/if}
			<button
				type="button"
				class="button primary shutter"
				disabled={!frameReady || cameraState !== 'live' || disabled || processing || taking}
				onclick={takePhoto}
				><Icon name="camera" size={18} />{taking
					? t('Mengambil foto kamera…')
					: t('Ambil foto')}</button
			>
		{:else if photo}
			<img
				src={photo.dataUrl}
				width={photo.width}
				height={photo.height}
				alt={t('Pratinjau foto presensi yang akan dikirim')}
			/>
			<span class="photo-size"
				><Icon name="check" size={14} /> {(photo.bytes / 1000).toFixed(1)} KB</span
			>
		{:else}
			<div class="upload-icon"><Icon name="camera" size={25} /></div>
			<strong>{processing ? t('Menyiapkan fotomu…') : t('Foto untuk presensimu')}</strong>
			<p>{t('Ambil foto langsung atau pilih dari perangkatmu.')}</p>
		{/if}
	</div>
	{#if cameraState === 'live'}
		<div class="camera-effect">
			<label for="camera-effect">{t('Efek kamera')}</label>
			<select
				id="camera-effect"
				value={effect}
				disabled={disabled || taking}
				onchange={(event) => (effect = event.currentTarget.value as CameraEffect)}
			>
				{#each Object.entries(CAMERA_EFFECTS) as [value, setting] (value)}
					<option {value}>{t(setting.label)}</option>
				{/each}
			</select>
		</div>
		<div class="camera-orientation">
			<label>
				<input
					type="checkbox"
					checked={correctMirroring}
					disabled={disabled || taking}
					aria-describedby="camera-orientation-help"
					onchange={(event) => changeOrientation(event.currentTarget.checked)}
				/>
				{t('Koreksi kiri-kanan')}
			</label>
			<p id="camera-orientation-help" class="field-help">
				{t('Aktifkan jika tulisan di kamera terlihat terbalik.')}
			</p>
		</div>
	{/if}
	<div class="source-options">
		<button
			type="button"
			class="button secondary"
			onclick={openCamera}
			disabled={disabled || processing || taking || cameraState !== 'closed'}
			><Icon name="camera" size={16} />{cameraState === 'starting'
				? t('Membuka kamera…')
				: cameraState === 'live'
					? t('Kamera aktif')
					: t('Buka kamera')}</button
		>
		<button
			type="button"
			class="button secondary"
			onclick={openGallery}
			disabled={disabled || processing || taking}
			><Icon name="image" size={16} />{t('Pilih galeri/file')}</button
		>
	</div>
	<input
		bind:this={fileInput}
		id="photo"
		class="file-input"
		type="file"
		accept="image/jpeg,image/png,image/webp"
		onclick={stopCamera}
		onchange={chooseFile}
		disabled={disabled || processing || taking}
		aria-label={t('Pilih atau ambil foto presensi')}
		aria-describedby="photo-help"
	/>
	{#if cameraError}<p class="notice camera-error" role="alert">{t(cameraError)}</p>{/if}
	<p id="photo-help" class="field-help">
		<Icon name="image" size={13} />
		{t('JPG, PNG, WebP · Otomatis diperkecil hingga 100 KB')}
	</p>
</div>

<style>
	.photo-picker {
		position: relative;
	}
	.photo-frame {
		border: 1px dashed var(--control-border);
		border-radius: 10px;
		background: var(--subtle);
		min-height: 214px;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		position: relative;
		padding: 22px;
		overflow: hidden;
	}
	.upload-icon {
		color: var(--primary);
		background: var(--primary-soft);
		padding: 12px;
		border-radius: 50%;
		margin-bottom: 12px;
	}
	.photo-frame strong {
		font-size: 12px;
	}
	.photo-frame p {
		font-size: 11px;
		color: var(--muted);
		margin: 8px 0 0;
		text-align: center;
		line-height: 1.6;
	}
	.has-photo,
	.camera-open {
		padding: 0;
		border-style: solid;
	}
	.has-photo img {
		width: 100%;
		height: 260px;
		object-fit: contain;
	}
	.camera-open {
		min-height: 300px;
		background: #14251f;
		border-color: #14251f;
	}
	video {
		display: block;
		width: 100%;
		height: 300px;
		object-fit: contain;
		transform: none;
	}
	video.corrected {
		transform: scaleX(-1);
	}
	.close-camera {
		position: absolute;
		top: 10px;
		right: 10px;
		color: white;
		background: #14251fcc;
		z-index: 2;
	}
	.close-camera:hover {
		background: var(--forest);
		color: white;
	}
	.camera-loading {
		--skeleton-fill: #52635d;
		--skeleton-panel-height: 105px;
		position: absolute;
		inset: 60px 20px 80px;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		gap: 14px;
		text-align: center;
		color: white;
		font-size: 12px;
		line-height: 1.6;
		pointer-events: none;
	}
	.camera-effect {
		display: flex;
		align-items: center;
		justify-content: space-between;
		flex-wrap: wrap;
		gap: 8px;
		margin: 10px 0 0;
	}
	.camera-effect select {
		min-height: 44px;
		border: 1px solid var(--control-border);
		border-radius: var(--control-radius);
		background: var(--surface);
		color: var(--ink);
		padding: 8px;
		font-size: 13px;
	}
	.camera-effect label {
		margin: 0;
	}
	.camera-orientation {
		margin-top: 4px;
	}
	.camera-orientation label {
		display: flex;
		align-items: center;
		gap: 9px;
		min-height: 44px;
		width: fit-content;
		margin: 0;
		cursor: pointer;
	}
	.camera-orientation input {
		width: 16px;
		height: 16px;
		padding: 0;
		accent-color: var(--primary);
	}
	.camera-orientation .field-help {
		margin-top: 0;
	}
	.shutter {
		position: absolute;
		bottom: 14px;
		left: 50%;
		transform: translateX(-50%);
		white-space: nowrap;
		min-height: 44px;
	}
	.photo-size {
		position: absolute;
		bottom: 10px;
		left: 10px;
		background: var(--primary-soft);
		color: var(--primary);
		display: flex;
		align-items: center;
		gap: 5px;
		padding: 8px 10px;
		border-radius: 6px;
		font-size: 11px;
	}
	.source-options {
		display: flex;
		flex-wrap: wrap;
		gap: 8px;
		margin-top: 10px;
	}
	.source-options .button {
		flex: 1;
		min-height: 44px;
		font-size: 11px;
		padding: 11px;
		white-space: nowrap;
	}
	.file-input {
		position: absolute;
		width: 1px;
		height: 1px;
		opacity: 0;
		padding: 0;
		bottom: 0;
		left: 50%;
	}
	.photo-picker:has(.file-input:focus-visible) {
		outline: 3px solid var(--ring);
		outline-offset: 3px;
		border-radius: 10px;
	}
	.field-help {
		color: var(--muted);
		font-size: 10px;
		display: flex;
		align-items: center;
		gap: 5px;
		margin: 10px 0 24px;
		line-height: 1.6;
	}
	.field-help :global(svg) {
		flex-shrink: 0;
	}
	.camera-error {
		font-size: 12px;
		margin: 12px 0;
	}
	@media (max-width: 460px) {
		.source-options .button {
			font-size: 10px;
		}
	}
</style>
