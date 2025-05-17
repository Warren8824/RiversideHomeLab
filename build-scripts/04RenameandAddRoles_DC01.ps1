# Domain Controller Setup Script
# This script will:
# 1. Check if roles are installed and install if missing
# 2. Rename the computer to DC01
# 3. Restart if needed

# Requires elevated permissions - must be run as Administrator

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script must be run as Administrator" -ForegroundColor Red
    exit
}

# Track if we need to restart
$restartNeeded = $false

# Check computer name and change if needed
$currentName = $env:COMPUTERNAME
if ($currentName -ne "DC01") {
    Write-Host "Renaming computer from $currentName to DC01..." -ForegroundColor Yellow
    Rename-Computer -NewName "DC01" -Force
    $restartNeeded = $true
    Write-Host "Computer will be renamed to DC01 after restart" -ForegroundColor Green
}

# List of required roles with friendly names and corresponding Windows feature names
$requiredRoles = @{
    "Active Directory Domain Services" = "AD-Domain-Services";
    "DHCP Server" = "DHCP";
    "DNS Server" = "DNS";
    "Remote Access" = "RemoteAccess"
}

# Check and install required roles
Write-Host "Checking required roles..." -ForegroundColor Cyan
foreach ($role in $requiredRoles.GetEnumerator()) {
    $roleName = $role.Key
    $featureName = $role.Value

    Write-Host "Checking for $roleName..." -NoNewline

    # Check if role is installed
    $installed = Get-WindowsFeature -Name $featureName | Where-Object {$_.InstallState -eq "Installed"}

    if ($installed) {
        Write-Host " Already installed!" -ForegroundColor Green
    } else {
        Write-Host " Not installed. Installing..." -ForegroundColor Yellow

        # Install the role with management tools
        $result = Install-WindowsFeature -Name $featureName -IncludeManagementTools

        if ($result.Success) {
            Write-Host "Successfully installed $roleName" -ForegroundColor Green
            if ($result.RestartNeeded -eq "Yes") {
                $restartNeeded = $true
            }
        } else {
            Write-Host "Failed to install $roleName" -ForegroundColor Red
            Write-Host $result.ExitCode
        }
    }
}

# Check if management tools are installed for AD DS specifically
Write-Host "Checking for RSAT AD management tools..." -NoNewline
$adTools = Get-WindowsFeature -Name "RSAT-AD-Tools" | Where-Object {$_.InstallState -eq "Installed"}
if ($adTools) {
    Write-Host " Already installed!" -ForegroundColor Green
} else {
    Write-Host " Not installed. Installing AD management tools..." -ForegroundColor Yellow
    $result = Install-WindowsFeature -Name "RSAT-AD-Tools" -IncludeAllSubFeature
    if ($result.Success) {
        Write-Host "Successfully installed AD management tools" -ForegroundColor Green
    } else {
        Write-Host "Failed to install AD management tools" -ForegroundColor Red
    }
}

# Summary
Write-Host "`n==== Installation Summary ====" -ForegroundColor Cyan
Write-Host "Computer name: " -NoNewline
if ($currentName -ne "DC01") {
    Write-Host "$currentName -> DC01 (pending restart)" -ForegroundColor Yellow
} else {
    Write-Host "DC01" -ForegroundColor Green
}

Write-Host "`nInstalled Roles:" -ForegroundColor Cyan
foreach ($role in $requiredRoles.GetEnumerator()) {
    $roleName = $role.Key
    $featureName = $role.Value

    $installed = Get-WindowsFeature -Name $featureName | Where-Object {$_.InstallState -eq "Installed"}

    Write-Host "- $roleName : " -NoNewline
    if ($installed) {
        Write-Host "Installed" -ForegroundColor Green
    } else {
        Write-Host "Not installed" -ForegroundColor Red
    }
}

# Check if we need to promote to Domain Controller
Write-Host "`nNext Steps:" -ForegroundColor Cyan
if (Get-Service -Name "NTDS" -ErrorAction SilentlyContinue) {
    Write-Host "This server is already configured as a Domain Controller." -ForegroundColor Green
} else {
    Write-Host "After roles are installed and server is restarted, promote to Domain Controller using:" -ForegroundColor Yellow
    Write-Host "Import-Module ADDSDeployment" -ForegroundColor White
    Write-Host "Install-ADDSForest -DomainName yourdomain.local -InstallDNS" -ForegroundColor White
}

# Offer to restart if needed
if ($restartNeeded) {
    Write-Host "`nA restart is required to complete the installation." -ForegroundColor Yellow
    $answer = Read-Host "Do you want to restart now? (Y/N)"
    if ($answer -eq "Y" -or $answer -eq "y") {
        Write-Host "Restarting computer..." -ForegroundColor Cyan
        Restart-Computer -Force
    } else {
        Write-Host "Please restart the computer manually to complete the setup." -ForegroundColor Yellow
    }
} else {
    Write-Host "`nNo restart is required." -ForegroundColor Green
}