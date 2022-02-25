[CmdletBinding()]
param (
    #Security, govarnance and compliance
    [Parameter(Mandatory = $false)][string[]]$PPBusinessDLP,
    [Parameter(Mandatory = $false)][string[]]$PPNonBusinessDLP,
    [Parameter(Mandatory = $false)][string[]]$PPBlockDLP,
    [Parameter(Mandatory = $false)][string]$PPGuestMakerSetting = 'Yes',
    [Parameter(Mandatory = $false)][string]$PPAppSharingSetting = 'Yes',
    #Admin environment and settings
    [Parameter(Mandatory = $false)][string]$PPEnvCreationSetting = 'Yes',
    [Parameter(Mandatory = $false)][string]$PPTrialEnvCreationSetting = 'Yes',
    [Parameter(Mandatory = $false)][string]$PPEnvCapacitySetting = 'Yes',
    [Parameter(Mandatory = $false)][string][AllowEmptyString()]$PPAdminEnvNaming,
    [ValidateSet('unitedstates', 'europe', 'asia', 'australia', 'india', 'japan', 'canada', 'unitedkingdom', 'unitedstatesfirstrelease', 'southamerica', 'france', 'switzerland', 'germany', 'unitedarabemirates')][Parameter(Mandatory = $false)][string]$PPAdminRegion,
    [Parameter(Mandatory = $false)][string]$PPAdminBilling,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()]$PPAdminCoeSetting,
    #Landing Zones[string][AllowEmptyString()]
    [Parameter(Mandatory = $false)][string][AllowEmptyString()]$PPDefaultRenameText,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()]$PPDefaultDLP,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()]$PPCitizen,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()]$PPCitizenCount,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()]$PPCitizenNaming,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()]$PPCitizenRegion,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()]$PPCitizenDlp,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()]$PPCitizenBilling,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()]$PPPro,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()]$PPProCount,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()]$PPProNaming,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()]$PPProRegion,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()]$PPProDlp,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()]$PPProBilling,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()]$PPSelectIndustry,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()]$PPIndustryNaming,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()]$PPIndustryRegion,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()]$PPIndustryBilling
)

$PSBoundParameters

#Install required modules
Install-Module -Name PowerOps -AllowPrerelease -Force

#Template references
$defaultDLPTemplateUri = 'https://raw.githubusercontent.com/Azure/AzOps/main/src/data/template/template.json'

#region set tenant settings
# Get existing tenant settings
$existingTenantSettings = Get-PowerOpsTenantSettings
# Update tenant settings
$tenantSettings = $existingTenantSettings
$tenantSettings.disableTrialEnvironmentCreationByNonAdminUsers = $PPTrialEnvCreationSetting -eq 'Yes'
$tenantSettings.powerPlatform.powerApps.enableGuestsToMake = $PPGuestMakerSetting -eq 'No'
$tenantSettings.powerPlatform.powerApps.disableShareWithEveryone = $PPAppSharingSetting -eq 'Yes'
$tenantSettings.disableEnvironmentCreationByNonAdminUsers = $PPEnvCreationSetting -eq 'Yes'
$tenantSettings.disableCapacityAllocationByEnvironmentAdmins = $PPEnvCapacitySetting -eq 'Yes'

# Update tenant settings
$tenantRequest = @{
    Path        = '/providers/Microsoft.BusinessAppPlatform/scopes/admin/updateTenantSettings'
    Method      = 'Post'
    RequestBody = ($tenantSettings | ConvertTo-Json -Depth 100)
}
Invoke-PowerOpsRequest @tenantRequest

#endregion set tenant settings

#region rename default environment
if (-not [string]::IsNullOrEmpty($PPDefaultRenameText)) {
    $defaultEnvironment = Invoke-PowerOpsRequest -Method Get -Path '/providers/Microsoft.BusinessAppPlatform/scopes/admin/environments' | Where-Object { $_.Properties.environmentSku -eq "Default" }
    $defaultEnvironment.properties.displayName = $PPDefaultRenameText
    $defaultEnvRequest = @{
        Path        = '/providers/Microsoft.BusinessAppPlatform/scopes/admin/environments/{0}' -f $defaultEnvironment.name
        Method      = 'Patch'
        RequestBody = ($defaultEnvironment | ConvertTo-Json -Depth 100)
    }
    Invoke-PowerOpsRequest @defaultEnvRequest
}
#endregion rename default environment
#region create default dlp policies
if ($PPDefaultDLP -eq 'Yes') {
    # Get default recommended DLP policy from repo
    $defaultDLPTemplate = 'DefaultDLP.json'
    $defaultDLPTemplate = (Invoke-WebRequest -Uri $defaultDLPTemplateUri).Content | Set-Content -Path $defaultDLPTemplate  -Force
    New-PowerOpsDLPPolicy -TemplateFile $defaultDLPTemplate -Name Default
}
#TODO - upload policies
#endregion create default dlp policies

#region create admin environments and import COE solution

#endregion create admin environments and import COE solution

#region create landing zones

#endregion create landing zones
