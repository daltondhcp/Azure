[CmdletBinding()]
param (
    #Deployment setup
    [Parameter(Mandatory = $false)][string]$AzureSubscriptionId,
    #Security, govarnance and compliance
    [Parameter(Mandatory = $false)][string[]]$PPBusinessDLP,
    [Parameter(Mandatory = $false)][string[]]$PPNonBusinessDLP,
    [Parameter(Mandatory = $false)][string[]]$PPBlockDLP,
    [Parameter(Mandatory = $false)][string]$PPGuestMakerSetting,
    [Parameter(Mandatory = $false)][string]$PPAppSharingSetting,
    #Admin environment and settings
    [Parameter(Mandatory = $false)][string]$PPEndCreationSetting,
    [Parameter(Mandatory = $false)][string]$PPTrialEnvCreationSetting,
    [Parameter(Mandatory = $false)][string]$PPEnvCapacitySetting,
    [Parameter(Mandatory = $false)][string]$PPAdminEnvNaming,
    [ValidateSet('unitedstates', 'europe', 'asia', 'australia', 'india', 'japan', 'canada', 'unitedkingdom', 'unitedstatesfirstrelease', 'southamerica', 'france', 'switzerland', 'germany', 'unitedarabemirates')][Parameter(Mandatory = $false)][string]$PPAdminRegion,
    [Parameter(Mandatory = $false)][string]$PPAdminCoeSetting,
    #Landing Zones
    [Parameter(Mandatory = $false)][string]$PPDefaultRename,
    [Parameter(Mandatory = $false)][string]$PPDefaultRenameText,
    [Parameter(Mandatory = $false)][string]$PPCitizen,
    [Parameter(Mandatory = $false)][string]$PPCitizenCount,
    [Parameter(Mandatory = $false)][string]$PPCitizenNaming,
    [Parameter(Mandatory = $false)][string]$PPCitizenRegion,
    [Parameter(Mandatory = $false)][string]$PPCitizenDlp,
    [Parameter(Mandatory = $false)][string]$PPCitizenBilling
)

#Install required modules
Install-Module -Name PowerOps -AllowPrerelease -Force

#region set tenant settings
# Get existing tenant settings
$existingTenantSettings = Get-PowerOpsTenantSettings
$tenantSettingstoChange = @($PPEndCreationSetting, $PPAppSharingSetting, $PPTrialEnvCreationSetting, $PPGuestMakerSetting)

$tenantSettings = $existingTenantSettings
$tenantSettings.disableTrialEnvironmentCreationByNonAdminUsers = $PPTrialEnvCreationSetting -eq 'No'
#TODO - update tenant settings based on settings to change

Invoke-PowerOpsRequest -Path /providers/Microsoft.BusinessAppPlatform/scopes/admin/updateTenantSettings -Method Post -RequestBody ($tenantSettings | ConvertTo-Json -Depth 100)

#endregion set tenant settings

#region create default dlp policies

#endregion create default dlp policies

#region create admin environments and import COE solution

#endregion create admin environments and import COE solution

#region create landing zones

#endregion create landing zones
