from core.db import execute_query

def consultar(tipo,desde,hasta):
    if tipo=='ventas': return execute_query('EXEC dbo.sp_Reporte_Ventas @Desde=%s,@Hasta=%s',[desde,hasta])
    if tipo in ('ingresos','cantidad','menos'):
        return execute_query('EXEC dbo.sp_Reporte_Productos @Desde=%s,@Hasta=%s,@Orden=%s',[desde,hasta,tipo])
    if tipo=='inventario': return execute_query('EXEC dbo.sp_Reporte_Inventario')
    if tipo=='sin_stock': return execute_query('EXEC dbo.sp_Reporte_SinStock')
    raise ValueError('Reporte desconocido')

def factura(numero):
    cab=execute_query("SELECT f.*,c.Nombre AS Cliente,c.NIT,u.Nombres+' '+u.Apellidos AS Empleado,a.TotalOriginal FROM dbo.Factura f JOIN dbo.Cliente c ON c.ClienteID=f.ClienteID JOIN dbo.Usuario u ON u.UsuarioID=f.UsuarioID LEFT JOIN dbo.FacturaAnulacion a ON a.FacturaID=f.FacturaID WHERE f.NumeroFactura=%s",[numero],one=True)
    if not cab: return None,[],[]
    detalle=execute_query('SELECT d.FacturaDetalleID,v.SKU,v.Producto,v.Presentacion,v.Color,d.Cantidad,d.PrecioUnitario,d.Descuento,ROUND(d.Cantidad*d.PrecioUnitario,2)-d.Descuento AS Importe FROM dbo.FacturaDetalle d JOIN dbo.vw_ProductosCatalogo v ON v.VarianteID=d.VarianteID WHERE d.FacturaID=%s ORDER BY d.FacturaDetalleID',[cab['FacturaID']])
    pagos=execute_query('SELECT m.Nombre AS Medio,p.Monto,p.Referencia FROM dbo.PagoFactura p JOIN dbo.MedioPago m ON m.MedioPagoID=p.MedioPagoID WHERE p.FacturaID=%s ORDER BY p.PagoFacturaID',[cab['FacturaID']])
    return cab,detalle,pagos
