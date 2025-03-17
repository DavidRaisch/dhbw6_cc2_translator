output "mongodb_connection_string" {
  description = "Connection string for the MongoDB Atlas Cluster"
  value       = "mongodb+srv://${mongodbatlas_database_user.translator_user.username}:${var.db_password}@${local.mongodb_server_without_uri}/translator_db?retryWrites=true&w=majority"
  sensitive   = true
}
