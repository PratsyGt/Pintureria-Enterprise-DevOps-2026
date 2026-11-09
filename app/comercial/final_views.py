from decimal import Decimal
from django import forms
from django.shortcuts import render,redirect
from django.contrib import messages
from django.db import DatabaseError
from django.http import Http404
from core.permissions import permission_required
from core.db import execute_query
from reportes.repositories import factura

class AnulacionForm(forms.Form):
    numero=forms.CharField(max_length=40,label='Número de factura')
    motivo=forms.CharField(max_length=250,min_length=5,widget=forms.Textarea(attrs={'rows':3}))
    confirmar=forms.BooleanField(label='Confirmo la anulación y la restitución del inventario')

@permission_required('anulaciones','editar')
def factura_anular(request):
    numero=(request.POST.get('numero') if request.method=='POST' else request.GET.get('numero','')).strip()[:40]
    cab=None;detalle=[];pagos=[]
    form=AnulacionForm(request.POST if request.method=='POST' else None,initial={'numero':numero})
    if numero:
        cab,detalle,pagos=factura(numero)
        if not cab: messages.error(request,'Factura no encontrada.')
    if request.method=='POST' and form.is_valid():
        try:
            row=execute_query('EXEC dbo.sp_Factura_Anular @NumeroFactura=%s,@UsuarioID=%s,@Motivo=%s',[form.cleaned_data['numero'],request.session['usuario_id'],form.cleaned_data['motivo']],one=True)
            messages.success(request,'Factura anulada. Total vigente: Q 0.00. Inventario restituido a los lotes originales.')
            return redirect('factura_imprimir',pk=row['FacturaID'])
        except DatabaseError:
            form.add_error(None,'No se pudo anular. Verifique que esté emitida y que sus salidas y devoluciones históricas estén conciliadas por lote.')
    return render(request,'comercial/anular.html',{'form':form,'f':cab,'detalle':detalle,'pagos':pagos,'numero':numero})

class DevolucionForm(forms.Form):
    detalle=forms.TypedChoiceField(coerce=int,label='Línea de factura')
    cantidad=forms.DecimalField(max_digits=12,decimal_places=3,min_value=Decimal('0.001'))
    motivo=forms.CharField(max_length=250,min_length=5)
    confirmar=forms.BooleanField(label='Confirmo la devolución')

@permission_required('devoluciones','editar')
def devolucion(request,pk):
    cab=execute_query('SELECT NumeroFactura FROM dbo.Factura WHERE FacturaID=%s',[pk],one=True)
    if not cab: raise Http404
    cab,detalle,pagos=factura(cab['NumeroFactura'])
    form=DevolucionForm(request.POST if request.method=='POST' else None)
    form.fields['detalle'].choices=[(d['FacturaDetalleID'],f"{d['Producto']} / {d['Presentacion']} / {d['Color'] or ''} - vendido {d['Cantidad']}") for d in detalle]
    if request.method=='POST' and form.is_valid():
        try:
            execute_query('EXEC dbo.sp_Devolucion_Registrar @FacturaID=%s,@FacturaDetalleID=%s,@Cantidad=%s,@UsuarioID=%s,@Motivo=%s',[pk,form.cleaned_data['detalle'],form.cleaned_data['cantidad'],request.session['usuario_id'],form.cleaned_data['motivo']],one=True)
            messages.success(request,'Devolución registrada y unidades reintegradas al inventario.')
            return redirect('devolucion',pk=pk)
        except DatabaseError: form.add_error(None,'No se pudo devolver. Revise el saldo pendiente, el estado de la factura y la trazabilidad de sus lotes.')
    historial=execute_query('SELECT d.DevolucionID,d.FechaDevolucion,d.Motivo,x.FacturaDetalleID,x.Cantidad,x.Monto FROM dbo.DevolucionVenta d JOIN dbo.DevolucionVentaDetalle x ON x.DevolucionID=d.DevolucionID WHERE d.FacturaID=%s ORDER BY d.DevolucionID',[pk])
    return render(request,'comercial/devolucion.html',{'form':form,'f':cab,'historial':historial})

@permission_required('cotizaciones')
def cotizacion_detalle(request,pk):
    cab=execute_query('SELECT c.*,cl.Nombre AS Cliente,cl.NIT FROM dbo.Cotizacion c JOIN dbo.Cliente cl ON cl.ClienteID=c.ClienteID WHERE c.CotizacionID=%s',[pk],one=True)
    if not cab: raise Http404
    rows=execute_query('SELECT v.Producto,v.SKU,v.Presentacion,v.Color,d.Cantidad,d.PrecioUnitario,d.Descuento,ROUND(d.Cantidad*d.PrecioUnitario,2)-d.Descuento AS Importe FROM dbo.CotizacionDetalle d JOIN dbo.vw_ProductosCatalogo v ON v.VarianteID=d.VarianteID WHERE d.CotizacionID=%s ORDER BY d.CotizacionDetalleID',[pk])
    return render(request,'comercial/cotizacion_detalle.html',{'c':cab,'rows':rows})


@permission_required('productos')
def productos_catalogo(request):
    from core.pagination import page_query
    rows,pagination=page_query(request,"SELECT v.*,COALESCE(i.StockActual,0) AS Existencias FROM dbo.vw_ProductosCatalogo v JOIN dbo.vw_InventarioActual i ON i.VarianteID=v.VarianteID",['VarianteID','SKU','Producto','Categoria','Marca','Presentacion','Color','PrecioVenta','Existencias','Activo'],'VarianteID',state_column='Activo',states=[('1','Activo'),('0','Inactivo')])
    return render(request,'comercial/productos.html',{'rows':rows,'pagination':pagination})
