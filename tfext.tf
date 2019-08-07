
#Extension: add server to domain
resource "azurerm_virtual_machine_extension" "ADD2AD" {
  name                 = "ADD2AD"
  location             = azurerm_resource_group.testvm.location
  resource_group_name  = azurerm_resource_group.testvm.name
  virtual_machine_name = azurerm_virtual_machine.InfrastructureServer.name
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"

  # https://docs.microsoft.com/en-us/windows/desktop/api/lmjoin/nf-lmjoin-netjoindomain

  settings = <<SETTINGS
        {
            "Name": "${var.DomainName}",
            "User": "${var.DJoinUser}",
            "Restart": "true",
            "Options": "3"
        }
SETTINGS


  protected_settings = <<PROTECTED_SETTINGS
    {
      "Password": "${var.ARM_VAR_DJoinSecret}"
    }
  
PROTECTED_SETTINGS


  depends_on = [azurerm_virtual_machine.InfrastructureServer]
}

locals {
  dsc_mode = "ApplyAndAutoCorrect"
}

#NOTE: Node data must already exist - otherwise the extension will fail with 'No NodeConfiguration was found for the agent.'
resource "azurerm_virtual_machine_extension" "dsc_extension" {
  name                       = "Microsoft.Powershell.DSC"
  location              t     = azurerm_resource_group.testvm.location
  resource_group_name        = azurerm_resource_group.testvm.name
  virtual_machine_name       = azurerm_virtual_machine.InfrastructureServer.name
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.77"
  auto_upgrade_minor_version = true

  #use default extension properties as mentioned here:
  #https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/dsc-template
  settings = <<SETTINGS_JSON
        {
            "configurationArguments": {
                "RegistrationUrl" : "${var.dscaa-server-endpoint}",
                "NodeConfigurationName" : "DemoConfig.localhost",
                "ConfigurationMode": "${local.dsc_mode}",
                "RefreshFrequencyMins": 30,
                "ConfigurationModeFrequencyMins": 15,
                "RebootNodeIfNeeded": false,
                "ActionAfterReboot": "continueConfiguration",
                "AllowModuleOverwrite": true
            }
        }
  
SETTINGS_JSON


  protected_settings = <<PROTECTED_SETTINGS_JSON
    {
        "configurationArguments": {
                "RegistrationKey": {
                    "userName": "NOT_USED",
                    "Password": "${var.dscaa-access-key}"
                }
        }
    }
  
PROTECTED_SETTINGS_JSON

}
