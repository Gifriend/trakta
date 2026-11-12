import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/preferences_repository.dart';
import 'preferences_state.dart';
export 'preferences_state.dart';

final preferencesRepositoryProvider = Provider<PreferencesRepository>(
  (ref) => throw StateError('Preferences must be initialized at startup.'),
);
final preferencesControllerProvider =
    StateNotifierProvider<PreferencesController, PreferencesState>(
      (ref) => PreferencesController(ref.watch(preferencesRepositoryProvider)),
    );

class PreferencesController extends StateNotifier<PreferencesState> {
  PreferencesController(this._repository) : super(_repository.read());
  final PreferencesRepository _repository;
  Future<void> update(PreferencesState value) async {
    // Preferences are small and independent of account data.
    await _repository.write(value);
    if (mounted) state = value;
  }
}
