output "nginx_service_node_port" {
  value = kubernetes_service.nginx.spec[0].port[0].node_port
}
