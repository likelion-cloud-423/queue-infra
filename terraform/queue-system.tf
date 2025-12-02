# =============================================================================
# Queue System Applications - 직접 배포
# =============================================================================

# queue-api Deployment
resource "kubernetes_deployment" "queue_api" {
  count = var.queue_system_enabled ? 1 : 0

  metadata {
    name      = "queue-api"
    namespace = "queue-system"
    labels = {
      app = "queue-api"
    }
  }

  spec {
    replicas = var.queue_api_replicas

    selector {
      match_labels = {
        app = "queue-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "queue-api"
        }
      }

      spec {
        container {
          name              = "queue-api"
          image             = "${var.ecr_registry}/queue-api:${var.queue_api_image_tag}"
          image_pull_policy = "Always"

          port {
            container_port = 8080
          }

          env {
            name  = "OTEL_EXPORTER_OTLP_ENDPOINT"
            value = "http://alloy.observability.svc.cluster.local:4318"
          }

          env {
            name  = "OTEL_SERVICE_NAME"
            value = "queue-api"
          }

          env {
            name = "SPRING_DATA_REDIS_HOST"
            value_from {
              secret_key_ref {
                name = "valkey-secret"
                key  = "SPRING_DATA_REDIS_HOST"
              }
            }
          }

          env {
            name = "SPRING_DATA_REDIS_PORT"
            value_from {
              secret_key_ref {
                name = "valkey-secret"
                key  = "SPRING_DATA_REDIS_PORT"
              }
            }
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          readiness_probe {
            http_get {
              path = "/actuator/health"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 3
            failure_threshold     = 5
          }

          liveness_probe {
            http_get {
              path = "/actuator/health"
              port = 8080
            }
            initial_delay_seconds = 60
            period_seconds        = 20
            timeout_seconds       = 3
            failure_threshold     = 5
          }
        }
      }
    }
  }

  depends_on = [module.eks, helm_release.alloy]
}

# queue-api Service
resource "kubernetes_service" "queue_api" {
  count = var.queue_system_enabled ? 1 : 0

  metadata {
    name      = "queue-api"
    namespace = "queue-system"
  }

  spec {
    selector = {
      app = "queue-api"
    }

    port {
      name        = "http"
      port        = 8080
      target_port = 8080
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.queue_api]
}

# queue-api HPA
resource "kubernetes_horizontal_pod_autoscaler_v2" "queue_api" {
  count = var.queue_system_enabled ? 1 : 0

  metadata {
    name      = "queue-api-hpa"
    namespace = "queue-system"
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = "queue-api"
    }

    min_replicas = var.queue_api_replicas
    max_replicas = var.queue_api_max_replicas

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 60
        }
      }
    }
  }

  depends_on = [kubernetes_deployment.queue_api]
}

# queue-manager Deployment
resource "kubernetes_deployment" "queue_manager" {
  count = var.queue_system_enabled ? 1 : 0

  metadata {
    name      = "queue-manager"
    namespace = "queue-system"
    labels = {
      app = "queue-manager"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "queue-manager"
      }
    }

    template {
      metadata {
        labels = {
          app = "queue-manager"
        }
      }

      spec {
        container {
          name              = "queue-manager"
          image             = "${var.ecr_registry}/queue-manager:${var.queue_manager_image_tag}"
          image_pull_policy = "Always"

          port {
            container_port = 8081
          }

          env {
            name  = "OTEL_EXPORTER_OTLP_ENDPOINT"
            value = "http://alloy.observability.svc.cluster.local:4318"
          }

          env {
            name  = "OTEL_SERVICE_NAME"
            value = "queue-manager"
          }

          env {
            name = "SPRING_DATA_REDIS_HOST"
            value_from {
              secret_key_ref {
                name = "valkey-secret"
                key  = "SPRING_DATA_REDIS_HOST"
              }
            }
          }

          env {
            name = "SPRING_DATA_REDIS_PORT"
            value_from {
              secret_key_ref {
                name = "valkey-secret"
                key  = "SPRING_DATA_REDIS_PORT"
              }
            }
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "300m"
              memory = "256Mi"
            }
          }

          readiness_probe {
            http_get {
              path = "/actuator/health"
              port = 8081
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 3
            failure_threshold     = 5
          }

          liveness_probe {
            http_get {
              path = "/actuator/health"
              port = 8081
            }
            initial_delay_seconds = 60
            period_seconds        = 20
            timeout_seconds       = 3
            failure_threshold     = 5
          }
        }
      }
    }
  }

  depends_on = [module.eks, helm_release.alloy]
}

# chat-server Deployment
resource "kubernetes_deployment" "chat_server" {
  count = var.queue_system_enabled ? 1 : 0

  metadata {
    name      = "chat-server"
    namespace = "queue-system"
    labels = {
      app = "chat-server"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "chat-server"
      }
    }

    template {
      metadata {
        labels = {
          app = "chat-server"
        }
      }

      spec {
        container {
          name              = "chat-server"
          image             = "${var.ecr_registry}/chat-server:${var.chat_server_image_tag}"
          image_pull_policy = "Always"

          port {
            name           = "http"
            container_port = 8080
          }

          env {
            name = "ConnectionStrings__Valkey"
            value_from {
              secret_key_ref {
                name = "valkey-secret"
                key  = "ConnectionStrings__Valkey"
              }
            }
          }

          env {
            name  = "ASPNETCORE_ENVIRONMENT"
            value = "Production"
          }

          env {
            name  = "OTEL_EXPORTER_OTLP_ENDPOINT"
            value = "http://alloy.observability.svc.cluster.local:4317"
          }

          env {
            name  = "OTEL_SERVICE_NAME"
            value = "chat-server"
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }

          readiness_probe {
            tcp_socket {
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 10
            timeout_seconds       = 1
            failure_threshold     = 3
          }

          liveness_probe {
            tcp_socket {
              port = 8080
            }
            initial_delay_seconds = 15
            period_seconds        = 20
            timeout_seconds       = 1
            failure_threshold     = 3
          }
        }
      }
    }
  }

  depends_on = [module.eks, helm_release.alloy]
}

# chat-server Service
resource "kubernetes_service" "chat_server" {
  count = var.queue_system_enabled ? 1 : 0

  metadata {
    name      = "chat-server"
    namespace = "queue-system"
  }

  spec {
    selector = {
      app = "chat-server"
    }

    port {
      name        = "websocket"
      port        = 9000
      target_port = 8080
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.chat_server]
}

# Queue System Ingress
resource "kubernetes_ingress_v1" "queue_system" {
  count = var.queue_system_enabled ? 1 : 0

  metadata {
    name      = "queue-ingress"
    namespace = "queue-system"
    annotations = {
      "alb.ingress.kubernetes.io/scheme"                  = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"             = "ip"
      "alb.ingress.kubernetes.io/listen-ports"            = "[{\"HTTP\":80}]"
      "alb.ingress.kubernetes.io/group.name"              = "queue-system"
      "alb.ingress.kubernetes.io/load-balancer-attributes" = "idle_timeout.timeout_seconds=1200"
      "alb.ingress.kubernetes.io/healthcheck-path"        = "/actuator/health"
      "alb.ingress.kubernetes.io/success-codes"           = "200"
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      http {
        path {
          path      = "/api/queue"
          path_type = "Prefix"
          backend {
            service {
              name = "queue-api"
              port {
                number = 8080
              }
            }
          }
        }

        path {
          path      = "/gameserver"
          path_type = "Prefix"
          backend {
            service {
              name = "chat-server"
              port {
                number = 9000
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_service.queue_api,
    kubernetes_service.chat_server,
    module.eks
  ]
}
