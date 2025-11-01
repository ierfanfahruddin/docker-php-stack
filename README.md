# Lingkungan Pengembangan Docker PHP

Repositori ini berisi lingkungan Docker yang lengkap untuk pengembangan PHP dengan dukungan untuk beberapa versi PHP, database MySQL, dan PostgreSQL.

## Layanan yang Disertakan

1. **Web Server Nginx** - Berjalan di port 8080
2. **PHP 8.3 FPM** - Untuk aplikasi PHP modern
3. **PHP 7.4 FPM** - Untuk aplikasi PHP lama
4. **MySQL 8.0** - Layanan database
5. **PostgreSQL 13** - Layanan database alternatif

## Struktur Proyek

```
├── docker-compose.yml          # Konfigurasi Docker Compose
├── nginx/default.conf          # Konfigurasi server Nginx
├── php-74-fpm/Dockerfile       # Konfigurasi Docker PHP 7.4 FPM
├── php-83-fpm/Dockerfile       # Konfigurasi Docker PHP 8.3 FPM
├── www/                        # Direktori file web
│   └── project_a/              # Proyek PHP contoh
│       └── index.php           # File PHP contoh
├── mysql-8-data/               # Persistensi data MySQL
├── postgresql-data/            # Persistensi data PostgreSQL
└── README.md                   # File ini
```

## Instalasi

1. **Prasyarat**
   - Instal Docker dan Docker Compose di sistem Anda
   - Pastikan port 8080, 3306, dan 5432 tersedia

2. **Klon atau Unduh Repositori**
   ```bash
   git clone https://github.com/ierfanfahruddin/docker-php-stack
   cd docker-php-stack
   ```

3. **Siapkan File Konfigurasi**
   Salin file konfigurasi contoh ke file yang sebenarnya:
   ```bash
   cp nginx/default.conf.example nginx/default.conf
   cp docker-compose.yml.example docker-compose.yml
   ```

4. **Sesuaikan Konfigurasi**
   Edit file `nginx/default.conf` dan `docker-compose.yml` sesuai kebutuhan Anda.

5. **Verifikasi Instalasi**
   ```bash
   docker-compose up -d
   ```

4. **Verifikasi Instalasi**
   - Server Nginx: http://localhost:8080
   - Akses project_a: http://localhost:8080/project_a

## Penggunaan

### Mengakses Layanan

- **Web Server**: http://localhost:8080
- **Database MySQL**:
  - Host: localhost
  - Port: 3306
  - User: dev_user
  - Password: dev_pass
  - Database: db_mysql
- **Database PostgreSQL**:
  - Host: localhost
  - Port: 5432
  - User: dev_user
  - Password: dev_pass
  - Database: db_postgre

### Bekerja dengan Proyek PHP

1. **Project A (PHP 8.3)**
   - Terletak di `www/project_a/`
   - Akses melalui http://localhost:8080/project_a

2. **Project B (PHP 7.4)**
   - Terletak di `www/proyek_b/`
   - Akses melalui http://localhost:8080/proyek_b

### Mengelola Kontainer

- **Melihat kontainer yang berjalan**:
  ```bash
  docker-compose ps
  ```

- **Melihat log**:
  ```bash
  docker-compose logs [nama-layanan]
  ```

- **Menghentikan semua layanan**:
  ```bash
  docker-compose down
  ```

- **Merestart layanan**:
  ```bash
  docker-compose restart
  ```

## Menambahkan Proyek Baru

1. **Buat direktori proyek baru** di folder `www/`:
   ```bash
   mkdir www/nama-proyek-anda
   ```

2. **Tambahkan file PHP Anda** ke direktori baru

3. **Konfigurasi Nginx** dengan mengedit `nginx/default.conf`:
   ```nginx
   location /nama-proyek-anda {
       alias /var/www/html/nama-proyek-anda;
       try_files $uri $uri/ /nama-proyek-anda/index.php?$query_string;
   }
   
   location ~ /nama-proyek-anda/.*\.php$ {
       include fastcgi_params;
       # Pilih versi PHP (php-83-fpm:9000 atau php-74-fpm:9000)
       fastcgi_pass php-83-fpm:9000;
       fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
   }
   ```

4. **Restart layanan Nginx**:
   ```bash
   docker-compose restart nginx
   ```

## Manajemen Database

### MySQL

- **Menghubungkan menggunakan klien MySQL**:
  ```bash
  mysql -h localhost -P 3306 -u dev_user -p db_mysql
  ```

- **Inisialisasi dengan skrip SQL**:
  Tempatkan file `.sql` di direktori `mysql-8-data/` sebelum memulai layanan

### PostgreSQL

- **Menghubungkan menggunakan klien PostgreSQL**:
  ```bash
  psql -h localhost -p 5432 -U dev_user -d db_postgre
  ```

- **Inisialisasi dengan skrip SQL**:
  Tempatkan file `.sql` di direktori `postgresql-data/` sebelum memulai layanan

## Penyelesaian Masalah

1. **Konflik port**:
   - Pastikan port 8080, 3306, dan 5432 tidak digunakan
   - Ubah port di `docker-compose.yml` jika diperlukan

2. **Masalah izin**:
   - Periksa izin file untuk volume yang dipasang
   - Pastikan Docker memiliki izin yang diperlukan untuk mengakses file proyek

3. **Masalah koneksi database**:
   - Verifikasi kredensial database di `docker-compose.yml`
   - Periksa apakah kontainer database berjalan dengan `docker-compose ps`

4. **Masalah versi PHP**:
   - Konfirmasi layanan PHP-FPM yang benar ditentukan dalam konfigurasi Nginx
   - Periksa log kontainer PHP-FPM dengan `docker-compose logs php-83-fpm`

## Menghentikan Lingkungan

Untuk menghentikan dan menghapus semua kontainer:
```bash
docker-compose down
```

Untuk menghentikan kontainer tetapi mempertahankan volume:
```bash
docker-compose stop
```

Untuk benar-benar menghapus kontainer dan volume:
```bash
docker-compose down -v