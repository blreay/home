@echo off
:: ============================================================
:: Collect Modern Standby diagnostic reports
:: - sleepstudy.html : per-session low-power %, component active ranking,
::                     Problem Device flags  (find what blocks standby)
:: - diag.html       : system sleep timeline, per-device D0/Dx states
:: - batteryreport.html : per-standby drain (mWh/%), battery health
:: Usage: just double-click (it will prompt for admin once)
:: Output: saved to your Desktop
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
set "OUT=%USERPROFILE%\Desktop"

echo ============================================================
echo   Collecting Modern Standby diagnostic reports
echo   Output folder: %OUT%
echo ============================================================
echo.

echo [1/3] Generating sleepstudy report (component power ranking)...
powercfg /sleepstudy /output "%OUT%\sleepstudy.html"

echo [2/3] Generating system sleep diagnostics (device timeline)...
powercfg /systemsleepdiagnostics /output "%OUT%\diag.html"

echo [3/3] Generating battery report (standby drain / health)...
powercfg /batteryreport /output "%OUT%\batteryreport.html"

echo.
echo ============================================================
echo   Done. Reports saved to your Desktop:
echo     - sleepstudy.html
echo     - diag.html
echo     - batteryreport.html
echo ============================================================
echo.
echo Open sleepstudy.html and look at the latest standby session:
echo   * %% LOW POWER STATE TIME (SW/HW): should be ^>90%%, low = bad
echo   * Component active ranking + "Problem Device: TRUE" = the culprit
echo   * DripsTransitions = 0 means it never reached deep low-power
echo.
pause
