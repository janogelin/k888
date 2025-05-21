# Terraform configuration for nginx deployment with full removal, create_before_destroy, and namespace setup

# Set nginx_enabled to false to remove the deployment and namespace
variable "nginx_enabled" {
  description = "Whether to deploy nginx and create the namespace. Set to false to remove everything."
  type        = bool
  default     = true
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

# Namespace for nginx deployment
resource "kubernetes_namespace" "nginx_demo" {
  count = var.nginx_enabled ? 1 : 0
  metadata {
    name = "nginx-demo"
  }
}

# Nginx deployment with create_before_destroy lifecycle
resource "kubernetes_deployment" "nginx" {
  count = var.nginx_enabled ? 1 : 0
  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace.nginx_demo[0].metadata[0].name
  }

  spec {
    replicas = 4

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:latest"
          port {
            container_port = 80
          }
        }
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }
} 