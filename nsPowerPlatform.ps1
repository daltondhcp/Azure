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
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPCitizenDescription,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPCitizenCurrency,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPCitizenLanguage,
    [Parameter(Mandatory = $false)]$PPCitizenConfiguration,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPPro,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPProCount,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPProNaming,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPProRegion,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPProDlp,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPProBilling,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPProAlm,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPProDescription,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPProCurrency,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPProLanguage,
    [Parameter(Mandatory = $false)]$PPProConfiguration,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPSelectIndustry,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPIndustryNaming,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPIndustryRegion,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPIndustryBilling,
    [Parameter(Mandatory = $false)][string][AllowEmptyString()][AllowNull()]$PPIndustryAlm
)

$DeploymentScriptOutputs = @{}

#Install required modules
Install-Module -Name PowerOps -AllowPrerelease -Force

#Default ALM environment tiers
$envTiers = 'dev', 'test', 'prod'

#region supporting functions
function New-EnvironmentCreationObject {
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'ARMInputString')]$ARMInputString,
        [Parameter(Mandatory = $true, ParameterSetName = 'EnvCount')][int]$EnvCount,
        [Parameter(Mandatory = $true, ParameterSetName = 'EnvCount')]$EnvNaming,
        [Parameter(Mandatory = $true, ParameterSetName = 'EnvCount')]$EnvRegion,
        [Parameter(Mandatory = $true, ParameterSetName = 'EnvCount')]$EnvLanguage,
        [Parameter(Mandatory = $true, ParameterSetName = 'EnvCount')]$EnvCurrency,
        [Parameter(Mandatory = $true, ParameterSetName = 'EnvCount')]$EnvDescription,
        [Parameter(Mandatory = $false)][switch]$EnvALM,
        [Parameter(Mandatory = $false, ParameterSetName = 'EnvCount')][switch]$EnvDataverse
    )
    if (-not [string]::IsNullOrEmpty($ARMInputString)) {
        foreach ($env in ($ARMInputString -split 'ppEnvName:')) {
            if ($env -match ".") {
                $environment = $env.TrimEnd(',')
                if ($EnvALM) {
                    foreach ($envTier in $envTiers) {
                        [PSCustomObject]@{
                            envRegion      = ($environment -split (','))[2].Split(':')[1]
                            envLanguage    = ($environment -split (','))[3].Split(':')[1]
                            envCurrency    = ($environment -split (','))[4].Split(':')[1]
                            envDescription = ($environment -split (','))[1].Split(':')[1]
                            envRbac        = ($environment -split (','))[5].Split(':')[1]
                            envName        = '{0}-{1}' -f ($environment -split (','))[0], $envTier
                        }
                    }
                }
                else {
                    [PSCustomObject]@{
                        envName        = ($environment -split (','))[0]
                        envRegion      = ($environment -split (','))[2].Split(':')[1]
                        envLanguage    = ($environment -split (','))[3].Split(':')[1]
                        envCurrency    = ($environment -split (','))[4].Split(':')[1]
                        envDescription = ($environment -split (','))[1].Split(':')[1]
                        envRbac        = ($environment -split (','))[5].Split(':')[1]
                    }
                }
            }
        }
    }
    else {
        1..$EnvCount | ForEach-Object -Process {
            $environmentName = "{0}-{1:d3}" -f $EnvNaming, $_
            if ($true -eq $EnvALM) {
                foreach ($envTier in $envTiers) {
                    [PSCustomObject]@{
                        envName        = "{0}-{1}" -f $environmentName, $envTier
                        envRegion      = $EnvRegion
                        envDataverse   = $EnvDataverse
                        envLanguage    = $envLanguage
                        envCurrency    = $envCurrency
                        envDescription = $envDescription
                        envRbac        = ''
                    }
                }
            }
            else {
                [PSCustomObject]@{
                    envName        = $environmentName
                    envRegion      = $EnvRegion
                    envDataverse   = $EnvDataverse
                    envLanguage    = $envLanguage
                    envCurrency    = $envCurrency
                    envDescription = $envDescription
                    envRbac        = ''
                }
            }
        }
    }
}
function New-DLPAssignmentFromEnv {
    param (
        [Parameter(Mandatory = $true)][string[]]$Environments,
        [Parameter(Mandatory = $true)][string]$EnvironmentDLP
    )
    #DLP Template references
    $dlpPolicies = @{
        baseUri          = 'https://raw.githubusercontent.com/microsoft/industry/main/foundations/powerPlatform/referenceImplementation/auxiliary/powerPlatform/'
        tenant           = @{
            low    = 'lowTenantDlpPolicy.json'
            medium = 'mediumTenantDlpPolicy.json'
            high   = 'highTenantDlpPolicy.json'
        }
        defaultEnv       = 'defaultEnvDlpPolicy.json'
        adminEnv         = 'adminEnvDlpPolicy.json'
        citizenDlpPolicy = 'citizenDlpPolicy.json'
        proDlpPolicy     = 'proDlpPolicy.json'
    }

    # Get base template from repo
    $templateFile = if ($Environments -contains 'AllEnvironments') { $dlpPolicies['tenant'].$EnvironmentDLP } else { $dlpPolicies["$EnvironmentDLP"] }
    if ([string]::IsNullOrEmpty($templateFile)) {
        throw "Cannot find DLP template $EnvironmentDLP"
    }
    try {
        $template = (Invoke-WebRequest -Uri ($dlpPolicies['BaseUri'] + $templateFile)).Content | ConvertFrom-Json -Depth 100
        Write-Host "Using base DLP template $templatefile"
    }
    catch {
        throw "Failed to get template $templatefile from $($dlpPolicies['baseUri'])"
    }

    # Handle environment inclusion
    if (($Environments -contains 'AllEnvironments' -and $Environments.count -gt 1) -or ($Environments -ne 'AllEnvironments')) {
        $environmentsToIncludeorExclude = $Environments | Where-Object { $_ -notlike 'AllEnvironments' } | ForEach-Object -Process {
            $envDisplayName = $_
            $envDetails = ''
            $envDetails = Get-PowerOpsEnvironment | Where-Object { $_.properties.displayName -eq $envDisplayName }
            [PSCustomObject]@{
                id   = $envDetails.id
                name = $envDetails.name
                type = 'Microsoft.BusinessAppPlatform/scopes/environments'
            }
        }
        if ($environmentsToIncludeorExclude.count -eq 1) {
            $template.environments | Add-Member -Type NoteProperty -Name id -Value $environmentsToIncludeorExclude.id -Force
            $template.environments | Add-Member -Type NoteProperty -Name name -Value $environmentsToIncludeorExclude.name -Force
        }
        else {
            $template.environments = $environmentsToIncludeorExclude
        }
        if ($Environments -contains 'AllEnvironments') {
            $template.environmentType = 'ExceptEnvironments'
        }
        else {
            $template.environmentType = 'OnlyEnvironments'
        }
    }
    # Convert template back to json and
    $template | ConvertTo-Json -Depth 100 -EnumsAsStrings | Set-Content -Path $templateFile -Force
    try {
        $null = New-PowerOpsDLPPolicy -TemplateFile $templateFile -Name $template.displayName -ErrorAction Stop
        Write-Host "Created Default $EnvironmentDLP DLP Policy"
    }
    catch {
        Write-Warning "Created Default $EnvironmentDLP DLP Policy`r`n$_"
    }
}
#endregion supporting functions

#region set tenant settings
# Get existing tenant settings
#TODO - add condition so script can be used without changing tenant settings
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
if ($PPTenantIsolationSetting -in 'inbound', 'outbound', 'both') {
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

    try {
        Set-PowerOpsTenantIsolation @tenantIsolationSettings
        Write-Host "Updated tenant isolation settings with $PPTenantIsolationSetting/$PPTenantIsolationDomains"
    }
    catch {
        throw "Failed to update tenant isolation settings"
    }
}
#endregion set tenant settings

#region default environment

# Rename default environment
if (-not [string]::IsNullOrEmpty($PPDefaultRenameText)) {
    # Retry logic to handle green field deployments
    $defaultEnvAttempts = 0
    do {
        $defaultEnvAttempts++
        $defaultEnvironment = Get-PowerOpsEnvironment | Where-Object { $_.Properties.environmentSku -eq "Default" }
        if (-not ($defaultEnvironment)) {
            Write-Host "Getting default environment - attempt $defaultEnvAttempts"
            Start-Sleep -Seconds 15
        }
    } until ($defaultEnvironment -or $defaultEnvAttempts -eq 15)
    # Get old default environment name
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
    try {
        New-DLPAssignmentFromEnv -Environments $defaultEnvironment.properties.displayName -EnvironmentDLP 'defaultEnv'
    }
    catch {
        Write-Warning "Failed to create Default Environment DLP Policy`r`n$_"
    }
}
#endregion default environment

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
    $adminEnvironments = Get-PowerOpsEnvironment | Where-Object { $_.properties.displayName -like "$PPAdminEnvNaming-admin*" }
    try {
        New-DLPAssignmentFromEnv -Environments $adminEnvironments.properties.displayName -EnvironmentDLP 'adminEnv'
        Write-Host "Created Default Admin Environment DLP Policy"
    }
    catch {
        Write-Warning "Created Default Admin Environment DLP Policy`r`n$_"
    }
}
#endregion create admin environments and import COE solution

#region create default tenant dlp policies
if ($PPTenantDLP -in 'low', 'medium', 'high') {
    try {
        $environments = @()
        $environments += 'AllEnvironments'
        if ($adminEnvironments) {
            $environments += $adminEnvironments.Properties.displayName
        }
        $null = New-DLPAssignmentFromEnv -Environments $environments -EnvironmentDLP $PPTenantDLP
        Write-Host "Created Default Tenant DLP Policy - $PPTenantDLP"
    }
    catch {
        Write-Warning "Failed to create Default Tenant DLP Policy`r`n$_"
    }
}
#endregion create default tenant dlp policies

#region create landing zones for citizen devs
if ($PPCitizen -in "yes", "half" -and $PPCitizenCount -ge 1 -or $PPCitizen -eq 'custom') {
    if ($PPCitizenConfiguration -ne 'null') {
        try {
            $environmentsToCreate = New-EnvironmentCreationObject -ARMInputString ($PPCitizenConfiguration -join ',') -EnvALM:($PPCitizenAlm -eq 'Yes')
        }
        catch {
            throw "Failed to create environment object. Input data is malformed. '`r`n$_'"
        }
    }
    else {
        try {
            $envHt = @{
                EnvCount       = $PPCitizenCount
                EnvNaming      = $PPCitizenNaming
                EnvRegion      = $PPCitizenRegion
                envLanguage    = $PPCitizenLanguage
                envCurrency    = $PPCitizenCurrency
                envDescription = $PPCitizenDescription
                EnvALM         = $PPCitizenAlm -eq 'Yes'
                EnvDataverse   = $PPCitizen -eq 'Yes'
            }
            $environmentsToCreate = New-EnvironmentCreationObject @envHt
        }
        catch {
            throw "Failed to create environment object. Input data is malformed. '`r`n$_'"
        }
    }
    foreach ($environment in $environmentsToCreate) {
        try {
            $envCreationHt = @{
                Name            = $environment.envName
                Location        = $environment.envRegion
                Dataverse       = $true
                Description     = $environment.envDescription
                LanguageName    = $environment.envLanguage
                Currency        = $environment.envCurrency
                SecurityGroupId = $environment.envRbac
            }
            $null = New-PowerOpsEnvironment @envCreationHt
            Write-Host "Created citizen environment $($environment.envName) in $($environment.envRegion)"
            if (-not [string]::IsNullOrEmpty($environment.envRbac) -and $environment.envDataverse -eq $false) {
                Write-Host "Assigning RBAC for principalId $($environment.envRbac) in citizen environment $($environment.envName)"
                $null = New-PowerOpsRoleAssignment -PrincipalId $environment.envRbac -RoleDefinition EnvironmentAdmin -EnvironmentName $environment.envName
            }
        }
        catch {
            Write-Warning "Failed to create citizen environment $($environment.envName) "
        }
    }
    if ($PPCitizenDlp -eq "Yes") {
        New-DLPAssignmentFromEnv -Environments $environmentsToCreate.envName -EnvironmentDLP 'citizenDlpPolicy'
    }
}
#endregion create landing zones for citizen devs

#region create landing zones for pro devs
if ($PPPro -in "yes", "half" -and $PPProCount -ge 1 -or $PPPro -eq 'custom') {
    if ($PPProConfiguration -ne 'null') {
        try {
            $environmentsToCreate = New-EnvironmentCreationObject -ARMInputString ($PPProConfiguration -join ',') -EnvALM:($PPProAlm -eq 'Yes')
        }
        catch {
            throw "Failed to create environment object. Input data is malformed. '`r`n$_'"
        }
    }
    else {
        try {
            $envHt = @{
                EnvCount       = $PPProCount
                EnvNaming      = $PPProNaming
                EnvRegion      = $PPProRegion
                EnvLanguage    = $PPProLanguage
                EnvCurrency    = $PPProCurrency
                EnvDescription = $PPProDescription
                EnvALM         = $PPProAlm -eq 'Yes'
                EnvDataverse   = $PPPro -eq 'Yes'
            }
            $environmentsToCreate = New-EnvironmentCreationObject @envHt
        }
        catch {
            throw "Failed to create environment object. Input data is malformed'`r`n$_'"
        }

    }
    foreach ($environment in $environmentsToCreate) {
        try {
            $envCreationHt = @{
                Name            = $environment.envName
                Location        = $environment.envRegion
                Dataverse       = $true
                Description     = $environment.envDescription
                LanguageName    = $environment.envLanguage
                Currency        = $environment.envCurrency
                SecurityGroupId = $environment.envRbac
            }
            $null = New-PowerOpsEnvironment @envCreationHt
            Write-Host "Created pro environment $($environment.envName) in $($environment.envRegion)"
            if (-not [string]::IsNullOrEmpty($environment.envRbac) -and $environment.envDataverse -eq $false) {
                Write-Host "Assigning RBAC for principalId $($environment.envRbac) pro environment $($environment.envName)"
                $null = New-PowerOpsRoleAssignment -PrincipalId $environment.envRbac -RoleDefinition EnvironmentAdmin -EnvironmentName $environment.envName
            }
        }
        catch {
            Write-Warning "Failed to create pro environment $($environment.envName) "
        }
    }
    if ($PPProDlp -eq "Yes") {
        New-DLPAssignmentFromEnv -Environments $environmentsToCreate.envName -EnvironmentDLP 'proDlpPolicy'
    }
}
#endregion create landing zones for pro devs

#region create industry landing zones
if (-not[string]::IsNullOrEmpty($PPIndustryNaming)) {
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
