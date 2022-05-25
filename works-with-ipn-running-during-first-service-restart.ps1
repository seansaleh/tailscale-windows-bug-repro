$sleepTime = 0
$ErrorActionPreference = "Stop"
Start-Transcript -OutputDirectory C:\scripts
Write-Host -ForegroundColor Green "Running script: $PSCommandPath"

Write-Host -ForegroundColor Green 'Installing tailscale'
# Note, we write to | Out-Host to make powershell wait on the install finishing
& msiexec /i "C:\scripts\tailscale-setup-1.24.2-amd64.msi" /quiet | Out-Host

# sleep $sleepTime
# Write-Host -ForegroundColor Green 'Starting the tailscale service, just to make sure it is running'
# net start Tailscale
# sleep $sleepTime

Write-Host -ForegroundColor Green 'Running tailscale debug prefs'
& "C:\Program Files\Tailscale\tailscale.exe" debug prefs
Write-Host -ForegroundColor Green 'Running tailscale up --unattended --authkey='
Write-Host -ForegroundColor Green 'Bug: this very rarely hangs, last seen when not waiting on the msi to finish installing.'
& "C:\Program Files\Tailscale\tailscale.exe" up --unattended --authkey=REPLACE_ME_WITH_YOUR_AUTHKEY
Write-Host -ForegroundColor Green 'Running tailscale status (to ensure this connected)'
& "C:\Program Files\Tailscale\tailscale.exe" status
& "C:\Program Files\Tailscale\tailscale.exe" debug prefs

Write-Host -ForegroundColor Green 'Restarting Tailscale service'
sleep $sleepTime
net stop Tailscale
sleep $sleepTime
net start Tailscale
sleep $sleepTime
Write-Host -ForegroundColor Green 'Checking Tailscale status. When the bug is triggered this shows "Logged out."'
& "C:\Program Files\Tailscale\tailscale.exe" status
& "C:\Program Files\Tailscale\tailscale.exe" debug prefs

Write-Host -ForegroundColor Green "Restarting the tailscale service a second time, and killing tailscale-ipn.exe along the way. Note that if we kill tailscale-ipn.exe during the first service restart then this would fail."
sleep $sleepTime
net stop Tailscale
sleep $sleepTime
Write-Host -ForegroundColor Green 'Killing the tailscale GUI tailscale-ipn.exe'
taskkill /im tailscale-ipn.exe /f
sleep $sleepTime
net start Tailscale
Write-Host -ForegroundColor Green "Note, we sometimes get 'unexpected state: NoState' from tailscale status" 
Write-Host -ForegroundColor Green "This isn't a sign that the main bug of 'Logged out.' has been triggered instead it appears to be a seperate race condition. A second tailscale status usually resolved unexpected state."
sleep $sleepTime
& "C:\Program Files\Tailscale\tailscale.exe" status
& "C:\Program Files\Tailscale\tailscale.exe" debug prefs

Write-Host -ForegroundColor Green "Doing a third restart of the tailscale service to prove that we don't need tailscale-ipn.exe"
sleep $sleepTime
net stop Tailscale
sleep $sleepTime
net start Tailscale
sleep $sleepTime
& "C:\Program Files\Tailscale\tailscale.exe" status
& "C:\Program Files\Tailscale\tailscale.exe" debug prefs