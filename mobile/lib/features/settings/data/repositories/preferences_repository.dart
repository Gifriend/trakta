import 'package:shared_preferences/shared_preferences.dart';
import '../../presentations/preferences_state.dart';

class PreferencesRepository {
  const PreferencesRepository(this._storage);
  final SharedPreferences _storage;
  PreferencesState read() => PreferencesState(
    theme:
        AppTheme.values
            .where((theme) => theme.name == _storage.getString('theme'))
            .firstOrNull ??
        AppTheme.classic,
    dark: _storage.getBool('dark') ?? false,
    locale: _storage.getString('locale') == 'en' ? 'en' : 'id',
    cameraEffect: _storage.getString('cameraEffect') ?? 'natural',
    correctMirroring: _storage.getBool('correctMirroring') ?? true,
    reduceTransparency: _storage.getBool('reduceTransparency') ?? false,
  );
  Future<void> write(PreferencesState value) async {
    await _storage.setString('theme', value.theme.name);
    await _storage.setBool('dark', value.dark);
    await _storage.setString('locale', value.locale);
    await _storage.setString('cameraEffect', value.cameraEffect);
    await _storage.setBool('correctMirroring', value.correctMirroring);
    await _storage.setBool('reduceTransparency', value.reduceTransparency);
  }
}
