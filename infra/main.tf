terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 1. Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "placement-tracker-rg"
  location = "East US"
}

# 2. Create App Service Plan
resource "azurerm_app_service_plan" "plan" {
  name                = "placement-tracker-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku {
    tier = "Free"
    size = "F1"
  }
}

# 3. Create App Service
resource "azurerm_app_service" "app" {
  name                = "placement-tracker-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.plan.id
}
