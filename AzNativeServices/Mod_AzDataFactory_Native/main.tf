# --- main.tf en Mod_AzDataFactory_Native ---

# --- LOCALS ---
locals {
  dns_zone_id = var.enable_private_dns_integration ? (
    var.create_private_dns_zone ? azurerm_private_dns_zone.adf_pvdns[0].id : var.private_dns_zone_id_datafactory
  ) : null
}

# --- DATA SOURCES ---
data "azurerm_resource_group" "rg_adf" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "private_endpoint_vnet" {
  name                = var.private_endpoint_vnet_name
  resource_group_name = var.private_endpoint_vnet_rg_name
}

data "azurerm_subnet" "private_endpoint_subnet" {
  name                 = var.private_endpoint_subnet_name
  virtual_network_name = var.private_endpoint_vnet_name
  resource_group_name  = var.private_endpoint_vnet_rg_name
}

# --- AZURE RESOURCES ---

# --- Creación Opcional de la Zona DNS Privada ---
resource "azurerm_private_dns_zone" "adf_pvdns" {
  count = var.enable_private_dns_integration && var.create_private_dns_zone ? 1 : 0

  name                = var.private_dns_zone_name
  resource_group_name = data.azurerm_resource_group.rg_adf.name
  tags                = var.tags
}

# --- Creación Opcional del VNet Link para la Zona DNS ---
resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  count = var.enable_private_dns_integration && var.create_private_dns_zone ? 1 : 0

  name                  = "${var.private_endpoint_vnet_name}-link-adf"
  private_dns_zone_name = azurerm_private_dns_zone.adf_pvdns[0].name
  resource_group_name   = data.azurerm_resource_group.rg_adf.name
  virtual_network_id    = data.azurerm_virtual_network.private_endpoint_vnet.id
  registration_enabled  = false
  tags                  = var.tags
}

# --- Creación de Azure Data Factory ---
resource "azurerm_data_factory" "adf" {
  name                = var.data_factory_name
  resource_group_name = data.azurerm_resource_group.rg_adf.name
  location            = data.azurerm_resource_group.rg_adf.location
  tags                = var.tags
}

# --- Creación del Private Endpoint ---
resource "azurerm_private_endpoint" "adf_pe" {
  name                = "${var.data_factory_name}-pe"
  resource_group_name = data.azurerm_resource_group.rg_adf.name
  location            = data.azurerm_resource_group.rg_adf.location
  subnet_id           = data.azurerm_subnet.private_endpoint_subnet.id

  private_service_connection {
    name                           = "${var.data_factory_name}-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_data_factory.adf.id
    subresource_names              = ["dataFactory"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.enable_private_dns_integration ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [local.dns_zone_id]
    }
  }

  dynamic "ip_configuration" {
    for_each = var.private_endpoint_ip_address != null ? [1] : []
    content {
      name                 = "default-ip-configuration"
      private_ip_address   = var.private_endpoint_ip_address
      subresource_name     = "dataFactory"
    }
  }

  tags = var.tags
}
