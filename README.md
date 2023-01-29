# windows-cleanup
Script for setting up fresh installs (or accounts) for Windows 10. 

Personally using it to automates PS setup for family members - everything that otherwise would be done manually.

Takes about 15min to run everything in it. It's written very simply, so it's easy to comment out what's not needed.


To run powershell scripts, first open PowerShell, then run the command:

```ps1
Set-ExecutionPolicy Bypass -Scope CurrentUser -Force
```

Apps to remove found based on 
https://learn.microsoft.com/en-us/windows/application-management/provisioned-apps-windows-client-os


## TODO
- Disable `News and Interests`
- Optimize theme
- Switch more performance settings in advanced settings
- handle pl installation
- unpin start menu

- remove windows speech recognition, narrator, solitaire & casual games, paint3d, pogoda/weather, mixed reality portal, edytor video, aplikacja łączę z telefonem, szybka pomoc, rejestrator kroków/problemów, micrososft update health tools, microsoft edge webview 2, more privacy changes, autostart apps
- windows store reset?


## Commands used

### Get-AppxPackage
Lists app installed for the user

```
Name              : Microsoft.MixedReality.Portal
PackageFullName   : Microsoft.MixedReality.Portal_2000.21051.1282.0_x64__8wekyb3d8bbwe
InstallLocation   : C:\Program Files\WindowsApps\Microsoft.MixedReality.Portal_2000.21051.1282.0_x64__8wekyb3d8bbwe
PackageFamilyName : Microsoft.MixedReality.Portal_8wekyb3d8bbwe
NonRemovable      : False
```


### Get-ProvisionedAppxPackage -Online
Lists app in the image,  installed for the every new user.

```
DisplayName  : Microsoft.ZuneMusic
PackageName  : Microsoft.ZuneMusic_2019.22031.10091.0_neutral_~_8wekyb3d8bbwe
```


### Remove-AppPackage -Package
The Remove-AppxPackage cmdlet removes an app package from a user account. An app package has an .msix or .appx file name extension


### Remove-ProvisionedAppxPackage -PackageName
Remove app from the Windows Image. Removed app will not be nstalled when creating new user accounts.

