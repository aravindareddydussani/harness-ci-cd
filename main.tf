terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0.0"
    }
  }

}

provider "google" {
  project = var.project_id
}

provider "google-beta" {
  project = var.project_id
}

variable "project_id" {
  description = "The ID of the GCP project where resources will be deployed"
  type        = string
  default = "playpen-c77259"
}

#enable the cloud workstation api
resource "google_project_service" "data_science_work_station_enable" {
  service = "workstations.googleapis.com"
  timeouts {
    create = "30m"
    update = "40m"
  }
  disable_dependent_services = true
  disable_on_destroy         = true
}

