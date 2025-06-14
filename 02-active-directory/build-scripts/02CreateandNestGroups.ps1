# Import the Active Directory module
Import-Module ActiveDirectory

# Define the OU where groups will be created
# You may need to modify this path to match your AD structure
$GroupsOU = "OU=Groups,DC=riverside,DC=local"

# Define department and location arrays for reuse
$locations = @("MAN", "LEE", "LIV", "HUL")
$operationalDepts = @("Scanning", "Machining", "3DPrinting")
$officeDepts = @("Office") # Renamed from "Site" to "Office"
$hoDepts = @("IT", "Finance", "Executive")
$allDepts = $operationalDepts + $officeDepts + @("IT", "Finance") # Exclude Exec group as only one member

# Function to create an AD group if it doesn't exist
function Create-ADGroupIfNotExists {
    param (
        [Parameter(Mandatory = $true)]
        [string]$GroupName,

        [Parameter(Mandatory = $false)]
        [string]$Description = "",

        [Parameter(Mandatory = $false)]
        [string]$Path = $GroupsOU,

        [Parameter(Mandatory = $false)]
        [string]$GroupScope = "Global",

        [Parameter(Mandatory = $false)]
        [string]$GroupCategory = "Security"
    )

    try {
        # Check if the group already exists
        $existingGroup = Get-ADGroup -Filter {Name -eq $GroupName} -ErrorAction SilentlyContinue

        if ($null -eq $existingGroup) {
            # Create the group if it doesn't exist
            New-ADGroup -Name $GroupName -SamAccountName $GroupName -GroupCategory $GroupCategory -GroupScope $GroupScope -DisplayName $GroupName -Path $Path -Description $Description
            Write-Host "Created group: $GroupName" -ForegroundColor Green
            return $true
        } else {
            Write-Host "Group already exists: $GroupName" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "Error creating group $GroupName : $_" -ForegroundColor Red
        return $false
    }
}

# Function to add a member to an AD group
function Add-GroupMember {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ParentGroup,

        [Parameter(Mandatory = $true)]
        [string]$ChildGroup
    )

    try {
        # Check if the child is already a member of the parent
        $isMember = Get-ADGroupMember -Identity $ParentGroup | Where-Object {$_.name -eq $ChildGroup}

        if ($null -eq $isMember) {
            # Add the child group to the parent group
            Add-ADGroupMember -Identity $ParentGroup -Members $ChildGroup
            Write-Host "Added $ChildGroup to $ParentGroup" -ForegroundColor Green
        } else {
            Write-Host "$ChildGroup is already a member of $ParentGroup" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Error adding $ChildGroup to $ParentGroup : $_" -ForegroundColor Red
    }
}

# Start a transcript log
$logPath = "$env:USERPROFILE\Documents\AD_Group_Creation_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
Start-Transcript -Path $logPath

Write-Host "Starting AD Group Structure Creation..." -ForegroundColor Cyan
Write-Host "Log file will be saved to: $logPath" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

#########################################################
# SECTION 1: Create all individual groups
#########################################################

Write-Host "`nCreating User Groups:" -ForegroundColor Magenta

# Top-level user groups
Create-ADGroupIfNotExists -GroupName "G_All_Users" -Description "All Users in the organization"
Create-ADGroupIfNotExists -GroupName "G_All_Sites_Users" -Description "All site location users - excluding HO"
Create-ADGroupIfNotExists -GroupName "G_HO_All_Users" -Description "All Head Office users"
Create-ADGroupIfNotExists -GroupName "G_All_Operators" -Description "All operators across all locations - excluding HO"
Create-ADGroupIfNotExists -GroupName "G_All_Managers" -Description "All managers across all locations - excluding HO"


# Site location groups
foreach ($loc in $locations) {
    Create-ADGroupIfNotExists -GroupName "G_${loc}_All_Users" -Description "All $loc location users"

    # Department roles per location
    foreach ($dept in $operationalDepts) {
        Create-ADGroupIfNotExists -GroupName "G_${loc}_${dept}_Operators" -Description "$loc $dept operators"
        Create-ADGroupIfNotExists -GroupName "G_${loc}_${dept}_Managers" -Description "$loc $dept managers"
    }

    # Office staff per location - Seperate function allowing expansions to office departments
    foreach ($dept in $officeDepts) {
        Create-ADGroupIfNotExists -GroupName "G_${loc}_${dept}_Operators" -Description "$loc $dept operators"
        Create-ADGroupIfNotExists -GroupName "G_${loc}_${dept}_Managers" -Description "$loc $dept managers"
    }
}

# Head Office groups
foreach ($dept in $hoDepts) {
    if ($dept -ne "Executive") {
        Create-ADGroupIfNotExists -GroupName "G_HO_${dept}_Operators" -Description "Head Office $dept operators"
        Create-ADGroupIfNotExists -GroupName "G_HO_${dept}_Managers" -Description "Head Office $dept managers"
    } else {
        Create-ADGroupIfNotExists -GroupName "G_HO_${dept}_CEO" -Description "Executive CEO group"
    }
}

# Cross-site role groups
foreach ($dept in $allDepts) {
    Create-ADGroupIfNotExists -GroupName "G_All_${dept}_Operators" -Description "All $dept operators across locations"
    Create-ADGroupIfNotExists -GroupName "G_All_${dept}_Managers" -Description "All $dept managers across locations"
    Create-ADGroupIfNotExists -GroupName "G_All_${dept}_Users" -Description "All $dept Operators and Managers across locations"
}

# Computer groups
Write-Host "`nCreating Computer Groups:" -ForegroundColor Magenta

Create-ADGroupIfNotExists -GroupName "G_All_Computers" -Description "All computers in the organization"
Create-ADGroupIfNotExists -GroupName "G_All_Site_Computers" -Description "All site location computers"
Create-ADGroupIfNotExists -GroupName "G_HO_All_Computers" -Description "All Head Office computers"

# Head Office computer groups
foreach ($dept in $hoDepts) {
    Create-ADGroupIfNotExists -GroupName "G_HO_${dept}_Computers" -Description "Head Office $dept computers"
}

# Site location computer groups
foreach ($loc in $locations) {
    Create-ADGroupIfNotExists -GroupName "G_${loc}_All_Computers" -Description "All $loc location computers"

    # Department computers per location
    foreach ($dept in $operationalDepts + $officeDepts) {
        Create-ADGroupIfNotExists -GroupName "G_${loc}_${dept}_Computers" -Description "$loc $dept computers"
    }
}

#########################################################
# SECTION 2: Create group memberships and nesting
#########################################################

Write-Host "`nSetting up Group Memberships for Users:" -ForegroundColor Magenta

# Add site groups to G_All_Sites_Users
foreach ($loc in $locations) {
    Add-GroupMember -ParentGroup "G_All_Sites_Users" -ChildGroup "G_${loc}_All_Users"
}

# Add department operator groups to location groups and cross-site operator groups
foreach ($loc in $locations) {
    foreach ($dept in $operationalDepts + $officeDepts) {
        # Add operators to location group
        Add-GroupMember -ParentGroup "G_${loc}_All_Users" -ChildGroup "G_${loc}_${dept}_Operators"
        # Add managers to location group
        Add-GroupMember -ParentGroup "G_${loc}_All_Users" -ChildGroup "G_${loc}_${dept}_Managers"

        # Add location operators to cross-site operator groups
        Add-GroupMember -ParentGroup "G_All_${dept}_Operators" -ChildGroup "G_${loc}_${dept}_Operators"
        # Add location managers to cross-site manager groups
        Add-GroupMember -ParentGroup "G_All_${dept}_Managers" -ChildGroup "G_${loc}_${dept}_Managers"
    }
}

# Add Head Office groups to G_HO_All_Users
foreach ($dept in $hoDepts) {
    if ($dept -ne "Executive") {
        Add-GroupMember -ParentGroup "G_HO_All_Users" -ChildGroup "G_HO_${dept}_Operators"
        Add-GroupMember -ParentGroup "G_HO_All_Users" -ChildGroup "G_HO_${dept}_Managers"

        # Add HO operators and managers to cross-site groups
        Add-GroupMember -ParentGroup "G_All_${dept}_Operators" -ChildGroup "G_HO_${dept}_Operators"
        Add-GroupMember -ParentGroup "G_All_${dept}_Managers" -ChildGroup "G_HO_${dept}_Managers"
    } else {
        Add-GroupMember -ParentGroup "G_HO_All_Users" -ChildGroup "G_HO_${dept}_CEO"
    }
}

# Add cross-department role groups to G_All_Operators and G_All_Managers
foreach ($dept in $allDepts) {
    Add-GroupMember -ParentGroup "G_All_Operators" -ChildGroup "G_All_${dept}_Operators"
    Add-GroupMember -ParentGroup "G_All_Managers" -ChildGroup "G_All_${dept}_Managers"

    # Add operators and managers to department user groups
    Add-GroupMember -ParentGroup "G_All_${dept}_Users" -ChildGroup "G_All_${dept}_Operators"
    Add-GroupMember -ParentGroup "G_All_${dept}_Users" -ChildGroup "G_All_${dept}_Managers"

}

# Add only top-level user groups to G_All_Users
Add-GroupMember -ParentGroup "G_All_Users" -ChildGroup "G_All_Sites_Users"
Add-GroupMember -ParentGroup "G_All_Users" -ChildGroup "G_HO_All_Users"
Add-GroupMember -ParentGroup "G_All_Users" -ChildGroup "G_All_Department_Users"

#########################################################
# SECTION 3: Set up Computer Group Memberships
#########################################################

Write-Host "`nSetting up Group Memberships for Computers:" -ForegroundColor Magenta

# Add site computer groups to G_All_Site_Computers
foreach ($loc in $locations) {
    Add-GroupMember -ParentGroup "G_All_Site_Computers" -ChildGroup "G_${loc}_All_Computers"

    # Add department computer groups to site computer groups
    foreach ($dept in $operationalDepts + $officeDepts) {
        Add-GroupMember -ParentGroup "G_${loc}_All_Computers" -ChildGroup "G_${loc}_${dept}_Computers"
    }
}

# Add Head Office computer groups to G_HO_All_Computers
foreach ($dept in $hoDepts) {
    Add-GroupMember -ParentGroup "G_HO_All_Computers" -ChildGroup "G_HO_${dept}_Computers"
}

# Add top-level computer groups to G_All_Computers
Add-GroupMember -ParentGroup "G_All_Computers" -ChildGroup "G_All_Site_Computers"
Add-GroupMember -ParentGroup "G_All_Computers" -ChildGroup "G_HO_All_Computers"

Write-Host "`nGroup structure creation completed." -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Cyan

# Stop the transcript
Stop-Transcript

Write-Host "`nScript execution complete. Log saved to $logPath" -ForegroundColor Cyan
Write-Host "Please review the log file for any errors or warnings." -ForegroundColor Cyan