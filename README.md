# Trakta

Aplikasi presensi Svelte 5 + SvelteKit + TypeScript, Firebase Authentication, Cloud Firestore, dan PWA. Antarmuka berbahasa Indonesia, responsif untuk desktop dan ponsel.

## Fitur

- Daftar, masuk, keluar, dan pemulihan kata sandi lewat email Firebase.
- Presensi masuk dan pulang, satu kali masing-masing per hari **Asia/Jakarta (WIB)**.
- Pilihan kerja di kantor, dari rumah, atau dinas luar; catatan opsional maksimal 300 karakter.
- Kamera depan otomatis dibuka saat form presensi siap. Ambil foto langsung, atau gunakan tombol **Pilih galeri/file** untuk memilih JPG, PNG, WebP maksimal 20 MB; kompresi JPEG di perangkat hingga **maksimal 100.000 byte (100 KB)** sebelum upload.
- Timestamp server Firestore untuk kedua presensi. Rules menolak timestamp buatan klien, tanggal berbeda, presensi ganda, dan pulang sebelum masuk.
- Riwayat 31 hari presensi terakhir, ringkasan bulan berjalan, durasi, catatan, serta lihat foto sesuai kebutuhan.
- PWA: shell aplikasi dapat dibuka offline setelah kunjungan online; pengiriman presensi memerlukan koneksi dan konfirmasi server.

## Setup Firebase

Target Firebase CLI sudah diatur ke `presensi-e558f` melalui `.firebaserc`. Panduan khusus database, rules, indeks, dan penanganan izin: [Konfigurasi Firebase dan Firestore](docs/FIREBASE.md).

Gunakan **Bun 1.4.2 atau lebih baru** untuk mengelola dependensi dan menjalankan script. `bun.lock` adalah lockfile proyek. Node yang kompatibel tetap diperlukan oleh beberapa CLI pengembangan (lingkungan pengembangan: Node 24), dan Java 21 untuk Firebase Emulator.

```powershell
bun install --frozen-lockfile
# Hanya untuk setup baru, bila .env belum tersedia:
Copy-Item .env.example .env
```

1. Buat proyek di [Firebase Console](https://console.firebase.google.com/).
2. Tambahkan **Web app** pada Project settings. Salin `apiKey`, `authDomain`, `projectId`, dan `appId` ke variabel `VITE_FIREBASE_*` di `.env`.
3. Aktifkan **Authentication → Sign-in method → Email/Password**. Tambahkan domain aplikasi ke Authorized domains (termasuk `localhost` untuk development bila belum ada).
4. Buat **Cloud Firestore database (Standard edition)** dalam mode produksi, lalu deploy rules berikut. Jangan gunakan rules akses publik.

```powershell
bun run firebase:login
bun run firestore:deploy
bun run dev --host 127.0.0.1
```

Buka URL lokal Vite. Daftar akun, login, pilih lokasi kerja, tambahkan foto/catatan, lalu kirim masuk. Form berubah menjadi presensi pulang setelah server menerima presensi masuk.

Konfigurasi web Firebase bersifat publik dan tertanam di build browser. Jangan menaruh private key atau service account di variabel `VITE_*`. Pembatasan akses data ada di `firestore.rules`.

## Lokal tanpa akun Firebase

Emulator membutuhkan Java 21. Di `.env`, kosongkan empat nilai konfigurasi dan ubah `VITE_FIREBASE_USE_EMULATORS=true`. Jalankan dua terminal:

```powershell
bun run emulators
```

```powershell
bun run dev --host 127.0.0.1
```

Auth: `127.0.0.1:9099`; Firestore: `127.0.0.1:8085`; Emulator UI: `127.0.0.1:4000`. Data emulator sementara. Jangan aktifkan mode emulator pada produksi atau saat menguji dari ponsel lain, karena loopback menunjuk perangkat tersebut.

## Struktur folder

```text
src/
  lib/
    components/       # AuthPanel, Dashboard, AttendanceForm, History, PwaInstall
    firebase/         # SDK, auth, transaksi dan query presensi
    types/            # Tipe domain presensi
    utils/            # Kompresi foto dan tanggal WIB
  routes/             # Halaman, layout, token dan gaya global
  service-worker/     # Cache shell publik
static/
  icons/              # Ikon PNG biasa dan maskable
  manifest.webmanifest
tests/
  firestore.rules.test.mjs
firestore.rules
firestore.indexes.json
firebase.json         # Firestore dan emulator
vercel.json           # Deployment website statis ke Vercel
```

Komponen memakai runes Svelte 5, event handler modern, derived state, cleanup listener, dan layanan terpisah. State autentikasi dimiliki halaman dan tidak dibagikan lintas request SSR.

## Data Firestore

```text
users/{uid}/attendance/{YYYYMMDD}
  dateKey: "20261110"
  checkIn:  { timestamp: Timestamp, mode: "office", note: "..." }
  checkOut: { timestamp: Timestamp, mode: "office", note: "..." }  # setelah pulang

users/{uid}/attendance/{YYYYMMDD}/photos/{checkIn|checkOut}
  base64: "..."
  bytes: 98432
  mimeType: "image/jpeg"
  createdAt: Timestamp
```

Ringkasan dan foto ditulis dalam **satu transaksi atomik**; tidak ada presensi sah tanpa foto. Foto terpisah supaya daftar riwayat tidak mengunduh gambar. Base64 memiliki overhead sekitar 33%; 100 KB gambar menjadi sekitar 133 KB teks. Indeks field `base64` dinonaktifkan.

Rules memeriksa ukuran hasil decode dari panjang base64 dan padding, termasuk menolak ukuran yang dipalsukan. Rules tidak memverifikasi isi visual foto atau identitas wajah. Pengguna dapat membaca data sendiri, tetapi tidak dapat mengubah/menghapus presensi atau foto. Pengelola proyek Firebase tetap memiliki akses administratif.

Tanggal hari diverifikasi dengan waktu server + 7 jam. Jam perangkat hanya untuk tampilan dan menentukan dokumen yang diminta; jam yang salah dapat menyebabkan penolakan. Pulang harus pada hari WIB yang sama; shift melewati tengah malam belum didukung. Durasi adalah rentang masuk–pulang tanpa pengurangan istirahat. Belum ada validasi GPS, jadwal kerja, atau keterlambatan.

## Validasi

```powershell
bun run check
bun run test:unit --run --project server
bun run test:rules
bun run build
```

`test:rules` menjalankan emulator untuk memeriksa akses antar akun, timestamp, tanggal WIB, foto atomik, duplikasi, perubahan data, ukuran foto, dan validasi field. Kompresi gambar dan alur antarmuka diverifikasi menggunakan browser asli.

`bun run test:browser` menguji alur penuh dengan Chrome yang sudah terpasang, server development di port 5173 dalam mode emulator, serta Auth/Firestore Emulator aktif. Script membuat akun uji dan presensi pada emulator. `bun run test:pwa` memeriksa manifest, installability, cache shell, dan reload offline pada preview produksi port 4173. Hasil screenshot disimpan di `test-results/` (diabaikan Git). Jangan menjalankan build bersamaan dengan preview; mulai ulang preview setelah build baru.

`bun run validate:svelte` menjalankan autofixer resmi dari skill Svelte. Referensi elemen `bind:this` digunakan untuk membuka pemilih file native dan mengendalikan dialog foto; tidak ada manipulasi DOM untuk rendering aplikasi.

## Build dan PWA

```powershell
# Isi .env produksi, set USE_EMULATORS=false, lalu build.
bun run build
bun run preview --host 127.0.0.1

# Terpisah: deploy rules dan indeks Firestore
bun run firestore:deploy
```

Website dipublikasikan ke **Vercel** menggunakan `vercel.json`. Adapter statis menghasilkan folder `build/` tanpa server Node pada runtime. Vercel menjalankan `bun install --frozen-lockfile` dan `bun run build`. Panduan import proyek, environment variables, dan domain: [Deployment Vercel](docs/VERCEL.md).

Firebase mengelola Authentication dan Firestore. Deployment rules/indeks menggunakan `bun run firestore:deploy`, terpisah dari deployment website. Script `firebase:deploy` tetap tersedia sebagai alias untuk perintah Firestore tersebut.

Set variabel `VITE_FIREBASE_*` di pengaturan Environment Variables Vercel, dengan `VITE_FIREBASE_USE_EMULATORS=false`. Build ulang/redeploy setelah mengubah nilai konfigurasi.

PWA aktif pada build produksi di HTTPS/localhost. Android/desktop: tombol **Pasang aplikasi** atau menu browser. iPhone: Safari → Bagikan → Tambahkan ke Layar Utama. Service worker hanya menyimpan build, ikon, dan shell publik; tidak menyimpan respons Auth, dokumen Firestore, atau foto. Firestore memakai cache memori SDK, bukan persistent offline cache. Sesi login tetap dikelola Firebase Auth pada browser; gunakan Keluar pada perangkat bersama.

Ikon dapat dibuat ulang dengan `python scripts/generate-icons.py` (Pillow).

Kamera langsung membutuhkan HTTPS/localhost, dukungan browser, serta izin kamera dari pengguna. Jika akses ditolak atau kamera tidak tersedia, pilihan galeri/file tetap dapat dipakai. Kamera dimatikan setelah foto diambil, saat beralih ke galeri, saat tab disembunyikan, atau saat formulir ditutup. Foto baru dikirim bersama konfirmasi presensi.

Referensi: [Firebase auth](https://firebase.google.com/docs/auth/web/password-auth), [transaksi Firestore](https://firebase.google.com/docs/firestore/manage-data/transactions), [security rules](https://firebase.google.com/docs/firestore/security/rules-fields), [service worker SvelteKit](https://svelte.dev/docs/kit/service-workers).
