# =============================================================================
# Kubernetes Namespaces
# =============================================================================

resource "kubernetes_namespace" "observability" {
  metadata {
    name = "observability"
    labels = {
      name = "observability"
    }
  }

  depends_on = [module.eks]
}

# =============================================================================
# Observability ConfigMaps
# =============================================================================

resource "kubernetes_config_map" "observability_config" {
  metadata {
    name      = "observability-config"
    namespace = kubernetes_namespace.observability.metadata[0].name
  }

  data = {
    PROMETHEUS_ENDPOINT = "http://prometheus-server.observability.svc.cluster.local"
    LOKI_ENDPOINT       = "http://loki:3100"
  }
}

resource "kubernetes_config_map" "alloy_config" {
  metadata {
    name      = "alloy-config"
    namespace = kubernetes_namespace.observability.metadata[0].name
  }

  data = {
    "config.alloy" = file("${path.module}/configs/alloy.alloy")
  }
}

# =============================================================================
# Redis Exporter
# =============================================================================

resource "kubernetes_config_map" "redis_exporter_config" {
  metadata {
    name      = "redis-exporter-config"
    namespace = kubernetes_namespace.observability.metadata[0].name
  }

  data = {
    REDIS_ADDR = "redis://${aws_elasticache_replication_group.valkey.primary_endpoint_address}:6379"
  }
}

resource "kubernetes_deployment" "redis_exporter" {
  metadata {
    name      = "redis-exporter"
    namespace = kubernetes_namespace.observability.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "redis-exporter"
      }
    }

    template {
      metadata {
        labels = {
          app = "redis-exporter"
        }
      }

      spec {
        container {
          name  = "redis-exporter"
          image = "oliver006/redis_exporter:latest"

          env {
            name = "REDIS_ADDR"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.redis_exporter_config.metadata[0].name
                key  = "REDIS_ADDR"
              }
            }
          }

          port {
            container_port = 9121
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "redis_exporter" {
  metadata {
    name      = "redis-exporter"
    namespace = kubernetes_namespace.observability.metadata[0].name
  }

  spec {
    selector = {
      app = "redis-exporter"
    }

    port {
      port        = 9121
      target_port = 9121
    }
  }
}

# =============================================================================
# Loki Helm Release
# =============================================================================

resource "helm_release" "loki" {
  name       = "loki"
  namespace  = kubernetes_namespace.observability.metadata[0].name
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = "6.46.0"

  values = [
    file("${path.module}/configs/loki-values.yaml"),
    yamlencode({
      loki = {
        storage = {
          bucketNames = {
            chunks = aws_s3_bucket.loki.id
            ruler  = aws_s3_bucket.loki.id
            admin  = aws_s3_bucket.loki.id
          }
        }
      }
      serviceAccount = {
        create = true
        name   = "loki"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.loki_role.arn
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.observability,
    aws_iam_role.loki_role,
    module.eks
  ]
}

# =============================================================================
# Prometheus Helm Release
# =============================================================================

resource "helm_release" "prometheus" {
  name       = "prometheus"
  namespace  = kubernetes_namespace.observability.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = "25.27.0"

  values = [file("${path.module}/configs/prometheus-values.yaml")]

  depends_on = [
    kubernetes_namespace.observability,
    module.eks
  ]
}

# =============================================================================
# Metrics Server (HPA용 리소스 수집)
# =============================================================================

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.12.2"

  values = [file("${path.module}/configs/metrics-server-values.yaml")]

  depends_on = [module.eks]
}

# =============================================================================
# Alloy Helm Release
# =============================================================================

resource "helm_release" "alloy" {
  name       = "alloy"
  namespace  = kubernetes_namespace.observability.metadata[0].name
  repository = "https://grafana.github.io/helm-charts"
  chart      = "alloy"
  version    = "1.4.0"

  values = [
    file("${path.module}/configs/alloy-values.yaml"),
    yamlencode({
      alloy = {
        configMap = {
          create = false
          name   = kubernetes_config_map.alloy_config.metadata[0].name
          key    = "config.alloy"
        }
        extraEnv = [
          {
            name = "PROMETHEUS_ENDPOINT"
            valueFrom = {
              configMapKeyRef = {
                name = kubernetes_config_map.observability_config.metadata[0].name
                key  = "PROMETHEUS_ENDPOINT"
              }
            }
          },
          {
            name = "LOKI_ENDPOINT"
            valueFrom = {
              configMapKeyRef = {
                name = kubernetes_config_map.observability_config.metadata[0].name
                key  = "LOKI_ENDPOINT"
              }
            }
          }
        ]
      }
      serviceAccount = {
        create = true
        name   = "alloy"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.alloy_role.arn
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.observability,
    kubernetes_config_map.alloy_config,
    kubernetes_config_map.observability_config,
    aws_iam_role.alloy_role,
    helm_release.loki,
    helm_release.prometheus,
    helm_release.metrics_server,
    module.eks
  ]
}

# =============================================================================
# Grafana Admin Secret
# =============================================================================

resource "kubernetes_secret" "grafana_admin" {
  metadata {
    name      = "grafana-admin"
    namespace = kubernetes_namespace.observability.metadata[0].name
  }

  data = {
    "admin-user"     = var.grafana_admin_user
    "admin-password" = var.grafana_admin_password
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace.observability]
}

# =============================================================================
# Grafana Helm Release
# =============================================================================

resource "helm_release" "grafana" {
  name       = "grafana"
  namespace  = kubernetes_namespace.observability.metadata[0].name
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "10.3.0"

  values = [
    file("${path.module}/configs/grafana-values.yaml"),
    yamlencode({
      admin = {
        existingSecret = kubernetes_secret.grafana_admin.metadata[0].name
      }
      dashboards = {
        default = {
          queue-system = {
            json = file("${path.module}/dashboards/queue-system.json")
          }
          valkey-monitoring = {
            json = file("${path.module}/dashboards/valkey.json")
          }
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.observability,
    kubernetes_secret.grafana_admin,
    helm_release.loki,
    helm_release.prometheus,
    module.eks
  ]
}
