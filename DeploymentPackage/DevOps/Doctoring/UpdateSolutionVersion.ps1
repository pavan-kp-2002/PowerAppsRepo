function Set-SolutionVersionNumber {
	param ([string]$CdsSolutionFolder)
	$fileName = $CdsSolutionFolder + "\Other\Solution.xml"
	[xml] $xdoc = get-content $fileName
	$version = $xdoc.SelectSingleNode('//Version')
	$date = Get-Date([datetime]::UtcNow) -UFormat "%Y.%m%d.%H%M"
	#Format should look like 0.2021.0415.1159 for example
	$version.InnerText = "0.$date"
	$xdoc.Save($fileName)
}
