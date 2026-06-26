#!/bin/bash
# ===================================================================
# cleanup_old_rows.sh
# Hapus baris lama pada tabel yang melebihi KEEP_ROWS baris.
#
# Logika:
#   - Untuk tabel dengan kolom created_at:
#       DELETE baris yang TIDAK termasuk dalam KEEP_ROWS baris terbaru
#       (ORDER BY created_at DESC)
#   - Untuk tabel TANPA kolom created_at:
#       Lewati (skip) — tidak dihapus agar tidak merusak data penting
#
# Cara menjalankan (dari host WSL/Linux):
#   docker exec -i db-postgre-15 bash < cleanup_old_rows.sh
# Atau copy dulu ke container lalu jalankan:
#   docker cp cleanup_old_rows.sh db-postgre-15:/backup/
#   docker exec db-postgre-15 bash /backup/cleanup_old_rows.sh
#
# PERINGATAN:
#   - Script ini MENGHAPUS DATA secara permanen. Pastikan sudah backup!
#   - Gunakan DRY_RUN=true untuk preview tanpa menghapus.
# ===================================================================
set -uo pipefail

# ---- Konfigurasi ---------------------------------------------------
DB_NAME="db_tes"       # nama database target
DB_HOST="localhost"
DB_PORT="5432"
DB_USERNAME="${POSTGRES_USER:-postgres}"
DB_PASSWORD="${POSTGRES_PASSWORD:-postgres}"

KEEP_ROWS=10000                 # jumlah baris terbaru yang dipertahankan per tabel
BACKUP_DIR="/backup"
DRY_RUN=true                   # true = hanya tampilkan, tidak benar-benar hapus
                                # Ganti ke false jika yakin ingin menghapus!

# Tabel yang ingin di-skip (pisahkan dengan spasi)
# Contoh: SKIP_TABLES="audit_logs master_config"
SKIP_TABLES=""

# ---- Setup ---------------------------------------------------------
LOG="${BACKUP_DIR}/cleanup_old_rows.log"
export PGPASSWORD="$DB_PASSWORD"
PSQL="psql -h $DB_HOST -p $DB_PORT -U $DB_USERNAME -d $DB_NAME"

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG"; }

mkdir -p "$BACKUP_DIR"

log "=== Cleanup Old Rows: $DB_NAME ==="
log "    Keep  : $KEEP_ROWS baris terbaru per tabel"
log "    Mode  : $([ "$DRY_RUN" = "true" ] && echo 'DRY RUN (tidak menghapus)' || echo 'LIVE (akan menghapus!)')"
log ""

# ---- Ambil semua tabel di schema public ----------------------------
TABLES=$($PSQL -t -A -c \
  "SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename" \
  2>> "$LOG") || TABLES=""

T_NUM=0
TOTAL_DELETED=0

for TABLE in $TABLES; do
  # Cek apakah tabel ada di daftar skip
  SKIP=false
  for SKIP_TBL in $SKIP_TABLES; do
    [ "$SKIP_TBL" = "$TABLE" ] && SKIP=true && break
  done
  if [ "$SKIP" = "true" ]; then
    log "  [SKIP] $TABLE — ada di daftar SKIP_TABLES"
    continue
  fi

  # Skip tabel yang namanya diawali dengan mst_
  if [[ "$TABLE" == mst_* ]]; then
    log "  [SKIP] $TABLE — prefix mst_ (master table, tidak dihapus)"
    continue
  fi

  T_NUM=$((T_NUM + 1))

  # Estimasi jumlah baris dari pg_class (cepat, tanpa COUNT)
  ROW_EST=$($PSQL -t -A -c \
    "SELECT reltuples::bigint FROM pg_class
     WHERE relname='$TABLE'
       AND relnamespace=(SELECT oid FROM pg_namespace WHERE nspname='public')" \
    2>> "$LOG") || ROW_EST=0

  # Lewati tabel yang baris estimasinya sudah di bawah KEEP_ROWS
  if [ "${ROW_EST:-0}" -le "$KEEP_ROWS" ] 2>/dev/null; then
    log "  [$T_NUM] $TABLE  (~$ROW_EST rows) — tidak perlu dihapus"
    continue
  fi

  # Cek apakah ada kolom created_at
  HAS_CREATED=$($PSQL -t -A -c \
    "SELECT 1 FROM information_schema.columns
     WHERE table_schema='public'
       AND table_name='$TABLE'
       AND column_name='created_at'
     LIMIT 1" 2>> "$LOG") || HAS_CREATED=""

  if [ "${HAS_CREATED:-}" != "1" ]; then
    log "  [$T_NUM] $TABLE  (~$ROW_EST rows) — [SKIP] tidak ada kolom created_at"
    continue
  fi

  # Hitung jumlah baris aktual yang akan dihapus
  DELETE_COUNT=$($PSQL -t -A -c \
    "SELECT COUNT(*) FROM \"$TABLE\"
     WHERE ctid NOT IN (
       SELECT ctid FROM \"$TABLE\" ORDER BY created_at DESC LIMIT $KEEP_ROWS
     )" 2>> "$LOG") || DELETE_COUNT="?"

  log "  [$T_NUM] $TABLE  (~$ROW_EST rows) — akan hapus ~$DELETE_COUNT baris lama"

  if [ "$DRY_RUN" = "false" ]; then
    DELETED=$($PSQL -t -A -c \
      "WITH kept AS (
         SELECT ctid FROM \"$TABLE\" ORDER BY created_at DESC LIMIT $KEEP_ROWS
       )
       DELETE FROM \"$TABLE\"
       WHERE ctid NOT IN (SELECT ctid FROM kept);
       SELECT 'deleted'" 2>> "$LOG") || DELETED="error"

    if [ "$DELETED" = "error" ]; then
      log "  [ERROR] Gagal hapus baris pada $TABLE, cek $LOG"
    else
      ACTUAL=$($PSQL -t -A -c "SELECT COUNT(*) FROM \"$TABLE\"" 2>> "$LOG") || ACTUAL="?"
      log "  [OK]   $TABLE — selesai. Sisa baris: $ACTUAL"
      TOTAL_DELETED=$((TOTAL_DELETED + ${DELETE_COUNT:-0}))
    fi
  fi
done

log ""
if [ "$DRY_RUN" = "true" ]; then
  log "=== DRY RUN selesai. Tidak ada data yang dihapus. ==="
  log "    Ubah DRY_RUN=false untuk benar-benar menghapus."
else
  log "=== Cleanup selesai. Total estimasi baris dihapus: $TOTAL_DELETED ==="
fi
