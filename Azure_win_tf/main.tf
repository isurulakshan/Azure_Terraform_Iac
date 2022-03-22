terraform {
  required_providers {
    azurerm={
      source  = "hashicorp/azurerm"
      version = "=2.97.0"
    }
  }
}

provider "azurerm" {
  features {}
}

#create azure resource group
resource "azurerm_resource_group" "rg" {
  name     = "RG-${var.customer_name}"
  location = var.location
    tags = {
    environment = var.environment
  }
}
#create azure vnet
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.customer_name}-${var.environment}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
    tags = {
    environment = var.environment
  }
}

#create subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.customer_name}-${var.environment}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]

}
#create public ip
resource "azurerm_public_ip" "pip" {
  name                = "${var.customer_name}-${var.environment}-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"

  tags = {
    environment = var.environment
  }
}
#create nic
resource "azurerm_network_interface" "nic" {
  name                = "${var.customer_name}-${var.environment}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${var.customer_name}-${var.environment}-ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.pip.id
  }
    tags = {
    environment = var.environment
  }
}
#create nsg
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.customer_name}-${var.environment}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow_RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = var.environment
  }
}

#bind nsg to nic
resource "azurerm_network_interface_security_group_association" "attach_nic" {
  network_interface_id = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}


#create azure windows vm
resource "azurerm_windows_virtual_machine" "vm" {
  name                = "${var.customer_name}-${var.environment}-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
    tags = {
    environment = var.environment
  }
}