output "network_name" {
  description = "Nombre de la red creada"
  value       = docker_network.lab.name
}

output "network_cidr" {
  description = "CIDR de la red"
  value       = var.network_cidr
}

output "web_container_name" {
  value = docker_container.web.name
}

output "app_container_name" {
  value = docker_container.app.name
}

output "db_container_name" {
  value = docker_container.db.name
}

output "ip_addresses" {
  description = "IPs asignadas a cada servidor"
  value = {
    web = var.web_ip
    app = var.app_ip
    db  = var.db_ip
  }
}

output "web_url" {
  description = "URL del servidor web"
  value       = "http://localhost:${var.web_host_port}"
}
