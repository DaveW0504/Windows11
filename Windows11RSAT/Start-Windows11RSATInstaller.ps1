# RSAT Installation Script for Windows 11
# Script will download and install RSAT tools based on user selection

function Show-Menu {
    param (
        [string]$Title = 'RSAT Tools Installation'
    )
    Clear-Host
    Write-Host "================ $Title ================"
    Write-Host
    Write-Host "1: Show all available RSAT features"
    Write-Host "2: Install specific RSAT feature"
    Write-Host "3: Install all RSAT features"
    Write-Host "4: Check installed RSAT features"
    Write-Host "Q: Quit"
    Write-Host
}

function Get-AllRSATFeatures {
    # Get all RSAT related features
    $rsatFeatures = Get-WindowsCapability -Online | Where-Object { $_.Name -like "*RSAT*" }
    return $rsatFeatures
}

function Show-AllRSATFeatures {
    $rsatFeatures = Get-AllRSATFeatures
    
    if ($rsatFeatures.Count -eq 0) {
        Write-Host "No RSAT features found. Make sure you're connected to the internet." -ForegroundColor Red
        return
    }
    
    Write-Host "Available RSAT Features:" -ForegroundColor Cyan
    $i = 1
    $rsatFeatures | ForEach-Object {
        $status = if ($_.State -eq "Installed") { "[Installed]" } else { "[Not Installed]" }
        Write-Host "$i. $($_.Name) $status"
        $i++
    }
}

function Install-SelectedRSATFeature {
    $rsatFeatures = Get-AllRSATFeatures
    
    if ($rsatFeatures.Count -eq 0) {
        Write-Host "No RSAT features found. Make sure you're connected to the internet." -ForegroundColor Red
        return
    }
    
    Write-Host "Available RSAT Features:" -ForegroundColor Cyan
    $i = 1
    $rsatFeatures | ForEach-Object {
        $status = if ($_.State -eq "Installed") { "[Installed]" } else { "[Not Installed]" }
        Write-Host "$i. $($_.Name) $status"
        $i++
    }
    
    $selection = Read-Host "Enter the number of the feature you want to install (or 'C' to cancel)"
    
    if ($selection -eq "C") {
        return
    }
    
    $selectionInt = 0
    if ([int]::TryParse($selection, [ref]$selectionInt)) {
        if ($selectionInt -ge 1 -and $selectionInt -le $rsatFeatures.Count) {
            $selectedFeature = $rsatFeatures[$selectionInt - 1]
            
            if ($selectedFeature.State -eq "Installed") {
                Write-Host "Feature is already installed: $($selectedFeature.Name)" -ForegroundColor Yellow
                return
            }
            
            Write-Host "Installing feature: $($selectedFeature.Name)" -ForegroundColor Cyan
            
            try {
                Add-WindowsCapability -Online -Name $selectedFeature.Name
                Write-Host "Installation completed successfully!" -ForegroundColor Green
            }
            catch {
                Write-Host "Error installing feature: $_" -ForegroundColor Red
                
                # Try alternative method if the standard method fails
                Write-Host "Trying alternative installation method..." -ForegroundColor Yellow
                try {
                    DISM.exe /Online /Add-Capability /CapabilityName:$($selectedFeature.Name)
                    Write-Host "Alternative installation completed successfully!" -ForegroundColor Green
                }
                catch {
                    Write-Host "Alternative installation also failed: $_" -ForegroundColor Red
                }
            }
        }
        else {
            Write-Host "Invalid selection. Please enter a number between 1 and $($rsatFeatures.Count)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Invalid input. Please enter a valid number or 'C' to cancel." -ForegroundColor Red
    }
}

function Install-AllRSATFeatures {
    $rsatFeatures = Get-AllRSATFeatures
    
    if ($rsatFeatures.Count -eq 0) {
        Write-Host "No RSAT features found. Make sure you're connected to the internet." -ForegroundColor Red
        return
    }
    
    $notInstalledFeatures = $rsatFeatures | Where-Object { $_.State -ne "Installed" }
    
    if ($notInstalledFeatures.Count -eq 0) {
        Write-Host "All RSAT features are already installed." -ForegroundColor Yellow
        return
    }
    
    Write-Host "Installing all RSAT features. This may take some time..." -ForegroundColor Cyan
    
    $installedCount = 0
    $failedCount = 0
    
    foreach ($feature in $notInstalledFeatures) {
        Write-Host "Installing: $($feature.Name)" -ForegroundColor Cyan
        
        try {
            Add-WindowsCapability -Online -Name $feature.Name
            Write-Host "Successfully installed: $($feature.Name)" -ForegroundColor Green
            $installedCount++
        }
        catch {
            Write-Host "Failed to install: $($feature.Name) - trying alternative method" -ForegroundColor Yellow
            
            # Try alternative method
            try {
                DISM.exe /Online /Add-Capability /CapabilityName:$($feature.Name)
                Write-Host "Successfully installed with alternative method: $($feature.Name)" -ForegroundColor Green
                $installedCount++
            }
            catch {
                Write-Host "Failed to install: $($feature.Name)" -ForegroundColor Red
                $failedCount++
            }
        }
    }
    
    Write-Host "Installation complete. Successfully installed: $installedCount, Failed: $failedCount" -ForegroundColor Cyan
}

function Check-InstalledRSATFeatures {
    $rsatFeatures = Get-AllRSATFeatures
    $installedFeatures = $rsatFeatures | Where-Object { $_.State -eq "Installed" }
    
    if ($installedFeatures.Count -eq 0) {
        Write-Host "No RSAT features are currently installed." -ForegroundColor Yellow
    }
    else {
        Write-Host "Installed RSAT Features:" -ForegroundColor Green
        $i = 1
        $installedFeatures | ForEach-Object {
            Write-Host "$i. $($_.Name)"
            $i++
        }
        Write-Host "Total installed features: $($installedFeatures.Count)" -ForegroundColor Cyan
    }
}

# Main script starts here
Write-Host "Checking if running as administrator..." -ForegroundColor Yellow
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "This script needs to be run as Administrator." -ForegroundColor Red
    Write-Host "Please right-click on PowerShell and select 'Run as administrator', then run the script again." -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

# Check internet connection
Write-Host "Checking internet connection..." -ForegroundColor Cyan
$internetConnected = $false
try {
    $internetConnected = Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet
}
catch {
    $internetConnected = $false
}

if (-not $internetConnected) {
    Write-Host "Internet connection not detected. RSAT features need to be downloaded from the internet." -ForegroundColor Red
    Write-Host "Please check your internet connection and try again." -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

# Welcome message
Write-Host "Welcome to the RSAT Tools Installation Script for Windows 11" -ForegroundColor Cyan
Write-Host "This script will help you install Remote Server Administration Tools (RSAT)" -ForegroundColor Cyan
Write-Host

# Main script loop
do {
    Show-Menu
    $input = Read-Host "Please make a selection"
    
    switch ($input) {
        '1' {
            Show-AllRSATFeatures
        }
        '2' {
            Install-SelectedRSATFeature
        }
        '3' {
            Install-AllRSATFeatures
        }
        '4' {
            Check-InstalledRSATFeatures
        }
        'q' {
            Write-Host "Exiting script. Thank you for using the RSAT Installation Tool!" -ForegroundColor Green
            break
        }
        default {
            Write-Host "Invalid selection. Please try again." -ForegroundColor Red
        }
    }
    
    if ($input -ne 'q') {
        Write-Host
        Write-Host "Press Enter to continue..."
        $null = Read-Host
    }
} until ($input -eq 'q')

# Keep the window open after script completes
if (-not $psISE) {
    Write-Host "Press any key to exit..."
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
