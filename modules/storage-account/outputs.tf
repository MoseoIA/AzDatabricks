# --- outputs.tf para el Módulo de Storage Account ---

output "storage_account_id" {
  value       = azurerm_storage_account.sa.id
  description = "El ID del recurso de la cuenta de almacenamiento."
}

output "primary_blob_endpoint" {
  value       = azurerm_storage_account.sa.primary_blob_endpoint
  description = "El endpoint primario para el servicio de Blob."
}

output "primary_dfs_endpoint" {
  value       = var.is_hns_enabled ? azurerm_storage_account.sa.primary_dfs_endpoint : null
  description = "El endpoint primario para el servicio DFS (Data Lake). Es nulo si la cuenta no es un Data Lake."
}

output "primary_file_endpoint" {
  value       = azurerm_storage_account.sa.primary_file_endpoint
  description = "El endpoint primario para el servicio de File."
}

output "primary_queue_endpoint" {
  value       = azurerm_storage_account.sa.primary_queue_endpoint
  description = "El endpoint primario para el servicio de Queue."
}

output "private_endpoint_blob_id" {
  value       = length(azurerm_private_endpoint.pe_blob) > 0 ? azurerm_private_endpoint.pe_blob[0].id : null
  description = "El ID del Private Endpoint para el servicio de Blob. Es nulo si no se creó."
}

output "private_endpoint_file_id" {
  value       = length(azurerm_private_endpoint.pe_file) > 0 ? azurerm_private_endpoint.pe_file[0].id : null
  description = "El ID del Private Endpoint para el servicio de File. Es nulo si no se creó."
}

output "private_endpoint_queue_id" {
  value       = length(azurerm_private_endpoint.pe_queue) > 0 ? azurerm_private_endpoint.pe_queue[0].id : null
  description = "El ID del Private Endpoint para el servicio de Queue. Es nulo si no se creó."
}

output "private_endpoint_dfs_id" {
  value       = length(azurerm_private_endpoint.pe_dfs) > 0 ? azurerm_private_endpoint.pe_dfs[0].id : null
  description = "El ID del Private Endpoint para el servicio DFS. Es nulo si no se creó."
}
