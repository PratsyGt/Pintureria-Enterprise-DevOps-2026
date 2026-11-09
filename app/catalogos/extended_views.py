from django.shortcuts import render,redirect
from django.http import Http404
from django.contrib import messages
from django.db import DatabaseError
from django.views.decorators.http import require_POST
from core.permissions import permission_required,user_permissions
from . import extended as repo
def metadata(tipo):
 if tipo not in repo.SPECS: raise Http404
 table,pk,fields=repo.SPECS[tipo]
 return {'titulo':tipo.capitalize(),'headers':[pk]+list(fields)+['Estado'],'id_db':pk}
@permission_required('catalogo')
def listado(request,tipo):
 meta=metadata(tipo);rows,pagination=repo.listar_pagina(tipo,request)
 return render(request,'catalogos/list.html',{'pagination':pagination,'tipo':tipo,'meta':meta,'extended':True,'puede_editar':user_permissions(request).get(tipo,{}).get('editar'),'table_rows':[{'pk':r[meta['id_db']],'activo':r['Activo'],'values':[r.get(k) for k in meta['headers'][:-1]]+[r['Activo']]} for r in rows]})
@permission_required('catalogo','editar')
def formulario(request,tipo,pk=None):
 meta=metadata(tipo);obj=repo.obtener(tipo,pk) if pk else None
 if pk and not obj: raise Http404
 form=repo.form_for(tipo,request.POST if request.method=='POST' else None,obj)
 if request.method=='POST' and form.is_valid():
  try:
   repo.guardar(tipo,form.cleaned_data,pk);messages.success(request,'Registro guardado correctamente.')
   return redirect('mantenimiento_list',tipo=tipo)
  except DatabaseError: form.add_error(None,'Revise códigos únicos y referencias relacionadas.')
 return render(request,'catalogos/form.html',{'tipo':tipo,'meta':meta,'form':form,'extended':True,'titulo':('Editar' if pk else 'Crear')+' '+tipo,'pk':pk})
@permission_required('catalogo','editar')
@require_POST
def estado(request,tipo,pk,activo):
 metadata(tipo)
 if activo not in (0,1) or not repo.obtener(tipo,pk): raise Http404
 repo.estado(tipo,pk,activo);messages.success(request,'Estado actualizado; historial conservado.')
 return redirect('mantenimiento_list',tipo=tipo)
