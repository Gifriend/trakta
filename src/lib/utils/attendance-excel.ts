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
	{ label: 'Koordinat masuk', width: 25 },
	{ label: 'Akurasi masuk (m)', width: 18 },
	{ label: 'Link peta masuk', width: 38 },
	{ label: 'Koordinat pulang', width: 25 },
	{ label: 'Akurasi pulang (m)', width: 18 },
	{ label: 'Link peta pulang', width: 38 },
	{ label: 'Catatan masuk', width: 42 },
	{ label: 'Catatan pulang', width: 42 }
];
const photoColumns = [
	{ label: 'Foto masuk', width: 34 },
	{ label: 'Foto pulang', width: 34 }
];
const photoWidth = 216;
const photoHeight = 154;

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
	const url = URL.createObjectURL(content);
	const size = await new Promise<{ width: number; height: number } | null>((resolve) => {
		const image = new window.Image();
		image.onload = () => resolve({ width: image.naturalWidth, height: image.naturalHeight });
		image.onerror = () => resolve(null);
		image.src = url;
	}).finally(() => URL.revokeObjectURL(url));
	if (!size?.width || !size.height) return null;
	const scale = Math.min(photoWidth / size.width, photoHeight / size.height);
	return {
		content,
		contentType: content.type,
		width: Math.max(1, Math.round(size.width * scale)),
		height: Math.max(1, Math.round(size.height * scale)),
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
						offset + 2,
						translate(locale, photoColumns[offset].label)
					);
				return Promise.all([photo('checkIn', 0), day.checkOut ? photo('checkOut', 1) : null]);
			})
		);
		photos.push(...batch);
	}
	return photos;
}

export async function createAttendanceWorkbook(
	days: AttendanceDay[],
	locale: Locale,
	photoOwnerUid?: string
) {
	const t = (message: string) => translate(locale, message);
	const photos = photoOwnerUid ? await loadWorkbookPhotos(photoOwnerUid, days, locale) : null;
	const workbookColumns = photos ? [columns[0], ...photoColumns, ...columns.slice(1)] : columns;
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

		const inLoc = day.checkIn.photoLocation;
		const outLoc = day.checkOut?.photoLocation;
		const inCoord = inLoc ? `${inLoc.latitude.toFixed(6)}, ${inLoc.longitude.toFixed(6)}` : null;
		const inAcc = inLoc ? Math.round(inLoc.accuracy) : null;
		const inMap = inLoc ? `https://www.google.com/maps?q=${inLoc.latitude},${inLoc.longitude}` : null;
		const outCoord = outLoc ? `${outLoc.latitude.toFixed(6)}, ${outLoc.longitude.toFixed(6)}` : null;
		const outAcc = outLoc ? Math.round(outLoc.accuracy) : null;
		const outMap = outLoc ? `https://www.google.com/maps?q=${outLoc.latitude},${outLoc.longitude}` : null;

		const row: Row = [
			{
				value: date,
				format: 'yyyy-mm-dd',
				height: rowPhotos?.some(Boolean) ? 126 : undefined,
				alignVertical: 'center'
			},
			timeCell(start),
			timeCell(end),
			duration === null ? null : { value: duration / millisecondsPerDay, format: '[h]:mm:ss' },
			t(day.checkOut ? 'Lengkap' : 'Sudah masuk'),
			t(WORK_MODES[day.checkIn.mode]),
			day.checkOut ? t(WORK_MODES[day.checkOut.mode]) : null,
			inCoord ? { value: inCoord, type: String } : null,
			inAcc === null ? null : { value: inAcc, type: Number },
			inMap ? { value: inMap, type: String } : null,
			outCoord ? { value: outCoord, type: String } : null,
			outAcc === null ? null : { value: outAcc, type: Number },
			outMap ? { value: outMap, type: String } : null,
			{ value: day.checkIn.note, type: String, wrap: true },
			day.checkOut ? { value: day.checkOut.note, type: String, wrap: true } : null
		];
		if (rowPhotos) {
			const [checkIn, checkOut] = rowPhotos;
			const missingPhoto = { value: t('Foto tidak ditemukan.'), wrap: true };
			row.splice(
				1,
				0,
				checkIn ? null : missingPhoto,
				day.checkOut && !checkOut ? missingPhoto : null
			);
		}
		return row;
	});

	const blob = await writeExcelFile([header, ...rows], {
		sheet: t('Riwayat presensi'),
		columns: workbookColumns.map(({ width }) => ({ width })),
		stickyRowsCount: 1,
		images: photos?.flat().filter((image) => image !== null)
	}).toBlob();
	const name = `trakta-${locale === 'en' ? 'attendance' : 'presensi'}-${dateKey()}${photos ? (locale === 'en' ? '-photos' : '-foto') : ''}.xlsx`;
	return new File([blob], name, {
		type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
	});
}
