# Cambios de la fase final

Comparación contra el ZIP entregado por el usuario. Los scripts 01–05 se conservan sin cambios.

## Implementación

- Identidad automática y creación activa; edición por ID de ruta.
- Mantenimientos ampliados y cambios de estado autorizados por POST.
- Navegación responsive, tablas con búsqueda/filtro/orden/páginas y confirmación modal.
- Seguridad de sesiones, contraseña inicial y permisos por rol/módulo.
- Refuerzo de facturación/cotización/recepción, exactitud de pagos y numeración secuencial.
- Anulación y devoluciones con asignación a lotes originales y auditoría.
- Siete reportes SQL, vista previa y PDF.
- 28 pruebas automatizadas, guion SQL y documentación.

## Archivos modificados

- `.gitignore`
- `README.md`
- `app/.env.example`
- `app/catalogos/forms.py`
- `app/catalogos/repositories.py`
- `app/catalogos/urls.py`
- `app/catalogos/views.py`
- `app/comercial/urls.py`
- `app/comercial/views.py`
- `app/config/settings.py`
- `app/config/urls.py`
- `app/core/context_processors.py`
- `app/core/decorators.py`
- `app/core/permissions.py`
- `app/requirements.txt`
- `app/seguridad/forms.py`
- `app/seguridad/management/commands/crear_admin.py`
- `app/seguridad/repositories.py`
- `app/seguridad/services.py`
- `app/seguridad/views.py`
- `app/static/css/site.css`
- `app/static/js/comercial.js`
- `app/templates/base.html`
- `app/templates/catalogos/form.html`
- `app/templates/catalogos/list.html`
- `app/templates/comercial/compra_form.html`
- `app/templates/comercial/compras.html`
- `app/templates/comercial/cotizacion_form.html`
- `app/templates/comercial/cotizaciones.html`
- `app/templates/comercial/factura_form.html`
- `app/templates/comercial/factura_print.html`
- `app/templates/comercial/facturas.html`
- `app/templates/comercial/inventario.html`
- `app/templates/comercial/inventario_lotes.html`
- `app/templates/comercial/inventario_movimientos.html`
- `app/templates/comercial/producto_form.html`
- `app/templates/comercial/recepcion_form.html`
- `app/templates/core/dashboard.html`
- `app/templates/seguridad/login.html`
- `app/templates/seguridad/usuario_form.html`
- `app/templates/seguridad/usuarios_list.html`

## Archivos nuevos

- `AUDITORIA.md`
- `Iniciar.ps1`
- `Instalar.ps1`
- `VALIDACION.md`
- `app/catalogos/extended.py`
- `app/catalogos/extended_views.py`
- `app/comercial/final_views.py`
- `app/core/middleware.py`
- `app/core/tests.py`
- `app/reportes/__init__.py`
- `app/reportes/pdf.py`
- `app/reportes/repositories.py`
- `app/reportes/services.py`
- `app/reportes/views.py`
- `app/requirements-test.txt`
- `app/static/js/site.js`
- `app/templates/comercial/anular.html`
- `app/templates/comercial/cotizacion_detalle.html`
- `app/templates/comercial/devolucion.html`
- `app/templates/reportes/index.html`
- `database/06_FaseFinal_Mejoras.sql`
- `database/07_Anulaciones_Reportes.sql`
- `database/08_Pruebas_Integracion.sql`

## SQL añadido

06: altas activas, orden, autorizaciones, catálogo comercial activo y flujos transaccionales.
07: tablas de auditoría/devoluciones, anulación y procedimientos de reportes.
08: escenarios de integración transaccional para ejecutar en desarrollo.

## Validación

Consultar VALIDACION.md. La conexión SQL real no estuvo disponible; no se declara validación de extremo a extremo.
