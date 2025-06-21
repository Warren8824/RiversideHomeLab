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
        try {
            New-ADOrganizationalUnit -Name $Name -Path $ParentDN -ProtectedFromAccidentalDeletion $true
            Write-Host "Created: $ouDN" -ForegroundColor Green
        }
        catch {
            Write-Host "ERROR creating $ouDN : $($_.Exception.Message)" -ForegroundColor Red
            throw
        }
    } else {
        Write-Host "Exists:  $ouDN" -ForegroundColor Yellow
    }
}

# Sites and Departments
$sites = @("Manchester", "Liverpool", "Hull", "Leeds")
$objects = @("Users", "Computers")
$departments = @("Scanning", "Machining", "3DPrinting", "Office")

# Head Office departments
$hoDepts = @("IT", "Finance", "Executive")

Write-Host "Creating root level OUs..." -ForegroundColor Cyan

# Create root level OUs
foreach ($object in $objects) {
    New-CheckedOU -Name "All$object" -ParentDN $domain
}

New-CheckedOU -Name "Groups" -ParentDN $domain
New-CheckedOU -Name "ServiceAccounts" -ParentDN $domain
New-CheckedOU -Name "Admin" -ParentDN $domain

Write-Host "Creating Sites and HeadOffice containers..." -ForegroundColor Cyan

# Create Sites and HeadOffice containers under each object type
foreach ($object in $objects) {
    $objectDN = "OU=All$object,$domain"
    New-CheckedOU -Name "Sites" -ParentDN $objectDN
    New-CheckedOU -Name "HeadOffice" -ParentDN $objectDN
}

Write-Host "Creating site-specific OUs..." -ForegroundColor Cyan

# Create OUs under Sites
foreach ($object in $objects) {
    $sitesDN = "OU=Sites,OU=All$object,$domain"

    foreach ($site in $sites) {
        New-CheckedOU -Name $site -ParentDN $sitesDN

        # Create departments under each site
        $siteDN = "OU=$site,$sitesDN"
        foreach ($dept in $departments) {
            New-CheckedOU -Name $dept -ParentDN $siteDN
        }
    }
}

Write-Host "Creating Head Office OUs..." -ForegroundColor Cyan

# Create Head Office departments
foreach ($object in $objects) {
    $headOfficeDN = "OU=HeadOffice,OU=All$object,$domain"

    foreach ($dept in $hoDepts) {
        New-CheckedOU -Name $dept -ParentDN $headOfficeDN
    }
}

Write-Host "OU structure build completed successfully!" -ForegroundColor Green