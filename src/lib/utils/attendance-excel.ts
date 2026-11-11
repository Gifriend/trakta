import writeExcelFile, { type Image, type Row } from 'write-excel-file/browser';
import { translate, type Locale } from '#lib/i18n.ts';
import { loadPhotoBlob } from '#lib/firebase/attendance.ts';
import { WORK_MODES, type AttendanceDay, type AttendanceKind } from '#lib/types/attendance.ts';
import { dateFromKey, dateKey, TIME_ZONE } from './date';

const secondsPerDay = 86_400;
const millisecondsPerDay = secondsPerDay * 1000;
const excelEpoch = Date.UTC(1899, 11, 30);
const jakartaClock = new Intl.DateTimeFormat('en-GB', {
	timeZone: TIME_ZONE,
	hourCycle: 'h23',
	hour: '2-digit',
	minute: '2-digit',
	second: '2-digit'
});

const columns = [
	{ label: 'Tanggal', width: 15 },
	{ label: 'Masuk (WIB)', width: 18 },
	{ label: 'Pulang (WIB)', width: 18 },
	{ label: 'Durasi', width: 14 },
	{ label: 'Status', width: 17 },
	{ label: 'Lokasi kerja masuk', width: 22 },
	{ label: 'Lokasi kerja pulang', width: 22 },
	{ label: 'Catatan masuk', width: 42 },
	{ label: 'Catatan pulang', width: 42 }
];
const photoColumns = [
	{ label: 'Foto masuk', width: 20 },
	{ label: 'Foto pulang', width: 20 }
];

function timeCell(date?: Date) {
	if (!date) return null;
	const [hours, minutes, seconds] = jakartaClock.format(date).split(':').map(Number);
	return {
		value: (hours * 3600 + minutes * 60 + seconds) / secondsPerDay,
		format: 'hh:mm:ss'
	};
}

async function loadExcelPhoto(
	uid: string,
	key: string,
	kind: AttendanceKind,
	row: number,
	column: number,
	title: string
): Promise<Image | null> {
	const content = await loadPhotoBlob(uid, key, kind);
	if (!content) return null;
	const bitmap = await createImageBitmap(content);
	const scale = Math.min(106 / bitmap.width, 76 / bitmap.height, 1);
	const width = Math.max(1, Math.round(bitmap.width * scale));
	const height = Math.max(1, Math.round(bitmap.height * scale));
	bitmap.close();
	return {
		content,
		contentType: content.type,
		width,
		height,
		dpi: 96,
		anchor: { row, column },
		offsetX: 6,
		offsetY: 6,
		title
	};
}

async function loadWorkbookPhotos(uid: string, days: AttendanceDay[], locale: Locale) {
	const photos: [Image | null, Image | null][] = [];
	const daysPerBatch = 3;
	for (let start = 0; start < days.length; start += daysPerBatch) {
		const batch = await Promise.all(
			days.slice(start, start + daysPerBatch).map(async (day, index) => {
				const row = start + index + 2;
				const photo = (kind: AttendanceKind, offset: number) =>
					loadExcelPhoto(
						uid,
						day.dateKey,
						kind,
						row,
						columns.length + offset + 1,
						translate(locale, photoColumns[offset].label)
					);
				return Promise.all([photo('checkIn', 0), day.checkOut ? photo('checkOut', 1) : null]);
			})
		);
		photos.push(...batch);
	}
	return photos;
}

export async function downloadAttendanceWorkbook(
	days: AttendanceDay[],
	locale: Locale,
	photoOwnerUid?: string
) {
	const t = (message: string) => translate(locale, message);
	const photos = photoOwnerUid ? await loadWorkbookPhotos(photoOwnerUid, days, locale) : null;
	const workbookColumns = photos ? [...columns, ...photoColumns] : columns;
	const header: Row = workbookColumns.map(({ label }) => ({
		value: t(label),
		fontWeight: 'bold',
		color: '#FFFFFF',
		backgroundColor: '#124E43',
		height: 24,
		alignVertical: 'center'
	}));
	const rows = days.map((day, index): Row => {
		const start = day.checkIn.timestamp?.toDate();
		const end = day.checkOut?.timestamp?.toDate();
		const duration = start && end ? Math.max(0, end.getTime() - start.getTime()) : null;
		const date = Math.floor((dateFromKey(day.dateKey).getTime() - excelEpoch) / millisecondsPerDay);
		const rowPhotos = photos?.[index];

		const row: Row = [
			{ value: date, format: 'yyyy-mm-dd', height: rowPhotos?.some(Boolean) ? 66 : undefined },
			timeCell(start),
			timeCell(end),
			duration === null ? null : { value: duration / millisecondsPerDay, format: '[h]:mm:ss' },
			t(day.checkOut ? 'Lengkap' : 'Sudah masuk'),
			t(WORK_MODES[day.checkIn.mode]),
			day.checkOut ? t(WORK_MODES[day.checkOut.mode]) : null,
			{ value: day.checkIn.note, type: String, wrap: true },
			day.checkOut ? { value: day.checkOut.note, type: String, wrap: true } : null
		];
		if (rowPhotos) {
			const [checkIn, checkOut] = rowPhotos;
			const missingPhoto = { value: t('Foto tidak ditemukan.'), wrap: true };
			row.push(checkIn ? null : missingPhoto, day.checkOut && !checkOut ? missingPhoto : null);
		}
		return row;
	});

	await writeExcelFile([header, ...rows], {
		sheet: t('Riwayat presensi'),
		columns: workbookColumns.map(({ width }) => ({ width })),
		stickyRowsCount: 1,
		images: photos?.flat().filter((image) => image !== null)
	}).toFile(
		`trakta-${locale === 'en' ? 'attendance' : 'presensi'}-${dateKey()}${photos ? (locale === 'en' ? '-photos' : '-foto') : ''}.xlsx`
	);
}
