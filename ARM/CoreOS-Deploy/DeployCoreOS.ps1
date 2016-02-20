[CmdletBinding(SupportsShouldProcess=$true)]
param (
    $DeploymentName = 'CoreOSTest',
    [ValidateSet('North Europe', 'West Europe')] 
    $Location = 'West Europe',
    $RGName = 'coreos-ams',
    $StorageAccountName = 'coreosstorage004',             
    $TemplateUri = 'https://raw.githubusercontent.com/daltondhcp/Azure/master/ARM/CoreOS-Deploy/azuredeploy-coreos.json'
)

#Check if resource group exist, create if not
$RGroup = Get-AzureRmResourceGroup -Name $RGName -Location $Location -ErrorAction Ignore -WarningAction Ignore
if (-not($RGroup)) {
    New-AzureRmResourceGroup -Name $RGName -Location $Location -Force -ErrorAction Stop -Verbose 
}

#Define Deployment template parameters
$TemplateParameters = @{
    storageAccountName = $storageaccountName    
    vmSize = 'Standard_A1'    
    coreVMPrefix  = 'coreos'    
    numberOfCoreNodes = 5
    adminusername = 'sysadmin'
    sshkeydata = 'ssh-rsa A/3pYOhGAopQRJ19Q== rsa-key-20160220'
    virtualNetworkName = 'virtualnetwork'
    AzureVnetAddressPrefix = '10.0.0.0/16'                 
    BEsubnetPrefix = '10.0.2.0/24'
    FEsubnetPrefix  = '10.0.1.0/24'
    BEsubnetName = 'frontend'
    FESubnetName = 'backend' 
    FENSGName = 'frontend-nsg'
    discoveryUrl = 'http://fleetdiscoveryjunk'
    DNSServerAddress = '4.2.2.1','4.2.2.2'

}

$GroupDeploymentHt = @{
    Name = $DeploymentName
    ResourceGroupName = $RGName
    #TemplateFile = ''
    TemplateParameterObject = $TemplateParameters 
    TemplateUri = $TemplateUri
}
New-AzureRmResourceGroupDeployment @GroupDeploymentHt -ErrorAction Stop -Verbose