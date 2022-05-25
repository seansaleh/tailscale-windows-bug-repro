$sleepTime = 0
$ErrorActionPreference = "Stop"
Start-Transcript -OutputDirectory C:\scripts
Write-Host -ForegroundColor Green "Running script: $PSCommandPath"

Write-Host -ForegroundColor Green 'Installing tailscale with TS_UNATTENDEDMODE="always"'
# Note, we write to | Out-Host to make powershell wait on the install finishing
& msiexec TS_UNATTENDEDMODE="always" /i "C:\scripts\tailscale-setup-1.24.2-amd64.msi" /quiet | Out-Host
# Note, installing Tailscale without TS_UNATTENDEDMODE="always" does not make a difference
# & msiexec /i "C:\scripts\tailscale-setup-1.24.2-amd64.msi" /quiet | Out-Host

sleep $sleepTime
Write-Host -ForegroundColor Green 'Starting the tailscale service, just to make sure it is running'
net start Tailscale
sleep $sleepTime
Write-Host -ForegroundColor Green 'Killing the tailscale-ipn.exe process. This makes our install fail and makes it resemble more of an automated headless install scenario.'
taskkill /im tailscale-ipn.exe /f
sleep $sleepTime

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

Write-Host -ForegroundColor Green "Doing a second restart of the tailscale service in case the first stop start didn't cause a failure"
sleep $sleepTime
net stop Tailscale
sleep $sleepTime
net start Tailscale
Write-Host -ForegroundColor Green "Note, we sometimes get 'unexpected state: NoState' from tailscale status" 
Write-Host -ForegroundColor Green "This isn't a sign that the main bug of 'Logged out.' has been triggered instead it appears to be a seperate race condition. A second tailscale status usually resolved unexpected state."
sleep $sleepTime
& "C:\Program Files\Tailscale\tailscale.exe" status
& "C:\Program Files\Tailscale\tailscale.exe" debug prefs
