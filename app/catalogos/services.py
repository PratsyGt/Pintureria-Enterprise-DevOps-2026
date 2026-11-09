from . import repositories as repo

def listar(tipo): return repo.listar(tipo)
def obtener(tipo,pk): return repo.obtener(tipo,pk)
def cambiar_estado(tipo,pk,activo): repo.cambiar_estado(tipo,pk,activo)

def guardar(tipo,data):
    return {
        'clientes':repo.guardar_cliente,
        'proveedores':repo.guardar_proveedor,
        'categorias':repo.guardar_categoria,
        'marcas':repo.guardar_marca,
    }[tipo](data)

def listar_pagina(tipo,request,fields):return repo.listar_pagina(tipo,request,fields)
