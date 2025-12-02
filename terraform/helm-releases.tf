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

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      name = "argocd"
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
    AMP_WORKSPACE_ID = aws_prometheus_workspace.this.id
    AMP_REGION       = "ap-northeast-2"
    LOKI_ENDPOINT    = "http://loki:3100"
  }
}

resource "kubernetes_config_map" "alloy_config" {
  metadata {
    name      = "alloy-config"
    namespace = kubernetes_namespace.observability.metadata[0].name
  }

  data = {
    "config.alloy" = <<-EOT
      // Grafana Alloy Configuration for EKS
      
      otelcol.receiver.otlp "default" {
        grpc { endpoint = "0.0.0.0:4317" }
        http { endpoint = "0.0.0.0:4318" }
        output {
          metrics = [otelcol.processor.batch.default.input]
          logs    = [otelcol.exporter.loki.default.input]
        }
      }
      
      otelcol.processor.batch "default" {
        timeout = "10s"
        send_batch_size = 1000
        output {
          metrics = [otelcol.exporter.prometheusremotewrite.amp.input]
        }
      }
      
      otelcol.auth.sigv4 "amp_auth" {
        region  = env("AMP_REGION")
        service = "aps"
      }
      
      otelcol.exporter.prometheusremotewrite "amp" {
        endpoint {
          url = "https://aps-workspaces." + env("AMP_REGION") + ".amazonaws.com/workspaces/" + env("AMP_WORKSPACE_ID") + "/api/v1/remote_write"
          auth = otelcol.auth.sigv4.amp_auth.handler
        }
      }
      
      otelcol.exporter.loki "default" {
        forward_to = [loki.write.default.receiver]
      }
      
      loki.write "default" {
        endpoint {
          url = env("LOKI_ENDPOINT") + "/loki/api/v1/push"
        }
      }
      
      prometheus.scrape "redis_exporter" {
        targets = [{ __address__ = "redis-exporter.observability.svc.cluster.local:9121" }]
        forward_to = [prometheus.remote_write.amp.receiver]
        scrape_interval = "15s"
        job_name = "elasticache-valkey"
      }
      
      discovery.kubernetes "queue_api" {
        role = "pod"
        namespaces { names = ["queue-system"] }
        selectors { role = "pod"; label = "app=queue-api" }
      }
      
      prometheus.scrape "queue_api" {
        targets    = discovery.kubernetes.queue_api.targets
        forward_to = [prometheus.remote_write.amp.receiver]
        scrape_interval = "15s"
        metrics_path = "/actuator/prometheus"
        job_name = "queue-api"
      }
      
      discovery.kubernetes "queue_manager" {
        role = "pod"
        namespaces { names = ["queue-system"] }
        selectors { role = "pod"; label = "app=queue-manager" }
      }
      
      prometheus.scrape "queue_manager" {
        targets    = discovery.kubernetes.queue_manager.targets
        forward_to = [prometheus.remote_write.amp.receiver]
        scrape_interval = "15s"
        metrics_path = "/actuator/prometheus"
        job_name = "queue-manager"
      }
      
      prometheus.remote_write "amp" {
        endpoint {
          url = "https://aps-workspaces." + env("AMP_REGION") + ".amazonaws.com/workspaces/" + env("AMP_WORKSPACE_ID") + "/api/v1/remote_write"
          sigv4 { region = env("AMP_REGION") }
        }
      }
    EOT
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
  version    = "6.16.0"

  values = [
    yamlencode({
      deploymentMode = "SingleBinary"
      loki = {
        auth_enabled = false
        commonConfig = {
          replication_factor = 1
        }
        schemaConfig = {
          configs = [
            {
              from         = "2024-01-01"
              store        = "tsdb"
              object_store = "s3"
              schema       = "v13"
              index = {
                prefix = "index_"
                period = "24h"
              }
            }
          ]
        }
        storage = {
          bucketNames = {
            chunks = aws_s3_bucket.loki.id
            ruler  = aws_s3_bucket.loki.id
            admin  = aws_s3_bucket.loki.id
          }
          type = "s3"
          s3 = {
            region           = "ap-northeast-2"
            s3ForcePathStyle = false
          }
        }
      }
      singleBinary = {
        replicas = 1
        resources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
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
      test = {
        enabled = false
      }
      monitoring = {
        selfMonitoring = {
          enabled = false
        }
        lokiCanary = {
          enabled = false
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.observability,
    aws_iam_role.loki_role
  ]
}

# =============================================================================
# Alloy Helm Release
# =============================================================================

resource "helm_release" "alloy" {
  name       = "alloy"
  namespace  = kubernetes_namespace.observability.metadata[0].name
  repository = "https://grafana.github.io/helm-charts"
  chart      = "alloy"
  version    = "0.9.2"

  values = [
    yamlencode({
      alloy = {
        configMap = {
          create = false
          name   = kubernetes_config_map.alloy_config.metadata[0].name
          key    = "config.alloy"
        }
        extraEnv = [
          {
            name = "AMP_WORKSPACE_ID"
            valueFrom = {
              configMapKeyRef = {
                name = kubernetes_config_map.observability_config.metadata[0].name
                key  = "AMP_WORKSPACE_ID"
              }
            }
          },
          {
            name = "AMP_REGION"
            valueFrom = {
              configMapKeyRef = {
                name = kubernetes_config_map.observability_config.metadata[0].name
                key  = "AMP_REGION"
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
      controller = {
        type     = "deployment"
        replicas = 1
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.observability,
    kubernetes_config_map.alloy_config,
    kubernetes_config_map.observability_config,
    aws_iam_role.alloy_role,
    helm_release.loki
  ]
}

# =============================================================================
# ArgoCD Helm Release
# =============================================================================

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.7.5"

  values = [
    yamlencode({
      global = {
        domain = "argocd.${var.name_prefix}.local"
      }
      server = {
        extraArgs = ["--insecure"]
        ingress = {
          enabled          = true
          ingressClassName = "alb"
          annotations = {
            "alb.ingress.kubernetes.io/scheme"                  = "internet-facing"
            "alb.ingress.kubernetes.io/target-type"             = "ip"
            "alb.ingress.kubernetes.io/listen-ports"            = "[{\"HTTP\":80}]"
            "alb.ingress.kubernetes.io/group.name"              = "argocd"
          }
        }
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
      }
      controller = {
        resources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
      }
      repoServer = {
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "256Mi"
          }
        }
      }
      applicationSet = {
        resources = {
          requests = {
            cpu    = "50m"
            memory = "64Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "128Mi"
          }
        }
      }
      redis = {
        resources = {
          requests = {
            cpu    = "50m"
            memory = "64Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "128Mi"
          }
        }
      }
      configs = {
        params = {
          "server.insecure" = true
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.argocd,
    module.eks
  ]
}
