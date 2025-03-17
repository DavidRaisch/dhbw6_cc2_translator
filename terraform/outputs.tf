output "public_ip_address" {
  description = "The public IP address of the VM"
  value       = module.azure_infrastructure.public_ip
}

output "mongodb_connection_string" {
  description = "MongoDB Atlas connection string"
  value       = module.mongodb_atlas.mongodb_connection_string
  sensitive   = true
}

output "deepl_auth_key" {
  description = "DeepL API key"
  value       = var.deepL_auth_key
  sensitive   = true
}
