import 'dart:ui';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../features/settings/presentations/preferences_controller.dart';
import '../theme/app_theme.dart';
import '../utils/strings.dart';

class Brand extends StatelessWidget {
  const Brand({super.key, this.size = 32});
  final double size;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SvgPicture.asset(
        'assets/brand.svg',
        width: size,
        height: size,
        excludeFromSemantics: true,
      ),
      const SizedBox(width: 10),
      Text(
        'trakta',
        style: TextStyle(
          fontSize: size * .8,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.4,
        ),
      ),
    ],
  );
}

class SurfaceCard extends ConsumerWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.extension<TraktaPalette>()!;
    final prefs = ref.watch(preferencesControllerProvider);
    final glass =
        (prefs.theme == AppTheme.glass || prefs.theme == AppTheme.liquid) &&
        !prefs.reduceTransparency &&
        !MediaQuery.highContrastOf(context);
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: glass ? .82 : 1),
        borderRadius: BorderRadius.circular(palette.radius),
        border: Border.all(
          color: theme.colorScheme.outline,
          width: prefs.theme == AppTheme.neo ? 2 : 1,
        ),
        boxShadow: prefs.theme == AppTheme.neo
            ? [
                BoxShadow(
                  color: theme.colorScheme.onSurface,
                  offset: const Offset(3, 3),
                ),
              ]
            : prefs.theme == AppTheme.clay
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: .12),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: child,
    );
    return glass
        ? ClipRRect(
            borderRadius: BorderRadius.circular(palette.radius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: content,
            ),
          )
        : content;
  }
}

class PrimaryAction extends ConsumerWidget {
  const PrimaryAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesControllerProvider);
    // Real UIKit controls on iOS; Flutter paints the Android glass surface.
    if (prefs.theme == AppTheme.liquid &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        !prefs.reduceTransparency &&
        !MediaQuery.highContrastOf(context) &&
        !busy &&
        onPressed != null) {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: CNButton(
          label: label,
          onPressed: onPressed,
          height: 54,
          style: CNButtonStyle.prominentGlass,
          tint: Theme.of(context).colorScheme.primary,
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy) ...[
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
              ] else if (icon != null) ...[
                Icon(icon),
                const SizedBox(width: 10),
              ],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          ),
        ),
      ),
    );
  }
}

class Notice extends StatelessWidget {
  const Notice(this.message, {super.key, this.error = false, this.onRetry});
  final String message;
  final bool error;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: error
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(
              color: error
                  ? Theme.of(context).colorScheme.onErrorContainer
                  : Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Icon(Icons.refresh)),
        ],
      ),
    ),
  );
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: EdgeInsets.fromLTRB(
      20,
      12,
      20,
      32 + MediaQuery.paddingOf(context).bottom,
    ),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ],
  );
}

Future<void> showAppError(BuildContext context, String message) async {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class EmptyState extends ConsumerWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.event_note_outlined,
  });
  final String message;
  final IconData icon;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36),
    child: Column(
      children: [
        Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          ref.watch(stringsProvider).t(message),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
