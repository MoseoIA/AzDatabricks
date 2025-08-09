# --- main.tf en Mod_AzKeyVault_Native ---

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_key_vault" "kv" {
  name                        = var.key_vault_name
  resource_group_name         = data.azurerm_resource_group.rg.name
  location                    = data.azurerm_resource_group.rg.location
  sku_name                    = var.sku_name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  enable_rbac_authorization   = var.enable_rbac_authorization
  soft_delete_retention_days  = var.soft_delete_retention_days
  purge_protection_enabled    = var.purge_protection_enabled
  public_network_access_enabled = var.public_network_access_enabled

  dynamic "network_acls" {
    for_each = var.public_network_access_enabled && length(var.allowed_public_ips) > 0 ? [1] : []
    content {
      default_action = "Deny"
      bypass         = "AzureServices"
      ip_rules       = var.allowed_public_ips
      virtual_network_subnet_ids = []
    }
  }

  tags = var.tags
}

data "azurerm_client_config" "current" {}

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
  kv_pe_ip = var.private_endpoint_ip_address != null ? var.private_endpoint_ip_address : (
    var.private_endpoint_ip_offset != null && var.enable_private_endpoint ? cidrhost(data.azurerm_subnet.pe_subnet[0].address_prefixes[0], var.private_endpoint_ip_offset) : null
  )
}

resource "azurerm_private_endpoint" "kv_pe" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.key_vault_name}-pe"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  subnet_id           = data.azurerm_subnet.pe_subnet[0].id

  private_service_connection {
    name                           = "${var.key_vault_name}-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_key_vault.kv.id
    subresource_names              = ["vault"]
  }

  dynamic "ip_configuration" {
    for_each = local.kv_pe_ip != null ? [1] : []
    content {
      name               = "default-ip-configuration"
      private_ip_address = local.kv_pe_ip
      subresource_name   = "vault"
    }
  }
}


