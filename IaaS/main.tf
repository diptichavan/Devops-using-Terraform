terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">3.0.0"
    }

     docker = {
      source  = "kreuzwerker/docker"
      version = "2.11.0"
    }
  }
}
dhbfjd


provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "d_rg" {
  name     = var.resource_group_name
  location = var.location
}
resource "azurerm_container_registry" "d_acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.d_rg.name
  location            = azurerm_resource_group.d_rg.location
  sku                 = "Basic"
  admin_enabled       = true
}
resource "azurerm_container_group" "d_cont_grp" {
  name                = "dipti-container-group"
  location            = azurerm_resource_group.d_rg.location
  resource_group_name = azurerm_resource_group.d_rg.name
  ip_address_type     = "public"
  dns_name_label      = "example-dns-name-label"

  container {
    name   = "example-container"
    image  = "${azurerm_container_registry.d_acr.login_server}/example-image:latest"
    cpu    = "1"
    memory = "1.5"
    ports {
      port     = 80
      protocol = "TCP"
    }
    environment_variables = {
      EXAMPLE_ENV_VAR = "example-value"
    }
  }
}


resource "azurerm_storage_account" "d_storage" {
  name                     = var.storage_name
  resource_group_name      = azurerm_resource_group.d_rg.name
  location                 = azurerm_resource_group.d_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "d_app_plan" {
  name                = var.app_plan_name
  location            = azurerm_resource_group.d_rg.location
  resource_group_name = azurerm_resource_group.d_rg.name
  kind                = "FunctionApp"
  reserved            = true
  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_function_app" "d_func_app" {
  name                       = var.func_app_name
  location                   = azurerm_resource_group.d_rg.location
  resource_group_name        = azurerm_resource_group.d_rg.name
  app_service_plan_id        = azurerm_app_service_plan.d_app_plan.id
  storage_account_name       = azurerm_storage_account.d_storage.name
  storage_account_access_key = azurerm_storage_account.d_storage.primary_access_key
  version                    = "~2"

  app_settings = {
    FUNCTION_APP_EDIT_MODE                    = "readOnly"
    https_only                                = true
    FUNCTIONS_EXTENSION_VERSION              = "~2"
    DOCKER_REGISTRY_SERVER_URL               = "${azurerm_container_registry.d_acr.login_server}"
    DOCKER_REGISTRY_SERVER_USERNAME          = "${azurerm_container_registry.d_acr.admin_username}"
    DOCKER_REGISTRY_SERVER_PASSWORD          = "${azurerm_container_registry.d_acr.admin_password}"
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = "${azurerm_storage_account.d_storage.primary_connection_string}"
    WEBSITE_CONTENTSHARE                     = "${azurerm_storage_account.d_storage.name}"
    FUNCTIONS_WORKER_RUNTIME                 = "custom"
    WEBSITES_PORT              = "80"
    WEBSITE_RUN_FROM_PACKAGE                 = "https://diptistorage.blob.core.windows.net/deployments/python-sample-vscode-flask-tutorial-master.zip"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE       = false
    FUNCTIONS_CUSTOM_HANDLER   = "DockerHubExampleApp:Run"
  }

  # site_config {
  #   always_on        = true
  #   linux_fx_version  = "DOCKER|${azurerm_container_registry.d_acr.login_server}/${var.image_name}:${var.image_tag}"
    
  # }

   identity {
    type = "SystemAssigned"
  }

}

resource "azurerm_function_app_slot" "d_func_app_slot" {
  name                = "d-function-app-slot"
  location            = azurerm_resource_group.d_rg.location
  resource_group_name = azurerm_resource_group.d_rg.name
  app_service_plan_id = azurerm_app_service_plan.d_app_plan.id
  function_app_id     = azurerm_function_app.d_func_app.id

  app_settings = {
    DOCKER_REGISTRY_SERVER_URL = azurerm_container_registry.d_acr.login_server
    DOCKER_REGISTRY_USERNAME   = azurerm_container_registry.d_acr.admin_username
    DOCKER_REGISTRY_PASSWORD   = azurerm_container_registry.d_acr.admin_password
    WEBSITES_PORT              = "80"
    FUNCTIONS_WORKER_RUNTIME   = "custom"
    FUNCTIONS_CUSTOM_HANDLER   = "DockerHubExampleApp:Run"
  }
}

