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

$componentKeyMap = @{}
$currentKey = 0

function Convert-NodeToIdentifier
{
  param(
    [Parameter(Mandatory=$true)]
    [System.Xml.XmlLinkedNode]$node
  )

  if($node.HasAttribute("type"))
  {
    $type = $node.type
  } else {
    Write-Error "MissingDependency sub-node is missing type: $($node.OuterXML)"
    Exit 1
  }

  if($node.HasAttribute("parentSchemaName"))
  {
    $parentSchemaName = $node.parentSchemaName
    if($node.HasAttribute("schemaName")) {
      $schemaName = $node.schemaName
    } else {
      Write-Error "MissingDependency sub-node has a parentSchemaName but no schemaName: $($node.OuterXML)"
      Exit 1
    }
    $identifier = "$type - $parentSchemaName - $schemaName"
  }
  elseif($node.HasAttribute("schemaName"))
  {
    $schemaName = $node.schemaName
    $identifier = "$type - $schemaName"
  } elseif($node.HasAttribute("id")) {
    $id = $node.id
    $identifier = "$type - $id"
  } elseif($node.HasAttribute("id.connectionreferencelogicalname")) {
    $id = $node["id.connectionreferencelogicalname"]
    $identifier = "$type - $id"
  } else {
    Write-Error "MissingDependency sub-node does not have any discernible identifiers: $($node.OuterXML)"
    Exit 1
  }

  return $identifier
}

foreach($node in $componentNodes)
{
  $identifier = Convert-NodeToIdentifier $node
  if($componentKeyMap.ContainsKey($identifier))
  {
    $key = $componentKeyMap.$identifier
  } else {
    $componentKeyMap.$identifier = $currentKey
    $key = $currentKey
    $currentKey++
  }
  $node.SetAttribute("key", $key)
}

$solutionXml.Save($solutionFilePath)