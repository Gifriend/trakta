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

function singleLocationAttempt(options: PositionOptions): Promise<GeolocationPosition> {
	return new Promise((resolve, reject) => {
		navigator.geolocation.getCurrentPosition(resolve, reject, options);
	});
}

function locationErrorMessage(error: GeolocationPositionError): string {
	switch (error.code) {
		case 1:
			return 'Izin lokasi belum diberikan. Ketuk ikon gembok/setelan di address bar browser untuk mengizinkan lokasi.';
		case 2:
			return 'GPS atau layanan lokasi perangkat tidak aktif. Mohon aktifkan GPS/Lokasi di pengaturan HP Anda lalu coba lagi.';
		case 3:
			return 'Waktu pencarian lokasi habis. Pastikan GPS HP aktif dan sinyal memadai lalu coba lagi.';
		default:
			return 'Lokasi belum dapat diperoleh. Aktifkan lokasi perangkat lalu coba lagi.';
	}
}

export async function checkLocationPermission(): Promise<PermissionState | 'unsupported'> {
	if (!navigator.permissions?.query) return 'unsupported';
	try {
		const status = await navigator.permissions.query({ name: 'geolocation' });
		return status.state;
	} catch {
		return 'unsupported';
	}
}

export async function locatePhoto(source: PhotoSource): Promise<PhotoLocation> {
	if (!navigator.geolocation) {
		throw new Error('Lokasi perangkat memerlukan browser yang mendukung dan koneksi HTTPS.');
	}

	try {
		const pos = await singleLocationAttempt({
			enableHighAccuracy: true,
			maximumAge: 10000,
			timeout: 10000
		});
		return {
			latitude: pos.coords.latitude,
			longitude: pos.coords.longitude,
			accuracy: pos.coords.accuracy,
			source
		};
	} catch (err: unknown) {
		const geoErr = err as GeolocationPositionError;
		if (geoErr?.code === 1) {
			throw new Error(locationErrorMessage(geoErr));
		}

		// Fallback for mobile: standard accuracy / cell & Wi-Fi fused location
		try {
			const pos = await singleLocationAttempt({
				enableHighAccuracy: false,
				maximumAge: 30000,
				timeout: 10000
			});
			return {
				latitude: pos.coords.latitude,
				longitude: pos.coords.longitude,
				accuracy: pos.coords.accuracy,
				source
			};
		} catch (fallbackErr: unknown) {
			const finalErr = (fallbackErr as GeolocationPositionError) || geoErr;
			throw new Error(locationErrorMessage(finalErr));
		}
	}
}
