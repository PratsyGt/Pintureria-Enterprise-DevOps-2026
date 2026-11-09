# Docker Hub, GitHub Actions y Dokploy

## Conectar el repositorio

Crea un repositorio GitHub del equipo y uno Docker Hub llamado, por ejemplo, cuenta/pintureria. Para el flujo descrito se usa un repositorio de imágenes público; para uno privado configura también credenciales de lectura en Dokploy y un imagePullSecret en Kubernetes. Desde la carpeta oficial, sustituye la URL del ejemplo por la real.

```powershell
git status
git remote add origin https://github.com/EQUIPO/REPOSITORIO.git
git push -u origin HEAD:main
```

Configura Actions antes del primer push que deba publicar. En Settings → Secrets and variables → Actions:

| Ámbito | Variables | Secretos |
| --- | --- | --- |
| Repositorio | DOCKERHUB_IMAGE (cuenta/pintureria), ENABLE_DOKPLOY y ENABLE_K8S | DOCKERHUB_USERNAME y DOCKERHUB_TOKEN con escritura limitada al repositorio |
| Environment dokploy | DOKPLOY_URL (URL HTTPS del panel), DOKPLOY_COMPOSE_ID, PUBLIC_URL (URL HTTPS de la app) | DOKPLOY_TOKEN |
| Environment kubernetes | PUBLIC_HOST (dominio sin protocolo) | KUBE_CONFIG_B64 |

Un pull request ejecuta las pruebas. Un push a main prueba Linux, inicia SQL y Gunicorn, verifica readiness, estáticos y reejecución segura de init. Luego publica esa imagen con el SHA completo. El job de despliegue consume su digest. Habilita cada destino con la variable de repositorio correspondiente en `true` después de prepararlo. Los jobs verifican por HTTPS que SQL responde y que la revisión reportada corresponde al push. Revisa la pestaña Actions y el resumen del job de publicación.

## VPS y dominio

Usa un VPS Linux x86_64 con IP estable, almacenamiento persistente, capacidad para el panel, la web y SQL Server, y acceso SSH administrativo. En un VPS dedicado, instala Dokploy siguiendo la [guía oficial](https://docs.dokploy.com/docs/core/installation). El instalador configura servicios de Docker y el proxy del host.

```bash
curl -fsSL https://dokploy.com/install.sh -o dokploy-install.sh
less dokploy-install.sh
sudo bash dokploy-install.sh
```

Permite TCP 80 y 443 de Internet. Limita SSH y la configuración inicial del panel (3000) a la red administrativa. Configura HTTPS del panel y limita finalmente el acceso directo a 3000. No abras 1433. Crea registros DNS A para el panel y la aplicación que apunten a la IP pública. Si publicas AAAA verifica también IPv6.

En Dokploy crea proyecto → Docker Compose → fuente **Raw**. Usa compose.dokploy.yml y estos valores privados en el editor de entorno: APP_IMAGE con el digest publicado, PUBLIC_HOST, SECRET_KEY, DB_PASSWORD y MSSQL_SA_PASSWORD. Genera valores distintos de los locales. Añade el dominio al servicio **web**, puerto **8000**, HTTPS y Let's Encrypt. Configura el redirect HTTP→HTTPS en el proxy. Mantén la base en la red interna. El proxy debe sobrescribir X-Forwarded-Proto y ser el único punto público de entrada al servicio. [Dominios de Docker Compose en Dokploy](https://docs.dokploy.com/docs/core/docker-compose/domains)

Despliega y revisa init (salida 0), db saludable y web saludable. Desde la terminal del servicio web ejecuta `python manage.py crear_admin --usuario gerente`. En GitHub habilita ENABLE_DOKPLOY. Actions actualiza la especificación Raw por API con la imagen exacta y solicita el despliegue. Las variables secretas del panel y la configuración del dominio se mantienen en Dokploy. Usa una cuenta API autorizada únicamente sobre el proyecto cuando tu instalación lo permita. [API Compose](https://docs.dokploy.com/docs/api/compose)

## Monitoreo, Fail2ban y respaldo

```bash
curl -fsS https://POS.TU-DOMINIO/health/live/
curl -fsS https://POS.TU-DOMINIO/health/ready/
python3 ops/monitor.py https://POS.TU-DOMINIO --seconds 120
docker stats --no-stream
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
sudo apt-get update && sudo apt-get install -y fail2ban python3-systemd
sudo install -m 0644 ops/sshd.local /etc/fail2ban/jail.d/pintureria-sshd.local
sudo fail2ban-client -t
sudo systemctl enable --now fail2ban
sudo systemctl restart fail2ban
sudo fail2ban-client status sshd
```

La jail protege SSH del VPS con cinco fallos en diez minutos y bloqueo de una hora. Configura el puerto de SSH real en la jail si lo cambiaste. Revisa logs y CPU/memoria desde Dokploy. Configura una comprobación externa periódica de /health/ready/ con alerta ante tres fallos; /health/live/ solo comprueba el proceso. Las respuestas incluyen la revisión y omiten detalles de conexión.

Desde una copia del repo **en el host** ejecuta `bash ops/backup.sh NOMBRE_CONTENEDOR_SQL /ruta/segura/backups`. El script crea un backup SQL nativo con CHECKSUM, ejecuta RESTORE VERIFYONLY y copia el archivo fuera del volumen. Programa la tarea con cron y copia los respaldos cifrados fuera del VPS. Ensaya la restauración en otra instancia antes de depender del respaldo. Para el ensayo, copia el .bak al contenedor de prueba, ejecuta RESTORE FILELISTONLY y usa RESTORE DATABASE con un nombre nuevo y WITH MOVE para los nombres lógicos obtenidos. Los logins de servidor y secretos requieren respaldo propio.

## Actualización en caliente y reversión

Haz un cambio visible en una rama, abre un PR y fusiónalo a main. Conserva el log del build, digest, despliegue y revisión de readiness. En Dokploy Compose con una sola web puede haber un corte durante la recreación. Mídelo con ops/monitor.py desde otra terminal. Para sustituir sin ese corte en Docker simple, prepara dos servicios web (azul/verde) conectados al mismo SQL, con la misma clave y una red privada común; prueba el nuevo por un dominio de preproducción, cambia el router de Traefik al saludable y drena el anterior. Esta variante de dos colores es una estrategia operativa, el Compose entregado ejecuta una web. La implementación automatizada con rolling update y dos réplicas está en Kubernetes.

Para revertir en Dokploy vuelve a aplicar la especificación con el digest anterior y verifica su SHA esperado. Mantén los volúmenes y la compatibilidad del esquema durante la reversión.
