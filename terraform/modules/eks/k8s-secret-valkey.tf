# Valkey Secret (Terraform → EKS 자동 생성)
# namespace: queue-system


resource "kubernetes_secret" "valkey_connection" {
  metadata {
    name      = "valkey-secret"     
    namespace = "queue-system"      
  }

  type = "Opaque"

  # Terraform이 base64 자동 인코딩해줌 (string_data)
  string_data = {
    # queue-api / queue-manager → Spring Boot
    SPRING_DATA_REDIS_HOST = aws_elasticache_replication_group.valkey.primary_endpoint_address
    SPRING_DATA_REDIS_PORT = "6379"

    # chat-server → host:port 한 줄
    ConnectionStrings__Valkey = "${aws_elasticache_replication_group.valkey.primary_endpoint_address}:6379"
  }

  depends_on = [
    aws_eks_cluster.this,
    aws_elasticache_replication_group.valkey
  ]
}
