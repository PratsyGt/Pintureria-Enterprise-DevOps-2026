from core.pagination import page_query
from . import pos_services,pos_repository
import json
from django.shortcuts import render, redirect
from django.db import transaction, connection, DatabaseError
import logging
logger=logging.getLogger(__name__)
from django.utils.http import url_has_allowed_host_and_scheme
from django.contrib import messages
from django.views.decorators.http import require_http_methods, require_POST
from decimal import Decimal, InvalidOperation
from core.permissions import permission_required
from core.db import execute_query
from core.decorators import login_required_custom

@login_required_custom
@permission_required('cotizaciones', 'ver')
def cotizaciones(request):
    rows,pagination=page_query(request,'SELECT c.CotizacionID,c.FechaCotizacion,c.Estado,c.Total,cl.Nombre AS Cliente FROM dbo.Cotizacion c JOIN dbo.Cliente cl ON cl.ClienteID=c.ClienteID',['CotizacionID', 'FechaCotizacion', 'Estado', 'Total', 'Cliente'],'CotizacionID',date_column='FechaCotizacion',state_column="Estado",states=[('PENDIENTE', 'Pendiente'), ('CONFIRMADA', 'Confirmada'), ('FACTURADA', 'Facturada'), ('VENCIDA', 'Vencida'), ('CANCELADA', 'Cancelada')])
    return render(request,'comercial/cotizaciones.html',{'rows':rows,'pagination':pagination})

@login_required_custom
@permission_required('cotizaciones', 'editar')
@require_POST
def cotizacion_confirmar(request,pk):
    try:
        row=execute_query('EXEC dbo.sp_Cotizacion_Confirmar @CotizacionID=%s,@UsuarioID=%s',[pk,request.session['usuario_id']],one=True)
        if row: messages.success(request,f"Cotización #{pk} confirmada. Ya puede facturarla.")
        else: messages.error(request,'La cotización no existe o ya no está pendiente.')
    except (ValueError, KeyError, InvalidOperation) as e: messages.error(request,str(e))
    except DatabaseError: logger.exception("Operación comercial fallida"); messages.error(request,f'No se pudo confirmar la cotización: Revise los datos y la conexión; consulte el registro del servidor.')
    return redirect('cotizaciones')


def validate_lines(raw, mode):
    data=json.loads(raw)
    if not isinstance(data,list) or not data or len(data)>100:
        raise ValueError('Agregue por lo menos una línea.')
    key='ordenCompraDetalleId' if mode=='recepcion' else 'varianteId'
    seen=set()
    for item in data:
        if not isinstance(item,dict) or type(item.get(key)) is not int or item[key]<=0:
            raise ValueError('Seleccione un producto/detalle válido.')
        if item[key] in seen:
            raise ValueError('No repita el mismo producto/detalle en varias líneas.')
        seen.add(item[key])
        for field in (['cantidad','costo'] if mode=='compra' else ['cantidad','costo','ubicacionId'] if mode=='recepcion' else ['cantidad','descuento']):
            try:
                value=Decimal(str(item[field]))
                if not value.is_finite() or (value<=0 if field in ('cantidad','ubicacionId') else value<0):
                    raise ValueError()
                if field=='ubicacionId' and value != value.to_integral_value(): raise ValueError()
                if field=='cantidad' and value.as_tuple().exponent < -3: raise ValueError()
                if field in ('costo','descuento') and value.as_tuple().exponent < -2: raise ValueError()
            except (KeyError,InvalidOperation,ValueError,TypeError):
                raise ValueError(f'Valor inválido en {field}.')
    return raw


def validate_payments(raw):
    data=json.loads(raw)
    if not isinstance(data,list) or not data or len(data)>100: raise ValueError('Ingrese al menos un medio de pago.')
    for entry in data:
        try:
            if not isinstance(entry,dict) or type(entry.get('medioPagoId')) is not int: raise ValueError()
            if len(str(entry.get('referencia','')))>100: raise ValueError()
            amount=Decimal(str(entry['monto']))
            if not amount.is_finite() or amount<=0 or amount.as_tuple().exponent < -2 or int(entry['medioPagoId'])<=0: raise ValueError()
        except (KeyError,ValueError,TypeError,InvalidOperation):
            raise ValueError('Los medios de pago y montos deben ser válidos y positivos.')
    return raw

@login_required_custom
@permission_required('cotizaciones', 'editar')
@require_http_methods(['GET','POST'])
def cotizacion_nueva(request):
    clientes=execute_query('SELECT ClienteID,Nombre,NIT FROM dbo.Cliente WHERE Activo=1 ORDER BY ClienteID ASC')
    productos=execute_query('SELECT VarianteID,SKU,Producto AS Nombre,PrecioVenta FROM dbo.vw_ProductosCatalogo WHERE DisponibleVenta=1 ORDER BY VarianteID ASC')
    if request.method=='POST':
        try:
            cliente=int(request.POST['cliente_id']); detalle=validate_lines(request.POST['detalle_json'],'cotizacion')
            vigencia=request.POST.get('vigencia') or None; obs=request.POST.get('observaciones') or None
            row=execute_query('EXEC dbo.sp_Cotizacion_Crear @ClienteID=%s,@UsuarioID=%s,@DetalleJSON=%s,@VigenciaHasta=%s,@Observaciones=%s',[cliente,request.session['usuario_id'],detalle,vigencia,obs],one=True)
            messages.success(request,f"Cotización #{row['CotizacionID']} creada correctamente."); return redirect('cotizaciones')
        except (ValueError, KeyError, InvalidOperation) as e: messages.error(request,str(e))
        except DatabaseError: logger.exception("Operación comercial fallida"); messages.error(request,f'No se pudo crear la cotización: Revise los datos y la conexión; consulte el registro del servidor.')
    return render(request,'comercial/cotizacion_form.html',{'draft':request.POST.dict() if request.method=='POST' else {},'clientes':clientes,'productos':productos})

@login_required_custom
@permission_required('facturas', 'ver')
def facturas(request):
    rows,pagination=page_query(request,"SELECT f.FacturaID,f.NumeroFactura,f.FechaFactura,f.Estado,f.Total,c.Nombre AS Cliente,u.Nombres+' '+u.Apellidos AS Vendedor FROM dbo.Factura f JOIN dbo.Cliente c ON c.ClienteID=f.ClienteID JOIN dbo.Usuario u ON u.UsuarioID=f.UsuarioID",['FacturaID', 'NumeroFactura', 'FechaFactura', 'Estado', 'Total', 'Cliente', 'Vendedor'],'FacturaID',date_column='FechaFactura',state_column="Estado",states=[('EMITIDA', 'Emitida'), ('ANULADA', 'Anulada')])
    return render(request,'comercial/facturas.html',{'rows':rows,'pagination':pagination})

@login_required_custom
@permission_required('facturas', 'editar')
@require_http_methods(['GET','POST'])
def factura_nueva(request):
    clientes=execute_query('SELECT ClienteID,Nombre,NIT FROM dbo.Cliente WHERE Activo=1 ORDER BY ClienteID ASC')
    productos=pos_repository.products()
    token=request.POST.get('checkout_token','') if request.method=='POST' else pos_services.checkout_token(request.session['usuario_id'])
    pagos=execute_query('SELECT MedioPagoID,Nombre FROM dbo.MedioPago WHERE Activo=1 ORDER BY Nombre')
    cotizaciones_confirmadas=execute_query("SELECT CotizacionID,ClienteID,Total FROM dbo.Cotizacion WHERE Estado='CONFIRMADA' ORDER BY CotizacionID ASC")
    if request.method=='POST':
        try:
            cliente=int(request.POST['cliente_id']); detalle=validate_lines(request.POST['detalle_json'],'factura') if not request.POST.get('cotizacion_id') else '[]'; pagos_json=validate_payments(request.POST['pagos_json'])
            cot=request.POST.get('cotizacion_id') or None
            row=pos_services.submit_sale(request.session['usuario_id'],token,cliente,detalle,pagos_json,cot)
            messages.success(request,f"Factura {row['NumeroFactura']} emitida correctamente."); return redirect('factura_imprimir',pk=row['FacturaID'])
        except (ValueError, KeyError, InvalidOperation) as e: messages.error(request,str(e))
        except DatabaseError: logger.exception("Operación comercial fallida"); messages.error(request,f'No se pudo emitir la factura: Revise los datos y la conexión; consulte el registro del servidor.')
    return render(request,'comercial/factura_form.html',{'checkout_token':token,'draft':request.POST.dict() if request.method=='POST' else {},'clientes':clientes,'productos':productos,'pagos':pagos,'cotizacion_preseleccionada':request.POST.get('cotizacion_id',request.GET.get('cotizacion','')),'cotizaciones_confirmadas':cotizaciones_confirmadas})

@login_required_custom
@permission_required('facturas', 'ver')
def factura_imprimir(request,pk):
    cab=execute_query('SELECT f.*,c.Nombre AS Cliente,c.NIT,c.Direccion,c.Telefono,u.Nombres+\' \'+u.Apellidos AS Vendedor FROM dbo.Factura f JOIN dbo.Cliente c ON c.ClienteID=f.ClienteID JOIN dbo.Usuario u ON u.UsuarioID=f.UsuarioID WHERE f.FacturaID=%s',[pk],one=True)
    if not cab: messages.error(request,'Factura no encontrada.'); return redirect('facturas')
    det=execute_query("SELECT d.Cantidad,d.PrecioUnitario,d.Descuento,(ROUND(d.Cantidad*d.PrecioUnitario,2)-d.Descuento) AS Importe,p.Nombre AS Producto,v.SKU,pr.Nombre AS Presentacion,co.Nombre AS Color FROM dbo.FacturaDetalle d JOIN dbo.ProductoVariante v ON v.VarianteID=d.VarianteID JOIN dbo.Producto p ON p.ProductoID=v.ProductoID JOIN dbo.Presentacion pr ON pr.PresentacionID=v.PresentacionID LEFT JOIN dbo.ColorProducto co ON co.ColorID=v.ColorID WHERE d.FacturaID=%s ORDER BY d.FacturaDetalleID",[pk])
    pagos=execute_query('SELECT mp.Nombre,p.Monto,p.Referencia FROM dbo.PagoFactura p JOIN dbo.MedioPago mp ON mp.MedioPagoID=p.MedioPagoID WHERE p.FacturaID=%s',[pk])
    return render(request,'comercial/factura_print.html',{'f':cab,'det':det,'pagos':pagos})

@login_required_custom
@permission_required('compras', 'ver')
def compras(request):
    proveedor=request.GET.get('proveedor','')
    provider_id=(int(proveedor) if proveedor.isdecimal() and len(proveedor)<=10 and int(proveedor)<=2147483647 else 0) if proveedor else None
    provider=execute_query('SELECT Nombre FROM dbo.Proveedor WHERE ProveedorID=%s',[provider_id],one=True) if provider_id else None
    rows,pagination=page_query(request,'SELECT o.OrdenCompraID,o.FechaOrden,o.Estado,p.Nombre AS Proveedor,(SELECT SUM(d.CantidadSolicitada*d.CostoUnitario) FROM dbo.OrdenCompraDetalle d WHERE d.OrdenCompraID=o.OrdenCompraID) AS Total FROM dbo.OrdenCompra o JOIN dbo.Proveedor p ON p.ProveedorID=o.ProveedorID'+(' WHERE o.ProveedorID=%s' if provider_id else ''),['OrdenCompraID', 'FechaOrden', 'Estado', 'Proveedor', 'Total'],'OrdenCompraID',params=[provider_id] if provider_id else [],date_column='FechaOrden',state_column="Estado",states=[('PENDIENTE', 'Pendiente'), ('PARCIAL', 'Parcial'), ('COMPLETA', 'Completa'), ('CANCELADA', 'Cancelada')])
    return render(request,'comercial/compras.html',{'rows':rows,'pagination':pagination,'proveedor_historial':provider})

@login_required_custom
@permission_required('compras', 'editar')
@require_http_methods(['GET','POST'])
def compra_nueva(request):
    proveedores=execute_query('SELECT ProveedorID,Nombre FROM dbo.Proveedor WHERE Activo=1 ORDER BY Nombre')
    productos=execute_query('SELECT VarianteID,SKU,Producto AS Nombre,PrecioVenta FROM dbo.vw_ProductosCatalogo WHERE DisponibleVenta=1 ORDER BY VarianteID ASC')
    if request.method=='POST':
        try:
            detalle=validate_lines(request.POST['detalle_json'],'compra')
            row=execute_query('EXEC dbo.sp_OrdenCompra_Crear @ProveedorID=%s,@UsuarioID=%s,@DetalleJSON=%s,@Observaciones=%s',[int(request.POST['proveedor_id']),request.session['usuario_id'],detalle,request.POST.get('observaciones') or None],one=True)
            messages.success(request,f"Orden de compra #{row['OrdenCompraID']} creada."); return redirect('compras')
        except (ValueError, KeyError, InvalidOperation) as e: messages.error(request,str(e))
        except DatabaseError: logger.exception("Operación comercial fallida"); messages.error(request,f'No se pudo crear la orden: Revise los datos y la conexión; consulte el registro del servidor.')
    return render(request,'comercial/compra_form.html',{'draft':request.POST.dict() if request.method=='POST' else {},'proveedores':proveedores,'productos':productos})

@login_required_custom
@permission_required('compras', 'editar')
@require_http_methods(['GET','POST'])
def compra_recibir(request,pk):
    orden=execute_query("SELECT o.OrdenCompraID,o.Estado,p.Nombre AS Proveedor FROM dbo.OrdenCompra o JOIN dbo.Proveedor p ON p.ProveedorID=o.ProveedorID WHERE o.OrdenCompraID=%s AND o.Estado IN ('PENDIENTE','PARCIAL')",[pk],one=True)
    if not orden: messages.error(request,'Orden no encontrada o ya completada.'); return redirect('compras')
    detalle=execute_query("SELECT d.OrdenCompraDetalleID,d.VarianteID,d.CantidadSolicitada,d.CantidadRecibida,d.CostoUnitario,(d.CantidadSolicitada-d.CantidadRecibida) AS Pendiente,p.Nombre AS Producto,v.SKU FROM dbo.OrdenCompraDetalle d JOIN dbo.ProductoVariante v ON v.VarianteID=d.VarianteID JOIN dbo.Producto p ON p.ProductoID=v.ProductoID WHERE d.OrdenCompraID=%s",[pk])
    ubicaciones=execute_query('SELECT UbicacionID,Codigo,Bodega FROM dbo.Ubicacion WHERE Activo=1 ORDER BY Bodega,Codigo')
    if request.method=='POST':
        try:
            payload=validate_lines(request.POST['detalle_json'],'recepcion')
            row=execute_query('EXEC dbo.sp_Compra_Recibir @OrdenCompraID=%s,@UsuarioID=%s,@DetalleJSON=%s,@DocumentoProveedor=%s,@Observaciones=%s',[pk,request.session['usuario_id'],payload,request.POST.get('documento') or None,request.POST.get('observaciones') or None],one=True)
            messages.success(request,f"Recepción #{row['RecepcionCompraID']} registrada. El inventario fue actualizado."); return redirect('compras')
        except (ValueError, KeyError, InvalidOperation) as e: messages.error(request,str(e))
        except DatabaseError: logger.exception("Operación comercial fallida"); messages.error(request,f'No se pudo registrar la recepción: Revise los datos y la conexión; consulte el registro del servidor.')
    return render(request,'comercial/recepcion_form.html',{'draft':request.POST.dict() if request.method=='POST' else {},'orden':orden,'detalle':detalle,'ubicaciones':ubicaciones})


@login_required_custom
@permission_required('inventario', 'ver')
def inventario(request):
    buscar = request.GET.get('q', '').strip()[:100]
    rows,pagination = page_query(request,"""
        SELECT i.VarianteID, i.SKU, i.Producto, i.Presentacion, i.Color,
               COALESCE(i.StockActual, 0) AS StockActual, i.StockMinimo,
               CASE WHEN COALESCE(i.StockActual, 0) = 0 THEN 'SIN STOCK'
                    WHEN COALESCE(i.StockActual, 0) <= i.StockMinimo THEN 'BAJO'
                    ELSE 'DISPONIBLE' END AS Estado,
               (SELECT COUNT(*) FROM dbo.LoteInventario l
                WHERE l.VarianteID=i.VarianteID AND l.Activo=1 AND l.CantidadDisponible>0) AS LotesDisponibles
        FROM dbo.vw_InventarioActual i
        WHERE (%s='' OR i.SKU LIKE %s OR i.Producto LIKE %s)
    """, ['VarianteID','SKU','Producto','Presentacion','Color','StockActual','StockMinimo','Estado'],'VarianteID',params=['','%%','%%'],state_column='Estado',states=[('DISPONIBLE','Disponible'),('BAJO','Stock bajo'),('SIN STOCK','Agotado')])
    resumen=execute_query("SELECT COUNT(*) AS productos,COALESCE(SUM(CASE WHEN COALESCE(StockActual,0)=0 THEN 1 ELSE 0 END),0) AS sin_stock,COALESCE(SUM(CASE WHEN StockActual>0 AND StockActual<=StockMinimo THEN 1 ELSE 0 END),0) AS bajos FROM dbo.vw_InventarioActual",one=True)
    return render(request, 'comercial/inventario.html', {'pagination':pagination,'rows': rows, 'resumen_inv': resumen, 'buscar': buscar})


@login_required_custom
@permission_required('inventario', 'ver')
def inventario_lotes(request):
    variante = request.GET.get('variante', '').strip()
    if not variante.isdecimal():
        messages.error(request, 'Seleccione un producto válido.')
        return redirect('inventario')
    producto = execute_query('SELECT VarianteID, SKU, Producto, Presentacion, Color FROM dbo.vw_ProductosCatalogo WHERE VarianteID=%s', [int(variante)], one=True)
    if not producto:
        messages.error(request, 'Producto no encontrado.')
        return redirect('inventario')
    rows,pagination = page_query(request,"""
        SELECT l.LoteID, l.CodigoLote, l.FechaIngreso, l.FechaVencimiento,
               l.CantidadInicial, l.CantidadDisponible, l.CostoUnitario,
               u.Codigo AS Ubicacion, u.Bodega
        FROM dbo.LoteInventario l JOIN dbo.Ubicacion u ON u.UbicacionID=l.UbicacionID
        WHERE l.VarianteID=%s AND l.Activo=1
    """, ['LoteID','CodigoLote','FechaIngreso','CantidadDisponible','CostoUnitario','Ubicacion','Bodega'],'LoteID',params=[int(variante)],default_sort='FechaIngreso')
    return render(request, 'comercial/inventario_lotes.html', {'producto': producto, 'rows': rows,'pagination':pagination})


@login_required_custom
@permission_required('inventario', 'ver')
def inventario_movimientos(request):
    tipo = request.GET.get('tipo', '').strip().upper()
    tipos = ('ENTRADA', 'SALIDA', 'DEVOLUCION', 'AJUSTE_ENTRADA', 'AJUSTE_SALIDA')
    if tipo not in tipos: tipo = ''
    rows,pagination = page_query(request,"""
        SELECT m.MovimientoID, m.FechaMovimiento, m.TipoMovimiento,
               m.Cantidad, m.CostoUnitario, m.ReferenciaTipo, m.ReferenciaID,
               m.Observaciones, l.LoteID, l.CodigoLote,
               v.SKU, p.Nombre AS Producto, ub.Bodega, ub.Codigo AS Ubicacion,
               us.Nombres + ' ' + us.Apellidos AS Responsable
        FROM dbo.MovimientoInventario m
        JOIN dbo.LoteInventario l ON l.LoteID=m.LoteID
        JOIN dbo.ProductoVariante v ON v.VarianteID=l.VarianteID
        JOIN dbo.Producto p ON p.ProductoID=v.ProductoID
        JOIN dbo.Ubicacion ub ON ub.UbicacionID=l.UbicacionID
        JOIN dbo.Usuario us ON us.UsuarioID=m.UsuarioID
        WHERE (%s='' OR m.TipoMovimiento=%s)
    """,['MovimientoID','FechaMovimiento','TipoMovimiento','SKU','Producto','Ubicacion','Responsable','ReferenciaTipo'],'MovimientoID',params=[tipo,tipo])
    return render(request, 'comercial/inventario_movimientos.html', {'pagination':pagination,'rows': rows, 'tipo': tipo, 'tipos': tipos})


@login_required_custom
@permission_required('productos', 'editar')
@require_http_methods(['GET','POST'])
def producto_nuevo(request):
    categorias=execute_query('SELECT CategoriaID,Nombre,ManejaLote FROM dbo.Categoria WHERE Activo=1 ORDER BY Nombre')
    marcas=execute_query('SELECT MarcaID,Nombre FROM dbo.Marca WHERE Activo=1 ORDER BY Nombre')
    presentaciones=execute_query('SELECT PresentacionID,Nombre FROM dbo.Presentacion WHERE Activo=1 ORDER BY Nombre')
    colores=execute_query('SELECT ColorID,Nombre FROM dbo.ColorProducto WHERE Activo=1 ORDER BY Nombre')
    origen=request.POST.get('siguiente') if request.method=='POST' else request.GET.get('siguiente','')
    if not origen or not url_has_allowed_host_and_scheme(origen,allowed_hosts={request.get_host()},require_https=request.is_secure()):
        origen='/comercial/inventario/'
    if request.method=='POST':
        try:
            codigo=request.POST.get('codigo_base','').strip()
            nombre=request.POST.get('nombre','').strip()
            sku=request.POST.get('sku','').strip()
            if not codigo or not nombre or not sku:
                raise ValueError('Código, nombre y SKU son obligatorios.')
            if len(codigo)>40 or len(nombre)>150 or len(sku)>60:
                raise ValueError('Revise la longitud del código, nombre y SKU.')
            cat=int(request.POST.get('categoria_id',''))
            marca=int(request.POST.get('marca_id',''))
            presentacion=int(request.POST.get('presentacion_id',''))
            color=int(request.POST['color_id']) if request.POST.get('color_id') else None
            precio=Decimal(request.POST.get('precio',''))
            minimo=Decimal(request.POST.get('stock_minimo','0'))
            if not precio.is_finite() or not minimo.is_finite() or precio<0 or minimo<0 or precio.as_tuple().exponent < -2 or minimo.as_tuple().exponent < -3:
                raise ValueError('Revise el precio y el stock mínimo.')
            if precio>Decimal('9999999999.99') or minimo>Decimal('999999999.999'):
                raise ValueError('Precio o stock mínimo fuera de rango.')
            if cat not in {r['CategoriaID'] for r in categorias} or marca not in {r['MarcaID'] for r in marcas} or presentacion not in {r['PresentacionID'] for r in presentaciones} or (color is not None and color not in {r['ColorID'] for r in colores}):
                raise ValueError('Seleccione una categoría, marca, presentación y color válidos.')
            lotes=next(r['ManejaLote'] for r in categorias if r['CategoriaID']==cat)
            with transaction.atomic():
                with connection.cursor() as cursor:
                    cursor.execute('SET NOCOUNT ON; INSERT INTO dbo.Producto (CategoriaID,MarcaID,CodigoBase,Nombre,Descripcion,ManejaColor,ManejaLote,Activo) VALUES (%s,%s,%s,%s,%s,%s,%s,1); SELECT CAST(SCOPE_IDENTITY() AS INT)',[cat,marca,codigo,nombre,request.POST.get('descripcion','').strip()[:300] or None,int(color is not None),int(lotes)])
                    producto_id=cursor.fetchone()[0]
                    cursor.execute('INSERT INTO dbo.ProductoVariante (ProductoID,PresentacionID,ColorID,SKU,PrecioVenta,StockMinimo,Activo) VALUES (%s,%s,%s,%s,%s,%s,1)',[producto_id,presentacion,color,sku,precio,minimo])
            messages.success(request,f'Producto {nombre} registrado correctamente. Ya puede agregarlo a una orden de compra.')
            return redirect(origen)
        except (ValueError, KeyError, InvalidOperation) as exc:
            messages.error(request,str(exc))
        except DatabaseError:
            logger.exception("Alta de producto fallida")
            messages.error(request,f'No se pudo registrar el producto: Revise los datos y la conexión; consulte el registro del servidor.')
    return render(request,'comercial/producto_form.html',{'categorias':categorias,'marcas':marcas,'presentaciones':presentaciones,'colores':colores,'siguiente':origen})
