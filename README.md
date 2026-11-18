# PoliVent

**Temukan. Daftar. Hadiri.**

Aplikasi mobile untuk menemukan dan mengikuti event kampus **Politeknik Negeri
Lampung (Polinela)**. Mahasiswa dapat mencari seminar, workshop, webinar, lomba,
dan kegiatan kampus lainnya, mendaftar secara online, lalu mendapatkan **tiket
digital berisi QR Code**. Event berbayar memakai **satu QRIS global**: peserta
memindai QR, mengunggah bukti bayar, lalu admin memverifikasi sebelum tiket
terbit. Admin juga mengelola event, harga tiket, peserta, dan pembayaran.

> Project mata kuliah **Pemrograman Aplikasi Mobile** — Politeknik Negeri Lampung, 2026.

---

## 1. Fitur

### Mahasiswa
- Register, login, logout, dan session yang tersimpan (token).
- **Login** — kartu kontak admin (nomor dari server + tombol **Salin**) muncul di
  bawah tautan daftar; otomatis disembunyikan jika admin belum mengisi nomor.
- **Home** — sapaan, pencarian, event pilihan, kategori, event terbaru.
- **Explore** — pencarian (judul, deskripsi, penyelenggara, lokasi, kategori) +
  filter kategori.
- **Detail event** — banner, kategori, deskripsi, jadwal, lokasi, penyelenggara,
  harga tiket, jumlah peserta, sisa kuota.
- **Pendaftaran** — peserta dapat mengubah nama, NIM, dan email khusus untuk event tersebut sebelum mengonfirmasi. Jika admin mengaktifkan wajib KTM pada event, peserta harus mengunggah foto KTM sebelum daftar/tiket/pembayaran dapat dilanjutkan. KTM disimpan privat dan hanya dapat diakses peserta pemilik atau admin.
- **Event gratis** — tiket QR langsung terbit setelah mendaftar.
- **Event berbayar** — halaman pembayaran berisi nominal, **QRIS global**, nama
  pemilik & nomor tujuan (bisa disalin), lalu unggah bukti bayar. Status:
  belum bayar → menunggu verifikasi → lunas / ditolak (bisa unggah ulang).
  **Tiket baru terbit setelah admin memverifikasi.**
- **My Event** — tab *Upcoming* dan *History* + badge status pembayaran dan
  tombol *Bayar* / *Lihat Tiket*.
- **Tiket digital** — nama event, nama peserta, NIM, tanggal, waktu, lokasi,
  ticket code, dan **QR Code**.
- **Profil** — edit profil, My Event, Tentang PoliVent, logout.

### Admin
- **Dashboard** — total event, event aktif, total peserta, event selesai,
  pembayaran menunggu verifikasi, pendapatan terverifikasi, daftar event
  mendatang.
- **CRUD event** — judul, kategori, deskripsi, banner (galeri/kamera), tanggal,
  jam mulai, jam selesai, lokasi, penyelenggara, kuota, **harga tiket**
  (0 = gratis), toggle **wajib unggah KTM**, jenis peserta individu/tim, dan
  **tanggal + jam batas akhir pendaftaran** per event.
- **Pembayaran** — daftar pembayaran semua event berbayar, ringkasan status,
  pencarian nama/NIM/event, lihat bukti (bisa di-zoom), **verifikasi** (tiket
  langsung terbit) atau **tolak** dengan alasan.
- **Pengaturan Pembayaran** — unggah/ganti **satu QRIS global** untuk semua
  event berbayar, nama pemilik, nomor tujuan/NMID, catatan, dan **kontak admin**
  (nomor HP/WA yang tampil di halaman login).
- **Daftar peserta** per event + pencarian nama/NIM/email/ticket code.

### Perilaku sistem
- Event selesai atau kuota penuh tidak bisa didaftari (validasi di Laravel).
- Pendaftaran ganda ditolak.
- Event berbayar: tiket `null` sampai pembayaran diverifikasi admin; penolakan
  membatalkan tiket dan peserta dapat mengunggah bukti baru.
- Loading, error (dengan tombol *Coba Lagi*), dan empty state di semua layar data.

---

## 2. Teknologi

| Lapisan | Teknologi |
| --- | --- |
| Mobile app | Flutter 3.47 / Dart 3.13 |
| HTTP client | `http` |
| Local storage | `shared_preferences` |
| QR Code | `qr_flutter` |
| Pilih gambar | `image_picker` |
| Lokalisasi | `flutter_localizations` (id_ID) |
| Backend | Laravel 13 REST API + Sanctum |
| Database | MySQL (XAMPP) |

State management memakai `ChangeNotifier` + `ValueNotifier` bawaan Flutter —
tanpa dependency tambahan, cukup untuk skala project ini.

---

## 3. Arsitektur

```text
Flutter App (UI + state lokal)
        │  HTTP / JSON  (Bearer token)
        ▼
Laravel REST API (/api)
        │  Eloquent ORM
        ▼
MySQL (polivent)
```

Aturan yang dipegang:
- Semua HTTP request lewat `services/` — **tidak ada HTTP di widget**.
- Base URL hanya ada di satu file: `lib/config/api_config.dart`.
- Validasi dilakukan di Flutter **dan** di Laravel; authorization hanya di Laravel.
- Token disimpan di `shared_preferences` (password tidak pernah disimpan).

### Sistem desain

- Warna, radius, spacing, bayangan, dan durasi animasi punya token di
  `lib/config/app_theme.dart` (`AppColors`, `AppRadius`, `AppSpacing`,
  `AppShadows`, `AppMotion`) — widget tidak memakai angka/hex acak.
- Header Home memakai gradien brand + ornamen `DecorativePattern` (CustomPainter).
- Kartu event/pendaftaran diberi bayangan lembut dan `PressScale` (umpan balik
  tekan 0,97×, otomatis batal saat user scroll).
- List memakai `FadeSlideIn` (fade + geser, stagger ringan) saat pertama tampil.
- Loading data memakai skeleton shimmer (`EventListSkeleton`) alih-alih spinner
  kosong; refresh tidak menghapus konten yang sudah ada.
- Bar kuota di detail event dianimasikan dengan `TweenAnimationBuilder`.
- Semua animasi hanya mengubah opacity/transform dan controller di-`dispose`.

---

## 4. Struktur Project

```text
lib/
├── main.dart                     Root app, routing, lokalisasi, 401 handler
├── config/
│   ├── api_config.dart           Satu-satunya sumber Base URL
│   ├── app_theme.dart            AppColors, AppTextStyles, AppRadius, AppTheme
│   ├── routes.dart               Nama route
│   └── app_navigator.dart        Global navigator key
├── models/                       User, Category, Event, Registration, Payment,
│                                 PaymentSetting
├── services/
│   ├── api_service.dart          HTTP layer + ApiException
│   ├── app_info_service.dart     Info publik (kontak admin untuk login)
│   ├── auth_service.dart         Login/register/logout/session
│   ├── event_service.dart        Event, kategori, statistik, peserta
│   ├── registration_service.dart Pendaftaran, tiket, unggah bukti bayar
│   └── payment_service.dart      QRIS, verifikasi/tolak, pengaturan admin
├── screens/
│   ├── splash/
│   ├── auth/                     login, register
│   ├── home/                     main_shell (bottom nav), home
│   ├── explore/
│   ├── event/                    detail, konfirmasi pendaftaran
│   ├── payment/                  QR pembayaran + unggah bukti
│   ├── ticket/
│   ├── my_event/
│   ├── profile/                  profil, edit profil, about
│   └── admin/                    shell, dashboard, CRUD event, peserta,
│                                 pembayaran, pengaturan QRIS
├── widgets/                      app_logo, admin_contact_card, custom_button,
│                                 custom_text_field, category_chip, event_banner,
│                                 event_card, section_header, empty, error,
│                                 status_badge, loading, skeleton, press_scale,
│                                 fade_slide_in, decorative_pattern
└── utils/                        storage, validators, formatters, json_helper,
                                  app_events, feedback
test/
├── models_test.dart              Model, validator, formatter
├── ui_widgets_test.dart          Skeleton, PressScale, FadeSlideIn, header,
│                                 banner, salin kontak admin
└── widget_test.dart              Widget test halaman login
```

---

## 5. Requirements

- Windows 10/11
- **XAMPP** (MySQL/MariaDB + PHP 8.3+)
- **Composer**
- **Flutter SDK 3.35+** (diuji pada 3.47.5 / Dart 3.13.4)
- **Android Studio** (SDK + emulator) atau HP Android dengan USB debugging

Cek environment:

```bash
flutter doctor
```

---

## 6. Setup Database & Laravel

Backend berada di **`D:\xampp\htdocs\polivent_api`** (di luar folder Flutter).

```bash
# 1. Aktifkan MySQL dari XAMPP Control Panel

# 2. Buat database
D:\xampp\mysql\bin\mysql.exe -u root -e "CREATE DATABASE IF NOT EXISTS polivent CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# 3. Setup & seed Laravel
cd D:\xampp\htdocs\polivent_api
composer install
php artisan migrate:fresh --seed
php artisan storage:link

# 4. Jalankan API
php artisan serve
```

API tersedia di `http://127.0.0.1:8000`.
Dokumentasi endpoint lengkap: `D:\xampp\htdocs\polivent_api\README.md`.

`.env` yang dipakai:

```env
APP_NAME=PoliVent
APP_URL=http://127.0.0.1:8000

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=polivent
DB_USERNAME=root
DB_PASSWORD=
```

---

## 7. Setup Flutter

```bash
cd D:\project\polivent
flutter pub get
flutter run
```

---

## 8. Konfigurasi API

Semua pengaturan alamat server ada di **`lib/config/api_config.dart`**:

| Perangkat | Base URL | Cara |
| --- | --- | --- |
| Android Emulator | `http://10.0.2.2:8000/api` | otomatis |
| Windows / Web / Desktop | `http://127.0.0.1:8000/api` | otomatis |
| HP Android fisik | `http://<IP-LAN>:8000/api` | `--dart-define` (disarankan) atau `_lanOverride` |

Untuk HP fisik:

1. Cari IP laptop: `ipconfig` → misal `192.168.1.10`.
2. Jalankan aplikasi dengan alamat API tersebut — tanpa mengubah kode:

```bash
flutter run -d <device-id> --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
```

Alternatif permanen: isi `_lanOverride` di `api_config.dart` dengan nilai yang
sama. Nilai `--dart-define` selalu menang atas `_lanOverride`.

3. Jalankan API agar bisa diakses dari jaringan:

```bash
php artisan serve --host=0.0.0.0 --port=8000
```

4. Pastikan HP dan laptop berada di Wi-Fi yang sama, lalu izinkan
   **PHP** di Windows Firewall.

> `android:usesCleartextTraffic="true"` sudah diaktifkan di
> `android/app/src/main/AndroidManifest.xml` agar HTTP lokal (bukan HTTPS)
> dapat diakses saat development.

---

## 9. Akun Demo

Dibuat otomatis oleh seeder:

| Role | Email | Password |
| --- | --- | --- |
| Admin | `admin@polivent.test` | `password` |
| Mahasiswa | `mahasiswa@polivent.test` | `password` |

Di halaman login tersedia tombol pintasan **Admin** dan **Mahasiswa** (khusus
development) yang otomatis mengisi kredensial di atas.

Data demo: 8 kategori, 10 event (2 sudah selesai, 8 akan datang; 7 berbayar
dengan harga Rp 15.000–Rp 50.000, 3 gratis), 12 pendaftaran dengan status
pembayaran: 8 lunas, 2 menunggu verifikasi, 1 ditolak, 1 belum bayar.
Akun `mahasiswa@polivent.test` punya 3 pendaftaran: Seminar Nasional (berbayar,
lunas), Seminar Literasi (gratis, riwayat), dan Turnamen ML (berbayar, belum
bayar — untuk mencoba alur pembayaran).

QR pembayaran memakai **satu QRIS asli** yang disimpan di
`database/seeders/assets/qr-pembayaran.jpg` dan disalin ke storage oleh
`PaymentSettingSeeder`. Ganti QR/keterangan lewat menu admin
**Pengaturan Pembayaran** tanpa mengubah kode.

Nomor kontak admin juga diatur di halaman yang sama. Data demo memakai
`0812-3456-7890`; nomor ini dibaca halaman login lewat endpoint publik
`GET /api/app-info`, jadi tidak di-hardcode di Flutter.

---

## 10. Cara Menjalankan (Ringkas)

```bash
# Terminal 1 — backend
cd D:\xampp\htdocs\polivent_api
php artisan serve

# Terminal 2 — aplikasi
cd D:\project\polivent
flutter run
```

Alur demo yang disarankan:

1. Login sebagai **Mahasiswa** → Home → buka event gratis → *Daftar Sekarang* →
   *Konfirmasi* → *Lihat Tiket* (QR muncul).
2. Buka event berbayar → *Daftar Sekarang* → halaman **Pembayaran** → scan QRIS,
   salin nominal, *Unggah Bukti Bayar* → status *Menunggu Verifikasi*.
3. Buka **My Event** → badge status pembayaran + tombol *Bayar* / *Lihat Tiket*.
4. Logout → login sebagai **Admin** → tab **Pembayaran** → buka bukti →
   *Verifikasi Pembayaran* (tiket peserta terbit) atau *Tolak* dengan alasan.
5. Tab **Pengaturan Pembayaran** → lihat/ganti QRIS global, rekening tujuan, dan
   nomor kontak admin (langsung terlihat di halaman login).
6. Tab **Event** → *Tambah Event* (isi harga, 0 = gratis) → *Kelola Event* →
   *Peserta*.

---

## 11. Testing

### Flutter

```bash
cd D:\project\polivent
flutter analyze     # No issues found
flutter test        # 24 tests passed
```

- `test/models_test.dart` — parsing model (termasuk data null), harga event,
  status pembayaran, nomor admin, validator (termasuk harga tiket & nomor HP),
  formatter tanggal Indonesia dan rupiah.
- `test/ui_widgets_test.dart` — skeleton + dispose controller shimmer,
  PressScale, FadeSlideIn, SectionHeader, placeholder banner, dan tombol salin
  kontak admin (clipboard + snackbar).
- `test/widget_test.dart` — halaman login tampil, memvalidasi email, dan tombol
  akun demo mengisi email + password.

### Laravel

```bash
cd D:\xampp\htdocs\polivent_api
php artisan test    # 30 passed, 181 assertions
php api_test.php    # 115 pengecekan end-to-end
```

### Uji manual end-to-end

| Skenario | Hasil yang diharapkan |
| --- | --- |
| Login password salah | Pesan error, tetap di halaman login |
| Register email/NIM duplikat | Pesan validasi dari Laravel |
| Daftar event yang sama 2× | "Kamu sudah terdaftar pada event ini." |
| Daftar event kuota penuh | "Kuota event sudah penuh." |
| Daftar event selesai | "Event sudah selesai..." |
| Daftar event berbayar | Tiket belum terbit, status "Belum Bayar" |
| Unggah bukti bayar | Status berubah menjadi "Menunggu Verifikasi" |
| Admin verifikasi | Status "Lunas", ticket code `POLI-...` terbit |
| Admin tolak | Status "Ditolak", tiket batal, alasan tampil |
| Unggah ulang setelah ditolak | Status kembali "Menunggu Verifikasi" |
| Admin ubah nomor kontak | Nomor baru langsung tampil di halaman login |
| Akses endpoint admin sebagai user | `403` dari server |
| Token dihapus/kedaluwarsa | Otomatis logout ke halaman login |
| Restart aplikasi | Session tetap login (token tersimpan) |

---

## 12. Catatan

- Banner event disimpan Laravel di `storage/app/public/banners` dan diakses
  lewat `banner_url`. Jika gambar gagal dimuat, Flutter menampilkan placeholder
  (aplikasi tidak crash).
- Semua gambar (banner, QRIS, bukti bayar) disajikan lewat route Laravel
  `GET /api/media/{path}` agar Flutter Web/CanvasKit tetap bisa memuatnya
  (file statis `/storage/...` tidak mengirim header CORS).
- Satu QRIS dipakai untuk semua event berbayar; nominal ditentukan per event.
  Pastikan QR hanya diganti lewat menu **Pengaturan Pembayaran**.
- KTM dan bukti pembayaran disimpan privat; bukti hanya dapat dimuat lewat
  endpoint terautentikasi oleh pemilik pendaftaran atau admin.
- Kategori belum punya layar CRUD sendiri di Flutter; endpoint-nya sudah tersedia
  di Laravel (dipakai untuk pengembangan lanjutan).
- Fitur opsional (favorit, notifikasi, QR scanner, dark mode) belum dikerjakan
  agar MVP tetap stabil.
