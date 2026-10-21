# Lab-only infrastructure. DO NOT APPLY until billing, quota, and cleanup preflight are complete.
# Even a CPU-only GKE cluster incurs charges.
resource "google_service_account" "gke_nodes" {
  account_id   = "gke-vllm-lab-nodes"
  display_name = "GKE vLLM lab node identity"
}

resource "google_project_iam_member" "node_minimum" {
  project = var.project_id
  role    = "roles/container.defaultNodeServiceAccount"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_compute_network" "lab" {
  name                    = "gke-vllm-lab-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "lab" {
  name          = "gke-vllm-lab-subnet"
  ip_cidr_range = "10.20.0.0/20"
  region        = var.region
  network       = google_compute_network.lab.id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.24.0.0/16"
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.21.0.0/20"
  }
}

resource "google_container_cluster" "lab" {
  name                     = var.cluster_name
  location                 = var.zone
  network                  = google_compute_network.lab.id
  subnetwork               = google_compute_subnetwork.lab.id
  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = false
  networking_mode          = "VPC_NATIVE"

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  lifecycle {
    precondition {
      condition     = var.acknowledge_paid_infrastructure
      error_message = "Paid cluster creation blocked. Set acknowledge_paid_infrastructure=true only after preflight."
    }
  }
}

resource "google_container_node_pool" "cpu" {
  name       = "cpu-system"
  location   = var.zone
  cluster    = google_container_cluster.lab.name
  node_count = 1

  node_config {
    machine_type    = "e2-standard-2"
    service_account = google_service_account.gke_nodes.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
  depends_on = [google_project_iam_member.node_minimum]
}

# Create the GPU pool only after explicit approval.
# count=0 omits the pool entirely, rather than creating a zero-sized node pool.
resource "google_container_node_pool" "gpu" {
  count      = var.gpu_node_count
  name       = "t4-inference"
  location   = var.zone
  cluster    = google_container_cluster.lab.name
  node_count = 1

  node_config {
    machine_type    = "n1-standard-4"
    service_account = google_service_account.gke_nodes.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    guest_accelerator {
      type  = "nvidia-tesla-t4"
      count = 1
      gpu_driver_installation_config {
        gpu_driver_version = "DEFAULT"
      }
    }
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
  lifecycle {
    precondition {
      condition     = var.acknowledge_gpu_cost
      error_message = "GPU creation blocked until acknowledge_gpu_cost=true and preflight is complete."
    }
  }
  depends_on = [google_project_iam_member.node_minimum]
}
