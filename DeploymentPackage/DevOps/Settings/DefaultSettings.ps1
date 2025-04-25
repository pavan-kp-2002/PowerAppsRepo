param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [PSCustomObject]
    $ConnectionParameters,

    [ValidateSet("Managed","Unmanaged")]
    [string]
    $PackageType = "Unmanaged"	
)

$CrmConnectionParameters = $ConnectionParameters.CrmConnectionParameter

$scriptsRoot = Split-Path -Parent $PSScriptRoot
$projectRoot = Split-Path -Parent $scriptsRoot

$solutionSettings = &"$projectRoot\SolutionSettings.ps1" 
$solutionName = $solutionSettings.CdsSolutionName

$solutionExt = if($PackageType -eq "Managed") { "_managed" }
$solutionFileName = "$solutionName$solutionExt.zip"

$exportFolder = "$projectRoot\temp\export"
$importFolder = "$projectRoot\temp\packed"

$packageFolder = "$projectRoot\temp\deployment\" + $solutionSettings.PackageFolder
$packageDllFile = "$projectRoot\bin\**\" + $solutionSettings.PackageDllFile

$mappingFile = "$projectRoot\Solution.Mappings.xml"
$configDataSchemaFile = "$projectRoot\ConfigData.Schema.xml"
$testDataSchemaFile = "$projectRoot\TestData.Schema.xml"

$solutionFolder = "$projectRoot\CdsSolution"
$solutionFolderTestPath = "$solutionFolder\other\solution.xml"
[Bool]$solutionExists = Test-Path -Path $solutionFolderTestPath

$configDataFolder = "$projectRoot\ConfigData"
$configDataTestPath = "$configDataFolder\data_schema.xml"
[Bool]$configDataExists = Test-Path -Path $configDataTestPath

$testDataFolder = "$projectRoot\TestData"
$testDataTestPath = "$testDataFolder\data_schema.xml"
[Bool]$testDataExists = Test-Path -Path $testDataTestPath

$documentTemplateFolder = "$projectRoot\DocumentTemplates"
[Bool]$documentTemplatesExist = Test-Path -PathType Container -Path $documentTemplateFolder

$dependencyFolder = "$projectRoot\CdsDependencies"

# build out list of files based on the dependency file name in the solution settings which are ordered in the way the 
# dependencies need to be layered.
[string[]]$dependencySolutions = @()
For ($i=0; $i -lt $solutionSettings.CdsSolutionDependencies.Length; $i++) {
	$dependencyName = $solutionSettings.CdsSolutionDependencies[$i]	
	$dependencySolutions += Get-ChildItem -Path $dependencyFolder -File -Filter $dependencyName -Recurse | Select-Object -ExpandProperty FullName
}

# Create a list of package solutions starting with dependencies and then adding the target solution if extracted solution data exists.
[string[]]$packageSolutions = $dependencySolutions
if($solutionExists){
  $packageSolutions += "$importFolder\$solutionFileName"
}

# Data dependencies are captured directly from the CdsDependency folder path because order does not matter.
[string[]]$dependencyConfigDataFiles = Get-ChildItem -Path $dependencyFolder -File -Filter "ConfigData.zip" -Recurse | Select-Object -ExpandProperty FullName
[string[]]$dependencyTestDataFiles = Get-ChildItem -Path $dependencyFolder -File -Filter "TestData.zip" -Recurse | Select-Object -ExpandProperty FullName

# Document Templates are captured directly from the DocumentTemplates folder
if($documentTemplatesExist){
[string[]]$documentTemplateFiles = Get-ChildItem -Path $documentTemplateFolder -File | Select-Object -ExpandProperty Fullname
}

@{  
	# ExportSolutions is used by export.ps1. Defines the managed and unmanaged solution(s) to export
	# and the location to place the exported zip files.
	ExportSolutions = [PSCustomObject]@{
        CrmConnectionParameters = $CrmConnectionParameters
        Solutions = @(
            [PSCustomObject]@{
                SolutionName = $solutionName
                Managed = $false
                ZipFile = "$exportFolder\ExportedSolution.zip"
            },
            [PSCustomObject]@{
                SolutionName = $solutionName
                Managed = $true
                ZipFile = "$exportFolder\ExportedSolution_managed.zip"
            }
        )
    }

	# ExtractSolutions is used by export.ps1. Defines the location of the solution zip file
	# to expand and the location in the repository to place the metadata.
	ExtractSolutions = @(
        [PSCustomObject]@{
            ZipFile = "$exportFolder\ExportedSolution.zip"
            MappingXmlFile = "$mappingFile"
            PackageType = "Both" # Unmanaged, Managed, Both
            Folder = "$solutionFolder"
        }) 

    # ExportConfigData is used by export.ps1. Defines configuration data to export and the zip file to put it in.
    ExportConfigData = [PSCustomObject]@{
		CrmConnectionParameters = $CrmConnectionParameters
        SchemaFile ="$configDataSchemaFile"
        ZipFile = "$exportFolder\ConfigData.zip"
        }
	
	# ExtractConfigData is used by export.ps1. Defines the name of the data zip file to expand and the 
	# location in the repository to place the data.
    ExtractConfigData = [PSCustomObject]@{
        ZipFile = "$exportFolder\ConfigData.zip"
        Folder = "$configDataFolder"
    }

     # ExportTestData is used by export.ps1. Defines test data to export and the zip file to put it in.
    ExportTestData = [PSCustomObject]@{
		CrmConnectionParameters = $CrmConnectionParameters
        SchemaFile ="$testDataSchemaFile"
        ZipFile = "$exportFolder\TestData.zip"
        }
	
	# ExtractTestData is used by export.ps1. Defines the name of the data zip file to expand and the 
	# location in the repository to place the data.
    ExtractTestData = [PSCustomObject]@{
        ZipFile = "$exportFolder\TestData.zip"
        Folder = "$testDataFolder"
    }
	
	# ExtractedSolutions is used by import.ps1. Defines location of solution metadata in repository and the 
	# zip file(s) created as part of the packing process. Multiple solutions can be packed as part of the 
	# same process.
    ExtractedSolutions = @(
        [PSCustomObject]@{
            Exists = $solutionExists
            Folder = "$solutionFolder"
            MappingXmlFile = "$mappingFile"
            PackageType = $PackageType
            ZipFile = "$importFolder\$solutionFileName"
        })
	
	# ExtractedConfigData is used by import.ps1. Defines the location of unpacked configuration data in the repository, a list of zip files containing
    # dependency configuration data, and the zip file to create for data import. 
	# part of the data packing process.
    ExtractedConfigData = [PSCustomObject]@{
        Exists = $configDataExists
        Folder = "$configDataFolder"
        ZipFile = "$importFolder\ConfigData.zip"
		DependencyDataFiles = $dependencyConfigDataFiles
    }

    # ExtractedTestData is used by import.ps1. Defines the location of unpacked test data in the repository, a list of zip files containing
    # dependency test data, and the zip file to create for data import. 
	# part of the data packing process.
    ExtractedTestData = [PSCustomObject]@{
        Exists = $testDataExists
        Folder = "$testDataFolder"
        ZipFile = "$importFolder\TestData.zip"
		DependencyDataFiles = $dependencyTestDataFiles
    }

    # DocumentTemplates is used by import.ps1. Defines the location of any document  templates that should be
    # imported.
    DocumentTemplates = [PSCustomObject]@{
        CrmConnectionParameters = $CrmConnectionParameters
        Exists = $documentTemplatesExist
        Folder = $documentTemplateFolder
        Files = $documentTemplateFiles
    }

	# CrmPackageDefinition is used by import.ps1. Defines the solutions and data that will be included 
	# in the solution.	
	CrmPackageDefinition = @(
        [PSCustomObject]@{   
			DataZipFile = "$importFolder\PackageConfigData.zip"		
            SolutionZipFiles = $packageSolutions
			PackageFolder = $packageFolder
			PackageDllFile = $packageDllFile
        }) 
	

    ResetEnvironmentDefinition = [PSCustomObject]@{
        Username = $ConnectionParameters.PowerAppsConnectionParamter.Username
        SecurePassword = [SecureString]$ConnectionParameters.PowerAppsConnectionParamter.SecurePassword
        EnvironmentName =$CrmConnectionParameters.OrganizationName
    }

	# CrmPackageDeploymentDefinition is used by import.ps1. Provides instructions to the package deployer utility to select and import 
    # a package.
    CrmPackageDeploymentDefinition = [PSCustomObject]@{
        CrmConnectionParameters = $CrmConnectionParameters
		PackageFolder = $packageFolder
		PackageName = $solutionSettings.PackageDllFile
    }
}