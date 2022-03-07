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

#Default environment tiers
$envTiers = 'dev','test','prod'
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
try {
    $tenantRequest = @{
        Path        = '/providers/Microsoft.BusinessAppPlatform/scopes/admin/updateTenantSettings'
        Method      = 'Post'
        RequestBody = ($tenantSettings | ConvertTo-Json -Depth 100)
    }
    $null = Invoke-PowerOpsRequest @tenantRequest
    Write-Host "Updated tenant settings"
} catch {
    throw "Failed to set tenant settings"
}

#endregion set tenant settings

#region rename default environment
if (-not [string]::IsNullOrEmpty($PPDefaultRenameText)) {
    $defaultEnvironment = Invoke-PowerOpsRequest -Method Get -Path '/providers/Microsoft.BusinessAppPlatform/scopes/admin/environments' | Where-Object { $_.Properties.environmentSku -eq "Default" }
    $oldDefaultName = $defaultEnvironment.properties.displayName
    if ($PPDefaultRenameText -ne $oldDefaultName) {
        $defaultEnvironment.properties.displayName = $PPDefaultRenameText
        $defaultEnvRequest = @{
            Path        = '/providers/Microsoft.BusinessAppPlatform/scopes/admin/environments/{0}' -f $defaultEnvironment.name
            Method      = 'Patch'
            RequestBody = ($defaultEnvironment | ConvertTo-Json -Depth 100)
        }
        try {
            Invoke-PowerOpsRequest @defaultEnvRequest
            Write-Host "Renamed default environment from $oldDefaultName to $PPDefaultRenameText"
        } catch {
            throw "Failed to rename Default DLP Policy"
        }
    }
}
#endregion rename default environment

#region create default dlp policies
if ($PPDefaultDLP -eq 'Yes') {
    # Get default recommended DLP policy from repo
    $defaultDLPTemplateFile = 'DefaultDLP.json'
    $defaultDLPTemplate = (Invoke-WebRequest -Uri $defaultDLPTemplateUri).Content | Set-Content -Path $defaultDLPTemplateFile -Force
    try {
        $null = New-PowerOpsDLPPolicy -TemplateFile $defaultDLPTemplateFile -Name Default
        Write-Host "Created Default DLP Policy"
    } catch {
        Write-Warning "Failed to create Default DLP Policy"
    }
}
#endregion create default dlp policies

#region create admin environments and import COE solution
if (-not [string]::IsNullOrEmpty($PPAdminEnvNaming)) {
    # Create environment
    foreach ($envTier in $envTiers) {
        try {
            $adminEnvName = '{0}-{1}' -f $PPAdminEnvNaming,$envTier
            $null = New-PowerOpsEnvironment -Name $adminEnvName -Location $PPAdminRegion -Dataverse $true
            Write-Host "Created environment $adminEnvName in $PPAdminRegion"
        } catch {
            throw "Failed to create admin environment $adminEnvName"
        }
    }
}
#endregion create admin environments and import COE solution

#region create landing zones for citizen devs
if ($PPCitizen -in "yes","half" -and $PPCitizenCount -ge 1) {
    $PPCitizenDataverse = $PPCitizen -eq "yes"
    1..$PPCitizenCount | ForEach-Object -Process {
        $environmentName = "{0}-{1:d2}" -f $PPCitizenNaming,$_
        try {
            $null = New-PowerOpsEnvironment -Name $environmentName -Location $PPCitizenRegion -Dataverse $PPCitizenDataverse
            Write-Host "Created citizen environment $environmentName in $PPCitizenRegion"
        } catch {
            throw "Failed to deploy citizen environment $environmentName"
        }
    }
}
#endregion create landing zones for citizen devs

#region create landing zones for pro devs
if ($PPPro -in "yes","half" -and $PPProCount -ge 1) {
    $PPProDataverse = $PPPro -eq "yes"
    1..$PPProCount | ForEach-Object -Process {
        $environmentName = "{0}-{1:d2}" -f $PPProNaming,$_
        try {
            $null = New-PowerOpsEnvironment -Name $environmentName -Location $PPProRegion -Dataverse $PPProDataverse
            Write-Host "Created pro environment $environmentName in $PPProRegion"
        } catch {
            throw "Failed to deploy pro environment $environmentName"
        }
    }
}
#endregion create landing zones for pro devs
