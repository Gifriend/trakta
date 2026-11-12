import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/models/attendance.dart';
import '../../../core/services/photo_service.dart';
import '../../../core/utils/strings.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../settings/presentations/preferences_controller.dart';
import 'camera_controller.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key, this.mode, this.timer = 0});
  final WorkMode? mode;
  final int timer;
  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen>
    with WidgetsBindingObserver {
  CameraRequest get request => (mode: widget.mode, timer: widget.timer);
  bool _picking = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      if (mounted) ref.read(cameraControllerProvider(request).notifier).open();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(cameraControllerProvider(request).notifier);
    if (_picking) return;
    if (state == AppLifecycleState.resumed) {
      controller.open();
    } else {
      controller.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> take(bool gallery) async {
    final prefs = ref.read(preferencesControllerProvider);
    _picking = gallery;
    final result = await ref
        .read(cameraControllerProvider(request).notifier)
        .take(
          effect: prefs.cameraEffect,
          correctMirroring: prefs.correctMirroring,
          gallery: gallery,
        );
    _picking = false;
    if (!mounted) return;
    if (result != null) {
      Navigator.pop(context, result);
    } else if (gallery) {
      ref
          .read(cameraControllerProvider(request).notifier)
          .open(clearError: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cameraControllerProvider(request));
    final controller = ref.read(cameraControllerProvider(request).notifier);
    final prefs = ref.watch(preferencesControllerProvider);
    final t = ref.watch(stringsProvider).t;
    return Scaffold(
      appBar: AppBar(
        title: Text(t('Ambil foto')),
        actions: [
          IconButton(
            onPressed: state.busy ? null : controller.flip,
            tooltip: t('Ganti kamera'),
            icon: const Icon(Icons.flip_camera_ios_outlined),
          ),
        ],
      ),
      body: PageBody(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: ColoredBox(
                color: Colors.black,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (state.ready && controller.preview != null)
                      Center(
                        child: ColorFiltered(
                          colorFilter: ColorFilter.matrix(
                            effectMatrix(prefs.cameraEffect),
                          ),
                          child: CameraPreview(controller.preview!),
                        ),
                      )
                    else
                      const Center(
                        child: Icon(
                          Icons.camera_alt_outlined,
                          size: 48,
                          color: Colors.white54,
                        ),
                      ),
                    if (state.countdown > 0)
                      Center(
                        child: Text(
                          '${state.countdown}',
                          style: const TextStyle(
                            fontSize: 96,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (state.busy && state.countdown == 0)
                      const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (state.error != null) ...[
            Notice(t(state.error!), error: true),
            Wrap(
              spacing: 12,
              children: [
                TextButton(
                  onPressed: controller.open,
                  child: Text(t('Coba lagi')),
                ),
                TextButton(
                  onPressed: Geolocator.openAppSettings,
                  child: Text(t('Buka pengaturan')),
                ),
              ],
            ),
          ],
          if (widget.mode != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                t(
                  widget.mode == WorkMode.office
                      ? 'Kamera langsung · radius kantor 150 m · lokasi akurat'
                      : 'Lokasi perangkat dicatat bersama foto.',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          DropdownButtonFormField<String>(
            initialValue: cameraEffects.containsKey(prefs.cameraEffect)
                ? prefs.cameraEffect
                : 'natural',
            decoration: InputDecoration(labelText: t('Efek kamera')),
            items: cameraEffects.entries
                .map(
                  (effect) => DropdownMenuItem(
                    value: effect.key,
                    child: Text(t(effect.value)),
                  ),
                )
                .toList(),
            onChanged: state.busy
                ? null
                : (effect) {
                    if (effect != null) {
                      ref
                          .read(preferencesControllerProvider.notifier)
                          .update(prefs.copyWith(cameraEffect: effect));
                    }
                  },
          ),
          const SizedBox(height: 16),
          PrimaryAction(
            label: t('Ambil foto'),
            icon: Icons.camera_alt_outlined,
            busy: state.busy,
            onPressed: state.ready ? () => take(false) : null,
          ),
          if (widget.mode != WorkMode.office) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: state.busy ? null : () => take(true),
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(t('Pilih galeri/file')),
            ),
          ],
        ],
      ),
    );
  }
}
