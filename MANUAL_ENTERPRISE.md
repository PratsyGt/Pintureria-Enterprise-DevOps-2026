# Manual breve — Pinturería Enterprise POS

## Iniciar

En esta carpeta ejecute `./Iniciar.ps1` desde PowerShell y abra http://127.0.0.1:8000/. La configuración local está en `app/.env`: servidor `.\SQLEXPRESS`, base PintureriaDB. Use su usuario habitual. Para una instalación desde ZIP siga README.md; el ZIP excluye credenciales y entorno virtual.

## Navegar y consultar

El botón superior contrae el menú en escritorio y abre el menú móvil. Escape cierra el drawer. El perfil permite consultar la sesión y salir. Alt+B enfoca el buscador de la pantalla. La lista de opciones depende de sus permisos.

En Resumen seleccione fechas y Actualizar período. Ventas de hoy/mes mantienen sus períodos propios; facturas/ticket/gráficas usan el intervalo seleccionado. Ver cifras del gráfico muestra la tabla accesible. Los importes son facturación bruta vigente; las devoluciones quedan en su historial.

Los listados ofrecen buscar, estado, orden y paginación. Facturas, cotizaciones y compras admiten fechas completas. Aplicar consulta el servidor; la URL permite guardar los filtros. En Proveedores, Historial de compras abre las órdenes del proveedor seleccionado. Los lotes se muestran inicialmente por fecha de ingreso e ID.

## Vender

1. Abra Punto de venta. Busque nombre o SKU; filtre categoría/marca si lo necesita.
2. Agregue productos, seleccione cliente, ajuste cantidades y descuentos. Las existencias visibles se vuelven a validar al emitir.
3. Pulse Cobrar. Revise el cliente y total. Puede agregar varios medios de pago; la suma debe ser exacta.
4. Confirme y espere la respuesta. El botón queda bloqueado durante el envío. La factura y el mensaje de éxito aparecen después de guardar.
5. Imprima el comprobante. Si la conexión falla, reintente con el mismo formulario: el token impide emitir otra factura por la misma operación. Abrir una venta nueva representa una operación nueva.

Para facturar una cotización confirmada use su enlace Facturar o el selector del carrito. Se conservan las líneas y precios de la cotización. El carrito directo queda apartado mientras se factura esa cotización. En móvil se muestran seis productos por página y existe el enlace Ir al carrito.

## Compras, cotizaciones y cambios de estado

Cree una cotización con sus líneas, guárdela y confírmela antes de facturar. Cree una orden de compra y registre lo realmente recibido: una entrega parcial deja saldo pendiente; al completarlo cambia a COMPLETA. Indique ubicación y lote en cada recepción.

Activar/desactivar mantiene el historial y solicita confirmación. Las anulaciones se consultan por número; revise el documento, escriba el motivo, marque la confirmación y acepte el diálogo. La restitución se registra en los lotes originales y la factura conserva su detalle histórico. Las devoluciones parciales se abren desde la factura.

## Reportes y accesibilidad

En Reportes seleccione uno de los siete tipos y sus parámetros. Consulte primero; exporte PDF/CSV o imprima. El PDF/CSV contiene todas las filas devueltas por los filtros, no solo una página visual. En consulta de factura ingrese el número comercial, por ejemplo P26-7.

La preferencia de movimiento reducido del sistema operativo se respeta automáticamente. Puede operar por teclado y cerrar diálogos con Escape antes de confirmar. Las notificaciones de error permanecen visibles hasta cerrarlas. Si hay un error al filtrar, se conservan los datos anteriores: vuelva a consultar antes de tratarlos como actualizados.
