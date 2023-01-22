Write-Host "Ensure Admin mode"
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Host "Switch to admin"
    Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
}

# Restore point
Write-Host "Create Restore Point"
Enable-ComputerRestore -Drive "C:\"
Checkpoint-Computer -Description "RestorePoint1" -RestorePointType "MODIFY_SETTINGS"


Write-Host "Uninstall bloatware"


Write-Host "Remove Cortana"
$Search = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
If (Test-Path $Search) { Set-ItemProperty $Search AllowCortana -Value 0 }
Get-AppxPackage -allusers Microsoft.549981C3F5F10 | Remove-AppxPackage

# TODO - test on new account
Write-Host "Uninstall what's possible from the pinnsed in Start Menu"
(New-Object -Com Shell.Application).
NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').
Items() | ForEach-Object { $_.Verbs() } | Where-Object { $_.Name -match 'Uninstall' } | ForEach-Object { $_.DoIt() }


# TODO - test on new account
Write-Host "Unpin what's remaining from the pinnsed in Start Menu"
(New-Object -Com Shell.Application).
NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').
Items() | ForEach-Object { $_.Verbs() } | Where-Object { $_.Name -match 'Un.*pin from Start' } | ForEach-Object { $_.DoIt() }


Write-Host "Remove Xbox"
@( "XblAuthManager", "XblGameSave", "XboxGipSvc", "XboxNetApiSvc" ) | ForEach-Object { Set-Service -Name $_ -StartupType "Disabled"  }
Get-ProvisionedAppxPackage -Online | Where-Object { $_.PackageName -match "xbox" } | ForEach-Object { Remove-ProvisionedAppxPackage -Online -AllUsers -PackageName $_.PackageName }
@( "Microsoft.GamingServices", "Microsoft.XboxApp", "Microsoft.Xbox.TCUI", "Microsoft.XboxGameCallableUI", "Microsoft.XboxGameOverlay", "Microsoft.XboxSpeechToTextOverlay", "Microsoft.XboxGamingOverlay", "Microsoft.XboxIdentityProvider", "Microsoft.Xbox.TCUI" ) | ForEach-Object { Get-AppxPackage -allusers $_ | Remove-AppxPackage -ErrorAction SilentlyContinue }
$PathToLMServicesXbgm = "HKLM:\SYSTEM\CurrentControlSet\Services\xbgm"
If (!(Test-Path "$PathToLMServicesXbgm")) { New-Item -Path "$PathToLMServicesXbgm" -Force | Out-Null }
Set-ItemProperty -Path "$PathToLMServicesXbgm" -Name "Start" -Type DWord -Value 4


Write-Host "Remove other advertised apps"
@( "Microsoft.BingNews", "Microsoft.GetHelp", "Microsoft.Getstarted", "Microsoft.Microsoft3DViewer", "Microsoft.MicrosoftOfficeHub", "Microsoft.NetworkSpeedTest", "Microsoft.News", "Microsoft.Office.Lens", "Microsoft.Office.OneNote",
    "Microsoft.Office.Sway", "Microsoft.OneConnect", "Microsoft.People", "Microsoft.Print3D", "Microsoft.Office.Todo.List", "Microsoft.Whiteboard", "Microsoft.WindowsAlarms", "Microsoft.WindowsFeedbackHub", "Microsoft.WindowsMaps", 
    "Microsoft.WindowsSoundRecorder", "Microsoft.ZuneMusic", "Microsoft.ZuneVideo", "EclipseManager", "ActiproSoftwareLLC", "AdobeSystemsIncorporated.AdobePhotoshopExpress", "Duolingo-LearnLanguagesforFree", "PandoraMediaInc", "CandyCrush", 
    "BubbleWitch3Saga", "Wunderlist", "Flipboard", "Twitter", "Facebook", "Spotify", "Minecraft", "Royal Revolt", "Sway", "Dolby" ) | ForEach-Object { Get-AppxPackage -allusers $_ | Remove-AppxPackage }


Write-Host "Add Registry key to prevent return of the bloatware"
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
If (!(Test-Path $registryPath)) {
    Mkdir $registryPath
    New-ItemProperty $registryPath DisableWindowsConsumerFeatures -Value 1 
}     


# Cleanup UI
# TODO - test on new account
Write-Host "Cleanup UI"


Write-Host "Hide Task View button"
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Type DWord -Value 0


Write-Host "Disable People icon on Taskbar"
$People = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People'
If (Test-Path $People) { Set-ItemProperty $People -Name PeopleBand -Value 0 }


Write-Host "Disable suggestions in the Start Menu"
$Suggestions = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'    
If (Test-Path $Suggestions) { Set-ItemProperty $Suggestions -Name SystemPaneSuggestionsEnabled -Value 0 }


Write-Host "Disable Bing Search in the Start Menu search"
$BingSearch = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
If (Test-Path $BingSearch) { Set-ItemProperty $BingSearch DisableSearchBoxSuggestions -Value 1 }


Write-Host "Changing default Explorer view to This PC..."
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Type DWord -Value 1


Write-Host "Show all tray icons"
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -Type DWord -Value 0


# UI optimizations
Write-Host "UI optimizations"


Write-Host "Show known file extensions"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Type DWord -Value 0


Write-Host "Show all icons on the desktop"
$path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
@("{20D04FE0-3AEA-1069-A2D8-08002B30309D}", "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}", "{59031a47-3f72-44a7-89c5-5595fe6b30ee}", "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}", "{645FF040-5081-101B-9F08-00AA002F954E}") | ForEach-Object { Set-ItemProperty -Path $path -Name $_ -Value 0 }


Write-Host "Showing file operations details..."
If (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager")) { New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" | Out-Null }
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" -Name "EnthusiastMode" -Type DWord -Value 1


Write-Host "Best Performance settings"
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "DragFullWindows" -Type String -Value 0
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Type String -Value 10
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Type Binary -Value ([byte[]](144, 18, 3, 128, 16, 0, 0, 0))
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Type String -Value 0
Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Type DWord -Value 0
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewAlphaSelect" -Type DWord -Value 0
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewShadow" -Type DWord -Value 0
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Type DWord -Value 0
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Type DWord -Value 3
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "EnableAeroPeek" -Type DWord -Value 0


# Privacy and background
Write-Host "Privacy and background"


Write-Host "Disable Activity History"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Type DWord -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Type DWord -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Type DWord -Value 0


Write-Host "Disabling Feedback..."
If (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules")) { New-Item -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Force | Out-Null }
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod" -Type DWord -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Type DWord -Value 1
Disable-ScheduledTask -TaskName "Microsoft\Windows\Feedback\Siuf\DmClient" -ErrorAction SilentlyContinue | Out-Null
Disable-ScheduledTask -TaskName "Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" -ErrorAction SilentlyContinue | Out-Null


Write-Host "Disable advertising ID"
If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo")) { New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" | Out-Null }
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -Type DWord -Value 1


Write-Host "Disable error reporting"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Type DWord -Value 1
Disable-ScheduledTask -TaskName "Microsoft\Windows\Windows Error Reporting\QueueReporting" | Out-Null


Write-Host "Stop and disable Diagnostics Tracking Service"
Stop-Service "DiagTrack" -WarningAction SilentlyContinue
Set-Service "DiagTrack" -StartupType Disabled


Write-Host "Turn off Data Collection via AllowTelemtry"
$DataCollection = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
If (Test-Path $DataCollection) { Set-ItemProperty $DataCollection -Name AllowTelemetry -Value 0 }


Write-Host "Disable automatic Maps update"
Set-ItemProperty -Path "HKLM:\SYSTEM\Maps" -Name "AutoUpdateEnabled" -Type DWord -Value 0


Write-Host "Stop and disable Diagnostics Tracking Service"
Stop-Service "DiagTrack"
Set-Service "DiagTrack" -StartupType Disabled


Write-Host "Disable Hibernation"
powercfg /hibernate off
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Power" -Name "HibernteEnabled" -Type Dword -Value 0
If (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings")) {
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" | Out-Null
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" -Name "ShowHibernateOption" -Type Dword -Value 0


Write-Host "Driver updates through Windows Update"
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Name "PreventDeviceMetadataFromNetwork" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontPromptForWindowsUpdate" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontSearchWindowsUpdate" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DriverUpdateWizardWuSearchEnabled" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -ErrorAction SilentlyContinue


# Install apps
Write-Host "Install apps"


Write-Host "Install Chrome"
$Installer =  $env:TEMP + "chrome_installer.exe"; Invoke-WebRequest -Uri "http://dl.google.com/chrome/install/375.126/chrome_installer.exe" -OutFile $Installer; Start-Process -FilePath $Installer -Args "/silent /install" -Verb RunAs -Wait; Remove-Item -Path $Installer


Write-Host "Install Firefox"
$Installer = $env:TEMP + "\firefox.exe"; Invoke-WebRequest "https://download.mozilla.org/?product=firefox-msi-latest-ssl&os=win64&lang=en-US" -OutFile $Installer; Start-Process -FilePath $Installer -Args "/s" -Verb RunAs -Wait; Remove-Item $Installer;


Write-Host "Install Brave"
$Installer = $env:TEMP + "\brave_installer-x64.exe"; Invoke-WebRequest "https://brave-browser-downloads.s3.brave.com/latest/brave_installer-x64.exe" -OutFile $Installer; Start-Process -FilePath $Installer -Args "/s" -Verb RunAs -Wait; Remove-Item $Installer;


# Time consuming stuff
Write-Host "Time consuming stuff"


Write-Host "Uninstall OneDrive - takes time"
If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive")) { New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" | Out-Null }
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Type DWord -Value 1
Stop-Process -Name "OneDrive" -ErrorAction SilentlyContinue
Start-Sleep -s 2
$onedrive = "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe"
If (!(Test-Path $onedrive)) { $onedrive = "$env:SYSTEMROOT\System32\OneDriveSetup.exe" }
Start-Process $onedrive "/uninstall" -NoNewWindow -Wait
Start-Sleep -s 2
Stop-Process -Name "explorer" -ErrorAction SilentlyContinue
Start-Sleep -s 2
Remove-Item -Path "$env:USERPROFILE\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "$env:PROGRAMDATA\Microsoft OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "$env:SYSTEMDRIVE\OneDriveTemp" -Force -Recurse -ErrorAction SilentlyContinue
If (!(Test-Path "HKCR:")) { New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null }
Remove-Item -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -ErrorAction SilentlyContinue


# Language
Write-Host "Language - takes time"
Install-Language pl-PL


# Cleanup
Write-Host "Cleanup"


Write-Host "Cleanup temp folders"
$tempfolders = @( “C:\Windows\Temp\*”, “C:\Windows\Prefetch\*”, “C:\Documents and Settings\*\Local Settings\temp\*”, “C:\Users\*\Appdata\Local\Temp\*” )
Remove-Item $tempfolders -force -recurse


#Disk Clean up Tool
Write-Host "Disk cleanup"
cleanmgr /sagerun:1 /VeryLowDisk /AUTOCLEAN | Out-Null

Write-Host "dism image cleanup"

Write-Host "Repair any damaged parts"
dism.exe /Online /Cleanup-Image /RestoreHealth 
Write-Host "Analyze image"
dism.exe /Online /Cleanup-Image /AnalyzeComponentStore
Write-Host "Remove old component files"
dism.exe /Online /Cleanup-Image /StartComponentCleanup
Write-Host "Remove superseded service pack files"
dism.exe /Online /Cleanup-Image /SPSuperseded


# Finalize
read-host "Done. Press ENTER to restart Themes services and exit"
Restart-Service Themes -Force
