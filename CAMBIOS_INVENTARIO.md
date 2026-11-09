# Actualización de inventario

Se incorporó el módulo **Inventario** con acceso desde la navegación y desde Inicio. Incluye:
- Stock actual por variante y advertencias de existencias bajas o agotadas.
- Consulta de lotes en orden de antigüedad y ubicación de bodega.
- Historial de los últimos 200 movimientos de inventario, con filtro por tipo.
- Búsqueda por SKU o nombre de producto.

Los registros son consultados desde las tablas existentes (`LoteInventario`, `MovimientoInventario`) y la vista `vw_InventarioActual`. La entrada de mercancía se hace desde **Compras → Registrar recepción**. Las salidas se registran automáticamente al facturar mediante el procedimiento almacenado existente. No se requiere crear tablas nuevas.

**Instalación:** instalar dependencias indicadas en `app/requirements.txt`, configurar `app/.env` y ejecutar los scripts SQL del proyecto en el orden indicado por su documentación.

**Limitación de las pruebas:** Se comprobó la sintaxis de los archivos Python, pero no se probó una conexión a SQL Server ni la ejecución integral de Django en este entorno. Se recomienda validar la navegación, las existencias, las recepciones y la facturación en su entorno antes de presentar.
