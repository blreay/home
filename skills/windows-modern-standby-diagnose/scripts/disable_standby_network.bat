@echo off
:: ============================================================
:: Disable "network connectivity in standby" (S0 self-connect)
:: Stops Modern Standby from periodically bringing Wi-Fi online
:: on its own -> removes the "self-wake -> unattended-timeout ->
:: early hibernate" chain, and saves standby power.
::
:: IMPORTANT: on company-managed PCs the security software (e.g.
:: AspectService) INTERCEPTS this change and shows an approval
:: prompt. "Access is denied" just means the prompt was not
:: approved (or was hidden). This script runs in a VISIBLE window
:: so you can see and APPROVE the prompt. Watch the screen.
:: ============================================================

:: ---- anti-loop guard ----
if "%~1"=="__elevated__" goto :main

:: ---- admin check via fltmc (independent of Server service) ----
fltmc >nul 2>&1
if %errorlevel%==0 goto :main

echo Requesting administrator privileges...
:: NOTE: deliberately NOT hidden - the security prompt must be visible
powershell -Command "Start-Process -FilePath '%~f0' -ArgumentList '__elevated__' -Verb RunAs"
exit /b

:main
set GUID_SUB=fea3413e-7e05-4911-9a71-700331f1c294
set GUID_SET=f15576e8-98b7-4186-b944-eafa664402d9

echo ============================================================
echo   Disable network connectivity in standby (S0 self-connect)
echo ============================================================
echo.
echo If your company security software pops up an approval dialog,
echo click ALLOW. If a step says "Access is denied", it only means
echo that prompt was not approved - just rerun this script.
echo.

echo [1/4] Unhiding the setting (so it is writable/visible)...
powercfg /attributes %GUID_SUB% %GUID_SET% -ATTRIB_HIDE

echo.
echo [2/4] Disabling on BATTERY (DC)...
powercfg /setdcvalueindex SCHEME_CURRENT %GUID_SUB% %GUID_SET% 0
if errorlevel 1 (
    echo   ^> denied once, retrying ONE more time - APPROVE the prompt...
    powercfg /setdcvalueindex SCHEME_CURRENT %GUID_SUB% %GUID_SET% 0
)

echo.
echo [3/4] Disabling on AC (plugged in)...
powercfg /setacvalueindex SCHEME_CURRENT %GUID_SUB% %GUID_SET% 0
if errorlevel 1 (
    echo   ^> denied once, retrying ONE more time - APPROVE the prompt...
    powercfg /setacvalueindex SCHEME_CURRENT %GUID_SUB% %GUID_SET% 0
)

echo.
echo [4/4] Applying and verifying...
powercfg /setactive SCHEME_CURRENT
echo.
echo ------------------------------------------------------------
echo   Current value (index 0 = Disabled = success):
echo ------------------------------------------------------------
powercfg /q SCHEME_CURRENT %GUID_SUB% %GUID_SET% | findstr /i "Index"
echo.
echo   AC index 0x0 = disabled on AC
echo   DC index 0x0 = disabled on battery
echo   (0x1 = Enabled, 0x2 = Managed by Windows)
echo.
echo ============================================================
echo   If either side still shows 0x1/0x2, rerun this script and
echo   be sure to click ALLOW on the security prompt that appears.
echo   Battery (DC) is the one that matters most for lid-closed
echo   drain; AC stays charging so it is optional.
echo ============================================================
echo.
echo NOTE: the surest 100%% network cutoff is Airplane Mode / Wi-Fi
echo   off before closing the lid - no setting can be blocked there.
echo.
pause
