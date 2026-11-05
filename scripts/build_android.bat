@echo off
rem One-shot Android build on Windows: models -> Rust .so -> Flutter APK.
rem
rem Usage: scripts\build_android.bat [--run | --install | --debug] [--no-rust]
rem   --no-rust  skip the Rust step (only Dart/Kotlin changed; the .so from the last build is reused)
rem   (none)     build app\build\app\outputs\flutter-apk\app-release.apk
rem   --install  build and install the release APK on the connected device
rem   --run      build a debug APK and launch it on the connected device (flutter run)
rem   --debug    build a debug APK only
setlocal

set "ROOT=%~dp0.."
for %%I in ("%ROOT%") do set "ROOT=%%~fI"
set "MODE="
set "NORUST="
:args
if "%~1"=="" goto :args_done
if /i "%~1"=="--no-rust" (set "NORUST=1") else (set "MODE=%~1")
shift
goto :args
:args_done

call "%ROOT%\scripts\download_models.bat" || exit /b 1
if defined NORUST (
  if not exist "%ROOT%\app\android\app\src\main\jniLibs\arm64-v8a\libreceipt_ocr.so" (
    echo --no-rust: no libreceipt_ocr.so yet, building it
    call "%ROOT%\scripts\build_android_rust.bat" || exit /b 1
  )
) else (
  call "%ROOT%\scripts\build_android_rust.bat" || exit /b 1
)

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
