@echo off
setlocal
set "GRADLE_VERSION=8.9"
set "CACHE_DIR=%USERPROFILE%\.gradle\dest-os-ares\gradle-%GRADLE_VERSION%"
set "GRADLE_BIN=%CACHE_DIR%\bin\gradle.bat"
if not exist "%GRADLE_BIN%" (
  if not exist "%CACHE_DIR%" mkdir "%CACHE_DIR%"
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -UseBasicParsing -Uri 'https://services.gradle.org/distributions/gradle-%GRADLE_VERSION%-bin.zip' -OutFile '%CACHE_DIR%\gradle.zip'"
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Force '%CACHE_DIR%\gradle.zip' '%CACHE_DIR%\extracted'"
  del /q "%CACHE_DIR%\gradle.zip"
  copy /y "%CACHE_DIR%\extracted\gradle-%GRADLE_VERSION%\bin\gradle.bat" "%GRADLE_BIN%" >nul
  xcopy /e /i /y "%CACHE_DIR%\extracted\gradle-%GRADLE_VERSION%" "%CACHE_DIR%" >nul
)
call "%GRADLE_BIN%" %*
endlocal
