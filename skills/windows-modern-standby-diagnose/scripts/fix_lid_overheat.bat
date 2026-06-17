@echo off
:: ============================================================
:: Fix laptop overheating/battery-drain after closing lid
:: (Modern Standby S0 -> add hibernate fallback)
:: Effect: enable hibernate + auto-hibernate when standby fails
:: Usage: just double-click (it will prompt for admin once)
:: ============================================================

:: ---- anti-loop guard ----
if "%~1"=="__elevated__" goto :main

:: ---- admin check via fltmc (independent of Server service) ----
fltmc >nul 2>&1
if %errorlevel%==0 goto :main

echo Requesting administrator privileges...
powershell -Command "Start-Process -FilePath '%~f0' -ArgumentList '__elevated__' -Verb RunAs"
exit /b

:main
echo ============================================================
echo   Fix lid-close overheat - enable hibernate + standby fallback
echo ============================================================
echo.

echo [1/3] Enabling hibernate...
powercfg /hibernate on

echo [2/3] On battery: auto-hibernate 30 min after standby...
powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP HIBERNATEIDLE 1800

echo [3/3] Applying power scheme...
powercfg /setactive SCHEME_CURRENT

echo.
echo ------------------------------------------------------------
echo   Core fix applied (battery 30-min hibernate fallback).
echo   This already prevents the lid-close drain on battery.
echo ------------------------------------------------------------
echo.

:: ---- OPTIONAL: AC-side hibernate fallback (default = No) ----
:: The AC HIBERNATEIDLE setting is hidden by Windows by default, so
:: setting it directly fails with "Access is denied". Enabling it
:: requires un-hiding the attribute first. On AC the laptop is
:: charging and won't be drained, so this is optional.
echo Optional: also set AC (plugged-in) 60-min hibernate fallback?
echo   - This un-hides a protected setting, then applies it.
echo   - Not needed to fix the battery drain. Default is No.
set "ANS=N"
set /p "ANS=Apply AC fallback too? [y/N]: "
if /i "%ANS%"=="Y" (
    echo Un-hiding AC hibernate-idle attribute...
    powercfg /attributes SUB_SLEEP HIBERNATEIDLE -ATTRIB_HIDE
    echo On AC: auto-hibernate 60 min after standby...
    powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP HIBERNATEIDLE 3600
    powercfg /setactive SCHEME_CURRENT
    echo AC fallback applied.
) else (
    echo Skipped AC fallback ^(default^).
)

echo.
echo ============================================================
echo   Done. Current sleep states:
echo ============================================================
powercfg /a
echo.
echo Note: from now on, even if Modern Standby cannot drop power,
echo       the laptop will hibernate within 30 min on battery,
echo       so it will no longer overheat or drain the battery.
echo.
pause
