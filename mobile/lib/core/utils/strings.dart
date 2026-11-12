import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/presentations/preferences_controller.dart';

final translationsProvider = Provider<Map<String, String>>((ref) => const {});
final stringsProvider = Provider<AppStrings>(
  (ref) => AppStrings(
    ref.watch(preferencesControllerProvider).locale,
    ref.watch(translationsProvider),
  ),
);

class AppStrings {
  const AppStrings(this.locale, this.english);
  final String locale;
  final Map<String, String> english;
  String t(String message, [Map<String, Object> values = const {}]) {
    var result = locale == 'en' ? english[message] ?? message : message;
    for (final entry in values.entries) {
      result = result.replaceAll('{${entry.key}}', '${entry.value}');
    }
    return result;
  }

  static Future<Map<String, String>> load() async => Map<String, String>.from(
    jsonDecode(await rootBundle.loadString('assets/translations.json')) as Map,
  );
}
