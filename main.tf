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
  depends_on      = [google_project_service.data_science_work_station_enable]
  create_duration = "20s"
}


resource "google_compute_address" "static" {
  name = "ipv4-address"
  region = var.region
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
  service_account {
    email  = google_service_account.data_science_ai_sa.email
    scopes = ["cloud-platform"]
  }
}
