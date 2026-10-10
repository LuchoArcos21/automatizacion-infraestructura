###############################################################################
# main.tf - Infraestructura de red virtual (Docker) definida como código
# Red 10.10.0.0/24 -> WEB (.10) | APP (.20) | DB (.30)
###############################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

# ----------------------------- Red privada ----------------------------------
resource "docker_network" "lab" {
  name   = var.network_name
  driver = "bridge"

  ipam_config {
    subnet  = var.network_cidr
    gateway = var.network_gateway
  }
}

# ------------------------------ Imágenes ------------------------------------
resource "docker_image" "web" {
  name         = var.web_image
  keep_locally = true
}

resource "docker_image" "app" {
  name         = var.app_image
  keep_locally = true
}

resource "docker_image" "db" {
  name         = var.db_image
  keep_locally = true
}

# ------------------------ Servidor de Base de Datos -------------------------
resource "docker_container" "db" {
  name    = "${var.project_name}-db"
  image   = docker_image.db.image_id
  restart = "unless-stopped"

  env = [
    "POSTGRES_DB=${var.db_name}",
    "POSTGRES_USER=${var.db_user}",
    "POSTGRES_PASSWORD=${var.db_password}",
  ]

  networks_advanced {
    name         = docker_network.lab.name
    ipv4_address = var.db_ip
  }

  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U ${var.db_user} -d ${var.db_name}"]
    interval = "5s"
    timeout  = "3s"
    retries  = 10
  }
}

# ---------------------- Servidor de Aplicaciones ----------------------------
resource "docker_container" "app" {
  name    = "${var.project_name}-app"
  image   = docker_image.app.image_id
  restart = "unless-stopped"

  command = ["python", "-m", "http.server", tostring(var.app_port), "--directory", "/tmp"]

  upload {
    file    = "/tmp/index.html"
    content = <<-EOT
      <h1>Servidor de Aplicaciones</h1>
      <p>IP: ${var.app_ip} | Base de datos: ${var.db_ip}:5432</p>
    EOT
  }

  networks_advanced {
    name         = docker_network.lab.name
    ipv4_address = var.app_ip
  }

  depends_on = [docker_container.db]
}

# --------------------------- Servidor Web -----------------------------------
resource "docker_container" "web" {
  name    = "${var.project_name}-web"
  image   = docker_image.web.image_id
  restart = "unless-stopped"

  ports {
    internal = 80
    external = var.web_host_port
  }

  upload {
    file    = "/etc/nginx/conf.d/default.conf"
    content = <<-EOT
      server {
        listen 80;
        location / {
          root  /usr/share/nginx/html;
          index index.html;
        }
        # Proxy hacia el servidor de aplicaciones
        location /app/ {
          proxy_pass http://${var.app_ip}:${var.app_port}/;
        }
      }
    EOT
  }

  upload {
    file    = "/usr/share/nginx/html/index.html"
    content = <<-EOT
      <h1>Servidor Web - ${var.project_name}</h1>
      <p>Infraestructura creada con Terraform.</p>
      <p>Red: ${var.network_cidr} | WEB ${var.web_ip} | APP ${var.app_ip} | DB ${var.db_ip}</p>
      <p><a href="/app/">Ir al servidor de aplicaciones</a></p>
    EOT
  }

  networks_advanced {
    name         = docker_network.lab.name
    ipv4_address = var.web_ip
  }

  depends_on = [docker_container.app]
}
