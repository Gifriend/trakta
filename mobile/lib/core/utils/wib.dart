import 'package:intl/intl.dart';

abstract final class Wib {
  static DateTime at(DateTime value) => value.toUtc().add(const Duration(hours: 7));
  static String key([DateTime? value]) => DateFormat('yyyyMMdd').format(at(value ?? DateTime.now()));
  static DateTime fromKey(String key) => DateTime.utc(int.parse(key.substring(0, 4)), int.parse(key.substring(4, 6)), int.parse(key.substring(6, 8)));
  static String time(DateTime? value) => value == null ? '—' : DateFormat('HH:mm').format(at(value));
  static String date(String key, String locale) => DateFormat('EEEE, d MMMM yyyy', locale).format(fromKey(key));
  static String duration(DateTime start, DateTime? end) {
    if (end == null) return '—';
    final minutes = end.difference(start).inMinutes.clamp(0, 999999);
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }
}
