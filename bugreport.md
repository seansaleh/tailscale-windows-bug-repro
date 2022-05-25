# Bug Summary
On Windows, if `tailscale-ipn.exe` is not running, then logging into Tailscale with `tailscale up --unattended` will fail to persist its login credentials after machine or Tailscale service restarts. This manifests as `tailscale status` showing `Logged out.`

If `tailscale-ipn.exe` is running while `tailscale up --unattended` is configured, and is still running when the `tailscale` service gets restarted, then Tailscale in unattended mode will stay logged in across machine reboots to Tailscale service restarts.

# Repro
Checkout the repository https://github.com/seansaleh/tailscale-windows-bug-repro \
Follow the steps in it's [`readme.md`](https://github.com/seansaleh/tailscale-windows-bug-repro/blob/main/readme.md) \
It is designed to use [Windows Sandbox](https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-sandbox/windows-sandbox-overview), since that is the fastest way to get a fresh windows VM and run scripts on it.

## Summary of repro:
There are four repro's of the issue in the repository, they are:
- works-with-ipn-running-always
    - Shows how your tailscale credentials are always persisted across tailscale service restarts if `tailscale-ipn.exe` is always running
- fails-without-ipn
    - Shows how tailscale is `Logged out.` if you don't run `tailscale-ipn.exe` and you restart the tailscale service
- works-with-ipn-running-during-first-service-restart
    - Shows how your tailscale credentials are always persisted across tailscale service restarts if `tailscale-ipn.exe` is running when the tailscale service is restarted for the first time
- fails-with-ipn-running-only-before-first-service-restart
    - Shows how tailscale is `Logged out.` if you kill `tailscale-ipn.exe` while restarting the tailscale service

## Environment:
Tailscale for Windows `1.24.2`
Windows 10 
Partial reproduction on Windows Server 2019

# Confounding factors
## Getting `unexpected state: NoState` from tailscale status
Sometimes if you run `tailscale status` immediately after `net start tailscale` you may get the message  `unexpected state: NoState`. This doesn't mean that you are logged in or out on Tailscale, it is just another bug. If you retry `tailscale status` it will give you accurate results.
## Not waiting for tailscale msi installer to finish
If you don't let the msi installer finish before running `tailscale up --unattended --authkey=<yourkeyhere>` then you may fail to get your login state to persist (likely a race between running `tailscale up` and `tailscale-ipn.exe` launching). You can fix this by making sure to wait for the tailscale installer to finish. \
In Powershell the easiest way is by adding `| Out-Host` like so: `& msiexec /i "tailscale-setup-1.24.2-amd64.msi" /quiet | Out-Host`
## Failures in non-interactive Windows scenarios or after reboot
This repro only covers issues with restarting the service in a Windows. \
There may be additional bugs lurking when running `tailscale up` on machines like Windows Server Core, when running scripts to install and configure tailscale without a login session (like from Ansible, or from AWS UserData Scripts). \
There may also be further issues when doing a full machine restart, not just stopping and starting the service. 
None of these are testable from my repro steps with Windows Sandbox.
## Installing Tailscale with unattended mode already set
Tailscale's MSI installer has [a setting to enable unattended mode](https://tailscale.com/kb/1189/install-windows-msi/#ts_unattendedmode). This didn't seem to make any sort of difference in my repros

# Workarounds:
## For installing in an interactive session _(Aka logged into windows with RDP or the equivalent)_
- Install Tailscale, make sure to wait for the installer to finish. 
    - In Powershell: `& msiexec /i "tailscale-setup-1.24.2-amd64.msi" /quiet | Out-Host`
- Ensure that `tailscale-ipn.exe` is running
- Run `tailscale up --unattended` (with or without `--authkey=<yourkeyhere>`)
- Restart the tailscale service twice, killing `tailscale-ipn.exe` during the second restart
    - In Powershell:
        ```
        net stop Tailscale
        net start Tailscale
        sleep 4
        & "C:\Program Files\Tailscale\tailscale.exe" status
        sleep 2
        net stop Tailscale
        taskkill /im tailscale-ipn.exe /f
        net start Tailscale
        sleep 4
        & "C:\Program Files\Tailscale\tailscale.exe" status
        ```

## For installing in a non-interactive session _(Windows Server Core, Ansible, SSH, AWS UserData Scripts, etc.)_
This is less tested, but there may be a way to run `tailscale-ipn.exe` from the terminal and then following the steps above. \
I was able to get this working for my use case.

From powershell (replacing `<yourkeyhere>`):
```pwsh
# Note that | Out-Host makes sure powershell waits for the installer to finish
& msiexec /i "tailscale-setup-1.24.2-amd64.msi" /quiet | Out-Host
& "C:\Program Files\Tailscale\tailscale-ipn.exe"
sleep 4
& "C:\Program Files\Tailscale\tailscale.exe" up --unattended --authkey=<yourkeyhere>
sleep 2
net stop Tailscale
net start Tailscale
sleep 4
& "C:\Program Files\Tailscale\tailscale.exe" status
sleep 2
net stop Tailscale
taskkill /im tailscale-ipn.exe /f
net start Tailscale
sleep 4
& "C:\Program Files\Tailscale\tailscale.exe" status
```
(All the sleeps above may not be necessary)