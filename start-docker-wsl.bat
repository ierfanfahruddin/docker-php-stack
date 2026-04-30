@echo off
REM ============================================================
REM  Startup Docker PHP Stack via WSL
REM  Klik dua kali file ini dari Windows untuk menjalankan Docker
REM ============================================================

echo.
echo ============================================================
echo   Docker PHP Stack - Startup via WSL
echo ============================================================
echo.

REM --- Cek apakah WSL tersedia ---
where wsl >nul 2>&1
if errorlevel 1 (
    echo [ERROR] WSL tidak ditemukan di sistem ini!
    pause
    exit /b 1
)

echo [INFO] Memulai Docker daemon di WSL...
wsl -e bash -c "sudo service docker start"

echo.
echo [INFO] Menjalankan docker-php-stack...
wsl -e bash -c "cd ~/projects/docker-php-stack && bash start-docker.sh"

echo.
pause
