from datetime import timedelta
from .db import execute_query

def sales_metrics(today, first, start, end):
    tomorrow = today + timedelta(days=1)
    previous_month = (first - timedelta(days=1)).replace(day=1)
    comparable_end = min(first, previous_month + timedelta(days=today.day))
    prior_start = start - (end - start)
    return execute_query("""
        SELECT
            SUM(CASE WHEN FechaFactura >= %s AND FechaFactura < %s THEN Total END) AS Hoy,
            SUM(CASE WHEN FechaFactura >= %s AND FechaFactura < %s THEN Total END) AS Ayer,
            SUM(CASE WHEN FechaFactura >= %s AND FechaFactura < %s THEN Total END) AS Mes,
            SUM(CASE WHEN FechaFactura >= %s AND FechaFactura < %s THEN Total END) AS MesAnterior,
            COUNT(CASE WHEN FechaFactura >= %s AND FechaFactura < %s THEN 1 END) AS Facturas,
            COUNT(CASE WHEN FechaFactura >= %s AND FechaFactura < %s THEN 1 END) AS FacturasPrevias,
            AVG(CASE WHEN FechaFactura >= %s AND FechaFactura < %s THEN Total END) AS Ticket
        FROM dbo.Factura
        WHERE Estado='EMITIDA' AND (
            (FechaFactura >= %s AND FechaFactura < %s) OR
            (FechaFactura >= %s AND FechaFactura < %s))
    """, [today, tomorrow, today-timedelta(days=1), today, first, tomorrow,
          previous_month, comparable_end, start, end, prior_start, start,
          start, end, previous_month, tomorrow, prior_start, end], one=True)


def daily(start,end):
    return execute_query("SELECT CAST(FechaFactura AS DATE) AS Fecha,SUM(Total) AS Total FROM dbo.Factura WHERE Estado='EMITIDA' AND FechaFactura>=%s AND FechaFactura<%s GROUP BY CAST(FechaFactura AS DATE) ORDER BY Fecha",[start,end])

def monthly(start,end):
    return execute_query("SELECT YEAR(FechaFactura) AS Anio,MONTH(FechaFactura) AS Mes,SUM(Total) AS Total FROM dbo.Factura WHERE Estado='EMITIDA' AND FechaFactura>=%s AND FechaFactura<%s GROUP BY YEAR(FechaFactura),MONTH(FechaFactura) ORDER BY Anio,Mes",[start,end])

def top_products(start, end, measure='quantity'):
    # Both orders are fixed SQL expressions. Group by sellable variant / SKU.
    expression = 'SUM(d.Cantidad)' if measure == 'quantity' else 'SUM(ROUND(d.Cantidad*d.PrecioUnitario,2)-d.Descuento)'
    return execute_query(f"""
        SELECT TOP(5) v.VarianteID, v.SKU, v.Producto, v.Presentacion, {expression} AS Total
        FROM dbo.FacturaDetalle d
        JOIN dbo.Factura f ON f.FacturaID=d.FacturaID
        JOIN dbo.vw_ProductosCatalogo v ON v.VarianteID=d.VarianteID
        WHERE f.Estado='EMITIDA' AND f.FechaFactura >= %s AND f.FechaFactura < %s
        GROUP BY v.VarianteID,v.SKU,v.Producto,v.Presentacion
        ORDER BY Total DESC,v.VarianteID
    """, [start, end])


def payments(start,end):
    return execute_query("""SELECT m.Nombre,SUM(p.Monto) AS Total FROM dbo.PagoFactura p JOIN dbo.Factura f ON f.FacturaID=p.FacturaID JOIN dbo.MedioPago m ON m.MedioPagoID=p.MedioPagoID
    WHERE f.Estado='EMITIDA' AND f.FechaFactura>=%s AND f.FechaFactura<%s GROUP BY m.Nombre ORDER BY m.Nombre""",[start,end])

def inventory():
    return execute_query("""SELECT COUNT(*) AS Variantes,COALESCE(SUM(CASE WHEN COALESCE(i.StockActual,0)=0 THEN 1 ELSE 0 END),0) AS Agotados,
    COALESCE(SUM(CASE WHEN i.StockActual>0 AND i.StockActual<=i.StockMinimo THEN 1 ELSE 0 END),0) AS Bajos FROM dbo.vw_InventarioActual i JOIN dbo.vw_ProductosCatalogo v ON v.VarianteID=i.VarianteID WHERE v.DisponibleVenta=1""",one=True)

def recent(module):
    sql={
    'facturas':"SELECT TOP(5) FacturaID AS ID,NumeroFactura AS Referencia,FechaFactura AS Fecha,Estado,Total FROM dbo.Factura ORDER BY FacturaID DESC",
    'cotizaciones':"SELECT TOP(5) CotizacionID AS ID,CONCAT('COT-',CotizacionID) AS Referencia,FechaCotizacion AS Fecha,Estado,Total FROM dbo.Cotizacion ORDER BY CotizacionID DESC",
    'compras':"SELECT TOP(5) OrdenCompraID AS ID,CONCAT('OC-',OrdenCompraID) AS Referencia,FechaOrden AS Fecha,Estado FROM dbo.OrdenCompra ORDER BY OrdenCompraID DESC",
    'inventario':"SELECT TOP(5) MovimientoID AS ID,CONCAT(ReferenciaTipo,' #',ReferenciaID) AS Referencia,FechaMovimiento AS Fecha,TipoMovimiento AS Estado FROM dbo.MovimientoInventario ORDER BY MovimientoID DESC"}
    return execute_query(sql[module])

def active_products():return execute_query('SELECT COUNT(*) AS Total FROM dbo.Producto WHERE Activo=1',one=True)['Total']
def pending_purchases():return execute_query("SELECT COUNT(*) AS Total FROM dbo.OrdenCompra WHERE Estado IN ('PENDIENTE','PARCIAL')",one=True)['Total']

def pending_quotes():
    return execute_query("SELECT COUNT(*) AS Total FROM dbo.Cotizacion WHERE Estado='PENDIENTE'", one=True)['Total']


def stock_alerts():
    return execute_query("""
        SELECT TOP(5) v.VarianteID, v.SKU, v.Producto, v.Presentacion
        FROM dbo.vw_ProductosCatalogo v
        JOIN dbo.vw_InventarioActual i ON i.VarianteID=v.VarianteID
        WHERE v.DisponibleVenta=1 AND COALESCE(i.StockActual,0)=0
        ORDER BY v.Producto, v.VarianteID
    """)
