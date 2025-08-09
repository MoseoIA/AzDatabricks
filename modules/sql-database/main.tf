# --- main.tf en Mod_AzSqlDatabase_Native ---

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_mssql_server" "sql" {
  name                         = var.sql_server_name
  resource_group_name          = data.azurerm_resource_group.rg.name
  location                     = data.azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.administrator_login
  administrator_login_password = var.administrator_login_password

  tags = var.tags
}
resource "azurerm_mssql_server_administrator" "aad_admin" {
  count               = var.sql_admin_group_object_id != null && var.sql_admin_group_name != null ? 1 : 0
  server_id           = azurerm_mssql_server.sql.id
  login               = var.sql_admin_group_name
  object_id           = var.sql_admin_group_object_id
  administrator_type  = "ActiveDirectory"
  azuread_authentication_only = var.azuread_authentication_only
}


resource "azurerm_mssql_database" "db" {
  name           = var.database_name
  server_id      = azurerm_mssql_server.sql.id
  sku_name       = var.sku_name
  zone_redundant = false

  tags = var.tags
}

# Reglas públicas opcionales: firewall del servidor
resource "azurerm_mssql_firewall_rule" "public_ips" {
  for_each         = toset(var.allowed_public_ips)
  name             = replace(each.value, "/", "-")
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = split("/", each.value)[0]
  end_ip_address   = split("/", each.value)[0]
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
  sql_pe_ip = var.private_endpoint_ip_address != null ? var.private_endpoint_ip_address : (
    var.private_endpoint_ip_offset != null && var.enable_private_endpoint ? cidrhost(data.azurerm_subnet.pe_subnet[0].address_prefixes[0], var.private_endpoint_ip_offset) : null
  )
}

resource "azurerm_private_endpoint" "sql_pe" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.sql_server_name}-pe"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  subnet_id           = data.azurerm_subnet.pe_subnet[0].id

  private_service_connection {
    name                           = "${var.sql_server_name}-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_mssql_server.sql.id
    subresource_names              = ["sqlServer"]
  }

  dynamic "ip_configuration" {
    for_each = local.sql_pe_ip != null ? [1] : []
    content {
      name               = "default-ip-configuration"
      private_ip_address = local.sql_pe_ip
      subresource_name   = "sqlServer"
    }
  }

  lifecycle {
    precondition {
      condition     = !(var.require_static_private_endpoint_ip) || (local.sql_pe_ip != null)
      error_message = "Se requiere IP estática para el Private Endpoint de SQL (defina private_endpoint_ip_address o private_endpoint_ip_offset)."
    }
  }
}

