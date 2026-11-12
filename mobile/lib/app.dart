import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentations/preferences_controller.dart';

class TraktaApp extends ConsumerWidget {
  const TraktaApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesControllerProvider);
    return MaterialApp.router(
      title: 'Trakta',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(appRouterProvider),
      theme: TraktaTheme.build(prefs.theme, false),
      darkTheme: TraktaTheme.build(prefs.theme, true),
      themeMode: prefs.dark ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(prefs.locale),
      supportedLocales: const [Locale('id'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
