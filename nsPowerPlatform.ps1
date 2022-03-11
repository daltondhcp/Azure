[CmdletBinding()]
param (
    #Security, govarnance and compliance
    [Parameter(Mandatory = $false)][string]$PPGuestMakerSetting = 'Yes',
    [Parameter(Mandatory = $false)][string]$PPAppSharingSetting = 'Yes',
    #Admin environment and settings
    [Parameter(Mandatory = $false)][string]$PPEnvCreationSetting = 'Yes',
    [Parameter(Mandatory = $false)][string]$PPTrialEnvCreationSetting = 'Yes',
    [Parameter(Mandatory = $false)][string]$PPEnvCapacitySetting = 'Yes',
    [Parameter(Mandatory = $false)][string]$PPTenantIsolationSetting = 'none',
    [Parameter(Mandatory = $false)][string]$PPTenantDLP = 'Yes',
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPTenantIsolationDomains,
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
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPCitizenAlm,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPPro,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPProCount,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPProNaming,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPProRegion,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPProDlp,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPProBilling,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPProAlm,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPSelectIndustry,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPIndustryNaming,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPIndustryRegion,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPIndustryBilling,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPIndustryAlm
)

$DeploymentScriptOutputs = @{}

#Install required modules
Install-Module -Name PowerOps -AllowPrerelease -Force

#DLP Template references
$dlpPolicies = @{
    baseUri    = 'https://raw.githubusercontent.com/microsoft/industry/ns-riv1/foundations/powerPlatform/referenceImplementation/auxiliary/powerPlatform/'
    tenant     = @{
        low    = 'lowTenantDlpPolicy.json'
        medium = 'mediumTenantDlpPolicy.json'
        high   = 'highTenantDlpPolicy.json'
    }
    defaultEnv = 'defaultEnvDlpPolicy.json'
    adminEnv   = 'adminEnvDlpPolicy.json'
}

#Default environment tiers
$envTiers = 'dev', 'test', 'prod'

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
}
catch {
    throw "Failed to set tenant settings"
}

# Tenant Isolation settings
if ($PPTenantIsolationSetting) {
    $tenantIsolationSettings = @{
        Enabled = $true
    }
    if ($PPTenantIsolationDomains) {
        $tenantIsolationSettings.TenantId = $PPTenantIsolationDomains
        if ($PPTenantIsolationSetting -eq 'both') {
            $tenantIsolationSettings.AllowedDirection = 'InboundAndOutbound'
        }
        else {
            $tenantIsolationSettings.AllowedDirection = $PPTenantIsolationSetting
        }
    }
    Set-PowerOpsTenantIsolation @tenantIsolationSettings
    Write-Host "Updated tenant isolation settings"
}
#endregion set tenant settings

#region default environment

# Rename default environment
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
        }
        catch {
            throw "Failed to rename Default Environment"
        }
    }
}
# Create DLP policy for default environment
if ($PPDefaultDLP -eq 'Yes') {
    # Get default recommended DLP policy from repo
    $templateFile = 'defaultEnv.json'
    $template = (Invoke-WebRequest -Uri ($dlpPolicies['BaseUri'] + $dlpPolicies['defaultEnv'])).Content | ConvertFrom-Json -Depth 100
    $template.environments = @([PSCustomObject]@{
            id   = $defaultEnvironment.id
            name = $defaultEnvironment.name
            type = 'Microsoft.BusinessAppPlatform/scopes/environments'
        })
    $template | ConvertTo-Json -Depth 100 -EnumsAsStrings | Set-Content -Path $templateFile -Force
    try {
        $null = New-PowerOpsDLPPolicy -TemplateFile $templateFile -Name "Default Environment DLP"
        Write-Host "Created Default Environment DLP Policy"
    }
    catch {
        Write-Warning "Failed to create Default Environment DLP Policy`r`n$_"
    }
}
#endregion default environment

#region create default dlp policies
if ($PPTenantDLP -in 'low', 'medium', 'high') {
    # Get default recommended DLP policy from repo
    $templateFile = $dlpPolicies.tenant.$PPTenantDLP
    $templateRaw = (Invoke-WebRequest -Uri ($dlpPolicies['BaseUri'] + $templateFile)).Content
    $templateRaw | Set-Content -Path $templateFile -Force
    try {
        $policyDisplayName = ($templateRaw | ConvertFrom-Json).DisplayName
        $null = New-PowerOpsDLPPolicy -TemplateFile $templateFile -Name $policyDisplayName
        Write-Host "Created Default Tenant DLP Policy - $policyDisplayName"
    }
    catch {
        Write-Warning "Failed to create Default Tenant DLP Policy`r`n$_"
    }
}
#endregion create default dlp policies

#region create admin environments and import COE solution
if (-not [string]::IsNullOrEmpty($PPAdminEnvNaming)) {
    # Create environment
    foreach ($envTier in $envTiers) {
        try {
            $adminEnvName = '{0}-admin-{1}' -f $PPAdminEnvNaming, $envTier
            $null = New-PowerOpsEnvironment -Name $adminEnvName -Location $PPAdminRegion -Dataverse $true
            Write-Host "Created environment $adminEnvName in $PPAdminRegion"
        }
        catch {
            throw "Failed to create admin environment $adminEnvName`r `n$_"
        }
    }
    # Assign DLP to created environments
    $adminEnvironments = Get-PowerOpsEnvironment | Where-Object { $_.properties.displayName -like "$PPAdminEnvNaming-admin*" } | ForEach-Object -Process {
        [PSCustomObject]@{
            id   = $_.id
            name = $_.name
            type = 'Microsoft.BusinessAppPlatform/scopes/environments'
        }
    }
    $templateFile = $dlpPolicies['adminEnv']
    $template = (Invoke-WebRequest -Uri ($dlpPolicies['BaseUri'] + $templateFile)).Content | ConvertFrom-Json -Depth 100
    $template.environments = $adminEnvironments
    $template | ConvertTo-Json -Depth 100 -EnumsAsStrings | Set-Content -Path $templateFile -Force
    try {
        $null = New-PowerOpsDLPPolicy -TemplateFile $templateFile -Name "Admin Environment DLP"
        Write-Host "Created Default Admin Environment DLP Policy"
    }
    catch {
        Write-Warning "Created Default Admin Environment DLP Policy`r`n$_"
    }
}
#endregion create admin environments and import COE solution

#region create landing zones for citizen devs
if ($PPCitizen -in "yes", "half" -and $PPCitizenCount -ge 1) {
    $PPCitizenDataverse = $PPCitizen -eq "yes"
    1..$PPCitizenCount | ForEach-Object -Process {
        $environmentName = "{0}-{1:d3}" -f $PPCitizenNaming, $_
        try {
            if ($PPCitizenAlm -eq 'Yes') {
                foreach ($envTier in $envTiers) {
                    $almEnvironmentName = "{0}-{1}" -f $environmentName, $envTier
                    $null = New-PowerOpsEnvironment -Name $almEnvironmentName -Location $PPCitizenRegion -Dataverse $PPCitizenDataverse
                    Write-Host "Created citizen environment $almEnvironmentName in $PPCitizenRegion"
                }
            }
            else {
                $null = New-PowerOpsEnvironment -Name $environmentName -Location $PPCitizenRegion -Dataverse $PPCitizenDataverse
                Write-Host "Created citizen environment $environmentName in $PPCitizenRegion"
            }
        }
        catch {
            throw "Failed to deploy citizen environment $environmentName"
        }
    }
}
#endregion create landing zones for citizen devs

#region create landing zones for pro devs
if ($PPPro -in "yes", "half" -and $PPProCount -ge 1) {
    $PPProDataverse = $PPPro -eq "yes"
    1..$PPProCount | ForEach-Object -Process {
        $environmentName = "{0}-{1:d3}" -f $PPProNaming, $_
        try {
            if ($PPProAlm -eq 'Yes') {
                foreach ($envTier in $envTiers) {
                    $almEnvironmentName = "{0}-{1}" -f $environmentName, $envTier
                    $null = New-PowerOpsEnvironment -Name $almEnvironmentName -Location $PPProRegion -Dataverse $PPProDataverse
                    Write-Host "Created pro environment $almEnvironmentName in $PPProRegion"
                }
            }
            else {
                $null = New-PowerOpsEnvironment -Name $environmentName -Location $PPProRegion -Dataverse $PPProDataverse
                Write-Host "Created pro environment $environmentName in $PPProRegion"
            }
        }
        catch {
            throw "Failed to deploy pro environment $environmentName"
        }
    }
}
#endregion create landing zones for pro devs

#region create industry landing zones
if (-not[string]::IsNullOrEmpty($PPSelectIndustry)) {
    #TODO Add template support for the different industries
    $environmentName = $PPIndustryNaming
    try {
        if ($PPIndustryAlm -eq 'Yes') {
            foreach ($envTier in $envTiers) {
                $almEnvironmentName = "{0}-{1}" -f $environmentName, $envTier
                $null = New-PowerOpsEnvironment -Name $almEnvironmentName -Location $PPIndustryRegion -Dataverse $true
                Write-Host "Created industry environment $almEnvironmentName in $PPIndustryRegion"
            }
        }
        else {
            $null = New-PowerOpsEnvironment -Name $environmentName -Location $PPIndustryRegion -Dataverse $true
            Write-Host "Created industry environment $environmentName in $PPIndustryRegion"
        }
    }
    catch {
        throw "Failed to deploy industry environment $environmentName"
    }
}
#endregion create industry landing zones
