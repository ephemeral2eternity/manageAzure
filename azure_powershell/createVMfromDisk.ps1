## Global
$rgName = "agens"
$location = "eastus"

## Storage
$storageName = $rgName + $location

## Compute
$vmName = "anomaly-01"
$computerName = "anomaly-01"
$vmSize = "Basic_A1"
$osDiskName = $vmName + "locatorOSdisk"

## VM Network
$nicname = $vmName + "-nic"
$pip = New-AzureRmPublicIpAddress -Name $vmName -ResourceGroupName $rgName -Location $location -AllocationMethod Dynamic
$vnetName = $rgName+$location
$vnet=Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName
$netSecurityGrpName="localization"
$netSecurityGrp=Get-AzureRmNetworkSecurityGroup -ResourceGroupName $rgName -Name $netSecurityGrpName
$nic=New-AzureRmNetworkInterface -Name $nicname -ResourceGroupName $rgName -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $netSecurityGrp.Id


## Setup local VM object
$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

$osDiskUri="https://agenseastus.blob.core.windows.net/vhds/anomaly-012016210224955.vhd"
$vm=Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -VhdUri $osDiskUri -CreateOption attach -Linux

## Create the VM in Azure
New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vm -Verbose -Debug