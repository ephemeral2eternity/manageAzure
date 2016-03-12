### Source VHD (West US) - anonymous access container ###
$srcUri="https://agenseastus.blob.core.windows.net/vhds/anomaly-012016210224955.vhd"
# $srcUri="https://agensimages.blob.core.windows.net/cmu-agens/anomalyLocator.vhd"
# $srcUri="https://agenseastus.blob.core.windows.net/vhds/anomaly-01201623133020.vhd"
 
### Target Storage Account (North Central US) ###
$rgName="agens"
$location="northcentralus"
$storageAccountName=$rgName + $location
#$storageAccount=New-AzureRmStorageAccount -ResourceGroupName $rgName -Name $storageAccountName -Location $location

$storageKey=""
 
### Create the destination context for authenticating the copy
$destContext = New-AzureStorageContext  -StorageAccountName $storageAccount `
										-StorageAccountKey $storageKey  
 
### Target Container Name
$containerName="vhds"
 
### Create the target container in storage
#New-AzureStorageContainer -Name $containerName -Context $destContext
 
### Start the Asynchronous Copy ###
$blobCopy = Start-AzureStorageBlobCopy -srcUri $srcUri `
									-DestContainer $containerName `
									-DestBlob "anomaly-03-OSDisk.vhd" `
									-DestContext $destContext

while(($blobCopy | Get-AzureStorageBlobCopyState).Status -eq "Pending")
{
    Start-Sleep -s 30
    $blobCopy | Get-AzureStorageBlobCopyState
}