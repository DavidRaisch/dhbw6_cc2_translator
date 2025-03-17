//DeepL
variable "deepL_auth_key" {
  description = "DeepL Authentication Key"
  type        = string
  sensitive   = true
}

// Azure provider credentials (no defaults for sensitive environment-specific values)
variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  default     = "e3dcd138-51df-4960-9f88-e43978fe333b"
}
variable "azure_client_id" {
  description = "Azure Client ID"
  type        = string
  default     = "25b72868-eb47-44ac-aada-52693649458d"
}
variable "azure_client_secret" {
  description = "Azure Client Secret"
  type        = string
  sensitive   = true
}
variable "azure_tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  default     = "e932d96a-c5aa-4f37-a68f-3722071530aa"
}

// Azure Infrastructure variables
variable "location" {
  description = "Azure location"
  type        = string
  default     = "East US"
}
variable "resource_group_name" {
  description = "Resource Group name"
  type        = string
  default     = "translator-rg"
}
variable "virtual_network_name" {
  description = "Virtual Network name"
  type        = string
  default     = "translator-vnet"
}
variable "subnet_name" {
  description = "Subnet name"
  type        = string
  default     = "translator-subnet"
}
variable "nsg_name" {
  description = "Network Security Group name"
  type        = string
  default     = "translator-nsg"
}
variable "public_ip_name" {
  description = "Public IP name"
  type        = string
  default     = "translator-public-ip"
}
variable "nic_name" {
  description = "Network Interface name"
  type        = string
  default     = "translator-nic"
}
variable "vm_name" {
  description = "Linux VM name"
  type        = string
  default     = "translator-vm"
}
variable "vm_size" {
  description = "VM size"
  type        = string
  default     = "Standard_B1s"
}
variable "vm_admin_username" {
  description = "VM admin username"
  type        = string
  default     = "azureuser"
}
variable "ssh_public_key_path" {
  description = "Path to the SSH public key"
  type        = string
  default     = "~/.ssh/azure_deploy_key.pub"
}
variable "vm_image_sku" {
  description = "SKU for the source image"
  type        = string
  default     = "20_04-lts"
}

// MongoDB Atlas variables
variable "mongodb_atlas_public_key" {
  description = "MongoDB Atlas Public Key"
  type        = string
}
variable "mongodb_atlas_private_key" {
  description = "MongoDB Atlas Private Key"
  type        = string
  sensitive   = true
}
variable "mongodb_atlas_org_id" {
  description = "MongoDB Atlas Organization ID"
  type        = string
  default     = "67d03a45d593c05518bb08a1"
}
variable "mongodb_project_name" {
  description = "MongoDB Atlas project name"
  type        = string
  default     = "translator-project"
}
variable "mongodb_cluster_name" {
  description = "MongoDB Atlas cluster name"
  type        = string
  default     = "translator-cluster"
}
variable "mongodb_provider_region_name" {
  description = "MongoDB provider region name"
  type        = string
  default     = "US_EAST_2"
}
variable "mongodb_provider_instance_size_name" {
  description = "MongoDB provider instance size name"
  type        = string
  default     = "M0"
}
variable "mongodb_db_username" {
  description = "MongoDB Database username"
  type        = string
  default     = "translator_user"
}
variable "mongodb_db_password" {
  description = "Set MongoDB Database user password"
  type        = string
  sensitive   = true
}
