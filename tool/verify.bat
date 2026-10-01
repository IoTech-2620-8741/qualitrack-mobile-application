@echo off
REM QualiTrack Mobile - verification (double-click). Output: tool\logs\verify.log
setlocal
cd /d "%~dp0.."
if not exist tool\logs mkdir tool\logs
set LOG=tool\logs\verify.log
set CI=true
echo # verify started %DATE% %TIME% > %LOG%

echo ===== flutter --version =====>> %LOG%
call flutter --version --suppress-analytics < nul >> %LOG% 2>&1
echo exit=%ERRORLEVEL%>> %LOG%

if not exist android (
  echo ===== flutter create =====>> %LOG%
  call flutter create --suppress-analytics --org com.iotech --project-name qualitrack_mobile --platforms android,ios . < nul >> %LOG% 2>&1
  echo exit=%ERRORLEVEL%>> %LOG%
)

echo ===== flutter pub get =====>> %LOG%
call flutter pub get --suppress-analytics < nul >> %LOG% 2>&1
echo exit=%ERRORLEVEL%>> %LOG%

echo ===== dart format . =====>> %LOG%
call dart format . < nul >> %LOG% 2>&1
echo exit=%ERRORLEVEL%>> %LOG%

echo ===== flutter analyze =====>> %LOG%
call flutter analyze --suppress-analytics < nul >> %LOG% 2>&1
echo exit=%ERRORLEVEL%>> %LOG%

echo ===== flutter test =====>> %LOG%
call flutter test --suppress-analytics --reporter expanded < nul >> %LOG% 2>&1
echo exit=%ERRORLEVEL%>> %LOG%

echo # verify finished %DATE% %TIME%>> %LOG%
echo.
echo Listo. Resultado en %LOG%
pause
