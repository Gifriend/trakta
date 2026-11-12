import type { Timestamp } from 'firebase/firestore';

export type AttendanceKind = 'checkIn' | 'checkOut';
export type WorkMode = 'office' | 'remote' | 'field';
export type PhotoSource = 'camera' | 'gallery';

export interface PhotoLocation {
	latitude: number;
	longitude: number;
	accuracy: number;
	source: PhotoSource;
}

export interface AttendanceEvent {
	timestamp: Timestamp;
	mode: WorkMode;
	note: string;
	photoLocation?: PhotoLocation;
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
