import { connectFirestoreEmulator, getFirestore, type Firestore } from 'firebase/firestore';
import { getFirebase } from './client';

let db: Firestore | undefined;

export function getDatabase(): Firestore {
	if (db) return db;
	db = getFirestore(getFirebase().app);
	if (import.meta.env.VITE_FIREBASE_USE_EMULATORS === 'true') {
		connectFirestoreEmulator(db, '127.0.0.1', 8085);
	}
	return db;
}
