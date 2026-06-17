@echo off
:: ============================================================
:: Show processes currently using audio (find what blocks Modern Standby)
:: Usage: just double-click to run (no admin needed)
:: How: lists processes that loaded the audio session module audioses.dll
:: ============================================================

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Write-Host '==== Processes using / holding audio ====' -ForegroundColor Cyan;" ^
  "Get-Process -ErrorAction SilentlyContinue ^| Where-Object { $_.Modules.ModuleName -contains 'audioses.dll' } ^| Select-Object @{N='Process';E={$_.ProcessName}}, @{N='PID';E={$_.Id}}, @{N='Mem(MB)';E={[math]::Round($_.WorkingSet64/1MB,1)}} ^| Sort-Object 'Mem(MB)' -Descending ^| Format-Table -AutoSize;" ^
  "Write-Host '';" ^
  "Write-Host '==== Audio device driver status (watch for Error/Problem) ====' -ForegroundColor Cyan;" ^
  "Get-PnpDevice -Class 'System','MEDIA' -ErrorAction SilentlyContinue ^| Where-Object { $_.FriendlyName -match 'Smart Sound|Audio|SST' } ^| Select-Object @{N='Status';E={$_.Status}}, @{N='Class';E={$_.Class}}, @{N='Name';E={$_.FriendlyName}} ^| Format-Table -AutoSize -Wrap;" ^
  "Write-Host '';" ^
  "Write-Host 'TIP: before closing the lid, quit/mute the apps above' -ForegroundColor Yellow;" ^
  "Write-Host '     (esp. DingTalk/Antding, meeting apps, music, browser media tabs).' -ForegroundColor Yellow;" ^
  "Write-Host 'EASIER: right-click the speaker icon in tray -> Open Volume Mixer,' -ForegroundColor Yellow;" ^
  "Write-Host '        and see which app is making sound.' -ForegroundColor Yellow"

echo.
pause
