param (
    # The connection parameters for the target organization    
    [ValidateSet("MySandbox","MyTest","DummyConnection")] # update this list based on files in the CdsConnectionParameters folder
    [string]
    $ConnectionName = "MySandbox",

    # The settings for the actions performed during the export
    [ValidateSet("DefaultSettings")] # update this list based on files in the Settings folder
    [string]
    $ImportSettings = "DefaultSettings",

    [ValidateSet("Managed","Unmanaged")]
    [string]
    $PackageType = "Unmanaged",   

    # The available actions to perform during the import
    [ValidateSet("All","Solutions","ConfigData","TestData","Compress-CrmSolution","Compress-ConfigData","Merge-ConfigData","Compress-TestData","Merge-TestData","New-CrmPackage","Invoke-ImportCrmPackage","Import-DocumentTemplates")]
    [string[]]
    $Actions = "All",
	
	[switch]
	$ResetEnvironment
)

$global:ErrorActionPreference = "Stop"

Write-Host("Running Import.ps1")

# Setup CRM_SDK_PATH variable and load required supporting modules
$Env:CRM_SDK_PATH = "$PSScriptRoot\Tools"
Import-Module "$env:CRM_SDK_PATH\Adoxio.Dynamics.DevOps\Adoxio.Dynamics.DevOps.psd1" -Force
Import-Module "$env:CRM_SDK_PATH\CCLLC.Cds.DevOps\CCLLC.Cds.DevOps.PowerShell.psd1" -Force

$ConnectionParameters = switch ($ConnectionName) {
	"MySandbox" {& "C:\\CrmConnection\MyCdsSandboxConnection.ps1"}
    "MyTest" {& "$env:CRM_SDK_PATH\MyCdsTestConnection.ps1"}
	default {& "$PSScriptRoot\CdsConnectionParameters\$ConnectionName.ps1"}
}

$settings = & "$PSScriptRoot\Settings\$ImportSettings.ps1" -ConnectionParameters $ConnectionParameters -PackageType $PackageType

$dataPackage = $null


# If directed, configured, and solution data exists then  compress the solution into a zip file.
if($settings.ExtractedSolutions `
    -and $settings.ExtractedSolutions.Exists `
    -and ("All" -in $Actions -or "New-CrmPackage" -in $Actions -or 'Solutions' -in $Actions -or 'Compress-CrmSolution' -in $Actions )) {
    Write-Host("Compressing Solution")
    & "$PSScriptRoot\Doctoring\Add-KeysToMissingDependencies.ps1" -SolutionFolderPath "$(Split-Path $PSScriptRoot)\CdsSolution"
    pac solution pack -f $settings.ExtractedSolutions.Folder -z $settings.ExtractedSolutions.ZipFile -m $settings.ExtractedSolutions.MappingXmlFile -p $settings.ExtractedSolutions.PackageType -e Verbose
}


# If directed, configured, and schema file exists then compress configuration data into a zip file
if($settings.ExtractedConfigData `
    -and $settings.ExtractedConfigData.Exists `
    -and ("All" -in $Actions -or "New-CrmPackage" -in $Actions -or "ConfigData" -in $Actions -or 'Compress-ConfigData' -in $Actions)) {
		Write-Host("Compressing configuration data")
        $settings.ExtractedConfigData | Compress-CrmData -Verbose	
        
        Write-Host("Adding compressed configuration data to package data.")
        $dataPackage = Import-CrmDataPackage -ZipPath $settings.ExtractedConfigData.ZipFile
}
	

# If directed and configured, merge dependency configuration data into the package data
if($settings.ExtractedConfigData `
    -and ("All" -in $Actions  -or "New-CrmPackage" -in $Actions -or "ConfigData" -in $Actions -or "Merge-ConfigData"-in $Actions ) `
    -and $settings.ExtractedConfigData.DependencyDataFiles `
    -and $settings.ExtractedConfigData.DependencyDataFiles.Count -ge 1 ) {
        
		# When data package build has already started merge in all dependency configuration data files
		if($dataPackage){
		
			Write-Host("Merging dependency configuration data into package data.")  
			         
			$settings.ExtractedConfigData.DependencyDataFiles | ForEach-Object -Process { 
				Write-Verbose("Merging $_")
				$additionalPackage = Import-CrmDataPackage -ZipPath $_
				$dataPackage = Merge-CrmDataPackage -SourcePackage $dataPackage -AdditionalPackage $additionalPackage
				}        
		}

		# When data package is being started by dependency configuration data
		Else {
		
            Write-Host("Creating package data from first dependency configuration data set.")
            $dataPackage = Import-CrmDataPackage -ZipPath $settings.ExtractedConfigData.DependencyDataFiles[0]

			# Two or more dependency data files -> Merge file 2 and above into the data package
			if($settings.ExtractedConfigData.DependencyDataFiles.Count -ge 2){

				Write-Host("Merging remaining dependency configuration data sets into package data")
        
				$mergeTarget = $settings.ExtractedConfigData.DependencyDataFiles[0]
				$additionalFiles = $settings.ExtractedConfigData.DependencyDataFiles -ne $mergeTarget
  
				$additionalFiles | ForEach-Object -Process { 				
				    $additionalPackage = Import-CrmDataPackage -ZipPath $_
				    $dataPackage = Merge-CrmDataPackage -SourcePackage $dataPackage -AdditionalPackage $additionalPackage
				}  
			}			
		}
}


# If directed, configured, and schema file exists then compress test data into a zip file 
if($settings.ExtractedTestData `
    -and $settings.ExtractedTestData.Exists `
	-and ("All" -in $Actions  -or "New-CrmPackage" -in $Actions -or "TestData" -in $Actions -or 'Merge-TestData' -in $Actions -or 'Compress-TestData' -in $Actions)) {
		Write-Host("Compressing Test Data")
		$settings.ExtractedTestData | Compress-CrmData
}

# If directed and configured, merge dependency test data into the package data zip file
if($settings.ExtractedTestData `
    -and ("All" -in $Actions -or "TestData" -in $Actions -or "Merge-TestData"-in $Actions )) {

		if($settings.ExtractedTestData.ZipFile -and (Test-Path -Path $settings.ExtractedTestData.ZipFile)){

            if($dataPackage){                
                Write-Host("Merging compressed data into the package data")
                $additionalPackage = Import-CrmDataPackage -ZipPath $settings.ExtractedTestData.ZipFile
				$dataPackage = Merge-CrmDataPackage -SourcePackage $dataPackage -AdditionalPackage $additionalPackage
            } Else {
                Write-Host("Creating package data from compressed test data.")
                $dataPackage = Import-CrmDataPackage -ZipPath $settings.ExtractedTestData.ZipFile
            }
		}

        if($settings.ExtractedTestData.DependencyDataFiles -and $settings.ExtractedTestData.DependencyDataFiles.Count -ge 1 ){
            
            if($dataPackage){
                Write-Host("Merging dependency test data into package data")
                $settings.ExtractedTestData.DependencyDataFiles | ForEach-Object -Process { 
				    $additionalPackage = Import-CrmDataPackage -ZipPath $_
				    $dataPackage = Merge-CrmDataPackage -SourcePackage $dataPackage -AdditionalPackage $additionalPackage
				}
            } Else {

                Write-Host("Creating package data from first dependency test data set.")
                $dataPackage = Import-CrmDataPackage -ZipPath $settings.ExtractedTestData.DependencyDataFiles[0]

			    # Two or more dependency data files -> Merge file 2 and above into the data package
			    if($settings.ExtractedTestData.DependencyDataFiles.Count -ge 2){

				    Write-Host("Merging remaining dependency data sets into package data")
        
				    $mergeTarget = $settings.ExtractedTestData.DependencyDataFiles[0]
				    $additionalFiles = $settings.ExtractedTestData.DependencyDataFiles -ne $mergeTarget
    
				    $additionalFiles | ForEach-Object -Process { 				
				        $additionalPackage = Import-CrmDataPackage -ZipPath $_
				        $dataPackage = Merge-CrmDataPackage -SourcePackage $dataPackage -AdditionalPackage $additionalPackage
				    }  
			    }
            }
        }

}


if($dataPackage) {
    Write-Host("Writing package data to zip file $settings.CrmPackageDefinition.DataZipFile")
    $folder = Split-Path -Path $settings.CrmPackageDefinition.DataZipFile
    if(-Not (Test-Path -Path $folder)){
        md -Path $folder
    }
    Export-CrmDataPackage -Package $dataPackage -ZipPath $settings.CrmPackageDefinition.DataZipFile
}
		

# remove data file from definition if doing only solutions
if($settings.CrmPackageDefinition -and  'Solutions' -in $Actions) {
	For ($i=0; $i -lt $settings.CrmPackageDefinition.Length; $i++) {
		$settings.CrmPackageDefinition[$i].PSObject.Properties.Remove("DataZipFile")
    }
}


if($settings.CrmPackageDefinition -and ("All" -in $Actions -or 'New-CrmPackage' -in $Actions -or 'Solutions' -in $Actions -or 'ConfigData' -in $Actions -or 'TestData' -in $Actions)) {
    
    # remove the data configuration if the zip file does not exist.
    if($settings.CrmPackageDefinition.DataZipFile -and -not (Test-Path -Path  $settings.CrmPackageDefinition.DataZipFile)){ 
		Write-Host("No Package Configuration Data: Cleaning up package definition to remove data file definition")
		For ($i=0; $i -lt $settings.CrmPackageDefinition.Length; $i++) {
			$settings.CrmPackageDefinition[$i].PSObject.Properties.Remove("DataZipFile")
		}		
	}

	Write-Host("Creating Deployment Package")
	$settings.CrmPackageDefinition | New-CrmPackage
}

if($settings.ResetEnvironmentDefinition -and ("All" -in $Actions -or 'Invoke-ImportCrmPackage' -in $Actions -or 'Solutions' -in $Actions -or 'ConfigData' -in $Actions -or 'TestData' -in $Actions) -and $ResetEnvironment) {
    
    	
	Add-PowerAppsAccount -Username $settings.ResetEnvironmentDefinition.Username -Password $settings.ResetEnvironmentDefinition.SecurePassword

    $searchTerm = "*(" + $settings.ResetEnvironmentDefinition.EnvironmentName + ")*"    
    $environment = Get-AdminPowerAppEnvironment -Filter $searchTerm | Select-Object -First 1   
    
    if(-not $environment){
        Write-Error("Failed to find Environment")
        Break
    }   

    $title = 'Confirm Environment Reset'
    $prompt = "Select Reset to reset '" + $environment.DisplayName + "'. Select Cancel to abort operation."
    $cancel = New-Object System.Management.Automation.Host.ChoiceDescription '&Cancel','Aborts the operation'
    $reset = New-Object System.Management.Automation.Host.ChoiceDescription '&Reset','Resets the environment'
    $options = [System.Management.Automation.Host.ChoiceDescription[]] ($cancel,$reset)
 
    $choice = $host.ui.PromptForChoice($title,$prompt,$options,0)

    if($choice -ne 1){
        break
    }
    Write-Host("Reseting " + $environment.DisplayName)           

    $domainName = $environment.DisplayName.Substring($environment.DisplayName.IndexOf("(")+1).Trim(")")
    $friendlyName = $environment.DisplayName.Substring(0, $environment.DisplayName.IndexOf("(")).Trim()
       
    $resetRequest = [pscustomobject]@{
        FriendlyName = $friendlyName
        DomainName = $domainName
        Purpose = "Developer sandbox"
        BaseLanguageCode = 1033
        Currency = [pscustomobject]@{
            Code = "USD"
            Name = "USD"
            Symbol = "$"
        }        
        
    }

    ## Calling Reset-PowerAppEnvironment synchronously is buggy so this is a hack that executes the request asynchronously and then monitors the
    ## LastModifiedTime to indicate when the reset is completed. This works based on the behavior that the LastModifiedTime is set when the 
    ## reset request is processed and again when it is complete.
    $resetEnvironmentResult = Reset-PowerAppEnvironment -EnvironmentName $environment.EnvironmentName -ResetRequestDefinition $resetRequest -WaitUntilFinished $false 
    
    if ($resetEnvironmentResult.Code -eq 202 -and $resetEnvironmentResult.Description -eq "Accepted") {
        Write-Output "Reset request submitted. Sleeping until reset complete..."
    } elseif ($resetEnvironmentResult.Errors) {
        Write-Warning "Reset Error: $($resetEnvironmentResult.Error)"
        Return
    }
    
    $resetEnvironmentModifiedTime = Get-AdminPowerAppEnvironment -Filter $searchTerm | Select-Object -First 1 | select -Property LastModifiedTime
    
    do {
        Start-Sleep -Seconds 30
        Write-Verbose "Checking modified time for environment update..."
        $testValue = Get-AdminPowerAppEnvironment -Filter $searchTerm | Select-Object -First 1 | select -Property LastModifiedTime        
    } While ($testValue.LastModifiedTime -eq $resetEnvironmentModifiedTime.LastModifiedTime)

    Write-Host "Environment updated. Waiting to until Organization connection can be acquired..."

    do {
        Start-Sleep -Seconds 15
        $localCredential = New-Object System.Management.Automation.PSCredential ($settings.ResetEnvironmentDefinition.Username, $settings.ResetEnvironmentDefinition.SecurePassword) 
        $activeOrganizations = Get-CrmOrganizations -DeploymentRegion NorthAmerica -OnLineType Office365 -Credential $localCredential 
        $targetOrganizations = $activeOrganizations | Where-Object {$_.UrlHostName -eq $domainName}        
   } While ($targetOrganizations.Length -ne 1)

    Write-Host "Reset completed."
}

if($settings.CrmPackageDeploymentDefinition -and ("All" -in $Actions -or 'Invoke-ImportCrmPackage' -in $Actions -or 'Solutions' -in $Actions -or 'ConfigData' -in $Actions -or 'TestData' -in $Actions)) {
    Write-Host("Deploying Package")
	$settings.CrmPackageDeploymentDefinition | Invoke-ImportCrmPackage
}

if($settings.DocumentTemplates `
    -and $settings.DocumentTemplates.Exists `
    -and $settings.DocumentTemplates.Files.Count -ge 1 `
    -and ("All" -in $Actions -or "Import-DocumentTemplates" -in $Actions)){
        [HashTable]$crmConnectionParameters = $settings.DocumentTemplates.CrmConnectionParameters
        [string]$path = $settings.DocumentTemplates.Folder

        Write-Host("Importing Document Templates from $path")        
        
        $crmConnection = Get-CrmConnection @crmConnectionParameters
        Import-DocumentTemplates -Conn @crmConnection -TemplateDirectory $path
}


