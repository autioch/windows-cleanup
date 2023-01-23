function registrySet($Path, $Name, $Type = "Dword", $Value = 0) { 
    if (!(Test-Path $Path)) {
        # Maybe instead of create, use -force with set-itemproperty?
        New-Item -Path $Path | Out-Null
    }
    
    $key = get-item $Path
    
    if ($null -ne $key.getValue($Name)) {
        Set-ItemProperty -Path $Path -Name $Name -Value $Value | Out-Null
    }
    else {
        New-ItemProperty -Path $Path -Name $Name -PropertyType $Type -Value $Value | Out-Null
    }
}

function appInstall($filename, $uri) { 
    $Installer = $env:TEMP + "\" + $filename;
    Invoke-WebRequest $uri -OutFile $Installer;
    Start-Process -FilePath $Installer -Args "/s /silent /install" -Verb RunAs -Wait;
    itemRemove -Path $Installer;
}

function appRemove($package) { 
    Remove-AppxPackage -Package $package -AllUsers -ErrorAction Continue | Out-Null
}

function appRemoveProvisioned($packageName) { 
    Remove-ProvisionedAppxPackage -PackageName $packageName -Online -AllUsers -ErrorAction Continue | Out-Null
}

function appRemoveRegex($regex) { 
    Get-ProvisionedAppxPackage -Online | Where-Object { $_.PackageName -match $regex } | ForEach-Object { Remove-ProvisionedAppxPackage -PackageName $_.PackageName -Online -AllUsers -ErrorAction Continue | Out-Null }
    Get-AppxPackage | Where-Object { $_.PackageName -match $regex } | ForEach-Object { appRemove -Package $_.PackageFullName }
}


function serviceDisable($Name){
    Stop-Service -Name $Name -WarningAction SilentlyContinue | Out-Null
    Set-Service -Name $Name -StartupType "Disabled" | Out-Null
}

function itemRemove($path){
    Remove-Item $path -force -recurse -ErrorAction SilentlyContinue
}

Write-Host "Ensure Admin mode"
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Host "Switch to admin"
    Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    exit;
}

Write-Host "Create Restore Point"
Enable-ComputerRestore -Drive "C:\"
Checkpoint-Computer -Description "RestorePoint1" -RestorePointType "MODIFY_SETTINGS"

Write-Host "Uninstall Cortana"
registrySet -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name AllowCortana -Value 0
appRemove -package Microsoft.549981C3F5F10

Write-Host "Uninstall Spotify"
appRemoveRegex -regex "spotify"

Write-Host "Uninstall microsoft apps"
@(  "Microsoft.BingNews", "Microsoft.GetHelp", "Microsoft.Getstarted", "Microsoft.Microsoft3DViewer", "Microsoft.MicrosoftOfficeHub", "Microsoft.NetworkSpeedTest", "Microsoft.News", "Microsoft.Office.Lens", "Microsoft.Office.OneNote",
    "Microsoft.Office.Sway", "Microsoft.OneConnect", "Microsoft.People", "Microsoft.Print3D", "Microsoft.Office.Todo.List", "Microsoft.Whiteboard", "Microsoft.WindowsAlarms", "Microsoft.WindowsFeedbackHub", "Microsoft.WindowsMaps", 
    "Microsoft.BingWeather", "Microsoft.MicrosoftSolitaireCollection", "Microsoft.MixedReality.Portal", "Microsoft.Wallet", "Microsoft.YourPhone", "Microsoft.XboxGameCallableUI", "Microsoft.MicrosoftTreasureHunt",
    "Microsoft.Windows.NarratorQuickStart", "Microsoft.WindowsSoundRecorder", "Microsoft.ZuneMusic", "Microsoft.ZuneVideo"
) | ForEach-Object { appRemove -package $_ }

Write-Host "Uninstall advertised apps"
@( "EclipseManager", "ActiproSoftwareLLC", "AdobeSystemsIncorporated.AdobePhotoshopExpress", "Duolingo-LearnLanguagesforFree", "PandoraMediaInc", "CandyCrush", 
    "BubbleWitch3Saga", "Wunderlist", "Flipboard", "Twitter", "Facebook", "Minecraft", "Royal Revolt", "Sway", "Dolby"
) | ForEach-Object { appRemove -package $_ }

Write-Host "Uninstall Xbox"
@( "XblAuthManager", "XblGameSave", "XboxGipSvc", "XboxNetApiSvc" ) | ForEach-Object { serviceDisable -Name $_ }
appRemove -package "Microsoft.GamingServices"
appRemoveRegex -regex "xbox"
# This should be found by the regex
# @( "Microsoft.GamingServices", "Microsoft.XboxApp", "Microsoft.Xbox.TCUI", "Microsoft.XboxGameCallableUI", "Microsoft.XboxGameOverlay", "Microsoft.XboxSpeechToTextOverlay", "Microsoft.XboxGamingOverlay", "Microsoft.XboxIdentityProvider", "Microsoft.Xbox.TCUI" ) | ForEach-Object { appRemove -package $_ }
registrySet -Path "HKLM:\SYSTEM\CurrentControlSet\Services\xbgm" -Name "Start" -Value 4
registrySet -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled"
registrySet -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" 
registrySet -Path "HKCU:\Software\Microsoft\GameBar" -Name "ShowGameModeNotifications"
registrySet -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled"
registrySet -Path "HKCU:\Software\Microsoft\GameBar" -Name "ShowStartupPanel"
registrySet -Path "HKCU:\Software\Microsoft\GameBar" -Name "UseNexusForGameBarEnabled"
registrySet -Path "HKLM:\SYSTEM\CurrentControlSet\Services\xbgm" -Name "Start" -Value 4
registrySet -Path "HKLM:\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter" -Name "ActivationType"

# TODO Doesn't work
Write-Host "Uninstall what's possible from the pinned in Start Menu"
(New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() | ForEach-Object { $_.Verbs() } | Where-Object { $_.Name -match 'Uninstall' } | ForEach-Object { $_.DoIt() }

# TODO Doesn't work
Write-Host "Unpin what's remaining from the pinnsed in Start Menu"
(New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() | ForEach-Object { $_.Verbs() } | Where-Object { $_.Name -match 'Un.*pin from Start' } | ForEach-Object { $_.DoIt() }


Write-Host "Disable Task View button"
registrySet -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton"

Write-Host "Changing default Explorer view to This PC..."
registrySet -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1

Write-Host "Show known file extensions"
registrySet -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt"

Write-Host "Disable People icon on Taskbar"
registrySet -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Name "PeopleBand"

Write-Host "Disable suggestions in the Start Menu"
registrySet -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled"

Write-Host "Disable bloatware reinstall"
registrySet -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1

Write-Host "Disable Bing Search in the Start Menu search"
registrySet -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Value 1

Write-Host "Show all tray icons"
registrySet -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray"

Write-Host "Never join taskbar items"
registrySet -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarGlomLevel" -Value 1

Write-Host "Show all icons on the desktop"
@("{20D04FE0-3AEA-1069-A2D8-08002B30309D}", "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}", "{59031a47-3f72-44a7-89c5-5595fe6b30ee}", "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}", "{645FF040-5081-101B-9F08-00AA002F954E}") | ForEach-Object { registrySet -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name $_ }

Write-Host "Hide searchbar"
registrySet -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchBoxTaskbarMode"

Write-Host "Showing file operations details..."
registrySet -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" -Name "EnthusiastMode" -Value 1

Write-Host "Best Performance settings"
registrySet -Path "HKCU:\Control Panel\Desktop" -Name "DragFullWindows" -Type String -Value 0
registrySet -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Type String -Value 10
registrySet -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Type Binary -Value ([byte[]](144, 18, 3, 128, 16, 0, 0, 0))
registrySet -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Type String -Value 0
registrySet -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay"
registrySet -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewAlphaSelect"
registrySet -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewShadow"
registrySet -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations"
registrySet -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 3
registrySet -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "EnableAeroPeek"

Write-Host "Disable Activity History"
registrySet -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed"
registrySet -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities"
registrySet -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities"

Write-Host "Disabling Feedback..."
registrySet -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod"
registrySet -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Value 1
Disable-ScheduledTask -TaskName "Microsoft\Windows\Feedback\Siuf\DmClient" -ErrorAction SilentlyContinue | Out-Null
Disable-ScheduledTask -TaskName "Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" -ErrorAction SilentlyContinue | Out-Null

Write-Host "Disable advertising ID"
registrySet -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -Value 1

Write-Host "Disable error reporting"
registrySet -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Value 1
Disable-ScheduledTask -TaskName "Microsoft\Windows\Windows Error Reporting\QueueReporting" | Out-Null

Write-Host "Stop and disable Diagnostics Tracking Service"
serviceDisable -Name "DiagTrack"

Write-Host "Turn off Data Collection via AllowTelemtry"
registrySet -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry"

Write-Host "Disable automatic Maps update"
registrySet -Path "HKLM:\SYSTEM\Maps" -Name "AutoUpdateEnabled"

Write-Host "Disable Weather & Interests"
registrySet - Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" - Name "ShellFeedsTaskbarViewMode " -Value 2

Write-Host "Disable Hibernation"
registrySet -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Power" -Name "HibernteEnabled"
registrySet -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" -Name "ShowHibernateOption"

Write-Host "Driver updates through Windows Update"
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Name "PreventDeviceMetadataFromNetwork" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontPromptForWindowsUpdate" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontSearchWindowsUpdate" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DriverUpdateWizardWuSearchEnabled" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -ErrorAction SilentlyContinue

Write-Host "Install browsers"
appInstall -filename "chrome_installer.exe" -uri "http://dl.google.com/chrome/install/375.126/chrome_installer.exe"
appInstall -filename "firefox.exe" -uri "https://download.mozilla.org/?product=firefox-msi-latest-ssl&os=win64&lang=en-US"
appInstall -filename "brave_installer-x64.exe" -uri "https://brave-browser-downloads.s3.brave.com/latest/brave_installer-x64.exe"

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
itemRemove -Path "$env:USERPROFILE\OneDrive" 
itemRemove -Path "$env:LOCALAPPDATA\Microsoft\OneDrive"
itemRemove -Path "$env:PROGRAMDATA\Microsoft OneDrive"
itemRemove -Path "$env:SYSTEMDRIVE\OneDriveTemp" 
If (!(Test-Path "HKCR:")) { New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null }
itemRemove -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" 
itemRemove -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" 

Write-Host "Language - takes time"
Install-Language pl-PL
Set-WinSystemLocale -SystemLocale pl-PL

Write-Host "Cleanup temp folders"
itemRemove -Path @( “C:\Windows\Temp\*”, “C:\Windows\Prefetch\*”, “C:\Documents and Settings\*\Local Settings\temp\*”, “C:\Users\*\Appdata\Local\Temp\*” )

Write-Host "Disk cleanup"
cleanmgr /sagerun:1 /VeryLowDisk /AUTOCLEAN | Out-Null

Write-Host "dism image cleanup"
dism.exe /Online /Cleanup-Image /RestoreHealth 
dism.exe /Online /Cleanup-Image /StartComponentCleanup
dism.exe /Online /Cleanup-Image /SPSuperseded

read-host "Done. Press ENTER to restart Themes services and exit"
Restart-Service Themes -Force
