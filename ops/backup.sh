#!/usr/bin/env bash
# Run on the Docker host; argument is the SQL container ID/name from the intended project.
set -euo pipefail
db="${1:?uso: bash ops/backup.sh CONTENEDOR_SQL CARPETA_DESTINO}"
dest="${2:?falta destino fuera del volumen}"
umask 077
mkdir -p -- "$dest"
name="PintureriaDB-$(date -u +%Y%m%dT%H%M%SZ).bak"
remote="/var/opt/mssql/data/$name"
docker exec "$db" bash -ec 'export SQLCMDPASSWORD="$MSSQL_SA_PASSWORD"; /opt/mssql-tools18/bin/sqlcmd -C -b -S localhost -U sa -Q "$1"' _ \
  "BACKUP DATABASE PintureriaDB TO DISK=N'$remote' WITH COPY_ONLY,CHECKSUM; RESTORE VERIFYONLY FROM DISK=N'$remote' WITH CHECKSUM;"
docker cp "$db:$remote" "$dest/$name"
sha256sum "$dest/$name" > "$dest/$name.sha256"
docker exec "$db" rm -- "$remote"
echo "$dest/$name"
