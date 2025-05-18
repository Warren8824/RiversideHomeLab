<#
.SYNOPSIS
    Creates and configures DHCP scopes for all site subnets in the homelab.

.DESCRIPTION
    This script automates the DHCP scope creation process for multiple sites
    in a simulated multi-site Active Directory environment. Each scope includes:
    - A /24 subnet
    - Defined IP range (x.x.x.20-x.x.x.250)
    - Gateway (Router) IP
    - DNS server configuration
    - 1-day lease duration

    The script checks if each scope already exists and skips it if so.
    Safe to re-run multiple times.

.EXAMPLE
    .\05CreateDHCPScopes_DC01.ps1
#>

# Set the DHCP server name (use localhost)
$serverName = $env:COMPUTERNAME

# DNS Server IP (shared for all sites)
$dnsServer = "10.90.10.1"

# DNS Domain name
$dnsDomain = "riverside.local"

# Lease duration (1 day)
$leaseDuration = [TimeSpan]::FromDays(1)

# Site-specific DHCP scope settings
$dhcpScopes = @{
    "Manchester" = @{ Subnet = "10.90.10.0"; Gateway = "10.90.10.1" }
    "Leeds" = @{ Subnet = "10.90.20.0"; Gateway = "10.90.20.1" }
    "Liverpool" = @{ Subnet = "10.90.30.0"; Gateway = "10.90.30.1" }
    "Hull" = @{ Subnet = "10.90.40.0"; Gateway = "10.90.40.1" }
}

# Begin script execution
Write-Host "`n=== DHCP Scope Configuration Script ===`n" -ForegroundColor Cyan

foreach ($site in $dhcpScopes.Keys) {
    $config = $dhcpScopes[$site]

    $subnet     = $config.Subnet
    $gateway    = $config.Gateway
    $scopeName  = "$site Scope"
    $scopeID    = $subnet
    $startRange = $subnet -replace "\.0$", ".20"
    $endRange   = $subnet -replace "\.0$", ".250"
    $mask       = "255.255.255.0"

    # Check if the scope already exists
    $existing = Get-DhcpServerv4Scope -ComputerName $serverName -ErrorAction SilentlyContinue |
                Where-Object { $_.ScopeId -eq $scopeID }

    if ($existing) {
        Write-Host "[SKIP] Scope '$scopeName' ($scopeID) already exists." -ForegroundColor Yellow
        continue
    }

    Write-Host "[INFO] Creating DHCP Scope: $scopeName ($subnet)" -ForegroundColor Cyan

    try {
        # Create new DHCP scope
        Add-DhcpServerv4Scope -ComputerName $serverName `
                              -Name $scopeName `
                              -StartRange $startRange `
                              -EndRange $endRange `
                              -SubnetMask $mask `
                              -LeaseDuration $leaseDuration `
                              -State Active

        # Set Router (Gateway)
        Set-DhcpServerv4OptionValue -ComputerName $serverName `
                                    -ScopeId $scopeID `
                                    -Router $gateway

        # Set DNS Server & Domain Name
        Set-DhcpServerv4OptionValue -ComputerName $serverName `
                                    -ScopeId $scopeID `
                                    -DnsServer $dnsServer `
                                    -DnsDomain $dnsDomain

        Write-Host "[OK] Scope for $site configured successfully.`n" -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] Failed to create scope for ${site}: $_" -ForegroundColor Red
    }
    # Enable Dynamic DNS updates for all clients
    Set-DhcpServerv4DnsSetting -ComputerName $serverName `
                               -ScopeId $scopeID `
                               -DynamicUpdates "Always" `
                               -DeleteDnsRRonLeaseExpiry $true

}

Write-Host "`n=== DHCP Scope Setup Complete ===`n" -ForegroundColor Cyan