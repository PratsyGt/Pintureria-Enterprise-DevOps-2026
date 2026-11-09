from django.urls import path
from . import views, final_views
urlpatterns = [
 path('productos/',final_views.productos_catalogo,name='productos_catalogo'),
 path('anulaciones/',final_views.factura_anular,name='factura_anular'),
 path('facturas/<int:pk>/devolucion/',final_views.devolucion,name='devolucion'),
 path('cotizaciones/<int:pk>/',final_views.cotizacion_detalle,name='cotizacion_detalle'),
 path('productos/nuevo/', views.producto_nuevo, name='producto_nuevo'),
 path('inventario/', views.inventario, name='inventario'),
 path('inventario/lotes/', views.inventario_lotes, name='inventario_lotes'),
 path('inventario/movimientos/', views.inventario_movimientos, name='inventario_movimientos'),
 path('cotizaciones/', views.cotizaciones, name='cotizaciones'),
 path('cotizaciones/nueva/', views.cotizacion_nueva, name='cotizacion_nueva'),
 path('cotizaciones/<int:pk>/confirmar/', views.cotizacion_confirmar, name='cotizacion_confirmar'),
 path('facturas/', views.facturas, name='facturas'),
 path('facturas/nueva/', views.factura_nueva, name='factura_nueva'),
 path('facturas/<int:pk>/', views.factura_imprimir, name='factura_imprimir'),
 path('compras/', views.compras, name='compras'),
 path('compras/nueva/', views.compra_nueva, name='compra_nueva'),
 path('compras/<int:pk>/recibir/', views.compra_recibir, name='compra_recibir'),
]
