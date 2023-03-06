variable "resource_group_name" {
  type        = string
  description = "RG name in Azure"
}

variable "acr_name" {
  type        = string
  description = "ACR name in Azure"
}

variable "location" {
  type        = string
  description = "Resources location in Azure"
}

variable "storage_name" {
  type        = string
  description = "Storage name in Azure"
}

variable "app_plan_name" {
  type        = string
  description = "App Service Plan name in Azure"
}


variable "func_app_name" {
  type        = string
  description = "Function App name in Azure"
}

variable "image_tag" {
  type        = string
  description = "Image Tag in Azure"
}

variable "image_name" {
  type        = string
  description = "Image Tag in Azure"
}
