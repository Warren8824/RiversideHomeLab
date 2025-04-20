param (
    [string]$VMName = "DC01",
    [long]$MemoryStartupBytes = 4GB,  # long required to avoid error converting to int32
    [int]$VHDSizeGB = 80,
    [string]$VMRootPath = "D:\VirtualMachines"
)

# Prompt for ISO path
$ISOPath = Read-Host "Enter the full path to the Windows Server 2025 ISO"

# Validate ISO exists
if (-not (Test-Path $ISOPath)) {
    Write-Error "The ISO path is invalid. Exiting."
    exit
}

# Define paths
$VMPath = Join-Path $VMRootPath $VMName
$VHDPath = Join-Path $VMPath "$VMName.vhdx"

# Create VM directory if needed
if (-not (Test-Path $VMPath)) {
    New-Item -ItemType Directory -Path $VMPath | Out-Null
    Write-Host "Created VM directory: $VMPath"
}

# Check if VM exists
if (Get-VM -Name $VMName -ErrorAction SilentlyContinue) {
    Write-Host "VM '$VMName' already exists. Skipping VM creation."
} else {
    # Create VM
    New-VM -Name $VMName -Generation 2 -MemoryStartupBytes $MemoryStartupBytes -NewVHDPath $VHDPath -NewVHDSizeBytes ($VHDSizeGB * 1GB) -Path $VMPath | Out-Null
    Set-VM -Name $VMName -DynamicMemoryEnabled $false
    Write-Host "Created VM '$VMName' with static memory and dynamic VHD."
}

# Attach ISO if not already mounted
$DVD = Get-VMDvdDrive -VMName $VMName
if ($DVD.Path -ne $ISOPath) {
    Set-VMDvdDrive -VMName $VMName -Path $ISOPath
    Write-Host "Mounted ISO to VM."
} else {
    Write-Host "ISO already mounted."
}

# Add NAT adapter only
$natAdapter = Get-VMNetworkAdapter -VMName $VMName | Where-Object { $_.SwitchName -eq "NATSwitch" }
if (-not $natAdapter) {
    try {
        Add-VMNetworkAdapter -VMName $VMName -SwitchName "NATSwitch" -Name "NAT"
        Write-Host "Added network adapter for 'NATSwitch'."
    } catch {
        Write-Warning "Failed to add adapter for 'NATSwitch': $_"
    }
} else {
    Write-Host "Adapter for 'NATSwitch' already present. Skipping."
}

Write-Host "`nAll done. You can now start '$VMName' and install Windows Server."
Write-Host "Remember to configure static IP and promote it to a Domain Controller later."
