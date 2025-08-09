variable "resource_group_name" {
  type        = string
  description = "Nombre del Resource Group donde se desplegarán los recursos. Debe existir previamente."
}

variable "tags" {
  type        = map(string)
  description = "Etiquetas comunes para todos los recursos."
  default     = {}
}

# Data Factory
variable "data_factory_name" {
  type        = string
  description = "Nombre de la instancia de Azure Data Factory."
}

variable "adf_private_endpoint_vnet_name" {
  type        = string
  description = "Nombre de la VNet donde se creará el Private Endpoint de ADF."
}

variable "adf_private_endpoint_vnet_rg_name" {
  type        = string
  description = "Resource Group de la VNet para el Private Endpoint de ADF."
}

variable "adf_private_endpoint_subnet_name" {
  type        = string
  description = "Subnet para el Private Endpoint de ADF."
}

variable "adf_enable_private_dns_integration" {
  type        = bool
  description = "Habilita la integración con Private DNS para ADF."
  default     = true
}

variable "adf_create_private_dns_zone" {
  type        = bool
  description = "Crea la zona DNS privada para ADF si es true."
  default     = false
}

variable "adf_private_dns_zone_name" {
  type        = string
  description = "Nombre de la zona DNS privada para ADF (si se crea)."
  default     = "privatelink.datafactory.azure.net"
}

variable "adf_private_dns_zone_id" {
  type        = string
  description = "ID de una zona DNS privada existente para ADF (si no se crea)."
  default     = null
}

variable "adf_private_endpoint_ip_address" {
  type        = string
  description = "IP privada deseada para el Private Endpoint de ADF (opcional)."
  default     = null
}

variable "adf_private_endpoint_ip_offset" {
  type        = number
  description = "Offset para calcular la IP del PE de ADF usando cidrhost(subnet_cidr, offset)."
  default     = null
}

# Databricks
variable "databricks_workspace_name" {
  type        = string
  description = "Nombre del Workspace de Databricks."
}

variable "databricks_managed_resource_group_name" {
  type        = string
  description = "Nombre del Managed Resource Group de Databricks."
}

variable "databricks_sku" {
  type        = string
  description = "SKU del workspace de Databricks."
  default     = "premium"
}

variable "databricks_vnet_name" {
  type        = string
  description = "VNet donde residen las subnets de Databricks (VNet Injection)."
}

variable "databricks_vnet_rg_name" {
  type        = string
  description = "Resource Group de la VNet de Databricks."
}

variable "databricks_public_subnet_name" {
  type        = string
  description = "Nombre de la subnet pública para Databricks."
}

variable "databricks_private_subnet_name" {
  type        = string
  description = "Nombre de la subnet privada para Databricks."
}

variable "public_subnet_nsg_id" {
  type        = string
  description = "ID del NSG asociado a la subnet pública de Databricks."
}

variable "private_subnet_nsg_id" {
  type        = string
  description = "ID del NSG asociado a la subnet privada de Databricks."
}

variable "db_private_endpoint_vnet_name" {
  type        = string
  description = "VNet donde se creará el Private Endpoint de Databricks."
}

variable "db_private_endpoint_vnet_rg_name" {
  type        = string
  description = "Resource Group de la VNet del Private Endpoint de Databricks."
}

variable "db_private_endpoint_subnet_name" {
  type        = string
  description = "Subnet para el Private Endpoint de Databricks."
}

variable "db_private_endpoint_ip_address" {
  type        = string
  description = "IP privada fija para el PE de Databricks (opcional)."
  default     = null
}

variable "db_private_endpoint_ip_offset" {
  type        = number
  description = "Offset para calcular la IP del PE de Databricks usando cidrhost(subnet_cidr, offset)."
  default     = null
}

# SQL Database
variable "enable_sql_database" {
  type        = bool
  description = "Si true, despliega SQL Server y Database."
  default     = false
}

variable "sql_server_name" {
  type        = string
  description = "Nombre del servidor SQL."
  default     = null
}

variable "sql_database_name" {
  type        = string
  description = "Nombre de la base de datos."
  default     = null
}

variable "sql_sku_name" {
  type        = string
  description = "SKU de la base de datos."
  default     = "GP_S_Gen5_2"
}

variable "sql_administrator_login" {
  type        = string
  description = "Usuario admin del servidor SQL."
  default     = null
}

variable "sql_administrator_login_password" {
  type        = string
  description = "Password admin del servidor SQL (suministrar por variable segura)."
  default     = null
}

variable "sql_admin_group_object_id" {
  type        = string
  description = "Object ID del grupo de Entra ID para SQL admin."
  default     = null
}

variable "sql_admin_group_name" {
  type        = string
  description = "Nombre/login del grupo de Entra ID para SQL admin."
  default     = null
}

variable "sql_azuread_authentication_only" {
  type        = bool
  description = "Forzar auth solo Azure AD."
  default     = true
}

variable "sql_private_endpoint_vnet_name" {
  type        = string
  description = "VNet para PE de SQL."
  default     = null
}

variable "sql_private_endpoint_vnet_rg_name" {
  type        = string
  description = "RG de la VNet de PE de SQL."
  default     = null
}

variable "sql_private_endpoint_subnet_name" {
  type        = string
  description = "Subnet de PE de SQL."
  default     = null
}

variable "sql_private_endpoint_ip_address" {
  type        = string
  description = "IP fija del PE de SQL."
  default     = null
}

variable "sql_private_endpoint_ip_offset" {
  type        = number
  description = "Offset para IP del PE de SQL."
  default     = null
}

variable "sql_allowed_public_ips" {
  type        = list(string)
  description = "IPs públicas permitidas para el servidor SQL (firewall)."
  default     = []
}

variable "db_enable_private_dns_integration" {
  type        = bool
  description = "Habilita la integración con Private DNS para Databricks."
  default     = true
}

variable "db_create_private_dns_zone" {
  type        = bool
  description = "Crea la zona DNS privada para Databricks si es true."
  default     = false
}

variable "db_private_dns_zone_name" {
  type        = string
  description = "Nombre de la zona DNS privada para Databricks (si se crea)."
  default     = "privatelink.azuredatabricks.net"
}

variable "db_private_dns_zone_id" {
  type        = string
  description = "ID de una zona DNS privada existente para Databricks (si no se crea)."
  default     = null
}

variable "db_create_storage_account" {
  type        = bool
  description = "Si true, crea una cuenta de almacenamiento para Databricks."
  default     = false
}

variable "db_storage_account_name" {
  type        = string
  description = "Nombre de la cuenta de almacenamiento (requerido si se crea)."
  default     = null
}


