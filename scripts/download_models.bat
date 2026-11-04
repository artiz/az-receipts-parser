@echo off
rem Fetch the docling.rs OCR models the app bundles as Flutter assets (Windows).
rem
rem Source: https://github.com/docling-project/docling.rs/releases (tag models-v1),
rem verified against the release's SHA256SUMS. ~31 MB in total:
rem   ocr_det.onnx          PP-OCRv6 text detector
rem   ocr_rec_v6.onnx       PP-OCRv6 multilingual recognizer (+ dictionary)
rem   ocr_textline_ori.onnx 0/180 degree text-line orientation classifier (optional)
rem
rem Usage: scripts\download_models.bat [target-dir]   (default: app\assets\models)
rem Needs curl.exe and PowerShell, both part of Windows 10/11.
setlocal EnableDelayedExpansion

set "ROOT=%~dp0.."
for %%I in ("%ROOT%") do set "ROOT=%%~fI"
if "%~1"=="" (set "TARGET=%ROOT%\app\assets\models") else (set "TARGET=%~f1")
if "%DOCLING_RS_MODELS_URL%"=="" (
  set "BASE=https://github.com/docling-project/docling.rs/releases/download/models-v1"
) else (
  set "BASE=%DOCLING_RS_MODELS_URL%"
)
set "FILES=ocr_det.onnx ocr_rec_v6.onnx ocr_rec_v6_dict.txt ocr_textline_ori.onnx"

where curl.exe >nul 2>nul || (echo curl.exe not found. Install it or use Windows 10 1803+ & exit /b 1)

if not exist "%TARGET%" mkdir "%TARGET%"
pushd "%TARGET%" || exit /b 1

curl.exe -fsSL -o SHA256SUMS "%BASE%/SHA256SUMS" || (echo failed to download SHA256SUMS & popd & exit /b 1)

for %%F in (%FILES%) do (
  call :expected "%%F" || (popd & exit /b 1)
  if exist "%%F" (
    call :verify "%%F" !EXPECTED!
    if !ERRORLEVEL! EQU 0 (
      echo ok ^(cached^)  %%F
    ) else (
      call :fetch "%%F" !EXPECTED! || (popd & exit /b 1)
    )
  ) else (
    call :fetch "%%F" !EXPECTED! || (popd & exit /b 1)
  )
)

> VERSION echo models-v1 %DATE%
del SHA256SUMS
popd
echo models in %TARGET%
exit /b 0

:expected
rem Looks up the sha256 for a file name in SHA256SUMS ("<hash>  <name>").
rem Read line by line (hash, name split on whitespace); findstr's "$" anchor is
rem unreliable on LF-only files, which is what the release serves.
set "EXPECTED="
for /f "usebackq tokens=1,2" %%a in ("SHA256SUMS") do (
  if /i "%%b"=="%~1" set "EXPECTED=%%a"
)
if "!EXPECTED!"=="" (echo %~1 is not listed in SHA256SUMS & exit /b 1)
exit /b 0

:verify
rem %1 file, %2 expected sha256. Returns 0 when the hash matches.
set "ACTUAL="
for /f "usebackq delims=" %%h in (`powershell -NoProfile -Command "(Get-FileHash -Algorithm SHA256 -LiteralPath '%~1').Hash.ToLower()"`) do set "ACTUAL=%%h"
if /i "!ACTUAL!"=="%~2" exit /b 0
exit /b 1

:fetch
echo downloading  %~1
curl.exe -fsSL -o "%~1" "%BASE%/%~1" || (echo download failed: %~1 & exit /b 1)
call :verify "%~1" %~2 || (echo checksum mismatch: %~1 & del "%~1" & exit /b 1)
exit /b 0
