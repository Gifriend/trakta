# Deployment website ke Vercel

Website Trakta menggunakan SvelteKit dengan adapter statis. Vercel menyajikan hasil build; Firebase menangani login dan penyimpanan presensi/foto.

| Bagian                 | Tempat                  | Konfigurasi                                                  |
| ---------------------- | ----------------------- | ------------------------------------------------------------ |
| Website, aset, dan PWA | Vercel                  | `vercel.json`                                                |
| Login pengguna         | Firebase Authentication | Firebase Console                                             |
| Presensi dan foto      | Cloud Firestore         | `firebase.json`, `firestore.rules`, `firestore.indexes.json` |
| Target proyek Firebase | Firebase CLI            | `.firebaserc`                                                |

## 1. Import repository

Push proyek ke repository Git milikmu, lalu pilih **Add New → Project** di Vercel dan import repository tersebut. Gunakan root directory yang berisi `package.json` dan `vercel.json`.

Pengaturan build sudah ada di `vercel.json`:

| Pengaturan       | Nilai                           |
| ---------------- | ------------------------------- |
| Framework Preset | Other (`framework: null`)       |
| Install Command  | `bun install --frozen-lockfile` |
| Build Command    | `bun run build`                 |
| Output Directory | `build`                         |

Preset Other digunakan karena proyek menghasilkan website statis melalui adapter SvelteKit yang sudah dikonfigurasi. Proses build tetap menjalankan SvelteKit. Tidak diperlukan adapter Vercel atau Vercel Functions untuk implementasi ini.

Gunakan versi Node build yang kompatibel dengan dependensi (pengembangan memakai Node 24). Commit `bun.lock` agar instalasi Vercel memakai versi dependensi yang sama.

## 2. Isi environment variables

Di **Project → Settings → Environment Variables**, salin nilai konfigurasi Web app Firebase yang sama dengan `.env` lokal:

```dotenv
VITE_FIREBASE_API_KEY=nilai_dari_firebase
VITE_FIREBASE_AUTH_DOMAIN=presensi-e558f.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=presensi-e558f
VITE_FIREBASE_APP_ID=nilai_dari_firebase
VITE_FIREBASE_USE_EMULATORS=false
```

Terapkan pada environment **Production** dan environment **Preview** jika preview perlu mengakses Firebase. Nilai `VITE_*` tertanam saat build, sehingga perubahan memerlukan deployment baru. `.env` lokal tidak diunggah ke Git. Vercel tidak membutuhkan akun admin Firebase, service account, atau token Firebase CLI untuk membangun website ini.

Jika Preview memakai proyek Firebase produksi yang sama, data presensi yang dikirim dari Preview juga masuk ke database produksi. Gunakan proyek Firebase terpisah untuk pengujian jika diperlukan.

## 3. Atur domain Firebase Authentication

Sesudah mendapatkan URL produksi, buka [Firebase Authentication](https://console.firebase.google.com/project/presensi-e558f/authentication) → **Settings → Authorized domains**. Tambahkan hostname Vercel produksi dan custom domain yang digunakan, tanpa `https://` atau path.

`VITE_FIREBASE_AUTH_DOMAIN` tetap memakai domain Web app Firebase. Domain website Vercel didaftarkan pada Authorized domains. Provider yang digunakan aplikasi ini adalah Email/Password.

## 4. Deploy Firestore secara terpisah

Jalankan dari komputer yang sudah login Firebase dengan akun yang memiliki izin:

```powershell
bun run firebase:login
bun run firestore:deploy
```

Perintah tersebut menerapkan rules dan indeks ke proyek `presensi-e558f`. Deployment Vercel tidak menjalankan Firebase CLI. Pengubahan UI cukup melalui deployment Vercel; pengubahan rules/indeks memerlukan perintah Firestore di atas. Panduan rinci ada di [FIREBASE.md](FIREBASE.md).

## 5. Verifikasi setelah deployment

1. Buka URL HTTPS produksi dan login.
2. Kirim presensi masuk/pulang menggunakan foto, lalu periksa riwayat.
3. Coba pasang PWA dari browser yang mendukung.
4. Setelah kunjungan online pertama, buka ulang aplikasi saat offline untuk memeriksa shell PWA. Pengiriman presensi tetap membutuhkan internet.

Header keamanan dan `Cache-Control: no-cache` untuk `service-worker.js` berada di `vercel.json`. Aset, manifest, dan service worker disajikan melalui domain Vercel yang sama. Konfigurasi ini tidak menambahkan rewrite semua request ke HTML, sehingga file PWA yang tidak ditemukan tetap menghasilkan 404.

Referensi: [Konfigurasi vercel.json](https://vercel.com/docs/project-configuration/vercel-json), [konfigurasi build](https://vercel.com/docs/builds/configure-a-build).
