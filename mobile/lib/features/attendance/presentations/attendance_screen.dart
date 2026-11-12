import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/attendance.dart';
import '../../../core/utils/strings.dart';
import '../../../core/utils/wib.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../camera/presentations/capture_screen.dart';
import '../../photo_editor/presentations/photo_editor_screen.dart';
import 'attendance_controller.dart';
import 'attendance_providers.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(currentDateProvider).valueOrNull ?? Wib.key();
    final feed = ref.watch(attendanceFeedProvider);
    final t = ref.watch(stringsProvider).t;
    return Scaffold(
      appBar: AppBar(title: Text(t('Presensi'))),
      body: feed.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(attendanceFeedProvider),
            child: Text(t('Coba lagi')),
          ),
        ),
        data: (data) {
          final today = data.days
              .where((day) => day.dateKey == date)
              .firstOrNull;
          if (today?.checkOut != null) {
            return const EmptyState(
              message: 'Presensi hari ini sudah lengkap.',
              icon: Icons.check_circle_outline,
            );
          }
          final request = (
            key: date,
            kind: today == null
                ? AttendanceKind.checkIn
                : AttendanceKind.checkOut,
          );
          return AttendanceForm(
            key: ValueKey('$date-${request.kind.name}'),
            request: request,
          );
        },
      ),
    );
  }
}

class AttendanceForm extends ConsumerStatefulWidget {
  const AttendanceForm({super.key, required this.request});
  final AttendanceRequest request;
  @override
  ConsumerState<AttendanceForm> createState() => _AttendanceFormState();
}

class _AttendanceFormState extends ConsumerState<AttendanceForm> {
  bool openingCamera = false;
  Future<void> capture() async {
    if (openingCamera) return;
    setState(() => openingCamera = true);
    final mode = ref.read(attendanceControllerProvider(widget.request)).mode;
    final photo = await Navigator.of(context).push<CapturedPhoto>(
      MaterialPageRoute(builder: (_) => CaptureScreen(mode: mode)),
    );
    if (!mounted) return;
    if (photo != null) {
      ref
          .read(attendanceControllerProvider(widget.request).notifier)
          .setPhoto(photo);
    }
    setState(() => openingCamera = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceControllerProvider(widget.request));
    final controller = ref.read(
      attendanceControllerProvider(widget.request).notifier,
    );
    final t = ref.watch(stringsProvider).t;
    ref.listen(attendanceControllerProvider(widget.request), (previous, next) {
      if (next.saved && previous?.saved != true) {
        showAppError(context, t('Presensi berhasil diterima server.'));
        context.pop();
      }
    });
    return PopScope(
      canPop: !state.busy,
      child: PageBody(
        children: [
          Text(
            t(
              widget.request.kind == AttendanceKind.checkIn
                  ? 'Presensi masuk'
                  : 'Presensi pulang',
            ),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(Wib.date(widget.request.key, ref.watch(stringsProvider).locale)),
          const SizedBox(height: 24),
          Text(
            t('Lokasi kerja'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WorkMode.values
                .map(
                  (mode) => ChoiceChip(
                    label: Text(t(mode.label)),
                    avatar: Icon(switch (mode) {
                      WorkMode.office => Icons.apartment,
                      WorkMode.remote => Icons.home_outlined,
                      WorkMode.field => Icons.work_outline,
                    }, size: 18),
                    selected: state.mode == mode,
                    onSelected: state.busy || openingCamera
                        ? null
                        : (_) => controller.setMode(mode),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          if (state.photo == null)
            SurfaceCard(
              child: Column(
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t('Foto wajib untuk setiap presensi.'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  PrimaryAction(
                    label: t('Buka kamera'),
                    busy: openingCamera,
                    onPressed: capture,
                  ),
                ],
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                state.photo!.bytes,
                height: 260,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(state.photo!.bytes.length / 1000).toStringAsFixed(1)} KB · ${t('Lokasi tercatat')}',
              textAlign: TextAlign.center,
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              children: [
                TextButton.icon(
                  onPressed: state.busy ? null : capture,
                  icon: const Icon(Icons.refresh),
                  label: Text(t('Ambil ulang')),
                ),
                TextButton.icon(
                  onPressed: state.busy
                      ? null
                      : () async {
                          final original = state.photo!;
                          final bytes = await Navigator.of(context)
                              .push<Uint8List>(
                                MaterialPageRoute(
                                  builder: (_) => PhotoEditorScreen(
                                    original: original.bytes,
                                  ),
                                ),
                              );
                          if (mounted && bytes != null) {
                            controller.setPhoto(
                              CapturedPhoto(bytes, location: original.location),
                            );
                          }
                        },
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(t('Edit foto')),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          TextField(
            enabled: !state.busy,
            maxLength: 300,
            maxLines: 3,
            onChanged: controller.setNote,
            decoration: InputDecoration(
              labelText: t('Catatan (opsional)'),
              alignLabelWithHint: true,
            ),
          ),
          if (state.error != null) Notice(t(state.error!), error: true),
          const SizedBox(height: 12),
          PrimaryAction(
            label: t(
              widget.request.kind == AttendanceKind.checkIn
                  ? 'Kirim presensi masuk'
                  : 'Kirim presensi pulang',
            ),
            busy: state.busy,
            icon: Icons.check_circle_outline,
            onPressed: state.photo == null
                ? null
                : () {
                    FocusScope.of(context).unfocus();
                    controller.submit();
                  },
          ),
          const SizedBox(height: 16),
          Text(
            t(
              'Presensi tercatat setelah diterima server. Waktu mengikuti WIB.',
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
