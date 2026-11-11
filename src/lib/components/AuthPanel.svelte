<script lang="ts">
	import { login, register, resetPassword, friendlyError } from '#lib/firebase/auth.ts';
	import { firebaseConfigured } from '#lib/firebase/client.ts';
	import Brand from './Brand.svelte';
	import Icon from './Icon.svelte';
	import Preferences from './Preferences.svelte';
	let mode = $state<'login' | 'register' | 'reset'>('login');
	let name = $state('');
	let email = $state('');
	let password = $state('');
	let visible = $state(false);
	let busy = $state(false);
	let error = $state('');
	let message = $state('');

	function changeMode(next: typeof mode) {
		mode = next;
		error = '';
		message = '';
	}
	async function submit(event: SubmitEvent) {
		event.preventDefault();
		if (busy) return;
		busy = true;
		error = '';
		message = '';
		try {
			if (mode === 'register') {
				if (name.trim().length < 2) throw new Error('Nama minimal 2 karakter.');
				await register(name, email, password);
			} else if (mode === 'reset') {
				await resetPassword(email);
				message =
					'Jika email terdaftar, tautan pemulihan akan dikirim. Periksa kotak masuk dan spam.';
			} else await login(email, password);
		} catch (cause) {
			error = friendlyError(cause);
		} finally {
			busy = false;
		}
	}
</script>

<div class="auth-shell">
	<section class="auth-story" aria-label="Tentang Trakta">
		<Brand light />
		<div class="story-content">
			<span class="eyebrow">SETIAP HARI, LEBIH BERARTI</span>
			<h1>Awali hari.<br />Catat kontribusi.</h1>
			<p>Presensi yang sederhana, supaya kamu bisa fokus pada hal yang lebih penting.</p>
			<div class="clock-art" aria-hidden="true">
				<div class="clock-orbit orbit-one"></div>
				<div class="clock-orbit orbit-two"></div>
				<div class="clock-face">
					<span class="clock-tick t1"></span><span class="clock-tick t2"></span><span
						class="clock-tick t3"
					></span><span class="clock-tick t4"></span><span class="hand hour"></span><span
						class="hand minute"
					></span><span class="clock-center"></span>
				</div>
				<span class="art-tag"><Icon name="check" size={17} /> Satu langkah, sudah tercatat.</span>
			</div>
		</div>
		<div class="story-footer">
			<Icon name="shield" size={18} /> Ruang presensi pribadi untuk aktivitas harianmu.
		</div>
	</section>
	<main id="main" class="auth-main">
		<div class="auth-toolbar">
			<div class="mobile-brand"><Brand /></div>
			<Preferences />
		</div>
		<div class="auth-form-wrap">
			<span class="mini-label">RUANG KERJAMU, LEBIH TERATUR</span>
			<h2>
				{mode === 'register'
					? 'Mari mulai hari baik.'
					: mode === 'reset'
						? 'Lupa kata sandi?'
						: 'Selamat datang kembali.'}
			</h2>
			<p class="muted">
				{mode === 'register'
					? 'Buat akun untuk mencatat presensi pertamamu.'
					: mode === 'reset'
						? 'Kami bantu kamu mengakses akun kembali.'
						: 'Masuk untuk mencatat kehadiranmu hari ini.'}
			</p>
			{#if !firebaseConfigured}<div class="notice setup-notice">
					<Icon name="info" />
					<div>
						<strong>Satu langkah sebelum mulai</strong>
						<p>
							Isi konfigurasi Firebase di <code>.env</code> sesuai panduan <code>README.md</code>,
							lalu jalankan ulang aplikasi.
						</p>
					</div>
				</div>{/if}
			<form onsubmit={submit}>
				{#if mode === 'register'}<label for="name">Nama lengkap</label><input
						id="name"
						autocomplete="name"
						bind:value={name}
						required
						minlength="2"
						maxlength="80"
						placeholder="Nama yang ingin ditampilkan"
						disabled={busy}
					/>{/if}
				<label for="email">Alamat email</label>
				<div class="input-icon">
					<Icon name="mail" size={19} /><input
						id="email"
						type="email"
						autocomplete="email"
						bind:value={email}
						required
						placeholder="nama@perusahaan.com"
						disabled={busy}
					/>
				</div>
				{#if mode !== 'reset'}<div class="label-row">
						<label for="password">Kata sandi</label>{#if mode === 'login'}<button
								type="button"
								class="text-button"
								onclick={() => changeMode('reset')}
								disabled={busy}>Lupa kata sandi?</button
							>{/if}
					</div>
					<div class="password-input">
						<input
							id="password"
							type={visible ? 'text' : 'password'}
							autocomplete={mode === 'register' ? 'new-password' : 'current-password'}
							bind:value={password}
							required
							minlength={mode === 'register' ? 8 : 1}
							placeholder={mode === 'register' ? 'Minimal 8 karakter' : 'Masukkan kata sandi'}
							disabled={busy}
						/><button
							type="button"
							class="icon-button"
							aria-label={visible ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi'}
							aria-pressed={visible}
							onclick={() => (visible = !visible)}><Icon name="eye" size={19} /></button
						>
					</div>{/if}
				{#if error}<p class="notice error" role="alert">{error}</p>{/if}
				{#if message}<p class="notice success" role="status">{message}</p>{/if}
				<button
					type="submit"
					class="button primary auth-submit"
					disabled={busy || !firebaseConfigured}
					>{busy
						? 'Mohon tunggu…'
						: mode === 'register'
							? 'Buat akun'
							: mode === 'reset'
								? 'Kirim tautan pemulihan'
								: 'Masuk ke ruang kerja'}<Icon name="arrow" size={19} /></button
				>
			</form>
			<p class="auth-switch">
				{mode === 'login' ? 'Belum punya akun?' : 'Sudah punya akun?'}
				<button
					type="button"
					class="text-button"
					disabled={busy}
					onclick={() => changeMode(mode === 'login' ? 'register' : 'login')}
					>{mode === 'login' ? 'Daftar sekarang' : 'Masuk di sini'}</button
				>
			</p>
			<div class="auth-assurance">
				<Icon name="shield" size={16} /> Terhubung dengan Firebase Authentication
			</div>
		</div>
		<div class="auth-bottom">Awali hari dengan tujuan. Pulang dengan pencapaian.</div>
	</main>
</div>

<style>
	.auth-shell {
		min-height: 100svh;
		display: grid;
		grid-template-columns: 46% 54%;
	}
	.auth-story {
		background: var(--forest);
		color: white;
		padding: 42px 9%;
		display: flex;
		flex-direction: column;
		position: relative;
		overflow: hidden;
	}
	.story-content {
		margin: auto 0;
		padding-top: 60px;
	}
	.eyebrow {
		color: var(--lime);
		font-size: 11px;
		font-weight: 650;
		letter-spacing: 2px;
	}
	h1 {
		font-size: clamp(40px, 4.4vw, 68px);
		line-height: 1.1;
		letter-spacing: -2.7px;
		font-weight: 550;
		margin: 22px 0;
	}
	.story-content > p {
		max-width: 340px;
		color: #b9d1cc;
		line-height: 1.8;
	}
	.story-footer {
		color: #b9d1cc;
		font-size: 12px;
		display: flex;
		align-items: center;
		gap: 9px;
		padding: 25px 0 0;
	}
	.clock-art {
		height: 290px;
		position: relative;
		display: grid;
		place-items: center;
		margin: 20px 0;
	}
	.clock-orbit {
		position: absolute;
		border: 1px solid #ffffff12;
		width: 300px;
		height: 300px;
		border-radius: 50%;
	}
	.orbit-two {
		width: 380px;
		height: 380px;
	}
	.clock-face {
		width: 196px;
		height: 196px;
		border-radius: 50%;
		background: #f4f6e9;
		box-shadow: 0 20px 40px #001c1920;
		position: relative;
		transform: rotate(-10deg);
	}
	.clock-tick {
		position: absolute;
		background: #aac0b4;
		border-radius: 5px;
	}
	.t1,
	.t3 {
		width: 3px;
		height: 12px;
		left: calc(50% - 1px);
	}
	.t1 {
		top: 15px;
	}
	.t3 {
		bottom: 15px;
	}
	.t2,
	.t4 {
		width: 12px;
		height: 3px;
		top: calc(50% - 1px);
	}
	.t2 {
		right: 15px;
	}
	.t4 {
		left: 15px;
	}
	.hand {
		background: var(--forest);
		position: absolute;
		left: calc(50% - 3px);
		bottom: 50%;
		border-radius: 6px;
		transform-origin: bottom center;
	}
	.hour {
		height: 46px;
		width: 6px;
		transform: rotate(-48deg);
	}
	.minute {
		height: 64px;
		width: 4px;
		transform: rotate(48deg);
	}
	.clock-center {
		position: absolute;
		width: 12px;
		height: 12px;
		background: var(--primary);
		border-radius: 50%;
		top: calc(50% - 6px);
		left: calc(50% - 6px);
	}
	.art-tag {
		position: absolute;
		bottom: 14px;
		right: -8px;
		display: flex;
		align-items: center;
		gap: 8px;
		background: var(--lime);
		color: var(--forest);
		padding: 12px 16px;
		font-size: 12px;
		border-radius: 8px;
		box-shadow: 0 8px 32px #0002;
		transform: rotate(-4deg);
	}
	.auth-main {
		background: var(--surface);
		display: flex;
		flex-direction: column;
		justify-content: center;
		align-items: center;
		padding: 56px;
	}
	.auth-form-wrap {
		width: 100%;
		max-width: 410px;
		margin: auto 0;
		padding: 55px 0;
	}
	.auth-toolbar {
		width: 100%;
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		justify-content: space-between;
		gap: 12px;
	}
	.mini-label {
		color: var(--primary);
		font-size: 10px;
		letter-spacing: 1.7px;
		font-weight: 750;
	}
	h2 {
		margin: 15px 0 10px;
		font-size: 31px;
		line-height: 1.25;
		letter-spacing: -1px;
		font-weight: 650;
	}
	.auth-form-wrap > p {
		font-size: 14px;
	}
	form {
		margin-top: 32px;
	}
	label {
		margin-top: 21px;
	}
	.label-row {
		display: flex;
		align-items: end;
		justify-content: space-between;
		gap: 8px;
	}
	.label-row label {
		margin-bottom: 8px;
	}
	.label-row .text-button {
		font-size: 12px;
		margin-bottom: 0;
	}
	.input-icon,
	.password-input {
		position: relative;
	}
	.input-icon > :global(svg) {
		position: absolute;
		left: 14px;
		top: 16px;
		color: var(--muted);
	}
	.input-icon input {
		padding-left: 43px;
	}
	.password-input input {
		padding-right: 48px;
	}
	.password-input .icon-button {
		position: absolute;
		right: 3px;
		top: 3px;
	}
	.auth-submit {
		width: 100%;
		justify-content: space-between;
		margin-top: 26px;
		min-height: 52px;
	}
	.auth-switch {
		text-align: center;
		margin-top: 22px;
		color: var(--muted);
	}
	.auth-assurance {
		border-top: 1px solid var(--border);
		padding-top: 23px;
		margin-top: 30px;
		color: var(--muted);
		display: flex;
		justify-content: center;
		gap: 7px;
		font-size: 11px;
	}
	.auth-bottom {
		color: var(--muted);
		font-size: 11px;
	}
	.setup-notice {
		margin-top: 24px;
		display: flex;
		gap: 10px;
		font-size: 12px;
	}
	.setup-notice :global(svg) {
		flex-shrink: 0;
	}
	.setup-notice p {
		margin: 5px 0 0;
		line-height: 1.7;
	}
	.mobile-brand {
		display: none;
	}
	@media (max-width: 800px) {
		.auth-shell {
			grid-template-columns: 1fr;
		}
		.auth-story {
			display: none;
		}
		.auth-main {
			padding: 30px 24px;
			min-height: 100svh;
		}
		.mobile-brand {
			display: block;
			align-self: flex-start;
		}
		.auth-form-wrap {
			padding: 50px 0;
		}
		h2 {
			font-size: 29px;
		}
	}
</style>
