import { describe, expect, it } from 'vitest';
import { dateKey, dateFromKey, durationLabel, formatTime } from './date';

describe('WIB attendance dates', () => {
	it('switches to the next attendance day at midnight WIB', () => {
		expect(dateKey(new Date('2026-11-10T16:59:59Z'))).toBe('20261110');
		expect(dateKey(new Date('2026-11-10T17:00:00Z'))).toBe('20261111');
	});
	it('keeps history dates stable regardless of host timezone', () => {
		expect(dateKey(dateFromKey('20260101'))).toBe('20260101');
		expect(formatTime(new Date('2026-01-01T00:05:00Z'))).toBe('07:05');
	});
	it('formats duration and handles an incomplete day', () => {
		expect(durationLabel(new Date('2026-01-01T01:00:00Z'), new Date('2026-01-01T09:32:00Z'))).toBe(
			'8j 32m'
		);
		expect(durationLabel(new Date())).toBe('—');
	});
});
