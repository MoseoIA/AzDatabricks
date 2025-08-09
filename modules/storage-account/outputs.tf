# --- outputs.tf en Mod_AzStorageAccount_Native ---

output "storage_account_id" {
  value       = azurerm_storage_account.sa.id
  description = "ID de la cuenta de almacenamiento."
}

output "primary_blob_endpoint" {
  value       = azurerm_storage_account.sa.primary_blob_endpoint
  description = "Endpoint Blob primario."
}


