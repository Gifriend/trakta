import 'dart:typed_data';

enum WorkMode {
  office('Di kantor'),
  remote('Dari rumah'),
  field('Dinas luar');

  const WorkMode(this.label);
  final String label;
}

enum AttendanceKind { checkIn, checkOut }

enum PhotoSource { camera, gallery }

class PhotoLocation {
  const PhotoLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.source,
  });
  final double latitude, longitude, accuracy;
  final PhotoSource source;
  Map<String, dynamic> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'source': source.name,
  };
}

class AttendanceEvent {
  const AttendanceEvent({
    required this.timestamp,
    required this.mode,
    required this.note,
    this.photoLocation,
  });
  final DateTime timestamp;
  final WorkMode mode;
  final String note;
  final PhotoLocation? photoLocation;
}

class AttendanceDay {
  const AttendanceDay({
    required this.dateKey,
    required this.checkIn,
    this.checkOut,
  });
  final String dateKey;
  final AttendanceEvent checkIn;
  final AttendanceEvent? checkOut;
}

class AttendancePage {
  const AttendancePage(this.days, this.hasNext);
  final List<AttendanceDay> days;
  final bool hasNext;
}

class AttendanceRange {
  const AttendanceRange({this.from, this.to});
  final String? from, to;
}

class CapturedPhoto {
  const CapturedPhoto(this.bytes, {this.location});
  final Uint8List bytes;
  final PhotoLocation? location;
}
