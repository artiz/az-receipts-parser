@echo off
rem One-shot Android build on Windows: models -> Rust .so -> Flutter APK.
rem
rem Usage: scripts\build_android.bat [--run | --install | --debug]
rem   (none)     build app\build\app\outputs\flutter-apk\app-release.apk
rem   --install  build and install the release APK on the connected device
rem   --run      build a debug APK and launch it on the connected device (flutter run)
rem   --debug    build a debug APK only
setlocal

set "ROOT=%~dp0.."
for %%I in ("%ROOT%") do set "ROOT=%%~fI"
set "MODE=%~1"

call "%ROOT%\scripts\download_models.bat" || exit /b 1
call "%ROOT%\scripts\build_android_rust.bat" || exit /b 1

pushd "%ROOT%\app" || exit /b 1
call flutter pub get || goto :fail

if /i "%MODE%"=="--run" (
  call flutter run
  goto :done
)
if /i "%MODE%"=="--debug" (
  call flutter build apk --debug
  goto :done
)
call flutter build apk --release || goto :fail
if /i "%MODE%"=="--install" (
  call flutter install --release
  goto :done
)
echo.
echo APK: %ROOT%\app\build\app\outputs\flutter-apk\app-release.apk

:done
set "RC=%ERRORLEVEL%"
popd
exit /b %RC%

:fail
popd
exit /b 1
