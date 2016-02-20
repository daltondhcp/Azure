[CmdletBinding(SupportsShouldProcess=$true)]
param (
    $DeploymentName = 'CoreOSTest',
    [ValidateSet('North Europe', 'West Europe')] #More regions are available ....
    $Location = 'West Europe',
    $RGName = 'CoreOSWE',
    $TemplateUri = 'https://raw.githubusercontent.com/daltondhcp/Azure/master/ARM/CoreOS-Deploy/azuredeploy-coreos.json'
)

#Check if resource group exist, create if not
$RGroup = Get-AzureRmResourceGroup -Name $RGName -Location $Location -ErrorAction Ignore -WarningAction Ignore
if (-not($RGroup)) {
    New-AzureRmResourceGroup -Name $RGName -Location $Location -Force -ErrorAction Stop
}

#Define Deployment template parameters
$TemplateParameters = @{
    storageAccountName = 'coreosstorage0032'     #lower case...            
    vmSize = 'Standard_A1'    
    coreVMPrefix  = 'coreos'    
    numberOfCoreNodes = 5
    adminusername = 'sysadmin'
    sshkeydata = 'ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAlx2tBjx7as63vWFaOg4fxPuRLJc4xWJNTXcsO1lgVA6MjGzmMPLEH2KJPhKOaW1kHMptWgyzGfN6lvSRruwc1wXffdPKR5qX9siezaSoD808Z+UXfZAkkIcdCgakhG4cHGenLBAsqik/0lghEEGX/7/ImwqJaBIxtRcqnP6vKW7SDQvEjWfBVdYnyc/TdwA7fAElVtm1bP7Or5ggPqGDbXJTCoKwMcWGfCA0Q51pYRgGgqVFdrDrEFdegYopVa9igM0vldbHD8jJ2SlG2xpXpRnEXH/Az0Q9Cjjp3gOU0P8U/7cAG/iN0ZEnX7q4+XIBqY/jtu/3pYOhGAopQRJ19Q== rsa-key-20160220'
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
New-AzureRmResourceGroupDeployment @GroupDeploymentHt -ErrorAction Stop