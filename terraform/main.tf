# main.tf

# Configure the Azure provider
provider "azurerm" {
  features {}

  subscription_id = "e3dcd138-51df-4960-9f88-e43978fe333b"
  client_id       = "25b72868-eb47-44ac-aada-52693649458d"
  client_secret   = ""
  tenant_id       = "e932d96a-c5aa-4f37-a68f-3722071530aa"
}

# Create a Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "translator-rg"
  location = "East US"  # Choose a region of your choice
}

# Create a Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "translator-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create a Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "translator-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create a Public IP Address
resource "azurerm_public_ip" "public_ip" {
  name                = "translator-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"  
  sku                 = "Standard"
}

# Create a Network Interface
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

# Create a Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "translator-vm"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = "Standard_B1s"  # Adjust the size as needed
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/azure_deploy_key.pub")  # Ensure your public key exists here.
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS" #22.04-LTS would be better
    version   = "latest"
  }
}

#TODO: use env_variables instead of hardcoded keys
#TODO: Network Security Group (NSG) needs to be created also
