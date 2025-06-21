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
$sites = @("Manchester", "Liverpool", "Hull", "Leeds")
$objects = @("Users", "Computers")
$departments = @("Scanning", "Machining", "3DPrinting", "Office")

# Create Head Office departments
$hoDepts = @("IT", "Finance", "Executive")

# Create root level OUs
New-CheckedOU -Name "All$objects[0]" -ParentDN $domain
New-CheckedOU -Name "All$objects[1]" -ParentDN $domain
New-CheckedOU -Name "Sites" -ParentDN "OU=All$objects[0],$domain"
New-CheckedOU -Name "Sites" -ParentDN "OU=All$objects[1],$domain"
New-CheckedOU -Name "HeadOffice" -ParentDN "OU=All$objects[0],$domain"
New-CheckedOU -Name "HeadOffice" -ParentDN "OU=All$objects[1],$domain"
New-CheckedOU -Name "Groups" -ParentDN $domain
New-CheckedOU -Name "ServiceAccounts" -ParentDN $domain
New-CheckedOU -Name "Admin" -ParentDN $domain

# Create OUs under Sites
foreach ($object in $objects)
{
    foreach ($site in $sites)
    {
        $siteDN = "OU=Sites,OU=All$object,$domain"
        New-CheckedOU -Name $site -ParentDN $siteDN

        foreach ($dept in $departments)
        {
            $deptDN = "OU=$site,OU=Sites,OU=All$object,$domain"
            New-CheckedOU -Name $dept -ParentDN $deptDN

        }
    }
    # Create HO OUs
    $deptDN = "OU=HeadOffice,OU=All$object,$domain"
    foreach ($dept in $hoDepts)
    {
        New-CheckedOU -Name $dept -ParentDN $deptDN
    }
}
Write-Host "OU structure build completed successfully!" -ForegroundColor Green
