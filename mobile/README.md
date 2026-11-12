# Trakta mobile

Aplikasi Flutter Android/iOS yang menggunakan Firebase Authentication dan Cloud Firestore **yang sama dengan web Trakta**. Folder web tetap di root; seluruh aplikasi native berada di `mobile/`.

## Menjalankan aplikasi

Gunakan Flutter **3.41.6 / Dart 3.11.4** atau versi kompatibel. Dependency dikunci melalui `pubspec.lock`.

```powershell
cd mobile
flutter pub get
Copy-Item config/firebase.example.json config/firebase.json
# Isi config/firebase.json, lalu:
flutter run --dart-define-from-file=config/firebase.json
```

Jika konfigurasi belum diisi, aplikasi menampilkan layar masuk dan pengaturan tema tanpa menginisialisasi Firebase. Tidak ada akun atau data presensi contoh yang disisipkan ke database.

## Firebase: isi konfigurasi per platform

Pada project Firebase web yang sama (target repo: `presensi-e558f`), tambahkan dua aplikasi:

| Platform | Identifier | Nilai konfigurasi |
|---|---|---|
| Android | `com.trakta.trakta_mobile` | `FIREBASE_API_KEY_ANDROID`, `FIREBASE_APP_ID_ANDROID` |
| iOS | `com.trakta.traktaMobile` | `FIREBASE_API_KEY_IOS`, `FIREBASE_APP_ID_IOS`, `FIREBASE_IOS_BUNDLE_ID` |
| Keduanya | Project Firebase web | `FIREBASE_PROJECT_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_STORAGE_BUCKET` (opsional) |

Gunakan **App ID Android/iOS**, bukan App ID web. `messagingSenderId` adalah nomor project; field ini dibutuhkan oleh `FirebaseOptions`, aplikasi ini tidak mengaktifkan push notification.

Nilai dapat dilihat di Firebase Console atau berkas konfigurasi aplikasi yang diunduh dari Console. `config/firebase.json` diabaikan Git. Firebase diinisialisasi dengan opsi Dart sehingga Authentication/Firestore tidak membutuhkan berkas native untuk build ini. Jangan menaruh service-account/private key di aplikasi.

Aktifkan Email/Password Authentication. Pakai database `(default)` dan deploy rules serta indexes yang sudah ada dari root repo:

```powershell
bun run firestore:deploy
```

Tidak ada koleksi baru atau perubahan rules untuk mobile. Path data tetap:

```text
users/{uid}/attendance/{YYYYMMDD}
users/{uid}/attendance/{YYYYMMDD}/photos/{checkIn|checkOut}
```

Presensi dan foto disimpan dalam satu transaksi, menggunakan server timestamps. Request memerlukan koneksi dan konfirmasi server. Foto maksimum 100.000 bytes JPEG; kantor memerlukan kamera, radius 150 m dari `(-6.2517753, 106.8422473)`, dan akurasi <=100 m. Lokasi direkam ketika foto diambil/dipilih. Dokumen lama tanpa `photoLocation` tetap terbaca. Hari menggunakan UTC+7/WIB, terlepas dari timezone perangkat. Shift lintas tengah malam mengikuti batasan web: checkout hanya pada hari WIB yang sama.

## Emulator Firebase

Di root repo, jalankan `bun run emulators` (Java 21). Pada terminal lain:

```powershell
cd mobile
# Android Emulator menggunakan 10.0.2.2 untuk mengakses komputer host.
flutter run --dart-define-from-file=config/emulators.android.json
# iOS Simulator pada Mac menggunakan 127.0.0.1.
flutter run --dart-define-from-file=config/emulators.ios.json
```

Keduanya memakai `demo-presensi`, Auth 9099 dan Firestore 8085. Config emulator tidak berisi key production. Build release menolak mode emulator. Pada perangkat fisik, gunakan alamat LAN host dan pastikan emulator Firebase mendengarkan pada interface LAN serta firewall mengizinkan koneksi.

## Android

- Minimum Android 7 / API 24; compile/target SDK mengikuti Flutter.
- Izin Internet, kamera, lokasi precise/coarse; kamera hardware bersifat opsional.
- Audio dan background location tidak diminta. Galeri memakai system picker.
- Cleartext hanya di manifest debug/profile untuk emulator. Backup aplikasi dinonaktifkan.
- Android SDK Platform 36, build tools, platform tools, command-line tools, JDK yang kompatibel, dan lisensi SDK diperlukan.

```powershell
flutter build apk --debug --dart-define-from-file=config/firebase.json
# Release: isi android/key.properties berdasarkan android/key.properties.example.
flutter build appbundle --release --dart-define-from-file=config/firebase.json
```

Signing release menggunakan keystore sendiri; tidak ada fallback ke debug signing. Keystore dan `key.properties` tidak di-commit. Sesuaikan identifier di Gradle, paket Kotlin, Firebase, dan dokumentasi bersama-sama bila akan diganti.

## iOS dan Liquid Glass

- Minimum deployment iOS **15.0**, termasuk Podfile dan target Xcode.
- Build iOS memerlukan **macOS + Xcode 26 atau lebih baru**, CocoaPods, dan signing Apple untuk perangkat/distribusi.
- Usage descriptions kamera, galeri, dan lokasi foreground sudah ada. Mode lokal memakai `NSAllowsLocalNetworking`; tidak ada pengecualian arbitrary loads global.
- Buka `ios/Runner.xcworkspace`, pilih development team dan provisioning untuk bundle `com.trakta.traktaMobile`.

```sh
flutter pub get
cd ios && pod install && cd ..
flutter build ios --no-codesign --dart-define-from-file=config/firebase.json
flutter build ipa --dart-define-from-file=config/firebase.json
```

Tema **Liquid Glass** tersedia di pengaturan. SDK lokal Flutter 3.41.6 belum menyediakan kontrol native Liquid Glass secara langsung; integrasi memakai [`cupertino_native`](https://pub.dev/packages/cupertino_native) yang menanamkan UIKit melalui platform views. Tab bar, tombol aksi utama, dan switch menggunakan kontrol native pada iOS; tampilan native bergantung versi OS, dengan glass pada iOS 26+. Bagian konten mempertahankan warna dan hierarki Trakta.

Pada Android, pilihan yang sama memakai permukaan kaca yang dirender Flutter (blur, tint, border), bukan material UIKit Apple. Pengaturan **Kurangi transparansi** dan mode high contrast menggunakan permukaan solid. Tetap lakukan QA native pada perangkat iOS 26+ sebelum distribusi karena paket native tersebut merupakan integrasi komunitas.

## Fitur dan struktur

- Email login, pendaftaran nama 2–80 karakter/password minimal 8, reset password, logout.
- Ringkasan hari ini/bulan ini; presensi masuk/pulang dengan foto, lokasi, mode kantor/rumah/dinas, dan catatan 300 karakter.
- Riwayat 10 baris per halaman, filter mulai/akhir, detail foto yang dimuat saat diminta.
- Ekspor `.xlsx` seluruh hasil filter, termasuk foto tertanam opsional. Tanggal/jam/durasi adalah sel numerik; catatan adalah sel teks, sehingga tidak menjadi formula.
- 10 efek kamera, kamera depan/belakang, koreksi mirror; kompresi foto dilakukan di isolate dan metadata EXIF dibuang.
- Editor: rotasi, square crop, bingkai none/love/stars/retro, caption 60 karakter, hingga 20 stiker dengan posisi, ukuran dan rotasi yang dapat diatur tanpa mengandalkan drag.
- Fotobox 2/3/4 pose, timer 0/3/5 detik, strip/grid, warna bingkai, retake, edit hasil, simpan/bagikan melalui share sheet sistem. Foto booth tidak dikirim ke Firebase. Pada iOS pilih Save to Files, pada Android pilih tujuan penyimpanan/aplikasi yang tersedia.
- Delapan tema web + Liquid Glass, light/dark, Indonesia/English; font Inter disertakan lokal.

```text
lib/
  core/
    config/       # Firebase bootstrap dan dart-define
    models/       # Attendance, lokasi, foto, stiker
    services/     # Aturan bisnis, lokasi, pemrosesan foto, ekspor, sharing
    routing/      # GoRouter + AppRoutes + auth redirect
    theme/        # Token warna dari CSS web
    utils/        # WIB, i18n, error mapping
    widgets/      # Brand, surface, tombol, adaptive shell
  features/
    auth/
    attendance/
    camera/
    dashboard/
    history/
    photo_editor/
    booth/
    settings/
```

Mengikuti pola referensi Inspire: `data/repositories`, `presentations/*_controller.dart`, `*_state.dart`, `*_screen.dart`. UI mengamati Riverpod 2 `StateNotifierProvider`; controller memanggil service/repository. State multi-field memakai Freezed; berkas generated dihasilkan build_runner dan di-commit. Transport memakai Firebase langsung karena backend web juga Firebase; tidak menambahkan Dio atau token cache terpisah.

## Validasi

```powershell
dart run build_runner build
dart format --output=none --set-exit-if-changed lib test integration_test tool
flutter analyze
flutter test
# Menghasilkan pratinjau UI dari widget tests di .tmp/previews (tidak di-commit).
flutter test test/app_flow_test.dart --dart-define=CAPTURE_PREVIEWS=true
# Regenerasi ikon dari logo web.
dart run tool/generate_icons.dart
```

Untuk tes FlutterFire native, jalankan emulator Firebase dan sebuah perangkat/emulator Android atau iOS:

```powershell
flutter test integration_test/firebase_attendance_test.dart -d DEVICE_ID --dart-define-from-file=config/emulators.android.json
```

Tes tersebut membuat akun dan presensi **hanya pada emulator** serta menolak konfigurasi production. Tes rules lintas akun, timestamp, atomicity dan geofence yang sudah ada tetap dijalankan dari root dengan `bun run test:rules`.

Periksa juga pada perangkat fisik: izin ditolak/permanen, lokasi kurang akurat, kamera background/resume, picker dibatalkan, koneksi putus saat submit, checkout hari berikutnya, share sheet iPad, teks besar, dan native Liquid Glass. Build iOS tidak dapat dijalankan dari Windows.

Referensi: [Firebase Flutter setup](https://firebase.google.com/docs/flutter/setup), [Flutter iOS setup](https://docs.flutter.dev/platform-integration/ios/setup), [cupertino_native](https://pub.dev/packages/cupertino_native).
