## Global
$rgName = "agens"
$location = "westus"

## Storage
$storageName = $rgName + $location

## Compute
$vmName = "anomaly-02"
$computerName = "anomaly-02"
$vmSize = "Basic_A1"
$osDiskName = $vmName + "OSDisk"

## VM Network
$nicname = $vmName + "-nic"
$pip = New-AzureRmPublicIpAddress -Name $vmName -ResourceGroupName $rgName -Location $location -AllocationMethod Dynamic
$vnetName = $rgName+$location

# Create a new virtual network, comment the following block if the vnet exists
$vnetName=$saName
$SubnetName="default"
$SubnetAddressPrefix="10.2.0.0/24"
echo "Creating Virtual Network Subnet"
$SingleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix
$vnetAddressPrefix="10.2.0.0/16"
echo "Creating Virtual Network $vnetName"
New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -Location $Location -AddressPrefix $vnetAddressPrefix -Subnet $SingleSubnet

# Get the existing virtual network
$vnet=Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName

$netSecurityGrpName=$saName+“-locator”
#echo "Creating New Network Security Group $netSecurityGrpName at $location"
#$netSecurityALLRule=New-AzureRmNetworkSecurityRuleConfig -Name "all-allow" -Description "Allow all tcp/udp/icmp traffic" `
#                -Access Allow -Protocol * -Direction Inbound -Priority 1100 `
#                -SourceAddressPrefix Internet -SourcePortRange * `
#                -DestinationAddressPrefix * -DestinationPortRange *
#New-AzureRmNetworkSecurityGroup -ResourceGroupName $rgName -Name $netSecurityGrpName -Location $location -SecurityRules $netSecurityALLRule
$netSecurityGrp=Get-AzureRmNetworkSecurityGroup -ResourceGroupName $rgName -Name $netSecurityGrpName
$nic=New-AzureRmNetworkInterface -Name $nicname -ResourceGroupName $rgName -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $netSecurityGrp.Id


## Setup local VM object
$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

$osDiskUri="https://agenswestus.blob.core.windows.net/vhds/anomaly-02-OSDisk.vhd"
$vm=Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -VhdUri $osDiskUri -CreateOption attach -Linux

## Create the VM in Azure
New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vm -Verbose -Debug