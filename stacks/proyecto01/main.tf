locals {
  common_tags = merge({
    project = var.project_name
  }, var.tags)
}

module "data_factory" {
  count = var.enable_data_factory ? 1 : 0
  source = "../../modules/data-factory"

  resource_group_name             = var.resource_group_name
  data_factory_name               = var.data_factory_name
  private_endpoint_vnet_name      = var.adf_private_endpoint_vnet_name
  private_endpoint_vnet_rg_name   = var.adf_private_endpoint_vnet_rg_name
  private_endpoint_subnet_name    = var.adf_private_endpoint_subnet_name
  enable_private_dns_integration  = var.adf_enable_private_dns_integration
  create_private_dns_zone         = var.adf_create_private_dns_zone
  private_dns_zone_name           = var.adf_private_dns_zone_name
  private_dns_zone_id_datafactory = var.adf_private_dns_zone_id
  private_endpoint_ip_address     = var.adf_private_endpoint_ip_address
  private_endpoint_ip_offset      = var.adf_private_endpoint_ip_offset
  tags                            = local.common_tags
}

module "databricks_workspace" {
  count = var.enable_databricks ? 1 : 0
  source = "../../modules/databricks-workspace"

  resource_group_name             = var.resource_group_name
  workspace_name                  = var.databricks_workspace_name
  managed_resource_group_name     = var.databricks_managed_resource_group_name
  sku                             = var.databricks_sku

  databricks_vnet_name            = var.databricks_vnet_name
  databricks_vnet_rg_name         = var.databricks_vnet_rg_name
  databricks_public_subnet_name   = var.databricks_public_subnet_name
  databricks_private_subnet_name  = var.databricks_private_subnet_name
  public_subnet_nsg_id            = var.public_subnet_nsg_id
  private_subnet_nsg_id           = var.private_subnet_nsg_id

  private_endpoint_vnet_name      = var.db_private_endpoint_vnet_name
  private_endpoint_vnet_rg_name   = var.db_private_endpoint_vnet_rg_name
  private_endpoint_subnet_name    = var.db_private_endpoint_subnet_name
  private_endpoint_ip_address     = var.db_private_endpoint_ip_address
  private_endpoint_ip_offset      = var.db_private_endpoint_ip_offset

  enable_private_dns_integration  = var.db_enable_private_dns_integration
  create_private_dns_zone         = var.db_create_private_dns_zone
  private_dns_zone_name           = var.db_private_dns_zone_name
  private_dns_zone_id_databricks  = var.db_private_dns_zone_id

  create_storage_account          = var.db_create_storage_account
  storage_account_name            = var.db_storage_account_name

  tags = local.common_tags
}

module "storage_account" {
  count = var.enable_storage ? 1 : 0
  source = "../../modules/storage-account"

  resource_group_name      = var.resource_group_name
  storage_account_name     = var.storage_account_name
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type
  is_hns_enabled           = var.storage_is_hns_enabled
  min_tls_version          = var.storage_min_tls_version
  enable_private_endpoint  = var.storage_enable_private_endpoint
  private_endpoint_vnet_name     = var.storage_private_endpoint_vnet_name
  private_endpoint_vnet_rg_name  = var.storage_private_endpoint_vnet_rg_name
  private_endpoint_subnet_name   = var.storage_private_endpoint_subnet_name
  private_endpoint_ip_address    = var.storage_private_endpoint_ip_address
  private_endpoint_ip_offset     = var.storage_private_endpoint_ip_offset
  allowed_public_ips        = var.storage_allowed_public_ips
  tags                     = local.common_tags
}

module "key_vault" {
  count = var.enable_key_vault ? 1 : 0
  source = "../../modules/keyvault"

  resource_group_name           = var.resource_group_name
  key_vault_name                = var.key_vault_name
  sku_name                      = var.key_vault_sku
  enable_rbac_authorization     = var.key_vault_enable_rbac
  soft_delete_retention_days    = var.key_vault_soft_delete_retention_days
  purge_protection_enabled      = var.key_vault_purge_protection
  public_network_access_enabled = var.key_vault_public_network_access
  enable_private_endpoint       = var.key_vault_enable_private_endpoint
  private_endpoint_vnet_name    = var.kv_private_endpoint_vnet_name
  private_endpoint_vnet_rg_name = var.kv_private_endpoint_vnet_rg_name
  private_endpoint_subnet_name  = var.kv_private_endpoint_subnet_name
  private_endpoint_ip_address   = var.kv_private_endpoint_ip_address
  private_endpoint_ip_offset    = var.kv_private_endpoint_ip_offset
  allowed_public_ips            = var.key_vault_allowed_public_ips
  tags                          = local.common_tags
}

module "sql_database" {
  count  = var.enable_sql_database ? 1 : 0
  source = "../../modules/sql-database"

  resource_group_name                 = var.resource_group_name
  sql_server_name                     = var.sql_server_name
  administrator_login                 = var.sql_administrator_login
  administrator_login_password        = var.sql_administrator_login_password
  database_name                       = var.sql_database_name
  sku_name                            = var.sql_sku_name
  sql_admin_group_object_id           = var.sql_admin_group_object_id
  sql_admin_group_name                = var.sql_admin_group_name
  azuread_authentication_only         = var.sql_azuread_authentication_only
  enable_private_endpoint             = true
  private_endpoint_vnet_name          = var.sql_private_endpoint_vnet_name
  private_endpoint_vnet_rg_name       = var.sql_private_endpoint_vnet_rg_name
  private_endpoint_subnet_name        = var.sql_private_endpoint_subnet_name
  private_endpoint_ip_address         = var.sql_private_endpoint_ip_address
  private_endpoint_ip_offset          = var.sql_private_endpoint_ip_offset
  allowed_public_ips                  = var.sql_allowed_public_ips
  tags                                = local.common_tags
}


