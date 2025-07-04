# --- main.tf en Mod_AzDatabricks_Native ---
# Versión final con integración de DNS completamente opcional.

# --- LOCALS ---
# Variables locales para simplificar la lógica condicional.
locals {
  # Decide qué ID de zona DNS usar, solo si la integración DNS está habilitada.
  dns_zone_id = var.enable_private_dns_integration ? (
    var.create_private_dns_zone ? azurerm_private_dns_zone.databricks_pvdns[0].id : var.private_dns_zone_id_databricks
  ) : null
}

# --- DATA SOURCES ---
data "azurerm_resource_group" "rg_databricks" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "databricks_vnet" {
  name                = var.databricks_vnet_name
  resource_group_name = var.databricks_vnet_rg_name
}

data "azurerm_virtual_network" "private_endpoint_vnet" {
  name                = var.private_endpoint_vnet_name
  resource_group_name = var.private_endpoint_vnet_rg_name
}

data "azurerm_subnet" "databricks_public_subnet" {
  name                 = var.databricks_public_subnet_name
  virtual_network_name = var.databricks_vnet_name
  resource_group_name  = var.databricks_vnet_rg_name
}

data "azurerm_subnet" "databricks_private_subnet" {
  name                 = var.databricks_private_subnet_name
  virtual_network_name = var.databricks_vnet_name
  resource_group_name  = var.databricks_vnet_rg_name
}

data "azurerm_subnet" "private_endpoint_subnet" {
  name                 = var.private_endpoint_subnet_name
  virtual_network_name = var.private_endpoint_vnet_name
  resource_group_name  = var.private_endpoint_vnet_rg_name
}


# --- AZURE RESOURCES ---

# --- Creación Opcional de la Zona DNS Privada ---
resource "azurerm_private_dns_zone" "databricks_pvdns" {
  count = var.enable_private_dns_integration && var.create_private_dns_zone ? 1 : 0

  name                = var.private_dns_zone_name
  resource_group_name = data.azurerm_resource_group.rg_databricks.name
  tags                = var.tags
}

# --- Creación Opcional del VNet Link para la Zona DNS ---
resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  count = var.enable_private_dns_integration && var.create_private_dns_zone ? 1 : 0

  name                  = "${var.private_endpoint_vnet_name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.databricks_pvdns[0].name
  resource_group_name   = data.azurerm_resource_group.rg_databricks.name
  virtual_network_id    = data.azurerm_virtual_network.private_endpoint_vnet.id
  registration_enabled  = false
  tags                  = var.tags
}


# --- Creación del Workspace de Azure Databricks ---
resource "azurerm_databricks_workspace" "databricks_ws" {
  name                          = var.workspace_name
  resource_group_name           = data.azurerm_resource_group.rg_databricks.name
  location                      = data.azurerm_resource_group.rg_databricks.location
  sku                           = var.sku
  managed_resource_group_name   = var.managed_resource_group_name
  public_network_access_enabled = false

  custom_parameters {
    no_public_ip        = true
    public_subnet_name  = data.azurerm_subnet.databricks_public_subnet.name
    private_subnet_name = data.azurerm_subnet.databricks_private_subnet.name
    virtual_network_id  = data.azurerm_virtual_network.databricks_vnet.id
  }

  tags = var.tags
}

# --- Creación del Private Endpoint ---
resource "azurerm_private_endpoint" "databricks_pe" {
  name                = "${var.workspace_name}-pe"
  resource_group_name = data.azurerm_resource_group.rg_databricks.name
  location            = data.azurerm_resource_group.rg_databricks.location
  subnet_id           = data.azurerm_subnet.private_endpoint_subnet.id

  private_service_connection {
    name                           = "${var.workspace_name}-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_databricks_workspace.databricks_ws.id
    subresource_names              = ["databricks_ui_api"]
  }

  # --- BLOQUE DINÁMICO ---
  # Este bloque 'private_dns_zone_group' solo se creará si var.enable_private_dns_integration es true.
  dynamic "private_dns_zone_group" {
    for_each = var.enable_private_dns_integration ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [local.dns_zone_id]
    }
  }

  tags = var.tags
}

# --- Creación Opcional de la Cuenta de Almacenamiento ---
resource "azurerm_storage_account" "storage_for_databricks" {
  count = var.create_storage_account ? 1 : 0

  name                     = var.storage_account_name
  resource_group_name      = data.azurerm_resource_group.rg_databricks.name
  location                 = data.azurerm_resource_group.rg_databricks.location
  
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true 

  tags = var.tags
}
