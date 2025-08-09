variable "project_name" {
  type    = string
  default = "proyecto04"
}

variable "resource_group_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enable_data_factory" {
  type    = bool
  default = false
}

variable "enable_databricks" {
  type    = bool
  default = false
}

variable "enable_storage" {
  type    = bool
  default = false
}

variable "enable_key_vault" {
  type    = bool
  default = false
}

variable "data_factory_name" {
  type    = string
  default = null
}
variable "adf_private_endpoint_vnet_name" {
  type    = string
  default = null
}
variable "adf_private_endpoint_vnet_rg_name" {
  type    = string
  default = null
}
variable "adf_private_endpoint_subnet_name" {
  type    = string
  default = null
}
variable "adf_enable_private_dns_integration" {
  type    = bool
  default = true
}
variable "adf_create_private_dns_zone" {
  type    = bool
  default = false
}
variable "adf_private_dns_zone_name" {
  type    = string
  default = "privatelink.datafactory.azure.net"
}
variable "adf_private_dns_zone_id" {
  type    = string
  default = null
}
variable "adf_private_endpoint_ip_address" {
  type    = string
  default = null
}
variable "adf_private_endpoint_ip_offset" {
  type    = number
  default = null
}

variable "databricks_workspace_name" {
  type    = string
  default = null
}
variable "databricks_managed_resource_group_name" {
  type    = string
  default = null
}
variable "databricks_sku" {
  type    = string
  default = "premium"
}
variable "databricks_vnet_name" {
  type    = string
  default = null
}
variable "databricks_vnet_rg_name" {
  type    = string
  default = null
}
variable "databricks_public_subnet_name" {
  type    = string
  default = null
}
variable "databricks_private_subnet_name" {
  type    = string
  default = null
}
variable "public_subnet_nsg_id" {
  type    = string
  default = null
}
variable "private_subnet_nsg_id" {
  type    = string
  default = null
}
variable "db_private_endpoint_vnet_name" {
  type    = string
  default = null
}
variable "db_private_endpoint_vnet_rg_name" {
  type    = string
  default = null
}
variable "db_private_endpoint_subnet_name" {
  type    = string
  default = null
}
variable "db_private_endpoint_ip_address" {
  type    = string
  default = null
}
variable "db_private_endpoint_ip_offset" {
  type    = number
  default = null
}
variable "db_enable_private_dns_integration" {
  type    = bool
  default = true
}
variable "db_create_private_dns_zone" {
  type    = bool
  default = false
}
variable "db_private_dns_zone_name" {
  type    = string
  default = "privatelink.azuredatabricks.net"
}
variable "db_private_dns_zone_id" {
  type    = string
  default = null
}
variable "db_create_storage_account" {
  type    = bool
  default = false
}
variable "db_storage_account_name" {
  type    = string
  default = null
}

# Storage Account - Private Endpoint y reglas públicas
variable "storage_private_endpoint_vnet_name" {
  type    = string
  default = null
}
variable "storage_private_endpoint_vnet_rg_name" {
  type    = string
  default = null
}
variable "storage_private_endpoint_subnet_name" {
  type    = string
  default = null
}
variable "storage_private_endpoint_ip_address" {
  type    = string
  default = null
}
variable "storage_private_endpoint_ip_offset" {
  type    = number
  default = null
}
variable "storage_enable_private_endpoint" {
  type    = bool
  default = true
}
variable "storage_allowed_public_ips" {
  type    = list(string)
  default = []
}

# Key Vault - Private Endpoint y reglas públicas
variable "kv_private_endpoint_vnet_name" {
  type    = string
  default = null
}
variable "kv_private_endpoint_vnet_rg_name" {
  type    = string
  default = null
}
variable "kv_private_endpoint_subnet_name" {
  type    = string
  default = null
}
variable "kv_private_endpoint_ip_address" {
  type    = string
  default = null
}
variable "kv_private_endpoint_ip_offset" {
  type    = number
  default = null
}
variable "key_vault_enable_private_endpoint" {
  type    = bool
  default = true
}
variable "key_vault_allowed_public_ips" {
  type    = list(string)
  default = []
}

variable "storage_account_name" {
  type    = string
  default = null
}
variable "storage_account_tier" {
  type    = string
  default = "Standard"
}
variable "storage_replication_type" {
  type    = string
  default = "LRS"
}
variable "storage_is_hns_enabled" {
  type    = bool
  default = false
}
variable "storage_min_tls_version" {
  type    = string
  default = "TLS1_2"
}

variable "key_vault_name" {
  type    = string
  default = null
}
variable "key_vault_sku" {
  type    = string
  default = "standard"
}
variable "key_vault_enable_rbac" {
  type    = bool
  default = true
}
variable "key_vault_soft_delete_retention_days" {
  type    = number
  default = 7
}
variable "key_vault_purge_protection" {
  type    = bool
  default = true
}
variable "key_vault_public_network_access" {
  type    = bool
  default = false
}

# SQL Database
variable "enable_sql_database" {
  type    = bool
  default = false
}
variable "sql_server_name" {
  type    = string
  default = null
}
variable "sql_database_name" {
  type    = string
  default = null
}
variable "sql_sku_name" {
  type    = string
  default = "GP_S_Gen5_2"
}
variable "sql_administrator_login" {
  type    = string
  default = null
}
variable "sql_administrator_login_password" {
  type    = string
  default = null
}
variable "sql_admin_group_object_id" {
  type    = string
  default = null
}
variable "sql_admin_group_name" {
  type    = string
  default = null
}
variable "sql_azuread_authentication_only" {
  type    = bool
  default = true
}
variable "sql_private_endpoint_vnet_name" {
  type    = string
  default = null
}
variable "sql_private_endpoint_vnet_rg_name" {
  type    = string
  default = null
}
variable "sql_private_endpoint_subnet_name" {
  type    = string
  default = null
}
variable "sql_private_endpoint_ip_address" {
  type    = string
  default = null
}
variable "sql_private_endpoint_ip_offset" {
  type    = number
  default = null
}
variable "sql_allowed_public_ips" {
  type    = list(string)
  default = []
}


