# --- variables.tf en Mod_AzDatabricks_Native ---
# Este archivo define todas las variables de entrada que el módulo acepta.

# --- Variables del Workspace de Databricks ---

variable "resource_group_name" {
  type        = string
  description = "Nombre del grupo de recursos donde se creará el Databricks."
}

variable "workspace_name" {
  type        = string
  description = "Nombre para el espacio de trabajo de Databricks."
}

variable "managed_resource_group_name" {
  type        = string
  description = "Nombre del grupo de recursos que será gestionado por Databricks."
}

variable "sku" {
  type        = string
  default     = "premium"
  description = "SKU para el workspace. 'premium' es requerido para Private Link y VNet Injection."
}

# --- Variables de Red para Databricks (VNet Injection) ---

variable "databricks_vnet_name" {
  type        = string
  description = "Nombre de la VNet para las subnets de Databricks."
}

variable "databricks_vnet_rg_name" {
  type        = string
  description = "Nombre del grupo de recursos de la VNet de Databricks."
}

variable "databricks_public_subnet_name" {
  type        = string
  description = "Nombre de la subnet pública para Databricks."
}

variable "databricks_private_subnet_name" {
  type        = string
  description = "Nombre de la subnet privada para Databricks."
}

# --- NUEVAS VARIABLES PARA LOS NSG ---
variable "public_subnet_nsg_id" {
  type        = string
  description = "El ID del Network Security Group para la subnet pública."
}

variable "private_subnet_nsg_id" {
  type        = string
  description = "El ID del Network Security Group para la subnet privada."
}

# --- Variables de Red para el Private Endpoint ---

variable "private_endpoint_vnet_name" {
  type        = string
  description = "Nombre de la VNet donde se creará el Private Endpoint."
}

variable "private_endpoint_vnet_rg_name" {
  type        = string
  description = "Nombre del grupo de recursos de la VNet del Private Endpoint."
}

variable "private_endpoint_subnet_name" {
  type        = string
  description = "Nombre de la subnet para el Private Endpoint."
}

# --- Variables de DNS Privado ---

variable "enable_private_dns_integration" {
  type        = bool
  description = "Interruptor principal. Si es true, se habilita la integración con Zonas DNS Privadas. Si es false, el Private Endpoint se crea sin asociación a DNS."
  default     = true
}

variable "create_private_dns_zone" {
  type        = bool
  description = "Si es true, el módulo creará una nueva Zona DNS Privada. Solo es relevante si enable_private_dns_integration es true."
  default     = false
}

variable "private_dns_zone_name" {
  type        = string
  description = "Nombre de la Zona DNS Privada a crear. Relevante solo si create_private_dns_zone es true."
  default     = "privatelink.azuredatabricks.net"
}

variable "private_dns_zone_id_databricks" {
  type        = string
  description = "ID de una Zona DNS Privada existente. Usar solo si enable_private_dns_integration es true y create_private_dns_zone es false."
  default     = null
}

# --- Variables para la Cuenta de Almacenamiento Opcional ---

variable "create_storage_account" {
  type        = bool
  description = "Si se establece en true, crea una cuenta de almacenamiento dedicada para Databricks."
  default     = false
}

variable "storage_account_name" {
  type        = string
  description = "Nombre único global para la cuenta de almacenamiento. Requerido si create_storage_account es true."
  default     = null
}

# --- Variable de Etiquetas ---

variable "tags" {
  type        = map(string)
  description = "Un mapa de etiquetas para aplicar a todos los recursos creados."
  default     = {}
}
