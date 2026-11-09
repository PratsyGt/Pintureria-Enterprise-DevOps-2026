# Mejoras Enterprise POS

Fecha: 4 de noviembre de 2026. Base: entrega final Django + SQL Server existente.

## Conservación y arquitectura

Restauración Git inicial: `6d281ac`, rama `codex/enterprise-pos`. Se trabajó en esta copia del proyecto, conservando la carpeta original. No se modificaron los scripts SQL, las claves primarias ni los procedimientos financieros. No se escribieron datos de prueba en PintureriaDB. Las credenciales, `.env`, `.venv` y temporales quedan fuera de Git y del ZIP.

Nuevos módulos: `core/dashboard_repository.py`, `dashboard_services.py`, `pagination.py`, `navigation.py`; `comercial/pos_repository.py`, `pos_services.py`. Las plantillas siguen siendo Django y el navegador usa JavaScript nativo, SVG y CSS. No se añadieron frameworks ni librerías de animación. Tipografía local disponible: Inter/Segoe UI/Arial, sin solicitudes a servicios de fuentes.

## Interfaz y módulos

- Tokens de color, espaciado, tipografía, superficies y estados en `site.css`; componentes compartidos en `templates/components`.
- Sidebar compacto con preferencia local, drawer móvil con foco controlado, Escape, fondo inerte, ruta activa única, perfil y búsqueda contextual Alt+B.
- Dashboard con ventas del día/mes, facturas, ticket, productos, faltantes y compras pendientes; series diarias/mensuales, ingresos por variante, pagos y actividad reciente. Las cifras financieras se consultan solo con permiso de reportes. Se excluyen anulaciones; devoluciones conservan su tratamiento bruto histórico.
- POS de catálogo/carrito con SKU, categoría, marca, stock, cantidades fraccionarias, descuentos, cliente y cotización. Carrito recuperado desde el POST cuando falla la operación. No almacena datos de clientes en localStorage.
- Cobro en diálogo, pagos combinados y validación exacta de importes. El cálculo visual usa enteros escalados BigInt; SQL recalcula y autoriza precios, stock y totales.
- Listados paginados en SQL: mantenimientos, usuarios, productos, facturas, cotizaciones, compras, inventario, lotes y movimientos. Búsqueda parametrizada, estado, orden permitido y desempate estable. Fechas inclusivas en facturas/cotizaciones/compras. Historial de proveedor enlazado desde su mantenimiento.
- Formularios comerciales recuperan campos y líneas tras errores. Acciones sensibles conservan confirmación explícita y CSRF; las opciones visibles respetan permisos.
- Los siete reportes conservan su lógica y añaden CSV con protección de fórmulas en texto. PDF paginado existente comprobado con resultados reales de QA. Impresión identificada como comprobante interno, sin atribuir certificación fiscal.

## Prevención de doble emisión

Cada formulario POS recibe un token firmado de 24 horas ligado al usuario. El servidor toma un bloqueo SQL transaccional `sp_getapplock`, verifica la huella del contenido y registra el resultado en la tabla existente AuditoriaOperacion, tipo SolicitudPOS. Factura y auditoría se confirman juntas. Un reintento idéntico obtiene la factura previa; otro contenido con el mismo token se rechaza. No cambió el SP de facturación. La cuenta SQL debe poder ejecutar el bloqueo de aplicación y escribir auditoría dentro de la transacción.

El navegador deshabilita el envío durante el proceso. La confirmación de éxito llega exclusivamente del backend. Esta protección específica de reintentos corresponde al POS; otros formularios tienen bloqueo visual y las reglas transaccionales preexistentes.

## Animaciones y accesibilidad

`motion.css` concentra entradas de tarjetas, indicador activo, página, login, modales y notificaciones. Duraciones habituales: 140, 180, 200, 220 y 280 ms. Los contadores duran 260 ms, conservan el texto final y evitan repetir valores ya vistos durante la sesión. Las gráficas usan SVG/CSS y transform/opacity.

`site.js` proporciona `Enterprise.notify`, `confirm`, `pulse`, `remove` y cierre de diálogos. Las notificaciones éxito/error/advertencia/información usan iconos SVG, roles status/alert, cierre con nombre accesible y permanecen hasta que se cierran. Filtrado y paginación muestran un indicador skeleton durante la petición real; los datos anteriores permanecen visibles. Un error de red los conserva.

`pos.js` anima entradas/salidas del carrito y cambios del total sin retrasar la transacción. `comercial.js` integra las entradas/salidas en cotizaciones y recepciones. No hay ciclos infinitos; skeleton y spinner tienen repeticiones acotadas y mantienen texto de estado al finalizar.

Se incluye la regla global prefers-reduced-motion para animaciones, transiciones y scroll; el JavaScript también consulta la preferencia. Escape, Tab y Alt+B fueron comprobados. El POS requiere JavaScript, pero ninguna función depende de que se reproduzca una animación.

## Validación y límites

Véase VALIDACION.md y `docs/evidencia/`. Las capturas corresponden exclusivamente a QA. Se comprobaron 66 combinaciones de pantallas/ancho en dos pasadas, además de diez rutas de escritorio. No hubo desbordamiento horizontal global ni errores de JavaScript en las ejecuciones finales.

No se midieron FPS en equipos físicos de caja ni carga con millones de registros. Se priorizan transform/opacity, eventos acotados y ausencia de dependencias pesadas; esto no garantiza 60 FPS en cualquier hardware. La fuente nativa puede cambiar ligeramente según el equipo. No se certifica accesibilidad con todos los lectores de pantalla ni compatibilidad con navegadores antiguos.

No incluye emisión FEL, integración bancaria, reembolsos externos ni despliegue público. Caché de intentos de login sigue siendo local al proceso; para varios procesos se necesita caché compartida. Las pruebas reales de navegador usaron gerente de QA; permisos de otros roles se cubrieron por contratos automatizados y procedimientos existentes, sin afirmar una certificación completa por rol en producción.
