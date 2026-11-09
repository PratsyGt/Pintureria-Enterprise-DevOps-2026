# Proyecto de Redes · Pinturería Enterprise POS

El directorio que contiene este documento es parte del proyecto definitivo. La aplicación utiliza las sesiones firmadas y los procedimientos SQL originales. La misma imagen Linux ejecuta Gunicorn en Dokploy y en las dos réplicas Kubernetes. El contenedor de desarrollo monta el código fuente y arranca el servidor de desarrollo de Django.

| Etapa | Guía |
| --- | --- |
| Instalación, Compose, SQL y trabajo en equipo | [Desarrollo local](local.md) |
| GitHub Actions, Docker Hub, Dokploy, DNS, TLS y operación | [Publicación y VPS](produccion.md) |
| Kubernetes, certificados, actualización y recuperación | [Clúster](kubernetes.md) |
| Resultados de esta PC y capturas para entregar | [Evidencias](evidencias.md) |

## Archivos de infraestructura

La raíz contiene Dockerfile, .dockerignore, compose.dev.yml, docker-compose.yml (entrada equivalente) y compose.dokploy.yml. El directorio ops contiene el instalador SQL, la generación de secretos locales, scripts de despliegue, verificación, monitoreo y respaldo. Los manifiestos están en k8s y el pipeline en .github/workflows/devops.yml. Django incorpora dos rutas HTTP de salud, configuración por variables y dependencias Linux en app/requirements-container.txt.

SQL Server se ejecuta en Linux amd64 con edición Express. La imagen web incluye ODBC Driver 18 y archivos estáticos recolectados durante el build. DEBUG=0 usa WhiteNoise. Cada instalación administra su propio volumen y credenciales.
