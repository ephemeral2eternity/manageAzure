## VM Account
# Set values for existing resource group
$rgName = "agens"

## Azure Storage Account
$Location="westus"
# This a Premium_LRS storage account. 
# It is required in order to run a client VM with efficiency and high performance.
$saName=$rgName+$Location
$saType="Standard_LRS"
# Give a name to your new container.
$ContainerName = "vhds"

# Create a new storage account.
#echo "Creating the storage account $saName at $Location"
#New-AzureRmStorageAccount -ResourceGroupName $rgName –Name $saName -Type $saType -Location $Location

## VM
$vmName = "anomaly-01"
$vmSize = "Basic_A1" 

# Disk
$OSDiskName="locatorOSdisk"
$SourceImageUri = "https://agenswestus.blob.core.windows.net/imgs/anomalyLocator.vhd"
$storageAcc=Get-AzureRmStorageAccount -ResourceGroupName $rgName -Name $saName
#$OSDiskUri=$storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $vmName + $OSDiskName  + ".vhd"
$OSDiskUri= '{0}vhds/{1}{2}.vhd' -f $storageAcc.PrimaryEndpoints.Blob.ToString(), $vmName.ToLower(), $OSDiskName
$OSDiskCaching = "ReadWrite"
$OSCreateOption = "FromImage"


## Networking
# Set the existing virtual network
$vnetName=$saName+"-net"
$SubnetName="default-subnet"
$SubnetAddressPrefix="10.2.0.0/24"
echo "Creating Virtual Network Subnet"
$SingleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix
$vnetAddressPrefix="10.2.0.0/16"
echo "Creating Virtual Network $vnetName"
$vnet=New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -Location $Location -AddressPrefix $vnetAddressPrefix -Subnet $SingleSubnet
# $vnet=New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -Location $Location -AddressPrefix $vnetAddressPrefix
$PublicIPAddressName = $vmName + "-ip"
echo "Creating IP $PublicIPAddressName for the vm $vmName"
$PIP = New-AzureRmPublicIpAddress -Name $PublicIPAddressName -ResourceGroupName $rgName -Location $Location -AllocationMethod Dynamic
$NICName = $vmName + "-nic"
echo "Creating New Network Security Group $netSecurityGrpName at $Location"
$netSecurityGrpName=$rgName + $Location + "-securitygrp"
$netSecurityALLRule=New-AzureRmNetworkSecurityRuleConfig -Name "all-allow" -Description "Allow all tcp/udp/icmp traffic" `
                -Access Allow -Protocol * -Direction Inbound -Priority 1100 `
                -SourceAddressPrefix Internet -SourcePortRange * `
                -DestinationAddressPrefix * -DestinationPortRange *
# New-AzureRmNetworkSecurityGroup -ResourceGroupName $rgName -Name $netSecurityGrpName -Location $Location -SecurityRules $netSecurityALLRule
$netSecurityGrp=Get-AzureRmNetworkSecurityGroup -ResourceGroupName $rgName -Name $netSecurityGrpName
echo "Creating the NIC $NICName for the vm $vmName"
$NIC = New-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $rgName -Location $Location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $PIP.Id -NetworkSecurityGroupId $netSecurityGrp.Id


# Credentials for Local Admin account you created in the sysprepped (generalized) vhd image
$VMLocalAdminUser = "chenw"
$VMLocalAdminSecurePassword = ConvertTo-SecureString "Jun.9332" -AsPlainText -Force
echo "Add credentials for the VM with local admin user : $VMLocalAdminUser"
$Credential=New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword); 

echo "Create the new VM configuration: $vmName"
$vm=New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize
echo "Set the operating system for the VM: $vmName"
$vm=Set-AzureRmVMOperatingSystem -VM $vm -ComputerName $vmName -Credential $Credential -Linux
echo "Add the network NIC the VM: $vmName"
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $NIC.Id
echo "Set the DISK for the VM: $vmName from the image source: $SourceImageUri !"
$vm=Set-AzureRmVMOSDisk -VM $vm -Name $OSDiskName -VhdUri $OSDiskUri -SourceImageUri $SourceImageUri -Caching $OSDiskCaching -CreateOption $OSCreateOption -Linux
echo "Create the VM: $vmName"
New-AzureRmVM -ResourceGroupName $rgName -Location $Location -VM $vm -Verbose