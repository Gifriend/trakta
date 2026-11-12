import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/bootstrap.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/photo_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/strings.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/data/repositories/auth_repository.dart';
import 'preferences_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool signingOut = false;
  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesControllerProvider);
    final t = ref.watch(stringsProvider).t;
    final user = ref.watch(bootstrapProvider).ready
        ? ref.watch(authSessionProvider).valueOrNull
        : null;
    Future<void> update(PreferencesState value) async {
      try {
        await ref.read(preferencesControllerProvider.notifier).update(value);
      } catch (_) {
        if (context.mounted) {
          showAppError(context, t('Pengaturan belum tersimpan. Coba lagi.'));
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t('Pengaturan')),
        leading: IconButton(
          tooltip: t('Kembali'),
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: PageBody(
        children: [
          if (user != null) ...[
            SurfaceCard(
              child: Row(
                children: [
                  CircleAvatar(
                    child: Text(
                      (user.displayName ?? user.email ?? 'T')
                          .substring(0, 1)
                          .toUpperCase(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? t('Akun pribadi'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(user.email ?? '', overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          Text(t('Tampilan'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AppTheme.values.map((theme) {
              final palette = TraktaTheme.build(theme, prefs.dark);
              return ChoiceChip(
                selected: prefs.theme == theme,
                avatar: CircleAvatar(
                  backgroundColor: palette.colorScheme.primary,
                  radius: 9,
                ),
                label: Text(themeLabels[theme]!),
                onSelected: (_) => update(prefs.copyWith(theme: theme)),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          if (prefs.theme == AppTheme.liquid)
            Notice(
              t(
                defaultTargetPlatform == TargetPlatform.iOS
                    ? 'Liquid Glass memakai kontrol native iOS. Efek mengikuti versi iOS dan pengaturan aksesibilitas.'
                    : 'Tema kaca Android memakai blur Flutter dan warna Trakta.',
              ),
            ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(t('Mode gelap')),
            value: prefs.dark,
            onChanged: (value) => update(prefs.copyWith(dark: value)),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(t('Kurangi transparansi')),
            subtitle: Text(
              t('Gunakan permukaan solid agar lebih mudah dibaca.'),
            ),
            value: prefs.reduceTransparency,
            onChanged: (value) =>
                update(prefs.copyWith(reduceTransparency: value)),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: prefs.locale,
            decoration: InputDecoration(labelText: t('Bahasa')),
            items: const [
              DropdownMenuItem(value: 'id', child: Text('Bahasa Indonesia')),
              DropdownMenuItem(value: 'en', child: Text('English')),
            ],
            onChanged: (value) {
              if (value != null) update(prefs.copyWith(locale: value));
            },
          ),
          const SizedBox(height: 28),
          Text(t('Kamera'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: cameraEffects.containsKey(prefs.cameraEffect)
                ? prefs.cameraEffect
                : 'natural',
            decoration: InputDecoration(labelText: t('Efek kamera')),
            items: cameraEffects.entries
                .map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(t(entry.value)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) update(prefs.copyWith(cameraEffect: value));
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t('Koreksi mirror')),
            subtitle: Text(t('Simpan foto kamera depan sesuai arah asli.')),
            trailing:
                prefs.theme == AppTheme.liquid &&
                    defaultTargetPlatform == TargetPlatform.iOS
                ? CNSwitch(
                    value: prefs.correctMirroring,
                    onChanged: (value) =>
                        update(prefs.copyWith(correctMirroring: value)),
                  )
                : Switch.adaptive(
                    value: prefs.correctMirroring,
                    onChanged: (value) =>
                        update(prefs.copyWith(correctMirroring: value)),
                  ),
          ),
          const SizedBox(height: 24),
          if (user != null)
            OutlinedButton.icon(
              onPressed: signingOut
                  ? null
                  : () async {
                      setState(() => signingOut = true);
                      try {
                        await ref.read(authServiceProvider).signOut();
                        if (context.mounted) context.go(AppRoutes.auth);
                      } catch (error) {
                        if (context.mounted) {
                          showAppError(context, t(friendlyError(error)));
                        }
                      } finally {
                        if (mounted) setState(() => signingOut = false);
                      }
                    },
              icon: const Icon(Icons.logout),
              label: Text(t('Keluar dari akun')),
            ),
          const SizedBox(height: 24),
          const Center(child: Brand(size: 26)),
          const SizedBox(height: 8),
          Text(
            'Android · iOS   /   1.0.0',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
