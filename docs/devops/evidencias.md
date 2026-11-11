# Evidencias para la entrega de Redes

## Resultados del laboratorio

| Criterio | Prueba realizada | Resultado |
| --- | --- | --- |
| Desarrollo local | Django y SQL Server Express en Compose con volumen. Se editó un estático desde el host, se comprobó la recarga de Django y se reinició el contenedor SQL con una marca de prueba. | El cambio fue visible por HTTP y SQL conservó la marca después del reinicio. |
| Aplicación funcional | Se ejecutaron las pruebas dentro de la imagen Linux y se inició sesión para abrir el dashboard y el punto de venta. | Pasaron 38 pruebas. Ambas pantallas respondieron por HTTP. [Captura del dashboard](evidencia/dashboard-compose.png). |
| Docker para producción | Se levantó el Compose destinado a Dokploy con una base separada y la imagen de la revisión `fdf33f7`. | Gunicorn respondió a la sonda de disponibilidad y sirvió los estáticos con `DEBUG=0`. |
| Acceso SQL y respaldo | Se comprobaron los roles de `pos_app` y se ejecutó un respaldo nativo con checksum. | La cuenta de aplicación carece de los roles sysadmin y db_owner. SQL Server aceptó el respaldo con `RESTORE VERIFYONLY`. Queda pendiente ensayar una restauración completa. |
| Dominio y HTTPS | El cliente de prueba accedió al Ingress de Traefik con el nombre `pos.redes.test` y validó el certificado contra la CA del laboratorio. | La verificación del nombre y la cadena pasó en ambas corridas. El certificado público se debe verificar después de configurar DNS en el servidor del equipo. |
| Alta disponibilidad | Con dos réplicas listas, se eliminó un pod web, se esperó su reemplazo y se actualizó el Deployment mientras se consultaba la disponibilidad por HTTPS. | Primera corrida, 55 consultas en 25,45 s y cero fallos. Segunda corrida, 50 consultas en 27,1 s y cero fallos. |

Los registros contienen los nombres de los pods, las revisiones observadas y los errores de cada muestreo. La segunda corrida pasó de `2b8f9a0` a `fdf33f7`. El clúster local tiene un solo nodo y una instancia de SQL. El ensayo cubre el fallo de un pod web y el reemplazo gradual de ambas réplicas. [Primera corrida](evidencia/alta-disponibilidad.json) · [Actualización final](evidencia/rollout-final.json)

## Reproducir la demostración

1. Arrancar Docker Desktop y levantar Compose siguiendo la [guía local](local.md). En esta PC el puerto configurado es 8019.
2. Abrir [el POS local](http://127.0.0.1:8019/) e ingresar con `gerente_redes`. La clave de esta instalación está en el archivo privado `.env.docker-admin` de la raíz. Excluir ese archivo de la presentación y de Git.
3. Mostrar el estado de los contenedores y consultar `/health/ready/` para demostrar la conexión a SQL. Mostrar un cambio en un archivo montado y comprobarlo desde el navegador.
4. Seguir la [guía Kubernetes](kubernetes.md) para repetir la prueba HTTPS, observar la sustitución de pods y guardar el registro de la nueva corrida.

## Evidencias pendientes del entorno público

El flujo de GitHub Actions y los archivos de despliegue están en el repositorio local. Para acreditar el recorrido completo desde un push hasta producción, el equipo debe configurar su repositorio remoto, el registro, el servidor y el dominio. La [guía de publicación](produccion.md) contiene los pasos y los nombres de las variables y secretos.

| Evidencia a capturar | Qué debe verse |
| --- | --- |
| GitHub Actions y Docker Hub | El commit, los pasos de prueba y publicación exitosos y el digest de la imagen. |
| Despliegue de Dokploy | El despliegue automático del mismo digest, los contenedores saludables y el volumen persistente. |
| DNS y HTTPS públicos | La aplicación abierta en el dominio del equipo, el certificado válido y la revisión del commit en la sonda de disponibilidad. |
| Operación del VPS | El estado de la jail SSH en Fail2ban y el resultado del monitoreo externo durante una actualización. |

Para la demostración de continuidad, usar el Deployment Kubernetes con dos réplicas. El Compose simple de Dokploy tiene una sola réplica web y su recreación puede producir un corte breve. Ocultar credenciales, tokens y direcciones privadas al preparar capturas para entregar.
