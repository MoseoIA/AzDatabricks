# --- variables.tf para el Módulo de Storage Account ---

# --- Variables Principales de la Cuenta de Almacenamiento ---

variable "resource_group_name" {
  type        = string
  description = "Nombre del grupo de recursos donde se creará la cuenta de almacenamiento."
}

variable "location" {
  type        = string
  description = "Ubicación/Región de Azure donde se crearán los recursos."
}

variable "storage_account_name" {
  type        = string
  description = "Nombre único global para la cuenta de almacenamiento."
}

variable "account_tier" {
  type        = string
  description = "Nivel de la cuenta de almacenamiento. Valores posibles: Standard, Premium."
  default     = "Standard"
}

variable "account_replication_type" {
  type        = string
  description = "Tipo de replicación. Valores posibles: LRS, GRS, RAGRS, ZRS."
  default     = "LRS"
}

variable "is_hns_enabled" {
  type        = bool
  description = "Si es true, habilita el espacio de nombres jerárquico para convertir la cuenta en un Azure Data Lake Storage Gen2."
  default     = false
}

# --- Variables de Red para Private Endpoints ---

variable "private_endpoint_vnet_rg_name" {
  type        = string
  description = "Nombre del grupo de recursos de la VNet para los Private Endpoints."
  default     = null
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "ID de la subred donde se desplegarán los Private Endpoints."
  default     = null
}

# --- Variables de Habilitación de Private Endpoints ---

variable "enable_private_endpoint_blob" {
  type        = bool
  description = "Si es true, crea un Private Endpoint para el servicio de Blob."
  default     = false
}

variable "enable_private_endpoint_file" {
  type        = bool
  description = "Si es true, crea un Private Endpoint para el servicio de File."
  default     = false
}

variable "enable_private_endpoint_queue" {
  type        = bool
  description = "Si es true, crea un Private Endpoint para el servicio de Queue."
  default     = false
}

variable "enable_private_endpoint_dfs" {
  type        = bool
  description = "Si es true y 'is_hns_enabled' es true, crea un Private Endpoint para el servicio DFS (Data Lake)."
  default     = false
}

# --- Variables de Integración con DNS Privado ---

variable "enable_private_dns_integration" {
  type        = bool
  description = "Si es true, se integra con Zonas DNS Privadas para la resolución de nombres de los Private Endpoints."
  default     = false
}

variable "private_dns_zone_ids" {
  type = object({
    blob  = optional(string)
    file  = optional(string)
    queue = optional(string)
    dfs   = optional(string)
  })
  description = "Un objeto con los IDs de las Zonas DNS Privadas existentes para cada tipo de servicio. Usar si 'enable_private_dns_integration' es true."
  default     = {}
}

# --- Variable de Etiquetas ---

variable "tags" {
  type        = map(string)
  description = "Un mapa de etiquetas para aplicar a todos los recursos creados."
  default     = {}
}
