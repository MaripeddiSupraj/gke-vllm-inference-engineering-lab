output "cluster_name" {
  value = google_container_cluster.lab.name
}
output "cluster_zone" {
  value = google_container_cluster.lab.location
}
output "gpu_node_count" {
  value = var.gpu_node_count
}
output "kubectl_credentials_command" {
  value = "gcloud container clusters get-credentials ${google_container_cluster.lab.name} --zone ${var.zone} --project ${var.project_id}"
}
