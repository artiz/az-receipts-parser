@echo off
rem Cross-compile rust\receipt_ocr for Android (arm64) and drop the .so into the
rem Flutter project's jniLibs (Windows). Requires:
rem   - Android NDK (ANDROID_NDK_HOME, or %ANDROID_HOME%\ndk\<version>, or the
rem     Android Studio default %LOCALAPPDATA%\Android\Sdk\ndk\<version>)
rem   - rustup target aarch64-linux-android (added below)
rem   - cargo-ndk  (cargo install cargo-ndk)
rem
rem Usage: scripts\build_android_rust.bat [--debug] [--abi arm64-v8a[,x86_64]]
setlocal EnableDelayedExpansion

set "ROOT=%~dp0.."
for %%I in ("%ROOT%") do set "ROOT=%%~fI"
set "CRATE=%ROOT%\rust\receipt_ocr"
set "OUT=%ROOT%\app\android\app\src\main\jniLibs"
set "PROFILE=--release"
set "ABIS=arm64-v8a"

:args
if "%~1"=="" goto :args_done
if /i "%~1"=="--debug" (set "PROFILE=" & shift & goto :args)
if /i "%~1"=="--abi" (set "ABIS=%~2" & shift & shift & goto :args)
echo unknown option %~1 & exit /b 2
:args_done

rem --- locate the NDK -----------------------------------------------------------
if not "%ANDROID_NDK_HOME%"=="" goto :ndk_ok
if "%ANDROID_HOME%"=="" if exist "%LOCALAPPDATA%\Android\Sdk" set "ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk"
if exist "%ANDROID_HOME%\ndk" (
  for /f "delims=" %%d in ('dir /b /ad /o-n "%ANDROID_HOME%\ndk"') do (
    if "!ANDROID_NDK_HOME!"=="" set "ANDROID_NDK_HOME=%ANDROID_HOME%\ndk\%%d"
  )
)
if "%ANDROID_NDK_HOME%"=="" (
  echo ANDROID_NDK_HOME is not set and no NDK was found under %%ANDROID_HOME%%\ndk.
  echo Install "NDK (Side by side)" in Android Studio ^> SDK Manager ^> SDK Tools.
  exit /b 1
)
:ndk_ok
echo NDK: %ANDROID_NDK_HOME%

where cargo-ndk >nul 2>nul || (echo cargo-ndk missing: run "cargo install cargo-ndk" & exit /b 1)

set "TARGETS="
for %%a in (%ABIS:,= %) do (
  if /i "%%a"=="arm64-v8a" rustup target add aarch64-linux-android >nul
  if /i "%%a"=="x86_64" rustup target add x86_64-linux-android >nul
  if /i "%%a"=="armeabi-v7a" rustup target add armv7-linux-androideabi >nul
  set "TARGETS=!TARGETS! -t %%a"
)

rem `ort` is built with `load-dynamic`: nothing from pyke's CDN is downloaded and
rem libonnxruntime.so comes from the onnxruntime-android AAR at run time.
pushd "%CRATE%" || exit /b 1
cargo ndk%TARGETS% -o "%OUT%" --platform 26 build %PROFILE% --lib
set "RC=%ERRORLEVEL%"
popd
if not "%RC%"=="0" exit /b %RC%

echo.
dir /s /b "%OUT%\libreceipt_ocr.so"
exit /b 0
