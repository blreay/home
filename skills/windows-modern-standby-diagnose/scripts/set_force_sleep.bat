@echo off
:: ============================================================
:: Sleep/hibernate timing safety net
:: - idle -> sleep (defeats "program keeps it awake", B-class)
:: - sleep N hours -> hibernate (fallback when standby drains, A-class)
:: Uses powercfg /change (the standard interface) FIRST, because on
:: IT-managed / locked machines /setdcvalueindex returns "Access is
:: denied" while /change still works. setvalueindex is used only as a
:: fallback for the AC side of hibernate-timeout.
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
echo   Sleep/hibernate timing safety net
echo ============================================================
echo.

echo [1/4] On battery: SLEEP after 10 min idle...
powercfg /change standby-timeout-dc 10
echo [2/4] On AC: SLEEP after 30 min idle...
powercfg /change standby-timeout-ac 30

echo [3/4] On battery: HIBERNATE after 16 hours of sleep (960 min)...
:: /change is reliable on locked machines; 960 min = 16 h
powercfg /change hibernate-timeout-dc 960
echo [4/4] On AC: HIBERNATE after 16 hours of sleep (960 min)...
powercfg /change hibernate-timeout-ac 960

powercfg /setactive SCHEME_CURRENT

echo.
echo ------------------------------------------------------------
echo   Set: idle 10/30 min -> sleep; then 16 h -> hibernate.
echo   Lid closed = sleep (instant resume on open) for up to 16 h,
echo   then hibernates. Critical-battery action (hibernate) still
echo   protects against drain inside that 16 h window.
echo ------------------------------------------------------------
echo.

:: ---- OPTIONAL: permanently ignore a specific app's wake requests ----
:: Default = No. Use only if one app repeatedly blocks sleep.
echo Optional: permanently ignore a specific process's wake requests?
echo   Example culprit seen on this machine: tblive.exe (DingTalk live).
echo   This runs: powercfg /requestsoverride PROCESS ^<name^> SYSTEM EXECUTION DISPLAY AWAYMODE
echo   Default is No.
set "ANS=N"
set /p "ANS=Add a requestsoverride for a process? [y/N]: "
if /i "%ANS%"=="Y" (
    set "PROC="
    set /p "PROC=Enter process exe name (e.g. tblive.exe): "
    if not "%PROC%"=="" (
        powercfg /requestsoverride PROCESS "%PROC%" SYSTEM EXECUTION DISPLAY AWAYMODE
        echo Override added for %PROC%. Current overrides:
        powercfg /requestsoverride
    ) else (
        echo No process name entered, skipped.
    )
) else (
    echo Skipped requestsoverride ^(default^).
)

echo.
echo ============================================================
echo   Done. Current sleep/hibernate timeouts:
echo ============================================================
echo [STANDBYIDLE expect DC=0x258=10min]
powercfg /q SCHEME_CURRENT SUB_SLEEP 29f6c1db-86da-48c5-9fdb-f2b67b1f44da | findstr /i "Index 索引"
echo [HIBERNATEIDLE expect DC=0xe100=16h]
powercfg /q SCHEME_CURRENT SUB_SLEEP 9d7815a6-7ee4-497e-8888-515a05f02364 | findstr /i "Index 索引"
echo.
echo NOTE: if hibernate timeout did NOT change, your power plan is
echo       locked. /change is the most reliable path; setvalueindex
echo       will fail with "Access is denied" on such machines.
echo.
pause
