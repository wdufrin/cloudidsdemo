variable "zone" {
    default = "us-east1-d"
    description = "default zone"  
}

variable "region" {
    default = "us-east1"
    description = "default region"
}

variable "project_id" {
    default = null
    description = "default project" 
}

variable "location" {
    default = "US"
    description = "default location"
}

variable "enable_apis" {
  description = "Whether to actually enable the APIs. If false, this module is a no-op."
  default     = true
  type        = bool
}

variable "disable_dependent_services" {
  description = "Whether services that are enabled and which depend on this service should also be disabled when this service is destroyed. https://www.terraform.io/docs/providers/google/r/google_project_service.html#disable_dependent_services"
  default     = false
  type        = bool
}

variable "disable_services_on_destroy" {
    description = "disables api's when terraform is destroyed"
    default = false
    type = bool
}

variable "network" {
    default = "testnetwork"
    type = string
}

variable "subnet" {
    default = "subnet01"  
    type = string
}