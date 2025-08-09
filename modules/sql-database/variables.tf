# --- variables.tf en Mod_AzSqlDatabase_Native ---

variable "resource_group_name" {
  type        = string
  description = "RG donde se crearán el servidor SQL y/o la base de datos."
}

variable "sql_server_name" {
  type        = string
  description = "Nombre del servidor SQL."
}

variable "administrator_login" {
  type        = string
  description = "Usuario administrador del servidor SQL."
}

variable "administrator_login_password" {
  type        = string
  description = "Password del administrador del servidor SQL."
  sensitive   = true
}

variable "database_name" {
  type        = string
  description = "Nombre de la base de datos."
}

variable "sku_name" {
  type        = string
  description = "SKU de la base de datos (por ejemplo, GP_S_Gen5_2)."
  default     = "GP_S_Gen5_2"
}

variable "tags" {
  type        = map(string)
  default     = {}
}

# Private Endpoint opcional
variable "enable_private_endpoint" {
  type        = bool
  default     = true
}

variable "private_endpoint_vnet_name" {
  type        = string
  default     = null
}

variable "private_endpoint_vnet_rg_name" {
  type        = string
  default     = null
}

variable "private_endpoint_subnet_name" {
  type        = string
  default     = null
}

variable "private_endpoint_ip_address" {
  type        = string
  default     = null
}

variable "private_endpoint_ip_offset" {
  type        = number
  default     = null
}

variable "require_static_private_endpoint_ip" {
  type        = bool
  default     = true
}

# Reglas públicas opcionales (si se habilitan a nivel de servidor)
variable "allowed_public_ips" {
  type        = list(string)
  default     = []
}

# Azure AD (Entra ID) administrador del servidor SQL
variable "sql_admin_group_object_id" {
  type        = string
  description = "Object ID del grupo de Entra ID que será Azure AD admin del servidor SQL."
  default     = null
}

variable "sql_admin_group_name" {
  type        = string
  description = "Nombre/login del grupo de Entra ID que será Azure AD admin del servidor SQL."
  default     = null
}

variable "azuread_authentication_only" {
  type        = bool
  description = "Si true, fuerza autenticación solo Azure AD en el servidor SQL."
  default     = true
}

