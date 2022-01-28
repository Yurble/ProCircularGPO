[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-ExecutionPolicy "Unrestricted"

# Force to create a zip file for repository, and then download said repository
$ZipFile = 'c:\Windows\Temp\AutoGPO.zip'
New-Item $ZipFile -ItemType File -Force
$RepositoryZipUrl = "https://github.com/Yurble/ProCircularGPO/archive/refs/heads/main.zip" 
# Download the zip file
Write-Host 'Starting download from Gitlab repository'
Invoke-RestMethod -Uri $RepositoryZipUrl -OutFile c:\Windows\Temp\AutoGPO.zip
Write-Host 'Download finished'

#Extract Zip File
Write-Host 'Unzipping the GitLab repository locally'
Expand-Archive -Path $ZipFile -DestinationPath c:\Windows\Temp -Force
Write-Host 'Unzip finished'

#Finds domain in use and stores it as variable for later use in script
$Domain_name = Read-Host -Prompt "Enter the domain used with AD; if your domain is 'example.com', enter 'example'"
$Domain_tld = Read-Host -Prompt "Enter the top-level domain of your AD domain without a period; an example would be 'com'"

# The following is copied and modified from "configure-AuditingPolicyGPOs.ps1" from github.com/clong/DetectionLab/Vagrant
# Purpose: Installs the GPOs for the custom WinEventLog auditing policy.

$OU_name = Read-Host -Prompt "Please enter the OU for the domain controller(s) here"
Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Configuring Domain Controller auditing policy GPO..."
$GPOName = 'Domain Controllers Enhanced Auditing Policy'
$OU = "ou=" + $OU_name + "," + "dc=" + $Domain_name + "," + "dc=" + $Domain_tld
Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Importing $GPOName..."
Import-GPO -BackupGpoName $GPOName -Path "C:\Windows\Temp\ProCircularGPO-main\Domain_Controllers_Enhanced_Auditing_Policy" -TargetName $GPOName -CreateIfNeeded
$gpLinks = $null
$gPLinks = Get-ADOrganizationalUnit -Identity $OU -Properties name,distinguishedName, gPLink, gPOptions
$GPO = Get-GPO -Name $GPOName
If ($gPLinks.LinkedGroupPolicyObjects -notcontains $gpo.path)
{
    New-GPLink -Name $GPOName -Target $OU -Enforced yes
}
else
{
    Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) GpLink $GPOName already linked on $OU. Moving On."
}

#Customizes the Server OU name and corrects the path for later use
$OU_name = Read-Host -Prompt "Please enter the OU for your servers here"
$OU_actual = '"' + $OU_name + '"'
$Domain_out = "dc=" + $Domain_name + "," + "dc=" + $Domain_tld
#Creates the OU, and then installs and links the appropriate GPO
Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Configuring Server auditing policy GPO..."
$GPOName = 'Servers Enhanced Auditing Policy'
New-ADOrganizationalUnit -name $OU_name -path $Domain_out
$OU = "ou=" + $OU_name + "," + "dc=" + $Domain_name + "," + "dc=" + $Domain_tld
Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Importing $GPOName..."
Import-GPO -BackupGpoName $GPOName -Path "C:\Windows\Temp\ProCircularGPO-main\Servers_Enhanced_Auditing_Policy" -TargetName $GPOName -CreateIfNeeded
$gpLinks = $null
$gPLinks = Get-ADOrganizationalUnit -Identity $OU -Properties name,distinguishedName, gPLink, gPOptions
$GPO = Get-GPO -Name $GPOName
If ($gPLinks.LinkedGroupPolicyObjects -notcontains $gpo.path)
{
	New-GPLink -Name $GPOName -Target $OU -Enforced Yes
	Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Script complete! Removing downloaded files..."
}
else
{
    Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) GpLink $GPOName already linked on $OU. Script complete! Removing downloaded files..."
}

# Commands to automatically delete the zip file and its expanded archive
Remove-Item 'C:\Windows\Temp\ProCircularGPO-main\' -Recurse -Force
Remove-Item 'C:\Windows\Temp\AutoGPO.zip'
Write-Host "Downloaded files removed. You are now free to roam about the server."


#For future use, if necessary:

#$GPOName = 'Workstations Enhanced Auditing Policy'
#$OU = $WorkingOU,$domain "ou=Workstations,dc=interns,dc=rock"
#Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Importing $GPOName..."
#Import-GPO -BackupGpoName $GPOName -Path "C:\Windows\Temp\ProCircularGPOtest-main\Workstations_Enhanced_Auditing_Policy" -TargetName $GPOName -CreateIfNeeded
#$gpLinks = $null
#$gPLinks = Get-ADOrganizationalUnit -Identity $OU -Properties name,distinguishedName, gPLink, gPOptions
#$GPO = Get-GPO -Name $GPOName
#If ($gPLinks.LinkedGroupPolicyObjects -notcontains $gpo.path)
#{
#    New-GPLink -Name $GPOName -Target $OU -Enforced yes
#}
#else
#{
#    Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) GpLink $GPOName already linked on $OU. Moving On."
#}