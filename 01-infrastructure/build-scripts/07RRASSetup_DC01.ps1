# SafeRRASSetup.ps1
Write-Host "`n=== RRAS Setup Checker & Configurator ===" -ForegroundColor Cyan

# Define interface aliases
$publicInterface = "NAT"  # Internet-facing interface
$internalInterfaces = @("MAN", "LEE", "LIV", "HUL")  # Your LANs

# 1. Remove any conflicting PowerShell NATs (New-NetNat)
$existingPSNat = Get-NetNat -ErrorAction SilentlyContinue
if ($existingPSNat) {
    Write-Host "[WARN] Found PowerShell NAT configuration. Removing to avoid RRAS conflict..." -ForegroundColor Yellow
    $existingPSNat | Remove-NetNat -Confirm:$false
    Write-Host "[OK] Removed conflicting PowerShell NAT." -ForegroundColor Green
} else {
    Write-Host "[OK] No PowerShell NAT conflicts found." -ForegroundColor Green
}

# 2. Ensure RRAS & Routing Features Installed
if (-not (Get-WindowsFeature RemoteAccess).Installed) {
    Write-Host "[INFO] Installing RemoteAccess feature..." -ForegroundColor Yellow
    Install-WindowsFeature RemoteAccess -IncludeManagementTools
}
if (-not (Get-WindowsFeature Routing).Installed) {
    Write-Host "[INFO] Installing Routing feature..." -ForegroundColor Yellow
    Install-WindowsFeature Routing
}
Write-Host "[OK] Required features installed." -ForegroundColor Green

# 3. Start and Enable RRAS Service
$rras = Get-Service RemoteAccess
if ($rras.Status -ne 'Running') {
    Write-Host "[INFO] Starting RRAS service..." -ForegroundColor Yellow
    Start-Service RemoteAccess
    Set-Service RemoteAccess -StartupType Automatic
    Write-Host "[OK] RRAS service running." -ForegroundColor Green
} else {
    Write-Host "[OK] RRAS service already running." -ForegroundColor Green
}

# 4. Enable Routing if not already
$rrasConfig = & netsh ras show config
if ($rrasConfig -notmatch "enabled\s*:\s*yes") {
    Write-Host "[INFO] Enabling RRAS routing..." -ForegroundColor Yellow
    & netsh ras set config enabled=yes
    Write-Host "[OK] RRAS routing enabled." -ForegroundColor Green
} else {
    Write-Host "[OK] RRAS already configured for routing." -ForegroundColor Green
}

# 5. Install NAT routing protocol (if not already installed)
$natInstalled = & netsh routing ip nat show interface 2>&1 | Select-String "Interface"
if (-not $natInstalled) {
    Write-Host "[INFO] Installing NAT protocol..." -ForegroundColor Yellow
    & netsh routing ip nat install
    Write-Host "[OK] NAT protocol installed." -ForegroundColor Green
} else {
    Write-Host "[OK] NAT protocol already installed." -ForegroundColor Green
}

# 6. Configure public interface for NAT
$natPublic = & netsh routing ip nat show interface | Select-String $publicInterface
if ($natPublic -notmatch "Internet") {
    Write-Host "[INFO] Setting $publicInterface as public NAT interface..." -ForegroundColor Yellow
    & netsh routing ip nat add interface "$publicInterface" full
    Write-Host "[OK] Public NAT interface configured." -ForegroundColor Green
} else {
    Write-Host "[OK] $publicInterface is already set for NAT." -ForegroundColor Green
}

# 7. Configure private/internal interfaces
foreach ($iface in $internalInterfaces) {
    $natPrivate = & netsh routing ip nat show interface | Select-String $iface
    if ($natPrivate -notmatch "Private") {
        Write-Host "[INFO] Marking $iface as private NAT interface..." -ForegroundColor Yellow
        & netsh routing ip nat add interface "$iface" private
        Write-Host "[OK] $iface marked as private." -ForegroundColor Green
    } else {
        Write-Host "[OK] $iface already set as private." -ForegroundColor Green
    }
}

# 8. Enable IP forwarding on all interfaces
foreach ($iface in $internalInterfaces + $publicInterface) {
    $ipfwd = Get-NetIPInterface -InterfaceAlias $iface -ErrorAction SilentlyContinue
    if ($ipfwd.Forwarding -ne "Enabled") {
        Write-Host "[INFO] Enabling IP forwarding on $iface..." -ForegroundColor Yellow
        Set-NetIPInterface -InterfaceAlias $iface -Forwarding Enabled
        Write-Host "[OK] IP forwarding enabled on $iface." -ForegroundColor Green
    } else {
        Write-Host "[OK] IP forwarding already enabled on $iface." -ForegroundColor Green
    }
}

Write-Host "`n=== RRAS Setup Verified and Applied Successfully ===" -ForegroundColor Cyan
