resource "kubernetes_secret" "valkey_connection" {
  metadata {
    name      = "valkey-secret"
    namespace = kubernetes_namespace.queue_system.metadata[0].name
  }

  type = "Opaque"


  data = {
    SPRING_DATA_REDIS_HOST    = var.valkey_endpoint          
    SPRING_DATA_REDIS_PORT    = "6379"                       
    ConnectionStrings__Valkey = "${var.valkey_endpoint}:6379"
  }

  depends_on = [
    aws_eks_cluster.this,
    kubernetes_namespace.queue_system,
  ]
}


