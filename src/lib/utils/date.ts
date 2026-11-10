export const TIME_ZONE = 'Asia/Jakarta';

export function dateKey(date = new Date()): string {
	const parts = new Intl.DateTimeFormat('en-GB', {
		timeZone: TIME_ZONE,
		year: 'numeric',
		month: '2-digit',
		day: '2-digit'
	}).formatToParts(date);
	return ['year', 'month', 'day'].map((type) => parts.find((p) => p.type === type)?.value).join('');
}

export function formatDate(date: Date, options: Intl.DateTimeFormatOptions = {}): string {
	return new Intl.DateTimeFormat('id-ID', {
		timeZone: TIME_ZONE,
		weekday: 'long',
		day: 'numeric',
		month: 'long',
		year: 'numeric',
		...options
	}).format(date);
}

export function formatTime(date?: Date): string {
	if (!date) return '—';
	return new Intl.DateTimeFormat('id-ID', {
		timeZone: TIME_ZONE,
		hour: '2-digit',
		minute: '2-digit',
		hourCycle: 'h23'
	})
		.format(date)
		.replace('.', ':');
}

export function dateFromKey(key: string): Date {
	return new Date(`${key.slice(0, 4)}-${key.slice(4, 6)}-${key.slice(6, 8)}T12:00:00+07:00`);
}

export function durationLabel(start?: Date, end?: Date): string {
	if (!start || !end) return '—';
	const minutes = Math.max(0, Math.floor((end.getTime() - start.getTime()) / 60_000));
	return `${Math.floor(minutes / 60)}j ${minutes % 60}m`;
}
