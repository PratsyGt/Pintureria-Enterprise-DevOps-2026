## Instalación en Windows

Requiere Python 3.11 o superior, SQL Server 2022 Express, SSMS y ODBC Driver 18 for SQL Server. Desde PowerShell, dentro de esta carpeta:

```powershell
.\Instalar.ps1
```

El instalador crea `.venv`, instala dependencias y genera una clave secreta aleatoria si `app/.env` no existe. Nunca reemplaza un `.env` existente. Si la política del equipo impide scripts, use los comandos equivalentes:

```powershell
py -3 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r app\requirements.txt
Copy-Item app\.env.example app\.env
.\.venv\Scripts\python.exe -c "import secrets; print(secrets.token_urlsafe(64))"
```

Copie la clave generada a `SECRET_KEY` en `app/.env`. No la publique. El archivo exige mínimo 50 caracteres. Configure:

```dotenv
SECRET_KEY=<clave generada localmente>
DEBUG=1
ALLOWED_HOSTS=localhost,127.0.0.1
DB_SERVER=.\SQLEXPRESS
DB_NAME=PintureriaDB
DB_DRIVER=ODBC Driver 18 for SQL Server
DB_TRUSTED_CONNECTION=yes
DB_USER=
DB_PASSWORD=
```

Con autenticación de Windows deje usuario y contraseña vacíos. Para autenticación SQL establezca `DB_TRUSTED_CONNECTION=no` y las credenciales locales correspondientes. Configure la instancia real; no es obligatorio que se llame SQLEXPRESS. Habilite TCP/IP y el servicio SQL Server si corresponde. `TrustServerCertificate=yes` está orientado al entorno local de clase; una instalación pública necesita certificado válido, HTTPS y `DEBUG=0`.

## Orden de los scripts SQL

En SSMS, sobre una base de desarrollo y con copia de seguridad:

1. `database/01_PintureriaDB_Fase1.sql`: estructura y datos base, solo instalación inicial.
2. `database/02_Datos_Demo.sql`: opcional, clientes/proveedores de demostración; no crea stock.
3. `database/04_Fase2_Comercial.sql`: procedimientos comerciales originales.
4. `database/05_Permisos_Usuarios.sql`: seleccionar **PintureriaDB** antes de ejecutarlo.
5. `database/06_FaseFinal_Mejoras.sql`: reglas de alta activa, permisos, validaciones y refuerzo comercial.
6. `database/07_Anulaciones_Reportes.sql`: devolución por lotes, anulación, auditoría y reportes.
7. `database/08_Pruebas_Integracion.sql`: pruebas con datos temporales que se revierten, únicamente en desarrollo.

`03_Pruebas_Fase1.sql` es una consulta de diagnóstico opcional. En una instalación existente con 01–05 aplicados, ejecutar únicamente 06 y 07. No volver a ejecutar 04 después de 06: reemplazaría los procedimientos reforzados. Los scripts 01–05 se conservan como origen histórico.

06 y 07 no borran datos comerciales. 06 rechaza crear el índice de cotización única si ya hay duplicados: deben conciliarse antes. Ejecutar cada archivo y revisar los mensajes de SSMS antes de pasar al siguiente. La base de los scripts es `PintureriaDB`; si cambia DB_NAME, adapte los `USE` de los scripts.

## Crear gerente e iniciar

```powershell
.\.venv\Scripts\python.exe app\manage.py crear_admin --usuario gerente
.\.venv\Scripts\python.exe app\manage.py check
.\Iniciar.ps1
```

El comando solicita una contraseña de mínimo 12 caracteres sin mostrarla. No incluye credenciales predeterminadas. Para restablecer una cuenta existente debe añadir explícitamente `--actualizar`.

Abrir http://127.0.0.1:8000/. No requiere `migrate`: las tablas de negocio se crean con los scripts SQL y las sesiones usan cookies firmadas. Para probar una venta: crear producto y variante, crear orden de compra, recibir unidades en una ubicación y emitir factura.

## Módulos y capas

- `catalogos`: cuatro mantenimientos originales; `extended.py` y `extended_views.py` añaden productos, variantes, presentaciones, unidades, colores y ubicaciones. SQL dinámico utiliza exclusivamente identificadores de un registro cerrado; todos los valores son parámetros.
- `seguridad`: PBKDF2, usuarios y permisos por módulo. Digitador administra datos/compras/cotizaciones; Cajero factura; Gerente conserva la administración completa existente. Puede personalizar permisos. Altas activas y cambios de estado por POST con CSRF.
- `comercial`: cotización y confirmación, factura directa o desde cotización, pagos múltiples, impresión, compras, recepción parcial, existencias/lotes/movimientos. `final_views.py` incorpora consulta/anulación, devoluciones e impresión de cotizaciones.
- `reportes`: formularios y servicios, repositorios SQL, vista previa, CSV y PDF con ReportLab.
- `core`: acceso SQL, autorización, contexto de plantillas, manejo de indisponibilidad y pruebas.

Las identidades siempre las genera SQL Server. En edición el ID procede de la URL autorizada, no del POST. Las altas usan Activo=1 en la aplicación, procedimientos y triggers; los registros históricos no se eliminan al desactivar.

## Operaciones transaccionales

`sp_Factura_Emitir` toma precios del catálogo o de la cotización, redondea cada importe a dos decimales y exige coincidencia exacta entre pagos y total. Bloquea lotes, descuenta por FechaIngreso/LoteID, registra salida y auditoría. Un error revierte toda la operación. La secuencia P26 genera números nuevos; los huecos por rollback son normales. Una cotización no puede facturarse dos veces ni reutilizarse después de anular la factura.

`sp_Compra_Recibir` bloquea la orden, verifica pendientes y registra lotes/movimientos; permite 75 + 25 de una orden de 100 y rechaza 75 + 26.

`sp_Devolucion_Registrar` devuelve una línea por operación, verifica el saldo y asigna cantidades a sus salidas originales mediante DevolucionLote. Puede repetirse para distintas líneas. Conserva el importe devuelto y la auditoría. No procesa reembolsos bancarios externos.

`sp_Factura_Anular` busca por número y bloquea la factura. Guarda sus montos originales en FacturaAnulacion, reintegra solo las cantidades aún no devueltas, conserva pagos/detalles/salidas y deja Subtotal/Descuento/Total vigentes en cero. Registra usuario, fecha y motivo. Rechaza anular dos veces. Si existen devoluciones antiguas sin correspondencia con lotes, exige conciliarlas: no inventa una asignación ni reintegra unidades a ciegas.

Los procedimientos comerciales revisan permisos con `sp_Autorizar`. La aplicación también protege cada ruta; utilice una cuenta SQL de aplicación con los permisos mínimos necesarios, nunca publique la conexión del administrador.

## Siete reportes

1. Facturado entre fechas, efectivo, cheque, tarjeta y otros medios.
2. Ingresos por producto/variante.
3. Cantidades vendidas separadas por presentación.
4. Inventario por lote, ubicación y costo.
5. Menor rotación, incluyendo variantes sin ventas.
6. Sin stock: variantes comercialmente activas agotadas.
7. Factura por número, empleado, detalle, estado y pagos históricos.

Los reportes 1, 2, 3 y 5 excluyen facturas anuladas. Son reportes **brutos facturados**, no un estado neto de reembolsos: las devoluciones se conservan separadamente. Las fechas extremas se incluyen completas. No se mezclan cubetas con galones. PDF y CSV incluyen el resultado completo de los filtros del formulario. La vista previa de reportes conserva el orden y las filas devueltas por el procedimiento.

## Pruebas y límites

```powershell
.\.venv\Scripts\python.exe -m pip install -r app\requirements-test.txt
.\.venv\Scripts\python.exe app\manage.py test core --verbosity 2
.\.venv\Scripts\python.exe app\manage.py check
node --check app\static\js\site.js
node --check app\static\js\comercial.js
node --check app\static\js\pos.js
```

Las 38 pruebas Python comprueban contratos con mocks explícitos; no se presentan como pruebas SQL. La integración se verificó adicionalmente en SQL Server real e independiente. `VALIDACION.md` distingue ambas coberturas.

Los listados operativos realizan búsqueda, filtros, orden y paginación en SQL Server con parámetros, columnas permitidas y desempate por ID. Los lotes parten de FechaIngreso/ID. Los filtros se conservan en la URL. El POS carga el catálogo activo al entrar y presenta 18 tarjetas por página (6 en móvil); para catálogos enormes conviene sustituir esa carga inicial por una API paginada. Los reportes exportan todos los resultados seleccionados; no se hizo una prueba de carga masiva.

El límite de intentos de login usa caché local (8 intentos por usuario/IP, 5 minutos). Para varios procesos debe configurarse caché compartida. Las cuentas inactivas y cambios de contraseña invalidan la sesión al revisar permisos; cookies duran una hora. No es un sistema de factura tributaria FEL.