#
# Windows PowerShell script for AD DS Deployment and promote to DC
#
# Deploy AD DS
Import-Module ADDSDeployment # promote to domain controller
Install-ADDSForest `         # Configure new forest
-CreateDnsDelegation:$false `
-DatabasePath "C:\WINDOWS\NTDS" `
-DomainMode "Win2025" `
-DomainName "riverside.local" `
-DomainNetbiosName "RIVERSIDE" `
-ForestMode "Win2025" `
-InstallDns:$true `
-LogPath "C:\WINDOWS\NTDS" `
-NoRebootOnCompletion:$false `
-SysvolPath "C:\WINDOWS\SYSVOL" `
-Force:$true

