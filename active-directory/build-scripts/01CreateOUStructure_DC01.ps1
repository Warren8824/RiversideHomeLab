# Define the base distinguished name
$domain = "DC=riverside,DC=local"

# Define a reusable function to create an OU if it doesn't exist
function New-CheckedOU {
    param (
        [string]$Name,
        [string]$ParentDN
    )

    $ouDN = "OU=$Name,$ParentDN"

    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouDN'" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $Name -Path $ParentDN -ProtectedFromAccidentalDeletion $true
        Write-Host "Created: $ouDN"
    } else {
        Write-Host "Exists:  $ouDN"
    }
}

# Sites and Departments
$sites = @("Manchester", "Liverpool", "Sheffield", "Leeds")
$departments = @("Scanning", "Machining", "3DPrinting", "Management")

# Create root level OUs
New-CheckedOU -Name "Sites" -ParentDN $domain
New-CheckedOU -Name "HeadOffice" -ParentDN $domain
New-CheckedOU -Name "Groups" -ParentDN $domain
New-CheckedOU -Name "ServiceAccounts" -ParentDN $domain
New-CheckedOU -Name "Admin" -ParentDN $domain

# Create OUs under Sites
foreach ($site in $sites) {
    $siteDN = "OU=Sites,$domain"
    New-CheckedOU -Name $site -ParentDN $siteDN

    foreach ($dept in $departments) {
        $deptDN = "OU=$site,OU=Sites,$domain"
        New-CheckedOU -Name $dept -ParentDN $deptDN

        # Users and Computers sub-OUs
        $deptBase = "OU=$dept,OU=$site,OU=Sites,$domain"
        New-CheckedOU -Name "Users" -ParentDN $deptBase
        New-CheckedOU -Name "Computers" -ParentDN $deptBase
    }
}

# Create Head Office departments
$hoDepts = @("IT", "Finance", "Executive", "Management")
$deptDN = "OU=HeadOffice,$domain"
foreach ($dept in $hoDepts) {
    New-CheckedOU -Name $dept -ParentDN $deptDN

    $base = "OU=$dept,OU=HeadOffice,$domain"
    New-CheckedOU -Name "Users" -ParentDN $base
    New-CheckedOU -Name "Computers" -ParentDN $base
}

Write-Host "OU structure build completed successfully!" -ForegroundColor Green
