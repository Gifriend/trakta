# Kontribusi ke Trakta

## Menjalankan proyek

```powershell
bun install --frozen-lockfile
bun run dev
```

Salin `.env.example` menjadi `.env` hanya untuk setup baru. Isi konfigurasi lokal sendiri. `bun.lock` dikomit agar versi dependensi konsisten.

## Conventional Commits

Gunakan format `type(scope): ringkasan`, dengan satu tujuan utama per commit:

| Tipe       | Contoh penggunaan                                |
| ---------- | ------------------------------------------------ |
| `feat`     | Fitur kamera, galeri, atau presensi              |
| `fix`      | Perbaikan bug atau penanganan error              |
| `build`    | Konfigurasi Bun, build, atau Vercel              |
| `chore`    | Konfigurasi repository dan tooling               |
| `test`     | Pengujian tanpa perubahan fitur                  |
| `docs`     | Panduan setup, penggunaan, atau deployment       |
| `refactor` | Perubahan struktur kode tanpa perubahan perilaku |

Contoh:

```text
feat(camera): add automatic capture and gallery selection
fix(attendance): explain denied Firestore access
build(vercel): separate static hosting from Firebase
docs: explain Firebase rules deployment
```

Gunakan body commit jika perlu menjelaskan alasan atau batasan perubahan. Untuk perubahan yang memutus kompatibilitas, tambahkan `!` setelah tipe/scope dan jelaskan `BREAKING CHANGE:` pada body.

## File untuk GitHub

| Dikomit                                                   | Diabaikan `.gitignore`                              |
| --------------------------------------------------------- | --------------------------------------------------- |
| `src/`, `static/`, ikon PWA                               | `node_modules/`, `.svelte-kit/`, `build/`           |
| `package.json`, `bun.lock`, konfigurasi build/lint        | Lockfile package manager lain                       |
| `.env.example` berisi placeholder                         | `.env` dan seluruh `.env.*` berisi nilai lokal      |
| `firebase.json`, `.firebaserc`, rules dan indeks          | Service account, private key, dan kredensial cloud  |
| `vercel.json`                                             | `.vercel/`, state hosting dan emulator              |
| `tests/`, `scripts/`, dokumentasi                         | Log, screenshot pengujian, profil browser, coverage |
| Rekomendasi `.vscode/settings.json` dan `extensions.json` | State editor lain dan file OS                       |
| Source aplikasi                                           | Skill/agent lokal `.agents/`, `.claude/`, `.codex/` |

`.firebaserc` memuat ID proyek yang digunakan CLI; ID proyek bukan kredensial. Konfigurasi web Firebase memakai variabel `VITE_*` dan tersedia pada build browser, sementara private key/service account tidak boleh dimasukkan ke source atau variabel `VITE_*`.

`static/` tetap dikomit karena berisi manifest dan ikon aplikasi. Jangan menyimpan foto presensi nyata di folder source; aplikasi menyimpannya ke Firestore. `test-results/` serta `uploads/` diabaikan untuk hasil lokal. `.prettierignore` hanya mengatur formatter dan tidak menentukan file yang dikirim ke GitHub.

Jika file rahasia terlanjur pernah dikomit, menambahkannya ke `.gitignore` tidak menghapusnya dari riwayat. Ganti kredensial yang terpapar dan tangani riwayat secara terpisah sebelum publikasi.

## Pemeriksaan sebelum commit

```powershell
bun run check
bun run test:unit --run --project server
bun run build
git diff --cached --check
git diff --cached --stat
```

Untuk perubahan kamera, jalankan `bun run test:browser` dengan Firebase Emulator dan server lokal dalam mode emulator. Script memakai kamera virtual Chrome sehingga tidak mengambil gambar dari webcam pribadi.

Periksa isi file yang di-stage sebelum commit. Commit lokal tidak otomatis mengirim kode ke GitHub. Panduan deployment website ada di [docs/VERCEL.md](docs/VERCEL.md); rules Firestore diterapkan terpisah sesuai [docs/FIREBASE.md](docs/FIREBASE.md).
