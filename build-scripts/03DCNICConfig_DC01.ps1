<#
.SYNOPSIS
    Renames and statically configures IP addresses for a Domain Controller's NICs.
.DESCRIPTION
    This script auto-renames NICs based on site-specific patterns and applies static
    IP settings for each interface including NAT configuration. Useful for multi-site
    homelabs or AD test environments using Hyper-V. Also disables IPv6 on all NICs.
    Sites:
    - MAN, LEE, LIV, HUL, NAT
.EXAMPLE
    .\DC_Network_Config_DC01.ps1
#>
# Mapping for NIC rename
$nicRenameMap = @{
    "MAN"        = "MAN"
    "LEE"        = "LEE"
    "LIV"        = "LIV"
    "HUL"        = "HUL"
    "NAT"        = "NAT"
}
# IP Configuration
$ipConfigs = @{
    "MAN"        = @{ IP = "10.90.10.1"; Prefix = 24; Gateway = $null; DNS = "10.90.10.1" }
    "LEE"        = @{ IP = "10.90.20.1"; Prefix = 24; Gateway = $null; DNS = "10.90.10.1" }
    "LIV"        = @{ IP = "10.90.30.1"; Prefix = 24; Gateway = $null; DNS = "10.90.10.1" }
    "HUL"        = @{ IP = "10.90.40.1"; Prefix = 24; Gateway = $null; DNS = "10.90.10.1" }
    "NAT"  = @{ IP = "192.168.100.2"; Prefix = 24; Gateway = "192.168.100.1"; DNS = @("8.8.8.8", "8.8.4.4") }
}
Write-Host "Detecting network adapters..." -ForegroundColor Cyan
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
foreach ($adapter in $adapters) {
    foreach ($key in $nicRenameMap.Keys) {
        if ($adapter.InterfaceDescription -like "*$key*" -or $adapter.Name -like "*$key*") {
            $targetName = $nicRenameMap[$key]
            if ($adapter.Name -ne $targetName) {
                Write-Host "** Renaming '$($adapter.Name)' to '$targetName'"
                Rename-NetAdapter -Name $adapter.Name -NewName $targetName -Confirm:$false
            } else {
                Write-Host "[OK] '$targetName' already correctly named" -ForegroundColor Green
            }
        }
    }
}
Start-Sleep -Seconds 5 # Let rename settle
foreach ($nic in $ipConfigs.Keys) {
    $conf = $ipConfigs[$nic]
    $existing = Get-NetIPAddress -InterfaceAlias $nic -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -eq $conf.IP }
    if ($null -eq $existing) {
        Write-Host "***  Configuring $nic with static IP $($conf.IP)"
        # Remove old config
        Get-NetIPAddress -InterfaceAlias $nic -ErrorAction SilentlyContinue | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
        Get-NetRoute -InterfaceAlias $nic -ErrorAction SilentlyContinue | Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue
        # Apply new IP
        New-NetIPAddress -InterfaceAlias $nic -IPAddress $conf.IP -PrefixLength $conf.Prefix -DefaultGateway $conf.Gateway -ErrorAction Stop
        Set-DnsClientServerAddress -InterfaceAlias $nic -ServerAddresses $conf.DNS
        # NAT route
        if ($conf.Gateway) {
            New-NetRoute -DestinationPrefix "0.0.0.0/0" -InterfaceAlias $nic -NextHop $conf.Gateway -ErrorAction SilentlyContinue
        }
        Write-Host "[OK] $nic configured." -ForegroundColor Green
    } else {
        Write-Host "[OK] $nic already has IP $($conf.IP)" -ForegroundColor Green
    }

    # Disable IPv6 for this interface
    Write-Host "     Disabling IPv6 on $nic interface" -ForegroundColor Yellow
    $interfaceIndex = (Get-NetAdapter -Name $nic).ifIndex
    Set-NetAdapterBinding -InterfaceAlias $nic -ComponentID "ms_tcpip6" -Enabled $false
    # Alternative method using registry in case the above doesn't work
    $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters\Interfaces\$((Get-NetAdapter -InterfaceAlias $nic).InterfaceGuid)"
    Set-ItemProperty -Path $registryPath -Name "DisabledComponents" -Value 0xffffffff -Type DWord -ErrorAction SilentlyContinue
    Write-Host "[OK] Disabled IPv6 on $nic" -ForegroundColor Green
}
Write-Host "Networking configuration complete." -ForegroundColor Cyan
Write-Host "IPv6 has been disabled on all configured interfaces." -ForegroundColor Cyan
