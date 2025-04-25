param (
    # The connection parameters for the target organization    
    [ValidateSet("Debug","Release")] 
    [string]
    $Configuration = "Release"
)

$global:ErrorActionPreference = "Stop"

Write-Host("Running post-build.ps1")
try{
    if($Configuration -eq "Release"){
        & "$PSScriptRoot\Import.ps1" -ConnectionName DummyConnection -PackageType Managed -Actions New-CrmPackage
    }
    else{
        & "$PSScriptRoot\Import.ps1" -ConnectionName DummyConnection -PackageType Unmanaged -Actions New-CrmPackage
    }
    & "$PSScriptRoot\Doctoring\Remove-KeysFromMissingDependencies.ps1" -SolutionFolderPath "$(Split-Path $PSScriptRoot)\CdsSolution"
}
catch{
	$_
    exit 1
}

