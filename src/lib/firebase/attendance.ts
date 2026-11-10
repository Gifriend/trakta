import {
	collection,
	doc,
	getDocFromServer,
	limit,
	onSnapshot,
	orderBy,
	query,
	runTransaction,
	serverTimestamp,
	type FirestoreError
} from 'firebase/firestore';
import { getFirebase } from './client';
import { getDatabase } from './database';
import type {
	AttendanceDay,
	AttendanceKind,
	CompressedPhoto,
	WorkMode
} from '#lib/types/attendance.ts';
import { dateKey } from '#lib/utils/date.ts';
import { MAX_PHOTO_BYTES } from '#lib/utils/image.ts';

export function watchAttendance(
	uid: string,
	onData: (days: AttendanceDay[]) => void,
	onError: (error: FirestoreError) => void
) {
	const db = getDatabase();
	return onSnapshot(
		query(collection(db, 'users', uid, 'attendance'), orderBy('dateKey', 'desc'), limit(31)),
		(snapshot) => {
			if (!snapshot.metadata.hasPendingWrites) {
				onData(snapshot.docs.map((entry) => ({ ...entry.data(), id: entry.id }) as AttendanceDay));
			}
		},
		onError
	);
}

export async function submitAttendance(input: {
	uid: string;
	kind: AttendanceKind;
	mode: WorkMode;
	note: string;
	photo: CompressedPhoto;
}) {
	if (!navigator.onLine) throw new Error('Hubungkan internet untuk mengirim presensi.');
	if (input.photo.bytes > MAX_PHOTO_BYTES || input.photo.bytes <= 0) {
		throw new Error('Foto harus berukuran maksimal 100 KB.');
	}
	const { auth } = getFirebase();
	const db = getDatabase();
	if (auth.currentUser?.uid !== input.uid) throw new Error('Sesi berakhir. Silakan masuk kembali.');
	const key = dateKey();
	const dayRef = doc(db, 'users', input.uid, 'attendance', key);
	const photoRef = doc(dayRef, 'photos', input.kind);
	await runTransaction(db, async (transaction) => {
		const snapshot = await transaction.get(dayRef);
		const day = snapshot.data() as Omit<AttendanceDay, 'id'> | undefined;
		if (day?.[input.kind])
			throw new Error(
				`Presensi ${input.kind === 'checkIn' ? 'masuk' : 'pulang'} hari ini sudah tercatat.`
			);
		if (input.kind === 'checkOut' && !day?.checkIn)
			throw new Error('Catat presensi masuk terlebih dahulu.');
		const event = { timestamp: serverTimestamp(), mode: input.mode, note: input.note.trim() };
		if (input.kind === 'checkIn') transaction.set(dayRef, { dateKey: key, checkIn: event });
		else transaction.update(dayRef, { checkOut: event });
		transaction.set(photoRef, {
			base64: input.photo.base64,
			bytes: input.photo.bytes,
			mimeType: 'image/jpeg',
			createdAt: serverTimestamp()
		});
	});
}

export async function loadPhoto(uid: string, key: string, kind: AttendanceKind): Promise<string> {
	const snapshot = await getDocFromServer(
		doc(getDatabase(), 'users', uid, 'attendance', key, 'photos', kind)
	);
	if (!snapshot.exists()) throw new Error('Foto tidak ditemukan.');
	return `data:image/jpeg;base64,${snapshot.data().base64}`;
}
