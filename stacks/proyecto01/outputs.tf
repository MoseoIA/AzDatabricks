output "adf_id" {
  value       = try(module.data_factory[0].data_factory_id, null)
  description = "ID de ADF si se habilitó."
}

output "databricks_workspace_id" {
  value       = try(module.databricks_workspace[0].databricks_workspace_id, null)
  description = "ID del Workspace de Databricks si se habilitó."
}

output "storage_account_id" {
  value       = try(module.storage_account[0].storage_account_id, null)
  description = "ID de la Storage Account si se habilitó."
}

output "key_vault_id" {
  value       = try(module.key_vault[0].key_vault_id, null)
  description = "ID del Key Vault si se habilitó."
}

output "sql_server_id" {
  value       = try(module.sql_database[0].sql_server_id, null)
  description = "ID del servidor SQL si se habilitó."
}

output "sql_database_id" {
  value       = try(module.sql_database[0].sql_database_id, null)
  description = "ID de la base de datos SQL si se habilitó."
}


