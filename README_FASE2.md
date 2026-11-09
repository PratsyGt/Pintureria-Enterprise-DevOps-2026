# Pinturería 2026 — Fase 2

## Qué se agregó
- Módulo Django `comercial` con páginas para cotizaciones, facturas/impresión, órdenes de compra y recepción de bodega.
- Procedimientos SQL Server para crear cotizaciones, emitir facturas de forma transaccional, crear órdenes y registrar recepciones parciales/completas.
- La facturación descuenta lotes por antigüedad (`FechaIngreso`, `LoteID`: PEPS/FIFO) y registra `SalidaLoteFactura` y `MovimientoInventario`.
- La transacción revierte la factura, pagos y movimientos si alguna validación falla.
- JSON se usa como parámetro de detalle para procesar varios renglones en un SP.
- Vista `vw_FacturasImpresion` y plantilla imprimible mediante el diálogo del navegador.

## Instalación
1. En SQL Server Management Studio, ejecutar en orden:
   - `database/01_PintureriaDB_Fase1.sql`
   - `database/02_Datos_Demo.sql`
   - `database/04_Fase2_Comercial.sql`
2. Verificar que haya clientes, proveedores, productos con variantes, medios de pago, ubicaciones y lotes de inventario. Para facturar, las variantes necesitan stock en `LoteInventario`.
3. En `app`, crear el entorno virtual, instalar `requirements.txt` y configurar `.env` con los datos de SQL Server.
4. Ejecutar `python manage.py runserver` y entrar con un usuario creado por el comando de administración ya incluido en el proyecto.

## JSON de ejemplo
- Cotización: `[ {"varianteId": 1, "cantidad": 2, "descuento": 0} ]`
- Factura directa: `[ {"varianteId": 1, "cantidad": 2, "descuento": 0} ]`. El precio se toma del catálogo de SQL Server; no se confía en el precio enviado por el navegador.
- Pagos: `[ {"medioPagoId": 1, "monto": 200, "referencia": ""} ]`. La suma debe coincidir con el total de la factura.
- Orden de compra: `[ {"varianteId": 1, "cantidad": 10, "costo": 55.00} ]`
- Recepción: `[ {"ordenCompraDetalleId": 1, "cantidad": 5, "ubicacionId": 1, "codigoLote": "L-001", "costo": 55.00} ]`

Los ID de los ejemplos son ilustrativos: deben sustituirse por identificadores que existan en tu base de datos. En una recepción parcial, la cantidad recibida es la cantidad de ESTA entrega, no el acumulado.

## Arquitectura
- Presentación: plantillas Django (`templates/comercial`).
- Controladores: `comercial/views.py`.
- Acceso a datos: `core/db.py` usando parámetros SQL y procedimientos almacenados.
- Persistencia/reglas críticas: SQL Server y transacciones en los SP.

## Pendiente de validar en el equipo local
Este entorno no tiene una instancia de SQL Server conectada, por lo que no es posible ejecutar los scripts ni confirmar conectividad real. Ejecuta los SQL en la base de desarrollo y prueba los flujos con datos demo antes de entregar. El script original de Fase 1 no se modifica; la ampliación va en `04_Fase2_Comercial.sql`.
