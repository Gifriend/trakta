import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, test } from 'node:test';
import {
	initializeTestEnvironment,
	assertFails,
	assertSucceeds
} from '@firebase/rules-unit-testing';
import {
	collection,
	doc,
	getDoc,
	getDocs,
	orderBy,
	query,
	serverTimestamp,
	setDoc,
	updateDoc,
	deleteDoc,
	writeBatch,
	Timestamp
} from 'firebase/firestore';

let env;
const key = () =>
	new Intl.DateTimeFormat('en-GB', {
		timeZone: 'Asia/Jakarta',
		year: 'numeric',
		month: '2-digit',
		day: '2-digit'
	})
		.formatToParts(new Date())
		.filter((p) => ['day', 'month', 'year'].includes(p.type))
		.reverse()
		.map((p) => p.value)
		.join('');
const day = (db, uid = 'alice', date = key()) => doc(db, 'users', uid, 'attendance', date);
const event = () => ({ timestamp: serverTimestamp(), mode: 'office', note: 'Daily work' });
const photo = (bytes = 3) => ({
	base64: Buffer.alloc(bytes).toString('base64'),
	bytes,
	mimeType: 'image/jpeg',
	createdAt: serverTimestamp()
});
function record(db, kind = 'checkIn', options = {}) {
	const ref = day(db, options.uid, options.date);
	const batch = writeBatch(db);
	if (kind === 'checkIn')
		batch.set(ref, { dateKey: options.date || key(), checkIn: { ...event(), ...options.event } });
	else batch.update(ref, { checkOut: { ...event(), ...options.event } });
	batch.set(doc(ref, 'photos', kind), { ...photo(), ...options.photo });
	return batch.commit();
}
before(async () => {
	env = await initializeTestEnvironment({
		projectId: 'demo-presensi',
		firestore: { host: '127.0.0.1', port: 8085, rules: await readFile('firestore.rules', 'utf8') }
	});
});
beforeEach(async () => {
	await env.clearFirestore();
});
after(async () => {
	await env?.cleanup();
});

test('owner can check in, list history, and check out with server timestamps', async () => {
	const db = env.authenticatedContext('alice').firestore();
	await assertSucceeds(record(db));
	await assertSucceeds(
		getDocs(query(collection(db, 'users/alice/attendance'), orderBy('dateKey', 'desc')))
	);
	await assertSucceeds(record(db, 'checkOut'));
	await assertSucceeds(getDoc(doc(day(db), 'photos/checkOut')));
});
test('unauthenticated users and other accounts cannot read or write personal data', async () => {
	const alice = env.authenticatedContext('alice').firestore();
	await record(alice);
	const bob = env.authenticatedContext('bob').firestore();
	const guest = env.unauthenticatedContext().firestore();
	await assertFails(getDoc(day(bob)));
	await assertFails(getDoc(doc(day(bob), 'photos/checkIn')));
	await assertFails(record(bob));
	await assertFails(getDoc(day(guest)));
	await assertFails(record(guest));
});
test('checkout requires a checkin, and an event requires its photo atomically', async () => {
	const db = env.authenticatedContext('alice').firestore();
	const batch = writeBatch(db);
	batch.set(day(db), { dateKey: key(), checkOut: event() });
	batch.set(doc(day(db), 'photos/checkOut'), photo());
	await assertFails(batch.commit());
	await assertFails(setDoc(day(db), { dateKey: key(), checkIn: event() }));
	await assertFails(setDoc(doc(day(db), 'photos/checkIn'), photo()));
});
test('recorded attendance and photos cannot be overwritten or deleted', async () => {
	const db = env.authenticatedContext('alice').firestore();
	await record(db);
	await assertFails(record(db));
	await assertFails(updateDoc(day(db), { 'checkIn.note': 'Rewritten' }));
	await assertFails(deleteDoc(day(db)));
	await assertFails(deleteDoc(doc(day(db), 'photos/checkIn')));
	await record(db, 'checkOut');
	await assertFails(record(db, 'checkOut'));
});
test('client-chosen timestamps and a different attendance date are rejected', async () => {
	const db = env.authenticatedContext('alice').firestore();
	await assertFails(record(db, 'checkIn', { event: { timestamp: Timestamp.fromMillis(0) } }));
	await assertFails(record(db, 'checkIn', { date: '20200101' }));
});
test('photo size is derived from base64 and capped at 100000 decoded bytes', async () => {
	const db = env.authenticatedContext('alice').firestore();
	await assertFails(record(db, 'checkIn', { photo: photo(100001) }));
	await assertFails(record(db, 'checkIn', { photo: { ...photo(100001), bytes: 10 } }));
	await assertSucceeds(record(db, 'checkIn', { photo: photo(100000) }));
});
test('invalid modes, extra fields, and oversized notes are rejected', async () => {
	const db = env.authenticatedContext('alice').firestore();
	await assertFails(record(db, 'checkIn', { event: { mode: 'fake' } }));
	await assertFails(record(db, 'checkIn', { event: { note: 'x'.repeat(301) } }));
	await assertFails(record(db, 'checkIn', { event: { admin: true } }));
});
