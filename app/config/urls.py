from django.urls import path, include
from core.views import dashboard,perfil
from reportes.views import index
from core.health import live, ready
urlpatterns=[
    path('health/live/',live),
    path('health/ready/',ready),
    path('perfil/',perfil,name='perfil'),
    path('reportes/',index,name='reportes'),
    path('', dashboard, name='dashboard'),
    path('seguridad/', include('seguridad.urls')),
    path('catalogos/', include('catalogos.urls')),
    path('comercial/', include('comercial.urls')),
]
