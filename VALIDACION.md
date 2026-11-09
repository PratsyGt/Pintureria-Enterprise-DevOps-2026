# Validación Enterprise — 4 de noviembre de 2026

## Resultado actual

- Django check: cero problemas. 38 pruebas Python aprobadas, con mocks explícitos para contratos de base de datos.
- Node syntax check: site.js, pos.js y comercial.js aprobados.
- SQL Server real `.\SQLEXPRESS`, base aislada `PintureriaEnterpriseQA_2e667eb0`: scripts 01/02/04/05/06/07/08 ejecutados correctamente. No se escribieron fixtures ni ventas en PintureriaDB.
- Los siete escenarios SQL08 pasaron: flujo completo, stock insuficiente, pago con diferencia, exceso de recepción, exceso de devolución, doble anulación y cotización facturada dos veces.
- Navegador Edge headless con gerente QA: venta directa de Q126 mediante pagos Q100+Q26; reenvío del mismo POST produjo el mismo número de factura. La primera corrida del arnés esperó una ruta incorrecta tras una venta válida; se corrigió el arnés y se repitió. Por eso quedaron dos ventas directas legítimas, no una duplicación por reintento.
- Cotización de dos unidades Q126 menos Q2 de descuento, confirmada y facturada por Q250. Compra de cuatro unidades recibida en dos entregas (3+1), estados PARCIAL y COMPLETA. Anulación de la factura de Q250: cancelar el diálogo no ejecutó la operación; aceptar la confirmó.
- Conciliación SQL posterior: tres facturas históricas, dos vigentes, Q252 facturados vigentes; tres registros de idempotencia. Stock QA-001: lote antiguo18, lote reciente10, recepciones4 =32. La anulación devolvió al lote original. Reutilizar token con huella distinta fue rechazado, sin crear facturas.
- Siete reportes en HTML/PDF/CSV: respuestas correctas, PDF válidos. Inventario y consulta de factura renderizados e inspeccionados visualmente; tablas legibles y pies numerados.
- Diez rutas principales con HTTP200. Primera matriz: cinco pantallas por seis anchos (30). Segunda matriz: seis pantallas por seis anchos (36), incluyendo nuevos filtros y perfil. Anchos: 360,390,768,1024,1366,1920. Cero desbordamientos globales y cero errores de JavaScript en las corridas finales.
- Menú compacto/móvil, Escape, atajo Alt+B, cancelación de cobro y prefers-reduced-motion comprobados. Filtro SQL encuentra SKU QA-030. Fechas futuras excluyen facturas. Un HTTP500 simulado al filtrar conserva las filas previas y presenta error.

## Evidencia

`docs/evidencia/` contiene resultados JSON y capturas de QA sin contraseñas. Los valores de las capturas proceden de transacciones reales en la base aislada y no se inyectan en la aplicación. El informe de la etapa anterior se conserva en `docs/VALIDACION_ANTERIOR_2026-11-02.md`; su limitación de conexión fue resuelta en esta etapa.

La base QA se conserva separada para inspección en SSMS; el servidor temporal se detuvo al terminar. La configuración normal de la aplicación sigue apuntando a PintureriaDB.

## Repetición local

Ejecute `python app/manage.py check` y `python app/manage.py test core --verbosity 2` con el entorno del proyecto. El archivo database/08_Pruebas_Integracion.sql documenta escenarios SQL con rollback y debe ejecutarse solo en una base de desarrollo preparada con 01/04/05/06/07. Para repetir la QA visual, siga MANUAL_ENTERPRISE.md con datos propios de una base aislada; no use datos de prueba en la base habitual.

## Alcance de la evidencia

Los contratos cubren permisos, CSRF, sesiones, validación comercial, campos de alta, parámetros SQL, token ligado al usuario, caducidad, huellas y límites de fecha. No equivalen a una auditoría externa de seguridad. Las verificaciones SQL y de navegador son adicionales a los mocks. No se hicieron pruebas de carga masiva, medición de FPS en hardware físico ni certificación fiscal; consulte MEJORAS_ENTERPRISE.md.
