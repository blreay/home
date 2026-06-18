@echo off
:: ============================================================
:: Disable network-adapter wake (stop NIC from waking/keeping the
:: system busy during sleep -> less standby drain).
:: Disables, for every physical network adapter:
::   - Wake-on-Magic-Packet  (power management)
::   - Wake-on-Pattern-Match (power management)
::   - any device armed to wake the system (powercfg)
:: Keeps "allow the computer to turn off this device to save power".
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
echo   Disable network-adapter wake (reduce standby drain)
echo ============================================================
echo.

echo [1/3] Disabling Wake-on-Magic-Packet / Wake-on-Pattern-Match
echo       on all physical network adapters...
echo       (adapters reporting "Unsupported" cannot wake anyway - harmless)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$nics = Get-NetAdapter -Physical -ErrorAction SilentlyContinue;" ^
  "foreach ($n in $nics) {" ^
  "  $pm = Get-NetAdapterPowerManagement -Name $n.Name -ErrorAction SilentlyContinue;" ^
  "  if ($pm -and ($pm.WakeOnMagicPacket -eq 'Unsupported') -and ($pm.WakeOnPattern -eq 'Unsupported')) { Write-Host ('  N/A  ' + $n.Name + ' (wake unsupported)') -ForegroundColor DarkGray; continue }" ^
  "  try { Disable-NetAdapterPowerManagement -Name $n.Name -WakeOnMagicPacket -WakeOnPattern -ErrorAction Stop; Write-Host ('  OK   ' + $n.Name) -ForegroundColor Green }" ^
  "  catch { try { $pm.WakeOnMagicPacket='Disabled'; $pm.WakeOnPattern='Disabled'; Set-NetAdapterPowerManagement -InputObject $pm; Write-Host ('  OK*  ' + $n.Name) -ForegroundColor Green } catch { Write-Host ('  SKIP ' + $n.Name + ' (' + $_.Exception.Message + ')') -ForegroundColor Yellow } }" ^
  "}"

echo.
echo [2/3] Disabling system wake for any wake-armed device...
for /f "delims=" %%D in ('powercfg /devicequery wake_armed') do (
    if not "%%D"=="" if /i not "%%D"=="NONE" if not "%%D"=="无" (
        echo   disabling wake: %%D
        powercfg /devicedisablewake "%%D"
    )
)

echo.
echo [3/3] Verifying...
echo ---- Adapters still allowed to wake the system ----
powercfg /devicequery wake_armed
echo ---- Per-adapter power management (expect Disabled or Unsupported) ----
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Get-NetAdapterPowerManagement -ErrorAction SilentlyContinue | Select-Object Name, WakeOnMagicPacket, WakeOnPattern | Format-Table -AutoSize"

echo.
echo ============================================================
echo   Done. NIC wake disabled - this blocks the main path for the
echo   network to wake/keep the system busy during standby.
echo ============================================================
echo.
echo NOTE: to also stop S0 from periodically self-connecting in
echo   standby, disable CONNECTIVITYINSTANDBY. On company-managed PCs
echo   powercfg may return "Access is denied" - that is the security
echo   software intercepting, NOT a hard lock. Run it in a VISIBLE
echo   elevated window and APPROVE the security prompt; it then works:
echo     powercfg /setdcvalueindex SCHEME_CURRENT SUB_NONE ^
echo       f15576e8-98b7-4186-b944-eafa664402d9 0
echo   (retry the AC side separately if it gets denied once.)
echo.
echo TIP: the surest way to stop ALL network drain is to turn on
echo      Airplane Mode (or switch Wi-Fi off) before closing the lid.
echo      Physical disconnect - security software cannot block it.
echo.
pause
