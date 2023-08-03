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