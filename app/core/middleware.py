import logging
from django.db import DatabaseError
from django.http import HttpResponse
from django.utils.deprecation import MiddlewareMixin

logger=logging.getLogger(__name__)

class DatabaseUnavailableMiddleware(MiddlewareMixin):
    def process_exception(self,request,exception):
        if isinstance(exception,DatabaseError):
            logger.exception('Fallo de base de datos en %s',request.path)
            return HttpResponse('<!doctype html><html lang="es"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Conexión no disponible</title><main style="max-width:600px;margin:10vh auto;padding:24px;font-family:system-ui"><h1>No se pudo completar la consulta</h1><p>Compruebe la instancia de SQL Server, las variables DB_* y los scripts de actualización. La operación no se confirmó.</p><a href="/">Volver al inicio</a></main></html>',status=503)
