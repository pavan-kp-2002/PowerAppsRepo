param(
  [Parameter(Mandatory=$true)]
  [string]$Path,
  [string[]]$TargetNodeQueries
)

process {
  [xml] $document = Get-Content $Path

  $targetNodes = [System.Collections.Generic.HashSet[System.Xml.XmlLinkedNode]]::new()
  if($TargetNodeQueries -ne $null) {
    foreach($query in $TargetNodeQueries) {
      $resultNodes = Select-Xml -Xml $document -XPath $query
      foreach($node in $resultNodes) {
        if(-not $targetNodes.Contains($node.Node)) {
          [void]$targetNodes.Add($node.Node)
        }
      }
    }
  }
  
  if(-not ([System.Management.Automation.PSTypeName]"XmlHelpers").Type) {
    Add-Type -TypeDefinition "
    using System.Collections.Generic;
    using System.Xml;
    public class XmlHelpers {
      public static XmlAttributeCollection GetAttributes(XmlLinkedNode node) {
        return node.Attributes;
      }

      public static IEnumerable<XmlNode> GetChildNodesClone(XmlLinkedNode node) {
        var list = new List<XmlNode>();
        foreach(var child in node.ChildNodes) {
          list.Add((XmlNode)child);
        }
        return list;
      }
    }" -ReferencedAssemblies ("System.Collections", "System.Xml", "System.Xml.ReaderWriter") -Language CSharp
  }

  function Sort-XmlNode {
    param(
      [Parameter(Mandatory=$true)]
      [System.Xml.XmlLinkedNode]$node
    )
    if($node.HasChildNodes) {
      foreach($child in $node.ChildNodes) {
        Sort-XmlNode $child
      }
    }

    $nodeAttributes = [XmlHelpers]::GetAttributes($node)
    $sortedAttributes = $nodeAttributes | Sort-Object -Property Name
    if($targetNodes.Contains($node)) {
      $sortedChildren = $node.ChildNodes | Sort-Object -Property OuterXml
    } else {
      $sortedChildren = [XmlHelpers]::GetChildNodesClone($node)
    }

    $node.RemoveAll()

    foreach($attribute in $sortedAttributes) {
      [void]$nodeAttributes.Append($attribute)
    }
    foreach($child in $sortedChildren) {
      [void]$node.AppendChild($child)
    }
  }

  function Save-FormattedXml {
    $absolutePath = Resolve-Path $Path
  
    $settings = [System.Xml.XmlWriterSettings]::new()
    $settings.Indent = $true
    $writer = [System.Xml.XmlWriter]::Create($absolutePath, $settings)
    $document.Save($writer)
  }
  
  Sort-XmlNode $document.DocumentElement
  (Save-FormattedXml)
}