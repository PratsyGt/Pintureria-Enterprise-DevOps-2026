from .db import execute_query

def dashboard_resumen():
    return execute_query('EXEC dbo.sp_DashboardResumen', one=True) or {}
