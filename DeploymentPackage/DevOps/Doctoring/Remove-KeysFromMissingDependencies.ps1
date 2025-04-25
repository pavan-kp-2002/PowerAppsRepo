param(
  [Parameter(Mandatory=$true)]
  [string]$SolutionFolderPath
)

$solutionFilePath = "$SolutionFolderPath\Other\solution.xml"
$solutionXml = New-Object xml
$solutionXml.PreserveWhitespace = $true
$solutionXml.Load($solutionFilePath)

$missingDependenciesNode = $solutionXml.SelectSingleNode("/ImportExportXml/SolutionManifest/MissingDependencies")
$componentNodes = $missingDependenciesNode.SelectNodes("descendant::*[self::Required or self::Dependent]")
foreach ($node in $componentNodes) {
  $node.Attributes.RemoveNamedItem("key") | Out-Null
}

$solutionXml.Save($solutionFilePath)

