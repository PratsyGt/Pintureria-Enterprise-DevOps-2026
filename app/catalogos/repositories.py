from core.db import execute_query, execute_non_query

CONFIG={
 'clientes':{'listar':'sp_Cliente_Listar','obtener':'sp_Cliente_Obtener','guardar':'sp_Cliente_Guardar','estado':'sp_Cliente_CambiarEstado','id':'ClienteID'},
 'proveedores':{'listar':'sp_Proveedor_Listar','obtener':'sp_Proveedor_Obtener','guardar':'sp_Proveedor_Guardar','estado':'sp_Proveedor_CambiarEstado','id':'ProveedorID'},
 'categorias':{'listar':'sp_Categoria_Listar','obtener':'sp_Categoria_Obtener','guardar':'sp_Categoria_Guardar','estado':'sp_Categoria_CambiarEstado','id':'CategoriaID'},
 'marcas':{'listar':'sp_Marca_Listar','obtener':'sp_Marca_Obtener','guardar':'sp_Marca_Guardar','estado':'sp_Marca_CambiarEstado','id':'MarcaID'},
}

def listar(tipo):
    return sorted(execute_query(f"EXEC dbo.{CONFIG[tipo]['listar']}"), key=lambda r:r[CONFIG[tipo]["id"]])

def obtener(tipo,pk):
    idn=CONFIG[tipo]['id']
    return execute_query(f"EXEC dbo.{CONFIG[tipo]['obtener']} @{idn}=%s",[pk],one=True)

def cambiar_estado(tipo,pk,activo):
    idn=CONFIG[tipo]['id']
    execute_non_query(f"EXEC dbo.{CONFIG[tipo]['estado']} @{idn}=%s,@Activo=%s",[pk,1 if activo else 0])

def guardar_cliente(d):
    p=[d.get('cliente_id') or None,d['tipo_cliente'],d.get('nit') or None,d['nombre'],d.get('telefono') or None,d.get('correo') or None,d.get('direccion') or None,1 if d.get('activo') else 0]
    return execute_query('EXEC dbo.sp_Cliente_Guardar @ClienteID=%s,@TipoCliente=%s,@NIT=%s,@Nombre=%s,@Telefono=%s,@Correo=%s,@Direccion=%s,@Activo=%s',p,one=True)

def guardar_proveedor(d):
    p=[d.get('proveedor_id') or None,d.get('nit') or None,d['nombre'],d.get('contacto') or None,d.get('telefono') or None,d.get('correo') or None,d.get('direccion') or None,1 if d.get('activo') else 0]
    return execute_query('EXEC dbo.sp_Proveedor_Guardar @ProveedorID=%s,@NIT=%s,@Nombre=%s,@Contacto=%s,@Telefono=%s,@Correo=%s,@Direccion=%s,@Activo=%s',p,one=True)

def guardar_categoria(d):
    p=[d.get('categoria_id') or None,d['nombre'],d['tipo_control'],1 if d.get('maneja_lote') else 0,d.get('descripcion') or None,1 if d.get('activo') else 0]
    return execute_query('EXEC dbo.sp_Categoria_Guardar @CategoriaID=%s,@Nombre=%s,@TipoControl=%s,@ManejaLote=%s,@Descripcion=%s,@Activo=%s',p,one=True)

def guardar_marca(d):
    p=[d.get('marca_id') or None,d['nombre'],d.get('descripcion') or None,1 if d.get('activo') else 0]
    return execute_query('EXEC dbo.sp_Marca_Guardar @MarcaID=%s,@Nombre=%s,@Descripcion=%s,@Activo=%s',p,one=True)


def listar_pagina(tipo,request,fields):
    from core.pagination import page_query
    tables={'clientes':'Cliente','proveedores':'Proveedor','categorias':'Categoria','marcas':'Marca'}
    return page_query(request,'SELECT * FROM dbo.'+tables[tipo],fields,CONFIG[tipo]['id'],state_column='Activo',states=[('1','Activo'),('0','Inactivo')])
