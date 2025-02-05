<#
    This script is designed to remove some of the unnecessary applications that comes installed with Windows 10
    and adjust some of the privacy settings within Windows 10.

    Some of this code was copied over from the Windows10Debloater script: https://github.com/Sycnex/Windows10Debloater/blob/master/Windows10Debloater.ps1
    Please use the above script for more options.
#>

Function Remove-Packages {
    # These are the packages that we want to remove from the system.
    $Pkgs = @(
    "Microsoft.BingWeather",
    "Microsoft.Getstarted",
    "Microsoft.GetHelp",
    "Microsoft.Messaging",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.Office.OneNote",
    "Microsoft.People",
    "Microsoft.SkypeApp",
    "Microsoft.SolitaireCollection",
    "Microsoft.StickyNotes",
    "Microsoft.Wallet",
    "Microsoft.WindowsMaps",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo"
    )

    # Uninstall the packages defined in the $Pkgs array
    Foreach ($Pkg in $Pkgs) {
        Write-output "Uninstalling the following package : $Pkg"
        Get-AppxPackage -AllUsers -Name $Pkg | Remove-AppxPackage
        #Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq $Pkg} | Remove-AppxProvisionedPackage -Online
    }
}

Function Protect-Privacy {
        #Disables Windows Feedback Experience
    Write-Output "Disabling Windows Feedback Experience program"
    $Advertising = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
    If (Test-Path $Advertising) {
        Set-ItemProperty $Advertising Enabled -Value 0 
    }
            
    #Stops Cortana from being used as part of your Windows Search Function
    Write-Output "Stopping Cortana from being used as part of your Windows Search Function"
    $Search = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    If (Test-Path $Search) {
        Set-ItemProperty $Search AllowCortana -Value 0 
    }

    #Disables Web Search in Start Menu
    Write-Output "Disabling Bing Search in Start Menu"
    $WebSearch = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" BingSearchEnabled -Value 0 
    If (!(Test-Path $WebSearch)) {
        New-Item $WebSearch
    }
    Set-ItemProperty $WebSearch DisableWebSearch -Value 1 
            
    #Stops the Windows Feedback Experience from sending anonymous data
    Write-Output "Stopping the Windows Feedback Experience program"
    $Period = "HKCU:\Software\Microsoft\Siuf\Rules"
    If (!(Test-Path $Period)) { 
        New-Item $Period
    }
    Set-ItemProperty $Period PeriodInNanoSeconds -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Type DWord -Value 1
    Disable-ScheduledTask -TaskName "Microsoft\Windows\Feedback\Siuf\DmClient" -ErrorAction SilentlyContinue | Out-Null
    Disable-ScheduledTask -TaskName "Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" -ErrorAction SilentlyContinue | Out-Null

    #Prevents bloatware applications from returning and removes Start Menu suggestions               
    Write-Output "Adding Registry key to prevent bloatware apps from returning"
    $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
    $registryOEM = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    If (!(Test-Path $registryPath)) { 
        New-Item $registryPath
    }
    Set-ItemProperty $registryPath DisableWindowsConsumerFeatures -Value 1 

    If (!(Test-Path $registryOEM)) {
        New-Item $registryOEM -Force
    }
    Set-ItemProperty $registryOEM  ContentDeliveryAllowed -Value 0 
    Set-ItemProperty $registryOEM  OemPreInstalledAppsEnabled -Value 0 
    Set-ItemProperty $registryOEM  PreInstalledAppsEnabled -Value 0 
    Set-ItemProperty $registryOEM  PreInstalledAppsEverEnabled -Value 0 
    Set-ItemProperty $registryOEM  SilentInstalledAppsEnabled -Value 0 
    Set-ItemProperty $registryOEM  SystemPaneSuggestionsEnabled -Value 0
}

Function Tweak-Services {
    # These are services that don't really provide any value and can be disabled. Most of them are telemery services.
    $DisableServices = @(
        "DiagTrack"                                 # Connected User Experiences and Telemetry
        "diagnosticshub.standardcollector.service"  # Microsoft (R) Diagnostics Hub Standard Collector Service
        "dmwappushservice"                          # Device Management Wireless Application Protocol (WAP)
        "GraphicsPerfSvc"                           # Graphics performance monitor service
        "HomeGroupListener"                         # HomeGroup Listener
        "HomeGroupProvider"                         # HomeGroup Provider
        "lfsvc"                                     # Geolocation Service
        "MapsBroker"                                # Downloaded Maps Manager
        "PcaSvc"                                    # Program Compatibility Assistant (PCA)
        "RemoteAccess"                              # Routing and Remote Access
        "RemoteRegistry"                            # Remote Registry
        "RetailDemo"                                # DEFAULT: Manual    | The Retail Demo Service controls device activity while the device is in retail demo mode.
        "TrkWks"                                    # Distributed Link Tracking Client
    )

    Foreach ($Service in $DisableServices) {
        If (Get-Service $Service -ErrorAction SilentlyContinue) {
            If ((Get-Service $Service).StartType -eq "Disabled") {
                Write-Host "$Service start type is already set to disabled." -ForegroundColor "Green"
            }
            Else {
                Write-Host "Setting $Service start type to disabled." -ForegroundColor "Blue"
                Set-Service $Service -StartupType "Disabled"
            }
        }
    }

    # These two services have a uniquely generated ID at the end of their service name.
    # The below commands get the actual service name so that we can pass them below.
    $BroadcastService = (Get-service "BcastDVRUserService_*").Name
    $CaptureService = (Get-Service "CaptureService_*").Name

    # These are services that can be set to manual startup type, so that if an application calls them, they can start.
    $ManualServices = @(
        "Sysmain"                                   # Superfetch can improve PC performance
        "wisvc"                                     # Disable Windows Insider
        "SharedAccess"                              # Internet Connection Sharing (ICS)
        "WerSvc"                                    # Windows Error Reporting
        "fax"                                       # Windows fax service
        "fhsvc"                                     # Fax history
        "WpcMonSvc"                                 # Parental Controls
        "SCardSvr"                                  # Smart card service
        "SEMgrSvc"                                  # NFC/SE manager (near field communications)
        "$BroadcastService"                         # GaveDVR and broadcast
        "$CaptureService"                           # Screen capture capabilities for applications that call Windows.Graphics.Capture API
    )

    Foreach ($Service in $ManualServices) {
        If (Get-Service $Service -ErrorAction SilentlyContinue) {
            If ((Get-Service $Service).StartType -eq "Manual") {
                Write-Host "$Service start type is already set to manual" -ForegroundColor "Green"
            }
            Else {
                Write-Host "Setting $Service start type to manual." -ForegroundColor "Blue"
                Set-Service $Service -StartupType "Manual"
            }
        }
    }
}

Function Custom-Tweaks {
    <#
        LaunchTo values will open the following items:
        1 = Computer
        2 = Fast Access
        3 = Downloads
    #>
    Write-Host "Set Explorers Entry Point"
	$LaunchTo = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
	Set-ItemProperty $LaunchTo LaunchTo -Value 1

    # Disable hibernation
    powercfg -h off

    # Disable Windows news and interests
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" -Name "EnableFeeds" -Type DWord -Value 0
    # Remove "News and Interest" from taskbar
    Set-ItemProperty -Path  "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -Type DWord -Value 2
}


do {
    $UninstallPkgs = Read-Host "Do you want to remove unnecessary packages? (y/n)"
    If ($UninstallPkgs -eq "y") {
        Remove-Packages
        Break
    }
} until ($UninstallPkgs -eq "n")

do {
    $ProtectPrivacy = Read-Host "Do you want to adjust privacy settings? (y/n)"
    if ($ProtectPrivacy -eq 'y') {
        Protect-Privacy
        Break
    }
} until ($ProtectPrivacy -eq "n")

do {
    $CustomTweaks = Read-Host "Do you want to apply custom tweaks? (y/n)"
    if ($CustomTweaks -eq 'y') {
        Custom-Tweaks
        Break
    }
} until ($CustomTweaks -eq "n")

do {
    $TweakServices = Read-Host "Do you want to adjust Windows services? (y/n)"
    if ($TweakServices -eq 'y') {
        Tweak-Services
        Break
    }
} until ($TweakServices -eq "n")