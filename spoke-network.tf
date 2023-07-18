terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>3.65.0"
    }
  }
}
# Configure Azure Provider 
provider "azurerm" {
  features {}
    subscription_id   = var.subscription_id
    tenant_id         = var.tenant_id
    client_id         = var.client_id
    client_secret     = var.client_secret
}
# Build azure resource group which is our terraform network
resource "azurerm_resource_group" "azure_terraform_mainnetwork" {
    name = "mainnetwork"
    location = var.resource_group_location
}
# Build a vnet which is our main network
resource "azurerm_virtual_network" "terraform_main" {
    name = "terraform-main"
    location = var.resource_group_location
    resource_group_name = azurerm_resource_group.azure_terraform_mainnetwork.name
    address_space = ["10.0.0.0/16"]
}
# Build dev subnet within terraform main. The virtual network argument is using an implicit dependancy
# by having the .name on the end of it so it knows to create the subnet AFTER the vnet is created
resource "azurerm_subnet" "terraform_dev_subnet" {
    name = "terraform-dev-subnet"
    resource_group_name = azurerm_resource_group.azure_terraform_mainnetwork.name
    address_prefixes = ["10.0.1.0/24"]
    virtual_network_name = azurerm_virtual_network.terraform_main.name
}
# Build test subnet within terraform main.
resource "azurerm_subnet" "terraform_test_subnet" {
    name = "terraform-test-subnet"
    resource_group_name = azurerm_resource_group.azure_terraform_mainnetwork.name
    address_prefixes = ["10.0.2.0/24"]
    virtual_network_name = azurerm_virtual_network.terraform_main.name
}
# Create a public IP address
resource "azurerm_public_ip" "terraform_public_ip" {
    name = "terraform-public-ip"
    location = var.resource_group_location
    resource_group_name = azurerm_resource_group.azure_terraform_mainnetwork.name
    allocation_method = "Dynamic"
}
# Create NSG and access control rules
resource "azurerm_network_security_group" "terraform_nsg" {
    name = "terraform-nsg"
    location = var.resource_group_location
    resource_group_name = azurerm_resource_group.azure_terraform_mainnetwork.name

    security_rule {
        name                       = "RDP"
        priority                   = 500
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "web"
        priority                   = 501
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
  }
}
# Create network interface
resource "azurerm_network_interface" "terraform_nic" {
  name                = "terraform-nic"
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.azure_terraform_mainnetwork.name

  ip_configuration {
    name                          = "terraform_nic_config"
    subnet_id                     = azurerm_subnet.terraform_dev_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.terraform_public_ip.id
  }
}
# Connect NSG to the nic
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.terraform_nic.id
  network_security_group_id = azurerm_network_security_group.terraform_nsg.id
}
# Create virtual machine
resource "azurerm_windows_virtual_machine" "terraform_dev_web" {
  name                  = "terraform-dev"
  admin_username        = "azureuser"
  admin_password        = random_password.password.result
  location              = var.resource_group_location
  resource_group_name   = azurerm_resource_group.azure_terraform_mainnetwork.name
  network_interface_ids = [azurerm_network_interface.terraform_nic.id]
  size                  = "Standard_B2s"

  os_disk {
    name                 = "devOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-datacenter-smalldisk-g2"
    version   = "latest"
  }
}
resource "random_password" "password" {
  length      = 12
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
  special     = true
}