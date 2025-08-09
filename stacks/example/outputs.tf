output "adf_id" {
  value       = module.data_factory.data_factory_id
  description = "ID del Azure Data Factory desplegado."
}

output "adf_private_endpoint_id" {
  value       = module.data_factory.private_endpoint_id
  description = "ID del Private Endpoint de ADF."
}

output "adf_private_endpoint_ip" {
  value       = module.data_factory.private_endpoint_ip_address
  description = "IP privada del Private Endpoint de ADF."
}

output "databricks_workspace_id" {
  value       = module.databricks_workspace.databricks_workspace_id
  description = "ID del Workspace de Databricks."
}

output "databricks_workspace_url" {
  value       = module.databricks_workspace.databricks_workspace_url
  description = "URL del Workspace de Databricks."
}

output "databricks_private_endpoint_id" {
  value       = module.databricks_workspace.private_endpoint_id
  description = "ID del Private Endpoint de Databricks."
}

output "databricks_storage_account_id" {
  value       = module.databricks_workspace.storage_account_id
  description = "ID de la cuenta de almacenamiento creada para Databricks (si aplica)."
}

output "sql_server_id" {
  value       = try(module.sql_database[0].sql_server_id, null)
  description = "ID del servidor SQL (si se habilitó)."
}

output "sql_database_id" {
  value       = try(module.sql_database[0].sql_database_id, null)
  description = "ID de la base de datos SQL (si se habilitó)."
}


