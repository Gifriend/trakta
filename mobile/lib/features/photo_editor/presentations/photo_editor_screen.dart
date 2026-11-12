import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/photo_edits.dart';
import '../../../core/utils/strings.dart';
import '../../../core/widgets/app_widgets.dart';
import 'photo_editor_controller.dart';

class PhotoEditorScreen extends ConsumerStatefulWidget {
  const PhotoEditorScreen({super.key, required this.original});
  final Uint8List original;
  @override
  ConsumerState<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends ConsumerState<PhotoEditorScreen> {
  bool before = false;
  final custom = TextEditingController();
  @override
  void dispose() {
    custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(photoEditorControllerProvider(widget.original));
    final controller = ref.read(
      photoEditorControllerProvider(widget.original).notifier,
    );
    final t = ref.watch(stringsProvider).t;
    final sticker = state.stickers
        .where((value) => value.id == state.selectedSticker)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(t('Edit foto'))),
      body: PageBody(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              before ? widget.original : state.preview ?? widget.original,
              gaplessPlayback: true,
              fit: BoxFit.contain,
              height: 300,
            ),
          ),
          if (state.busy) const LinearProgressIndicator(),
          if (state.error != null)
            Notice(t(state.error!), error: true, onRetry: controller.render),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: Text(t('Sebelum')),
                selected: before,
                onSelected: (value) => setState(() => before = value),
              ),
              ActionChip(
                avatar: const Icon(Icons.rotate_right),
                label: Text(t('Putar')),
                onPressed: () => controller.update(
                  state.copyWith(turns: (state.turns + 1) % 4),
                ),
              ),
              FilterChip(
                label: Text(t('Potong persegi')),
                selected: state.square,
                onSelected: (value) =>
                    controller.update(state.copyWith(square: value)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: state.frame,
            decoration: InputDecoration(labelText: t('Bingkai foto')),
            items: photoFrames.entries
                .map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(t(entry.value)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                controller.update(state.copyWith(frame: value));
              }
            },
          ),
          const SizedBox(height: 16),
          TextField(
            maxLength: 60,
            decoration: InputDecoration(labelText: t('Caption')),
            onChanged: (value) =>
                controller.update(state.copyWith(caption: value)),
          ),
          Text(t('Stiker'), style: Theme.of(context).textTheme.titleMedium),
          Wrap(
            spacing: 6,
            children:
                [
                      '😊',
                      '😎',
                      '🥳',
                      '😍',
                      '🤩',
                      '😄',
                      '✨',
                      '⭐',
                      '🌟',
                      '❤️',
                      '💚',
                      '💛',
                      '🌸',
                      '🌼',
                      '🌈',
                      '☀️',
                      '☁️',
                      '🎉',
                      '🎊',
                      '🎀',
                      '🔥',
                      '👍',
                      '✌️',
                      '💯',
                    ]
                    .map(
                      (emoji) => ActionChip(
                        label: Text(
                          emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        onPressed: state.stickers.length >= 20
                            ? null
                            : () => controller.addSticker(emoji),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: custom,
                  maxLength: 12,
                  decoration: InputDecoration(labelText: t('Stiker sendiri')),
                ),
              ),
              IconButton(
                onPressed: state.stickers.length >= 20
                    ? null
                    : () {
                        controller.addSticker(custom.text);
                        custom.clear();
                      },
                tooltip: t('Tambah stiker'),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          if (state.stickers.isNotEmpty)
            Wrap(
              spacing: 8,
              children: state.stickers
                  .map(
                    (item) => ChoiceChip(
                      label: Text('${item.text} ${item.id + 1}'),
                      selected: item.id == state.selectedSticker,
                      onSelected: (_) => controller.selectSticker(item.id),
                    ),
                  )
                  .toList(),
            ),
          if (sticker != null) ...[
            _slider(
              t('Posisi horizontal'),
              sticker.x,
              .05,
              .95,
              (value) => controller.changeSticker(sticker.copyWith(x: value)),
            ),
            _slider(
              t('Posisi vertikal'),
              sticker.y,
              .05,
              .95,
              (value) => controller.changeSticker(sticker.copyWith(y: value)),
            ),
            _slider(
              t('Ukuran stiker'),
              sticker.size,
              .05,
              .35,
              (value) =>
                  controller.changeSticker(sticker.copyWith(size: value)),
            ),
            _slider(
              t('Rotasi stiker'),
              sticker.rotation,
              -180,
              180,
              (value) =>
                  controller.changeSticker(sticker.copyWith(rotation: value)),
            ),
            TextButton.icon(
              onPressed: controller.removeSticker,
              icon: const Icon(Icons.delete_outline),
              label: Text(t('Hapus stiker')),
            ),
          ],
          const SizedBox(height: 16),
          PrimaryAction(
            label: t('Simpan perubahan'),
            busy: state.busy,
            onPressed: state.error != null
                ? null
                : () =>
                      Navigator.pop(context, state.preview ?? widget.original),
          ),
        ],
      ),
    );
  }

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      Slider(
        label: value.toStringAsFixed(2),
        value: value,
        min: min,
        max: max,
        onChanged: onChanged,
      ),
    ],
  );
}
