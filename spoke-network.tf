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
    subscription_id   = "4f8b1e4a-3a40-4602-8c46-cfa331c40dc6"
    tenant_id         = "341ffecf-7d58-47a0-8fff-c9d2e5db1e68"
    client_id         = "c85ae931-f15c-40eb-9d8c-2da83d2542ed"
    client_secret     =  var.client_secret
}
# Build azure resource group which is our terraform network
resource "azurerm_resource_group" "azure_terraform_mainnetwork" {
    name = "mainnetwork"
    location = "uksouth"
}
# Build a vnet which is our main network
resource "azurerm_virtual_network" "terraform_main" {
    name = "terraform-main"
    location = azurerm_resource_group.azure_terraform_mainnetwork.location
    resource_group_name = "mainnetwork"
    address_space = ["10.0.0.0/16"]
}
# Build dev subnet within terraform main. The virtual network argument is using an implicit dependancy
# by having the .name on the end of it so it knows to create the subnet AFTER the vnet is created
resource "azurerm_subnet" "terraform_dev_subnet" {
    name = "terraform-dev-subnet"
    resource_group_name = "mainnetwork"
    address_prefixes = ["10.0.1.0/24"]
    virtual_network_name = azurerm_virtual_network.terraform_main.name
}
# Build test subnet within terraform main.
resource "azurerm_subnet" "terraform_test_subnet" {
    name = "terraform-test-subnet"
    resource_group_name = "mainnetwork"
    address_prefixes = ["10.0.2.0/24"]
    virtual_network_name = azurerm_virtual_network.terraform_main.name
}