@echo off
rem Create the upload keystore for Google Play and write app\android\key.properties
rem (both stay out of git). Run once per machine that builds release bundles.
rem
rem Usage: scripts\make_keystore.bat [path\to\upload.jks]
rem   default keystore path: %USERPROFILE%\az-budget-upload.jks (outside the repo)
rem
rem Back the .jks and the passwords up somewhere safe: with Play App Signing a
rem lost upload key can be reset through Play support, but it costs days.
setlocal EnableDelayedExpansion

set "ROOT=%~dp0.."
for %%I in ("%ROOT%") do set "ROOT=%%~fI"
set "KS=%~1"
if "%KS%"=="" set "KS=%USERPROFILE%\az-budget-upload.jks"
set "PROPS=%ROOT%\app\android\key.properties"

rem --- keytool: JAVA_HOME, Android Studio's bundled JDK, then PATH ---------------
set "KEYTOOL="
if not "%JAVA_HOME%"=="" if exist "%JAVA_HOME%\bin\keytool.exe" set "KEYTOOL=%JAVA_HOME%\bin\keytool.exe"
if "%KEYTOOL%"=="" if exist "%ProgramFiles%\Android\Android Studio\jbr\bin\keytool.exe" set "KEYTOOL=%ProgramFiles%\Android\Android Studio\jbr\bin\keytool.exe"
if "%KEYTOOL%"=="" if exist "%LOCALAPPDATA%\Programs\Android Studio\jbr\bin\keytool.exe" set "KEYTOOL=%LOCALAPPDATA%\Programs\Android Studio\jbr\bin\keytool.exe"
if "%KEYTOOL%"=="" for %%p in (keytool.exe) do if not "%%~$PATH:p"=="" set "KEYTOOL=%%~$PATH:p"
if "%KEYTOOL%"=="" (
  echo keytool.exe not found: set JAVA_HOME or install Android Studio.
  exit /b 1
)

if exist "%KS%" (
  echo Keystore already exists: %KS%
  echo Delete it first if you really want a new one ^(a new key cannot update an app uploaded with the old one^).
  exit /b 1
)

set /p "PASS=Keystore password (min 6 characters, same for the key): "
if "%PASS%"=="" exit /b 1
set /p "NAME=Your name or company for the certificate [AZ Budget]: "
if "%NAME%"=="" set "NAME=AZ Budget"

"%KEYTOOL%" -genkeypair -v -keystore "%KS%" -alias upload -keyalg RSA -keysize 2048 -validity 10000 ^
  -storepass "%PASS%" -keypass "%PASS%" -dname "CN=%NAME%"
rem keytool's exit code is not trusted (some launchers return nonzero after a
rem successful store): the keystore file is what counts.
if not exist "%KS%" (
  echo keytool did not create %KS%
  exit /b 1
)

rem Gradle reads the path with forward slashes fine; backslashes would be escapes.
set "KSF=!KS:\=/!"
rem Written line by line with delayed expansion, so a password with & ^ ( ) or
rem quotes cannot break the command.
> "%PROPS%" echo storeFile=!KSF!
>> "%PROPS%" echo storePassword=!PASS!
>> "%PROPS%" echo keyAlias=upload
>> "%PROPS%" echo keyPassword=!PASS!
if not exist "%PROPS%" (
  echo could not write %PROPS%
  exit /b 1
)

echo.
echo Keystore: %KS%
echo Written:  %PROPS%  ^(ignored by git^)
echo Release builds and bundles are now signed with the upload key: scripts\build_android.bat --bundle
echo BACK UP the keystore and the password now.
endlocal
