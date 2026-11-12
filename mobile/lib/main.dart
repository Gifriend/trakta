import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/config/bootstrap.dart';
import 'core/utils/strings.dart';
import 'features/settings/data/repositories/preferences_repository.dart';
import 'features/settings/presentations/preferences_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  final storage = await SharedPreferences.getInstance();
  final translations = await AppStrings.load();
  final bootstrap = await bootstrapFirebase();
  runApp(
    ProviderScope(
      overrides: [
        preferencesRepositoryProvider.overrideWithValue(
          PreferencesRepository(storage),
        ),
        translationsProvider.overrideWithValue(translations),
        bootstrapProvider.overrideWithValue(bootstrap),
      ],
      child: const TraktaApp(),
    ),
  );
}
