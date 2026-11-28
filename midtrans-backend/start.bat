@echo off
setlocal
cd /d "%~dp0"

if not exist ".env" (
  echo [1/2] File .env belum ada. Menyalin dari .env.example...
  copy /Y ".env.example" ".env" >nul
  echo.
  echo Silakan isi MIDTRANS_SERVER_KEY dan MIDTRANS_CLIENT_KEY di file .env
  echo yang baru dibuka, lalu simpan dan jalankan start.bat lagi.
  echo.
  notepad ".env"
  pause
  exit /b 1
)

findstr /C:"SB-Mid-server-xxxxxxxxxxxxxxxx" ".env" >nul
if not errorlevel 1 (
  echo [PERINGATAN] MIDTRANS_SERVER_KEY di .env masih placeholder.
  echo Buka .env dan isi Server Key asli dari Dashboard Midtrans Sandbox.
  echo.
  notepad ".env"
  pause
  exit /b 1
)

echo Menjalankan backend Midtrans di http://localhost:3000 ...
echo Tekan Ctrl+C untuk menghentikan.
echo.
npm.cmd start
pause
