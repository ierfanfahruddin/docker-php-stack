#!/bin/bash
# ===================================================================
# backup_filtered.sh
# Backup 1 file: Schema + Data INSERT (50k row) + Index
#
# Urutan di dalam file:
#   1. CREATE TABLE, sequences, types  (pre-data)
#   2. INSERT statements               (max 50k row/tabel, ORDER BY created_at DESC)
#   3. CREATE INDEX, constraints       (post-data)
#
# Kenapa lebih cepat dari pg_dump penuh:
#   - Index hanya DDL teks, bukan dump fisik (abaikan bloat)
#   - Data hanya 50k row terakhir per tabel, bukan jutaan row
#   - CATATAN: tabel besar tanpa index pada created_at akan full scan
#
# Optimasi index created_at:
#   - Jika AUTO_CREATE_INDEX=true, script akan buat index sementara
#     pada kolom created_at untuk tabel yang belum punya index tersebut.
#   - Index akan di-DROP setelah backup selesai (optional: DROP_INDEX_AFTER=true)
#   - Jika false, hanya WARN di log untuk tabel yang akan full scan
#
# Cara menjalankan (dari host WSL/Linux):
#   docker exec -i db-postgre-15 bash < backup_filtered.sh
# Atau copy dulu ke container lalu jalankan:
#   docker cp backup_filtered.sh db-postgre-15:/backup/
#   docker exec db-postgre-15 bash /backup/backup_filtered.sh
#
# Docker compose service    : db-postgre (container: db-postgre-15)
# Volume backup di host     : /mnt/c/Users/ierfa/Downloads/Compressed
# Volume backup di container: /backup
# ===================================================================
set -uo pipefail

# ---- Konfigurasi ---------------------------------------------------
# Sesuaikan dengan nilai di .env / docker-compose-apache.yml
DB_NAME="tm_slawi_simrs"           # nama database target (bukan ${POSTGRES_DB} yang berisi db default)
DB_HOST="localhost"        # localhost karena script berjalan di dalam container db-postgre-15
DB_PORT="5432"
DB_USERNAME="${POSTGRES_USER:-postgres}"
DB_PASSWORD="${POSTGRES_PASSWORD:-postgres}"
LIMIT_ROWS=10000
BACKUP_DIR="/backup"       # volume mount: /mnt/c/Users/ierfa/Downloads/Compressed:/backup
AUTO_CREATE_INDEX=false   # true = buat index created_at otomatis jika belum ada
DROP_INDEX_AFTER=true     # true = drop index yang dibuat script ini setelah backup

# ---- Setup ---------------------------------------------------------
DATE_TAG=$(date +"%Y_%m_%d_%H")
LOG="${BACKUP_DIR}/backup_filtered_error.log"
FILE="${BACKUP_DIR}/${DB_NAME}_${DATE_TAG}.sql"

export PGPASSWORD="$DB_PASSWORD"
PSQL="psql -h $DB_HOST -p $DB_PORT -U $DB_USERNAME -d $DB_NAME"
PG_CONN="postgresql://$DB_USERNAME:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME"

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG"; }

mkdir -p "$BACKUP_DIR"
rm -f "$FILE" "${FILE}.gz" 2>/dev/null || true

log "=== Backup Filtered: $DB_NAME ==="
log "    Limit : $LIMIT_ROWS rows/tabel"
log "    Output: $FILE"

# ---- Header file ---------------------------------------------------
{
  echo "-- ============================================================"
  echo "-- Backup : $DB_NAME"
  echo "-- Generated : $(date '+%Y-%m-%d %H:%M:%S')"
  echo "-- Limit/tabel : $LIMIT_ROWS rows (ORDER BY created_at DESC)"
  echo "-- Restore : psql -d TARGET_DB -f <file>"
  echo "-- ============================================================"
  echo ""
} > "$FILE"

# ---- 1. Schema: CREATE TABLE, sequences, types (tanpa index) -------
log "[1/3] Ekspor schema (CREATE TABLE)..."
{
  echo "-- ============================================================"
  echo "-- BAGIAN 1: SCHEMA (CREATE TABLE, SEQUENCE, TYPE)"
  echo "-- ============================================================"
  echo ""
  pg_dump -O -x --schema-only --section=pre-data --dbname="$PG_CONN" 2>> "$LOG"
  echo ""
} >> "$FILE"
log "  -> selesai"

# ---- 1b. Cek & buat index created_at yang hilang -------------------
log "[1b/3] Cek index pada kolom created_at..."
CREATED_INDEX_LIST=()

TABLES_WITH_CREATED=$($PSQL -t -A -c "
  SELECT c.table_name
  FROM information_schema.columns c
  WHERE c.table_schema = 'public'
    AND c.column_name   = 'created_at'
  ORDER BY c.table_name
" 2>> "$LOG") || TABLES_WITH_CREATED=""

for TBL in $TABLES_WITH_CREATED; do
  HAS_IDX=$($PSQL -t -A -c "
    SELECT 1
    FROM pg_index      i
    JOIN pg_class      t ON t.oid = i.indrelid
    JOIN pg_class      x ON x.oid = i.indexrelid
    JOIN pg_attribute  a ON a.attrelid = t.oid AND a.attnum = i.indkey[0]
    WHERE t.relnamespace = (SELECT oid FROM pg_namespace WHERE nspname='public')
      AND t.relname  = '$TBL'
      AND a.attname  = 'created_at'
    LIMIT 1
  " 2>> "$LOG") || HAS_IDX=""

  if [ "${HAS_IDX:-}" != "1" ]; then
    if [ "$AUTO_CREATE_INDEX" = "true" ]; then
      IDX_NAME="_bkp_idx_${TBL}_created_at"
      log "  [INDEX] Membuat index: $IDX_NAME pada $TBL(created_at)..."
      $PSQL -c "CREATE INDEX CONCURRENTLY IF NOT EXISTS \"$IDX_NAME\" ON \"$TBL\" (created_at DESC)" \
        2>> "$LOG" && CREATED_INDEX_LIST+=("$TBL|$IDX_NAME") \
        || log "  [WARN] Gagal buat index $IDX_NAME"
    else
      log "  [WARN] $TBL: tidak ada index pada created_at → akan full scan!"
    fi
  fi
done
log "  -> selesai"

# ---- 2. Data: INSERT last $LIMIT_ROWS rows per tabel ---------------
log "[2/3] Ekspor data INSERT (max $LIMIT_ROWS baris/tabel)..."
{
  echo "-- ============================================================"
  echo "-- BAGIAN 2: DATA (INSERT, max $LIMIT_ROWS rows/tabel)"
  echo "-- ============================================================"
  echo ""
  echo "SET search_path TO public;"
  echo "SET session_replication_role = replica;"
  echo ""
} >> "$FILE"

# Ambil semua tabel di schema public
TABLES=$($PSQL -t -A -c \
  "SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename" \
  2>> "$LOG") || TABLES=""

T_NUM=0
for TABLE in $TABLES; do
  T_NUM=$((T_NUM + 1))

  # Cek apakah ada kolom created_at
  HAS_CREATED=$($PSQL -t -A -c \
    "SELECT 1 FROM information_schema.columns
     WHERE table_schema='public'
       AND table_name='$TABLE'
       AND column_name='created_at'
     LIMIT 1" 2>> "$LOG") || HAS_CREATED=""

  if [ "${HAS_CREATED:-}" = "1" ]; then
    ORDER_LIMIT="ORDER BY created_at DESC LIMIT $LIMIT_ROWS"
    SORT_INFO="ORDER BY created_at DESC"
  else
    ORDER_LIMIT="LIMIT $LIMIT_ROWS"
    SORT_INFO="no created_at, LIMIT only"
  fi

  # Estimasi jumlah baris dari pg_class (tidak perlu COUNT, cepat)
  ROW_EST=$($PSQL -t -A -c \
    "SELECT reltuples::bigint FROM pg_class
     WHERE relname='$TABLE'
       AND relnamespace=(SELECT oid FROM pg_namespace WHERE nspname='public')" \
    2>> "$LOG") || ROW_EST="?"

  log "  [$T_NUM] $TABLE  (~$ROW_EST rows, $SORT_INFO)"

  echo "-- Tabel: \"$TABLE\" (~$ROW_EST rows, export max $LIMIT_ROWS)" >> "$FILE"

  # Pendekatan efisien:
  #   - Bangun ekspresi VALUES langsung di SQL menggunakan format_type + quote_nullable
  #   - Hindari correlated subquery row_to_json+unnest yang berjalan rows×columns kali
  #   - Satu query flat per tabel: PostgreSQL bisa pipeline hasilnya langsung ke psql output
  COL_EXPR=$($PSQL -t -A -c "
    SELECT string_agg(
      'quote_nullable(' || quote_ident(column_name) || '::text)',
      ' || '','' || ' ORDER BY ordinal_position
    )
    FROM information_schema.columns
    WHERE table_schema='public' AND table_name='$TABLE'
  " 2>> "$LOG") || COL_EXPR=""

  COL_LIST=$($PSQL -t -A -c "
    SELECT string_agg(quote_ident(column_name), ', ' ORDER BY ordinal_position)
    FROM information_schema.columns
    WHERE table_schema='public' AND table_name='$TABLE'
  " 2>> "$LOG") || COL_LIST=""

  if [ -n "$COL_EXPR" ] && [ -n "$COL_LIST" ]; then
    $PSQL -t -A -c "
      SELECT 'INSERT INTO \"$TABLE\" ($COL_LIST) VALUES (' || $COL_EXPR || ');'
      FROM (SELECT * FROM \"$TABLE\" $ORDER_LIMIT) _t
    " 2>> "$LOG" >> "$FILE" || log "  [WARN] Error pada tabel $TABLE, cek $LOG"
  else
    log "  [WARN] Tidak bisa ambil info kolom untuk $TABLE, skip."
  fi

  echo "" >> "$FILE"
done

{
  echo "SET session_replication_role = DEFAULT;"
  echo ""
} >> "$FILE"
log "  -> selesai"

# ---- 2b. Drop index sementara yang dibuat script ini ---------------
if [ "$DROP_INDEX_AFTER" = "true" ] && [ ${#CREATED_INDEX_LIST[@]} -gt 0 ]; then
  log "[2b/3] Drop index sementara backup..."
  for ENTRY in "${CREATED_INDEX_LIST[@]}"; do
    IDX="${ENTRY##*|}"
    log "  DROP INDEX $IDX"
    $PSQL -c "DROP INDEX CONCURRENTLY IF EXISTS \"$IDX\"" 2>> "$LOG" \
      || log "  [WARN] Gagal drop $IDX, hapus manual: DROP INDEX CONCURRENTLY \"$IDX\";"
  done
  log "  -> selesai"
fi

# ---- 3. Index + constraints + triggers (post-data) -----------------
log "[3/3] Ekspor index & constraints..."
{
  echo "-- ============================================================"
  echo "-- BAGIAN 3: INDEX, CONSTRAINTS, TRIGGERS"
  echo "-- ============================================================"
  echo ""
  pg_dump -O -x --schema-only --section=post-data --dbname="$PG_CONN" 2>> "$LOG"
  echo ""
} >> "$FILE"
log "  -> selesai"

# ---- 4. Compress ---------------------------------------------------
log "Compress..."
gzip -f "$FILE"
log "  -> ${FILE}.gz  ($(du -sh "${FILE}.gz" | cut -f1))"

log "=== Selesai Backup ==="
