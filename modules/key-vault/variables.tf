# --- variables.tf para el Módulo de Key Vault ---

# --- Variables Principales del Key Vault ---

variable "resource_group_name" {
  type        = string
  description = "Nombre del grupo de recursos donde se creará el Key Vault."
}

variable "location" {
  type        = string
  description = "Ubicación/Región de Azure donde se crearán los recursos."
}

variable "key_vault_name" {
  type        = string
  description = "Nombre único global para el Key Vault."
}

variable "sku_name" {
  type        = string
  description = "SKU del Key Vault. Valores posibles: standard, premium."
  default     = "standard"
}

# --- Variables de Configuración de Seguridad ---

variable "enabled_for_disk_encryption" {
  type        = bool
  description = "Permite que las máquinas virtuales recuperen certificados almacenados como secretos de este Key Vault."
  default     = false
}

variable "soft_delete_retention_days" {
  type        = number
  description = "Número de días que se retienen los secretos eliminados."
  default     = 7
}

variable "purge_protection_enabled" {
  type        = bool
  description = "Si es true, habilita la protección contra purga, haciendo la eliminación irreversible."
  default     = false
}

# --- Variables para Políticas de Acceso ---

variable "access_policies" {
  type = list(object({
    object_id = string
    key_permissions         = list(string)
    secret_permissions      = list(string)
    certificate_permissions = list(string)
    storage_permissions     = list(string)
  }))
  description = "Una lista de objetos que definen las políticas de acceso para el Key Vault. El ID de tenant se obtiene automáticamente."
  default     = []
}

# --- Variables de Red para Private Endpoint ---

variable "enable_private_endpoint" {
  type        = bool
  description = "Si es true, crea un Private Endpoint para el Key Vault."
  default     = false
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "ID de la subred donde se desplegará el Private Endpoint."
  default     = null
}

# --- Variables de Integración con DNS Privado ---

variable "enable_private_dns_integration" {
  type        = bool
  description = "Si es true, se integra con una Zona DNS Privada para la resolución de nombres."
  default     = false
}

variable "private_dns_zone_id" {
  type        = string
  description = "ID de la Zona DNS Privada existente para 'privatelink.vaultcore.azure.net'."
  default     = null
}

# --- Variable de Etiquetas ---

variable "tags" {
  type        = map(string)
  description = "Un mapa de etiquetas para aplicar a todos los recursos creados."
  default     = {}
}
