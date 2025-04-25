param(
  [Parameter(Mandatory=$true)]
  [string]$Path,
  [string[]]$TargetNodeQueries
)

process {
  $files = Get-ChildItem $Path -Recurse
  foreach($file in $files) {
    & $PSScriptRoot\Sort-XmlFile.ps1 $file.FullName $TargetNodeQueries
  }
}