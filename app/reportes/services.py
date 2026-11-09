from datetime import date
from django import forms
from . import repositories as repo

REPORTES=[('ventas','1 · Total facturado y medios de pago'),('ingresos','2 · Productos que más ingresos generan'),('cantidad','3 · Productos más vendidos'),('inventario','4 · Inventario actual por lote y ubicación'),('menos','5 · Productos con menos ventas'),('sin_stock','6 · Productos sin stock'),('factura','7 · Consulta de factura')]

class ReporteForm(forms.Form):
    tipo=forms.ChoiceField(choices=REPORTES)
    desde=forms.DateField(required=False,widget=forms.DateInput(format='%Y-%m-%d',attrs={'type':'date'}))
    hasta=forms.DateField(required=False,widget=forms.DateInput(format='%Y-%m-%d',attrs={'type':'date'}))
    numero=forms.CharField(max_length=40,required=False,label='Número de factura')
    def clean(self):
        data=super().clean()
        if data.get('tipo') in ('ventas','ingresos','cantidad','menos'):
            if not data.get('desde') or not data.get('hasta'): raise forms.ValidationError('Seleccione ambas fechas.')
            if data['desde']>data['hasta']: raise forms.ValidationError('La fecha inicial no puede superar la final.')
        if data.get('tipo')=='factura' and not data.get('numero'): self.add_error('numero','Ingrese el número de factura.')
        return data

def tabla(titulo,rows):
    return {'titulo':titulo,'headers':list(rows[0]) if rows else [],'rows':[list(r.values()) for r in rows]}

def generar(data):
    titulo=dict(REPORTES)[data['tipo']]
    if data['tipo']=='factura':
        cab,detalle,pagos=repo.factura(data['numero'])
        if not cab: raise ValueError('No se encontró la factura indicada.')
        campos=['NumeroFactura','FechaFactura','Cliente','NIT','Empleado','Estado','Subtotal','Descuento','Total','TotalOriginal','FechaAnulacion','MotivoAnulacion']
        return titulo,[tabla('Factura',[{'Dato':k,'Valor':cab.get(k)} for k in campos]),tabla('Detalle original',detalle),tabla('Pagos históricos (sin vigencia si la factura está anulada)',pagos)]
    rows=repo.consultar(data['tipo'],data.get('desde'),data.get('hasta'))
    return titulo,[tabla(titulo,rows)]
