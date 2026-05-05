#!/bin/bash
# ============================================================
#  Script: set-permission-contoh.sh
#  Fungsi: Mengatur permission semua folder tmp & captcha di bawah www/php7/contoh
#  Cocok untuk development lokal, jangan commit ke repo publik!
# ============================================================

# Contoh penggunaan:
#   bash set-permission-contoh.sh
#
# Jika folder project Anda berbeda, sesuaikan path di bawah ini.

TARGET_ROOT="./www/php7/contoh"

if [ ! -d "$TARGET_ROOT" ]; then
  echo "[ERROR] Folder $TARGET_ROOT tidak ditemukan!"
  exit 1
fi

echo "[INFO] Mencari semua folder tmp dan captcha di $TARGET_ROOT ..."
find "$TARGET_ROOT" -type d \( -name tmp -o -name captcha \) -print0 | while IFS= read -r -d '' dir; do
  echo "[INFO] Set permission 777 pada: $dir"
  chmod -R 777 "$dir"
done
echo "[OK]    Semua folder tmp dan captcha di $TARGET_ROOT sudah di-set ke 777."

echo "[INFO] Menjalankan chown -R $USER:$USER pada $TARGET_ROOT ..."
echo "000000" | sudo -S chown -R $USER:$USER "$TARGET_ROOT"
echo "[OK]    chown selesai."