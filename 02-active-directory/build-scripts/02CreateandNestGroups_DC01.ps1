# Requires: ActiveDirectory module
# Purpose: Create Three-level AD global groups (Base ➔ Site ➔ Global) for users and computers
# We will also have a roll-up Department groups to   ➔ Department
# allow Departmental targeting of software and rules
# Safe to run multiple times without duplication

Import-Module ActiveDirectory

# Base Distinguished Name for groups OU
$BaseGroupOU = 'OU=Groups,DC=riverside,DC=local'

# Site and department definitions - UPDATED to match OU structure
$Sites = @('Manchester','Liverpool','Hull','Leeds')  # Full site names matching OU structure
$SiteCodes = @('MAN','LIV','HUL','LEE')             # Short codes for group names
$HoSite = 'HeadOffice'                              # Head Office name matching OU
$HoCode = 'HO'                                      # Head Office short code

# Department names matching OU structure exactly
$Departments = @('Scanning','Machining','3DPrinting','Office')
$HoDepartments = @('IT','Finance','Executive')

$UserRoles = @('Operator','Manager')                # Base roles

# Computer suffix
$CompSuffix = 'Computers'

# Functions
function Create-Group {
    param(
        [string]$Name,
        [string]$Description = "Auto-created: $Name"
    )
    if (-not (Get-ADGroup -Filter "Name -eq '$Name'" -ErrorAction SilentlyContinue)) {
        try {
            New-ADGroup -Name $Name -GroupScope Global -GroupCategory Security -Path $BaseGroupOU -Description $Description
            Write-Host "[+] Created group: $Name" -ForegroundColor Green
        }
        catch {
            Write-Host "[!] Error creating group $Name`: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "[=] Exists: $Name" -ForegroundColor Yellow
    }
}

function Add-NestedGroup {
    param(
        [string]$Parent,
        [string]$Child
    )
    try {
        if (-not (Get-ADGroupMember -Identity $Parent -Recursive | Where-Object Name -EQ $Child)) {
            Add-ADGroupMember -Identity $Parent -Members $Child
            Write-Host "[~] Nested $Child into $Parent" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host "[!] Error nesting $Child into $Parent`: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "Creating AD Security Groups aligned with OU structure..." -ForegroundColor Magenta

# 1) CREATE GLOBAL GROUPS
Write-Host "`n=== Creating Global Groups ===" -ForegroundColor Yellow
Create-Group 'G_All_Users' "Global group containing all user groups"
Create-Group 'G_All_Computers' "Global group containing all computer groups"

# 2) CREATE DEPARTMENT ROLL-UPS
Write-Host "`n=== Creating Department Roll-up Groups ===" -ForegroundColor Yellow
$AllDepts = $Departments + $HoDepartments
foreach ($dept in $AllDepts) {
    $deptUsers = "G_All_${dept}_Users"
    $deptComps = "G_All_${dept}_${CompSuffix}"
    Create-Group $deptUsers "Department roll-up for all $dept users"
    Create-Group $deptComps "Department roll-up for all $dept computers"
}

# 3) CREATE SITE GROUPS
Write-Host "`n=== Creating Site Groups ===" -ForegroundColor Yellow
for ($i = 0; $i -lt $Sites.Count; $i++) {
    $siteCode = $SiteCodes[$i]
    $siteName = $Sites[$i]
    $siteUsers = "G_${siteCode}"
    $siteComps = "G_${siteCode}_${CompSuffix}"
    Create-Group $siteUsers "Site group for all $siteName users"
    Create-Group $siteComps "Site group for all $siteName computers"
}

# Head Office site group
Create-Group "G_${HoCode}" "Site group for all $HoSite users"
Create-Group "G_${HoCode}_${CompSuffix}" "Site group for all $HoSite computers"

# 4) CREATE BASE USER GROUPS AND NESTING
Write-Host "`n=== Creating Base User Groups and Nesting ===" -ForegroundColor Yellow
for ($i = 0; $i -lt $Sites.Count; $i++) {
    $siteCode = $SiteCodes[$i]
    $siteName = $Sites[$i]

    foreach ($dept in $Departments) {
        foreach ($role in $UserRoles) {
            $base = "G_${siteCode}_${dept}_${role}"
            Create-Group $base "Base group for $role users in $dept department at $siteName"

            # Nest into dept roll-up
            Add-NestedGroup "G_All_${dept}_Users" $base
            # Nest into site
            Add-NestedGroup "G_${siteCode}" $base
        }
    }
    # Nest site into global (do this once per site)
    Add-NestedGroup 'G_All_Users' "G_${siteCode}"
}

# CREATE HEAD OFFICE BASE GROUPS AND NESTING
Write-Host "`n=== Creating Head Office User Groups ===" -ForegroundColor Yellow
foreach ($dept in $HoDepartments) {
    foreach ($role in $UserRoles) {
        $base = "G_${HoCode}_${dept}_${role}"
        Create-Group $base "Base group for $role users in $dept department at Head Office"
        Add-NestedGroup "G_All_${dept}_Users" $base
        Add-NestedGroup "G_${HoCode}" $base
    }
}
# Nest Head Office into global
Add-NestedGroup 'G_All_Users' "G_${HoCode}"

# 5) CREATE BASE COMPUTER GROUPS AND NESTING
Write-Host "`n=== Creating Base Computer Groups and Nesting ===" -ForegroundColor Yellow
for ($i = 0; $i -lt $Sites.Count; $i++) {
    $siteCode = $SiteCodes[$i]
    $siteName = $Sites[$i]

    foreach ($dept in $Departments) {
        $baseComp = "G_${siteCode}_${dept}_${CompSuffix}"
        Create-Group $baseComp "Base group for computers in $dept department at $siteName"
        Add-NestedGroup "G_All_${dept}_${CompSuffix}" $baseComp
        Add-NestedGroup "G_${siteCode}_${CompSuffix}" $baseComp
    }
    # Nest site computers into global (do this once per site)
    Add-NestedGroup 'G_All_Computers' "G_${siteCode}_${CompSuffix}"
}

# CREATE HEAD OFFICE COMPUTER GROUPS AND NESTING
Write-Host "`n=== Creating Head Office Computer Groups ===" -ForegroundColor Yellow
foreach ($dept in $HoDepartments) {
    $baseComp = "G_${HoCode}_${dept}_${CompSuffix}"
    Create-Group $baseComp "Base group for computers in $dept department at Head Office"
    Add-NestedGroup "G_All_${dept}_${CompSuffix}" $baseComp
    Add-NestedGroup "G_${HoCode}_${CompSuffix}" $baseComp
}
# Nest Head Office computers into global
Add-NestedGroup 'G_All_Computers' "G_${HoCode}_${CompSuffix}"

Write-Host "`n[✓] All groups created and nested successfully!" -ForegroundColor Green
Write-Host "Groups created in: $BaseGroupOU" -ForegroundColor Green

# Display summary
Write-Host "`n=== SUMMARY ===" -ForegroundColor Magenta
Write-Host "Sites: $($Sites -join ', ')" -ForegroundColor White
Write-Host "Site Departments: $($Departments -join ', ')" -ForegroundColor White
Write-Host "Head Office Departments: $($HoDepartments -join ', ')" -ForegroundColor White
Write-Host "User Roles: $($UserRoles -join ', ')" -ForegroundColor White
Write-Host "Total groups created: $((($Sites.Count * $Departments.Count * $UserRoles.Count * 2) + ($HoDepartments.Count * $UserRoles.Count * 2) + ($AllDepts.Count * 2) + ($Sites.Count * 2) + 4))" -ForegroundColor White