variable "location" {
  description = "Azure location"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "virtual_network_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
}

variable "nsg_name" {
  description = "Name of the Network Security Group"
  type        = string
}

variable "public_ip_name" {
  description = "Name of the Public IP"
  type        = string
}

variable "nic_name" {
  description = "Name of the Network Interface"
  type        = string
}

variable "vm_name" {
  description = "Name of the Linux Virtual Machine"
  type        = string
}

variable "vm_size" {
  description = "Size of the VM"
  type        = string
}

variable "vm_admin_username" {
  description = "Admin username for the VM"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key"
  type        = string
}

variable "vm_image_sku" {
  description = "SKU for the VM image"
  type        = string
}
