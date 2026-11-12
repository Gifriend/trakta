import type { PhotoLocation, PhotoSource, WorkMode } from '#lib/types/attendance.ts';

// Pin linked by the official SUCOFINDO contact page. Keep firestore.rules in sync.
const office = { latitude: -6.2517753, longitude: 106.8422473 };
export const OFFICE_RADIUS_METERS = 150;
const OFFICE_MAX_ACCURACY_METERS = 100;

export function photoLocationIssue(location: PhotoLocation, mode: WorkMode) {
	if (mode !== 'office') return '';
	if (location.source !== 'camera') return 'Ambil foto langsung dari kamera untuk presensi kantor.';
	if (location.accuracy > OFFICE_MAX_ACCURACY_METERS)
		return 'Lokasi belum cukup akurat. Dekati jendela atau area terbuka lalu coba lagi.';
	const north = (location.latitude - office.latitude) * 110600;
	const east = (location.longitude - office.longitude) * 110660;
	return north * north + east * east > OFFICE_RADIUS_METERS ** 2
		? 'Lokasimu berada di luar radius {radius} m dari Graha Sucofindo.'
		: '';
}

export function locatePhoto(source: PhotoSource): Promise<PhotoLocation> {
	return new Promise((resolve, reject) => {
		if (!navigator.geolocation) {
			reject(new Error('Lokasi perangkat memerlukan browser yang mendukung dan koneksi HTTPS.'));
			return;
		}
		navigator.geolocation.getCurrentPosition(
			({ coords: { latitude, longitude, accuracy } }) =>
				resolve({ latitude, longitude, accuracy, source }),
			(error) =>
				reject(
					new Error(
						error.code === 1
							? 'Izinkan akses lokasi untuk mengambil foto presensi.'
							: 'Lokasi belum dapat diperoleh. Aktifkan lokasi perangkat lalu coba lagi.'
					)
				),
			{ enableHighAccuracy: true, maximumAge: 0, timeout: 12000 }
		);
	});
}
