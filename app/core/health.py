import os

from django.db import DatabaseError, connection
from django.http import JsonResponse
from django.views.decorators.cache import never_cache
from django.views.decorators.http import require_safe


def status(available):
    return JsonResponse({'status': 'ok' if available else 'unavailable',
                         'revision': os.getenv('APP_REVISION', 'local')},
                        status=200 if available else 503)


@never_cache
@require_safe
def live(request):
    return status(True)


@never_cache
@require_safe
def ready(request):
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT TOP (1) RolID FROM dbo.Rol WHERE Nombre='GERENTE'")
            return status(cursor.fetchone() is not None)
    except DatabaseError:
        return status(False)
