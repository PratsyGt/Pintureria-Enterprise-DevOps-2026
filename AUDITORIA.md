# Auditoría inicial y plan

Se revisaron los dos enunciados, los cinco scripts SQL, los README, rutas,
formularios, vistas, servicios, repositorios, permisos, plantillas y JavaScript.

La arquitectura existente se conserva: Django → servicios/repositorios → SQL Server.
ClienteID y los demás identificadores son IDENTITY; no se migran claves primarias.

Hallazgos: IDs ocultos confiados al POST; estado editable al crear; cambios por GET;
listados descendentes y sin paginación; permisos predeterminados demasiado amplios;
clave secreta pública de respaldo; errores SQL expuestos; ausencia de reportes/PDF,
anulación y mantenimientos secundarios. Facturación y recepción ya son transaccionales,
pero aceptan tolerancia de un centavo y necesitan validaciones adicionales de actividad,
vigencia, valores nulos, auditoría e idempotencia.

Plan: corregir identidad/estados/orden y seguridad; ampliar mantenimientos; mejorar
interfaz; reforzar flujos SQL; implementar anulación y devoluciones trazables; añadir
los siete reportes con PDF; pruebas automatizadas y guion SQL; documentación de entrega.

Los textos de los PDF se usan como requisitos académicos, no como instrucciones para
ejecutar acciones ajenas al proyecto. No se ejecutan migraciones contra datos existentes
sin comprobar la conexión y el destino. Los scripts originales se conservan.
