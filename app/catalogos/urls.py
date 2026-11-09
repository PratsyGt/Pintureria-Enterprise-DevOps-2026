from django.urls import path
from . import views, extended_views
urlpatterns=[
    path('mantenimiento/<str:tipo>/',extended_views.listado,name='mantenimiento_list'),
    path('mantenimiento/<str:tipo>/nuevo/',extended_views.formulario,name='mantenimiento_nuevo'),
    path('mantenimiento/<str:tipo>/<int:pk>/editar/',extended_views.formulario,name='mantenimiento_editar'),
    path('mantenimiento/<str:tipo>/<int:pk>/estado/<int:activo>/',extended_views.estado,name='mantenimiento_estado'),
    path('<str:tipo>/',views.catalogo_list,name='catalogo_list'),
    path('<str:tipo>/nuevo/',views.catalogo_nuevo,name='catalogo_nuevo'),
    path('<str:tipo>/<int:pk>/editar/',views.catalogo_editar,name='catalogo_editar'),
    path('<str:tipo>/<int:pk>/estado/<int:activo>/',views.catalogo_estado,name='catalogo_estado'),
]
