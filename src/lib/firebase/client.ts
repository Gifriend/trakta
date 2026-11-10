import { browser } from '$app/env';
import { getApp, getApps, initializeApp } from 'firebase/app';
import { connectAuthEmulator, getAuth } from 'firebase/auth';

const useEmulators = import.meta.env.VITE_FIREBASE_USE_EMULATORS === 'true';
const config = {
	apiKey: import.meta.env.VITE_FIREBASE_API_KEY || (useEmulators ? 'demo-api-key' : ''),
	authDomain:
		import.meta.env.VITE_FIREBASE_AUTH_DOMAIN ||
		(useEmulators ? 'demo-presensi.firebaseapp.com' : ''),
	projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || (useEmulators ? 'demo-presensi' : ''),
	appId: import.meta.env.VITE_FIREBASE_APP_ID || (useEmulators ? 'demo-app-id' : '')
};

export const firebaseConfigured = Object.values(config).every(Boolean);

let services:
	{ auth: ReturnType<typeof getAuth>; app: ReturnType<typeof initializeApp> } | undefined;

export function getFirebase() {
	if (!browser) throw new Error('Firebase hanya tersedia di browser.');
	if (!firebaseConfigured) throw new Error('Konfigurasi Firebase belum diisi. Ikuti README.md.');
	if (services) return services;
	const app = getApps().length ? getApp() : initializeApp(config);
	const auth = getAuth(app);
	if (useEmulators) {
		connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
	}
	services = { auth, app };
	return services;
}
