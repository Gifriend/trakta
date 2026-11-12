import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/bootstrap.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/strings.dart';
import '../../../core/widgets/app_widgets.dart';
import 'auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController();
  bool visible = false;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = ref.watch(bootstrapProvider).ready;
    final state = ready ? ref.watch(authControllerProvider) : null;
    final mode = state?.mode ?? AuthMode.login;
    final t = ref.watch(stringsProvider).t;
    final palette = Theme.of(context).extension<TraktaPalette>()!;
    final title = switch (mode) {
      AuthMode.login => 'Selamat datang kembali.',
      AuthMode.register => 'Mulai hari yang lebih teratur.',
      AuthMode.reset => 'Lupa kata sandi?',
    };
    final action = switch (mode) {
      AuthMode.login => 'Masuk',
      AuthMode.register => 'Buat akun',
      AuthMode.reset => 'Kirim tautan reset',
    };
    void submit() {
      if (!ready) return;
      FocusScope.of(context).unfocus();
      ref
          .read(authControllerProvider.notifier)
          .submit(
            name: name.text,
            email: email.text,
            password: password.text,
            locale: ref.read(stringsProvider).locale,
          );
    }

    return Scaffold(
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
      body: PageBody(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: palette.forest,
              borderRadius: BorderRadius.circular(palette.radius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.schedule_rounded, color: palette.lime, size: 38),
                const SizedBox(height: 20),
                Text(
                  t('Setiap hari,\nsatu langkah berarti.'),
                  style: Theme.of(
                    context,
                  ).textTheme.headlineLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 14),
                Text(
                  t('Presensi sederhana untuk hari kerja yang lebih teratur.'),
                  style: TextStyle(color: palette.lime, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(t(title), style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            t('Catat kehadiranmu, lanjutkan harimu.'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          if (!ready)
            Notice(
              t(
                ref.watch(bootstrapProvider).error ??
                    'Firebase belum dikonfigurasi. Isi konfigurasi mobile untuk mulai menggunakan akun.',
              ),
            ),
          if (state?.error != null) Notice(t(state!.error!), error: true),
          if (state?.message != null) Notice(t(state!.message!)),
          AutofillGroup(
            child: Column(
              children: [
                if (mode == AuthMode.register) ...[
                  TextField(
                    controller: name,
                    enabled: !(state?.busy ?? false),
                    autofillHints: const [AutofillHints.name],
                    textCapitalization: TextCapitalization.words,
                    maxLength: 80,
                    decoration: InputDecoration(labelText: t('Nama lengkap')),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: email,
                  enabled: !(state?.busy ?? false),
                  autofillHints: const [AutofillHints.email],
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: t('Email'),
                    prefixIcon: const Icon(Icons.alternate_email),
                  ),
                ),
                if (mode != AuthMode.reset) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: password,
                    enabled: !(state?.busy ?? false),
                    autofillHints: [
                      mode == AuthMode.register
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    obscureText: !visible,
                    autocorrect: false,
                    enableSuggestions: false,
                    onSubmitted: (_) => submit(),
                    decoration: InputDecoration(
                      labelText: t('Kata sandi'),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: t(
                          visible
                              ? 'Sembunyikan kata sandi'
                              : 'Tampilkan kata sandi',
                        ),
                        onPressed: () => setState(() => visible = !visible),
                        icon: Icon(
                          visible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (mode == AuthMode.login)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: ready && !state!.busy
                    ? () => ref
                          .read(authControllerProvider.notifier)
                          .changeMode(AuthMode.reset)
                    : null,
                child: Text(t('Lupa kata sandi?')),
              ),
            ),
          const SizedBox(height: 16),
          PrimaryAction(
            label: t(action),
            busy: state?.busy ?? false,
            onPressed: ready ? submit : null,
            icon: Icons.arrow_forward,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: ready && !state!.busy
                ? () {
                    password.clear();
                    ref
                        .read(authControllerProvider.notifier)
                        .changeMode(
                          mode == AuthMode.login
                              ? AuthMode.register
                              : AuthMode.login,
                        );
                  }
                : null,
            child: Text(
              t(
                mode == AuthMode.login
                    ? 'Belum punya akun? Daftar'
                    : 'Sudah punya akun? Masuk',
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'TRAKTA · ${t('Ruang pribadi')}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
