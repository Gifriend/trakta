import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/bootstrap.dart';
import '../../../../core/models/attendance.dart';
import '../../../../core/utils/app_error.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => AttendanceRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  ),
);

class AttendanceFeed {
  const AttendanceFeed(this.days, this.fromCache);
  final List<AttendanceDay> days;
  final bool fromCache;
}

class AttendanceRepository {
  const AttendanceRepository(this._db, this._auth);
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  void _assertOwner(String uid) {
    if (_auth.currentUser?.uid != uid) {
      throw const AppException('Sesi berakhir. Silakan masuk kembali.');
    }
  }

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _db.collection('users').doc(uid).collection('attendance');
  Query<Map<String, dynamic>> _query(String uid, AttendanceRange range) {
    Query<Map<String, dynamic>> query = _collection(
      uid,
    ).orderBy('dateKey', descending: true);
    if (range.from != null) {
      query = query.where('dateKey', isGreaterThanOrEqualTo: range.from);
    }
    if (range.to != null) {
      query = query.where('dateKey', isLessThanOrEqualTo: range.to);
    }
    return query;
  }

  Stream<AttendanceFeed> watch(String uid) {
    _assertOwner(uid);
    return _query(uid, const AttendanceRange())
        .limit(31)
        .snapshots(includeMetadataChanges: true)
        .where((snapshot) => !snapshot.metadata.hasPendingWrites)
        .map((snapshot) {
          _assertOwner(uid);
          return AttendanceFeed(
            snapshot.docs.map((doc) => parseDay(doc.id, doc.data())).toList(),
            snapshot.metadata.isFromCache,
          );
        });
  }

  Future<AttendancePage> page(
    String uid,
    AttendanceRange range, {
    String? after,
  }) async {
    _assertOwner(uid);
    var query = _query(uid, range);
    if (after != null) query = query.startAfter([after]);
    final snapshot = await query
        .limit(11)
        .get(const GetOptions(source: Source.server));
    _assertOwner(uid);
    return AttendancePage(
      snapshot.docs
          .take(10)
          .map((doc) => parseDay(doc.id, doc.data()))
          .toList(),
      snapshot.docs.length > 10,
    );
  }

  Future<List<AttendanceDay>> all(String uid, AttendanceRange range) async {
    _assertOwner(uid);
    final result = await _query(
      uid,
      range,
    ).get(const GetOptions(source: Source.server));
    _assertOwner(uid);
    return result.docs.map((doc) => parseDay(doc.id, doc.data())).toList();
  }

  Future<Uint8List?> photo(String uid, String key, AttendanceKind kind) async {
    _assertOwner(uid);
    final result = await _collection(uid)
        .doc(key)
        .collection('photos')
        .doc(kind.name)
        .get(const GetOptions(source: Source.server));
    _assertOwner(uid);
    final data = result.data()?['base64'];
    return data is String && data.isNotEmpty ? base64Decode(data) : null;
  }

  Future<void> submit({
    required String uid,
    required String key,
    required AttendanceKind kind,
    required WorkMode mode,
    required String note,
    required CapturedPhoto photo,
  }) async {
    _assertOwner(uid);
    final day = _collection(uid).doc(key);
    await _db.runTransaction((transaction) async {
      _assertOwner(uid);
      final existing = (await transaction.get(day)).data();
      if (existing?[kind.name] != null) {
        throw const AppException(
          'Presensi hari ini sudah tercatat. Muat ulang ringkasan.',
        );
      }
      if (kind == AttendanceKind.checkOut && existing?['checkIn'] == null) {
        throw const AppException('Catat presensi masuk terlebih dahulu.');
      }
      final event = {
        'timestamp': FieldValue.serverTimestamp(),
        'mode': mode.name,
        'note': note.trim(),
        'photoLocation': photo.location!.toMap(),
      };
      if (kind == AttendanceKind.checkIn) {
        transaction.set(day, {'dateKey': key, 'checkIn': event});
      } else {
        transaction.update(day, {'checkOut': event});
      }
      transaction.set(day.collection('photos').doc(kind.name), {
        'base64': base64Encode(photo.bytes),
        'bytes': photo.bytes.length,
        'mimeType': 'image/jpeg',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
    _assertOwner(uid);
  }

  static AttendanceDay parseDay(String key, Map<String, dynamic> data) =>
      AttendanceDay(
        dateKey: key,
        checkIn: _event(data['checkIn'] as Map<String, dynamic>),
        checkOut: data['checkOut'] == null
            ? null
            : _event(data['checkOut'] as Map<String, dynamic>),
      );
  static AttendanceEvent _event(Map<String, dynamic> data) {
    final location = data['photoLocation'] as Map<String, dynamic>?;
    return AttendanceEvent(
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      mode: WorkMode.values.byName(data['mode'] as String),
      note: data['note'] as String? ?? '',
      photoLocation: location == null
          ? null
          : PhotoLocation(
              latitude: (location['latitude'] as num).toDouble(),
              longitude: (location['longitude'] as num).toDouble(),
              accuracy: (location['accuracy'] as num).toDouble(),
              source: PhotoSource.values.byName(location['source'] as String),
            ),
    );
  }
}
