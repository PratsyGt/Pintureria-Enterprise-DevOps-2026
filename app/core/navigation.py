from django.urls import reverse

def navigation(request,perms):
    definitions=[('Principal',[('dashboard','Resumen','grid',None,None)]),
    ('Operaciones',[('factura_nueva','Punto de venta','cart','facturas','editar'),('cotizaciones','Cotizaciones','file','cotizaciones','ver'),('facturas','Facturas','receipt','facturas','ver'),('compras','Compras y recepciones','truck','compras','ver'),('factura_anular','Anulaciones','return','anulaciones','editar')]),
    ('Inventario',[('productos_catalogo','Productos','box','productos','ver'),('inventario','Existencias y lotes','layers','inventario','ver'),('inventario_movimientos','Movimientos','activity','inventario','ver'),('mantenimiento_list:ubicaciones','Ubicaciones','pin','ubicaciones','ver'),('mantenimiento_list:variantes','Variantes','swatch','variantes','ver')]),
    ('Administración',[('catalogo_list:clientes','Clientes','users','clientes','ver'),('catalogo_list:proveedores','Proveedores','truck','proveedores','ver'),('catalogo_list:categorias','Categorías','grid','categorias','ver'),('catalogo_list:marcas','Marcas','tag','marcas','ver'),('mantenimiento_list:presentaciones','Presentaciones','box','presentaciones','ver'),('mantenimiento_list:colores','Colores','swatch','colores','ver'),('mantenimiento_list:unidades','Unidades','layers','unidades','ver'),('usuarios_list','Usuarios y permisos','shield','gerente','ver')]),
    ('Inteligencia comercial',[('reportes','Reportes y análisis','chart','reportes','ver')]),
    ('Cuenta',[('perfil','Mi perfil','user',None,None)])]
    output=[];section='Espacio de trabajo'
    for title,items in definitions:
        links=[]
        for route,label,icon,module,action in items:
            if module=='gerente' and request.session.get('rol')!='GERENTE':continue
            if module and module!='gerente' and not perms.get(module,{}).get(action):continue
            name,*args=route.split(':');url=reverse(name,args=args)
            active=request.path==url or (url!='/' and request.path.startswith(url) and name not in ('factura_nueva','facturas','compras'))
            if active:section=label
            links.append({'url':url,'label':label,'icon':icon,'active':active})
        if links:output.append({'title':title,'links':links})
    links=[link for group in output for link in group['links']]
    candidates=[link for link in links if request.path==link['url'] or (link['url']!='/' and request.path.startswith(link['url']))]
    selected=max(candidates,key=lambda link:len(link['url'])) if candidates else None
    for link in links:link['active']=link is selected
    return output,selected['label'] if selected else section
