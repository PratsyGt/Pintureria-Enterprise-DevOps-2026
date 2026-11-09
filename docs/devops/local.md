# Desarrollo local

1. En Windows x64 habilita virtualización y WSL 2. Desde PowerShell de administrador ejecuta `wsl --install` si falta WSL y reinicia cuando Windows lo pida. Instala [Docker Desktop para Windows](https://docs.docker.com/desktop/setup/install/windows-install/), selecciona el motor WSL 2 y contenedores Linux. Para Compose reserva memoria suficiente para SQL Server (al menos 2 GB para el motor SQL además del resto de la pila). Para las dos instalaciones locales simultáneas se usó Docker Desktop con unos 8 GB asignados.
2. Abre PowerShell en la carpeta oficial que contiene Dockerfile. Comprueba `docker version` y `docker compose version`. El archivo de inclusión y la configuración de pruebas utilizan una versión moderna de Compose (v2.24.4 o posterior).
3. Crea secretos locales propios y arranca los servicios.

```powershell
py -3 ops/local_env.py
docker compose --env-file .env.docker -f compose.dev.yml build web
docker compose --env-file .env.docker -f compose.dev.yml up -d --wait
docker compose --env-file .env.docker ps -a
docker compose --env-file .env.docker logs init
docker compose --env-file .env.docker exec web python manage.py crear_admin --usuario gerente
```

El comando de gerente pide la contraseña en la terminal. Abre http://localhost:8000/ y entra con ese usuario. En la PC de entrega el puerto elegido en .env.docker es 8019 porque el 8000 ya estaba ocupado. El archivo privado utiliza secretos distintos para Django, SA y pos_app. El puerto de SQL solo existe en la red interna. La comunicación web usa db:1433. La instalación nativa de Windows sigue leyendo app/.env y admite autenticación integrada. Los contenedores omiten ese archivo.

```powershell
curl.exe -fsS http://localhost:8019/health/ready/
docker compose --env-file .env.docker exec web python manage.py check
docker compose --env-file .env.docker exec web python manage.py shell -c "from core.db import execute_query; print(execute_query('SELECT DB_NAME() AS Base, SYSTEM_USER AS Cuenta',one=True))"
py -3 ops/check_compose.py --port 8019
docker compose --env-file .env.docker stats --no-stream
docker compose --env-file .env.docker logs --tail 30 web
```

Ajusta el puerto de los ejemplos a WEB_PORT. El verificador prueba lectura de un archivo estático editado, recarga del proceso Django y persistencia de una marca temporal tras reiniciar **el db del Compose de desarrollo**. Ejecútalo cuando puedas interrumpir brevemente esa base. Para ver cambios manualmente, modifica una plantilla o un estilo en VS Code y recarga el navegador. Los módulos Python se recargan desde sus bind mounts. Los cambios de dependencias requieren rebuild.

En Linux usa `python3` y `curl` para los mismos pasos. Para detener el entorno conservando los datos usa `docker compose --env-file .env.docker down`. Para levantarlo de nuevo usa `up -d --wait`.

## Instalación SQL

El servicio init espera a que SQL responda y toma un bloqueo de sesión en master. Solo instala PintureriaDB cuando no existe. Aplica 01, 04, 05, 06 y 07 en ese orden sobre una única conexión, separando los lotes GO. Los scripts 02 (demo), 03 (diagnóstico) y 08 (pruebas) quedan fuera del arranque. Al final crea el login SQL pos_app y una marca de instalación. Un reinicio con marca devuelve éxito sin repetir los scripts. Una base preexistente sin marca o una instalación parcial exige diagnóstico del lote y recuperación desde respaldo o un volumen nuevo. No añadas la marca a mano.

La web puede leer el esquema dbo, ejecutar los procedimientos de la aplicación y escribir directamente solo los mantenimientos, permisos y auditoría que el código utiliza. SA permanece en SQL e init. La clave de Django debe mantenerse estable entre releases y réplicas para conservar las sesiones. Para rotar una contraseña SQL, actualiza primero el login de la base y luego los secretos de los consumidores. Cambiar únicamente el archivo env no actualiza cuentas persistidas.

## Misma imagen para los integrantes

El primer build local sirve para desarrollar la infraestructura. Para una entrega de equipo, todos descargan **el mismo digest** indicado en el resumen de GitHub Actions y usan el mismo commit para los bind mounts. En PowerShell:

```powershell
$env:APP_IMAGE='cuenta/pintureria@sha256:DIGEST_PUBLICADO'
docker pull $env:APP_IMAGE
docker compose --env-file .env.docker up -d --no-build --wait
```

En Linux usa `export APP_IMAGE='cuenta/pintureria@sha256:DIGEST_PUBLICADO'`. Los volúmenes SQL son independientes por instalación.
