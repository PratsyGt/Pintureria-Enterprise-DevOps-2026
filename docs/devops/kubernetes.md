# Kubernetes

## Despliegue público

Prepara un clúster con nodos Linux amd64, almacenamiento dinámico para PVC y espacio para dos pods web más un tercero durante los rollouts. En un clúster multinodo la afinidad preferida intenta separar las réplicas. El laboratorio local tiene un único nodo. SQL Server Express usa un solo StatefulSet con PVC RWO de 10 Gi. La demostración de continuidad cubre la capa web; la pérdida del nodo o del único SQL requiere otra estrategia de HA y recuperación.

Selecciona explícitamente el contexto. En el repositorio los comandos siguientes se ejecutan desde la raíz con Bash.

```bash
export CTX=nombre-del-contexto
export HOST=pos-k8s.tu-dominio.com
export IMAGE='cuenta/pintureria@sha256:DIGEST_PUBLICADO'
kubectl --context "$CTX" get nodes
kubectl --context "$CTX" get storageclass
kubectl --context "$CTX" apply -f k8s/namespace.yaml
kubectl --context "$CTX" apply -f k8s/releaser-rbac.yaml
```

Si el clúster ya tiene controlador Traefik con clase traefik, úsalo. En un clúster nuevo con balanceador externo disponible puedes instalarlo así:

```bash
helm upgrade --install traefik traefik --repo https://traefik.github.io/charts --kube-context "$CTX" --namespace ingress-system --create-namespace --set ingressClass.name=traefik --set ingressClass.isDefaultClass=false --set service.spec.type=LoadBalancer
kubectl --context "$CTX" -n ingress-system get svc
helm upgrade --install cert-manager oci://quay.io/jetstack/charts/cert-manager --kube-context "$CTX" --namespace cert-manager --create-namespace --set crds.enabled=true --wait
sed 's/__EMAIL__/admin@tu-dominio.com/' k8s/issuer.example.yaml | kubectl --context "$CTX" apply -f -
```

Apunta el registro A del dominio al balanceador de Traefik. Permite que el desafío ACME HTTP-01 llegue por 80 y el tráfico TLS por 443. Verifica los valores del chart en la versión elegida. [Traefik en Kubernetes](https://doc.traefik.io/traefik/getting-started/install-traefik/) · [Instalación oficial de cert-manager](https://cert-manager.io/docs/installation/helm/)

Prepara fuera de Git un archivo privado con tres líneas SECRET_KEY, DB_PASSWORD y MSSQL_SA_PASSWORD (formato CLAVE=valor sin comillas). En bash usa permisos 600. El instalador de secretos utiliza create para evitar rotaciones accidentales sobre una base existente.

```bash
python3 ops/kube_secrets.py --context "$CTX" --env-file /ruta/privada/pos.env
python3 ops/kube_apply.py bootstrap --context "$CTX" --image "$IMAGE" --host "$HOST"
python3 ops/kube_apply.py release --context "$CTX" --image "$IMAGE" --host "$HOST"
kubectl --context "$CTX" -n pintureria-redes get pods,svc,ingress,pdb,pvc
kubectl --context "$CTX" -n pintureria-redes get certificate,challenge
kubectl --context "$CTX" -n pintureria-redes exec -it deploy/web -- python manage.py crear_admin --usuario gerente
curl -fsS "https://$HOST/health/ready/"
```

bootstrap se ejecuta solo en la instalación inicial. En siguientes releases aplica únicamente release. CI necesita una identidad autorizada en el namespace, que pueda modificar los recursos incluidos en la fase release. El Role de ejemplo concede esas operaciones. Configura un kubeconfig específico del clúster y de esa identidad, con CA, endpoint accesible desde el runner y credenciales vigentes. Usa un runner en la red privada si el API no es público. Guarda el kubeconfig codificado en el secreto KUBE_CONFIG_B64 del environment kubernetes. En Linux puedes cargarlo directamente con `base64 -w0 /ruta/privada/pos.kubeconfig | gh secret set KUBE_CONFIG_B64 --env kubernetes`. Mantén control de acceso al environment y rota las credenciales de acuerdo con el proveedor.

## Reproducir el laboratorio de esta PC

El namespace pintureria-redes ya contiene SQL, el PVC, dos réplicas y un controlador Traefik local. Para una instalación nueva, activa Kubernetes en Docker Desktop (el laboratorio usó el provisionador kind), aplica el namespace y crea los secretos con ops/kube_secrets.py. Para usar una imagen local en ese provisionador hay que importarla en containerd del nodo. Docker Desktop con un provisionador distinto puede utilizar almacenamiento compartido de imágenes o descargarlas directamente del registry.

```powershell
$rev = git rev-parse HEAD
docker build --target production --build-arg "APP_REVISION=$rev" -t "pintureria-redes:$rev" .
cmd /d /c "docker save pintureria-redes:$rev | docker exec -i desktop-control-plane ctr -n k8s.io images import --local --platform linux/amd64 -"
# Solo en una instalación nueva:
kubectl --context docker-desktop apply -f k8s/namespace.yaml
py -3 ops/kube_secrets.py --context docker-desktop --env-file .env.docker
py -3 ops/kube_apply.py bootstrap --context docker-desktop --image "pintureria-redes:$rev" --host pos.redes.test
py -3 ops/kube_apply.py release --context docker-desktop --image "pintureria-redes:$rev" --host pos.redes.test
```

Instala el controlador local si falta. Usa una CA de laboratorio durante siete días. El script genera y descarta la clave privada de la CA, almacena el certificado y la clave del sitio en el Secret pos-tls y escribe únicamente el certificado público de la CA en tmp. Se necesita el paquete Python cryptography, disponible en el entorno del proyecto por las dependencias de conexión. Para renovar un certificado de este mismo laboratorio agrega --renew. El laboratorio no instala cert-manager y por eso la anotación del Ingress no emite un certificado público.

```powershell
helm upgrade --install pos-ingress traefik --repo https://traefik.github.io/charts --kube-context docker-desktop --namespace pintureria-redes --skip-crds --set service.spec.type=ClusterIP --set providers.kubernetesCRD.enabled=false --set ingressClass.isDefaultClass=false --set ingressClass.name=traefik --set 'providers.kubernetesIngress.namespaces[0]=pintureria-redes' --set ingressRoute.dashboard.enabled=false --wait
.\.venv\Scripts\python.exe ops/local_tls.py --context docker-desktop
kubectl --context docker-desktop -n pintureria-redes port-forward service/pos-ingress-traefik 8443:443 --address 127.0.0.1
```

Con el túnel abierto, desde otra terminal:

```powershell
curl.exe --noproxy "*" --cacert tmp/redes-local-ca.pem --resolve pos.redes.test:8443:127.0.0.1 https://pos.redes.test:8443/health/ready/
kubectl --context docker-desktop -n pintureria-redes get pods -w
```

Para visualizar el dominio en navegador, el archivo hosts de Windows puede mapear `127.0.0.1 pos.redes.test`. El navegador también tiene que confiar en la CA del laboratorio. La prueba automatizada valida la cadena y el nombre sin modificar hosts ni el almacén de confianza del equipo.

## Demostrar alta disponibilidad y actualización

En el laboratorio, importa **una revisión distinta** a la que está desplegada usando el build anterior y ejecuta:

```powershell
.\.venv\Scripts\python.exe ops/ha_local.py --image "pintureria-redes:$rev" --revision "$rev"
```

El verificador solo apunta a docker-desktop/pintureria-redes. Comprueba HTTPS, login y estáticos, elimina un único pod seleccionado por app=pos-web, espera su reemplazo, cambia la imagen y espera el rollout. Sondea el Ingress durante todo el proceso y guarda observaciones en tmp/ha-redes.json. La validación de cliente TLS está habilitada.

En producción, observa `kubectl -n pintureria-redes rollout status deploy/web` y en otra terminal ejecuta `python3 ops/monitor.py https://DOMINIO --seconds 120`. Revisa `kubectl -n pintureria-redes logs deploy/web --tail=80`, eventos y probes. Si el clúster tiene Metrics Server, consulta también `kubectl -n pintureria-redes top pod`. Para volver a una revisión anterior usa `kubectl -n pintureria-redes rollout undo deployment/web`, comprueba readiness y corrige el origen Git antes del siguiente despliegue. El PDB protege desalojos voluntarios gestionados por Kubernetes; el ensayo de eliminación directa prueba al controlador de réplicas.
