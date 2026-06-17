@echo off
:: ============================================================
:: Show what is BLOCKING the system from sleeping
:: (catches the "lid closed but never slept" case)
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
echo   What is blocking sleep right now (powercfg /requests)
echo ============================================================
echo.
echo Look at the SYSTEM / EXECUTION / DISPLAY / AWAYMODE sections:
echo any process or driver listed there is preventing sleep.
echo (e.g. tblive.exe = DingTalk live plugin, a media player, etc.)
echo.
powercfg /requests
echo.
echo ============================================================
echo   Recently active wake-blocking history (last few sessions)
echo   If the latest sleepstudy session shows STATE = Active while
echo   the lid was closed, a program blocked sleep (not a deep-sleep
echo   problem). Run collect_reports.bat and check the State column.
echo ============================================================
echo.
pause
