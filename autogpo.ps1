[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-ExecutionPolicy "Unrestricted"

# Force to create a zip file for repository, and then download said repository
$ZipFile = 'c:\Windows\Temp\ZipFile.zip'
New-Item $ZipFile -ItemType File -Force
$RepositoryZipUrl = "https://github.com/Yurble/ProCircularGPOtest/archive/refs/heads/main.zip" 
# Download the zip file
Write-Host 'Starting download from Gitlab repository'
Invoke-RestMethod -Uri $RepositoryZipUrl -OutFile c:\Windows\Temp\ZipFile.zip
Write-Host 'Download finished'

#Extract Zip File
#Write-Host 'Starting unzipping the GitHub Repository locally'
Expand-Archive -Path $ZipFile -DestinationPath c:\Windows\Temp -Force
Write-Host 'Unzip finished'

#Finds domain in use and stores it as variable for later use in script
$Domain_name = Read-Host -Prompt "Enter the domain of your AD [forest]; if your domain is 'domain.tld', enter what is used at 'domain'"
$Domain_tld = Read-Host -Prompt "Enter the top-level domain name of your AD domain without a period at the front;`n an example top-level domain would be 'com'"

#copied from "configure-AuditingPolicyGPOs.ps1" from github.com/clong/DetectionLab/Vagrant
# Purpose: Installs the GPOs for the custom WinEventLog auditing policy.

$OU_name = Read-Host -Prompt "Please enter the name of the Domain Controller OU here"
Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Configuring Domain Controller auditing policy GPO..."
$GPOName = 'Domain Controllers Enhanced Auditing Policy'
$OU = "ou=" + $OU_name + "," + "dc=" + $Domain_name + "," + "dc=" + $Domain_tld
Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Importing $GPOName..."
Import-GPO -BackupGpoName $GPOName -Path "C:\Windows\Temp\ProCircularGPOtest-main\Domain_Controllers_Enhanced_Auditing_Policy" -TargetName $GPOName -CreateIfNeeded
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
$OU_name = Read-Host -Prompt "Please enter the name of the Server OU here"
$OU_actual = '"' + $OU_name + '"'
$Domain_out = "dc=" + $Domain_name + "," + "dc=" + $Domain_tld
#Creates the OU, and then installs and links the appropriate GPO
Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Configuring Server auditing policy GPO..."
$GPOName = 'Servers Enhanced Auditing Policy'
New-ADOrganizationalUnit -name $OU_name -path $Domain_out
$OU = "ou=" + $OU_name + "," + "dc=" + $Domain_name + "," + "dc=" + $Domain_tld
Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Importing $GPOName..."
Import-GPO -BackupGpoName $GPOName -Path "C:\Windows\Temp\ProCircularGPOtest-main\Servers_Enhanced_Auditing_Policy" -TargetName $GPOName -CreateIfNeeded
$gpLinks = $null
$gPLinks = Get-ADOrganizationalUnit -Identity $OU -Properties name,distinguishedName, gPLink, gPOptions
$GPO = Get-GPO -Name $GPOName
If ($gPLinks.LinkedGroupPolicyObjects -notcontains $gpo.path)
{
	New-GPLink -Name $GPOName -Target $OU -Enforced Yes
	Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Script completed! Removing downloaded files..."
}
else
{
    Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) GpLink $GPOName already linked on $OU. Script completed! Removing downloaded files..."
}

# Commands to automatically delete the zip file and its expanded archive
Remove-Item 'C:\Windows\Temp\ProCircularGPOtest-main\' -Recurse -Force
Remove-Item 'C:\Windows\Temp\Zipfile.zip'
Write-Host "Downloaded files removed. You are now free to roam about the server."



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