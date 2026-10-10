# Arquitectura

```
                 INFRAESTRUCTURA (Terraform + Docker)
                              │
                     ┌────────▼────────┐
                     │  lab-network    │
                     │  10.10.0.0/24   │
                     │  GW 10.10.0.1   │
                     └────────┬────────┘
              ┌───────────────┼────────────────┐
        ┌─────▼─────┐   ┌─────▼─────┐    ┌─────▼─────┐
        │    WEB    │──►│    APP    │───►│    DB     │
        │ nginx     │   │ python    │    │ postgres  │
        │10.10.0.10 │   │10.10.0.20 │    │10.10.0.30 │
        │ :80 (host)│   │ :8080     │    │ :5432     │
        └───────────┘   └───────────┘    └───────────┘
```

## Componentes

| Recurso Terraform           | Tipo            | Descripción                                   |
|-----------------------------|-----------------|-----------------------------------------------|
| `docker_network.lab`        | Red             | Bridge 10.10.0.0/24, gateway 10.10.0.1        |
| `docker_image.web/app/db`   | Imágenes (x3)   | nginx, python, postgres                       |
| `docker_container.db`       | Contenedor      | Base de datos PostgreSQL en 10.10.0.30        |
| `docker_container.app`      | Contenedor      | Servidor de aplicaciones en 10.10.0.20:8080   |
| `docker_container.web`      | Contenedor      | nginx en 10.10.0.10, puerto 80 publicado      |

Total: 7 recursos (1 red + 3 imágenes + 3 contenedores).

## Relaciones y dependencias

- Todos los contenedores se conectan a `docker_network.lab` con IP fija.
- Orden de creación: red/imágenes → **db** → **app** → **web** (`depends_on`).
- El servidor web hace *proxy* de `/app/` hacia el servidor de aplicaciones.
- El servidor de aplicaciones puede alcanzar la base de datos por 10.10.0.30:5432.

## Flujo de comunicación

Cliente → `localhost:80` → WEB (10.10.0.10) → APP (10.10.0.20:8080) → DB (10.10.0.30:5432)
