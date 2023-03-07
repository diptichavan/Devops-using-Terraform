terraform {

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">3.0.0"
    }
  }

  backend "azurerm" {
    storage_account_name = azurerm_storage_account.terraform_state_sa.name
    container_name       = azurerm_storage_container.terraform_state_container.name
    key                  = "terraform.tfstate"

    access_key = data.azurerm_key_vault_secret.terraform_state_secret.value
  }
}

provider "azurerm" {
  features {}
}


resource "azurerm_key_vault" "function_app_kv" {
  name                = "state-keyvault"
  location            = "west europe"
  resource_group_name = azurerm_resource_group.example.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "get",
      "list",
    ]
    secret_permissions = [
      "get",
      "list",
    ]
  }
}

data "azurerm_key_vault_secret" "terraform_state_secret" {
  name         = "state-secret"
  key_vault_id = azurerm_key_vault.function_app_kv.id
}

variable "password" {
  default = data.azurerm_key_vault_secret.terraform_state_secret.value
}


resource "azurerm_storage_account" "terraform_state_sa" {
  name                     = "terraformstatesa"
  resource_group_name      = azurerm_resource_group.function_app_rg.name
  location                 = "west europe"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
resource "azurerm_storage_container" "terraform_state_container" {
  name                  = "terraformstatecontainer"
  storage_account_name  = azurerm_storage_account.terraform_state_sa.name
  container_access_type = "private"
}






resource "azurerm_app_service_plan" "function_app_plan" {
  name                = "function-app-service-plan"
  location            = azurerm_resource_group.function_app_rg.location
  resource_group_name = azurerm_resource_group.function_app_rg.name

  sku {
    tier = "Standerd"
    size = "S1"
  }
}

resource "azurerm_container_registry" "function_registry" {
  name                = "function-container-registry"
  location            = azurerm_resource_group.function_app_rg.location
  resource_group_name = azurerm_resource_group.function_app_rg.name
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_storage_account" "function_storage_sa" {
  name                     = "functionstoragesa"
  resource_group_name      = azurerm_resource_group.function_app_rg.name
  location                 = azurerm_resource_group.function_app_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  enable_https_traffic_only = true
}



resource "azurerm_function_app" "function_app" {
  name                = "functionapp1"
  location            = azurerm_resource_group.function_app_rg.location
  resource_group_name = azurerm_resource_group.function_app_rg.name
  app_service_plan_id = azurerm_app_service_plan.function_app_rg.id
   storage_account_name       = azurerm_storage_account.function_storage_sa.name
  storage_account_access_key = azurerm_storage_account.function_storage_sa.primary_access_key

  site_config {
     always_on        = true
    linux_fx_version = "DOCKER|mcr.microsoft.com/azure-functions/python:3.0-python3.8-appservice"
  }

  app_settings = {
    "DOCKER_REGISTRY_SERVER_URL" = "https://${azurerm_container_registry.function_registry.login_server}"
    "DOCKER_REGISTRY_SERVER_USERNAME" = azurerm_container_registry.function_registry.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD" = azurerm_container_registry.function_registry.admin_password
  }

  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    azurerm_container_registry.function_registry,
  ]
}

resource "null_resource" "example" {
  triggers = {
    dockerfile = filebase64("C:\Terraform On Azure\Devops-using-Terraform\python-sample-vscode-flask-tutorial-master\Dockerfile")
  }

  provisioner "local-exec" {
    command = "echo '${base64decode(var.dockerfile)}' | docker build -t ${azurerm_container_registry.function_registry.login_server}/${azurerm_container_registry.function_registry.name}:${var.tag} -f - . && docker push ${azurerm_container_registry.function_registry.login_server}/${azurerm_container_registry.function_registry.name}:${var.tag}"
  }
}

variable "tag" {
  default = "latest"
}

variable "dockerfile" {
  default = "Dockerfile"
}




