########################################################################################################################
##
## This script will download Sdk Tools to the path specified by the CRM_SDK_PATH environment variable. The script assumes
## that the CRM_SDK_PATH ends with a folder named Tools (e.g. c:\my\development\root\Tools). 
## 
########################################################################################################################

$sourceNugetExe = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
$targetNugetExe = ".\nuget.exe"
Remove-Item .\Tools -Force -Recurse -ErrorAction Ignore
Invoke-WebRequest $sourceNugetExe -OutFile $targetNugetExe
Set-Alias nuget $targetNugetExe -Scope Global -Verbose

##
##Download CoreTools
##
./nuget install  Microsoft.CrmSdk.CoreTools -O .\Tools
md .\Tools\CoreTools
$coreToolsFolder = Get-ChildItem ./Tools | Where-Object {$_.Name -match 'Microsoft.CrmSdk.CoreTools.'}
move .\Tools\$coreToolsFolder\content\bin\coretools\*.* .\Tools\CoreTools
Remove-Item .\Tools\$coreToolsFolder -Force -Recurse

##
##Download Configuration Migration
##
./nuget install  Microsoft.CrmSdk.XrmTooling.ConfigurationMigration.Wpf -O .\Tools
md .\Tools\ConfigurationMigration
$configMigFolder = Get-ChildItem ./Tools | Where-Object {$_.Name -match 'Microsoft.CrmSdk.XrmTooling.ConfigurationMigration.Wpf.'}
move .\Tools\$configMigFolder\tools\*.* .\Tools\ConfigurationMigration
Remove-Item .\Tools\$configMigFolder -Force -Recurse

##
##Download Package Deployer 
##
./nuget install  Microsoft.CrmSdk.XrmTooling.PackageDeployment.WPF -O .\Tools
md .\Tools\PackageDeployment
$pdFolder = Get-ChildItem ./Tools | Where-Object {$_.Name -match 'Microsoft.CrmSdk.XrmTooling.PackageDeployment.Wpf.'}
move .\Tools\$pdFolder\tools\*.* .\Tools\PackageDeployment
Remove-Item .\Tools\$pdFolder -Force -Recurse

##
##Download Package Deployer PowerShell module
##
./nuget install Microsoft.CrmSdk.XrmTooling.PackageDeployment.PowerShell -O .\Tools
$pdPoshFolder = Get-ChildItem ./Tools | Where-Object {$_.Name -match 'Microsoft.CrmSdk.XrmTooling.PackageDeployment.PowerShell.'}
move .\Tools\$pdPoshFolder\tools\*.* .\Tools\PackageDeployment.PowerShell
Remove-Item .\Tools\$pdPoshFolder -Force -Recurse

##
##Remove NuGet.exe
##
Remove-Item nuget.exe

##
##Copy the developer sandbox connection script
##
Copy-Item "$PSScriptRoot\CdsConnectionParameters\MyCdsSandboxConnection-Template.ps1" -Destination "Tools\MyCdsSandboxConnection.ps1"