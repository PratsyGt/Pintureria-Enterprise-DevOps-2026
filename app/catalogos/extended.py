"""SQL identifiers come exclusively from the closed SPECS registry."""
from django import forms
from core.db import execute_query, execute_non_query
C=lambda n,**kw:forms.CharField(max_length=n,**kw)
I=lambda **kw:forms.TypedChoiceField(coerce=int,**kw)
D=lambda d,p,**kw:forms.DecimalField(max_digits=d,decimal_places=p,min_value=0,**kw)
SPECS={
 'unidades':('UnidadMedida','UnidadMedidaID',{'Nombre':C(50),'Simbolo':C(15)}),
 'presentaciones':('Presentacion','PresentacionID',{'Nombre':C(50),'UnidadMedidaID':I(label='Unidad'),'FactorGalon':D(10,5,required=False)}),
 'colores':('ColorProducto','ColorID',{'Nombre':C(80),'CodigoHex':forms.RegexField(r'^#[0-9A-Fa-f]{6}$',required=False)}),
 'ubicaciones':('Ubicacion','UbicacionID',{'Codigo':C(30),'Bodega':C(80),'Pasillo':C(30,required=False),'Estante':C(30,required=False),'Nivel':C(30,required=False),'Descripcion':C(180,required=False)}),
 'productos':('Producto','ProductoID',{'CodigoBase':C(40),'Nombre':C(150),'CategoriaID':I(label='Categoría'),'MarcaID':I(label='Marca'),'Descripcion':C(300,required=False),'ManejaColor':forms.BooleanField(required=False),'ManejaLote':forms.BooleanField(required=False)}),
 'variantes':('ProductoVariante','VarianteID',{'ProductoID':I(label='Producto'),'PresentacionID':I(label='Presentación'),'ColorID':I(required=False,empty_value=None),'SKU':C(60),'PrecioVenta':D(12,2),'StockMinimo':D(12,3)})}
RELATIONS={'UnidadMedidaID':'UnidadMedida','CategoriaID':'Categoria','MarcaID':'Marca','ProductoID':'Producto','PresentacionID':'Presentacion','ColorID':'ColorProducto'}
def form_for(tipo,data=None,initial=None):
 fields=SPECS[tipo][2]
 form=type('MantenimientoForm',(forms.Form,),dict(fields))(data,initial=initial)
 for key,table in RELATIONS.items():
  if key in fields:
   rows=execute_query(f'SELECT {key},Nombre FROM dbo.{table} WHERE Activo=1 OR {key}=%s ORDER BY {key} ASC',[(initial or {}).get(key) or 0])
   form.fields[key].choices=[('','Seleccione')]+[(r[key],r['Nombre']) for r in rows]
 return form
def listar(tipo):
 table,pk,_=SPECS[tipo]
 return execute_query(f'SELECT * FROM dbo.{table} ORDER BY {pk} ASC')
def obtener(tipo,value):
 table,pk,_=SPECS[tipo]
 return execute_query(f'SELECT * FROM dbo.{table} WHERE {pk}=%s',[value],one=True)
def guardar(tipo,data,value=None):
 table,pk,fields=SPECS[tipo];names=list(fields)
 values=[data[k] if data[k]!='' else None for k in names]
 if value:
  execute_non_query(f'UPDATE dbo.{table} SET '+','.join(f'{k}=%s' for k in names)+f' WHERE {pk}=%s',values+[value])
 else:
  execute_non_query(f'INSERT dbo.{table} ('+','.join(names)+',Activo) VALUES ('+','.join(['%s']*len(names))+',1)',values)
def estado(tipo,value,active):
 table,pk,_=SPECS[tipo]
 execute_non_query(f'UPDATE dbo.{table} SET Activo=%s WHERE {pk}=%s',[int(active),value])


def listar_pagina(tipo,request):
 from core.pagination import page_query
 table,pk,fields=SPECS[tipo]
 return page_query(request,f'SELECT * FROM dbo.{table}',[pk]+list(fields)+['Activo'],pk,state_column='Activo',states=[('1','Activo'),('0','Inactivo')])
