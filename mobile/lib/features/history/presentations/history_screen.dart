import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/attendance.dart';
import '../../../core/services/file_share_service.dart';
import '../../../core/utils/strings.dart';
import '../../../core/utils/wib.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../attendance/data/repositories/attendance_repository.dart';
import '../../auth/data/repositories/auth_repository.dart';
import 'history_controller.dart';

final attendancePhotoProvider = FutureProvider.autoDispose
    .family<Uint8List?, ({String key, AttendanceKind kind})>((ref, request) {
      final uid = ref.watch(authSessionProvider).valueOrNull?.uid ?? '';
      return ref
          .watch(attendanceRepositoryProvider)
          .photo(uid, request.key, request.kind);
    });

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyControllerProvider),
        controller = ref.read(historyControllerProvider.notifier);
    final strings = ref.watch(stringsProvider),
        t = ref.watch(stringsProvider).t;
    Future<void> date(bool from) async {
      final key = from ? state.from : state.to;
      final chosen = await showDatePicker(
        context: context,
        initialDate: key == null ? Wib.fromKey(Wib.key()) : Wib.fromKey(key),
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (chosen == null) return;
      final value =
          '${chosen.year}${chosen.month.toString().padLeft(2, '0')}${chosen.day.toString().padLeft(2, '0')}';
      await controller.filter(
        from: from ? value : state.from,
        to: from ? state.to : value,
      );
    }

    return RefreshIndicator(
      onRefresh: controller.load,
      child: PageBody(
        children: [
          const SizedBox(height: 12),
          Text(
            t('Riwayat presensi'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(t('Lihat kembali hari-hari produktifmu.')),
          const SizedBox(height: 24),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: state.exporting ? null : () => date(true),
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(
                        state.from == null ? t('Tanggal mulai') : state.from!,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: state.exporting ? null : () => date(false),
                      icon: const Icon(Icons.event_outlined, size: 18),
                      label: Text(
                        state.to == null ? t('Tanggal akhir') : state.to!,
                      ),
                    ),
                    if (state.from != null || state.to != null)
                      TextButton(
                        onPressed: state.exporting
                            ? null
                            : () => controller.filter(),
                        child: Text(t('Hapus filter')),
                      ),
                  ],
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(t('Sertakan foto di Excel')),
                  value: state.includePhotos,
                  onChanged: state.exporting
                      ? null
                      : (value) => controller.includePhotos(value ?? false),
                ),
                OutlinedButton.icon(
                  onPressed: state.exporting || state.busy
                      ? null
                      : () async {
                          final origin = FileShareService.origin(context);
                          final bytes = await controller.export(strings);
                          if (!context.mounted || bytes == null) return;
                          try {
                            await FileShareService.share(
                              bytes,
                              name:
                                  'trakta-${strings.locale == 'en' ? 'attendance' : 'presensi'}-${Wib.key()}${state.includePhotos ? '-foto' : ''}.xlsx',
                              mimeType:
                                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                              origin: origin,
                            );
                          } catch (_) {
                            if (context.mounted) {
                              showAppError(
                                context,
                                t('Ekspor belum dapat dibagikan. Coba lagi.'),
                              );
                            }
                          }
                        },
                  icon: state.exporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_outlined),
                  label: Text(
                    t(state.exporting ? 'Menyiapkan Excel…' : 'Ekspor Excel'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (state.error != null)
            Notice(t(state.error!), error: true, onRetry: controller.load),
          if (state.busy)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.days.isEmpty)
            const EmptyState(message: 'Belum ada riwayat presensi.')
          else
            ...state.days.map(
              (day) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SurfaceCard(
                  padding: EdgeInsets.zero,
                  child: ExpansionTile(
                    key: ValueKey(day.dateKey),
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    shape: const Border(),
                    collapsedShape: const Border(),
                    title: Text(
                      Wib.date(day.dateKey, strings.locale),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${Wib.time(day.checkIn.timestamp)} – ${Wib.time(day.checkOut?.timestamp)} WIB\n${t(day.checkOut == null ? 'Sudah masuk' : 'Lengkap')} · ${Wib.duration(day.checkIn.timestamp, day.checkOut?.timestamp)}',
                      ),
                    ),
                    children: [
                      AttendanceEventDetail(
                        day: day,
                        event: day.checkIn,
                        kind: AttendanceKind.checkIn,
                      ),
                      if (day.checkOut != null) ...[
                        const Divider(height: 32),
                        AttendanceEventDetail(
                          day: day,
                          event: day.checkOut!,
                          kind: AttendanceKind.checkOut,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: state.busy || state.page == 0
                    ? null
                    : () => controller.load(page: state.page - 1),
                tooltip: t('Sebelumnya'),
                icon: const Icon(Icons.chevron_left),
              ),
              Text('${t('Halaman')} ${state.page + 1}'),
              IconButton(
                onPressed: state.busy || !state.hasNext
                    ? null
                    : () => controller.load(page: state.page + 1),
                tooltip: t('Selanjutnya'),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AttendanceEventDetail extends ConsumerStatefulWidget {
  const AttendanceEventDetail({
    super.key,
    required this.day,
    required this.event,
    required this.kind,
  });
  final AttendanceDay day;
  final AttendanceEvent event;
  final AttendanceKind kind;
  @override
  ConsumerState<AttendanceEventDetail> createState() =>
      _AttendanceEventDetailState();
}

class _AttendanceEventDetailState extends ConsumerState<AttendanceEventDetail> {
  bool loadPhoto = false;
  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider).t,
        location = widget.event.photoLocation;
    final request = (key: widget.day.dateKey, kind: widget.kind);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${t(widget.kind == AttendanceKind.checkIn ? 'Masuk' : 'Pulang')} · ${t(widget.event.mode.label)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (widget.event.note.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(widget.event.note),
          ),
        if (location != null)
          Text(
            '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}\n±${location.accuracy.round()} m · ${t(location.source == PhotoSource.camera ? 'Kamera' : 'Galeri')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        const SizedBox(height: 12),
        if (!loadPhoto)
          OutlinedButton.icon(
            onPressed: () => setState(() => loadPhoto = true),
            icon: const Icon(Icons.image_outlined),
            label: Text(t('Lihat foto')),
          )
        else
          ref
              .watch(attendancePhotoProvider(request))
              .when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Notice(
                  t('Foto belum dapat dimuat. Coba lagi.'),
                  error: true,
                  onRetry: () =>
                      ref.invalidate(attendancePhotoProvider(request)),
                ),
                data: (bytes) => bytes == null
                    ? Text(t('Foto tidak ditemukan.'))
                    : GestureDetector(
                        onTap: () => showDialog<void>(
                          context: context,
                          builder: (context) => Dialog.fullscreen(
                            child: Scaffold(
                              appBar: AppBar(title: Text(t('Foto presensi'))),
                              body: Center(
                                child: InteractiveViewer(
                                  child: Image.memory(bytes),
                                ),
                              ),
                            ),
                          ),
                        ),
                        child: Semantics(
                          button: true,
                          label: t('Perbesar foto'),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              bytes,
                              height: 220,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
              ),
      ],
    );
  }
}
