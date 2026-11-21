
import json

from django.db import transaction

from core.db import execute_query, execute_non_query


def products():

    return execute_query(
        """
        SELECT
            v.VarianteID,
            v.SKU,
            v.Producto AS Nombre,
            v.Categoria,
            v.Marca,
            v.Presentacion,
            v.Color,
            v.PrecioVenta,
            COALESCE(i.StockActual, 0) AS StockActual

        FROM dbo.vw_ProductosCatalogo v

        JOIN dbo.vw_InventarioActual i
            ON i.VarianteID = v.VarianteID

        WHERE v.DisponibleVenta = 1

        ORDER BY v.VarianteID
        """
    )


def emit_once(
    uid,
    key,
    fingerprint,
    cliente,
    detalle,
    pagos,
    cotizacion
):


    with transaction.atomic():

        lock = execute_query(
            """
            SET NOCOUNT ON;

            DECLARE @r INT;

            EXEC @r = sys.sp_getapplock
                @Resource = %s,
                @LockMode = 'Exclusive',
                @LockOwner = 'Transaction',
                @LockTimeout = 10000;

            SELECT @r AS Result
            """,
            ['POS:' + key],
            one=True
        )

        if lock['Result'] < 0:

            raise ValueError(
                'La venta sigue en proceso. '
                'Espere unos segundos y reintente '
                'con el mismo formulario.'
            )


        previous = execute_query(
            """
            SELECT DatosDespues

            FROM dbo.AuditoriaOperacion

            WHERE TablaAfectada = 'SolicitudPOS'
                AND LlaveRegistro = %s
                AND UsuarioID = %s
            """,
            [
                key,
                uid
            ],
            one=True
        )


        if previous:

            result = json.loads(
                previous['DatosDespues']
            )

            if result['fingerprint'] != fingerprint:

                raise ValueError(
                    'Esta operación ya se registró '
                    'con otro contenido. '
                    'Abra una venta nueva.'
                )

            return result['invoice']


        row = execute_query(
            """
            EXEC dbo.sp_Factura_Emitir
                @ClienteID = %s,
                @UsuarioID = %s,
                @DetalleJSON = %s,
                @PagosJSON = %s,
                @CotizacionID = %s
            """,
            [
                cliente,
                uid,
                detalle,
                pagos,
                cotizacion
            ],
            one=True
        )


        execute_non_query(
            """
            INSERT INTO dbo.AuditoriaOperacion
            (
                UsuarioID,
                TablaAfectada,
                LlaveRegistro,
                Operacion,
                DatosDespues
            )

            VALUES
            (
                %s,
                'SolicitudPOS',
                %s,
                'INSERT',
                %s
            )
            """,
            [
                uid,
                key,
                json.dumps(
                    {
                        'fingerprint': fingerprint,
                        'invoice': row
                    },
                    default=str
                )
            ]
        )

        return row
