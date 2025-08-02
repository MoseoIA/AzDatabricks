# --- main.tf para el Módulo de Storage Account ---

# --- DATA SOURCES ---
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# --- RECURSO PRINCIPAL: CUENTA DE ALMACENAMIENTO ---
resource "azurerm_storage_account" "sa" {
  name                     = var.storage_account_name
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  is_hns_enabled           = var.is_hns_enabled

  tags = var.tags
}

# --- RECURSOS DE PRIVATE ENDPOINT (condicionales) ---

# Private Endpoint para BLOB
resource "azurerm_private_endpoint" "pe_blob" {
  count = var.enable_private_endpoint_blob ? 1 : 0

  name                = "${var.storage_account_name}-pe-blob"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.storage_account_name}-psc-blob"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.sa.id
    subresource_names              = ["blob"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.enable_private_dns_integration && lookup(var.private_dns_zone_ids, "blob", null) != null ? [1] : []
    content {
      name                 = "default-blob"
      private_dns_zone_ids = [var.private_dns_zone_ids.blob]
    }
  }

  tags = var.tags
}

# Private Endpoint para FILE
resource "azurerm_private_endpoint" "pe_file" {
  count = var.enable_private_endpoint_file ? 1 : 0

  name                = "${var.storage_account_name}-pe-file"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.storage_account_name}-psc-file"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.sa.id
    subresource_names              = ["file"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.enable_private_dns_integration && lookup(var.private_dns_zone_ids, "file", null) != null ? [1] : []
    content {
      name                 = "default-file"
      private_dns_zone_ids = [var.private_dns_zone_ids.file]
    }
  }

  tags = var.tags
}

# Private Endpoint para QUEUE
resource "azurerm_private_endpoint" "pe_queue" {
  count = var.enable_private_endpoint_queue ? 1 : 0

  name                = "${var.storage_account_name}-pe-queue"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.storage_account_name}-psc-queue"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.sa.id
    subresource_names              = ["queue"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.enable_private_dns_integration && lookup(var.private_dns_zone_ids, "queue", null) != null ? [1] : []
    content {
      name                 = "default-queue"
      private_dns_zone_ids = [var.private_dns_zone_ids.queue]
    }
  }

  tags = var.tags
}

# Private Endpoint para DFS (Data Lake)
resource "azurerm_private_endpoint" "pe_dfs" {
  count = var.enable_private_endpoint_dfs && var.is_hns_enabled ? 1 : 0

  name                = "${var.storage_account_name}-pe-dfs"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.storage_account_name}-psc-dfs"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.sa.id
    subresource_names              = ["dfs"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.enable_private_dns_integration && lookup(var.private_dns_zone_ids, "dfs", null) != null ? [1] : []
    content {
      name                 = "default-dfs"
      private_dns_zone_ids = [var.private_dns_zone_ids.dfs]
    }
  }

  tags = var.tags
}
