import {
	createUserWithEmailAndPassword,
	sendPasswordResetEmail,
	signInWithEmailAndPassword,
	signOut,
	updateProfile
} from 'firebase/auth';
import { getFirebase } from './client';

export async function login(email: string, password: string) {
	return signInWithEmailAndPassword(getFirebase().auth, email.trim(), password);
}

export async function register(name: string, email: string, password: string) {
	const result = await createUserWithEmailAndPassword(getFirebase().auth, email.trim(), password);
	await updateProfile(result.user, { displayName: name.trim() });
	await result.user.getIdToken(true);
	return result;
}

export function resetPassword(email: string) {
	return sendPasswordResetEmail(getFirebase().auth, email.trim());
}

export function logout() {
	return signOut(getFirebase().auth);
}

export function friendlyError(error: unknown): string {
	const code =
		typeof error === 'object' && error !== null && 'code' in error ? String(error.code) : '';
	const messages: Record<string, string> = {
		'auth/invalid-credential': 'Email atau kata sandi salah. Periksa lalu coba lagi.',
		'auth/user-not-found': 'Email atau kata sandi salah. Periksa lalu coba lagi.',
		'auth/wrong-password': 'Email atau kata sandi salah. Periksa lalu coba lagi.',
		'auth/email-already-in-use': 'Email sudah terdaftar. Silakan masuk.',
		'auth/weak-password': 'Kata sandi terlalu lemah. Gunakan minimal 8 karakter.',
		'auth/password-does-not-meet-requirements':
			'Kata sandi belum memenuhi kebijakan proyek Firebase.',
		'auth/too-many-requests': 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.',
		'auth/network-request-failed': 'Koneksi terputus. Periksa internet lalu coba lagi.',
		'auth/operation-not-allowed': 'Login email belum diaktifkan di Firebase Authentication.',
		'permission-denied':
			'Akses presensi ditolak. Periksa izin akun, tanggal perangkat, atau pengaturan akses aplikasi.',
		unavailable: 'Server belum dapat dihubungi. Periksa koneksi internet lalu coba lagi.'
	};
	return (
		messages[code] ||
		(error instanceof Error ? error.message : 'Terjadi kesalahan. Silakan coba lagi.')
	);
}
