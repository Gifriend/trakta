# Konfigurasi Firebase dan Firestore

Proyek aplikasi ini: **`presensi-e558f`**, sesuai `VITE_FIREBASE_PROJECT_ID` di `.env`. Firebase CLI memakai target yang sama melalui `.firebaserc`.

Firebase digunakan untuk Authentication dan Firestore. Website dideploy secara terpisah ke Vercel sesuai [panduan Vercel](VERCEL.md). `firebase.json` hanya mengatur database, rules, indeks, dan emulator.

## 1. Pasang dependensi dengan Bun

```powershell
bun install --frozen-lockfile
```

Gunakan `bun.lock` sebagai lockfile. Perintah aplikasi adalah `bun run dev`, `bun run check`, dan `bun run build`. Firebase CLI tetap menggunakan runtime Node yang terpasang; tidak perlu memasang Firebase CLI global.

## 2. Login ke akun pemilik proyek

```powershell
bun run firebase:login --reauth
bun run firebase:databases
```

Login memakai akun Google yang memiliki akses ke proyek `presensi-e558f`. Jika perlu memilih akun lain:

```powershell
bunx --no-install firebase login:add
bunx --no-install firebase login:use EMAIL_AKUN_PEMILIK
```

Jika muncul `403 The caller does not have permission`, akun CLI belum memiliki izin yang diperlukan. Gunakan akun pemilik proyek, atau minta pemilik memberikan izin pengelolaan database, rules, dan indeks. Konfigurasi web `.env` tidak memberikan izin administratif untuk deploy.

## 3. Buat atau periksa database

Buka [Firestore proyek presensi-e558f](https://console.firebase.google.com/project/presensi-e558f/firestore).

Jika belum ada database, pilih **Create database** dengan pengaturan:

| Pengaturan                   | Nilai                       |
| ---------------------------- | --------------------------- |
| Edition                      | Standard                    |
| Database ID                  | `(default)`                 |
| Mode                         | Native / Firestore          |
| Location untuk database baru | `asia-southeast2` — Jakarta |
| Security rules awal          | Production mode             |

`firebase.json` menyertakan database, edition, lokasi, rules, dan indeks tersebut. Firebase CLI dapat membuat database default saat deploy pertama jika belum ada dan akun memiliki izin. Jika database sudah ada, lokasi tetap memakai lokasi database tersebut; konfigurasi ini tidak memindahkan data. Lokasi database baru harus ditentukan sebelum dibuat karena tidak dapat diubah setelahnya.

## 4. Terapkan rules dan indeks

Rules bawaan berikut menolak semua pembacaan dan penulisan, termasuk dari akun yang sudah login:

```text
allow read, write: if false;
```

Jika aplikasi menampilkan **Akses presensi belum diizinkan** atau versi sebelumnya menampilkan **Data belum dapat dimuat**, buka [Firestore → Rules](https://console.firebase.google.com/project/presensi-e558f/firestore/rules), **ganti seluruh isi editor dengan seluruh isi [firestore.rules](../firestore.rules)**, lalu pilih **Publish**. Gunakan database `(default)` pada proyek `presensi-e558f`. Setelah rules dipublikasikan, tekan **Muat ulang data** di aplikasi. Jika listener masih memakai rules sebelumnya, tunggu propagasi rules lalu coba kembali.

File lokal tidak otomatis mengubah rules yang aktif di Firebase. Deployment website ke Vercel juga tidak memublikasikan rules. Akun CLI yang terakhir diperiksa belum memiliki izin mengelola proyek (HTTP 403); gunakan Firebase Console dengan akun pemilik atau login CLI memakai akun yang memiliki izin. Mengganti rules ke akses publik tidak diperlukan.

Perintah CLI untuk menerapkan rules dan indeks yang sama:

```powershell
bun run firestore:deploy
```

Script hanya menargetkan Firestore. Perintah ini dijalankan terpisah ketika rules atau indeks berubah; tidak dijalankan otomatis oleh build Vercel. File yang diterapkan:

- `firestore.rules`: hanya pengguna terautentikasi yang dapat mengakses data miliknya. Timestamp harus berasal dari server, satu masuk/pulang per hari WIB, foto wajib dalam transaksi yang sama, dan catatan maksimal 300 karakter.
- `firestore.indexes.json`: field foto `base64` tidak diindeks. Query riwayat menggunakan indeks satu field `dateKey`, sehingga tidak membutuhkan composite index.

Presensi dan foto tidak dapat diedit atau dihapus lewat aplikasi. Rules khusus aplikasi ini tidak memberikan akses ke koleksi lain. Jika proyek dipakai aplikasi lain, gabungkan rules aplikasi tersebut sebelum deploy.

Alternatif melalui Console: buka tab **Rules**, salin seluruh isi `firestore.rules`, lalu **Publish**. Pengecualian indeks foto tetap perlu diterapkan lewat CLI atau konfigurasi single-field index Console untuk collection group `photos`, field `base64`.

## 5. Aktifkan Authentication

Buka [Authentication](https://console.firebase.google.com/project/presensi-e558f/authentication), aktifkan provider **Email/Password**, lalu periksa Authorized domains. Tambahkan hostname produksi Vercel (contoh `nama-proyek.vercel.app`), custom domain yang digunakan, serta `localhost` untuk pengembangan. Domain ditulis tanpa protokol atau path.

`.env` sudah tersedia di proyek ini dan tidak perlu ditimpa. Untuk setup di komputer lain, salin `.env.example` ke `.env` dan isi nilai konfigurasi Web app dari Firebase Project settings. Pastikan `VITE_FIREBASE_USE_EMULATORS=false` untuk Firebase produksi.

## 6. Jalankan dan verifikasi

```powershell
bun run dev
```

Daftar/login, kirim foto untuk masuk, lalu kirim foto pulang. Dokumen dibuat otomatis oleh transaksi aplikasi; tidak perlu membuat koleksi atau data contoh secara manual:

```text
users/{firebaseAuthUid}/attendance/{YYYYMMDD}
  dateKey: string
  checkIn: { timestamp: Timestamp, mode: string, note: string }
  checkOut: { timestamp: Timestamp, mode: string, note: string }

users/{firebaseAuthUid}/attendance/{YYYYMMDD}/photos/checkIn
users/{firebaseAuthUid}/attendance/{YYYYMMDD}/photos/checkOut
  base64: string
  bytes: integer <= 100000
  mimeType: "image/jpeg"
  createdAt: Timestamp
```

Dokumen `users/{uid}` sendiri tidak perlu dibuat; Firestore dapat memiliki subkoleksi tanpa dokumen induk. Foto asli dikompresi menjadi JPEG maksimal 100 KB, kemudian disimpan sebagai teks base64 pada dokumen foto. Waktu presensi memakai `serverTimestamp()` dan diverifikasi oleh rules.

Uji lokal tanpa menyentuh proyek produksi:

```powershell
bun run test:rules
```

Perintah ini menggunakan proyek emulator `demo-presensi`, terpisah dari target produksi. Java 21 diperlukan.

Referensi resmi: [Firebase CLI](https://firebase.google.com/docs/cli), [pengelolaan database](https://firebase.google.com/docs/firestore/manage-databases), [lokasi Firestore](https://firebase.google.com/docs/firestore/locations).
