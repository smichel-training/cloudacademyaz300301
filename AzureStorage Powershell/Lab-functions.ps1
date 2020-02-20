# Function Add-Entity: Adds a blob file entity of a given type to a table.
function Add-Entity() {
    [CmdletBinding()]
    param(
      $Table,
      $Blob,
      $Type
    )
  
    # Use the Container name as the partition key
    $PartitionKey = $Blob.ICloudBlob.Container.Name
    # Use the blob name as the row key
    $RowKey = $Blob.Name

    # https://github.com/paulomarquesc/AzureRmStorageTable/tree/master/docs
    Add-AzTableRow -table $Table -partition $partitionKey -rowKey $RowKey -property @{"Type"=$Type;"storageUri"=$Blob.ICloudBlob.StorageUri.PrimaryUri.AbsoluteUri}


  
    #$Entity = New-Object -TypeName Microsoft.WindowsAzure.Storage.Table.DynamicTableEntity
    #$Entity.PartitionKey = $PartitionKey
    #$Entity.RowKey = $RowKey
    #$Entity.Properties.Add("Type", $Type)
    #$Entity.Properties.Add("StorageUri", $Blob.ICloudBlob.StorageUri.PrimaryUri.AbsoluteUri)
  
    #$Table.CloudTable.Execute([Microsoft.WindowsAzure.Storage.Table.TableOperation]::Insert($Entity))
    
  }