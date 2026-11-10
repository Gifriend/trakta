import type { Timestamp } from 'firebase/firestore';

export type AttendanceKind = 'checkIn' | 'checkOut';
export type WorkMode = 'office' | 'remote' | 'field';

export interface AttendanceEvent {
	timestamp: Timestamp;
	mode: WorkMode;
	note: string;
}

export interface AttendanceDay {
	id: string;
	dateKey: string;
	checkIn: AttendanceEvent;
	checkOut?: AttendanceEvent;
}

export interface CompressedPhoto {
	base64: string;
	dataUrl: string;
	bytes: number;
	width: number;
	height: number;
}

export const WORK_MODES: Record<WorkMode, string> = {
	office: 'Di kantor',
	remote: 'Dari rumah',
	field: 'Dinas luar'
};
