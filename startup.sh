#!/bin/bash

# ==============================================================================
# Skrip Startup untuk Lingkungan Docker Proyek Laravel Filament
# ==============================================================================
#
# Lokasi: /home/ierfan/docker/startup.sh
#
# Cara Menggunakan:
# 1. Berikan izin eksekusi pada file ini:
#    chmod +x startup.sh
#
# 2. Jalankan dengan perintah yang tersedia:
#    ./startup.sh up        - Memulai semua layanan Docker di background.
#    ./startup.sh down      - Menghentikan semua layanan Docker.
#    ./startup.sh restart   - Menghentikan lalu memulai ulang semua layanan.
#    ./startup.sh ps        - Menampilkan status kontainer yang berjalan.
#    ./startup.sh logs      - Menampilkan log dari semua layanan.
#    ./startup.sh logs <nama_layanan> - Menampilkan log dari layanan spesifik (cth: ./startup.sh logs apache).
#    ./startup.sh exec <nama_layanan> <perintah> - Menjalankan perintah di dalam kontainer (cth: ./startup.sh exec php-83-fpm sh).
#
# ==============================================================================

# Variabel untuk perintah dasar Docker Compose
COMPOSE_CMD="docker compose -f docker-compose-apache.yml"

# Mengambil argumen pertama (perintah)
COMMAND=$1

# Mengambil argumen kedua dan seterusnya (untuk logs dan exec)
SERVICE_NAME=$2
shift 2
EXEC_ARGS="$@"


echo "=================================================="

case "$COMMAND" in
  up)
    echo "🚀 Memulai semua layanan Docker..."
    $COMPOSE_CMD up -d
    echo "✅ Layanan telah dimulai. Gunakan './startup.sh ps' untuk melihat status."
    ;;
  down)
    echo "🛑 Menghentikan semua layanan Docker..."
    $COMPOSE_CMD down
    echo "✅ Semua layanan telah dihentikan."
    ;;
  restart)
    echo "🔄 Merestart semua layanan Docker..."
    $COMPOSE_CMD down
    $COMPOSE_CMD up -d
    echo "✅ Semua layanan telah direstart."
    ;;
  ps)
    echo "📊 Menampilkan status kontainer..."
    $COMPOSE_CMD ps
    ;;
  logs)
    echo "📜 Menampilkan log untuk layanan: ${SERVICE_NAME:-semua}"
    $COMPOSE_CMD logs -f $SERVICE_NAME
    ;;
  exec)
    echo "💻 Mengakses shell/perintah di layanan: $SERVICE_NAME..."
    $COMPOSE_CMD exec $SERVICE_NAME ${EXEC_ARGS:-sh}
    ;;
  *)
    echo "Perintah tidak valid. Gunakan salah satu dari: up, down, restart, ps, logs, exec"
    exit 1
    ;;
esac

echo "=================================================="