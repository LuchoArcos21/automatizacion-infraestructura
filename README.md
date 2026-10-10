# Automatización de Infraestructura con Terraform (IaC)

**Práctica:** Construcción y automatización de una infraestructura de red mediante Terraform
**Materia:** Automatización de Infraestructura Digital II
**Alumno:** _<tu nombre>_ | **Fecha:** _<fecha>_

## 1. Introducción
Este proyecto implementa una infraestructura virtual (red + 3 servidores) usando **Infraestructura como Código (IaC)** con Terraform y Docker como plataforma de laboratorio. Se complementa con scripts Bash para automatizar el despliegue, la verificación y la destrucción, y se versiona todo con Git.

## 2. Descripción del problema
Una pequeña empresa configura su entorno de desarrollo de forma manual, lo que causa:
- Errores humanos.
- Configuraciones distintas entre servidores.
- Dificultad para reproducir el entorno.
- Falta de documentación.
- Dificultad para identificar cambios.

**Solución:** definir toda la infraestructura en código declarativo (Terraform), reproducible y versionado.

## 3. Arquitectura
Ver [`docs/arquitectura.md`](docs/arquitectura.md).

| Elemento | IP | Tecnología |
|---|---|---|
| Red `lab-network` | 10.10.0.0/24 (GW 10.10.0.1) | Docker bridge |
| Servidor Web | 10.10.0.10 | nginx (puerto interno 80, puerto de acceso 8081)|
| Servidor de Aplicaciones | 10.10.0.20 | Python http.server (8080) |
| Servidor de Base de Datos | 10.10.0.30 | PostgreSQL 16 (5432) |

## 4. Herramientas utilizadas
Ubuntu/Debian · Terraform · Docker · Docker Compose · Git · GitHub/GitLab · Bash · Visual Studio Code · curl · ping.

## 5. Descripción de DevOps
**DevOps** es una cultura y conjunto de prácticas que integran desarrollo (Dev) y operaciones (Ops) para entregar software de forma más rápida, frecuente y confiable. Se apoya en:
- **Automatización** de tareas repetitivas (build, pruebas, despliegue, infraestructura).
- **Integración y entrega continua (CI/CD).**
- **Infraestructura como Código (IaC):** la infraestructura se describe en archivos versionables.
- **Control de versiones** (Git) como fuente única de verdad.
- **Monitoreo y retroalimentación** continua.
- **Colaboración** entre equipos.

## 6. Ventajas de la automatización
- **Reproducibilidad:** el mismo código crea siempre el mismo entorno.
- **Consistencia:** se eliminan diferencias entre servidores.
- **Menos errores humanos.**
- **Rapidez:** se despliega en minutos, no horas.
- **Documentación viva:** el código describe la infraestructura.
- **Trazabilidad:** Git registra quién cambió qué y cuándo.
- **Escalabilidad** y facilidad para clonar entornos (dev, test, prod).
- **Ahorro de costos** y tiempo del personal.

## 7. Descripción del código Terraform
| Archivo | Función |
|---|---|
| `terraform/main.tf` | Provider Docker, red, imágenes y los 3 contenedores con IP fija y `depends_on`. |
| `terraform/variables.tf` | Variables (CIDR, IPs, imágenes, puertos, credenciales). `db_password` es `sensitive`. |
| `terraform/terraform.tfvars` | Valores concretos del entorno. |
| `terraform/outputs.tf` | Salidas: nombres, IPs, URL del web. |
| `docker/docker-compose.yml` | Alternativa equivalente en Compose. |

## 8. Descripción de los scripts
| Script | Acción |
|---|---|
| `scripts/deploy.sh` | `init` → `fmt` → `validate` → `plan` → `apply`. |
| `scripts/verify.sh` | `validate`, `state list`, `docker ps`, `docker network ls`, IPs, `ping` entre servidores, `pg_isready`, `curl`. Guarda log en `evidencias/`. |
| `scripts/destroy.sh` | `terraform destroy`. |

## 9. Procedimiento de implementación
```bash
# Preparar entorno
terraform version && docker --version && git --version
git init

# Despliegue automático
./scripts/deploy.sh

# o manualmente
cd terraform
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform show
```

## 10. Procedimiento de verificación
```bash
./scripts/verify.sh
# o manualmente:
terraform -chdir=terraform validate    # Success! The configuration is valid.
terraform -chdir=terraform show
docker ps
docker network ls
docker exec lab-web ping -c 2 10.10.0.20
curl http://localhost
```

## 11. Resultados
> Completa con tus capturas de la carpeta `evidencias/`.

**Recursos creados y relaciones (Actividad 5):** se crean 7 recursos: 1 red (`docker_network`), 3 imágenes (`docker_image`) y 3 contenedores (`docker_container`). Los contenedores dependen de la red y de su imagen; además `web` depende de `app` y `app` depende de `db`, por lo que Terraform los crea en ese orden. Todos comparten la red 10.10.0.0/24 con IP fija.

**Reproducibilidad (Actividad 8):**
1. `./scripts/destroy.sh` → elimina todo.
2. `./scripts/deploy.sh` → recrea todo.
3. `./scripts/verify.sh` → todas las comprobaciones correctas.

| Evidencia | Captura |
|---|---|
| Init | `evidencias/01_terraform_init.png` |
| Validate | `evidencias/02_terraform_validate.png` |
| Plan | `evidencias/03_terraform_plan.png` |
| Apply | `evidencias/04_terraform_apply.png` |
| Funcionando | `evidencias/05_infra_funcionando.png` |
| Verificación | `evidencias/06_verificacion.png` |
| Destroy | `evidencias/07_terraform_destroy.png` |
| Reconstrucción | `evidencias/08_reconstruccion.png` |

## 12. Conclusiones
Terraform permitió definir la red y los tres servidores como código, eliminando la configuración manual y sus errores. Los scripts Bash automatizaron el ciclo completo (desplegar, verificar, destruir) y las pruebas confirmaron que la infraestructura real coincide con lo declarado. La destrucción y reconstrucción demostraron la reproducibilidad, principio central de DevOps.

### Pregunta de análisis
**¿Qué ventajas presenta reconstruir la infraestructura a partir del código frente a la configuración manual?**
- **Rapidez:** un solo comando recrea todo el entorno en minutos.
- **Consistencia:** siempre resulta idéntico, sin "deriva" de configuración.
- **Sin errores humanos:** no depende de recordar pasos.
- **Documentación y trazabilidad:** el código en Git muestra qué cambió, quién y por qué; se puede revertir.
- **Verificable:** se puede probar automáticamente con `verify.sh`.
- **Recuperación ante desastres:** se reconstruye rápido ante fallas.
- **Escalable:** se clonan entornos (dev/test/prod) con solo cambiar variables.

## Estructura del repositorio
```
automatizacion-infraestructura/
├── terraform/ (main.tf, variables.tf, outputs.tf, terraform.tfvars)
├── scripts/   (deploy.sh, verify.sh, destroy.sh)
├── docker/    (docker-compose.yml)
├── docs/      (arquitectura.md)
├── evidencias/
├── .gitignore
└── README.md
```
