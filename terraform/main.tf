terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.0.0"
    }
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = ">= 1.0.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = "e3dcd138-51df-4960-9f88-e43978fe333b"
  client_id       = "25b72868-eb47-44ac-aada-52693649458d"
  client_secret   = ""
  tenant_id       = "e932d96a-c5aa-4f37-a68f-3722071530aa"
}

# Azure Infrastruktur

# Ressourcengruppe
resource "azurerm_resource_group" "rg" {
  name     = "translator-rg"
  location = "East US"
}

# Virtuelles Netzwerk
resource "azurerm_virtual_network" "vnet" {
  name                = "translator-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnetz
resource "azurerm_subnet" "subnet" {
  name                 = "translator-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Netzwerksicherheitsgruppe (NSG) mit Regeln für SSH (Port 22) und Translator App (Port 5005)
resource "azurerm_network_security_group" "nsg" {
  name                = "translator-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowTranslatorApp"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5005"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Öffentliche IP-Adresse
resource "azurerm_public_ip" "public_ip" {
  name                = "translator-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Netzwerkschnittstelle (NIC)
resource "azurerm_network_interface" "nic" {
  name                = "translator-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# NSG-Zuordnung zur NIC
resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Linux-VM
resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "translator-vm"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = "Standard_B1s"
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/azure_deploy_key.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"   # Alternativ: "22.04-LTS" je nach Bedarf
    version   = "latest"
  }
}

provider "mongodbatlas" {
  public_key  = var.mongodb_atlas_public_key
  private_key = var.mongodb_atlas_private_key
}

variable "mongodb_atlas_public_key" {
  description = "MongoDB Atlas Public Key"
  type        = string
  default     = "tvkhftqp"
}

variable "mongodb_atlas_private_key" {
  description = "MongoDB Atlas Private Key"
  type        = string
  default     = "ac842ecd-4c45-4fcd-ac30-d597ccde4384"
  sensitive   = true
}

variable "mongodb_atlas_org_id" {
  description = "MongoDB Atlas Organization ID"
  type        = string
  default     = "67d03a45d593c05518bb08a1"
}

# MongoDB Atlas Projekt erstellen
resource "mongodbatlas_project" "project" {
  name   = "translator-project"
  org_id = var.mongodb_atlas_org_id
}

# Kostenlosen MongoDB Atlas Cluster erstellen (Free Tier, M0)
resource "mongodbatlas_cluster" "cluster" {
  project_id         = mongodbatlas_project.project.id
  name               = "translator-cluster"
  provider_name      = "TENANT"
  backing_provider_name ="AZURE"
  provider_region_name        = "US_EAST_2"
  provider_instance_size_name = "M0"
  cluster_type       = "REPLICASET"
  backup_enabled     = false
}

# MongoDB Benutzer erstellen
resource "mongodbatlas_database_user" "translator_user" {
  username           = "translator_user"
  password           = var.mongodb_user_password
  project_id         = mongodbatlas_project.project.id
  auth_database_name = "admin"

  roles {
    role_name     = "readWriteAnyDatabase"           # Admin-Rechte für die Datenbank
    database_name = "admin"        # Für Schema-Operationen
  }
}

# Sensible Variablen für Sicherheit
variable "mongodb_user_password" {
  description = "Passwort für den MongoDB Benutzer"
  type        = string
  sensitive   = true
  default     = "#1234Jr"
}

# Atlas IP Access List: Erlaube den Zugriff von der öffentlichen IP der VM (als /32)
resource "mongodbatlas_project_ip_access_list" "access" {
  project_id = mongodbatlas_project.project.id
  ip_address = azurerm_public_ip.public_ip.ip_address
  comment    = "Allow access from translator VM"
  depends_on = [azurerm_public_ip.public_ip]
}

# Outputs
output "public_ip_address" {
  description = "Die öffentliche IP-Adresse der VM"
  value       = azurerm_public_ip.public_ip.ip_address
}

locals {
  mongodb_server_without_uri = replace(mongodbatlas_cluster.cluster.connection_strings[0].standard_srv, "mongodb+srv://", "")
}

output "mongodb_connection_string" {
  description = "Verbindungsstring (SRV) zum MongoDB Atlas Cluster"
  #value       = mongodbatlas_cluster.cluster.connection_strings[0].standard_srv
  value       = "mongodb+srv://${mongodbatlas_database_user.translator_user.username}:${var.mongodb_user_password}@${local.mongodb_server_without_uri}"
  sensitive = true
}

resource "null_resource" "write_tf_output" {
  # Verwende einen Trigger, der sich ändert, damit der local-exec bei jedem Apply ausgeführt wird
  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    command = "terraform output -json > terraform_output.json"
  }
}



#TODO: use env_variables instead of hardcoded keys
#TODO: Network Security Group (NSG) needs to be created also
#TODO:more structure in terraform: main.tf, provider.tf, variable.tf, ...
