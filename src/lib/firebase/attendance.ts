import {
	collection,
	doc,
	getDocFromServer,
	getDocsFromServer,
	limit,
	onSnapshot,
	orderBy,
	query,
	runTransaction,
	serverTimestamp,
	startAfter,
	where,
	type FirestoreError,
	type QueryConstraint,
	type QueryDocumentSnapshot
} from 'firebase/firestore';
import { getFirebase } from './client';
import { getDatabase } from './database';
import type {
	AttendanceDay,
	AttendanceKind,
	CompressedPhoto,
	PhotoLocation,
	WorkMode
} from '#lib/types/attendance.ts';
import { dateKey } from '#lib/utils/date.ts';
import { MAX_PHOTO_BYTES } from '#lib/utils/image.ts';

export type AttendanceRange = { from?: string; to?: string };

function attendanceQuery(uid: string, range?: AttendanceRange) {
	const filters: QueryConstraint[] = [orderBy('dateKey', 'desc')];
	if (range?.from) filters.push(where('dateKey', '>=', range.from));
	if (range?.to) filters.push(where('dateKey', '<=', range.to));
	return query(collection(getDatabase(), 'users', uid, 'attendance'), ...filters);
}

function attendanceDay(entry: QueryDocumentSnapshot): AttendanceDay {
	return { ...entry.data(), id: entry.id } as AttendanceDay;
}

export const ATTENDANCE_PAGE_SIZE = 10;

export async function loadAttendancePage(uid: string, range?: AttendanceRange, before?: string) {
	const base = attendanceQuery(uid, range);
	const pageQuery = before ? query(base, startAfter(before)) : base;
	const snapshot = await getDocsFromServer(query(pageQuery, limit(ATTENDANCE_PAGE_SIZE + 1)));
	return {
		days: snapshot.docs.slice(0, ATTENDANCE_PAGE_SIZE).map(attendanceDay),
		hasNext: snapshot.size > ATTENDANCE_PAGE_SIZE
	};
}

export function watchAttendance(
	uid: string,
	onData: (days: AttendanceDay[]) => void,
	onError: (error: FirestoreError) => void
) {
	return onSnapshot(
		query(attendanceQuery(uid), limit(31)),
		(snapshot) => {
			if (!snapshot.metadata.hasPendingWrites) {
				onData(snapshot.docs.map(attendanceDay));
			}
		},
		onError
	);
}

export async function loadAttendanceForExport(
	uid: string,
	range?: AttendanceRange
): Promise<AttendanceDay[]> {
	const { auth } = getFirebase();
	if (auth.currentUser?.uid !== uid) throw new Error('Sesi berakhir. Silakan masuk kembali.');
	const snapshot = await getDocsFromServer(attendanceQuery(uid, range));
	if (auth.currentUser?.uid !== uid) throw new Error('Sesi berakhir. Silakan masuk kembali.');
	return snapshot.docs.map(attendanceDay);
}

export async function submitAttendance(input: {
	uid: string;
	kind: AttendanceKind;
	mode: WorkMode;
	note: string;
	photo: CompressedPhoto;
	photoLocation: PhotoLocation;
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
		const event = {
			timestamp: serverTimestamp(),
			mode: input.mode,
			note: input.note.trim(),
			photoLocation: input.photoLocation
		};
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

async function loadPhotoBase64(uid: string, key: string, kind: AttendanceKind) {
	const snapshot = await getDocFromServer(
		doc(getDatabase(), 'users', uid, 'attendance', key, 'photos', kind)
	);
	const base64 = snapshot.data()?.base64;
	return typeof base64 === 'string' && base64.trim() ? base64 : null;
}

export async function loadPhoto(uid: string, key: string, kind: AttendanceKind): Promise<string> {
	const base64 = await loadPhotoBase64(uid, key, kind);
	if (base64 === null) throw new Error('Foto tidak ditemukan.');
	return `data:image/jpeg;base64,${base64}`;
}

export async function loadPhotoBlob(uid: string, key: string, kind: AttendanceKind) {
	const base64 = await loadPhotoBase64(uid, key, kind);
	if (base64 === null) return null;
	let decoded: string;
	try {
		decoded = atob(base64);
	} catch {
		return null;
	}
	const bytes = Uint8Array.from(decoded, (character) => character.charCodeAt(0));
	return new Blob([bytes], { type: 'image/jpeg' });
}
