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
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPAdminEnvNaming,
    [ValidateSet('unitedstates', 'europe', 'asia', 'australia', 'india', 'japan', 'canada', 'unitedkingdom', 'unitedstatesfirstrelease', 'southamerica', 'france', 'switzerland', 'germany', 'unitedarabemirates')][Parameter(Mandatory = $false)][string]$PPAdminRegion,
    [Parameter(Mandatory = $false)][string]$PPAdminBilling,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPAdminCoeSetting,
    #Landing Zones[string][AllowEmptyString()]
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPDefaultRenameText,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPDefaultDLP,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPCitizen,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPCitizenCount,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPCitizenNaming,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPCitizenRegion,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPCitizenDlp,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPCitizenBilling,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPPro,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPProCount,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPProNaming,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPProRegion,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPProDlp,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPProBilling,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPSelectIndustry,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPIndustryNaming,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPIndustryRegion,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPIndustryBilling
)

$DeploymentScriptOutputs = @{}

#Install required modules
Install-Module -Name PowerOps -AllowPrerelease -Force

#Template references
$defaultDLPTemplateUri = 'https://raw.githubusercontent.com/daltondhcp/Azure/nsppscript/defaultDLP.json'

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

    if ($PPDefaultRenameText -ne $defaultEnvironment.properties.displayName) {
        $defaultEnvironment.properties.displayName = $PPDefaultRenameText
        $defaultEnvRequest = @{
            Path        = '/providers/Microsoft.BusinessAppPlatform/scopes/admin/environments/{0}' -f $defaultEnvironment.name
            Method      = 'Patch'
            RequestBody = ($defaultEnvironment | ConvertTo-Json -Depth 100)
        }
        Invoke-PowerOpsRequest @defaultEnvRequest
    }
}
#endregion rename default environment
#region create default dlp policies
if ($PPDefaultDLP -eq 'Yes') {
    # Get default recommended DLP policy from repo
    $defaultDLPTemplateFile = 'DefaultDLP.json'
    $defaultDLPTemplate = (Invoke-WebRequest -Uri $defaultDLPTemplateUri).Content | Set-Content -Path $defaultDLPTemplateFile -Force
    New-PowerOpsDLPPolicy -TemplateFile $defaultDLPTemplateFile -Name Default
}
#endregion create default dlp policies

#region create admin environments and import COE solution
if (-not [string]::IsNullOrEmpty($PPAdminEnvNaming)) {
    # Create environment
    try {
        New-PowerOpsEnvironment -Name $PPAdminEnvNaming -Location $PPAdminRegion -Dataverse $true
    } catch {
        throw "Failed to create admin environment $PPAdminEnvNaming"
    }
}
#endregion create admin environments and import COE solution

#region create landing zones for citizen devs
if ($PPCitizenCount -ge 1) {
    $PPCitizenDataverse = $PPCitizen -eq "yes"
    1..$PPCitizenCount | ForEach-Object -Process {
        $environmentName = "{0}-{1:d2}" -f $PPCitizenNaming,$_
        New-PowerOpsEnvironment -Name $environmentName -Location $PPCitizenRegion -Dataverse $PPCitizenDataverse
    }
}
#endregion create landing zones for citizen devs

#region create landing zones for pro devs
if ($PPProCount -ge 1) {
    $PPProDataverse = $PPPro -eq "yes"
    1..$PPProCount | ForEach-Object -Process {
        $environmentName = "{0}-{1:d2}" -f $PPProNaming,$_
        New-PowerOpsEnvironment -Name $environmentName -Location $PPProRegion -Dataverse $PPProDataverse
    }
}

#endregion create landing zones for pro devs
