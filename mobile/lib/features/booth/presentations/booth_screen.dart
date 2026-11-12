import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/attendance.dart';
import '../../../core/services/file_share_service.dart';
import '../../../core/utils/strings.dart';
import '../../../core/utils/wib.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../camera/presentations/capture_screen.dart';
import '../../photo_editor/presentations/photo_editor_screen.dart';
import 'booth_controller.dart';

class BoothScreen extends ConsumerStatefulWidget {
  const BoothScreen({super.key});
  @override
  ConsumerState<BoothScreen> createState() => _BoothScreenState();
}

class _BoothScreenState extends ConsumerState<BoothScreen> {
  bool sharing = false;
  Future<void> capture({int? index}) async {
    final timer = ref.read(boothControllerProvider).timer;
    final photo = await Navigator.of(context).push<CapturedPhoto>(
      MaterialPageRoute(builder: (_) => CaptureScreen(timer: timer)),
    );
    if (mounted && photo != null) {
      ref
          .read(boothControllerProvider.notifier)
          .addPhoto(photo.bytes, index: index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(boothControllerProvider),
        controller = ref.read(boothControllerProvider.notifier);
    final t = ref.watch(stringsProvider).t;
    return Scaffold(
      appBar: AppBar(title: Text(t('Fotobox'))),
      body: PageBody(
        children: [
          Text(t('Ambil beberapa pose, hias, lalu simpan ke perangkatmu.')),
          const SizedBox(height: 24),
          if (state.collage == null) ...[
            Text(
              t('Jumlah foto'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [2, 3, 4]
                  .map(
                    (count) => ChoiceChip(
                      label: Text('$count ${t('foto')}'),
                      selected: state.count == count,
                      onSelected: state.busy
                          ? null
                          : (_) => controller.configure(
                              state.copyWith(
                                count: count,
                                photos: state.photos.take(count).toList(),
                              ),
                            ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text(
              t('Susunan foto'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(t('Strip vertikal')),
                  selected: !state.grid,
                  onSelected: state.busy
                      ? null
                      : (_) =>
                            controller.configure(state.copyWith(grid: false)),
                ),
                ChoiceChip(
                  label: Text(t('Kolase')),
                  selected: state.grid,
                  onSelected: state.busy
                      ? null
                      : (_) => controller.configure(state.copyWith(grid: true)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              t('Timer kamera'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Wrap(
              spacing: 8,
              children: [0, 3, 5]
                  .map(
                    (timer) => ChoiceChip(
                      label: Text(timer == 0 ? t('Tanpa timer') : '${timer}s'),
                      selected: state.timer == timer,
                      onSelected: state.busy
                          ? null
                          : (_) => controller.configure(
                              state.copyWith(timer: timer),
                            ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text(
              t('Warna bingkai'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Wrap(
              spacing: 8,
              children:
                  {
                        0xfffff1d8: 'Krem',
                        0xffffe2ec: 'Merah muda',
                        0xffe1e9ff: 'Lavender',
                        0xffd5f3e8: 'Mint',
                        0xffffffff: 'Putih',
                      }.entries
                      .map(
                        (entry) => ChoiceChip(
                          avatar: CircleAvatar(
                            backgroundColor: Color(entry.key),
                            radius: 9,
                          ),
                          label: Text(t(entry.value)),
                          selected: state.color == entry.key,
                          onSelected: state.busy
                              ? null
                              : (_) => controller.configure(
                                  state.copyWith(color: entry.key),
                                ),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 24),
            for (var i = 0; i < state.photos.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SurfaceCard(
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          state.photos[i],
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(t('Pose {number}', {'number': i + 1})),
                      ),
                      IconButton(
                        onPressed: state.busy ? null : () => capture(index: i),
                        tooltip: t('Ambil ulang'),
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
              ),
            if (state.photos.length < state.count)
              PrimaryAction(
                label: t('Ambil pose berikutnya'),
                icon: Icons.camera_alt_outlined,
                onPressed: () => capture(),
              )
            else
              PrimaryAction(
                label: t('Buat fotobox'),
                busy: state.busy,
                onPressed: controller.compose,
              ),
          ] else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(state.collage!, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final edited = await Navigator.of(context).push<Uint8List>(
                  MaterialPageRoute(
                    builder: (_) => PhotoEditorScreen(original: state.collage!),
                  ),
                );
                if (mounted && edited != null) controller.edited(edited);
              },
              icon: const Icon(Icons.auto_awesome_outlined),
              label: Text(t('Hias fotobox')),
            ),
            const SizedBox(height: 12),
            PrimaryAction(
              label: t('Simpan / bagikan foto'),
              busy: sharing,
              icon: Icons.ios_share,
              onPressed: () async {
                setState(() => sharing = true);
                try {
                  await FileShareService.share(
                    state.collage!,
                    name: 'trakta-fotobox-${Wib.key()}.jpg',
                    mimeType: 'image/jpeg',
                    origin: FileShareService.origin(context),
                  );
                } catch (_) {
                  if (context.mounted) {
                    showAppError(
                      context,
                      t('Foto belum dapat dibagikan. Coba lagi.'),
                    );
                  }
                } finally {
                  if (mounted) setState(() => sharing = false);
                }
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: controller.reset,
              child: Text(t('Sesi baru')),
            ),
          ],
          if (state.error != null) Notice(t(state.error!), error: true),
          const SizedBox(height: 16),
          Text(
            t('Fotobox disimpan di perangkat dan tidak dikirim ke Firebase.'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
