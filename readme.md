# Setup
## Pre-req's
* Install Windows Sandbox: https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-sandbox/windows-sandbox-overview#installation
## Tailscale Installer
Download [`tailscale-setup-1.24.2-amd64.msi`](https://pkgs.tailscale.com/stable/tailscale-setup-1.24.2-amd64.msi) to the root of this repo. You can get it at https://pkgs.tailscale.com/stable/#windows \
If you want to use a newer version replace all reference in the code to `tailscale-setup-1.24.2-amd64.msi`
## Text Replacement
You must replace two different strings in the code to make this work. I'd highly suggest you do find and replace in the whole repository.
* `REPLACE_ME_WITH_YOUR_AUTHKEY`
   - Generate a reusable Tailscale auth key at https://login.tailscale.com/admin/settings/keys and replace all references to `REPLACE_ME_WITH_YOUR_AUTHKEY`
* `REPLACE_ME_WITH_THIS_REPOS_PATH`
   - Replace this with the path to this git Repository. Like `C:\dev\tailscale-windows-bug-repro`

# Explanation
This repo is for helping diagnose and reproduce Tailscale bugs https://github.com/tailscale/tailscale/issues/2137 and https://github.com/tailscale/tailscale/issues/3186

It uses Windows Sandbox to very quickly iterate and get a new clean Windows VM to test things in.

You can double click on the different `.wsb` files to launch a new VM which shows the bug failing with Tailscale.

The different test cases:
- works-with-ipn-running-always
    - Shows how your tailscale credentials are always persisted across tailscale service restarts if `tailscale-ipn.exe` is always running
- fails-without-ipn
    - Shows how tailscale is `Logged out.` if you don't run `tailscale-ipn.exe` and you restart the tailscale service
- works-with-ipn-running-during-first-service-restart
    - Shows how your tailscale credentials are always persisted across tailscale service restarts if `tailscale-ipn.exe` is running when the tailscale service is restarted for the first time
- fails-with-ipn-running-only-before-first-service-restart
    - Shows how tailscale is `Logged out.` if you kill `tailscale-ipn.exe` while restarting the tailscale service