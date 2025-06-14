# Requires: ActiveDirectory module
# Purpose: Create Three-level AD global groups (Base ➔ Site ➔ Global) for users and computers
# We will also have a roll-up Department groups to   ➔ Department
# allow Departmental targteting of software and rules
# Safe to run multiple times without duplication

Import-Module ActiveDirectory

# Base Distinguished Name for groups OU
$BaseGroupOU = 'OU=Groups,DC=riverside,DC=local'

# Site and department definitions
$Sites = @('MAN','LEE','LIV','HUL')         # Operational sites
$HoSite = 'HO'                              # Head Office code

$Departments = @('Scanning','Machining','3DPrinting','Office')
$HoDepartments = @('IT','Finance','Executive')

$UserRoles = @('Operator','Manager')        # Base roles

# Computer suffix
$CompSuffix = 'Computers'

# Functions
function Ensure-Group {
    param($Name)
    if (-not (Get-ADGroup -Filter "Name -eq '$Name'" -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $Name -GroupScope Global -GroupCategory Security -Path $BaseGroupOU -Description "Auto-created: $Name"
        Write-Host "[+] Created group: $Name" -ForegroundColor Green
    } else {
        Write-Host "[=] Exists: $Name" -ForegroundColor Yellow
    }
}

function Add-NestedGroup {
    param($Parent,$Child)
    if (-not (Get-ADGroupMember -Identity $Parent -Recursive | Where-Object Name -EQ $Child)) {
        Add-ADGroupMember -Identity $Parent -Members $Child
        Write-Host "[~] Nested $Child into $Parent" -ForegroundColor Cyan
    }
}

# 1) CREATE GLOBAL GROUPS
Ensure-Group 'G_All_Users'
Ensure-Group 'G_All_Computers'

# 2) CREATE DEPARTMENT ROLL-UPS
$AllDepts = $Departments + $HoDepartments
foreach ($dept in $AllDepts) {
    $deptUsers = "G_All_${dept}_Users"
    Ensure-Group $deptUsers
    # Computer roll-up
    $deptComps = "G_All_${dept}_${CompSuffix}"
    Ensure-Group $deptComps
}

# 3) CREATE SITE GROUPS
foreach ($site in $Sites + $HoSite) {
    $siteUsers = "G_${site}"
    $siteComps = "G_${site}_${CompSuffix}"
    Ensure-Group $siteUsers
    Ensure-Group $siteComps
}

# 4) CREATE BASE USER GROUPS AND NESTING
foreach ($site in $Sites) {
    foreach ($dept in $Departments) {
        foreach ($role in $UserRoles) {
            $base = "G_${site}_${dept}_$role"
            Ensure-Group $base
            # Nest into dept roll-up
            Add-NestedGroup "G_All_${dept}_Users" $base
            # Nest into site
            Add-NestedGroup "G_${site}" $base
            # Nest site into global
            Add-NestedGroup 'G_All_Users' "G_${site}"
        }
    }
}
# CREATE HEAD OFFICE BASE GROUPS AND NESTING
foreach ($dept in $HoDepartments) {
    foreach ($role in $UserRoles) {
        $base = "G_${HoSite}_${dept}_$role"
        Ensure-Group $base
        Add-NestedGroup "G_All_${dept}_Users" $base
        Add-NestedGroup "G_${HoSite}" $base
        Add-NestedGroup 'G_All_Users' "G_${HoSite}"
    }
}

# 5) CREATE BASE COMPUTER GROUPS AND NESTING
foreach ($site in $Sites) {
    foreach ($dept in $Departments) {
        $baseComp = "G_${site}_${dept}_${CompSuffix}"
        Ensure-Group $baseComp
        Add-NestedGroup "G_All_${dept}_${CompSuffix}" $baseComp
        Add-NestedGroup "G_${site}_${CompSuffix}" $baseComp
        Add-NestedGroup 'G_All_Computers' "G_${site}_${CompSuffix}"
    }
}
# CREATE HEAD OFFICE COMPUTERS AND NESTING
foreach ($dept in $HoDepartments) {
    $baseComp = "G_${HoSite}_${dept}_${CompSuffix}"
    Ensure-Group $baseComp
    Add-NestedGroup "G_All_${dept}_${CompSuffix}" $baseComp
    Add-NestedGroup "G_${HoSite}_${CompSuffix}" $baseComp
    Add-NestedGroup 'G_All_Computers' "G_${HoSite}_${CompSuffix}"
}

Write-Host '`n[✓] All groups created and nested successfully.' -ForegroundColor Green
