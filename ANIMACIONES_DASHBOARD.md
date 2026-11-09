# Animaciones del dashboard

La entrada se ejecuta al abrir el resumen comercial. La etiqueta Git `antes-animaciones-dashboard` identifica la versión anterior (75ac785) en esta carpeta. Para ver el resultado, abre `docs/evidencia/animaciones/entrada-dashboard.webm`. Es una captura de Edge con la aplicación Django conectada a la base aislada de QA.

## Auditoría

El contador anterior duraba 260 ms y guardaba cada valor visto en sessionStorage. Al regresar a la página, esa condición omitía el contador y la clase de entrada de su tarjeta. Las reglas de gráficas buscaban .chart-line y .bar-fill, mientras el dashboard violeta renderiza .curve, .ring-piece y .rank em. La hoja executive.css únicamente aplicaba un fundido a parte de esos elementos.

## Secuencia y ajustes

Las variables de tiempo están en el bloque «Dashboard timing» de `app/static/css/motion.css`. Cambia `--motion-speed` de 1 a 0.8 para reducir la duración un 20 %, o a 1.2 para aumentarla un 20 %. El multiplicador controla tiempos y retrasos de la presentación. El contador lee las mismas variables desde JavaScript.

| Elemento | Inicio y duración con velocidad 1 |
| --- | --- |
| Sidebar de escritorio | Entra desde la izquierda durante 390 ms. Los iconos empiezan cada 27 ms hasta el octavo retraso. |
| Header, saludo y perfil | El header empieza a los 90 ms y dura 400 ms. Saludo y controles comienzan a los 170 ms. |
| Tarjetas | La primera empieza a los 300 ms. Cada tarjeta entra desde 20 px más abajo durante 480 ms, con 90 ms entre tarjetas. |
| Contadores | 820 ms desde el inicio de cada tarjeta. Las cantidades monetarias conservan los dos decimales y el prefijo Q. |
| Gráficas | La primera entrada empieza a los 780 ms y dura 620 ms. Se dibuja la línea SVG, crecen las barras y se revelan los arcos de la dona. |
| Actividad e inventario | Cada panel entra una vez al alcanzar la zona visible. Los visibles inicialmente esperan hasta la etapa de 1040 ms. La entrada dura 410 ms, con 65 ms entre paneles de una misma tanda. |

`--kpi-start-ms`, `--kpi-step-ms` y `--counter-ms` son números en milisegundos. `--chart-start` y `--chart-time` son duraciones CSS. Con seis tarjetas, el contador de la sexta puede terminar a los 1570 ms. Un valor de cero se presenta directamente. Los cambios de período interpolan desde el valor previo cuando cambia la cifra. El indicador de carga sigue ligado a la petición real.

## Archivos

- `app/templates/base.html` y `app/templates/core/dashboard.html` cargan los recursos, definen la longitud del trazo SVG, pasan la participación real de cada segmento y habilitan la consulta del dashboard sin JavaScript.
- `app/static/css/motion.css` coordina la secuencia, el hover de tarjetas y los tooltips. `app/static/css/executive.css` deja de aplicar el fundido anterior a las mismas gráficas.
- `app/static/js/dashboard-motion.js` administra los contadores con un bucle requestAnimationFrame, revela los paneles con IntersectionObserver y finaliza las animaciones al ocultar la pestaña o activar movimiento reducido.
- `app/static/js/site.js` avisa al dashboard cuando una consulta ha reemplazado sus datos. `app/static/js/dashboard.js` gestiona los cambios de vista y las ayudas de los iconos en el menú compacto.

## Verificación

Pasaron las 38 pruebas Django. La comprobación de navegador se hizo desde esta instalación contra la base SQL de QA, en Edge de escritorio a 1366 × 900 y con viewport móvil a 390 × 844. Las hojas de estilo y los tres scripts del dashboard respondieron con HTTP 200. La última ejecución terminó sin errores de consola ni de JavaScript.

Se capturaron 92 fotogramas de la presentación. Los comienzos observados de las seis tarjetas, medidos respecto al primero, fueron 0, 83, 166, 265, 348 y 448 ms. Se observaron valores intermedios en el contador, el valor final de Q252.00 y opacidad final completa. Se verificaron los eventos de dibujo de línea, barras y segmentos, la aparición de la actividad al desplazarse, los controles de sidebar y la consulta filtrada. La grabación WebM se reprodujo hasta el final.

Con movimiento reducido se comprobó que las tarjetas ya presentaban sus valores finales al cargar. También se abrió el dashboard con JavaScript desactivado y se verificó la disponibilidad del menú alternativo y de las tres vistas de ventas. El lector de pantalla recibe un valor final separado del número visual en movimiento. La validación de accesibilidad se realizó en el navegador y no incluyó una sesión manual con lector de pantalla. Los tiempos son observaciones en Edge y pueden variar según el hardware.
