import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/attendance.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/strings.dart';
import '../../../core/utils/wib.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../attendance/presentations/attendance_providers.dart';
import '../../auth/data/repositories/auth_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider),
        user = ref.watch(authSessionProvider).valueOrNull;
    final t = strings.t;
    final date = ref.watch(currentDateProvider).valueOrNull ?? Wib.key();
    final feed = ref.watch(attendanceFeedProvider);
    final palette = Theme.of(context).extension<TraktaPalette>()!;
    final name =
        (user?.displayName?.isNotEmpty == true
                ? user!.displayName!
                : user?.email?.split('@').first ?? t('Teman'))
            .split(' ')
            .first;
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(attendanceFeedProvider);
        await ref.read(attendanceFeedProvider.future);
      },
      child: PageBody(
        children: [
          const SizedBox(height: 12),
          Text(
            t('Halo, {name}', {'name': name}),
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 6),
          Text(
            t('Catat kehadiranmu, lanjutkan harimu.'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.booth),
            icon: const Icon(Icons.auto_awesome_outlined),
            label: Text(t('Buka fotobox')),
          ),
          const SizedBox(height: 20),
          feed.when(
            loading: () => const SurfaceCard(
              child: SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, stack) => Notice(
              t(friendlyError(error)),
              error: true,
              onRetry: () => ref.invalidate(attendanceFeedProvider),
            ),
            data: (data) {
              final today = data.days
                  .where((day) => day.dateKey == date)
                  .firstOrNull;
              final complete = today?.checkOut != null;
              final monthCount = data.days
                  .where((day) => day.dateKey.startsWith(date.substring(0, 6)))
                  .length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (data.fromCache)
                    Notice(
                      t(
                        'Menunggu sinkronisasi server. Presensi baru memerlukan internet.',
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: palette.forest,
                      borderRadius: BorderRadius.circular(palette.radius),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('HARI INI'),
                          style: TextStyle(
                            color: palette.lime,
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          Wib.date(date, strings.locale),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            t(
                              complete
                                  ? 'Presensi lengkap'
                                  : today == null
                                  ? 'Belum presensi'
                                  : 'Sudah masuk',
                            ),
                            style: TextStyle(color: palette.lime),
                          ),
                        ),
                        const SizedBox(height: 28),
                        if (MediaQuery.textScalerOf(context).scale(30) > 40)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _time(t('Masuk'), today?.checkIn, Icons.login),
                              const SizedBox(height: 24),
                              _time(t('Pulang'), today?.checkOut, Icons.logout),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: _time(
                                  t('Masuk'),
                                  today?.checkIn,
                                  Icons.login,
                                ),
                              ),
                              Container(
                                height: 48,
                                width: 1,
                                color: Colors.white24,
                              ),
                              const SizedBox(width: 28),
                              Expanded(
                                child: _time(
                                  t('Pulang'),
                                  today?.checkOut,
                                  Icons.logout,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 28),
                        if (complete)
                          Text(
                            '${t('Durasi kerja')}  ${Wib.duration(today!.checkIn.timestamp, today.checkOut!.timestamp)}',
                            style: TextStyle(
                              color: palette.lime,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: palette.lime,
                              foregroundColor: palette.forest,
                              minimumSize: const Size(double.infinity, 52),
                            ),
                            onPressed: () => context.push(AppRoutes.attendance),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.fingerprint),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    t(
                                      today == null
                                          ? 'Presensi masuk'
                                          : 'Presensi pulang',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SurfaceCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.event_available_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t('Kehadiran bulan ini'),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$monthCount ${t('hari')}',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text(
                        t('Aktivitas terbaru'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.history),
                        child: Text(t('Lihat semua')),
                      ),
                    ],
                  ),
                  if (data.days.isEmpty)
                    const EmptyState(message: 'Belum ada riwayat presensi.')
                  else
                    ...data.days
                        .take(3)
                        .map(
                          (day) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              day.checkOut != null
                                  ? Icons.check_circle_outline
                                  : Icons.timelapse,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(Wib.date(day.dateKey, strings.locale)),
                            subtitle: Text(
                              '${Wib.time(day.checkIn.timestamp)} – ${Wib.time(day.checkOut?.timestamp)} WIB',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.go(AppRoutes.history),
                          ),
                        ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _time(String label, AttendanceEvent? event, IconData icon) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      const SizedBox(height: 8),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          Wib.time(event?.timestamp),
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      const Text('WIB', style: TextStyle(fontSize: 11, color: Colors.white60)),
    ],
  );
}
