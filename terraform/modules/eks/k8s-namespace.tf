resource "kubernetes_namespace" "queue_system" {
  metadata {
    name = "queue-system"
  }
}