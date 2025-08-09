output "adf_id" { value = try(module.data_factory[0].data_factory_id, null) }
output "databricks_workspace_id" { value = try(module.databricks_workspace[0].databricks_workspace_id, null) }
output "storage_account_id" { value = try(module.storage_account[0].storage_account_id, null) }
output "key_vault_id" { value = try(module.key_vault[0].key_vault_id, null) }

output "sql_server_id" { value = try(module.sql_database[0].sql_server_id, null) }
output "sql_database_id" { value = try(module.sql_database[0].sql_database_id, null) }


