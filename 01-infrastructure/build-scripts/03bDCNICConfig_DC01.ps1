# Expected NIC names
$expectedNICs = @("NAT", "MAN", "LEE", "LIV", "HUL")

# Static IP configurations per NIC
$ipConfigs = @{
    "NAT" = @{ IP = "192.168.100.2"; Prefix = 24; Gateway = "192.168.100.1"; DNS = @("8.8.8.8", "8.8.4.4") }
    "MAN" = @{ IP = "10.90.10.1"; Prefix = 24; Gateway = $null; DNS = "10.90.10.1" }
    "LEE" = @{ IP = "10.90.20.1"; Prefix = 24; Gateway = $null; DNS = "10.90.10.1" }
    "LIV" = @{ IP = "10.90.30.1"; Prefix = 24; Gateway = $null; DNS = "10.90.10.1" }
    "HUL" = @{ IP = "10.90.40.1"; Prefix = 24; Gateway = $null; DNS = "10.90.10.1" }
}

Write-Host "Checking for expected NICs..." -ForegroundColor Cyan

# Get all NIC names that are up
$availableNICs = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -ExpandProperty Name

# Find missing NICs
$missingNICs = $expectedNICs | Where-Object { $_ -notin $availableNICs }

if ($missingNICs.Count -gt 0) {
    Write-Host "[ERROR] Missing NICs detected: $($missingNICs -join ', ')" -ForegroundColor Red
    Write-Host "Please complete step 3a: rename your NICs manually before running this." -ForegroundColor Yellow
    exit 1
}

Write-Host "All expected NICs found. Proceeding with IP configuration..." -ForegroundColor Green

# Define how to deal with DNS Checks
function ArraysEqual($a, $b) {
    if ($a.Count -ne $b.Count) { return $false }
    $diff = Compare-Object ($a | Sort-Object) ($b | Sort-Object)
    return ($diff.Count -eq 0)
}

<#
.SYNOPSIS
    Checks NIC names and configures static IPv4, DNS, and disables IPv6 on DC NICs.
.DESCRIPTION
    Validates NIC naming against expected list.
    For each NIC, configures static IP, DNS, disables IPv6 only if needed.
    Fails with a clear message if expected NIC names are missing.
.EXAMPLE
    .\03DCNICConfig.ps1
#>

# Define expected NIC names
$expectedNICs = @("MAN", "LEE", "LIV", "HUL", "NAT")

# Define IP, prefix, gateway, and DNS configs
$ipConfigs = @{
    "NAT" = @{ IP = "192.168.100.2"; Prefix = 24; Gateway = "192.168.100.1"; DNS = @("8.8.8.8", "8.8.4.4") }
    "MAN" = @{ IP = "10.90.10.1"; Prefix = 24; Gateway = $null; DNS = @("10.90.10.1") }
    "LEE" = @{ IP = "10.90.20.1"; Prefix = 24; Gateway = $null; DNS = @("10.90.10.1") }
    "LIV" = @{ IP = "10.90.30.1"; Prefix = 24; Gateway = $null; DNS = @("10.90.10.1") }
    "HUL" = @{ IP = "10.90.40.1"; Prefix = 24; Gateway = $null; DNS = @("10.90.10.1") }
}

Write-Host "Starting NIC configuration check..." -ForegroundColor Cyan

# Get current NIC names
$currentNICs = (Get-NetAdapter | Select-Object -ExpandProperty Name)

# Check that all expected NICs exist
$missingNICs = $expectedNICs | Where-Object { $currentNICs -notcontains $_ }
if ($missingNICs.Count -gt 0) {
    Write-Host "[ERROR] The following expected NIC names were not found: $($missingNICs -join ', ')" -ForegroundColor Red
    Write-Host "Please ensure you have completed NIC renaming (step 3a) before running this script." -ForegroundColor Yellow
    exit 1
}

# Process each NIC config
foreach ($nic in $expectedNICs) {
    $conf = $ipConfigs[$nic]

    # Get current IPv4 IP addresses on this NIC
    $currentIPs = Get-NetIPAddress -InterfaceAlias $nic -AddressFamily IPv4 -ErrorAction SilentlyContinue
    $hasCorrectIP = $currentIPs | Where-Object { $_.IPAddress -eq $conf.IP }

    # Get current DNS servers
    $currentDNS = (Get-DnsClientServerAddress -InterfaceAlias $nic -ErrorAction SilentlyContinue).ServerAddresses

    # Get IPv6 binding status
    $ipv6Binding = Get-NetAdapterBinding -InterfaceAlias $nic -ComponentID "ms_tcpip6" -ErrorAction SilentlyContinue
    $ipv6Enabled = $ipv6Binding.Enabled

    # Check if all settings are already correct
    $dnsMatches = $false
    if ($currentDNS -and $conf.DNS) {
        $dnsMatches = ArraysEqual $currentDNS $conf.DNS
    }

    if ($hasCorrectIP -and $dnsMatches -and ($ipv6Enabled -eq $false)) {
        Write-Host "[SKIP] $nic already configured correctly." -ForegroundColor Green
        continue
    }

    Write-Host "[CONFIG] Configuring $nic..." -ForegroundColor Cyan

    # Remove existing IPv4 IP addresses and routes
    if ($currentIPs) {
        $currentIPs | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
    }
    Get-NetRoute -InterfaceAlias $nic -ErrorAction SilentlyContinue | Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue

    # Add new static IP
    if ($conf.Gateway) {
        New-NetIPAddress -InterfaceAlias $nic -IPAddress $conf.IP -PrefixLength $conf.Prefix -DefaultGateway $conf.Gateway -ErrorAction Stop
    } else {
        New-NetIPAddress -InterfaceAlias $nic -IPAddress $conf.IP -PrefixLength $conf.Prefix -ErrorAction Stop
    }

    # Set DNS servers if different or not set
    if (-not $dnsMatches) {
        Set-DnsClientServerAddress -InterfaceAlias $nic -ServerAddresses $conf.DNS
    }

    # Disable IPv6 if enabled
    if ($ipv6Enabled) {
        Set-NetAdapterBinding -InterfaceAlias $nic -ComponentID "ms_tcpip6" -Enabled $false
    }

    Write-Host "[OK] $nic configured: IP set to $($conf.IP), DNS set, IPv6 disabled." -ForegroundColor Green
}

Write-Host "NIC configuration complete." -ForegroundColor Cyan
