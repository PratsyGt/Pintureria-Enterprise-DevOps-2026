"""Install the original schema on a fresh, private SQL Server container only."""
import os
import re
import time
from pathlib import Path

import pyodbc


def connect():
    # Fixed internal service and database prevent accidental use against Windows.
    password = os.environ['MSSQL_SA_PASSWORD'].replace('}', '}}')
    dsn = ('DRIVER={ODBC Driver 18 for SQL Server};SERVER=db,1433;DATABASE=master;'
           'UID=sa;Encrypt=yes;TrustServerCertificate=yes;PWD={' + password + '}')
    for attempt in range(60):
        try:
            return pyodbc.connect(dsn, autocommit=True, timeout=4)
        except pyodbc.OperationalError:
            if attempt == 59:
                raise
            time.sleep(2)


def drain(cursor):
    while cursor.nextset():
        pass


def grant_runtime_permissions(cursor):
    # Include explicitly the tables used via the catalog registry's dynamic SQL.
    readable = """
        AuditoriaOperacion Categoria Cliente ColorProducto Cotizacion CotizacionDetalle
        DevolucionVenta DevolucionVentaDetalle Factura FacturaAnulacion FacturaDetalle
        LoteInventario Marca MedioPago MovimientoInventario OrdenCompra OrdenCompraDetalle
        PagoFactura Presentacion Producto ProductoVariante Proveedor Rol Ubicacion
        UnidadMedida Usuario UsuarioPermiso vw_InventarioActual vw_ProductosCatalogo vw_UsuariosRoles
    """.split()
    for table in readable:
        cursor.execute(f'GRANT SELECT ON dbo.{table} TO pos_app')
    procedures = [
        f'sp_{catalog}_{action}'
        for catalog in ('Categoria','Cliente','Marca','Proveedor','Usuario')
        for action in ('CambiarEstado','Guardar','Listar','Obtener')
    ]
    procedures.extend("""
        sp_Compra_Recibir sp_Cotizacion_Confirmar sp_Cotizacion_Crear sp_DashboardResumen
        sp_Devolucion_Registrar sp_Factura_Anular sp_Factura_Emitir sp_OrdenCompra_Crear
        sp_Reporte_Inventario sp_Reporte_Productos sp_Reporte_SinStock sp_Reporte_Ventas
        sp_Rol_Listar sp_UsuarioObtenerPorNombre sp_UsuarioRegistrarAcceso
    """.split())
    for procedure in procedures:
        cursor.execute(f'GRANT EXECUTE ON dbo.{procedure} TO pos_app')
    for table in ('UnidadMedida','Presentacion','ColorProducto','Ubicacion','Producto','ProductoVariante'):
        cursor.execute(f'GRANT INSERT, UPDATE ON dbo.{table} TO pos_app')
    cursor.execute('GRANT INSERT, DELETE ON dbo.UsuarioPermiso TO pos_app')
    cursor.execute('GRANT INSERT ON dbo.AuditoriaOperacion TO pos_app')


def main():
    with connect() as conn:
        cursor = conn.cursor()
        lock = cursor.execute("""
            SET NOCOUNT ON; DECLARE @r int;
            EXEC @r=sys.sp_getapplock @Resource='PintureriaBootstrap',@LockMode='Exclusive',
                @LockOwner='Session',@LockTimeout=120000; SELECT @r;
        """).fetchval()
        if lock < 0:
            raise RuntimeError('No se obtuvo el bloqueo de instalación.')
        if cursor.execute("SELECT DB_ID('PintureriaDB')").fetchval() is not None:
            cursor.execute('USE PintureriaDB')
            if cursor.execute("SELECT COUNT(*) FROM sys.extended_properties WHERE class=0 AND name='PintureriaInstallV1'").fetchval():
                print('Instalación ya completada.')
                return
            raise RuntimeError('Base existente sin marca de instalación. Requiere revisión manual.')
        root = Path('/srv/database')
        for prefix in ('01','04','05','06','07'):
            script, = root.glob(prefix + '_*.sql')
            print('Aplicando', script.name, flush=True)
            for batch in re.split(r'^\s*GO\s*$', script.read_text(encoding='utf-8-sig'), flags=re.I|re.M):
                if batch.strip():
                    drain(cursor.execute(batch))
        password = os.environ['DB_PASSWORD']
        if not 12 <= len(password) <= 128:
            raise ValueError('DB_PASSWORD requiere entre 12 y 128 caracteres.')
        # SQL DDL requires a literal. QUOTENAME safely quotes the parameter on the server.
        cursor.execute("""DECLARE @pwd nvarchar(128)=?;
            DECLARE @sql nvarchar(max)='CREATE LOGIN pos_app WITH PASSWORD='+QUOTENAME(@pwd,CHAR(39))+', CHECK_POLICY=ON';
            EXEC(@sql)""", password)
        cursor.execute('CREATE USER pos_app FOR LOGIN pos_app')
        grant_runtime_permissions(cursor)
        cursor.execute("EXEC sys.sp_addextendedproperty @name='PintureriaInstallV1',@value=1")
        print('Base preparada y usuario pos_app creado.')


if __name__ == '__main__':
    main()
