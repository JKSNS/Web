<#
.SYNOPSIS
  Installs IIS (Internet Information Services) on Windows Server 2012/2016 
  and creates a basic website called "MySite".

.DESCRIPTION
  - Checks OS version (basic check).
  - Installs the IIS (Web-Server) role and its management tools.
  - Creates a folder for the new website (C:\inetpub\MySite).
  - Creates a new website in IIS using that folder as the content root.
  - Binds the new site to port 80 on all IP addresses (*).

.NOTES
  You must run this script as Administrator (elevated PowerShell).
#>

Write-Host "=== Detecting Windows version ==="
$winVer = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
Write-Host "Detected OS:" $winVer

Write-Host "`n=== Installing IIS ==="
Install-WindowsFeature -Name Web-Server -IncludeManagementTools

Write-Host "`n=== Importing WebAdministration module ==="
Import-Module WebAdministration

Write-Host "`n=== Creating a new website folder ==="
$sitePath = "C:\inetpub\MySite"
if (-Not (Test-Path $sitePath)) {
    New-Item -Path $sitePath -ItemType Directory | Out-Null
    Write-Host "Created folder: $sitePath"
} else {
    Write-Host "Folder already exists: $sitePath"
}

Write-Host "`n=== Creating a new website in IIS ==="
$siteName = "MySite"
$port = 80
$bind = "*:$port:"

# Remove the default website if desired (optional step):
# Remove-Website -Name "Default Web Site"

# Create the new site
try {
    New-WebSite -Name $siteName -PhysicalPath $sitePath -Port $port -Force | Out-Null
    Write-Host "Website '$siteName' created on port $port."
} catch {
    Write-Host "Error creating website: $($_.Exception.Message)"
}

Write-Host "`n=== Starting the new website ==="
Start-Website -Name $siteName

Write-Host "`n=== IIS installation and site creation completed successfully! ==="
Write-Host "You can now place your web content in: $sitePath"
Write-Host "Browse http://<YOUR_SERVER_IP> (or server name) to view your site."
