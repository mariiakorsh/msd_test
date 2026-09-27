terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = ">=8.0, < 9.0"
    }
  }
}

provider "google" {
  project = "msd-test-assignment"
  region  = "us-west1"
}