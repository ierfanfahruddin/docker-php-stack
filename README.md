# Laravel Filament dengan Apache

Proyek ini adalah contoh konfigurasi untuk menjalankan aplikasi Laravel Filament menggunakan Apache sebagai pengganti Nginx, dengan dukungan untuk beberapa versi PHP.

## Daftar Isi

- [Prasyarat](#prasyarat)
- [Instalasi](#instalasi)
- [Menjalankan Aplikasi](#menjalankan-aplikasi)
- [Struktur Direktori](#struktur-direktori)
- [Menjalankan Proyek Baru](#menjalankan-proyek-baru)
- [Konfigurasi Apache](#konfigurasi-apache)
- [Penyelesaian Masalah](#penyelesaian-masalah)
- [Lisensi](#lisensi)

## Prasyarat

Sebelum memulai, pastikan Anda telah menginstal:

- Docker
- Docker Compose

## Instalasi

1. Clone repository ini ke direktori lokal Anda:
   ```bash
   git clone <url-repository> laravel-filament-apache
   cd laravel-filament-apache
   ```

2. Pastikan Docker dan Docker Compose telah terinstal di sistem Anda.

## Menjalankan Aplikasi

1. Jalankan layanan dengan perintah:
   ```bash
   docker compose -f docker-compose-apache.yml up -d
   ```

2. Tunggu beberapa saat hingga semua layanan berjalan.

3. Akses aplikasi di browser Anda melalui:
   - `http://localhost:8080/` untuk aplikasi Laravel Filament
   - `http://project-a.localhost:8080/` untuk contoh proyek A
   - `http://project-b.localhost:8080/` untuk contoh proyek B
   - `http://php7.localhost:8080/sample/` untuk contoh proyek PHP 7.4
   - `http://php8.localhost:8080/sample/` untuk contoh proyek PHP 8.3

4. Untuk menghentikan layanan:
   ```bash
   docker compose -f docker-compose-apache.yml down
   ```

## Struktur Direktori

```
.
├── apache/
│   ├── httpd.conf          # Konfigurasi utama Apache
│   └── vhosts/
│       ├── laravel.conf  # Virtual host untuk aplikasi Laravel
│       ├── php7.conf       # Virtual host untuk proyek PHP 7.4
│       ├── php8.conf       # Virtual host untuk proyek PHP 8.3
│       ├── project_a.conf  # Virtual host untuk proyek A
│       └── project_b.conf  # Virtual host untuk proyek B
├── docker-compose-apache.yml  # Konfigurasi Docker Compose
├── php-83-fpm/
│   └── Dockerfile          # Konfigurasi PHP 8.3 FPM
├── php-74-fpm/
│   └── Dockerfile          # Konfigurasi PHP 7.4 FPM
├── www/
│   ├── laravel/  # Aplikasi Laravel Filament
│   ├── project_a/          # Contoh proyek sederhana
│   ├── project_b/          # Contoh proyek dengan koneksi database
│   ├── php7/               # Direktori untuk proyek PHP 7.4
│   │   └── sample/         # Contoh proyek PHP 7.4
│   └── php8/               # Direktori untuk proyek PHP 8.3
│       └── sample/         # Contoh proyek PHP 8.3
└── ...
```

## Menjalankan Proyek Baru

Untuk menambahkan proyek baru:

1. **Untuk proyek yang membutuhkan PHP 7.4**:
   - Letakkan file proyek Anda di direktori `www/php7/nama-proyek/`
   - Akses proyek melalui `http://php7.localhost:8080/nama-proyek/`

2. **Untuk proyek yang membutuhkan PHP 8.3**:
   - Letakkan file proyek Anda di direktori `www/php8/nama-proyek/`
   - Akses proyek melalui `http://php8.localhost:8080/nama-proyek/`

3. **Untuk proyek khusus (seperti Laravel Filament)**:
   - Buat direktori baru di `www/` dengan nama proyek Anda
   - Tambahkan konfigurasi virtual host baru di `apache/vhosts/`
   - Sesuaikan konfigurasi `docker-compose-apache.yml` jika diperlukan
   - Akses proyek melalui URL yang telah dikonfigurasi

Tidak perlu konfigurasi tambahan untuk setiap proyek baru selama mengikuti struktur yang telah disediakan.

## Konfigurasi Apache

Konfigurasi Apache telah dioptimalkan untuk aplikasi Laravel Filament dengan:

- Virtual host khusus untuk aplikasi laravel
- Pengaturan rewrite rules yang sesuai untuk Laravel
- Konfigurasi PHP-FPM yang terintegrasi
- Penanganan khusus untuk direktori Livewire dan Filament
- Virtual host terpisah untuk proyek PHP 7.4 dan 8.3

## Penyelesaian Masalah

Jika mengalami error 405 Method Not Allowed:

1. Pastikan file `.env` di direktori aplikasi Laravel sudah dikonfigurasi dengan benar
2. Periksa konfigurasi session di `config/session.php`
3. Verifikasi bahwa CSRF token disertakan dalam request POST/PUT/PATCH/DELETE
4. Cek log Apache untuk informasi lebih detail tentang error

Jika mengalami masalah koneksi seperti "refused to connect":

1. Pastikan semua layanan Docker berjalan dengan perintah `docker compose -f docker-compose-apache.yml up -d`
2. Gunakan format URL yang benar: `http://[nama-virtual-host]:8080/` karena semua layanan dijalankan melalui port 8080
3. Periksa file hosts sistem Anda jika perlu menambahkan entri untuk virtual host


Cara masuk ke fpm php:

```bash
docker compose exec php-83-fpm sh
```

## Lisensi

MIT