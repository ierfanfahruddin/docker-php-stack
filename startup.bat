@echo off
setlocal EnableDelayedExpansion

REM ============================================================
REM  Startup script untuk docker-php-stack (Windows)
REM  Jalankan dari folder project ini
REM ============================================================

set COMPOSE_FILE=docker-compose-apache.yml
set MAX_WAIT=60
set WAIT_INTERVAL=5
set ELAPSED=0

echo.
echo ============================================================
echo   Docker PHP Stack - Startup Script
echo ============================================================
echo.

REM --- Cek apakah file docker-compose tersedia ---
if not exist "%COMPOSE_FILE%" (
    echo [ERROR] File "%COMPOSE_FILE%" tidak ditemukan!
    echo         Pastikan script dijalankan dari folder project yang benar.
    echo.
    pause
    exit /b 1
)

REM --- Tunggu Docker Engine aktif ---
echo [INFO] Mengecek status Docker Engine...

:waitdocker
docker info >nul 2>&1
if errorlevel 1 (
    if !ELAPSED! geq %MAX_WAIT% (
        echo.
        echo [ERROR] Docker Engine tidak aktif setelah %MAX_WAIT% detik.
        echo         Pastikan Docker Desktop sudah berjalan, lalu coba lagi.
        echo.
        pause
        exit /b 1
    )
    echo [WAIT]  Docker Engine belum aktif. Mencoba lagi dalam %WAIT_INTERVAL% detik...
    echo         ^(Silakan nyalakan Docker Desktop jika belum^)
    timeout /t %WAIT_INTERVAL% >nul
    set /a ELAPSED+=WAIT_INTERVAL
    goto waitdocker
)
echo [OK]    Docker Engine aktif!
echo.

REM --- Stop dan hapus container lama ---
echo [INFO] Menghentikan container lama...
docker compose -f %COMPOSE_FILE% down
if errorlevel 1 (
    echo [WARN]  Gagal menghentikan container lama. Melanjutkan...
)
echo.

REM --- Build ulang image jika ada perubahan (opsional) ---
REM Hapus tanda REM di bawah ini jika ingin selalu build ulang
REM echo [INFO] Building image...
REM docker compose -f %COMPOSE_FILE% build
REM if errorlevel 1 (
REM     echo [ERROR] Build gagal! Periksa Dockerfile Anda.
REM     pause
REM     exit /b 1
REM )

REM --- Jalankan semua service ---
echo [INFO] Menjalankan semua service...
docker compose -f %COMPOSE_FILE% up -d
if errorlevel 1 (
    echo.
    echo [ERROR] Gagal menjalankan service!
    echo         Periksa log dengan perintah:
    echo           docker compose -f %COMPOSE_FILE% logs
    echo.
    pause
    exit /b 1
)
echo.

REM --- Tampilkan status container ---
echo [INFO] Status container:
echo ============================================================
docker compose -f %COMPOSE_FILE% ps
echo ============================================================
echo.
echo [OK]    Semua service berhasil dijalankan.
echo.
echo   Tips perintah berguna:
echo   - Lihat log    : docker compose -f %COMPOSE_FILE% logs -f
echo   - Stop semua   : docker compose -f %COMPOSE_FILE% down
echo   - Restart      : docker compose -f %COMPOSE_FILE% restart
echo.

pause
endlocal