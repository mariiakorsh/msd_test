terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">=8.0, < 9.0"
    }
  }
}

provider "google" {
  project = "msd-test-assignment"
  region  = "us-west1"
}

resource "google_service_account" "demo" {
  account_id = "platform-demo-sa"
  display_name = "Custom SA for VM instance"
}

resource "google_compute_network" "demo" {
  name                    = "platform-demo-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "demo" {
  name          = "platform-demo-subnet"
  region        = "us-west1"
  ip_cidr_range = "10.42.0.0/24"
  network       = google_compute_network.demo.id
}

resource "google_compute_firewall" "http" {
  name          = "platform-demo-allow-http"
  network       = google_compute_network.demo.name
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags = ["platform-demo"]
}

resource "google_compute_instance" "demo" {
  name = "platform-demo-vm"
  machine_type = "e2-micro"
  zone = "us-west1-a"

  tags = ["platform-demo"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      type = "pd-standard"
      size = 10
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.demo.id
    access_config {}
  }

  service_account {
    email = google_service_account.demo.email
    scopes = ["cloud-platform"]
  }
}
