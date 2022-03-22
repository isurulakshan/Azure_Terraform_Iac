# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.97.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "rg" {
  name     = "RG-${var.customer}"
  location = var.location
}

resource "azurerm_app_service_plan" "plan" {
  name = "${var.customer}-${var.env_type}-plan"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku{
      tier = "Standard"
      size = "S1"
  }
  kind = "Linux"
  reserved = true

}
resource "azurerm_app_service" "app" {
  name                = "${var.customer}-${var.env_type}-appservice"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.plan.id
  

  site_config {
    #linux_fx_version = "DOCKER|nginx:latest"
    linux_fx_version = "COMPOSE|${filebase64("docker-compose.yaml")}"
  }

}

