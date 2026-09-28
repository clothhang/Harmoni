@echo off
setlocal EnableDelayedExpansion

set "URL=https://nightly.link/love2d/love/workflows/main/main/love-windows-x64.zip"
set "BIN=bin"
set "DEST=%BIN%\love"
set "TEMP=%TEMP%\love_install_%RANDOM%"

if exist "%DEST%" (
    choice /M "LOVE is already installed. Reinstall? "
    if errorlevel 2 exit /b
    rmdir /S /Q "%DEST%"
)

mkdir "%TEMP%"
mkdir "%BIN%" >nul 2>&1

echo Downloading...

powershell -NoProfile -Command "Invoke-WebRequest '%URL%' -OutFile '%TEMP%\outer.zip'" || goto :fail
powershell -NoProfile -Command "Expand-Archive '%TEMP%\outer.zip' '%TEMP%\outer' -Force" || goto :fail

for /R "%TEMP%\outer" %%F in (*.zip) do (
    set "INNERZIP=%%F"
    goto :zip
)

goto :fail

:zip
powershell -NoProfile -Command "Expand-Archive '!INNERZIP!' '%TEMP%\inner' -Force" || goto :fail

for /D %%D in ("%TEMP%\inner\love-*") do (
    xcopy "%%D" "%DEST%" /E /I /Y >nul
    goto :done
)

:fail
rmdir /S /Q "%TEMP%" >nul 2>&1
exit /b 1

:done
rmdir /S /Q "%TEMP%" >nul 2>&1
echo Done.