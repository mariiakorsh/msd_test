terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">=8.0, < 9.0"
    }
  }
}

provider "google" {
  project = local.project
  region  = local.region
}

locals {
  project = "msd-test-assignment"
  region  = "us-west1"
}

resource "google_service_account" "demo" {
  account_id   = "platform-demo-sa"
  display_name = "Custom SA for VM instance"
}

resource "google_compute_network" "demo" {
  name                    = "platform-demo-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "demo" {
  name          = "platform-demo-subnet"
  region        = local.region
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
  name         = "platform-demo-vm"
  machine_type = "e2-micro"
  zone         = "us-west1-a"

  tags = ["platform-demo"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      type  = "pd-standard"
      size  = 10
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.demo.id
    access_config {}
  }

  service_account {
    email  = google_service_account.demo.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    "startup-script" = file("${path.module}/startup.sh")
  }
}

resource "google_compute_firewall" "iap_ssh" {
  name          = "platform-demo-allow-iap-ssh"
  network       = google_compute_network.demo.name
  source_ranges = ["35.235.240.0/20"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["platform-demo"]
}

resource "google_project_iam_member" "vm_log_writer" {
  project = local.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.demo.email}"
}

resource "google_service_account" "deployer" {
  account_id   = "platform-demo-deployer"
  display_name = "GitHub Actions platform demo deployer"
}

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github-actions"
  project                   = local.project
  display_name              = "GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = local.project
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "GitHub Actions provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = <<-EOT
    assertion.repository_owner_id == "123419107" &&
    assertion.repository == "mariiakorsh/msd_test" &&
    assertion.ref == "refs/heads/main"
  EOT

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "github_deployer" {
  service_account_id = google_service_account.deployer.name
  role               = "roles/iam.workloadIdentityUser"

  member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/mariiakorsh/msd_test"
}

output "server_public_ip" {
  value = google_compute_instance.demo.network_interface[0].access_config[0].nat_ip
}
