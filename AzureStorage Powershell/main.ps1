# Connect to your Cloud Academy temporary Azure account

# get the lab resource group name
$rg = $(Get-AzResourceGroup).ResourceGroupName

# create a new storage account based on storageTemplate.json file
New-AzResourceGroupDeployment -ResourceGroupName $rg -Name storage-deployment -TemplateFile .\storageTemplate.json

# get the newly created storage account name
$createdStorageAccount = $(Get-AzResourceGroupDeployment -ResourceGroupName $rg -DeploymentName storage-deployment).Outputs.storageAccountName.value

# Make the new storage account the default for the current PowerShell session
Set-AzCurrentStorageAccount -ResourceGroupName $rg -StorageAccountName $createdStorageAccount

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



