from django.db import connection


def rows_to_dicts(cursor):
    cols=[c[0] for c in cursor.description] if cursor.description else []
    return [dict(zip(cols,row)) for row in cursor.fetchall()]


def execute_query(sql, params=None, one=False):
    with connection.cursor() as cursor:
        cursor.execute(sql, params or [])
        data=rows_to_dicts(cursor)
    return (data[0] if data else None) if one else data


def execute_non_query(sql, params=None):
    with connection.cursor() as cursor:
        cursor.execute(sql, params or [])
