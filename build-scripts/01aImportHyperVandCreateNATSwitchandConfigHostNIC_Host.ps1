<#
.SYNOPSIS
    Prepares Hyper-V host by creating the Internal switch for NAT and configuring its host NIC.
.DESCRIPTION
    This script runs under PowerShell 5.1 with the Hyper-V module installed. It:
    - Verifies Administrator privileges
    - Validates running on the Hyper-V host
    - Imports the Hyper-V module
    - Creates one Internal virtual switch: NATSwitch (if missing)
    - Configures the host's Internal vEthernet (NATSwitch) adapter with IP 192.168.100.1/24 if not already configured
    - Outputs success messages to the console and stops on any error
    NOTE: Private switches (MAN-SW01, LEE-SW01, LIV-SW01, HUL-SW01) should be created manually beforehand.

.EXAMPLE
    .\01aImportHyperVandCreateNATSwitchandConfigHostNIC_Host.ps1
#>

# Ensure script is running as Administrator
If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltinRole] "Administrator")) {
    Write-Error "This script must be run as Administrator. Exiting."
    exit 1
}

# Validate this is the Hyper-V host by checking VMMS service
$vmms = Get-Service -Name vmms -ErrorAction SilentlyContinue
If (-not $vmms -or $vmms.Status -ne 'Running') {
    Write-Error "VMMS (Hyper-V Virtual Machine Management) service not running. Please execute this script on the Hyper-V host."
    exit 1
}

# Import Hyper-V module
Write-Host "Importing Hyper-V module..."
Import-Module Hyper-V -ErrorAction Stop
Write-Host "Hyper-V module imported successfully.`n"

# Create Internal switch for NAT
$switchName = 'NATSwitch'
Write-Host "Checking for existing Internal switch '$switchName'..."
if (Get-VMSwitch -Name $switchName -ErrorAction SilentlyContinue) {
    Write-Host "INFO: VMSwitch '$switchName' already exists. Skipping creation.`n"
} else {
    Write-Host "Creating Internal switch '$switchName'..."
    try {
        New-VMSwitch -Name $switchName -SwitchType Internal -ErrorAction Stop
        Write-Host "SUCCESS: '$switchName' created.`n"
    }
    catch {
        Write-Error "ERROR: Failed to create '$switchName'. $_"
        throw
    }
}

# Configure the host's Internal NIC for NAT if not already configured
$adapterAlias = "vEthernet ($switchName)"
$desiredIP = '192.168.100.1'
$desiredPrefix = 24

# Check existing IP configuration
$existing = Get-NetIPAddress -InterfaceAlias $adapterAlias -PrefixLength $desiredPrefix -IPAddress $desiredIP -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "INFO: Host adapter '$adapterAlias' already configured with $desiredIP/$desiredPrefix. Skipping.`n"
} else {
    Write-Host "Configuring host adapter '$adapterAlias' with IP $desiredIP/$desiredPrefix..."
    try {
        # Remove any existing IPs on this adapter
        Get-NetIPAddress -InterfaceAlias $adapterAlias -ErrorAction SilentlyContinue |
            Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue

        New-NetIPAddress `
            -InterfaceAlias $adapterAlias `
            -IPAddress $desiredIP `
            -PrefixLength $desiredPrefix `
            -ErrorAction Stop

        Write-Host "SUCCESS: Host adapter configured.`n"
    }
    catch {
        Write-Error "ERROR: Failed to configure host adapter. $_"
        throw
    }
}

Write-Host "Host preparation complete. NATSwitch and host NIC are ready.`n"

<#
Manual Prerequisites (on the Hyper-V host):

- Create four Private virtual switches manually:
    MAN-SW01, LEE-SW01, LIV-SW01, HUL-SW01

Use Hyper-V Manager or:
```powershell
New-VMSwitch -Name "MAN-SW01" -SwitchType Private
New-VMSwitch -Name "LEE-SW01" -SwitchType Private
New-VMSwitch -Name "LIV-SW01" -SwitchType Private
New-VMSwitch -Name "HUL-SW01" -SwitchType Private
```
#>
