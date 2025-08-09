# --- variables.tf en Mod_AzKeyVault_Native ---

variable "resource_group_name" {
  type        = string
  description = "Nombre del grupo de recursos donde se creará el Key Vault."
}

variable "key_vault_name" {
  type        = string
  description = "Nombre del Key Vault (3-24 caracteres, letras y números)."
}

variable "sku_name" {
  type        = string
  description = "SKU del Key Vault (standard o premium)."
  default     = "standard"
}

variable "enable_rbac_authorization" {
  type        = bool
  description = "Si true, habilita RBAC en lugar de políticas de acceso."
  default     = true
}

variable "soft_delete_retention_days" {
  type        = number
  description = "Días de retención para soft delete."
  default     = 7
}

variable "purge_protection_enabled" {
  type        = bool
  description = "Protección contra purga."
  default     = true
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Permite acceso por red pública."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Mapa de etiquetas."
  default     = {}
}

# --- Private Endpoint opcional ---
variable "enable_private_endpoint" {
  type        = bool
  description = "Si true, crea Private Endpoint para Key Vault."
  default     = true
}

variable "private_endpoint_vnet_name" {
  type        = string
  description = "VNet donde se creará el PE."
  default     = null
}

variable "private_endpoint_vnet_rg_name" {
  type        = string
  description = "RG de la VNet del PE."
  default     = null
}

variable "private_endpoint_subnet_name" {
  type        = string
  description = "Subnet del PE."
  default     = null
}

variable "private_endpoint_ip_address" {
  type        = string
  description = "IP fija del PE."
  default     = null
}

variable "private_endpoint_ip_offset" {
  type        = number
  description = "Offset para calcular IP del PE con cidrhost()."
  default     = null
}

variable "allowed_public_ips" {
  type        = list(string)
  description = "IPs/CIDRs permitidos si se habilita acceso público."
  default     = []
}


