import writeExcelFile, { type Row } from 'write-excel-file/browser';
import { translate, type Locale } from '#lib/i18n.ts';
import { WORK_MODES, type AttendanceDay } from '#lib/types/attendance.ts';
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

function timeCell(date?: Date) {
	if (!date) return null;
	const [hours, minutes, seconds] = jakartaClock.format(date).split(':').map(Number);
	return {
		value: (hours * 3600 + minutes * 60 + seconds) / secondsPerDay,
		format: 'hh:mm:ss'
	};
}

export async function downloadAttendanceWorkbook(days: AttendanceDay[], locale: Locale) {
	const t = (message: string) => translate(locale, message);
	const header: Row = columns.map(({ label }) => ({
		value: t(label),
		fontWeight: 'bold',
		color: '#FFFFFF',
		backgroundColor: '#124E43',
		height: 24,
		alignVertical: 'center'
	}));
	const rows = days.map((day): Row => {
		const start = day.checkIn.timestamp?.toDate();
		const end = day.checkOut?.timestamp?.toDate();
		const duration = start && end ? Math.max(0, end.getTime() - start.getTime()) : null;
		const date = Math.floor((dateFromKey(day.dateKey).getTime() - excelEpoch) / millisecondsPerDay);

		return [
			{ value: date, format: 'yyyy-mm-dd' },
			timeCell(start),
			timeCell(end),
			duration === null ? null : { value: duration / millisecondsPerDay, format: '[h]:mm:ss' },
			t(day.checkOut ? 'Lengkap' : 'Sudah masuk'),
			t(WORK_MODES[day.checkIn.mode]),
			day.checkOut ? t(WORK_MODES[day.checkOut.mode]) : null,
			{ value: day.checkIn.note, type: String, wrap: true },
			day.checkOut ? { value: day.checkOut.note, type: String, wrap: true } : null
		];
	});

	await writeExcelFile([header, ...rows], {
		sheet: t('Riwayat presensi'),
		columns: columns.map(({ width }) => ({ width })),
		stickyRowsCount: 1
	}).toFile(`trakta-${locale === 'en' ? 'attendance' : 'presensi'}-${dateKey()}.xlsx`);
}
