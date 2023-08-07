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

# waiting for the apis to be fully enabled
resource "time_sleep" "ws_api_enable_wait_20s" {
  create_duration = "20s"
}

variable "region" {
  description = "The default GCP region to deploy resources to"
  type        = string
  default     = "europe-west2"
}

resource "google_compute_address" "static" {
  name = "ipv4-address"
  region = var.region
}

variable "project_name" {
  description = "project name"
  default     = "data-science"
  type        = string
}

variable "vpc" {
  description = "The vpc to deploy resources to"
  type        = string
  default     = "data-science-vpc"
}

variable "subnet" {
  description = "The subnet to deploy resources to"
  type        = string
  default     = "data-science-vpc-subnet"
}

variable "subnet_cidr" {
  description = "The subnet to deploy resources to"
  type        = string
  default     = "10.154.0.0/20"
}

variable "notebook_zone" {
  description = "The default notebook zone"
  type        = string
  default     = "europe-west2-b"
}

# vpc network to attach the notebook
resource "google_compute_network" "data_science_network" {
  project                 = var.project_id
  name                    = var.vpc
  auto_create_subnetworks = false
  description             = "VPC of the project"
}

resource "google_compute_firewall" "data_science_rules" {
  project       = var.project_id
  name          = "${var.project_name}-firewall-rules"
  network       = google_compute_network.data_science_network.name
  description   = "Creates firewall rule targeting tagged instances"
  source_ranges = ["0.0.0.0/0", ]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  depends_on = [google_compute_network.data_science_network]
}

# sub-network to attach with correct cidr ranges
resource "google_compute_subnetwork" "data_science_subnetwork" {
  name                     = var.subnet
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.data_science_network.id
  ip_cidr_range            = var.subnet_cidr
  stack_type               = "IPV4_IPV6"
  ipv6_access_type         = "EXTERNAL"
  private_ip_google_access = true
  //private_ipv6_google_access = "ENABLE_BIDIRECTIONAL_ACCESS_TO_GOOGLE"
  depends_on = [google_compute_network.data_science_network]
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_instance" "nexus_instance" {
  name         = "delegate-vm"
  machine_type = "e2-standard-4"
  zone         = var.notebook_zone

  # Boot disk
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size  = 100
    }
  }

  # Network
  network_interface {
    network    = google_compute_network.data_science_network.name
    subnetwork = google_compute_subnetwork.data_science_subnetwork.name
    access_config {
      nat_ip = google_compute_address.static.address
    }
  }

  # Metadata startup script
  #metadata_startup_script = file("${path.module}/nexus_startup.sh")
#   service_account {
#     email  = google_service_account.data_science_ai_sa.email
#     scopes = ["cloud-platform"]
#   }
}
