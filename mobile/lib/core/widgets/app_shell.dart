import 'dart:ui';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/settings/presentations/preferences_controller.dart';
import '../routing/app_routes.dart';
import '../utils/strings.dart';
import 'app_widgets.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child, required this.index});
  final Widget child;
  final int index;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesControllerProvider),
        t = ref.watch(stringsProvider).t;
    final native =
        prefs.theme == AppTheme.liquid &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        !prefs.reduceTransparency &&
        !MediaQuery.highContrastOf(context);
    void navigate(int value) =>
        context.go(value == 0 ? AppRoutes.today : AppRoutes.history);
    Widget navigation = native
        ? CupertinoTheme(
            data: CupertinoThemeData(
              brightness: Theme.of(context).brightness,
              primaryColor: Theme.of(context).colorScheme.primary,
            ),
            child: CNTabBar(
              height: 64,
              currentIndex: index,
              onTap: navigate,
              tint: Theme.of(context).colorScheme.primary,
              items: [
                CNTabBarItem(
                  label: t('Hari ini'),
                  icon: const CNSymbol('square.grid.2x2'),
                ),
                CNTabBarItem(
                  label: t('Riwayat'),
                  icon: const CNSymbol('calendar'),
                ),
              ],
            ),
          )
        : NavigationBar(
            height: 72,
            selectedIndex: index,
            onDestinationSelected: navigate,
            backgroundColor: prefs.theme == AppTheme.liquid
                ? Colors.transparent
                : null,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.grid_view_outlined),
                selectedIcon: const Icon(Icons.grid_view_rounded),
                label: t('Hari ini'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.calendar_month_outlined),
                selectedIcon: const Icon(Icons.calendar_month),
                label: t('Riwayat'),
              ),
            ],
          );
    if (!native &&
        prefs.theme == AppTheme.liquid &&
        !prefs.reduceTransparency &&
        !MediaQuery.highContrastOf(context)) {
      navigation = ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: .86),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: navigation,
          ),
        ),
      );
    }
    return Scaffold(
      extendBody: prefs.theme == AppTheme.liquid,
      appBar: AppBar(
        title: const Brand(),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.settings),
            tooltip: t('Pengaturan'),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: EdgeInsets.fromLTRB(
          prefs.theme == AppTheme.liquid ? 18 : 0,
          0,
          prefs.theme == AppTheme.liquid ? 18 : 0,
          prefs.theme == AppTheme.liquid ? 12 : 0,
        ),
        child: navigation,
      ),
    );
  }
}
