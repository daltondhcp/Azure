param (  
    $OperatingSystem = 'Windows Server 2019',
    $Environment = '',
    $VMSize = '',    
    $Region = '',
    $NetworkZone = '',
    $Description = '',
    $SR = ''
)

if ($OperatingSystem -like "Windows*") {
    #Get the latest windows image and SKU 
    $OSVersionToInstall = $OperatingSystem.Split(" ")[-1]
    $ImageSku = Get-AzVMImagesku -Location $Region -PublisherName MicrosoftWindowsServer -Offer windowsserver | Where-Object {$_.Skus -like "$OSVersionToInstall*"} | Select-Object -First 1
} else {
    #Find your linux image :) 
}

#Get Virtual network 
$VNet = Get-AzVirtualNetwork 
$Subnet = $VNet.Subnets | Where-Object {$_.Name -like "Application"}
#Set virtual machine properties 
$VMLocalAdminUser = "01localvmadmin"
$Password = '{0}!#{1}' -f (New-Guid).Guid,(New-Guid).Guid
$VMLocalAdminSecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
$ResourceGroupName = "365labvm-{0}" -f (New-Guid).Guid.Split("-")[2]
$VMName = $ResourceGroupName
$NicName = "{0}-nic01" -f $VMName 
$VMSize = "Standard_DS1_v2"

#Create Resource Group 
New-AzResourceGroup -Name $ResourceGroupName -Location $Region -Verbose 
$NIC = New-AzNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName -Location $Region -SubnetId $Subnet.Id 

$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword)

$VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus $imagesku.Skus -Version latest

New-AzVM -ResourceGroupName $ResourceGroupName -Location $Region -VM $VirtualMachine -Verbose 

$DJoinUser = Get-AzKeyVaultSecret -VaultName vmdeploy-kv -Name djoin-user 
$DJoinSecret = Get-AzKeyVaultSecret -VaultName vmdeploy-kv -Name djoin-secret 
$DjoinCredentials = New-Object System.Management.Automation.PSCredential ($DJoinUser.SecretValueText, $Djoinsecret.SecretValue)

function Add-JDAzureRMVMToDomain {
    <#
    .SYNOPSIS
        The function joins Azure RM virtual machines to a domain.
    .EXAMPLE
        Get-AzureRmVM -ResourceGroupName 'ADFS-WestEurope' | Select-Object Name,ResourceGroupName | Out-GridView -PassThru | Add-JDAzureRMVMToDomain -DomainName corp.acme.com -Verbose
    .EXAMPLE
        Add-JDAzureRMVMToDomain -DomainName corp.acme.com -VMName AMS-ADFS1 -ResourceGroupName 'ADFS-WestEurope'
    .NOTES
        Author   : Johan Dahlbom, johan[at]dahlbom.eu
        Blog     : 365lab.net
        The script are provided “AS IS” with no guarantees, no warranties, and it confer no rights.
    #>
    
    param(
        [Parameter(Mandatory=$true)]
        [string]$DomainName,
        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]$Credentials = (Get-Credential -Message 'Enter the domain join credentials'),
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [Alias('VMName')]
        [string]$Name,
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({Get-AzResourceGroup -Name $_})]
        [string]$ResourceGroupName
    )
        begin {
            #Define domain join settings (username/domain/password)
            $Settings = @{
                Name = $DomainName
                User = $Credentials.UserName
                Restart = "true"
                Options = 3
            }
            $ProtectedSettings =  @{
                    Password = $Credentials.GetNetworkCredential().Password
            }
            Write-Verbose -Message "Domainname is: $DomainName"
        }
        process {
            try {
                $RG = Get-AzResourceGroup -Name $ResourceGroupName
                $JoinDomainHt = @{
                    ResourceGroupName = $RG.ResourceGroupName
                    ExtensionType = 'JsonADDomainExtension'
                    Name = 'joindomain'
                    Publisher = 'Microsoft.Compute'
                    TypeHandlerVersion = '1.3'
                    Settings = $Settings
                    VMName = $Name
                    ProtectedSettings = $ProtectedSettings
                    Location = $RG.Location
                }
                Write-Verbose -Message "Joining $Name to $DomainName"
                Set-AzVMExtension @JoinDomainHt
            } catch {
                Write-Warning $_
            }
        }
        end { }
}

Add-JDAzureRMVMToDomain -DomainName corp.365lab.net -Name $VMName -ResourceGroupName  $ResourceGroupName -verbose -Credentials $DjoinCredentials