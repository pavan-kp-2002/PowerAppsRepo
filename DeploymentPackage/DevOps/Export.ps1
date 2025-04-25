param (
    # The connection parameters for the target organization    
    [ValidateSet("MySandbox","MyTest")] # update this list based on files in the CdsConnectionParameters folder
    [string]
    $ConnectionName = "MySandbox",

    # The settings for the actions performed during the export
    [ValidateSet("DefaultSettings")] # update this list based on files in the Settings folder
    [string]
    $ExportSettings = "DefaultSettings",

    # The available actions to perform during the export
    [ValidateSet("All","Solutions","ConfigData", "TestData" ,"Export-CrmSolutions","Expand-CrmSolutions","Export-ConfigData","Expand-ConfigData", "Export-TestData","Expand-TestData")]
    [string[]]
    $Actions = "Solutions"
)

$global:ErrorActionPreference = "Stop"

$Env:CRM_SDK_PATH = "$PSScriptRoot\Tools"
Import-Module "$env:CRM_SDK_PATH\Adoxio.Dynamics.DevOps\Adoxio.Dynamics.DevOps.psd1" -Force


$ConnectionParameters = switch ($ConnectionName) {
	"MySandbox" {& "C:\\CrmConnection\MyCdsSandboxConnection.ps1"}
	default {& "$PSScriptRoot\CdsConnectionParameters\$ConnectionName.ps1"}
}

$settings = & "$PSScriptRoot\Settings\$ExportSettings.ps1" -ConnectionParameters $ConnectionParameters

$cdsSolutionFolder = "$($PSScriptRoot | Split-Path)\CdsSolution"
. "$PSScriptRoot\Doctoring\UpdateSolutionVersion.ps1"

if($settings.ExportSolutions -and ('All' -in $Actions -or 'Solutions' -in $Actions -or 'Export-CrmSolutions' -in $Actions)) {
    $settings.ExportSolutions | Export-CrmSolutions
}

if($settings.ExtractSolutions -and ('All' -in $Actions -or 'Solutions' -in $Actions -or 'Expand-CrmSolutions' -in $Actions)) {
    $settings.ExtractSolutions | Expand-CrmSolution
    Set-SolutionVersionNumber -CdsSolutionFolder $cdsSolutionFolder
    & "$PSScriptRoot\Doctoring\Remove-KeysFromMissingDependencies.ps1" -SolutionFolderPath "$(Split-Path $PSScriptRoot)\CdsSolution"
    & "$PSScriptRoot\Doctoring\Sort-SolutionXmlFolder.ps1" -Path "$(Split-Path $PSScriptRoot)\CdsSolution\other"	
}

if($settings.ExportConfigData -and ('All' -in $Actions -or 'ConfigData' -in $Actions -or 'Export-ConfigData' -in $Actions) -and (Test-Path -Path $settings.ExportConfigData.SchemaFile)) {
    $settings.ExportConfigData | Export-CrmData
}

if($settings.ExtractConfigData -and  ('All' -in $Actions -or 'ConfigData' -in $Actions -or 'Expand-ConfigData' -in $Actions) -and (Test-Path -Path $settings.ExtractConfigData.ZipFile)) {
    $settings.ExtractConfigData | Expand-CrmData
}

if($settings.ExportTestData -and ('TestData' -in $Actions -or 'Export-TestData' -in $Actions) -and (Test-Path -Path $settings.ExportTestData.SchemaFile)) {
    $settings.ExportTestData | Export-CrmData
}

if($settings.ExtractTestData -and  ('TestData' -in $Actions -or 'Expand-TestData' -in $Actions) -and (Test-Path -Path $settings.ExtractTestData.ZipFile)) {
    $settings.ExtractTestData | Expand-CrmData
}

