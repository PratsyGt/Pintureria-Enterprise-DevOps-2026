from django.views.decorators.http import require_POST
from django.shortcuts import render,redirect
from django.contrib import messages
from django.db import DatabaseError, IntegrityError
from core.permissions import permission_required, user_permissions
from .forms import ClienteForm,ProveedorForm,CategoriaForm,MarcaForm
from . import services

META={
 'clientes':{
   'titulo':'Clientes','singular':'cliente','form':ClienteForm,'id_form':'cliente_id','id_db':'ClienteID',
   'headers':['ID','Tipo','NIT','Nombre','Teléfono','Correo','Estado'],
   'fields':['ClienteID','TipoCliente','NIT','Nombre','Telefono','Correo','Activo']},
 'proveedores':{
   'titulo':'Proveedores','singular':'proveedor','form':ProveedorForm,'id_form':'proveedor_id','id_db':'ProveedorID',
   'headers':['ID','NIT','Nombre','Contacto','Teléfono','Correo','Estado'],
   'fields':['ProveedorID','NIT','Nombre','Contacto','Telefono','Correo','Activo']},
 'categorias':{
   'titulo':'Categorías','singular':'categoría','form':CategoriaForm,'id_form':'categoria_id','id_db':'CategoriaID',
   'headers':['ID','Nombre','Tipo','Maneja lote','Descripción','Estado'],
   'fields':['CategoriaID','Nombre','TipoControl','ManejaLote','Descripcion','Activo']},
 'marcas':{
   'titulo':'Marcas','singular':'marca','form':MarcaForm,'id_form':'marca_id','id_db':'MarcaID',
   'headers':['ID','Nombre','Descripción','Estado'],
   'fields':['MarcaID','Nombre','Descripcion','Activo']},
}

def _initial(tipo,obj):
    if not obj:return {}
    maps={
      'clientes':{'cliente_id':'ClienteID','tipo_cliente':'TipoCliente','nit':'NIT','nombre':'Nombre','telefono':'Telefono','correo':'Correo','direccion':'Direccion','activo':'Activo'},
      'proveedores':{'proveedor_id':'ProveedorID','nit':'NIT','nombre':'Nombre','contacto':'Contacto','telefono':'Telefono','correo':'Correo','direccion':'Direccion','activo':'Activo'},
      'categorias':{'categoria_id':'CategoriaID','nombre':'Nombre','tipo_control':'TipoControl','maneja_lote':'ManejaLote','descripcion':'Descripcion','activo':'Activo'},
      'marcas':{'marca_id':'MarcaID','nombre':'Nombre','descripcion':'Descripcion','activo':'Activo'},
    }
    return {k:obj.get(v) for k,v in maps[tipo].items()}

@permission_required('catalogo', 'ver')
def catalogo_list(request,tipo):
    if tipo not in META:return redirect('dashboard')
    meta=META[tipo]
    rows,pagination=services.listar_pagina(tipo,request,meta['fields'])
    table_rows=[{'pk':r[meta['id_db']], 'activo':r['Activo'], 'values':[r.get(f) for f in meta['fields']]} for r in rows]
    return render(request,'catalogos/list.html',{'pagination':pagination,'tipo':tipo,'meta':meta,'rows':rows,'table_rows':table_rows,'puede_editar':user_permissions(request).get(tipo,{}).get('editar',False)})

@permission_required('catalogo', 'editar')
def catalogo_nuevo(request,tipo):
    if tipo not in META:return redirect('dashboard')
    meta=META[tipo]; Form=meta['form']
    form=Form(request.POST or None)
    if request.method=='POST' and form.is_valid():
        try:
            services.guardar(tipo,{**form.cleaned_data,meta['id_form']:None,'activo':True})
            messages.success(request,f"{meta['singular'].capitalize()} guardado correctamente.")
            return redirect('catalogo_list',tipo=tipo)
        except (DatabaseError,IntegrityError) as exc:
            messages.error(request,f'No se pudo guardar: Revise los datos y la conexión; consulte el registro del servidor.')
    return render(request,'catalogos/form.html',{'tipo':tipo,'meta':meta,'form':form,'titulo':f"Nuevo {meta['singular']}"})

@permission_required('catalogo', 'editar')
def catalogo_editar(request,tipo,pk):
    if tipo not in META:return redirect('dashboard')
    meta=META[tipo]; obj=services.obtener(tipo,pk)
    if not obj:
        messages.error(request,'Registro no encontrado.'); return redirect('catalogo_list',tipo=tipo)
    Form=meta['form']; form=Form(request.POST or None,initial=_initial(tipo,obj))
    if request.method=='POST' and form.is_valid():
        try:
            services.guardar(tipo,{**form.cleaned_data,meta['id_form']:pk,'activo':obj['Activo']})
            messages.success(request,f"{meta['singular'].capitalize()} actualizado correctamente.")
            return redirect('catalogo_list',tipo=tipo)
        except (DatabaseError,IntegrityError) as exc:
            messages.error(request,f'No se pudo actualizar: Revise los datos y la conexión; consulte el registro del servidor.')
    return render(request,'catalogos/form.html',{'tipo':tipo,'meta':meta,'form':form,'pk':pk,'titulo':f"Editar {meta['singular']}"})

@permission_required('catalogo', 'editar')
@require_POST
def catalogo_estado(request,tipo,pk,activo):
    if tipo not in META:return redirect('dashboard')
    if activo not in (0,1) or not services.obtener(tipo,pk):
        from django.http import Http404
        raise Http404
    services.cambiar_estado(tipo,pk,bool(activo))
    messages.success(request,'Estado actualizado.')
    return redirect('catalogo_list',tipo=tipo)
