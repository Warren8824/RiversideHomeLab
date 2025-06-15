# Import ActiveDirectory module for AD cmdlets
Import-Module ActiveDirectory

# Prompt for the default password (as SecureString, hidden input)
$defaultPassword = Read-Host -AsSecureString "Enter default password for new accounts"

# Path to the input CSV file
$csvPath = "sample_AD_users.csv"
if (!(Test-Path $csvPath)) {
    Write-Error "CSV file not found at $csvPath"
    exit
}

# Import the CSV; expected headers:
# Full Name, Username, Job Role, Site, Department, OU Location, Group Memberships
$users = Import-Csv -Path $csvPath

foreach ($user in $users) {
    $username = $user.Username

    # Skip if user already exists
    if (Get-ADUser -Filter "SamAccountName -eq '$username'" -ErrorAction SilentlyContinue) {
        Write-Host "User '$username' exists – skipping." -ForegroundColor Yellow
        continue
    }

    # Split full name into first and last (assumes exactly two parts)
    $nameParts = $user.'Full Name'.Trim() -split '\s+', 2
    $givenName = $nameParts[0]
    $surname   = if ($nameParts.Count -gt 1) { $nameParts[1] } else { "" }

    # Prepare other attributes
    $department = $user.Department
    $jobRole    = $user.'Job Role'
    $site       = $user.Site
    $ouPath     = $user.'OU Location'
    # Title = Department + space + JobRole
    $title      = "$department $jobRole"

    # Create the AD user
    New-ADUser `
        -Name           "$givenName $surname" `
        -SamAccountName $username `
        -GivenName      $givenName `
        -Surname        $surname `
        -Path           $ouPath `
        -Title          $title `
        -Department     $department `
        -Office         $site `
        -AccountPassword $defaultPassword `
        -Enabled        $true `
        -ChangePasswordAtLogon $true `
        -AccountExpirationDate (Get-Date).AddDays(14)

    Write-Host "Created '$username' with title '$title' in OU '$ouPath'." -ForegroundColor Green

    # Add to the most-specific group (last in semicolon list)
    if ($user.'Group Memberships') {
        $groups    = $user.'Group Memberships' -split ';'
        $lastGroup = $groups[-1].Trim()
        if ($lastGroup) {
            Add-ADGroupMember -Identity $lastGroup -Members $username
            Write-Host " -> Added to group '$lastGroup'." -ForegroundColor Green
        }
    }
}
