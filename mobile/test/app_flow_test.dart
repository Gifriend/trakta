import 'dart:io';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trakta_mobile/app.dart';
import 'package:trakta_mobile/core/config/bootstrap.dart';
import 'package:trakta_mobile/core/models/attendance.dart';
import 'package:trakta_mobile/core/services/export_service.dart';
import 'package:trakta_mobile/core/utils/strings.dart';
import 'package:trakta_mobile/features/attendance/data/repositories/attendance_repository.dart';
import 'package:trakta_mobile/features/attendance/presentations/attendance_providers.dart';
import 'package:trakta_mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:trakta_mobile/features/settings/data/repositories/preferences_repository.dart';
import 'package:trakta_mobile/features/settings/presentations/preferences_controller.dart';

class _User extends Fake implements User {
  @override
  String get uid => 'test-user';
  @override
  String get displayName => 'Nadia Putri';
  @override
  String get email => 'nadia@example.test';
}

class _Repository extends Fake implements AttendanceRepository {
  static final day = AttendanceDay(
    dateKey: '20261112',
    checkIn: AttendanceEvent(
      timestamp: DateTime.utc(2026, 11, 12, 1, 12),
      mode: WorkMode.office,
      note: 'Review proyek Trakta',
    ),
  );
  @override
  Future<AttendancePage> page(
    String uid,
    AttendanceRange range, {
    String? after,
  }) async => AttendancePage([day], false);
}

class _Export extends Fake implements ExportService {}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  Future<void> pump(
    WidgetTester tester, {
    bool authenticated = false,
    AppTheme theme = AppTheme.classic,
    bool dark = false,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'theme': theme.name, 'dark': dark});
    final storage = (await tester.runAsync(SharedPreferences.getInstance))!;
    final translations = (await tester.runAsync(AppStrings.load))!;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesRepositoryProvider.overrideWithValue(
            PreferencesRepository(storage),
          ),
          translationsProvider.overrideWithValue(translations),
          bootstrapProvider.overrideWithValue(
            BootstrapResult(ready: authenticated),
          ),
          authSessionProvider.overrideWith(
            (ref) => Stream.value(authenticated ? _User() : null),
          ),
          currentDateProvider.overrideWith((ref) => Stream.value('20261112')),
          attendanceFeedProvider.overrideWith(
            (ref) => Stream.value(AttendanceFeed([_Repository.day], false)),
          ),
          attendanceRepositoryProvider.overrideWithValue(_Repository()),
          exportServiceProvider.overrideWithValue(_Export()),
        ],
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: const RepaintBoundary(
            key: ValueKey('preview'),
            child: TraktaApp(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> screenshot(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('CAPTURE_PREVIEWS')) return;
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('preview')),
      );
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('.tmp/previews/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets(
    'unconfigured app stays usable for themes and does not initialize Firebase',
    (tester) async {
      await pump(tester);
      expect(find.text('Selamat datang kembali.'), findsOneWidget);
      expect(
        find.textContaining('Firebase belum dikonfigurasi'),
        findsOneWidget,
      );
      await screenshot(tester, 'login');
      await tester.tap(find.byTooltip('Pengaturan'));
      await tester.pumpAndSettle();
      expect(find.text('Liquid Glass'), findsOneWidget);
      await tester.tap(find.text('Liquid Glass'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('authenticated dashboard navigates to history and booth', (
    tester,
  ) async {
    await pump(tester, authenticated: true);
    expect(find.text('Halo, Nadia'), findsOneWidget);
    expect(find.text('08:12'), findsOneWidget);
    await screenshot(tester, 'today');
    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();
    expect(find.text('Ekspor Excel'), findsOneWidget);
    expect(find.byTooltip('Pengaturan'), findsOneWidget);
    expect(tester.getTopLeft(find.byTooltip('Pengaturan')).dy, lessThan(60));
    expect(
      tester.getTopLeft(find.text('Riwayat presensi')).dy,
      greaterThan(56),
    );
    expect(find.text('Sertakan foto di Excel'), findsOneWidget);
    await screenshot(tester, 'history');
    await tester.tap(find.text('Hari ini'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buka fotobox'));
    await tester.pumpAndSettle();
    expect(find.text('Jumlah foto'), findsOneWidget);
    expect(find.text('Tanpa timer'), findsOneWidget);
  });
  testWidgets('all web themes fit narrow screens in light and dark', (
    tester,
  ) async {
    for (final theme in AppTheme.values) {
      for (final dark in [false, true]) {
        await pump(
          tester,
          authenticated: true,
          theme: theme,
          dark: dark,
          size: const Size(320, 720),
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${theme.name}, dark=$dark',
        );
      }
    }
  });
  testWidgets('liquid theme dashboard preview and larger text', (tester) async {
    await pump(
      tester,
      authenticated: true,
      theme: AppTheme.liquid,
      dark: true,
      size: const Size(390, 844),
    );
    await screenshot(tester, 'liquid-dark');
    expect(tester.takeException(), isNull);
    await pump(
      tester,
      authenticated: true,
      size: const Size(320, 720),
      textScale: 1.8,
    );
    expect(tester.takeException(), isNull);
  });
}
