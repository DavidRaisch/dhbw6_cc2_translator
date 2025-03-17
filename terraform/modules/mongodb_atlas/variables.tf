variable "org_id" {
  description = "MongoDB Atlas Organization ID"
  type        = string
}

variable "project_name" {
  description = "MongoDB Atlas Project Name"
  type        = string
}

variable "cluster_name" {
  description = "MongoDB Atlas Cluster Name"
  type        = string
}

variable "provider_region_name" {
  description = "MongoDB provider region name"
  type        = string
}

variable "provider_instance_size_name" {
  description = "MongoDB provider instance size name"
  type        = string
}

variable "db_username" {
  description = "MongoDB Database username"
  type        = string
}

variable "db_password" {
  description = "Set MongoDB Database user password"
  type        = string
  sensitive   = true
}

variable "vm_public_ip" {
  description = "Public IP address of the translator VM"
  type        = string
}
