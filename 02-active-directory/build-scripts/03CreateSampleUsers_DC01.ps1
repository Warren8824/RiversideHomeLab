# Path to your CSV file with user data
$csvPath = "path\to\file\sample_AD_users.csv"

# Import the Active Directory module if not loaded
Import-Module ActiveDirectory

# Import user data from CSV
$users = Import-Csv -Path $csvPath

# Promt for default password to create all users with
$defaultPassword = Read-Host -AsSecureString "Enter password for all users temporary password"

foreach ($user in $users) {
    # Prepare variables
    $firstName = $user.'First Name'
    $lastName = $user.'Last Name'
    $username = $user.Username
    $ouLocation = $user.'OU Location'

    # Prepare other attributes
    $department = $user.Department
    $jobRole    = $user.'Job Role'
    $site       = $user.Site
    # Title = Department + space + JobRole
    $title      = "$department $jobRole"

    # Extract the last group from the Group Memberships (semicolon separated)
    $groups = $user.'Group Memberships' -split ';' | ForEach-Object { $_.Trim() }
    $specificGroup = $groups[-1]  # last group in the list

    # Check if user already exists to avoid duplication
    $existingUser = Get-ADUser -Filter { SamAccountName -eq $username } -ErrorAction SilentlyContinue

    if ($existingUser) {
        Write-Host "User $username already exists. Skipping creation."
    } else {
        # Create new user with required attributes
        try {
            New-ADUser `
                -GivenName $firstName `
                -Surname $lastName `
                -Name "$firstName $lastName" `
                -SamAccountName $username `
                -UserPrincipalName "$username@riverside.local" `
                -Path $ouLocation `
                -Title $title `
                -Description $title `
                -Department $department `
                -Office $site `
                -AccountPassword $defaultPassword `
                -Enabled $true `
                -ChangePasswordAtLogon $true `

            Write-Host "Created user $username in $ouLocation"
        }
        catch {
            Write-Warning "Failed to create user $username. Error: $_"
            continue
        }
    }

    # Add user to the most specific group only
    try {
        Add-ADGroupMember -Identity $specificGroup -Members $username -ErrorAction Stop
        Write-Host "Added $username to group $specificGroup"
    }
    catch {
        Write-Warning "Failed to add $username to group $specificGroup. Error: $_"
    }
}
