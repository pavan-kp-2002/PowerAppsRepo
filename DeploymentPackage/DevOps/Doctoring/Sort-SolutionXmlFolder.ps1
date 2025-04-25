param(
  [Parameter(Mandatory=$true)]
  [string]$Path
)

process {
  & $PSScriptRoot\Sort-XmlFiles.ps1 `
    -Path "$Path/*.xml" `
    -TargetNodeQueries @(
      "/ImportExportXml/SolutionManifest/MissingDependencies",
      "/EntityRelationships",
      "/Entity/EntityInfo/entity/attributes"
    )
}