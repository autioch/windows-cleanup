# windows-cleanup
Script for setting up fresh installs (or accounts) for Windows 10. 

Personally using it to automates PS setup for family members - everything that otherwise would be done manually.

Takes about 15min to run everything in it. It's written very simply, so it's easy to comment out what's not needed.


To run powershell scripts, first open PowerShell, then run the command:

```ps1
Set-ExecutionPolicy Bypass -Scope CurrentUser -Force
```

## TODO
- Disable `News and Interests`
- Optimize theme
- Switch more performance settings in advanced settings
- uninstalling Onedrive - should its process be disabled first?
- handle pl installation

- remove windows speech recognition, narrator, solitaire & casual games, paint3d, pogoda/weather, mixed reality portal, edytor video, aplikacja łączę z telefonem, szybka pomoc, rejestrator kroków/problemów, micrososft update health tools, microsoft edge webview 2, more privacy changes, autostart apps
- windows store reset?


# Get-AppxPackage
Name              : Microsoft.MixedReality.Portal
PackageFullName   : Microsoft.MixedReality.Portal_2000.21051.1282.0_x64__8wekyb3d8bbwe
InstallLocation   : C:\Program Files\WindowsApps\Microsoft.MixedReality.Portal_2000.21051.1282.0_x64__8wekyb3d8bbwe
PackageFamilyName : Microsoft.MixedReality.Portal_8wekyb3d8bbwe
NonRemovable      : False


## Get-ProvisionedAppxPackage -Online
DisplayName  : Microsoft.ZuneMusic
PackageName  : Microsoft.ZuneMusic_2019.22031.10091.0_neutral_~_8wekyb3d8bbwe

## Remove-AppPackage -Package
## emove-ProvisionedAppxPackage -PackageName


https://learn.microsoft.com/en-us/windows/application-management/provisioned-apps-windows-client-os