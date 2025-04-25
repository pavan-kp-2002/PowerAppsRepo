$Folder = 'C:\Program Files\WindowsPowerShell\Modules\Microsoft.Xrm.Tooling.PackageDeployment.Powershell\3.3.0.940'
Install-Module Adoxio.Dynamics.DevOps -Force -AllowClobber
Install-Module Microsoft.PowerApps.Administration.PowerShell -Force -AllowClobber
Install-Module Microsoft.PowerApps.PowerShell -Force -AllowClobber
Install-Module Microsoft.Xrm.Data.PowerShell -Force -AllowClobber
Install-Module Microsoft.Xrm.DevOps.Data.PowerShell -Force -AllowClobber
Install-Module Microsoft.Xrm.Tooling.ConfigurationMigration -Force -AllowClobber
Install-Module Microsoft.Xrm.Tooling.PackageDeployment.PowerShell -Force -AllowClobber
Install-Module -Name Microsoft.Xrm.Tooling.PackageDeployment.Powershell -RequiredVersion 3.3.0.928
if(Test-Path -Path $Folder)
{
	Remove-Item $Folder -Recurse -Force
}