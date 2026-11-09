# Validación realizada — 2 de noviembre de 2026

## Ejecutado y aprobado

- `python app/manage.py check`: 0 problemas.
- `python app/manage.py test core`: 28 pruebas aprobadas sin conexión SQL.
- Compilación de todos los módulos Python: aprobada.
- `node --check` de `comercial.js` y `site.js`: aprobado.
- Compilación de todas las plantillas Django, incluidos enlaces y formularios.
- Navegador Edge headless: clientes, formulario de cliente, dashboard, factura desde cotización y reportes a 390, 768 y 1440 px. 15 combinaciones sin desbordamiento global ni errores de JavaScript después de corregir facturación móvil.
- Búsqueda de un registro de la última página entre 61 registros: resultado único correcto.
- Cotización preseleccionada: editor directo deshabilitado, pago inicial 20.00 y diferencia 0.00.
- PDF con 150 filas: múltiples páginas, texto escapado y última fila presente. PDF de inventario con 69 filas renderizado e inspeccionado visualmente: encabezado, celdas y pie legibles.

Los HTML y PDF de prueba usaron fixtures explícitos bajo `tmp/qa`, aislados de la aplicación. No son evidencia de datos SQL reales. Los reportes del producto consultan únicamente SQL Server.

## Cobertura de las pruebas Python

IDs y estado fuera de formularios de alta; ID manipulado ignorado al crear/editar; conservación del estado al editar; rechazo de cambios por GET; CSRF; login/logout; revocación por inactividad o contraseña cambiada; permiso de solo consulta; contraseñas obligatorias; exclusión de facturación del Digitador; JSON duplicado, cantidades negativas/no finitas, precisión, ubicación fraccionaria, medios de pago; fechas de reportes; factura inexistente; consultas a repositorios; PDF y plantillas.

## No validado contra SQL Server

El controlador ODBC 18 está instalado, pero la conexión con timeout corto a `localhost\SQLEXPRESS`, base PintureriaDB y autenticación de Windows devolvió error 08001 (instancia inaccesible). No se ejecutaron los scripts SQL ni se modificaron bases existentes. Los procedimientos y triggers fueron revisados en código; su compilación y comportamiento real siguen pendientes.

Ejecute `database/08_Pruebas_Integracion.sql` en una base de desarrollo después de 01/04/05/06/07. Esperado: siete mensajes OK para flujo completo, stock insuficiente, diferencia de un centavo, sobre-recepción, sobre-devolución, doble anulación y doble facturación de cotización. Cada escenario revierte sus fixtures. Los huecos en IDENTITY/SEQUENCE no son fallos.

## Lista de comprobación manual con SQL Server

1. Crear gerente y entrar. Crear Digitador y Cajero con permisos del rol; comprobar rutas denegadas y permisos personalizados.
2. Crear cliente sin ID ni Activo. Editarlo y comprobar que conserva el mismo ID. Desactivar por POST, consultar historial y volver a activar.
3. Crear categoría, marca, presentación, producto y variante. Intentar repetir SKU/código único: rechazo sin pérdida del original.
4. Crear compra de 100; recibir 75 y luego 25. Ver PARCIAL/COMPLETA, lotes y movimientos.
5. Cotizar dos variantes, confirmar, emitir con dos medios de pago y revisar impresión. Reintentar la misma cotización: rechazo.
6. Factura directa con cantidades fraccionarias: suma de importes redondeados a dos decimales = pagos.
7. Devolver parcialmente una línea y anular después. Suma final de existencias = anterior a la venta; pagos y salidas permanecen históricos, total vigente cero.
8. Comparar los siete reportes con consultas SQL independientes. Verificar límites de fechas, anuladas, cero ventas y distintos tamaños de presentación. Descargar cada PDF.
9. Abrir dos sesiones y competir por el último stock, por la misma cotización y por anulación/devolución. Solo una operación incompatible debe prosperar. Revisar bloqueos y reintentos por deadlock si el volumen aumenta.
10. Apagar temporalmente SQL Server en desarrollo: mostrar error comprensible y no una confirmación de éxito. Reactivar y comprobar datos íntegros.

## Límites conocidos

- La paginación/búsqueda de tablas es local sobre el resultado completo, pensada para el proyecto académico.
- La caja no integra un banco ni FEL; registra los medios de pago ingresados.
- Los reportes de ventas son brutos facturados, excluyen anulaciones; devoluciones y reembolsos son conceptos separados.
- Una devolución previa que no tenga lote conciliado bloquea la anulación para evitar duplicar stock.
- No se probó despliegue público, carga masiva ni recuperación de backups.
