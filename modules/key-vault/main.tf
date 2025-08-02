# --- main.tf para el Módulo de Key Vault ---

# --- DATA SOURCES ---
data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# --- RECURSO PRINCIPAL: KEY VAULT ---
resource "azurerm_key_vault" "kv" {
  name                        = var.key_vault_name
  resource_group_name         = data.azurerm_resource_group.rg.name
  location                    = var.location
  sku_name                    = var.sku_name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  
  enabled_for_disk_encryption = var.enabled_for_disk_encryption
  soft_delete_retention_days  = var.soft_delete_retention_days
  purge_protection_enabled    = var.purge_protection_enabled

  # Bloque dinámico para crear políticas de acceso
  dynamic "access_policy" {
    for_each = var.access_policies
    content {
      tenant_id = data.azurerm_client_config.current.tenant_id
      object_id = access_policy.value.object_id

      key_permissions         = lookup(access_policy.value, "key_permissions", [])
      secret_permissions      = lookup(access_policy.value, "secret_permissions", [])
      certificate_permissions = lookup(access_policy.value, "certificate_permissions", [])
      storage_permissions     = lookup(access_policy.value, "storage_permissions", [])
    }
  }

  tags = var.tags
}

# --- RECURSO DE PRIVATE ENDPOINT (condicional) ---
resource "azurerm_private_endpoint" "pe_kv" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "${var.key_vault_name}-pe"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.key_vault_name}-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_key_vault.kv.id
    subresource_names              = ["vault"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.enable_private_dns_integration && var.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "default-kv"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }

  tags = var.tags
}
