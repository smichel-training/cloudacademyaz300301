# Required components
# Powershell AZ module
# Powershell AzTable module (Install-Module -Name AzTable)
# Microsoft.azure.storage.queue type
add-type -Path 'C:\Users\smichel\Documents\PowerShell\Modules\Az.Storage\1.11.0\Microsoft.Azure.Storage.Queue.dll'

# Connect to your Cloud Academy temporary Azure account
# Connect-AzAccount

# get the lab resource group name or if you are working on your account then create a dedicated resource group
# $rg = $(Get-AzResourceGroup).ResourceGroupName
$rg = New-AzResourceGroup -Name azstoragetraining -Location 'West Europe'

# create a new storage account based on storageTemplate.json file
New-AzResourceGroupDeployment -ResourceGroupName $rg.ResourceGroupName -Name storage-deployment -TemplateFile .\storageTemplate.json

# get the newly created storage account name
$createdStorageAccount = $(Get-AzResourceGroupDeployment -ResourceGroupName $rg.ResourceGroupName -DeploymentName storage-deployment).Outputs.storageAccountName.value

# Make the new storage account the default for the current PowerShell session
Set-AzCurrentStorageAccount -ResourceGroupName $rg.ResourceGroupName -StorageAccountName $createdStorageAccount

# download image
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/cloudacademy/azure-lab-provisioners/master/azure-storage/image.png" -OutFile .\image.png

# Create a new blob container
New-AzStorageContainer -Name images -Permission Off

# upload image.png within the new container
Set-AzStorageBlobContent -Container images -File .\image.png

# Get the blob object of the uploaded image (This is not the image)
$blob = Get-AzStorageBlob -Container images -Blob image.png

# Display the URI of the blob
# There is only a primary URI because the storage account is not configured as GRS
$blob.ICloudBlob.StorageUri

# Store the Uri
$blobUri = $blob.ICloudBlob.StorageUri.PrimaryUri

# Construct an URI with a SAS Token
$blobSASUri = $blobUri.AbsoluteUri + $(New-AzStorageBlobSASToken -CloudBlob $blob.ICloudBlob -Permission r)

# Open the URI with IE
Start-Process -FilePath 'iexplore.exe' -ArgumentList $blobSASUri

# Create key-value hashtable
$Metadata = @{ Type = "Wallpaper" }

# Upload another image with associated Metadata
Set-AzStorageBlobContent -Container images -File C:\Windows\Web\Wallpaper\Theme1\img13.jpg -Metadata $Metadata

# Get all blob of type Wallpaper
$wallpapers = Get-AzStorageBlob -Container images | Where-Object {$_.ICloudBlob.Metadata["type"] -eq "Wallpaper"}

#Download the file
Get-AzStorageBlobContent -CloudBlob $wallpapers.ICloudBlob

# Create a new blob container
New-AzStorageContainer -Name wallpapers -Permission Container

# Copy wallpapers from images container to wallpapers container
Start-AzStorageBlobCopy -CloudBlob $wallpapers[0].ICloudBlob -DestContainer wallpapers

# Remove the image from images container
Remove-AzStorageBlob -CloudBlob $wallpapers[0].ICloudBlob

# Create a new table 
$TblName = "blobFiles"
New-AzStorageTable -Name $TblName

# get the table reference
$Tbl = Get-AzStorageTable -Name $TblName

# Get back the container references created previously
$Logo = Get-AzStorageBlob -Container images
$Wallpaper = Get-AzStorageBlob -Container wallpapers

# load functions from lab-functions.ps1
. ./lab-functions.ps1

# Add enity in table
Add-Entity -Table $Tbl.CloudTable -Blob $Logo -Type "logo"
Add-Entity -Table $Tbl.CloudTable -Blob $Wallpaper -Type "wallpaper"

# Query the table
# Default query is "Select all"
Get-AzTableRow -table $tbl.CloudTable | ft


# Get entity from Wallpapers Partition Key
# Partiton Key is case sensitive !!
$entity = Get-AzTableRow -table $tbl.CloudTable -partitionKey 'wallpapers'

# Get entity based on the type collumn
# columnName and value are case sensitive
$entity = get-azTableRow -table $tbl.CloudTable -columnName "Type" -value "wallpaper" -operator Equal

# Display entity
$Entity

# Create a message Queue
$QueueName = "thumbnail-queue" 
$Queue = New-AzStorageQueue –Name $QueueName

# Add Messages to the queue
Add-Message -Queue $Queue -Blob $Logo
Add-Message -Queue $Queue -Blob $Wallpaper

# Refresh $Queue object
$Queue = Get-AzStorageQueue -Name $QueueName
$Queue.ApproximateMessageCount

# download and import Resize-Image module
Invoke-WebRequest -Uri "https://gallery.technet.microsoft.com/scriptcenter/Resize-Image-A-PowerShell-3d26ef68/file/135684/1/Resize-Image.psm1" -OutFile .\Resize-Image.psm1
Import-Module .\Resize-Image.psm1 

# Create a new blob container
New-AzStorageContainer -Name thumbnails -Permission Container

# Process Message in queue
Process-Message -Queue $Queue
Process-Message -Queue $Queue
Process-Message -Queue $Queue

# Get Storage Account Key
Get-AzStorageAccountKey -ResourceGroupName $rg.ResourceGroupName -Name $createdStorageAccount
# Regenerate key1
New-AzStorageAccountKey -ResourceGroupName $rg.ResourceGroupName -Name $createdStorageAccount -KeyName key1
# Regenerate key2 by entering:
New-AzStorageAccountKey -ResourceGroupName $rg.ResourceGroupName -Name $createdStorageAccount -KeyName key2
# List the keys to verify they are not the same as before:
Get-AzStorageAccountKey -ResourceGroupName $rg.ResourceGroupName -Name $createdStorageAccount
