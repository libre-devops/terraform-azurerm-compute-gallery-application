module "rg" {
  source = "registry.terraform.io/libre-devops/rg/azurerm"

  rg_name  = "rg-${var.short}-${var.loc}-${var.env}-${random_string.entropy.result}"
  location = local.location
  tags     = local.tags
}

module "shared_vars" {
  source = "libre-devops/shared-vars/azurerm"
}

locals {
  lookup_cidr = {
    for landing_zone, envs in module.shared_vars.cidrs : landing_zone => {
      for env, cidr in envs : env => cidr
    }
  }
}

module "subnet_calculator" {
  source = "libre-devops/subnet-calculator/null"

  base_cidr = local.lookup_cidr[var.short][var.env][0]
  subnets = {
    "AzureBastionSubnet" = {
      mask_size = 26
      netnum    = 0
    }
    "subnet1" = {
      mask_size = 26
      netnum    = 1
    }
  }
}

module "network" {
  source = "libre-devops/network/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  vnet_name          = "vnet-${var.short}-${var.loc}-${var.env}-01"
  vnet_location      = module.rg.rg_location
  vnet_address_space = [module.subnet_calculator.base_cidr]

  subnets = {
    for i, name in module.subnet_calculator.subnet_names :
    name => {
      address_prefixes  = toset([module.subnet_calculator.subnet_ranges[i]])
      service_endpoints = ["Microsoft.Keyvault", "Microsoft.Storage"]
    }
  }
}

module "nsg" {
  source = "libre-devops/nsg/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  nsg_name              = "nsg-${var.short}-${var.loc}-${var.env}-01"
  associate_with_subnet = true
  subnet_id             = element(values(module.network.subnets_ids), 1)
  custom_nsg_rules = {
    "AllowVnetInbound" = {
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    }
  }
}
#
#module "bastion" {
#  source = "libre-devops/bastion/azurerm"
#
#  rg_name  = module.rg.rg_name
#  location = module.rg.rg_location
#  tags     = module.rg.rg_tags
#
#  bastion_host_name                  = "bst-${var.short}-${var.loc}-${var.env}-01"
#  create_bastion_nsg                 = true
#  create_bastion_nsg_rules           = true
#  create_bastion_subnet              = false
#  external_subnet_id                 = module.network.subnets_ids["AzureBastionSubnet"]
#  bastion_subnet_target_vnet_name    = module.network.vnet_name
#  bastion_subnet_target_vnet_rg_name = module.network.vnet_rg_name
#  bastion_subnet_range               = "10.0.1.0/27"
#}

resource "azurerm_application_security_group" "server_asg" {
  resource_group_name = module.rg.rg_name
  location            = module.rg.rg_location
  tags                = module.rg.rg_tags

  name = "asg-${var.short}-${var.loc}-${var.env}-01"
}


module "gallery" {
  source = "registry.terraform.io/libre-devops/compute-gallery/azurerm"

  compute_gallery = [
    {
      name     = "gal${var.short}${var.loc}${var.env}01"
      rg_name  = module.rg.rg_name
      location = module.rg.rg_location
      tags     = module.rg.rg_tags
    }
  ]
}

module "images" {
  source = "registry.terraform.io/libre-devops/compute-gallery-image/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags


  gallery_name = module.gallery.gallery_name["0"]
  images = [
    {
      name                                = "Windows2022AzureEdition"
      description                         = "The Windows 2022 image"
      specialised                         = false
      hyper_v_generation                  = "V2"
      os_type                             = "Windows"
      accelerated_network_support_enabled = true
      max_recommended_vcpu                = 16
      min_recommended_vcpu                = 2
      max_recommended_memory_in_gb        = 32
      min_recommended_memory_in_gb        = 8

      identifier = {
        offer     = "${var.short}${var.env}WindowsServer"
        publisher = "LibreDevOps"
        sku       = "2022AzureEdition"
      }
    }
  ]
}

resource "azurerm_user_assigned_identity" "uid" {
  name                = "uid-${var.short}-${var.loc}-${var.env}-01"
  resource_group_name = module.rg.rg_name
  location            = module.rg.rg_location
  tags                = module.rg.rg_tags
}

locals {
  now                 = timestamp()
  seven_days_from_now = timeadd(timestamp(), "168h")
}

module "sa" {
  source = "libre-devops/storage-account/azurerm"
  storage_accounts = [
    {
      name     = "sa${var.short}${var.loc}${var.env}01"
      rg_name  = module.rg.rg_name
      location = module.rg.rg_location
      tags     = module.rg.rg_tags

      identity_type = "SystemAssigned, UserAssigned"
      identity_ids  = [azurerm_user_assigned_identity.uid.id]

      network_rules = {
        bypass                     = ["AzureServices"]
        default_action             = "Allow"
        ip_rules                   = []
        virtual_network_subnet_ids = [module.network.subnets_ids["subnet1"]]
      }
    },
  ]
}

module "windows_server" {
  source = "libre-devops/windows-vm/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  windows_vms = [
    {
      name           = "web-${var.short}-${var.loc}-${var.env}-01"
      subnet_id      = module.network.subnets_ids["subnet1"]
      create_asg     = false
      asg_id         = azurerm_application_security_group.server_asg.id
      admin_username = "Local${title(var.short)}${title(var.env)}Admin"
      admin_password = data.azurerm_key_vault_secret.admin_pwd.value
      vm_size        = "Standard_B2ms"
      timezone       = "UTC"
      vm_os_simple   = "WindowsServer2022AzureEditionGen2"
      os_disk = {
        disk_size_gb = 128
      }
      identity_type = "SystemAssigned, UserAssigned"
      identity_ids  = [azurerm_user_assigned_identity.uid.id]

      run_vm_command = {
        inline = "try { Install-WindowsFeature -Name Web-Server -IncludeManagementTools } catch { Write-Error 'Failed to install IIS: $_'; exit 1 }"
      }
    },
  ]
}


locals {
  applications = {
    powershell-core = {
      name        = "PowerShellCore"
      version     = "7.4.1"
      description = "PowerShell for every system!"
      os_type     = "Windows"
      end_of_life = "2026-10-13T00:00:00Z" #13/10/2026
    }
  }
}

resource "azurerm_storage_container" "sa_container" {
  name                  = "windows-app"
  storage_account_name  = module.sa.storage_account_names["sa${var.short}${var.loc}${var.env}01"]
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "sa_blob" {
  name                   = "scripts"
  storage_account_name   = module.sa.storage_account_names["sa${var.short}${var.loc}${var.env}01"]
  storage_container_name = azurerm_storage_container.sa_container.name
  type                   = "Block"
  source_uri             = ""
}

module "apps" {
  source = "../../"

  gallery_id = module.gallery.gallery_id[0]
  location   = module.gallery.gallery_location[0]
  tags       = module.gallery.gallery_tags[0]

  applications = [
    {
      name               = local.applications.powershell-core.name
      description        = local.applications.powershell-core.description
      os_type            = local.applications.powershell-core.os_type
      end_of_life_date   = local.applications.powershell-core.end_of_life
      create_app_version = true
      app_version_manage_action = {
        install = "install.exe"
        remove  = "uninstall.exe"
        update  = "update.exe"
      }
      app_version_name = "latest"
      app_version_source = {
        media_link = azurerm_storage_blob.sa_blob.id
      }
      app_version_target_region = [{
        name                   = module.rg.rg_location
        regional_replica_count = 1
      }]
    }
  ]
}
