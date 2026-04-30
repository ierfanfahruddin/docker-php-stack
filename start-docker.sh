#!/bin/bash
# ============================================================
#  Startup script untuk docker-php-stack (WSL/Linux)
#  Jalankan dari folder project ini:  bash start-docker.sh
# ============================================================

COMPOSE_FILE="docker-compose-apache.yml"
MAX_WAIT=60
WAIT_INTERVAL=5
ELAPSED=0

echo ""
echo "============================================================"
echo "  Docker PHP Stack - Startup Script (WSL)"
echo "============================================================"
echo ""

# --- Cek file docker-compose tersedia ---
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "[ERROR] File '$COMPOSE_FILE' tidak ditemukan!"
    echo "        Pastikan script dijalankan dari folder project yang benar."
    echo ""
    exit 1
fi

# --- Tunggu Docker daemon aktif ---
echo "[INFO] Mengecek status Docker daemon..."

while ! docker info > /dev/null 2>&1; do
    if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
        echo ""
        echo "[ERROR] Docker daemon tidak aktif setelah ${MAX_WAIT} detik."
        echo "        Coba jalankan: sudo service docker start"
        echo "        Atau jika pakai Docker Desktop WSL integration, pastikan Docker Desktop menyala."
        echo ""
        exit 1
    fi
    echo "[WAIT]  Docker belum aktif. Mencoba lagi dalam ${WAIT_INTERVAL} detik... (${ELAPSED}s/${MAX_WAIT}s)"
    sleep "$WAIT_INTERVAL"
    ELAPSED=$((ELAPSED + WAIT_INTERVAL))
done

echo "[OK]    Docker daemon aktif!"
echo ""

# --- Stop dan hapus container lama ---
echo "[INFO] Menghentikan container lama..."
docker compose -f "$COMPOSE_FILE" down || echo "[WARN]  Tidak ada container lama, melanjutkan..."
echo ""

# --- Jalankan semua service ---
echo "[INFO] Menjalankan semua service..."
if ! docker compose -f "$COMPOSE_FILE" up -d; then
    echo ""
    echo "[ERROR] Gagal menjalankan service!"
    echo "        Periksa log dengan perintah:"
    echo "          docker compose -f $COMPOSE_FILE logs"
    echo ""
    exit 1
fi
echo ""

# --- Tampilkan status container ---
echo "[INFO] Status container:"
echo "============================================================"
docker compose -f "$COMPOSE_FILE" ps
echo "============================================================"
echo ""
echo "[OK]    Semua service berhasil dijalankan."
echo ""
echo "  Tips perintah berguna:"
echo "  - Lihat log    : docker compose -f $COMPOSE_FILE logs -f"
echo "  - Stop semua   : docker compose -f $COMPOSE_FILE down"
echo "  - Restart      : docker compose -f $COMPOSE_FILE restart"
echo ""
