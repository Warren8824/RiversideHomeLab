<#
.SYNOPSIS
    Configures DNS forwarders and reverse lookup zones in a homelab.

.DESCRIPTION
    - Adds missing forwarders: 8.8.8.8, 1.1.1.1
    - Creates AD-integrated reverse lookup zones with secure dynamic updates
    - Idempotent: skips anything already configured
#>

$dnsServer = $env:COMPUTERNAME
$desiredForwarders = @("8.8.8.8", "1.1.1.1")

# Define /24 reverse zone networks
$reverseZones = @(
    "10.90.10.0/24",
    "10.90.20.0/24",
    "10.90.30.0/24",
    "10.90.40.0/24"
)

Write-Host "`n=== DNS Configuration Script ===`n" -ForegroundColor Cyan

# === Step 1: Check/Add Forwarders ===
$currentForwarders = (Get-DnsServerForwarder -ComputerName $dnsServer -ErrorAction SilentlyContinue).IPAddress
$missingForwarders = $desiredForwarders | Where-Object { $_ -notin $currentForwarders }

if ($missingForwarders.Count -gt 0) {
    Write-Host "[INFO] Adding missing DNS forwarders: $($missingForwarders -join ', ')" -ForegroundColor Cyan
    Add-DnsServerForwarder -IPAddress $missingForwarders -ComputerName $dnsServer
} else {
    Write-Host "[SKIP] DNS forwarders already configured." -ForegroundColor Yellow
}

# === Step 2: Create Reverse Zones ===
foreach ($cidr in $reverseZones) {
    $ipAddress = ($cidr -split '/')[0]
    $octets = $ipAddress -split '\.'
    $zoneName = "$($octets[2]).$($octets[1]).$($octets[0]).in-addr.arpa"

    $zoneExists = Get-DnsServerZone -ComputerName $dnsServer -ErrorAction SilentlyContinue |
                  Where-Object { $_.ZoneName -eq $zoneName }

    if ($zoneExists) {
        Write-Host "[SKIP] Reverse zone $zoneName already exists." -ForegroundColor Yellow
        continue
    }

    try {
        Write-Host "[INFO] Creating reverse lookup zone: $zoneName" -ForegroundColor Cyan
        Add-DnsServerPrimaryZone -ComputerName $dnsServer `
                                 -NetworkId $cidr `
                                 -ReplicationScope "Domain" `
                                 -DynamicUpdate "Secure"

        Write-Host "[OK] Reverse zone $zoneName created successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] Failed to create reverse zone ${zoneName}: $_" -ForegroundColor Red
    }
}

Write-Host "`n=== DNS Configuration Complete ===`n" -ForegroundColor Cyan
