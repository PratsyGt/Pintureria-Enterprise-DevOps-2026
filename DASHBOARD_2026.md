# Dashboard ejecutivo de Pinturería Enterprise POS

El diseño del 9 de noviembre de 2026 toma del video la navegación lateral violeta, la cabecera compacta, los accesos rápidos junto al saludo y las tarjetas sobre un fondo claro. El abanico de muestras de pintura identifica la aplicación. En escritorio el menú empieza compacto y recuerda la elección del usuario. En móvil se abre como panel lateral.

## Uso y significado de los datos

El selector junto a «Resumen comercial» cambia el período. Las ventas del día y del mes corresponden al calendario actual. Las facturas emitidas, el ticket promedio, los cobros y los productos vendidos corresponden al intervalo elegido. Las cotizaciones pendientes, las compras por recibir y el inventario muestran el estado actual. Los permisos determinan qué tarjetas y enlaces se presentan.

«7 días» muestra hasta los últimos siete días del intervalo. «Mensual» agrupa las ventas por mes y «Período» muestra el detalle diario. El cobro por medio de pago suma los pagos registrados en facturas vigentes. El detalle de líneas sirve para ordenar las cinco variantes por cantidad vendida o por ingresos. Cada fila identifica el SKU y la presentación. Los tres cálculos consultan por separado facturas, pagos y detalles para que una factura con varios pagos no multiplique las ventas.

Las variaciones de ventas comparan el día con ayer y el mes hasta hoy con el tramo equivalente del mes anterior. Las facturas se comparan con el intervalo anterior de igual duración. El porcentaje requiere una base anterior positiva. Para los pendientes e inventario se presenta el conteo actual, ya que las consultas no ofrecen una fotografía histórica comparable.

La gráfica de ventas admite consulta por teclado y tabla de cifras. El movimiento reducido se toma de la preferencia del sistema. Alt+B enfoca la búsqueda contextual y, en el dashboard, abre un buscador de módulos permitidos. Escape cierra el buscador y el menú móvil.

## Archivos

| Archivos | Cambio |
| --- | --- |
| app/templates/base.html, app/static/js/site.js | Navegación compartida, acceso a venta, perfil, búsqueda de módulos y controles de teclado. |
| app/templates/core/dashboard.html | Saludo, seis indicadores por permisos, filtros, cinco visualizaciones y actividad enlazada. |
| app/static/css/executive.css, app/static/js/dashboard.js | Composición adaptable, controles de gráficas, foco y tooltips. Reutiliza site.css y motion.css. |
| app/static/img/brand-mark.svg, swatch-deck.svg en la misma carpeta | Icono de aplicación y muestrario vectorial local. |
| app/core/dashboard_repository.py, app/core/dashboard_services.py | Consultas de lectura, períodos comparables, agregación mensual, ranking y alertas. |
| app/core/pagination.py | Filtro parametrizado por ID para abrir una compra o movimiento concreto en su listado existente. |

## Comprobaciones

Se ejecutaron las 38 pruebas Django con las dependencias de prueba instaladas. Edge cargó el dashboard desde Django con un gerente de QA conectado a SQL Server. Se comprobó la carga de las hojas de estilo, los scripts y la ilustración. La ejecución final terminó sin errores de consola ni de JavaScript.

El filtro correspondiente al 4 de noviembre devolvió Q252.00 en ventas vigentes de la base aislada. También se probaron el cambio de gráfica después de actualizar filtros, las ayudas al enfocar puntos, los enlaces a registros individuales, la búsqueda de módulos, Escape, el menú móvil y el movimiento reducido. Se abrieron Punto de venta, Clientes y Reportes para verificar la plantilla compartida.

Las capturas de 360, 390, 768, 1024, 1366 y 1920 píxeles se encuentran en docs/evidencia/dashboard-violeta. Se revisaron en navegador con viewport emulado y sin desbordamiento horizontal general. El rendimiento en equipos físicos y otros motores de navegador queda fuera de esta prueba. Los saldos y documentos de las capturas pertenecen a la base de QA.

El punto de restauración Git anterior al cambio es la etiqueta respaldo-dashboard-20261109, en el commit 66f5475.

