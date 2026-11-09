from django.urls import path
from . import views
urlpatterns=[
    path('login/',views.login_view,name='login'),
    path('logout/',views.logout_view,name='logout'),
    path('usuarios/',views.usuarios_list,name='usuarios_list'),
    path('usuarios/nuevo/',views.usuario_nuevo,name='usuario_nuevo'),
    path('usuarios/<int:usuario_id>/editar/',views.usuario_editar,name='usuario_editar'),
    path('usuarios/<int:usuario_id>/estado/<int:activo>/',views.usuario_estado,name='usuario_estado'),
]
