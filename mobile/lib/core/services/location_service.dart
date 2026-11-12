import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../models/attendance.dart';
import '../utils/app_error.dart';

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

class LocationService {
  static const officeLatitude = -6.2517753;
  static const officeLongitude = 106.8422473;
  static const officeRadius = 150;
  static String? issue(PhotoLocation location, WorkMode mode) {
    if (!location.latitude.isFinite ||
        !location.longitude.isFinite ||
        !location.accuracy.isFinite ||
        location.latitude.abs() > 90 ||
        location.longitude.abs() > 180 ||
        location.accuracy < 0 ||
        location.accuracy > 40075000) {
      return 'Lokasi belum dapat diperoleh. Aktifkan lokasi perangkat lalu coba lagi.';
    }
    if (mode != WorkMode.office) return null;
    if (location.source != PhotoSource.camera) {
      return 'Ambil foto langsung dari kamera untuk presensi kantor.';
    }
    if (location.accuracy > 100) {
      return 'Lokasi belum cukup akurat. Dekati jendela atau area terbuka lalu coba lagi.';
    }
    // Identical projection to firestore.rules, including inclusive 150 m boundary.
    final north = (location.latitude - officeLatitude) * 110600;
    final east = (location.longitude - officeLongitude) * 110660;
    if (north * north + east * east > officeRadius * officeRadius) {
      return 'Lokasimu berada di luar radius 150 m dari Graha Sucofindo.';
    }
    return null;
  }

  Future<PhotoLocation> capture(PhotoSource source) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const AppException('Aktifkan lokasi perangkat lalu coba lagi.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const AppException(
        'Izin lokasi dinonaktifkan. Aktifkan melalui pengaturan aplikasi.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw const AppException(
        'Izinkan akses lokasi untuk mengambil foto presensi.',
      );
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return PhotoLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        source: source,
      );
    } catch (_) {
      throw const AppException(
        'Lokasi belum dapat diperoleh. Aktifkan lokasi perangkat lalu coba lagi.',
      );
    }
  }
}
