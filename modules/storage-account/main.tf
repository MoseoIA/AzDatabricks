# --- main.tf en Mod_AzStorageAccount_Native ---

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_storage_account" "sa" {
  name                            = var.storage_account_name
  resource_group_name             = data.azurerm_resource_group.rg.name
  location                        = data.azurerm_resource_group.rg.location
  account_tier                    = var.account_tier
  account_replication_type        = var.account_replication_type
  is_hns_enabled                  = var.is_hns_enabled
  min_tls_version                 = var.min_tls_version

  network_rules {
    default_action = "Deny"
    ip_rules       = var.allowed_public_ips
    bypass         = ["AzureServices"]
  }

  tags = var.tags
}

data "azurerm_virtual_network" "pe_vnet" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = var.private_endpoint_vnet_name
  resource_group_name = var.private_endpoint_vnet_rg_name
}

data "azurerm_subnet" "pe_subnet" {
  count                = var.enable_private_endpoint ? 1 : 0
  name                 = var.private_endpoint_subnet_name
  virtual_network_name = var.private_endpoint_vnet_name
  resource_group_name  = var.private_endpoint_vnet_rg_name
}

locals {
  sa_pe_ip = var.private_endpoint_ip_address != null ? var.private_endpoint_ip_address : (
    var.private_endpoint_ip_offset != null && var.enable_private_endpoint ? cidrhost(data.azurerm_subnet.pe_subnet[0].address_prefixes[0], var.private_endpoint_ip_offset) : null
  )
}

resource "azurerm_private_endpoint" "sa_pe" {
  count               = var.enable_private_endpoint ? length(var.private_endpoint_subresources) : 0
  name                = "${var.storage_account_name}-${var.private_endpoint_subresources[count.index]}-pe"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  subnet_id           = data.azurerm_subnet.pe_subnet[0].id

  private_service_connection {
    name                           = "${var.storage_account_name}-${var.private_endpoint_subresources[count.index]}-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.sa.id
    subresource_names              = [var.private_endpoint_subresources[count.index]]
  }

  dynamic "ip_configuration" {
    for_each = local.sa_pe_ip != null ? [1] : []
    content {
      name               = "default-ip-configuration"
      private_ip_address = local.sa_pe_ip
      subresource_name   = var.private_endpoint_subresources[count.index]
    }
  }

  lifecycle {
    precondition {
      condition     = !(var.require_static_private_endpoint_ip) || (local.sa_pe_ip != null)
      error_message = "Se requiere IP estática para los Private Endpoints de Storage (defina private_endpoint_ip_address o private_endpoint_ip_offset)."
    }
  }
}


